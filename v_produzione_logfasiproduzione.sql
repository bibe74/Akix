CREATE OR REPLACE VIEW v_anagrafica_statofase
AS
SELECT
	10 AS statofase_id,
	'Fase attiva, macchina presidiata' AS statofase_descrizione,
	1 AS is_fase_produzione,
	0 AS is_fase_attrezzaggio
UNION ALL SELECT 20, 'Fase attiva, macchina non presidiata', 1, 0
UNION ALL SELECT 30, 'Pausa', 0, 0
UNION ALL SELECT 40, 'Attrezzaggio', 0, 1
UNION ALL SELECT 50, 'Terminata', 0, 0
UNION ALL SELECT 60, 'Lavorazione esterna', 0, 0;

CREATE OR REPLACE VIEW v_produzione_logfasiproduzione
AS
WITH LogFasiProduzione
AS (
	SELECT
		LFP.*,
		ROW_NUMBER() OVER (PARTITION BY LFP.fasiproduzione_id ORDER BY LFP.dataora_cambiostato) AS rn

	FROM produzione_logfasiproduzione LFP
	
	--
	-- Vedo solo le fasi con un logfase con stato 50 (Terminata)
	WHERE EXISTS (SELECT 1 FROM produzione_logfasiproduzione LFP1 WHERE LFP1.fasiproduzione_id = LFP.fasiproduzione_id AND LFP1.statofase_id = 50)
	--
),
LogFasiProduzioneConQtaProdotta
AS (
	SELECT
		LFP.logfasiproduzione_id,
	   LFP.fasiproduzione_id,
	   FP.lottiproduzione_id,
		ROW_NUMBER() OVER (PARTITION BY FP.lottiproduzione_id ORDER BY LFP.dataora_cambiostato DESC) AS rn
		
	FROM produzione_logfasiproduzione LFP
	INNER JOIN produzione_fasiproduzione FP ON FP.fasiproduzione_id = LFP.fasiproduzione_id
	WHERE LFP.statofase_id = 50 -- 50: Terminata
)
SELECT
	LFP.logfasiproduzione_id,
	LFP.fasiproduzione_id,
	LFP.operatore_id,
	AO.operatore_codice,
	AO.operatore_descrizione,
	LFP.rn,
	LFP.dataora_cambiostato,
   LFPNext.dataora_cambiostato AS dataora_cambiostato_Next,
   LFP.statofase_id,
	SF.statofase_descrizione,
	SF.is_fase_produzione,
	SF.is_fase_attrezzaggio,
	LP.lottiproduzione_id,
	LP.data_fine_produzione,
	CDL.centrodilavoro_codice,
	CDL.centrodilavoro_descrizione,
	FDB.numero AS fasedistintabase_numero,
	F.fornitore_ragione_sociale,
	A.articolo_codice,
	A.articolo_descrizione,

   TIMESTAMPDIFF(SECOND, LFP.dataora_cambiostato, LFPNext.dataora_cambiostato) AS durata_secondi,
	CASE WHEN LFPCQP.logfasiproduzione_id = LFP.logfasiproduzione_id THEN FP.qta_prodotta ELSE NULL END AS qta_prodotta,
	CASE WHEN LFPCQP.logfasiproduzione_id = LFP.logfasiproduzione_id THEN FP.qta_scartata ELSE NULL END AS qta_scartata
   
