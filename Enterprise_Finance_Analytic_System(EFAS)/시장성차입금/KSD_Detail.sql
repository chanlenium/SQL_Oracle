/***********************************
 * 시장성 차입금 세부현황 - 기간산업 회사채 만기별 발행 추이(전체, 단기채, 중기채, 장기채) - 화면정의서 p.46
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_Infra_MANGI_SEC_AMT;
-- (Step1) 각 산업별, 회사채 종류별(단기채/중기채/단기채) 발행액
SELECT DISTINCT	
	t0.GG_YM,
	t0.EFAS,
	t0.MANGI_GBN,
	SUM(t0.SEC_AMT) OVER (PARTITION BY t0.GG_YM, t0.EFAS, t0.MANGI_GBN) as SEC_AMT
	INTO RESULT_KSD_Infra_MANGI_SEC_AMT
FROM
	(
	SELECT 
		t.*,
		CAST(t.SEC_ISS_DT as DATE) as SEC_ISS_DT_D,
		CAST(t.SEC_MATU_DT as DATE) as SEC_MATU_DT_D,
		SEC_MATU_DT_D - SEC_ISS_DT_D as date_Diff,
		CASE -- 만기 구분
			WHEN date_Diff < 365 THEN '1'	-- 단기채(1)
			WHEN date_Diff BETWEEN 365 AND 365 * 5 THEN '2'	-- 중기채(2)
			WHEN date_Diff > 365 * 5 THEN '3'	-- 장기채(3)
		END as MANGI_GBN
	FROM 
		KSD_InfraStandBy t
	WHERE
		SUBSTR(t.SEC_ACCT_CD, 1, 1) = '1'	-- 일반회사채
	)t0;

-- (Step2) 각 산업별 일반회사채 발행액 합계 추가
INSERT INTO RESULT_KSD_Infra_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.EFAS,
	'0',	-- 차입금 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS)
FROM
	RESULT_KSD_Infra_MANGI_SEC_AMT t;

-- (Step3) 전산업 만기별(단기채/중기채/단기채) 일반회사채 발행액 추가
INSERT INTO RESULT_KSD_Infra_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	t.MANGI_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.MANGI_GBN)
FROM
	(SELECT * FROM RESULT_KSD_Infra_MANGI_SEC_AMT WHERE MANGI_GBN <> '0') t;

-- (Step4) 전산업 일반회사채 발행액 합계 추가
INSERT INTO RESULT_KSD_Infra_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	'0',	-- 차입금 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_Infra_MANGI_SEC_AMT WHERE MANGI_GBN <> '0' AND EFAS <> '00') t;





/***********************************
 * 시장성 차입금 세부현황 - 신산업 회사채 만기별 발행 추이(전체, 단기채, 중기채, 장기채) - 화면정의서 p.46
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_NewIndu_MANGI_SEC_AMT;
-- (Step1) 각 산업별, 회사채 종류별(단기채/중기채/단기채) 발행액
SELECT DISTINCT	
	t0.GG_YM,
	t0.NEW_INDU_CODE,
	t0.MANGI_GBN,
	SUM(t0.SEC_AMT) OVER (PARTITION BY t0.GG_YM, t0.NEW_INDU_CODE, t0.MANGI_GBN) as SEC_AMT
	INTO RESULT_KSD_NewIndu_MANGI_SEC_AMT
FROM
	(
	SELECT 
		t.*,
		CAST(t.SEC_ISS_DT as DATE) as SEC_ISS_DT_D,
		CAST(t.SEC_MATU_DT as DATE) as SEC_MATU_DT_D,
		SEC_MATU_DT_D - SEC_ISS_DT_D as date_Diff,
		CASE -- 만기 구분
			WHEN date_Diff < 365 THEN '1'	-- 단기채(1)
			WHEN date_Diff BETWEEN 365 AND 365 * 5 THEN '2'	-- 중기채(2)
			WHEN date_Diff > 365 * 5 THEN '3'	-- 장기채(3)
		END as MANGI_GBN
	FROM 
		KSD_NewInduStandBy t
	WHERE
		SUBSTR(t.SEC_ACCT_CD, 1, 1) = '1'	-- 일반회사채
	)t0;

-- (Step2) 각 산업별 일반회사채 발행액 합계 추가
INSERT INTO RESULT_KSD_NewIndu_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.NEW_INDU_CODE,
	'0',	-- 차입금 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE)
FROM
	RESULT_KSD_NewIndu_MANGI_SEC_AMT t;

-- (Step3) 전산업 만기별(단기채/중기채/단기채) 일반회사채 발행액 추가
INSERT INTO RESULT_KSD_NewIndu_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	t.MANGI_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.MANGI_GBN)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_MANGI_SEC_AMT WHERE MANGI_GBN <> '0') t;

-- (Step4) 전산업 일반회사채 발행액 합계 추가
INSERT INTO RESULT_KSD_NewIndu_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	'0',	-- 차입금 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_MANGI_SEC_AMT WHERE MANGI_GBN <> '0' AND NEW_INDU_CODE <> '00') t;





/***********************************
 * 시장성 차입금 세부현황 - 기간산업 CP/단기사채 유동성 현황(전체, ABCP, PF-ABCP, AB단기사채, PF-AB단기사채) - 화면정의서 p.47
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_Infra_CPSHORT_SEC_AMT;
-- (Step1) 각 산업별, CP(ABCP/PF-ABCP) 및 단기사채(AB단기사채/PF-AB단기사채) 종류별 발행액
SELECT DISTINCT	
	t.GG_YM,
	t.EFAS,
	t.SEC_ACCT_CD as CP_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS, t.SEC_ACCT_CD) as SEC_AMT	
	INTO RESULT_KSD_Infra_CPSHORT_SEC_AMT
FROM 
	KSD_InfraStandBy t
WHERE
	t.SEC_ACCT_CD in ('22', '23', '32', '33'); -- (AB단기사채: 22, PF-AB단기사채: 23, ABCP: 32, PF-ABCP: 33)

-- (Step2) 각 산업별 CP/단기사채 발행액 합계 추가
INSERT INTO RESULT_KSD_Infra_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.EFAS,
	'0',	-- 차입금 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS)
FROM
	RESULT_KSD_Infra_CPSHORT_SEC_AMT t;

-- (Step3) 전산업 CP(ABCP/PF-ABCP) 및 단기사채(AB단기사채/PF-AB단기사채) 종류별 발행액 추가
INSERT INTO RESULT_KSD_Infra_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	t.CP_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.CP_GBN)
FROM
	(SELECT * FROM RESULT_KSD_Infra_CPSHORT_SEC_AMT WHERE CP_GBN <> '0') t;

-- (Step4) 전산업 CP/단기사채 발행액 합계 추가
INSERT INTO RESULT_KSD_Infra_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	'0',	-- 차입금 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_Infra_CPSHORT_SEC_AMT WHERE CP_GBN <> '0' AND EFAS <> '00') t;





/***********************************
 * 시장성 차입금 세부현황 - 신산업 CP/단기사채 유동성 현황(전체, ABCP, PF-ABCP, AB단기사채, PF-AB단기사채) - 화면정의서 p.47
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_NewINDU_CPSHORT_SEC_AMT;
-- (Step1) 각 산업별, CP(ABCP/PF-ABCP) 및 단기사채(AB단기사채/PF-AB단기사채) 종류별 발행액
SELECT DISTINCT	
	t.GG_YM,
	t.NEW_INDU_CODE,
	t.SEC_ACCT_CD as CP_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE, t.SEC_ACCT_CD) as SEC_AMT	
	INTO RESULT_KSD_NewINDU_CPSHORT_SEC_AMT
FROM 
	KSD_NewInduStandBy t
WHERE
	t.SEC_ACCT_CD in ('22', '23', '32', '33'); -- (AB단기사채: 22, PF-AB단기사채: 23, ABCP: 32, PF-ABCP: 33)

-- (Step2) 각 산업별 CP/단기사채 발행액 합계 추가
INSERT INTO RESULT_KSD_NewINDU_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.NEW_INDU_CODE,
	'0',	-- 차입금 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE)
FROM
	RESULT_KSD_NewINDU_CPSHORT_SEC_AMT t;

-- (Step3) 전산업 CP(ABCP/PF-ABCP) 및 단기사채(AB단기사채/PF-AB단기사채) 종류별 발행액 추가
INSERT INTO RESULT_KSD_NewINDU_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	t.CP_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.CP_GBN)
FROM
	(SELECT * FROM RESULT_KSD_NewINDU_CPSHORT_SEC_AMT WHERE CP_GBN <> '0') t;

-- (Step4) 전산업 CP/단기사채 발행액 합계 추가
INSERT INTO RESULT_KSD_NewINDU_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	'0',	-- 차입금 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_NewINDU_CPSHORT_SEC_AMT WHERE CP_GBN <> '0' AND NEW_INDU_CODE <> '00') t;





-- 결과 조회 (시장성 차입금 세부현황 - 회사채 만기별 발행 추이: 기간산업)
SELECT * FROM RESULT_KSD_Infra_MANGI_SEC_AMT ORDER BY GG_YM, TO_NUMBER(EFAS, '00'), MANGI_GBN;
-- 결과 조회 (시장성 차입금 세부현황 - 회사채 만기별 발행 추이: 신산업)
SELECT * FROM RESULT_KSD_NewIndu_MANGI_SEC_AMT ORDER BY GG_YM, TO_NUMBER(NEW_INDU_CODE, '00'), MANGI_GBN;
-- 결과 조회 (시장성 차입금 세부현황 - CP/단기사채 유동화 현황: 기간산업)
SELECT * FROM RESULT_KSD_Infra_CPSHORT_SEC_AMT ORDER BY GG_YM, TO_NUMBER(EFAS, '00'), CP_GBN;
-- 결과 조회 (시장성 차입금 세부현황 - CP/단기사채 유동화 현황: 신산업)
SELECT * FROM RESULT_KSD_NewINDU_CPSHORT_SEC_AMT ORDER BY GG_YM, TO_NUMBER(NEW_INDU_CODE, '00'), CP_GBN;