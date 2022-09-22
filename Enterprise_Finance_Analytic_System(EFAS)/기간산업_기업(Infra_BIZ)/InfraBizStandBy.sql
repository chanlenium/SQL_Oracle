/***************************************************************************
 *                 기 업 대 출 기본테이블(BASIC_BIZ_LOAN) 생성                            
 * 기업대출 기본테이블 생성 (대출 = 대출채권계(1901) + 대출채권CMA계정포함(5301) - 지급보증대지급금(1391))
 ***************************************************************************/
-- (Step1) CORP_BIZ_DATA 테이블에서 기업(법인, 개인사업자) 데이터를 추출하고, 사업자번호 단위로 정제
-- 활용 테이블: CORP_BIZ_DATA -> BRNO_AMT_RAW 테이블을 만듦               
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BRNO_AMT_RAW;
-- Table 생성 (기준년월, 기업구분, 법인(주민)번호, 사업자번호, SOI_CD, EI_ITT_CD, 사업자단위 대출(BRNO_AMT))
SELECT	
	t0.GG_YM,
	t0.BRWR_NO_TP_CD,
	t0.CORP_NO,
	t0.BRNO,
	t0.SOI_CD,
	t0.EI_ITT_CD,
	t0.BR_ACT,
	
	-- (여신) 1901만 볼 경우
	-- t0.AMT1901 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD) as BRNO_AMT
			
	-- (여신) 1901 + 5301 - 1391
	t0.AMT1901 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD)
	+ t0.AMT5301 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD)
	- t0.AMT1391 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD) as BRNO_AMT	
	INTO BRNO_AMT_RAW
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
		t.BR_ACT,
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
		  	AND t.BRWR_NO_TP_CD in ('1', '3')	-- 법인과 개인만 count
	) t0;
-- 결과 조회
SELECT * FROM BRNO_AMT_RAW;





-- (Step2) BRNO_AMT_RAW에 BIZ_RAW, ITTtoSOI2 테이블과 결합하여 기업 개요 정보 add
-- 활용 테이블: BRNO_AMT_RAW, BIZ_RAW, ITTtoSOI2 -> BASIC_BIZ_LOAN 테이블을 만듦               
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BASIC_BIZ_LOAN;
-- Table 생성 (기준년월, 기업구분, 법인(주민)번호, 사업자번호, SOI_CD, EI_ITT_CD, 사업자단위 대출, KSIC, EFAS, BIZ_SIZE, 외감여부, 상장구분, 신용등급, SOI_CD2)
SELECT
	t10.*,
	t20.SOI_CD2
	INTO BASIC_BIZ_LOAN
FROM
	(
	SELECT
		t1.*, 
	  	t2.KSIC, 
	  	t2.EFAS, 
	  	t2.BIZ_SIZE,
	  	t2.OSIDE_ISPT_YN,
	  	t2.BLIST_MRKT_DIVN_CD,
	  	t2.CORP_CRI
	FROM 
	  	BRNO_AMT_RAW t1
	LEFT JOIN 
		BIZ_RAW t2 
		ON (t1.GG_YM = t2.GG_YM 
	  		AND t1.CORP_NO = t2.CORP_NO
	  		AND t1.BRNO = t2.BRNO)
	 ) t10
	 LEFT JOIN ITTtoSOI2 t20	-- SOI_CD2를 붙임
	 	ON To_number(t10.EI_ITT_CD, '9999') = To_number(t20.ITT_CD, '9999');
-- 결과조회
SELECT count(gg_ym) FROM BASIC_BIZ_LOAN;	 








/***************************************************************************
 *                 담 보 현 황 기본테이블(BASIC_BIZ_DAMBO) 생성                         
 * 기업담보 기본테이블 생성 (1:재산권, 2:보증, 5:기타)
 ***************************************************************************/
