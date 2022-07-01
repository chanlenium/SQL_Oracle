/***************************************************************************
 *                 개인사업자대출 기본테이블(BASIC_IND_BIZ_LOAN) 생성                            
 * 기업대출 기본테이블 생성 (대출 = 대출채권계(1901) + 대출채권CMA계정포함(5301) - 지급보증대지급금(1391))
 * 기업대출 테이블(CORP_BIZ_DATA) 등을 활용하여 "개인사업자 대출추이, 개인사업자 대출현황" 등 통계 작성
 ***************************************************************************/
-- (Step1) CORP_BIZ_DATA 테이블에서 기업(개인사업자, 가계) 데이터를 추출하고, 사업자번호 단위로 정제
-- 활용 테이블: CORP_BIZ_DATA -> IND_BRNO_AMT_RAW 테이블을 만듦(개인사업자 대출)               
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS IND_BRNO_AMT_RAW;
-- Table 생성 (기준년월, 기업구분, 주민번호, 사업자번호, SOI_CD, EI_ITT_CD, 사업자단위 대출(BRNO_AMT)
SELECT	
	t0.GG_YM,
	t0.BRWR_NO_TP_CD,
	t0.CORP_NO,
	t0.BRNO,
	t0.SOI_CD,
	t0.EI_ITT_CD,
	
	-- (여신) 1901만 볼 경우
	t0.AMT1901 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD) as BRNO_AMT
			
	-- (여신) 1901 + 5301 - 1391
--	t0.AMT1901 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD)
--	+ t0.AMT5301 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD)
--	- t0.AMT1391 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD) as BRNO_AMT
	INTO IND_BRNO_AMT_RAW
FROM 
(
	SELECT
		t.GG_YM,
		t.BRWR_NO_TP_CD,
		TRIM(t.CORP_NO) as CORP_NO,
		SUBSTR(t.BRNO, 4) as BRNO,
		t.EI_ITT_CD,
		t.SOI_CD,	
		t.ACCT_CD,
		DECODE(t.ACCT_CD, '1901', t.S_AMT, 0) as AMT1901, -- 대출채권계
       	DECODE(t.ACCT_CD, '5301', t.S_AMT, 0) as AMT5301, -- 대출채권(CMA계정포함)
       	DECODE(t.ACCT_CD, '1391', t.S_AMT, 0) as AMT1391 -- 지급보증대지급금
	FROM CORP_BIZ_DATA t
		WHERE t.RPT_CD = '31'	-- 보고서 번호 
		  	AND t.ACCT_CD IN ('1901', '5301', '1391') 
		  	AND t.SOI_CD IN (
		    	'01', '03', '05', '07', '11', '13', '15', '21', '31', '33', '35', '37', '41', 
		    	'43', '44', '46', '47', '61', '71', '74', '75', '76', '77', '79', '81', 
		    	'83', '85', '87', '89', '91', '94', '95', '97'
		  	)
		  	AND t.BRWR_NO_TP_CD in ('1')	-- 개인만 선택
) t0;
-- 결과 조회
SELECT * FROM IND_BRNO_AMT_RAW;


