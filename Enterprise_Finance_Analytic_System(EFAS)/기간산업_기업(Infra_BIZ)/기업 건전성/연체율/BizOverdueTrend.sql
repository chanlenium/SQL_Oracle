/*****************************************************
 * 건전성 지표 추이 - 연체율 추이 (보고서 p.6, [그림1], [표])
 * RFP p.15 [그림1] 연체율
 * 활용 테이블 : (1) BASIC_BIZ_OVD -> OVERDUE_TB 테이블 만들어 연체율 계산
 *****************************************************/
-- (Step1) 월별, 산업별, 기업규모별, 외감여부별, 상장여부별, 기업별(산업자번호 단위) 연체여부 테이블 생성
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
	t.BRWR_NO_TP_CD = '3' -- 법인
	AND NVL(t.EFAS, '') <> '55'	-- 금융보험업 제외
	AND t.OSIDE_ISPT_YN = 'Y' -- 외감 여부
	AND 
	    CASE 
			WHEN '${isSangJang}' = 'Y' 
			THEN t.BLIST_MRKT_DIVN_CD IN ('1', '2')	-- 상장기업(코스피(1), 코스닥(2))
			ELSE t.BLIST_MRKT_DIVN_CD IN ('1', '2', '3', '9')	-- 외감전체
		END;
-- 결과 조회
SELECT * FROM OVERDUE_TB;


-- 월별, 기업규모별 연체율 계산 
DROP TABLE IF EXISTS OVERDUE_BIZSIZE;
SELECT DISTINCT
 	t0.GG_YM, 
 	SUM(t0.isOVERDUE_1) OVER (PARTITION BY t0.GG_YM) as NUM_OF_OVERDUE_BIZ_1,	-- 대기업 연체 기업수
 	SUM(t0.isBiz_1) OVER (PARTITION BY t0.GG_YM) as NUM_OF_BIZ_1,	-- 대기업 기업수
 	ROUND(SUM(t0.isOVERDUE_1) OVER (PARTITION BY t0.GG_YM) 
 		/ NULLIF(SUM(t0.isBiz_1) OVER (PARTITION BY t0.GG_YM), 0), 4) as OVERDUE_RATIO_1,	-- 대기업 연체율	
 	SUM(t0.isOVERDUE_2) OVER (PARTITION BY t0.GG_YM) as NUM_OF_OVERDUE_BIZ_2,	-- 중소기업 연체 기업수
 	SUM(t0.isBiz_2) OVER (PARTITION BY t0.GG_YM) as NUM_OF_BIZ_2,	-- 중소기업 기업수
 	ROUND(SUM(t0.isOVERDUE_2) OVER (PARTITION BY t0.GG_YM) 
 		/ NULLIF(SUM(t0.isBiz_2) OVER (PARTITION BY t0.GG_YM), 0), 4) as OVERDUE_RATIO_2,	-- 중소기업 연체율
 	SUM(t0.isOVERDUE_3) OVER (PARTITION BY t0.GG_YM) as NUM_OF_OVERDUE_BIZ_3,	-- 중견기업 연체 기업수
 	SUM(t0.isBiz_3) OVER (PARTITION BY t0.GG_YM) as NUM_OF_BIZ_3,	-- 중견기업 기업수
 	ROUND(SUM(t0.isOVERDUE_3) OVER (PARTITION BY t0.GG_YM) 
 		/ NULLIF(SUM(t0.isBiz_3) OVER (PARTITION BY t0.GG_YM), 0), 4) as OVERDUE_RATIO_3,	-- 중견기업 연체율
 	SUM(t0.isOVERDUE_0) OVER (PARTITION BY t0.GG_YM) as NUM_OF_OVERDUE_BIZ_0,	-- 기타기업 연체 기업수
 	SUM(t0.isBiz_0) OVER (PARTITION BY t0.GG_YM) as NUM_OF_BIZ_0,	-- 기타기업 기업수
 	ROUND(SUM(t0.isOVERDUE_0) OVER (PARTITION BY t0.GG_YM) 
 		/ NULLIF(SUM(t0.isBiz_0) OVER (PARTITION BY t0.GG_YM), 0), 4) as OVERDUE_RATIO_0	-- 기타기업 연체율
 	INTO OVERDUE_BIZSIZE
