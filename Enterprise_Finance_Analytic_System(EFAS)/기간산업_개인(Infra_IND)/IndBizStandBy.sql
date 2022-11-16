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
	t0.BR_ACT,
	-- 대출금액
	t0.AMT1901 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD)
	+ t0.AMT5301 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD)
	- t0.AMT1391 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD) as BRNO_AMT,
	-- 연체금액
	t0.ODU_AMT1901 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD)
	+ t0.ODU_AMT5301 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD) as BRNO_ODU_AMT
	into IND_BRNO_AMT_RAW
FROM 
	(
	SELECT
		t.GG_YM,
		t.BRWR_NO_TP_CD,
		TRIM(t.CORP_NO) as CORP_NO,
		SUBSTR(t.BRNO, 4) as BRNO,
		t.BR_ACT, 
		t.EI_ITT_CD,
		t.SOI_CD,	
		t.ACCT_CD,
		DECODE(t.ACCT_CD, '1901', NVL(t.S_AMT, 0), 0) as AMT1901, -- 대출채권계
       	DECODE(t.ACCT_CD, '5301', NVL(t.S_AMT, 0), 0) as AMT5301, -- 대출채권(CMA계정포함)
       	DECODE(t.ACCT_CD, '1391', NVL(t.S_AMT, 0), 0) as AMT1391, -- 지급보증대지급금	
       	DECODE(t.ACCT_CD, '1901', NVL(t.ODU_AMT, 0), 0) as ODU_AMT1901, -- 대출채권계 연체
       	DECODE(t.ACCT_CD, '5301', NVL(t.ODU_AMT, 0), 0) as ODU_AMT5301 -- 대출채권(CMA계정포함) 연체
	FROM CORP_BIZ_DATA t
		WHERE t.RPT_CD = '31'	-- 보고서 번호 
		  	AND t.ACCT_CD IN ('1901', '5301', '1391') 
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
	t0.BR_ACT,
	-- 동일 주민번호의 다수사업장 대출 배분
	t0.LOAN_1 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_1,
	t0.LOAN_2 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_2,
	t0.LOAN_5 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_5,
	t0.LOAN_7 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_7,
	t0.LOAN_9 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_9,
	-- 동일 주민번호의 다수사업장 연체 배분
	t0.LOAN_OVD_AMT / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_OVD_AMT
	into HOU_BRNO_AMT_RAW
FROM 
	(
	SELECT DISTINCT
		t.GG_YM,
		TRIM(t.CORP_NO) as CORP_NO,
		SUBSTR(t.BRNO, 4) as BRNO,
		t.BR_ACT,
		t.LOAN_1,
		t.LOAN_2,
		t.LOAN_5, 
		t.LOAN_7, 
		t.LOAN_9,
		t.LOAN_OVD_AMT
	FROM CORP_BIZ_DATA t
		WHERE t.BRWR_NO_TP_CD in ('1')	-- 개인만 선택
	ORDER BY TRIM(t.CORP_NO), t.GG_YM
	) t0
ORDER BY t0.CORP_NO, t0.GG_YM;
-- 결과 조회
SELECT * FROM HOU_BRNO_AMT_RAW;



-- (Step3) IND_BRNO_AMT_RAW와 HOU_BRNO_AMT_RAW 결합하고, 그 결과를 BIZ_RAW 테이블과 결합하여 기업 개요 정보 add
-- 활용 테이블: IND_BRNO_AMT_RAW, HOU_BRNO_AMT_RAW, BIZ_RAW -> BASIC_BIZ_LOAN 테이블을 만듦               
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BASIC_IND_BIZ_LOAN;
-- Table 생성 (기준년월, 기업구분, 법인(주민)번호, 사업자번호, SOI_CD, EI_ITT_CD, 사업자단위 대출(BRNO_AMT), 사업자단위 연체금(ODU_AMT), KSIC, EFAS, BIZ_SIZE, 외감여부, 신용등급, SOI_CD2)
SELECT
	t10000.*,
	t20000.SOI_CD2
	into BASIC_IND_BIZ_LOAN
FROM
	(
	SELECT
		t1000.*,
		t2000.KSIC, 
		t2000.EFAS, 
		t2000.BIZ_SIZE,
		t2000.OSIDE_ISPT_YN,
		t2000.BLIST_MRKT_DIVN_CD,
		t2000.CORP_CRI
	FROM 
		(
		SELECT 
			t100.*,
			t200.LOAN_1,
			t200.LOAN_2,
			t200.LOAN_5,
			t200.LOAN_7,
			t200.LOAN_9,
			t200.LOAN_1 + t200.LOAN_2 + t200.LOAN_5 + t200.LOAN_7 + t200.LOAN_9 as HOU_LOAN,
			t200.LOAN_OVD_AMT
		FROM
			(
			SELECT
				t10.GG_YM,
				t10.CORP_NO,
				t10.BRNO,
				t10.BR_ACT,
				t20.SOI_CD,
				t20.EI_ITT_CD,
				t20.BRNO_AMT,
				t20.BRNO_ODU_AMT
			FROM
				(
				SELECT DISTINCT
					t.GG_YM,
					trim(t.CORP_NO) as CORP_NO,
					SUBSTR(t.BRNO, 4) as BRNO,
					NVL(t.BR_ACT, '99') as BR_ACT
				FROM 
					CORP_BIZ_DATA t 
				WHERE 
					t.BRWR_NO_TP_CD = '1'
				) t10
				LEFT JOIN IND_BRNO_AMT_RAW t20
				ON t10.GG_YM = t20.GG_YM
					AND t10.CORP_NO = t20.CORP_NO
					AND t10.BRNO = t20.BRNO
					AND t10.BR_ACT = NVL(t20.BR_ACT, '99')
			ORDER BY t20.BRNO_AMT desc
			) t100
			LEFT JOIN HOU_BRNO_AMT_RAW t200
			ON t100.GG_YM = t200.GG_YM
				AND t100.CORP_NO = t200.CORP_NO
				AND t100.BRNO = t200.BRNO
				AND t100.BR_ACT = NVL(t200.BR_ACT, '99')
		ORDER BY t100.BRNO_AMT desc
		) t1000
		LEFT JOIN BIZ_RAW t2000 
		ON t1000.GG_YM = t2000.GG_YM 
		  	AND t1000.CORP_NO = t2000.CORP_NO
		  	AND t1000.BRNO = t2000.BRNO
	ORDER BY t1000.BRNO_AMT desc
	) t10000
	LEFT JOIN ITTtoSOI2 t20000	-- SOI_CD2를 붙임
	 	ON t10000.EI_ITT_CD = t20000.ITT_CD
ORDER BY t10000.BRNO_AMT;
-- 결과 조회
SELECT * FROM BASIC_IND_BIZ_LOAN ORDER BY BRNO_AMT desc;
