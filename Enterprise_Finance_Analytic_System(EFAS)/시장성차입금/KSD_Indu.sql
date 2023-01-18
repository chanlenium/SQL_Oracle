/***********************************
 * 기간산업 업종별 시장성 차입금 현황 (대/중소/중견, 차입금전체(0)/일반회사채(1)/단기사채(2)/CP(3)) - 화면정의서 p.48
 ***********************************/
-- (Step1) 기간산업 업종별 시장성 차입금 현월, 전월, 전년동월 데이터 추출을 위한 임시테이블(temp_KSD_INDU_TB) 생성
DROP TABLE IF EXISTS temp_KSD_INDU_TB;
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	t.EFAS,
	SUBSTR(t.SEC_ACCT_CD, 1, 1) as KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS, t.SEC_ACCT_CD) as SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS, t.SEC_ACCT_CD) as SEC_BAL
	INTO temp_KSD_INDU_TB
FROM 
	KSD_InfraStandBy t;
	
INSERT INTO temp_KSD_INDU_TB
SELECT DISTINCT
	t.GG_YM,
	'0',	-- 전 기업 BIZ_SIZE '0'코드 할당
	t.EFAS,
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS, t.KSD_GBN) as SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.EFAS, t.KSD_GBN) as SEC_BAL
FROM
	temp_KSD_INDU_TB t;

DROP TABLE IF EXISTS temp_KSD_INDU;
SELECT 
	t.*,
	CASE -- 전월
		WHEN SUBSTR(t.GG_YM, 5, 2) = '01'	-- 1월인 경우 
		THEN REPLACE(CONCAT(TO_CHAR(SUBSTR(t.GG_YM, 1, 4) - 1, '0000'), '12'), ' ', '')
		ELSE REPLACE(CONCAT(SUBSTR(t.GG_YM, 1, 4), TO_CHAR(SUBSTR(t.GG_YM, 5, 2) - 1, '00')), ' ', '')
	END as prevMM,
	REPLACE(CONCAT(TO_CHAR(SUBSTR(t.GG_YM, 1, 4) - 1, '0000'), TO_CHAR(SUBSTR(t.GG_YM, 5, 2))), ' ', '') as prevYY
	INTO temp_KSD_INDU
FROM 
	temp_KSD_INDU_TB t;
DROP TABLE IF EXISTS temp_KSD_INDU_TB;

-- (Step2) 기간산업 업종별 시장성차입금 현월, 전월, 전년동월 데이터 추출
DROP TABLE IF EXISTS RESULT_KSD_Infra_BIZSIZE_SEC_AMT;
SELECT 
	t10.GG_YM,
	t10.BIZ_SIZE,	-- 기업규모(전기업: 0, 대기업: 1, 중소기업: 2, 중견기업: 3)
	t10.EFAS,
	t10.KSD_GBN,	-- 시장성차입금 구분(회사채(1)/단기사채(2)/CP(3))
	t10.SEC_AMT,	-- 현월 발행액
	t10.prevMM_SEC_AMT,	-- 전월 발행액
	t20.SEC_AMT as prevYY_SEC_AMT,	-- 전년동월 발행액
	t10.SEC_BAL,	-- 현월 잔액
	t10.prevMM_SEC_BAL,	-- 전월 잔액
	t20.SEC_BAL as prevYY_SEC_BAL	-- 전년동월 잔액
	INTO RESULT_KSD_Infra_BIZSIZE_SEC_AMT
FROM
	(
	SELECT 
		t1.*,
		t2.SEC_AMT as prevMM_SEC_AMT,
		t2.SEC_BAL as prevMM_SEC_BAL
	FROM temp_KSD_INDU t1
		LEFT JOIN temp_KSD_INDU t2
		ON
			t1.prevMM = t2.GG_YM 
			AND t1.BIZ_SIZE = t2.BIZ_SIZE
			AND t1.EFAS = t2.EFAS
			AND t1.KSD_GBN = t2.KSD_GBN
	ORDER BY t1.GG_YM
	) t10
	LEFT JOIN temp_KSD_INDU t20
	ON 
		t10.prevYY = t20.GG_YM
		AND t10.BIZ_SIZE = t20.BIZ_SIZE
		AND t10.EFAS = t20.EFAS
		AND t10.KSD_GBN = t20.KSD_GBN
ORDER BY
	t10.GG_YM, t10.BIZ_SIZE, t10.EFAS, t10.KSD_GBN;

-- (Step3) 기간산업 업종별 시장성차입금 합계 추가
INSERT INTO RESULT_KSD_Infra_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	t.EFAS,
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as prevYY_SEC_BAL
FROM
	RESULT_KSD_Infra_BIZSIZE_SEC_AMT t;

-- (Step4) 기간산업 전산업 시장성차입금(일반회사채/단기사채/CP) 데이터 추가
INSERT INTO RESULT_KSD_Infra_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	'00',	-- 전산업은 '99'코드 할당
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevYY_SEC_BAL
FROM
	(SELECT * FROM RESULT_KSD_Infra_BIZSIZE_SEC_AMT WHERE KSD_GBN <> '0') t;

-- (Step5) 기간산업 전산업 시장성차입금 합계 추가
INSERT INTO RESULT_KSD_Infra_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	'00',	-- 전산업은 '99'코드 할당
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevYY_SEC_BAL
FROM
	(SELECT * FROM RESULT_KSD_Infra_BIZSIZE_SEC_AMT WHERE KSD_GBN <> '0' AND EFAS <> '00') t;