-- (Step2) CORP_BIZ_DATA 테이블에서 가계 대출 데이터를 추출하고, 사업자번호 단위로 정제
-- 활용 테이블: CORP_BIZ_DATA -> HOU_BRNO_AMT_RAW 테이블을 만듦(가계대출)               
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS HOU_BRNO_AMT_RAW;
-- Table 생성 (기준년월, 주민번호, 사업자번호, 가계대출(LOAN 1, 2, 5, 7, 9)
SELECT	
	t0.GG_YM,
	t0.CORP_NO,
	t0.BRNO,
	-- 동일 주민번호의 다수사업장 대출 배분
	t0.LOAN_1 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_1,
	t0.LOAN_2 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_2,
	t0.LOAN_5 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_5,
	t0.LOAN_7 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_7,
	t0.LOAN_9 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_9
	INTO HOU_BRNO_AMT_RAW
FROM 
(
	SELECT DISTINCT
		t.GG_YM,
		TRIM(t.CORP_NO) as CORP_NO,
		SUBSTR(t.BRNO, 4) as BRNO,
		t.LOAN_1,
		t.LOAN_2,
		t.LOAN_5,
		t.LOAN_7,
		t.LOAN_9
	FROM CORP_BIZ_DATA t
		WHERE t.BRWR_NO_TP_CD in ('1')	-- 개인만 선택
) t0;
-- 결과 조회
SELECT * FROM HOU_BRNO_AMT_RAW;


-- (Step3) IND_BRNO_AMT_RAW와 HOU_BRNO_AMT_RAW 결합하고, 그 결과를 BIZ_RAW 테이블과 결합하여 기업 개요 정보 add
-- 활용 테이블: IND_BRNO_AMT_RAW, HOU_BRNO_AMT_RAW, BIZ_RAW -> BASIC_BIZ_LOAN 테이블을 만듦               
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BASIC_IND_BIZ_LOAN;
-- Table 생성 (기준년월, 기업구분, 법인(주민)번호, 사업자번호, SOI_CD, EI_ITT_CD, 사업자단위 대출(BRNO_AMT), 사업자단위 연체금(ODU_AMT), KSIC, EFAS, BIZ_SIZE, 외감여부, 신용등급, SOI_CD2)
SELECT
	t10.*,
	t20.SOI_CD2
	INTO BASIC_IND_BIZ_LOAN
FROM
	(
	SELECT
		t1.*, 
	  	t2.KSIC, 
	  	t2.EFIS as EFAS, 
	  	t2.BIZ_SIZE,
	  	t2.OSIDE_ISPT_YN,
	  	t2.BLIST_MRKT_DIVN_CD,
	  	t2.CORP_CRI
	FROM 
	  	(
	  	SELECT
			t01.GG_YM,
			t01.CORP_NO,
			t01.BRNO,
			t01.SOI_CD,
			t01.EI_ITT_CD,
			t01.BRNO_AMT,
			t02.LOAN_1,
			t02.LOAN_2,
			t02.LOAN_5,
			t02.LOAN_7,
			t02.LOAN_9,
			t02.LOAN_1 + t02.LOAN_2 + t02.LOAN_5 + t02.LOAN_7 +	t02.LOAN_9 as HOU_LOAN
		FROM
			IND_BRNO_AMT_RAW t01, HOU_BRNO_AMT_RAW t02
		WHERE
			t01.GG_YM = t02.GG_YM
			AND t01.CORP_NO = t02.CORP_NO
			AND t01.BRNO = t02.BRNO
	  	) t1
	LEFT JOIN 
		BIZ_RAW t2 
		ON (t1.GG_YM = t2.GG_YM 
	  		AND t1.CORP_NO = t2.CORP_NO
	  		AND t1.BRNO = t2.BRNO)
	 ) t10
	 LEFT JOIN ITTtoSOI2 t20	-- SOI_CD2를 붙임
	 	ON t10.EI_ITT_CD = t20.ITT_CD;
-- 결과 조회
SELECT * FROM BASIC_IND_BIZ_LOAN;


   







/***************************************************************************
 *                 개인사업자/가계대출 연체율 기본테이블(IND_BRNO_OVD_RAW) 생성                            
 * 개인사업자 연체 기본테이블 생성
 * 기업대출 테이블(CORP_BIZ_DATA) 등을 활용하여 "개인사업자대출 연체율 추이" 통계 작성
 ***************************************************************************/
-- 활용 테이블: CORP_BIZ_DATA -> IND_BRNO_OVD_RAW 테이블을 만듦(개인사업자 연체 : CORP_NO, BRNO단위로 그루핑)               
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS IND_BRNO_OVD_RAW;
-- Table 생성 (기준년월, 주민번호, 사업자번호, 기업대출연체여부, 가계대출연체여부)
SELECT	
	t1.GG_YM,
	t1.CORP_NO,
	t1.BRNO,
	CASE WHEN t1.ODU_AMT > 0 THEN 1 ELSE 0 END as isBIZOVERDUE,
	CASE WHEN t2.AVG_LOAN_OVD_AMT > 0 THEN 1 ELSE 0 END as isHOUOVERDUE
	INTO IND_BRNO_OVD_RAW
FROM
	(
	SELECT DISTINCT 
		t.GG_YM,
		TRIM(t.CORP_NO) as CORP_NO,
		SUBSTR(t.BRNO, 4) as BRNO,
		t.ODU_AMT
	FROM CORP_BIZ_DATA t
		WHERE t.BRWR_NO_TP_CD in ('1')	-- 개인만 선택
	) t1,
	(
	SELECT DISTINCT
		t.GG_YM,
		TRIM(t.CORP_NO) as CORP_NO,
		SUBSTR(t.BRNO, 4) as BRNO,
		COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM, t.CORP_NO) as BIZ_CNT,
		t.LOAN_OVD_AMT,
		t.LOAN_OVD_AMT / COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM, t.CORP_NO) as AVG_LOAN_OVD_AMT
	FROM CORP_BIZ_DATA t
		WHERE t.BRWR_NO_TP_CD in ('1')	-- 개인만 선택
	) t2
WHERE
	t1.GG_YM = t2.GG_YM 
	AND t1.CORP_NO = t2.CORP_NO
	AND t1.BRNO = t2.BRNO;
-- 결과 조회
SELECT * FROM IND_BRNO_OVD_RAW;


-- 임시테이블 삭제
DROP TABLE IF EXISTS IND_BRNO_AMT_RAW;
DROP TABLE IF EXISTS HOU_BRNO_AMT_RAW;
