/*****************************************************
 * 담보가액 현황 - 담보가액 추이 (보고서 p.1, [그림 1]) 
 * RFP p.12 [그림1] 담보가액 추이 
 * 활용 테이블: BASIC_BIZ_DAMBO       
 * 사용자 입력 : 조회기준년월(inputGG_YM)        
 *****************************************************/
DROP TABLE IF EXISTS RESULT_BIZDamboTrend;
SELECT DISTINCT 
	t.GG_YM, 
	t.DAMBO_TYPE,	  	 -- 담보유형(1:재산권, 2:보증, 5:기타, 6:총계) 
  	round(SUM(t.BRNO_DAMBO_AMT) OVER(PARTITiON BY t.GG_YM, t.DAMBO_TYPE), 0) AS DAMBO_AMT -- 담보유형 및 기준년월별 담보가액 sum
  	INTO RESULT_BIZDamboTrend
FROM 
  	BASIC_BIZ_DAMBO t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
	AND t.BRWR_NO_TP_CD = '3'	-- 법인만
	AND NVL(t.EFAS, '') <> '55'	-- 금융보험업 제외
ORDER BY 
	t.GG_YM;


 
 
  	
/*****************************************************
 * 담보가액 현황 - 업권별(은행/비은행) 전년 동월 대비 담보가액 변화 (p.1, [그림 1])
 * RFP p.12 [그림2] 금융업권별 담보가액 
 * 활용 테이블: BASIC_BIZ_DAMBO
 *****************************************************/
DROP TABLE IF EXISTS RESULT_BIZDamboTrend_UPKWON;
SELECT 
  	t000.isBANK, 
  	t000.DAMBO_TYPE, 
  	round(t000.BANK_N1 + t000.nonBANK_N1, 0) as AMT_N2,  -- 전전년 동월 담보가액
  	round(t000.BANK_N1 + t000.nonBANK_N1, 0) as AMT_N1, -- 전년 동월 담보가액
  	round(t000.BANK_N0 + t000.nonBANK_N0, 0) as AMT_N0  -- 현월 담보가액
  	INTO RESULT_BIZDamboTrend_UPKWON
