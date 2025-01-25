USE AkixRaccoltaDatiProduzione;
GO

/*
SET NOEXEC OFF;
--*/ SET NOEXEC ON;

DROP TABLE IF EXISTS Produzione.FasiProduzione;
DROP TABLE IF EXISTS Produzione.PrelevamentiProduzione;
DROP TABLE IF EXISTS Produzione.LottiProduzione;
DROP TABLE IF EXISTS Produzione.OrdiniProduzione;
DROP SCHEMA Produzione;

DROP TABLE IF EXISTS Anagrafica.ArticoloVersione;
DROP TABLE IF EXISTS Anagrafica.Articolo;
DROP TABLE IF EXISTS Anagrafica.UnitaDiMisura;
DROP TABLE IF EXISTS Anagrafica.Cliente;
DROP TABLE IF EXISTS Anagrafica.CambioStatoProduzione;
DROP TABLE IF EXISTS Anagrafica.CausaleProduzione;
DROP TABLE IF EXISTS Anagrafica.Operatore;
DROP TABLE IF EXISTS Anagrafica.CalendarioCentroDiLavoro;
DROP TABLE IF EXISTS Anagrafica.Turno;
DROP TABLE IF EXISTS Anagrafica.LavorazioneCentroDiLavoro;
DROP TABLE IF EXISTS Anagrafica.CentroDiLavoro;
DROP TABLE IF EXISTS Anagrafica.Lavorazione;
DROP TABLE IF EXISTS Anagrafica.StatoProduzione;
DROP SCHEMA Anagrafica;

/*** Anagrafica: Inizio ***/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = N'Anagrafica')
BEGIN
	EXEC ('CREATE SCHEMA Anagrafica AUTHORIZATION dbo;'); -- Anagrafiche (clienti, causali, articoli, lavorazioni, ecc.)
END;
GO

/**
 * @table Anagrafica.StatoProduzione
 * @description Anagrafica stati produzione (da utilizzare per Ordini produzione, Lotti produzione e Fasi produzione)
*/

--DROP TABLE Anagrafica.StatoProduzione;
GO

