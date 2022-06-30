/******************************************
 * 기업 대출잔액 추이 - 산업별 대출규모(대출급증업종 등) (p.1, [그림3])
 * 활용 테이블 : BASIC_BIZ_LOAN
 * 사용자 입력 : 조회기준년월(inputGG_YM)
 * 현월(inputGG_YM)과 전년동월(inputGG_YM-100)의 대출 증감을 비교하여 대출 증감이 높은 산업 순으로 정렬
 ******************************************/
SELECT 
	t1.GG_YM,
	t1.EFAS,
	t1.EFAS_AMT
FROM 
  	(
    SELECT DISTINCT
    	t.GG_YM, 
    	t.BRWR_NO_TP_CD, 
      	t.EFAS, 
      	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRWR_NO_TP_CD, t.EFAS) as EFAS_AMT -- 월별, 산업별 대출합
    FROM 
      	BASIC_BIZ_LOAN t 
    ORDER BY 
      	t.EFAS
  	) t1, 
  	(
    -- 현월 및 전년동월 대출 증감 계산 (대출증감 내림차순으로 정렬하기 위함)
    SELECT DISTINCT 
    	t0.EFAS, 
      	SUM(DECODE(t0.GG_YM, ${inputGG_YM}, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) as thisAMT, -- 현월 대출잔액
      	SUM(DECODE(t0.GG_YM, ${inputGG_YM} - 100, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) as prevAMT, -- 전년동월 대출잔액
      	SUM(DECODE(t0.GG_YM, ${inputGG_YM}, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) - SUM(DECODE(t0.GG_YM, ${inputGG_YM}-100, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) as incAMT -- 대출 증감
    FROM 
    	(
        SELECT DISTINCT 
        	t.GG_YM, 
        	t.BRWR_NO_TP_CD,
          	t.EFAS, 
          	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRWR_NO_TP_CD, t.EFAS) as EFAS_AMT -- 월별, 산업별 대출합
        FROM 
          	BASIC_BIZ_LOAN t 
        ORDER BY 
          t.EFAS
    	) t0 
    WHERE 
      	CAST(t0.GG_YM AS INTEGER) in (${inputGG_YM}-100, ${inputGG_YM})	-- 현월(${inputGG_YM}), 전년(${inputGG_YM}-100) 동월
  	) t2 
WHERE 
  	t1.EFAS = t2.EFAS 
ORDER BY 
  	t1.GG_YM, t2.incAMT DESC;  

  
  
  
  
/*****************************************************
* 대출급증업종의 대출증감 - 대출급증업종 기업 대출 증감 현황 (p.2, [표])
******************************************************/
SELECT 
  	t000.EFAS, 
  	-- 총 대출 잔액
  	t000.prevAMT, 
  	t000.thisAMT, 
  	ROUND(t000.thisAMT / t000.prevAMT - 1, 4) as AMTgrowth, -- 대출잔액 증감율
  	-- 차주당 평균 대출잔액
  	t000.prevAVG_AMT, 
  	t000.thisAVG_AMT, 
  	ROUND(t000.thisAVG_AMT / t000.prevAVG_AMT - 1, 4) as AVG_AMTgrowth -- 평균대출잔액 증감율
FROM 
  	(
    SELECT DISTINCT
    	t00.EFAS, 
    	SUM(DECODE(t00.GG_YM, ${inputGG_YM}, t00.EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS) as thisAMT, -- 현월 대출잔액
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM} - 100, t00.EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS) as prevAMT, -- 전년동월 대출잔액
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM}, t00.AVG_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS) as thisAVG_AMT, -- 현월 대출잔액
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM} - 100, t00.AVG_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS) as prevAVG_AMT -- 전년동월 대출잔액
    FROM 
      	(
        SELECT DISTINCT 
        	t0.GG_YM, 
          	t0.EFAS, 
          	SUM(t0.LOAN) OVER(PARTITION BY t0.EFAS, t0.GG_YM) as EFAS_AMT, -- 산업별 대출합
          	COUNT(t0.BRNO) OVER(PARTITION BY t0.EFAS, t0.GG_YM) as EFAS_BRWR_CNT, -- 산업별 차주 수
          	ROUND(SUM(t0.LOAN) OVER(PARTITION BY t0.EFAS, t0.GG_YM) / COUNT(t0.BRNO) OVER(PARTITION BY t0.EFAS, t0.GG_YM), 2) as AVG_EFAS_AMT -- 산업별 차주당 평균 대출잔액
        FROM 
          	(
            SELECT DISTINCT
            	t.GG_YM, 
              	t.BRNO, 
              	t.EFAS, 
              	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRNO, t.EFAS) as LOAN 
            FROM 
              	BASIC_BIZ_LOAN t 
            WHERE 
              	CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}-100, ${inputGG_YM})	-- 현월(${inputGG_YM}), 전년(${inputGG_YM}-100) 동월
          	) t0 
      	) t00 
  	) t000 