FROM 
  	(
    SELECT DISTINCT 
    	t00.isBANK, 
      	t00.DAMBO_TYPE, 
      	-- 은행 담보현황(현월, 전년동월)
      	SUM(CASE WHEN t00.isBANK = '은행' AND t00.GG_YM = ${inputGG_YM} THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as BANK_N0, 
      	SUM(CASE WHEN t00.isBANK = '은행' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as BANK_N1, 
      	SUM(CASE WHEN t00.isBANK = '은행' AND t00.GG_YM = ${inputGG_YM} - 200 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as BANK_N2,
      	-- 비은행 담보현황(현월, 전년동월)
      	SUM(CASE WHEN t00.isBANK = '비은행' AND t00.GG_YM = ${inputGG_YM} THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as nonBANK_N0, 
      	SUM(CASE WHEN t00.isBANK = '비은행' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as nonBANK_N1,
      	SUM(CASE WHEN t00.isBANK = '비은행' AND t00.GG_YM = ${inputGG_YM} - 200 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as nonBANK_N2
    FROM 
      	(
        SELECT DISTINCT 
        	t0.GG_YM, 
          	t0.isBANK, 
          	t0.DAMBO_TYPE,	-- 담보유형(1:재산권, 2:보증, 5:기타, 6:총계)
          	round(SUM(t0.BRNO_DAMBO_AMT) OVER(PARTITiON BY t0.GG_YM, t0.DAMBO_TYPE, t0.isBANK), 0) AS DAMBO_AMT -- 담보유형 및 기준년월별 담보가액 sum
          	--t0.BRNO_DAMBO_AMT
        FROM 
          	(
            SELECT 
              	t.*, 
              	CASE WHEN t.SOI_CD in ('01', '03', '05', '07') THEN '은행' ELSE '비은행' END as isBANK -- 업권 정의
            FROM 
              	BASIC_BIZ_DAMBO t 
            WHERE 
            	CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}, ${inputGG_YM} - 100, ${inputGG_YM} - 200)	-- 최근 3개년 
            	AND t.BRWR_NO_TP_CD = '3'	-- 법인만
				AND NVL(t.EFAS, '') <> '55'	-- 금융보험업 제외
          	) t0 
      	) t00
  	) t000;

  
  
 
 
/*****************************************************
 * 담보가액 현황 - 주요산업별 담보가액
 * 주요 산업 전년 동월 대비 재산권/보증/기타 변화 (p.1, [그림 1])
 * RFP p.12 [그림2] 업종별 담보가액 
 * (자동차: 37, 조선: 39, 철강: 22, 정유: 11, 석유화학: 12, 반도체: 26, 디스플레이: 27, 해운: 48, 건설: 45)
 * 활용 테이블: BASIC_BIZ_DAMBO
 *****************************************************/
DROP TABLE IF EXISTS RESULT_BIZDamboTrend_EFAS;
SELECT 
  	t00.EFAS, 
  	t00.DAMBO_TYPE,
  	-- 전전년 동월 담보가액
  	t00.N2_EFAS37 + t00.N2_EFAS39 + t00.N2_EFAS22 + t00.N2_EFAS11 + t00.N2_EFAS12 + t00.N2_EFAS26 + t00.N2_EFAS27 + t00.N2_EFAS48 + t00.N2_EFAS45 as N2_AMT,
  	-- 전년 동월 담보가액
  	t00.N1_EFAS37 + t00.N1_EFAS39 + t00.N1_EFAS22 + t00.N1_EFAS11 + t00.N1_EFAS12 + t00.N1_EFAS26 + t00.N1_EFAS27 + t00.N1_EFAS48 + t00.N1_EFAS45 as N1_AMT,
  	-- 현월 담보가액
  	t00.N0_EFAS37 + t00.N0_EFAS39 + t00.N0_EFAS22 + t00.N0_EFAS11 + t00.N0_EFAS12 + t00.N0_EFAS26 + t00.N0_EFAS27 + t00.N0_EFAS48 + t00.N0_EFAS45 as AMT_N0 	
  	INTO RESULT_BIZDamboTrend_EFAS
FROM 
  	(
    SELECT DISTINCT 
    	t0.EFAS, 
	  	t0.DAMBO_TYPE, 
	  	-- 자동차(37) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '37' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS37, 
	  	SUM(CASE WHEN t0.EFAS = '37' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS37, 
	  	SUM(CASE WHEN t0.EFAS = '37' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS37,
	  	-- 조선(39) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '39' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS39, 
	  	SUM(CASE WHEN t0.EFAS = '39' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS39,
	  	SUM(CASE WHEN t0.EFAS = '39' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS39,
	  	-- 철강(22) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '22' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS22, 
	  	SUM(CASE WHEN t0.EFAS = '22' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS22,
	  	SUM(CASE WHEN t0.EFAS = '22' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS22,
	  	-- 정유(11) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '11' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS11, 
	  	SUM(CASE WHEN t0.EFAS = '11' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS11,
	  	SUM(CASE WHEN t0.EFAS = '11' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS11,
	  	-- 석유화학(12) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '12' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS12, 
	  	SUM(CASE WHEN t0.EFAS = '12' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS12,
	  	SUM(CASE WHEN t0.EFAS = '12' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS12,
	  	-- 반도체(26) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '26' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS26, 
	  	SUM(CASE WHEN t0.EFAS = '26' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS26,
	  	SUM(CASE WHEN t0.EFAS = '26' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS26,
	  	-- 디스플레이(27) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '27' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS27, 
	  	SUM(CASE WHEN t0.EFAS = '27' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS27,
	  	SUM(CASE WHEN t0.EFAS = '27' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS27,
	  	-- 해운(48) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '48' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS48, 
	  	SUM(CASE WHEN t0.EFAS = '48' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS48,
	  	SUM(CASE WHEN t0.EFAS = '48' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS48,
	  	-- 건설(45) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '45' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS45, 
	  	SUM(CASE WHEN t0.EFAS = '45' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS45,
	  	SUM(CASE WHEN t0.EFAS = '45' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS45
    FROM 
      	(
        SELECT DISTINCT 
        	t.GG_YM, 
          	t.EFAS, 
          	t.DAMBO_TYPE,	-- 담보유형(1:재산권, 2:보증, 5:기타, 6:총계)
          	round(SUM(t.BRNO_DAMBO_AMT) OVER(PARTITiON BY t.GG_YM, t.DAMBO_TYPE, t.EFAS), 0) AS DAMBO_AMT -- 담보유형 및 기준년월별 담보가액 sum
        FROM 
            BASIC_BIZ_DAMBO t 
        WHERE 
            CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}, ${inputGG_YM} - 100, ${inputGG_YM} - 200)	-- 최근 3개년 
            AND t.BRWR_NO_TP_CD = '3'	-- 법인만
			AND NVL(t.EFAS, '') <> '55'	-- 금융보험업 제외
        ) t0
  	) t00
WHERE 
	t00.EFAS in ('37', '39', '22', '11', '12', '26', '27', '48', '45')
ORDER BY 
  	To_number(t00.EFAS, '99'), DAMBO_TYPE;
  	
  

  
  
-- 결과 조회
SELECT * FROM RESULT_BIZDamboTrend ORDER BY GG_YM, DAMBO_TYPE;
SELECT * FROM RESULT_BIZDamboTrend_UPKWON ORDER BY isBANK, DAMBO_TYPE;
SELECT * FROM RESULT_BIZDamboTrend_EFAS ORDER BY TO_NUMBER(EFAS, '99'), DAMBO_TYPE;