CREATE TABLE Anagrafica_StatoProduzione (
	statoproduzione_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	codice NVARCHAR(20) NOT NULL,
	descrizione NVARCHAR(80) NOT NULL,
	sequenza SMALLINT NOT NULL,
	is_attivo TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE Anagrafica_Lavorazione (
	lavorazione_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	codice NVARCHAR(20) NOT NULL,
	descrizione NVARCHAR(80) NOT NULL,
	tipo_durata CHAR(1) NOT NULL DEFAULT 'F',
	is_attivo TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE Anagrafica_CentroDiLavoro (
	centrodilavoro_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	codice NVARCHAR(20) NOT NULL,
	descrizione NVARCHAR(80) NOT NULL,
	is_attivo TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE Anagrafica_LavorazioneCentroDiLavoro (
	lavorazionecentrodilavoro_id_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	lavorazione_id INT NOT NULL REFERENCES Anagrafica_Lavorazione (lavorazione_id),
	centrodilavoro_id INT NOT NULL REFERENCES Anagrafica_CentroDiLavoro (centrodilavoro_id),
	is_attivo BIT NOT NULL DEFAULT 0
);

CREATE TABLE Anagrafica_Turno (
	turno_id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	codice NVARCHAR(20) NOT NULL,
	descrizione NVARCHAR(80) NOT NULL,
	dataora_inizio DATETIME(6) NOT NULL,
	durata_secondi INT NOT NULL,
	is_attivo TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE Anagrafica_CalendarioCentroDiLavoro (
	calendariocentrodilavoro_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	centrodilavoro_id INT NOT NULL REFERENCES Anagrafica_CentroDiLavoro (centrodilavoro_id),
	data_turno DATE NOT NULL,
	turno_id TINYINT NOT NULL REFERENCES Anagrafica_Turno (turno_id),
	dataora_inizio DATETIME NOT NULL,
	dataora_fine DATETIME NOT NULL
);

CREATE TABLE Anagrafica_Operatore (
	operatore_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	codice NVARCHAR(20) NOT NULL,
	descrizione NVARCHAR(80) NOT NULL,
	is_attivo TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE Anagrafica_CausaleProduzione (
	causaleproduzione_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	codice NVARCHAR(20) NOT NULL,
	descrizione NVARCHAR(80) NOT NULL,
	is_attivo TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE Anagrafica_CambioStatoProduzione (
	cambiostatoproduzione_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	statoproduzione_id_inizio INT NOT NULL REFERENCES Anagrafica_StatoProduzione (statoproduzione_id),
	statoproduzione_id_fine INT NOT NULL REFERENCES Anagrafica_StatoProduzione (statoproduzione_id),
	causaleproduzione_id INT NOT NULL REFERENCES Anagrafica_CausaleProduzione (causaleproduzione_id),
	is_attivo TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE Anagrafica_Cliente (
	cliente_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	codice NVARCHAR(20) NOT NULL,
	ragione_sociale NVARCHAR(80) NOT NULL,
	is_attivo TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE Anagrafica_UnitaDiMisura (
	unitadimisura_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	codice NVARCHAR(20) NOT NULL,
	descrizione NVARCHAR(80) NOT NULL,
	is_attivo TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE Anagrafica_Articolo (
	articolo_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	codice NVARCHAR(20) NOT NULL,
	descrizione NVARCHAR(80) NOT NULL,
	unitadimisura_id INT NOT NULL REFERENCES Anagrafica_UnitaDiMisura (unitadimisura_id),
	is_attivo TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE Anagrafica_ArticoloVersione (
	articoloversione_id INT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	articolo_id INT NOT NULL REFERENCES Anagrafica_Articolo (articolo_id),
	codice NVARCHAR(20) NOT NULL,
	descrizione NVARCHAR(80) NOT NULL,
	is_attivo TINYINT NOT NULL DEFAULT 0
);

CREATE TABLE Produzione_OrdiniProduzione (
	ordiniproduzione_id BIGINT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	codice NVARCHAR(20) NOT NULL,
	cliente_id INT NOT NULL REFERENCES Anagrafica_Cliente (cliente_id),
	data_consegna DATE NOT NULL
);

CREATE TABLE Produzione_LottiProduzione (
	lottiproduzione_id BIGINT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	ordiniproduzione_id BIGINT NOT NULL REFERENCES Produzione_OrdiniProduzione (ordiniproduzione_id),
	articoloversione_id INT NOT NULL REFERENCES Anagrafica_ArticoloVersione (articoloversione_id),
	articolo_id INT NOT NULL REFERENCES Anagrafica_Articolo (articolo_id),
	qta_richiesta DECIMAL(10, 2) NOT NULL
);

CREATE TABLE Produzione_PrelevamentiProduzione (
	prelevamentiproduzione_id BIGINT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	operatore_id INT NOT NULL REFERENCES Anagrafica_Operatore (operatore_id),
	lottiproduzione_id BIGINT NOT NULL REFERENCES Produzione_LottiProduzione (lottiproduzione_id),
	dataora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	qta_prelevata DECIMAL(10, 2) NULL
);

CREATE TABLE Produzione_FasiProduzione (
	fasiproduzione_id BIGINT NOT NULL AUTO_INCREMENT  PRIMARY KEY,
	centrodilavoro_id INT NOT NULL REFERENCES Anagrafica_CentroDiLavoro (centrodilavoro_id),
	operatore_id INT NOT NULL REFERENCES Anagrafica_Operatore (operatore_id),
	lottiproduzione_id BIGINT NOT NULL REFERENCES Produzione_LottiProduzione (lottiproduzione_id),
	dataora_inizio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	dataora_fine DATETIME NULL,
	-- statoproduzione_id INT NOT NULL CONSTRAINT FK_Produzione_FasiProduzione_statoproduzione_id REFERENCES Anagrafica_StatoProduzione (statoproduzione_id),
	statoproduzione_id INT NULL,
	-- causaleproduzione_id INT NOT NULL CONSTRAINT FK_Produzione_FasiProduzione_causaleproduzione_id REFERENCES Anagrafica_CausaleProduzione (causaleproduzione_id),
	causaleproduzione_id INT NULL,
	qta_prodotta DECIMAL(10, 2) NULL,
	qta_scartata DECIMAL(10, 2) NULL
);