-- (사전준비) CORP_BIZ_DATA 테이블에서 기업(법인, 개인사업자) 데이터를 추출하고, 사업자번호 단위로 정제한 후 기업개요(BIZ_RAW, ITTtoSOI2)와 결합
-- 활용 테이블: CORP_BIZ_DATA, BIZ_RAW, ITTtoSOI2 -> BASIC_BIZ_DAMBO 테이블을 만듦               
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BASIC_BIZ_DAMBO;
-- Table 생성 (기준년월, 기업구분, 법인(주민)번호, 사업자번호, SOI_CD, EI_ITT_CD, 사업자단위 대출(BRNO_AMT), 사업자단위 연체금(ODU_AMT), KSIC, EFAS, BIZ_SIZE, 외감여부, 신용등급, SOI_CD2)
SELECT
	t10.*,
	t20.SOI_CD2
	INTO BASIC_BIZ_DAMBO
FROM
	(SELECT
			t1.*, 
		  	t2.KSIC, 
		  	t2.EFAS, 
		  	t2.BIZ_SIZE
	FROM	  	
		(SELECT DISTINCT
			t0.GG_YM,
			t0.BRWR_NO_TP_CD,
			t0.BRNO,
			t0.CORP_NO,
			t0.ACCT_CD,
			t0.DAMBO_TYPE,
			t0.EI_ITT_CD,
			t0.SOI_CD,
			t0.DAMBO_AMT / t0.CNT_BRNO as BRNO_DAMBO_AMT	-- 사업자번호 기준 담보가액
		FROM
			(SELECT DISTINCT 
				t.GG_YM, 
				t.BRWR_NO_TP_CD,
				trim(t.CORP_NO) as CORP_NO,
				t.EI_ITT_CD,
				t.SOI_CD,
				substr(t.BRNO, 4) as BRNO,
				t.ACCT_CD,
			  	SUBSTR(t.ACCT_CD, 1, 1) AS DAMBO_TYPE, -- 담보유형(1:재산권, 2:보증, 5:기타, 6:총계)
			  	S_AMT,
			  	SUM(t.S_AMT) OVER(PARTITiON BY t.GG_YM, t.CORP_NO, t.EI_ITT_CD, t.BRNO, t.ACCT_CD) AS DAMBO_AMT, -- 담보유형 및 기준년월별 담보가액 sum
			  	COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM, t.CORP_NO, t.EI_ITT_CD, t.ACCT_CD) AS CNT_BRNO	-- 동일 CORP_NO에 연계된 사업자번호(BRNO)수
			FROM 
			 	 CORP_BIZ_DATA t 
			WHERE 
			  	t.RPT_CD = '33' -- 담보기록 보고서번호: 33
			  	AND t.BRWR_NO_TP_CD in ('1', '3')	-- 법인 & 개인사업자
			ORDER BY 
			  t.GG_YM) t0) t1
		 	LEFT JOIN 
				BIZ_RAW t2 
			ON (t1.GG_YM = t2.GG_YM 
		  		AND t1.CORP_NO = t2.CORP_NO
		  		AND t1.BRNO = t2.BRNO)
		 ) t10
		 LEFT JOIN ITTtoSOI2 t20	-- SOI_CD2를 붙임
		 	ON t10.EI_ITT_CD = t20.ITT_CD;
-- 결과 조회
select * from BASIC_BIZ_DAMBO;	










/*****************************************************
 *             연 체 율 기본테이블 생성(BASIC_BIZ_OVD)
 * 신용공여정보 보유 기업 수 대비 연체 기업 수 비중 계산
 * 활용 테이블 : CORP_BIZ_DATA -> BRNO_OVD_RAW -> BASIC_BIZ_OVD 
 *****************************************************/
-- (Step1) CORP_BIZ_DATA 테이블에서 기업(법인, 개인사업자) 연체 데이터를 추출하고, 사업자번호 단위로 정제
-- 활용 테이블: CORP_BIZ_DATA -> BRNO_OVD_RAW 테이블을 만듦               
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BRNO_OVD_RAW;
-- Table 생성 (기준년월, 기업구분, 법인(주민)번호, 사업자번호, SOI_CD, EI_ITT_CD, 사업자단위 연체금(ODU_AMT))
SELECT DISTINCT 
	t.GG_YM,
	t.BRWR_NO_TP_CD,
	TRIM(t.CORP_NO) as CORP_NO,
	SUBSTR(t.BRNO, 4) as BRNO,
	t.SOI_CD,
	t.EI_ITT_CD,
	t.ODU_AMT
	INTO BRNO_OVD_RAW