ORDER BY To_number(t000.EFAS, '99');





/****************************************************************
 * 대출급증업종의 대출증감 - 대출급증업종 기업규모별 대출 증감 현황 (기업규모별, p.2) *
 ****************************************************************/
SELECT 
	t000.BIZ_SIZE,
  	t000.EFAS, 
  	-- 총 대출 잔액
  	t000.prevAMT, 
  	t000.thisAMT, 
  	ROUND(t000.thisAMT / t000.prevAMT - 1, 4) as AMTgrowth, -- 대출잔액 증감율
  	-- 차주당 평균 대출잔액
  	t000.prevAVG_AMT, 
  	t000.thisAVG_AMT, 
  	ROUND(t000.thisAVG_AMT / t000.prevAVG_AMT - 1, 4) as AVG_AMTgrowth -- 평균대출잔액 증감율
FROM 
  	(
    SELECT DISTINCT
    	t00.BIZ_SIZE,
    	t00.EFAS, 
    	SUM(DECODE(t00.GG_YM, ${inputGG_YM}, t00.BIZ_SIZE_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS, t00.BIZ_SIZE) as thisAMT, -- 기업규모별 현월 대출잔액
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM} - 100, t00.BIZ_SIZE_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS, t00.BIZ_SIZE) as prevAMT, -- 기업규모별 전년동월 대출잔액
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM}, t00.AVG_BIZ_SIZE_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS, t00.BIZ_SIZE) as thisAVG_AMT, -- 기업규모별 현월 대출잔액
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM} - 100, t00.AVG_BIZ_SIZE_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS, t00.BIZ_SIZE) as prevAVG_AMT -- 기업규모별 전년동월 대출잔액
    FROM 
      	(
        SELECT DISTINCT 
        	t0.BIZ_SIZE,
        	t0.GG_YM, 
          	t0.EFAS, 
          	SUM(t0.LOAN) OVER(PARTITION BY t0.BIZ_SIZE, t0.EFAS, t0.GG_YM) as BIZ_SIZE_EFAS_AMT, -- 산업별/기업규모별 월별 대출합
          	COUNT(t0.BRNO) OVER(PARTITION BY t0.BIZ_SIZE, t0.EFAS, t0.GG_YM) as BIZ_SIZE_EFAS_BRNO_CNT, -- 산업별/기업규모별 월별 차주 수
          	ROUND(SUM(t0.LOAN) OVER(PARTITION BY t0.BIZ_SIZE, t0.EFAS, t0.GG_YM) / COUNT(t0.BRNO) OVER(PARTITION BY t0.BIZ_SIZE, t0.EFAS, t0.GG_YM), 2) as AVG_BIZ_SIZE_EFAS_AMT -- 산업별/기업규모별 월별 차주당 평균 대출잔액
        FROM 
          	(
            SELECT DISTINCT
            	t.BIZ_SIZE,
            	t.GG_YM, 
              	t.BRNO, 
              	t.EFAS, 
              	SUM(t.BRNO_AMT) OVER(PARTITION BY t.BIZ_SIZE, t.GG_YM, t.BRNO, t.EFAS) as LOAN 
            FROM 
              	BASIC_BIZ_LOAN t 
            WHERE 
              	CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}-100, ${inputGG_YM})	-- 현월(${inputGG_YM}), 전년(${inputGG_YM}-100) 동월
              	AND t.BIZ_SIZE in ('1', '2', '3') -- 기업규모(t.BIZ_SIZE - 1: 대기업, 2: 중소기업, 3: 중견기업)
          	) t0 
      	) t00 
  	) t000 
ORDER BY t000.BIZ_SIZE, To_number(t000.EFAS, '99');