FROM LogFasiProduzione LFP
LEFT JOIN v_anagrafica_statofase SF ON SF.statofase_id = LFP.statofase_id
LEFT JOIN LogFasiProduzione LFPNext ON LFPNext.fasiproduzione_id = LFP.fasiproduzione_id AND LFPNext.rn = LFP.rn + 1
LEFT JOIN anagrafica_operatore AO ON AO.operatore_id = LFP.operatore_id
LEFT JOIN produzione_fasiproduzione FP ON FP.fasiproduzione_id = LFP.fasiproduzione_id
LEFT JOIN produzione_lottiproduzione LP ON LP.lottiproduzione_id = FP.lottiproduzione_id
LEFT JOIN anagrafica_centrodilavoro CDL ON CDL.centrodilavoro_id = FP.centrodilavoro_id
LEFT JOIN anagrafica_fase_distinta_base FDB ON FDB.id = FP.fasedistintabase_id
LEFT JOIN anagrafica_distinta_base DB ON DB.id = FDB.distinta_base_id
LEFT JOIN anagrafica_fornitore F ON F.fornitore_id = FP.fornitore_id
LEFT JOIN produzione_ordiniproduzione OP ON OP.ordiniproduzione_id = LP.ordiniproduzione_id
LEFT JOIN anagrafica_articolo A ON A.articolo_id = LP.articolo_id
LEFT JOIN LogFasiProduzioneConQtaProdotta LFPCQP ON LFPCQP.fasiproduzione_id = LFP.fasiproduzione_id
	AND LFPCQP.rn = 1
ORDER BY LFP.fasiproduzione_id,
	LFP.rn;

#SELECT * FROM v_produzione_logfasiproduzione ORDER BY fasiproduzione_id DESC, rn DESC;

#SELECT * FROM v_produzione_logfasiproduzione WHERE lottiproduzione_id = 918 AND articolo_codice = 'R@OILCA01314'

WITH LogFasiProduzione
AS (
	SELECT
		LFP.*,
		ROW_NUMBER() OVER (PARTITION BY FP.centrodilavoro_id ORDER BY LFP.dataora_cambiostato DESC) AS rn

	FROM produzione_logfasiproduzione LFP
	INNER JOIN produzione_fasiproduzione FP ON FP.fasiproduzione_id = LFP.fasiproduzione_id
	INNER JOIN anagrafica_centrodilavoro CDL ON CDL.centrodilavoro_id = FP.centrodilavoro_id
	WHERE LFP.dataora_cambiostato <= '2022-05-31 17:25:00'
		# AND CDL.centrodilavoro_id = 2
)
SELECT
	LFP.logfasiproduzione_id,
	LFP.fasiproduzione_id,
	LFP.operatore_id,
	AO.operatore_codice,
	AO.operatore_descrizione,
	LFP.rn,
	LFP.dataora_cambiostato,
   LFP.statofase_id,
	SF.statofase_descrizione,
	SF.is_fase_produzione,
	SF.is_fase_attrezzaggio,
	LP.lottiproduzione_id,
	LP.data_fine_produzione,
	CDL.centrodilavoro_codice,
	CDL.centrodilavoro_descrizione,
	FDB.numero AS fasedistintabase_numero,
	F.fornitore_ragione_sociale,
	A.articolo_codice,
	A.articolo_descrizione

FROM LogFasiProduzione LFP
LEFT JOIN v_anagrafica_statofase SF ON SF.statofase_id = LFP.statofase_id
LEFT JOIN anagrafica_operatore AO ON AO.operatore_id = LFP.operatore_id
LEFT JOIN produzione_fasiproduzione FP ON FP.fasiproduzione_id = LFP.fasiproduzione_id
LEFT JOIN produzione_lottiproduzione LP ON LP.lottiproduzione_id = FP.lottiproduzione_id
LEFT JOIN anagrafica_centrodilavoro CDL ON CDL.centrodilavoro_id = FP.centrodilavoro_id
LEFT JOIN anagrafica_fase_distinta_base FDB ON FDB.id = FP.fasedistintabase_id
LEFT JOIN anagrafica_distinta_base DB ON DB.id = FDB.distinta_base_id
LEFT JOIN anagrafica_fornitore F ON F.fornitore_id = FP.fornitore_id
LEFT JOIN produzione_ordiniproduzione OP ON OP.ordiniproduzione_id = LP.ordiniproduzione_id
LEFT JOIN anagrafica_articolo A ON A.articolo_id = LP.articolo_id
WHERE LFP.rn = 1
ORDER BY CDL.centrodilavoro_codice;