IF OBJECT_ID(N'Anagrafica.StatoProduzione', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.StatoProduzione (
		statoproduzione_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_StatoProduzione PRIMARY KEY CLUSTERED,
		codice NVARCHAR(20) NOT NULL,
		descrizione NVARCHAR(80) NOT NULL,
		sequenza SMALLINT NOT NULL,
		is_finale BIT NOT NULL CONSTRAINT DFT_Anagrafica_StatoProduzione_is_finale DEFAULT (0),
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_StatoProduzione_is_attivo DEFAULT (0)
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_StatoProduzione_codice ON Anagrafica.StatoProduzione (codice);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_StatoProduzione_sequenza ON Anagrafica.StatoProduzione (sequenza);

	INSERT INTO Anagrafica.StatoProduzione
	(
	    codice,
	    descrizione,
	    sequenza,
		is_attivo
	)
	VALUES (
		N'C', -- codice - nvarchar(20)
	    N'Creato', -- descrizione - nvarchar(80)
	    10,    -- sequenza - smallint
		1	-- is_attivo - bit
	),
	(N'P', N'Programmato', 20, 1),
	(N'I', N'Iniziato', 30, 1),
	(N'S', N'Sospeso', 40, 1),
	(N'D', N'Dichiarato finito', 50, 1),
	(N'F', N'Finito', 60, 1),
	(N'A', N'Annullato', 99, 1);

	SELECT * FROM Anagrafica.StatoProduzione;

END;
GO

/**
 * @table Anagrafica.Lavorazione
 * @description Anagrafica lavorazioni
*/

--DROP TABLE Anagrafica.Lavorazione;
GO

IF OBJECT_ID(N'Anagrafica.Lavorazione', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.Lavorazione (
		lavorazione_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_Lavorazione PRIMARY KEY CLUSTERED,
		codice NVARCHAR(20) NOT NULL,
		descrizione NVARCHAR(80) NOT NULL,
		tipo_durata CHAR(1) NOT NULL CONSTRAINT DFT_Anagrafica_Lavorazione_tipo_operazione DEFAULT ('F'),
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_Lavorazione_is_attivo DEFAULT (0)
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_Lavorazione_codice ON Anagrafica.Lavorazione (codice);

	INSERT INTO Anagrafica.Lavorazione
	(
	    codice,
	    descrizione,
		is_attivo
	)
	VALUES
	(   N'T', -- codice - nvarchar(20)
	    N'Tornitura',  -- descrizione - nvarchar(80)
		1	-- is_attivo - bit
	),
	(N'F', N'Fresatura', 1),
	(N'R', N'Rettifica', 1);

	SELECT * FROM Anagrafica.Lavorazione;

END;
GO

/**
 * @table Anagrafica.CentroDiLavoro
 * @description Anagrafica centri di lavoro
*/

--DROP TABLE Anagrafica.CentroDiLavoro;
GO

IF OBJECT_ID(N'Anagrafica.CentroDiLavoro', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.CentroDiLavoro (
		centrodilavoro_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_CentroDiLavoro PRIMARY KEY CLUSTERED,
		codice NVARCHAR(20) NOT NULL,
		descrizione NVARCHAR(80) NOT NULL,
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_CentroDiLavoro_is_attivo DEFAULT (0)
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_CentroDiLavoro_codice ON Anagrafica.CentroDiLavoro (codice);

	INSERT INTO Anagrafica.CentroDiLavoro
	(
	    codice,
	    descrizione,
		is_attivo
	)
	VALUES
	(   N'T1', -- codice - nvarchar(20)
	    N'Tornio 1',  -- descrizione - nvarchar(80)
		1	-- is_attivo - bit
	),
	(N'T2', N'Tornio 2', 1),
	(N'F', N'Fresa', 1);

	SELECT * FROM Anagrafica.CentroDiLavoro;

END;
GO

/**
 * @table Anagrafica.LavorazioneCentroDiLavoro
 * @description Relazione molti-a-molti lavorazione/centro di lavoro
*/

--DROP TABLE Anagrafica.LavorazioneCentroDiLavoro;
GO

IF OBJECT_ID(N'Anagrafica.LavorazioneCentroDiLavoro', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.LavorazioneCentroDiLavoro (
		lavorazionecentrodilavoro_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_LavorazioneCentroDiLavoro PRIMARY KEY CLUSTERED,
		lavorazione_id INT NOT NULL CONSTRAINT FK_LavorazioneCentroDiLavoro_lavorazione_id REFERENCES Anagrafica.Lavorazione (lavorazione_id),
		centrodilavoro_id INT NOT NULL CONSTRAINT FK_LavorazioneCentroDiLavoro_centrodilavoro_id REFERENCES Anagrafica.CentroDiLavoro (centrodilavoro_id),
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_LavorazioneCentroDiLavoro_is_attivo DEFAULT (0)
	);

	INSERT INTO Anagrafica.LavorazioneCentroDiLavoro
	(
	    lavorazione_id,
	    centrodilavoro_id,
		is_attivo
	)
	VALUES
	(   1, -- lavorazione_id - int
	    1,  -- centrodilavoro_id - int
		1	-- is_attivo - bit
	),
	(1, 2, 1),
	(1, 2, 1),
	(2, 3, 1),
	(3, 1, 1),
	(3, 2, 1),
	(3, 3, 1);

	SELECT * FROM Anagrafica.LavorazioneCentroDiLavoro;

END;
GO

/**
 * @table Anagrafica.Turno
 * @description Anagrafica turni
*/

--DROP TABLE Anagrafica.Turno;
GO

IF OBJECT_ID(N'Anagrafica.Turno', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.Turno (
		turno_id TINYINT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_Turno PRIMARY KEY CLUSTERED,
		codice NVARCHAR(20) NOT NULL,
		descrizione NVARCHAR(80) NOT NULL,
		dataora_inizio DATETIME2 NOT NULL,
		durata_secondi INT NOT NULL,
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_Turno_is_attivo DEFAULT (0)
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_Turno_codice ON Anagrafica.Turno (codice);

	INSERT INTO Anagrafica.Turno
	(
	    codice,
	    descrizione,
	    dataora_inizio,
	    durata_secondi,
		is_attivo
	)
	VALUES
	(   N'T1',       -- codice - nvarchar(20)
	    N'Primo turno',       -- descrizione - nvarchar(80)
	    '1900-01-01 06:00:00', -- dataora_inizio - datetime2
	    28800,  -- durata_secondi - int
		1	-- is_attivo - bit
	),
	(N'T2', N'Secondo turno', '1900-01-01 14:00:00', 28800, 1),
	(N'T3', N'Secondo turno', '1900-01-01 14:00:00', 28800, 0),
	(N'TU', N'Turno unico', '1900-01-01 06:00:00', 28800, 0)

END;
GO

/**
 * @table Anagrafica.CalendarioCentroDiLavoro
 * @description Calendario centri di lavoro
*/

--DROP TABLE Anagrafica.CalendarioCentroDiLavoro;
GO

IF OBJECT_ID(N'Anagrafica.CalendarioCentroDiLavoro', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.CalendarioCentroDiLavoro (
		calendariocentrodilavoro_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_CalendarioCentroDiLavoro PRIMARY KEY CLUSTERED,
		centrodilavoro_id INT NOT NULL CONSTRAINT FK_Anagrafica_CalendarioCentroDiLavoro_centrodilavoro_id REFERENCES Anagrafica.CentroDiLavoro (centrodilavoro_id),
		data_turno DATE NOT NULL,
		turno_id TINYINT NOT NULL CONSTRAINT FK_Anagrafica_CalendarioCentroDiLavoro_turno_id REFERENCES Anagrafica.Turno (turno_id),
		dataora_inizio DATETIME2 NOT NULL,
		dataora_fine DATETIME2 NOT NULL
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_codice ON Anagrafica.CalendarioCentroDiLavoro (centrodilavoro_id, data_turno, turno_id);

END;
GO

/**
 * @table Anagrafica.Operatore
 * @description Anagrafica operatori
*/

--DROP TABLE Anagrafica.Operatore;
GO

IF OBJECT_ID(N'Anagrafica.Operatore', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.Operatore (
		operatore_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_Operatore PRIMARY KEY CLUSTERED,
		codice NVARCHAR(20) NOT NULL,
		descrizione NVARCHAR(80) NOT NULL,
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_Operatore_is_attivo DEFAULT (0)
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_codice ON Anagrafica.Operatore (codice);

END;
GO

/**
 * @table Anagrafica.CausaleProduzione
 * @description Anagrafica causali di produzione
*/

--DROP TABLE Anagrafica.CausaleProduzione;
GO

IF OBJECT_ID(N'Anagrafica.CausaleProduzione', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.CausaleProduzione (
		causaleproduzione_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_CausaleProduzione PRIMARY KEY CLUSTERED,
		codice NVARCHAR(20) NOT NULL,
		descrizione NVARCHAR(80) NOT NULL,
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_CausaleProduzione_is_attivo DEFAULT (0)
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_codice ON Anagrafica.CausaleProduzione (codice);

END;
GO

/**
 * @table Anagrafica.CambioStatoProduzione
 * @description Anagrafica causali di produzione
*/

--DROP TABLE Anagrafica.CambioStatoProduzione;
GO

IF OBJECT_ID(N'Anagrafica.CambioStatoProduzione', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.CambioStatoProduzione (
		cambiostatoproduzione_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_CambioStatoProduzione PRIMARY KEY CLUSTERED,
		statoproduzione_id_inizio INT NOT NULL CONSTRAINT FK_Anagrafica_CambioStatoProduzione_statoproduzione_id_inizio FOREIGN KEY REFERENCES Anagrafica.StatoProduzione (statoproduzione_id),
		statoproduzione_id_fine INT NOT NULL CONSTRAINT FK_Anagrafica_CambioStatoProduzione_statoproduzione_id_fine FOREIGN KEY REFERENCES Anagrafica.StatoProduzione (statoproduzione_id),
		causaleproduzione_id INT NOT NULL CONSTRAINT FK_Anagrafica_CambioStatoProduzione_causaleproduzione_id FOREIGN KEY REFERENCES Anagrafica.CausaleProduzione (causaleproduzione_id),
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_CambioStatoProduzione_is_attivo DEFAULT (0)
	);

END;
GO

/**
 * @table Anagrafica.Cliente
 * @description Anagrafica clienti (importazione dal gestionale)
*/

--DROP TABLE Anagrafica.Cliente;
GO

IF OBJECT_ID(N'Anagrafica.Cliente', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.Cliente (
		cliente_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_Cliente PRIMARY KEY CLUSTERED,
		codice NVARCHAR(20) NOT NULL,
		ragione_sociale NVARCHAR(80) NOT NULL,
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_Cliente_is_attivo DEFAULT (0)
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_codice ON Anagrafica.Cliente (codice);

END;
GO

/**
 * @table Anagrafica.UnitaDiMisura
 * @description Anagrafica unità di misura
*/

--DROP TABLE Anagrafica.UnitaDiMisura;
GO

IF OBJECT_ID(N'Anagrafica.UnitaDiMisura', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.UnitaDiMisura (
		unitadimisura_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_UnitaDiMisura PRIMARY KEY CLUSTERED,
		codice NVARCHAR(20) NOT NULL,
		descrizione NVARCHAR(80) NOT NULL,
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_UnitaDiMisura_is_attivo DEFAULT (0)
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_codice ON Anagrafica.UnitaDiMisura (codice);

END;
GO

/**
 * @table Anagrafica.Articolo
 * @description Anagrafica articoli (importazione dal gestionale)
*/

--DROP TABLE Anagrafica.Articolo;
GO

IF OBJECT_ID(N'Anagrafica.Articolo', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.Articolo (
		articolo_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_Articolo PRIMARY KEY CLUSTERED,
		codice NVARCHAR(20) NOT NULL,
		descrizione NVARCHAR(80) NOT NULL,
		unitadimisura_id INT NOT NULL CONSTRAINT FK_Anagrafica_Articolo_unitadimisura_id FOREIGN KEY REFERENCES Anagrafica.UnitaDiMisura (unitadimisura_id),
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_Articolo_is_attivo DEFAULT (0)
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_codice ON Anagrafica.Articolo (codice);

END;
GO

/**
 * @table Anagrafica.ArticoloVersione
 * @description Versionamento articoli
*/

--DROP TABLE Anagrafica.ArticoloVersione;
GO

IF OBJECT_ID(N'Anagrafica.ArticoloVersione', N'U') IS NULL
BEGIN

	CREATE TABLE Anagrafica.ArticoloVersione (
		articoloversione_id INT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Anagrafica_ArticoloVersione PRIMARY KEY CLUSTERED,
		articolo_id INT NOT NULL CONSTRAINT FK_Anagrafica_ArticoloVersione_articolo_id FOREIGN KEY REFERENCES Anagrafica.Articolo (articolo_id),
		codice NVARCHAR(20) NOT NULL,
		descrizione NVARCHAR(80) NOT NULL,
		is_attivo BIT NOT NULL CONSTRAINT DFT_Anagrafica_ArticoloVersione_is_attivo DEFAULT (0)
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Anagrafica_ArticoloVersione_codice ON Anagrafica.ArticoloVersione (articolo_id, codice);

END;
GO

/*** Anagrafica: Fine ***/

/*** Produzione: Inizio ***/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = N'Produzione')
BEGIN
	EXEC ('CREATE SCHEMA Produzione AUTHORIZATION dbo;'); -- Dati di produzione (ordini, lotti, fasi, ecc.)
END;
GO

/**
 * @table Produzione.OrdiniProduzione
 * @description Ordini di produzione (importazione dal gestionale)
*/

--DROP TABLE Produzione.OrdiniProduzione;
GO

IF OBJECT_ID(N'Produzione.OrdiniProduzione', N'U') IS NULL
BEGIN

	CREATE TABLE Produzione.OrdiniProduzione (
		ordiniproduzione_id BIGINT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Produzione_OrdiniProduzione PRIMARY KEY CLUSTERED,
		codice NVARCHAR(20) NOT NULL,
		cliente_id INT NOT NULL CONSTRAINT FK_Produzione_OrdiniProduzione_cliente_id FOREIGN KEY REFERENCES Anagrafica.Cliente (cliente_id),
		data_consegna DATE NOT NULL
	);

	CREATE UNIQUE NONCLUSTERED INDEX IX_Produzione_OrdiniProduzione_codice ON Produzione.OrdiniProduzione (codice);

END;
GO

/**
 * @table Produzione.LottiProduzione
 * @description Lotti di produzione (importazione dal gestionale)
*/

--DROP TABLE Produzione.LottiProduzione;
GO

IF OBJECT_ID(N'Produzione.LottiProduzione', N'U') IS NULL
BEGIN

	CREATE TABLE Produzione.LottiProduzione (
		lottiproduzione_id BIGINT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Produzione_LottiProduzione PRIMARY KEY CLUSTERED,
		ordiniproduzione_id BIGINT NOT NULL CONSTRAINT FK_Produzione_LottiProduzione_ordiniproduzione_id REFERENCES Produzione.OrdiniProduzione (ordiniproduzione_id),
		articoloversione_id INT NOT NULL CONSTRAINT FK_Produzione_LottiProduzione_articoloversione_id REFERENCES Anagrafica.ArticoloVersione (articoloversione_id),
		--articolo_id INT NOT NULL CONSTRAINT FK_Produzione_LottiProduzione_articolo_id REFERENCES Anagrafica.Articolo (articolo_id),
		qta_richiesta DECIMAL(10, 2) NOT NULL,
		qta_prodotta DECIMAL(10, 2) NULL,
		qta_scartata DECIMAL(10, 2) NULL
	);

END;
GO

/**
 * @table Produzione.PrelevamentiProduzione
 * @description Prelevamenti di produzione (operatività)
*/

--DROP TABLE Produzione.PrelevamentiProduzione;
GO

IF OBJECT_ID(N'Produzione.PrelevamentiProduzione', N'U') IS NULL
BEGIN

	CREATE TABLE Produzione.PrelevamentiProduzione (
		prelevamentiproduzione_id BIGINT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Produzione_PrelevamentiProduzione PRIMARY KEY CLUSTERED,
		operatore_id INT NOT NULL CONSTRAINT FK_Produzione_PrelevamentiProduzione_operatore_id REFERENCES Anagrafica.Operatore (operatore_id),
		lottiproduzione_id BIGINT NOT NULL CONSTRAINT FK_Produzione_PrelevamentiProduzione_lottiproduzione_id REFERENCES Produzione.LottiProduzione (lottiproduzione_id),
		dataora DATETIME2 NOT NULL CONSTRAINT DFT_Produzione_PrelevamentiProduzione_dataora DEFAULT (CURRENT_TIMESTAMP),
		qta_prelevata DECIMAL(10, 2) NULL
	);

END;
GO

/**
 * @table Produzione.FasiProduzione
 * @description Fasi di produzione (operatività)
*/

--DROP TABLE Produzione.FasiProduzione;
GO

IF OBJECT_ID(N'Produzione.FasiProduzione', N'U') IS NULL
BEGIN

	CREATE TABLE Produzione.FasiProduzione (
		fasiproduzione_id BIGINT NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Produzione_FasiProduzione PRIMARY KEY CLUSTERED,
		--centrodilavoro_id INT NOT NULL CONSTRAINT FK_Produzione_FasiProduzione_centrodilavoro_id REFERENCES Anagrafica.CentroDiLavoro (centrodilavoro_id),
		lavorazionecentrodilavoro_id INT NOT NULL CONSTRAINT FK_Produzione_FasiProduzione_lavorazionecentrodilavoro_id FOREIGN KEY REFERENCES Anagrafica.LavorazioneCentroDiLavoro (lavorazionecentrodilavoro_id),
		operatore_id INT NOT NULL CONSTRAINT FK_Produzione_FasiProduzione_operatore_id REFERENCES Anagrafica.Operatore (operatore_id),
		lottiproduzione_id BIGINT NOT NULL CONSTRAINT FK_Produzione_FasiProduzione_lottiproduzione_id REFERENCES Produzione.LottiProduzione (lottiproduzione_id),
		lavorazione_id INT NOT NULL CONSTRAINT FK_Produzione_FasiProduzione_lavorazione_id REFERENCES Anagrafica.Lavorazione (lavorazione_id),
		dataora_inizio DATETIME2 NOT NULL CONSTRAINT DFT_Produzione_FasiProduzione_dataora_inizio DEFAULT (CURRENT_TIMESTAMP),
		dataora_fine DATETIME2 NULL,
		--statoproduzione_id INT NOT NULL CONSTRAINT FK_Produzione_FasiProduzione_statoproduzione_id REFERENCES Anagrafica.StatoProduzione (statoproduzione_id),
		statoproduzione_id INT NULL,
		--causaleproduzione_id INT NOT NULL CONSTRAINT FK_Produzione_FasiProduzione_causaleproduzione_id REFERENCES Anagrafica.CausaleProduzione (causaleproduzione_id),
		causaleproduzione_id INT NULL,
		is_finale BIT NOT NULL CONSTRAINT DFT_Produzione_FasiProduzione_is_finale DEFAULT (0),
		qta_prodotta DECIMAL(10, 2) NULL,
		qta_scartata DECIMAL(10, 2) NULL
	);

END;
GO

/*** Produzione: Fine ***/
