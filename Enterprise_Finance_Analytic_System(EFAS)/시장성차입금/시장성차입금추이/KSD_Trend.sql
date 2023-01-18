/***********************************
 * 시장성 차입금 추이 - 기간산업 시장성 차입금 발행액(전체, 일반회사채, CP, 단기사채) - 화면정의서 p.43
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_Infra_SEC_AMT;
-- (Step1) 각 산업별, 차입금 종류별 발행액
SELECT DISTINCT	
	t0.GG_YM,
	t0.EFAS,
	SUBSTR(t0.SEC_ACCT_CD, 1, 1) as KSD_GBN,	--(일반회사채:1, 단기사채:2, CP:3)
	SUM(t0.SEC_AMT) OVER (PARTITION BY t0.GG_YM, t0.EFAS, SUBSTR(t0.SEC_ACCT_CD, 1, 1)) as SEC_AMT
	INTO RESULT_KSD_Infra_SEC_AMT
FROM
	KSD_InfraStandBy t0;

-- (Step2) 각 산업 차입금 종류별 발행액 합계 추가
INSERT INTO RESULT_KSD_Infra_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.EFAS,
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS)
FROM
	RESULT_KSD_Infra_SEC_AMT t;

-- (Step3) 전산업 차입금 종류별 발행액 추가
INSERT INTO RESULT_KSD_Infra_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.KSD_GBN)
FROM
	(SELECT * FROM RESULT_KSD_Infra_SEC_AMT WHERE KSD_GBN <> '0') t;

-- (Step4) 전산업 차입금 종류별 발행액 합계 추가
INSERT INTO RESULT_KSD_Infra_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_Infra_SEC_AMT WHERE KSD_GBN <> '0' AND EFAS <> '00') t;





/***********************************
 * 시장성 차입금 추이 - 신산업 시장성 차입금 발행액(전체, 일반회사채, CP, 단기사채) - 화면정의서 p.43
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_NewIndu_SEC_AMT;
-- (Step1) 각 산업별, 차입금 종류별 잔액
SELECT DISTINCT	
	t0.GG_YM,
	t0.NEW_INDU_CODE,
	SUBSTR(t0.SEC_ACCT_CD, 1, 1) as KSD_GBN,	--(일반회사채:1, 단기사채:2, CP:3)
	SUM(t0.SEC_AMT) OVER (PARTITION BY t0.GG_YM, t0.NEW_INDU_CODE, SUBSTR(t0.SEC_ACCT_CD, 1, 1)) as SEC_AMT
	INTO RESULT_KSD_NewIndu_SEC_AMT
FROM
	KSD_NewInduStandBy t0;

-- (Step2) 각 산업 차입금 종류별 잔액 합계 추가
INSERT INTO RESULT_KSD_NewIndu_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.NEW_INDU_CODE,
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE)
FROM
	RESULT_KSD_NewIndu_SEC_AMT t;

-- (Step3) 전산업 차입금 종류별 잔액 추가
INSERT INTO RESULT_KSD_NewIndu_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.KSD_GBN)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_SEC_AMT WHERE KSD_GBN <> '0') t;

-- (Step4) 전산업 차입금 종류별 잔액 합계 추가
INSERT INTO RESULT_KSD_NewIndu_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_SEC_AMT WHERE KSD_GBN <> '0' AND NEW_INDU_CODE <> '00') t;





/***********************************
 * 시장성 차입금 추이 - 기간산업 시장성 차입금 잔액(전체, 일반회사채, CP, 단기사채) - 화면정의서 p.44
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_Infra_SEC_BAL;
-- (Step1) 각 산업별, 차입금 종류별 발행액
SELECT DISTINCT	
	t0.GG_YM,
	t0.EFAS,
	SUBSTR(t0.SEC_ACCT_CD, 1, 1) as KSD_GBN,	--(일반회사채:1, 단기사채:2, CP:3)
	SUM(t0.SEC_BAL) OVER (PARTITION BY t0.GG_YM, t0.EFAS, SUBSTR(t0.SEC_ACCT_CD, 1, 1)) as SEC_BAL
	INTO RESULT_KSD_Infra_SEC_BAL
FROM
	KSD_InfraStandBy t0;

-- (Step2) 각 산업 차입금 종류별 발행액 합계 추가
INSERT INTO RESULT_KSD_Infra_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	t.EFAS,
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.EFAS)
FROM
	RESULT_KSD_Infra_SEC_BAL t;

-- (Step3) 전산업 차입금 종류별 발행액 추가
INSERT INTO RESULT_KSD_Infra_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	t.KSD_GBN,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.KSD_GBN)
FROM
	(SELECT * FROM RESULT_KSD_Infra_SEC_BAL WHERE KSD_GBN <> '0') t;

-- (Step4) 전산업 차입금 종류별 발행액 합계 추가
INSERT INTO RESULT_KSD_Infra_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_Infra_SEC_BAL WHERE KSD_GBN <> '0' AND EFAS <> '00') t;





/***********************************
 * 시장성 차입금 추이 - 신산업 시장성 차입금 잔액(전체, 일반회사채, CP, 단기사채) - 화면정의서 p.44
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_NewIndu_SEC_BAL;
-- (Step1) 각 산업별, 차입금 종류별 잔액
SELECT DISTINCT	
	t0.GG_YM,
	t0.NEW_INDU_CODE,
	SUBSTR(t0.SEC_ACCT_CD, 1, 1) as KSD_GBN,	--(일반회사채:1, 단기사채:2, CP:3)
	SUM(t0.SEC_BAL) OVER (PARTITION BY t0.GG_YM, t0.NEW_INDU_CODE, SUBSTR(t0.SEC_ACCT_CD, 1, 1)) as SEC_BAL
	INTO RESULT_KSD_NewIndu_SEC_BAL
FROM
	KSD_NewInduStandBy t0;

-- (Step2) 각 산업 차입금 종류별 잔액 합계 추가
INSERT INTO RESULT_KSD_NewIndu_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	t.NEW_INDU_CODE,
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE)
FROM
	RESULT_KSD_NewIndu_SEC_BAL t;

-- (Step3) 전산업 차입금 종류별 잔액 추가
INSERT INTO RESULT_KSD_NewIndu_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	t.KSD_GBN,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.KSD_GBN)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_SEC_BAL WHERE KSD_GBN <> '0') t;

-- (Step4) 전산업 차입금 종류별 잔액 합계 추가
INSERT INTO RESULT_KSD_NewIndu_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	'00',	-- 전산업은 '00'코드 할당
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_SEC_BAL WHERE KSD_GBN <> '0' AND NEW_INDU_CODE <> '00') t;





/***********************************
 * 시장성 차입금 추이 - 금융성 차입금 월별 발행액(전체금융채, 일반은행채, 할부금융채, 신용카드채, 기타 금융채) - 화면정의서 p.45
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_Infra_FIN_SEC_AMT;
-- (Step1) 금융보험업 금융채 종류별 발행액
SELECT DISTINCT	-- 금융채
	t0.GG_YM,
	t0.EFAS,
	t0.SEC_ACCT_CD as KSD_GBN,	
	SUM(t0.SEC_AMT) OVER (PARTITION BY t0.GG_YM, t0.EFAS, t0.SEC_ACCT_CD) as SEC_AMT
	INTO RESULT_KSD_Infra_FIN_SEC_AMT
FROM
	KSD_InfraStandBy t0
WHERE
	t0.EFAS = '55'	-- 금융보험업
	AND t0.SEC_ACCT_CD in ('11', '12', '13', '14', '15')	--(일반회사채: 11, 일반은행채: 12, 할부금융채:13, 신용카드채:14, 기타금융채:15)
ORDER BY
	t0.GG_YM, t0.SEC_ACCT_CD;
-- 결과 조회
SELECT * FROM RESULT_KSD_Infra_FIN_SEC_AMT ORDER BY GG_YM, KSD_GBN;

-- (Step2) 금융보험업 금융채 발행액 합계 추가
INSERT INTO RESULT_KSD_Infra_FIN_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.EFAS,
	'0',	-- 금융채 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS)
FROM
	RESULT_KSD_Infra_FIN_SEC_AMT t;





-- 결과 조회 (시장성 차입금 추이 - 시장성 차입금 발행액: 기간산업)
SELECT * FROM RESULT_KSD_Infra_SEC_AMT ORDER BY GG_YM, TO_NUMBER(EFAS, '00'), KSD_GBN;
-- 결과 조회 (시장성 차입금 추이 - 시장성 차입금 발행액: 신산업)
SELECT * FROM RESULT_KSD_NewIndu_SEC_AMT ORDER BY GG_YM, TO_NUMBER(NEW_INDU_CODE, '00'), KSD_GBN;
-- 결과 조회 (시장성 차입금 추이 - 시장성 차입금 잔액: 기간산업)
SELECT * FROM RESULT_KSD_Infra_SEC_BAL ORDER BY GG_YM, TO_NUMBER(EFAS, '00'), KSD_GBN;
-- 결과 조회 (시장성 차입금 추이 - 시장성 차입금 잔액: 신산업)
SELECT * FROM RESULT_KSD_NewIndu_SEC_BAL ORDER BY GG_YM, TO_NUMBER(NEW_INDU_CODE, '00'), KSD_GBN;
-- 결과 조회 (시장성 차입금 추이 - 금융성 차입금 발행액: 금융보험업에 한함)
SELECT * FROM RESULT_KSD_Infra_FIN_SEC_AMT ORDER BY GG_YM, KSD_GBN;
