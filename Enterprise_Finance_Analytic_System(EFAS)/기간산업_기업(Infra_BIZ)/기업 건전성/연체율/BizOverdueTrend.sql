/*****************************************************
 * 건전성 지표 추이 - 연체율 추이 (p.6, [그림1], [표])
 * 활용 테이블 : (1) BASIC_BIZ_OVD -> OVERDUE_TB 테이블 만들어 연체율 계산
 *****************************************************/
-- (Standby) 월별, 산업별, 기업규모별, 외감여부별, 상장여부별, 기업별(산업자번호 단위) 연체여부 테이블 생성
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS OVERDUE_TB;
-- OVERDUE_TB 테이블 생성(기준년월, 기업구분, 법인번호, 사업자번호, EFAS, 기업규모, 외감여부, 상장구분, 연체여부)
SELECT DISTINCT
		t.GG_YM,
		t.BRWR_NO_TP_CD,
		t.CORP_NO,
		t.BRNO,
		t.EFAS,
		t.BIZ_SIZE,
		t.OSIDE_ISPT_YN,	-- 외감여부
		t.BLIST_MRKT_DIVN_CD,	-- 상장여부
		CASE 
			WHEN SUM(t.ODU_AMT) OVER(PARTITION BY t.GG_YM, t.BRNO) > 0
			THEN 1
			ELSE 0
		END as isOVERDUE
	INTO OVERDUE_TB
FROM BASIC_BIZ_OVD t
WHERE 
	t.BRWR_NO_TP_CD = 3 -- 법인
	AND t.OSIDE_ISPT_YN = 'Y'; -- 외감 여부
--	AND t.BLIST_MRKT_DIVN_CD in ('1', '2')	-- 코스피(1), 코스닥(2)
-- 결과 조회
SELECT * FROM OVERDUE_TB;


-- 월별, 기업규모별 연체율 계산 
SELECT DISTINCT 
 	t.GG_YM, 
  	CASE 
  		WHEN t.BIZ_SIZE = 1 THEN t.BIZ_SIZE || ' 대기업'
  		WHEN t.BIZ_SIZE = 2 THEN t.BIZ_SIZE || ' 중소기업'
  		WHEN t.BIZ_SIZE = 3 THEN t.BIZ_SIZE || ' 중견기업'
  		ELSE t.BIZ_SIZE
  	END as BIZ_SIZE,
  	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as NUM_OF_OVERDUE_BIZ,	-- 연체 기업수
  	COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as TOT_NUM_OF_BIZ,  -- 기업규모별 전체 기업수 
  	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) / COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as OVERDUE_RATIO	-- 기업규모별 연체율  
FROM
	OVERDUE_TB t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM};





/*****************************************************
 * 연체율: 업종별 현황 (p.6 표) - 연체율, 전년동월대비 증가율 도출
 *****************************************************/
-- (Step1) 업종별 당월 및 전년동월의 연체기업 수, 전체기업 수 정보로 구성된 테이블(EFAS_OVERDUE_TB) 생성
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS EFAS_OVERDUE_TB;
-- 테이블 생성
SELECT DISTINCT 
	t00.EFAS, 
  	-- 금년 동월 연체기업수, 총 기업수
  	SUM(CASE WHEN t00.GG_YM = ${inputGG_YM} THEN EFAS_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as thisYY_EFAS_OVERDUE_BIZ_CNT,
  	SUM(CASE WHEN t00.GG_YM = ${inputGG_YM} THEN EFAS_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as thisYY_EFAS_TOT_BIZ_CNT,
  	-- 전년 동월 연체기업수, 총 기업수
  	SUM(CASE WHEN t00.GG_YM = ${inputGG_YM} - 100 THEN EFAS_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as prevYY_EFAS_OVERDUE_BIZ_CNT,
  	SUM(CASE WHEN t00.GG_YM = ${inputGG_YM} - 100 THEN EFAS_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as prevYY_EFAS_TOT_BIZ_CNT
  	INTO EFAS_OVERDUE_TB
FROM 
  	(
    SELECT DISTINCT
    	t0.GG_YM,
      	t0.EFAS, 
      	-- 금년 동월 연체기업수, 총 기업수
      	SUM(t0.isOVERDUE) OVER(PARTITION BY t0.GG_YM, t0.EFAS) as EFAS_OVERDUE_BIZ_CNT, 
      	COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EFAS) as EFAS_TOT_BIZ_CNT 
    FROM 
      	(
        SELECT 
        	t.*
        FROM 
          	OVERDUE_TB t 
        WHERE 
          	CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}, ${inputGG_YM} - 100)	-- 당월 및 전년 동월 
      	) t0
  	) t00;
-- 결과 조회
SELECT * FROM EFAS_OVERDUE_TB t;


-- (Step2) 총계 계산하여 삽입
INSERT INTO EFAS_OVERDUE_TB 
SELECT 
  	'99', -- 총합은 EFIS code '00'할당 
  	SUM(t.thisYY_EFAS_OVERDUE_BIZ_CNT), 
  	SUM(t.thisYY_EFAS_TOT_BIZ_CNT), 
  	SUM(t.prevYY_EFAS_OVERDUE_BIZ_CNT), 
  	SUM(t.prevYY_EFAS_TOT_BIZ_CNT) 
FROM 
  	EFAS_OVERDUE_TB t;
-- 결과 조회
SELECT * FROM EFAS_OVERDUE_TB t;


-- (Step3) 당해년/전년 동월 연체율 및 전년 동월 대비 증가율 계산 */
SELECT 
  	TO_NUMBER(t.EFAS, '99') as EFAS, 
  	ROUND(t.thisYY_EFAS_OVERDUE_BIZ_CNT / t.thisYY_EFAS_TOT_BIZ_CNT, 4) as thisYY_OVERDUE_RATE, -- 당월 연체율
  	ROUND(t.prevYY_EFAS_OVERDUE_BIZ_CNT / t.prevYY_EFAS_TOT_BIZ_CNT, 4) as prevYY_OVERDUE_RATE, -- 전년 동월 연체율
  	ROUND(t.thisYY_EFAS_OVERDUE_BIZ_CNT / t.thisYY_EFAS_TOT_BIZ_CNT, 4) - ROUND(t.prevYY_EFAS_OVERDUE_BIZ_CNT / t.prevYY_EFAS_TOT_BIZ_CNT, 4) as INC_OVERDUE_RATE -- 전년 동월 대비 증가율
FROM 
  	EFAS_OVERDUE_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');