FROM 
	(
	SELECT 
		t.*,
		DECODE(t.BIZ_SIZE, '1', isOVERDUE, 0) as isOVERDUE_1,	-- 대기업 연체여부
		DECODE(t.BIZ_SIZE, '1', 1, 0) as isBiz_1,				-- 대기업이면 카운트
		DECODE(t.BIZ_SIZE, '2', isOVERDUE, 0) as isOVERDUE_2,	-- 중소기업 연체여부
		DECODE(t.BIZ_SIZE, '2', 1, 0) as isBiz_2,				-- 중소기업이면 카운트
		DECODE(t.BIZ_SIZE, '3', isOVERDUE, 0) as isOVERDUE_3,	-- 중견기업 연체여부
		DECODE(t.BIZ_SIZE, '3', 1, 0) as isBiz_3,				-- 중견기업이면 카운트
		DECODE(NVL(t.BIZ_SIZE, '0'), isOVERDUE, 0) as isOVERDUE_0,	-- 기타기업 연체여부
		DECODE(NVL(t.BIZ_SIZE, '0'), isOVERDUE, 0) as isBiz_0		-- 기타기업이면 카운트
	FROM
		OVERDUE_TB t
	WHERE
		CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
	) t0
ORDER BY t0.GG_YM;






/*****************************************************
 * 연체율: 업종별 현황 (보고서 p.6 표) - 연체율, 전년동월대비 증가율 도출
 * RFP p.16 [표] 연체율 : 업종별 현황
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
  	'00', -- 전산업은 EFAS code '00'할당 
  	SUM(t.thisYY_EFAS_OVERDUE_BIZ_CNT), 
  	SUM(t.thisYY_EFAS_TOT_BIZ_CNT), 
  	SUM(t.prevYY_EFAS_OVERDUE_BIZ_CNT), 
  	SUM(t.prevYY_EFAS_TOT_BIZ_CNT) 
FROM 
  	EFAS_OVERDUE_TB t;
-- 결과 조회
SELECT * FROM EFAS_OVERDUE_TB t;


-- (Step3) 당해년/전년 동월 연체율 및 전년 동월 대비 증가율 계산 */
DROP TABLE IF EXISTS OVERDUE_EFAS;
SELECT 
  	TO_NUMBER(t.EFAS, '99') as EFAS, 
  	ROUND(t.thisYY_EFAS_OVERDUE_BIZ_CNT / t.thisYY_EFAS_TOT_BIZ_CNT, 4) as thisYY_OVERDUE_RATE, -- 당월 연체율
  	ROUND(t.prevYY_EFAS_OVERDUE_BIZ_CNT / t.prevYY_EFAS_TOT_BIZ_CNT, 4) as prevYY_OVERDUE_RATE, -- 전년 동월 연체율
  	ROUND(t.thisYY_EFAS_OVERDUE_BIZ_CNT / t.thisYY_EFAS_TOT_BIZ_CNT, 4) - ROUND(t.prevYY_EFAS_OVERDUE_BIZ_CNT / t.prevYY_EFAS_TOT_BIZ_CNT, 4) as INC_OVERDUE_RATE -- 전년 동월 대비 증가율
  	INTO OVERDUE_EFAS
FROM 
  	EFAS_OVERDUE_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');
  	
  
  
  
-- 임시테이블 삭제
DROP TABLE IF EXISTS OVERDUE_TB;
DROP TABLE IF EXISTS EFAS_OVERDUE_TB;


-- 결과조회
SELECT * FROM OVERDUE_BIZSIZE ORDER BY GG_YM;
SELECT * FROM OVERDUE_EFAS ORDER BY EFAS;