/***********************************
 * 신산업 업종별 시장성 차입금 현황 (대/중소/중견, 차입금전체(0)/일반회사채(1)/단기사채(2)/CP(3)) - 화면정의서 p.48
 ***********************************/
-- (Step1) 신산업 업종별 시장성 차입금 현월, 전월, 전년동월 데이터 추출을 위한 임시테이블(temp_KSD_INDU_TB) 생성
DROP TABLE IF EXISTS temp_KSD_INDU_TB;
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	t.NEW_INDU_CODE,
	SUBSTR(t.SEC_ACCT_CD, 1, 1) as KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE, t.SEC_ACCT_CD) as SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE, t.SEC_ACCT_CD) as SEC_BAL
	INTO temp_KSD_INDU_TB
FROM 
	KSD_NewInduStandBy t;
	
INSERT INTO temp_KSD_INDU_TB
SELECT DISTINCT
	t.GG_YM,
	'0',	-- 전 기업 BIZ_SIZE '0'코드 할당
	t.NEW_INDU_CODE,
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE, t.KSD_GBN) as SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE, t.KSD_GBN) as SEC_BAL
FROM
	temp_KSD_INDU_TB t;

DROP TABLE IF EXISTS temp_KSD_INDU;
SELECT 
	t.*,
	CASE -- 전월
		WHEN SUBSTR(t.GG_YM, 5, 2) = '01'	-- 1월인 경우 
		THEN REPLACE(CONCAT(TO_CHAR(SUBSTR(t.GG_YM, 1, 4) - 1, '0000'), '12'), ' ', '')
		ELSE REPLACE(CONCAT(SUBSTR(t.GG_YM, 1, 4), TO_CHAR(SUBSTR(t.GG_YM, 5, 2) - 1, '00')), ' ', '')
	END as prevMM,
	REPLACE(CONCAT(TO_CHAR(SUBSTR(t.GG_YM, 1, 4) - 1, '0000'), TO_CHAR(SUBSTR(t.GG_YM, 5, 2))), ' ', '') as prevYY
	INTO temp_KSD_INDU
FROM 
	temp_KSD_INDU_TB t;
DROP TABLE IF EXISTS temp_KSD_INDU_TB;

-- (Step2) 신산업 업종별 시장성차입금 현월, 전월, 전년동월 데이터 추출
DROP TABLE IF EXISTS RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT;
SELECT 
	t10.GG_YM,
	t10.BIZ_SIZE,	-- 기업규모(전기업: 0, 대기업: 1, 중소기업: 2, 중견기업: 3)
	t10.NEW_INDU_CODE,
	t10.KSD_GBN,	-- 시장성차입금 구분(회사채(1)/단기사채(2)/CP(3))
	t10.SEC_AMT,	-- 현월 발행액
	t10.prevMM_SEC_AMT,	-- 전월 발행액
	t20.SEC_AMT as prevYY_SEC_AMT,	-- 전년동월 발행액
	t10.SEC_BAL,	-- 현월 잔액
	t10.prevMM_SEC_BAL,	-- 전월 잔액
	t20.SEC_BAL as prevYY_SEC_BAL	-- 전년동월 잔액
	INTO RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT
FROM
	(
	SELECT 
		t1.*,
		t2.SEC_AMT as prevMM_SEC_AMT,
		t2.SEC_BAL as prevMM_SEC_BAL
	FROM temp_KSD_INDU t1
		LEFT JOIN temp_KSD_INDU t2
		ON
			t1.prevMM = t2.GG_YM 
			AND t1.BIZ_SIZE = t2.BIZ_SIZE
			AND t1.NEW_INDU_CODE = t2.NEW_INDU_CODE
			AND t1.KSD_GBN = t2.KSD_GBN
	ORDER BY t1.GG_YM
	) t10
	LEFT JOIN temp_KSD_INDU t20
	ON 
		t10.prevYY = t20.GG_YM
		AND t10.BIZ_SIZE = t20.BIZ_SIZE
		AND t10.NEW_INDU_CODE = t20.NEW_INDU_CODE
		AND t10.KSD_GBN = t20.KSD_GBN
ORDER BY
	t10.GG_YM, t10.BIZ_SIZE, t10.NEW_INDU_CODE, t10.KSD_GBN;

-- (Step3) 신산업 업종별 시장성차입금 합계 추가
INSERT INTO RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	t.NEW_INDU_CODE,
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as prevYY_SEC_BAL
FROM
	RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT t;

-- (Step4) 신산업 전산업 시장성차입금(일반회사채/단기사채/CP) 데이터 추가
INSERT INTO RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	'00',	-- 전산업은 '99'코드 할당
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevYY_SEC_BAL
FROM
	(SELECT * FROM RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT WHERE KSD_GBN <> '0') t;

-- (Step5) 신산업 전산업 시장성차입금 합계 추가
INSERT INTO RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	'00',	-- 전산업은 '99'코드 할당
	'0',	-- 차입금 종류별 합계는 '0' 코드 할당
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevYY_SEC_BAL
FROM
	(SELECT * FROM RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT WHERE KSD_GBN <> '0' AND NEW_INDU_CODE <> '00') t;





-- 결과 조회 (시장성 차입금 산업별 분석 - 업종별 시장성 차입금 현황: 기간산업)
SELECT * FROM RESULT_KSD_Infra_BIZSIZE_SEC_AMT ORDER BY GG_YM, BIZ_SIZE, EFAS, KSD_GBN;
-- 결과 조회 (시장성 차입금 산업별 분석 - 업종별 시장성 차입금 현황: 신산업)
SELECT * FROM RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT ORDER BY GG_YM, BIZ_SIZE, NEW_INDU_CODE, KSD_GBN;