FROM CORP_BIZ_DATA t
	WHERE t.BRWR_NO_TP_CD in ('1', '3');	-- 법인, 개인만 선택	
-- 결과 조회
SELECT * FROM BRNO_OVD_RAW;


-- (Step2) BRNO_OVD_RAW와 BIZ_RAW 테이블과 결합하여 기업 개요 정보 add
-- 활용 테이블: BRNO_OVD_RAW, BIZ_RAW -> BASIC_BIZ_OVD 테이블을 만듦               
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BASIC_BIZ_OVD;
-- Table 생성 (기준년월, 기업구분, 법인(주민)번호, 사업자번호, SOI_CD, EI_ITT_CD, 사업자단위 연체금(ODU_AMT), KSIC, EFAS, BIZ_SIZE, 외감여부, 상장구분, 신용등급, SOI_CD2)
SELECT
	t10.*,
	t20.SOI_CD2
	INTO BASIC_BIZ_OVD
FROM
	(
	SELECT
		t1.*, 
	  	t2.KSIC, 
	  	t2.EFAS, 
	  	t2.BIZ_SIZE,
	  	t2.OSIDE_ISPT_YN,
	  	t2.BLIST_MRKT_DIVN_CD,
	  	t2.CORP_CRI
	FROM 
	  	BRNO_OVD_RAW t1
	LEFT JOIN 
		BIZ_RAW t2 
		ON (t1.GG_YM = t2.GG_YM 
	  		AND t1.CORP_NO = t2.CORP_NO
	  		AND t1.BRNO = t2.BRNO)
	 ) t10
	 LEFT JOIN ITTtoSOI2 t20	-- SOI_CD2를 붙임
	 	ON t10.EI_ITT_CD = t20.ITT_CD;
-- 결과 조회
SELECT * FROM BASIC_BIZ_OVD;











/*****************************************************
 *             기간산업 재무비율 도출용 기업테이블 생성(GIUP_RAW)
 * 활용 테이블 : TCB_NICE_COMP_OUTL(기업개요) -> GIUP_RAW 
 * 이주혜 조사역 코드 준용 (재무비율은 NICE 기업 pool을 대상으로 도출함)
 * 최신 들어온 기업정보 케이스의 경우, 세세분류코드는 가장 최신월에 들어온거 사용
 *****************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS GIUP_RAW;
-- 테이블 생성(기준년월, NICE기업코드, 사업자번호, 법인번호, 기업규모, 외감여부, 상장구분, KSIC)
SELECT 
  	a.STD_YM, 
  	a.COMP_CD, 
  	BRNO, 
  	CORP_NO, 
  	COMP_SCL_DIVN_CD, 
  	OSIDE_ISPT_YN, 
  	BLIST_MRKT_DIVN_CD,
  	KSIC 
  	INTO GIUP_RAW 
FROM 
  	(
    SELECT * 
    FROM
      	(
        SELECT 
          	ROW_NUMBER() OVER(PARTITION BY COMP_CD ORDER BY STD_YM DESC) as rn, * 
        FROM 
          	TCB_NICE_COMP_OUTL
      	) as a 
    WHERE 
      	rn = 1
  	) as a 
  	LEFT JOIN -- KSIC가 null인 것을 포함하여 기업테이블 생성
  	(
    SELECT 
      	COMP_CD, 
      	KSIC 
    FROM 
      	(
        -- STD_YM을 기준으로 순위 매기기
        SELECT 
          	ROW_NUMBER() over (partition by COMP_CD order by STD_YM desc) as rn, * 
        FROM 
          	(
            SELECT DISTINCT 
              	STD_YM, 
              	COMP_CD, 
              	substr(NICE_STDD_INDU_CLSF_CD, 4, 5) as KSIC -- KSIC 5자리만 선택
           	FROM 
              	TCB_NICE_COMP_OUTL 
            WHERE 
              	KSIC is not null -- null인 것을 제외
             ) as a
      	) as a 
    WHERE 
      	rn = 1 -- 가장 최근 등록된 데이터만 사용
    ) as b using (COMP_CD);
-- 결과 조회
select * from GIUP_RAW;  



-- 임시테이블 삭제
--DROP TABLE IF EXISTS BRNO_AMT_RAW;
--DROP TABLE IF EXISTS BRNO_OVD_RAW;