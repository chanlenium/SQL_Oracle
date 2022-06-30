/*****************************************************
 * 담보가액 현황 - 담보가액 추이 (p.1, [그림 1]) 
 * 활용 테이블: BASIC_BIZ_DAMBO       
 * 사용자 입력 : 조회기준년월(inputGG_YM)        
 *****************************************************/
SELECT DISTINCT 
	t.GG_YM, 
	t.DAMBO_TYPE,	  	 -- 담보유형(1:재산권, 2:보증, 5:기타, 6:총계) 
	CASE 
  		WHEN t.BIZ_SIZE = 1 THEN t.BIZ_SIZE || ' 대기업'
  		WHEN t.BIZ_SIZE = 2 THEN t.BIZ_SIZE || ' 중소기업'
  		WHEN t.BIZ_SIZE = 3 THEN t.BIZ_SIZE || ' 중견기업'
  		ELSE t.BIZ_SIZE
  	END as BIZ_SIZE,
  	round(SUM(t.BRNO_DAMBO_AMT) OVER(PARTITiON BY t.GG_YM, t.DAMBO_TYPE, t.BIZ_SIZE), 0) AS DAMBO_AMT -- 담보유형 및 기준년월별 담보가액 sum
FROM 
  	BASIC_BIZ_DAMBO t
WHERE
	CAST(t.GG_YM AS INTEGER) <= :inputGG_YM
ORDER BY 
	t.GG_YM;


 
 
  	
/*****************************************************
 * 담보가액 현황 - 업권별(은행/비은행) 전년 동월 대비 담보가액 변화 (p.1, [그림 1])
 * 활용 테이블: BASIC_BIZ_DAMBO
 *****************************************************/
SELECT 
  	t000.isBANK, 
  	t000.DAMBO_TYPE, 
  	round(t000.BANK_thisYY + t000.nonBANK_thisYY, 0) as thisYY_AMT, -- 현월 담보가액
  	round(t000.BANK_prevYY + t000.nonBANK_prevYY, 0) as prevYY_AM -- 전년 동월 담보가액
FROM 
  	(
    SELECT DISTINCT 
    	t00.isBANK, 
      	t00.DAMBO_TYPE, -- 은행 담보현황(현월, 전년동월)
      	SUM(CASE WHEN t00.isBANK = '은행' AND t00.GG_YM = :inputGG_YM THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as BANK_thisYY, 
      	SUM(CASE WHEN t00.isBANK = '은행' AND t00.GG_YM = :inputGG_YM - 100 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as BANK_prevYY, 
      	-- 비은행 담보현황(현월, 전년동월)
      	SUM(CASE WHEN t00.isBANK = '비은행' AND t00.GG_YM = :inputGG_YM THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as nonBANK_thisYY, 
      	SUM(CASE WHEN t00.isBANK = '비은행' AND t00.GG_YM = :inputGG_YM - 100 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as nonBANK_prevYY 
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
            	CAST(t.GG_YM AS INTEGER) in (:inputGG_YM, :inputGG_YM - 100)	-- 당월 및 전년 동월 
          	) t0 
      	) t00
  	) t000;

  
  
 
 
/*****************************************************
 * 담보가액 현황 - 주요산업별 담보가액
 * 주요 산업 전년 동월 대비 재산권/보증/기타 변화 (p.1, [그림 1])
 * (자동차: 37, 조선: 39, 철강: 22, 정유: 11, 석유화학: 12, 반도체: 26, 디스플레이: 27, 해운: 48, 건설: 45)
 * 활용 테이블: BASIC_BIZ_DAMBO
 *****************************************************/
SELECT 
  	t00.EFAS, 
  	t00.DAMBO_TYPE, 
  	-- 현월 담보가액
  	t00.thisYY_EFAS37 + t00.thisYY_EFAS39 + t00.thisYY_EFAS22 + t00.thisYY_EFAS11 + t00.thisYY_EFAS12 + t00.thisYY_EFAS26 + t00.thisYY_EFAS27 + t00.thisYY_EFAS48 + t00.thisYY_EFAS45 as thisYY_AMT, 
  	-- 전년 동월 담보가액
  	t00.prevYY_EFAS37 + t00.prevYY_EFAS39 + t00.prevYY_EFAS22 + t00.prevYY_EFAS11 + t00.prevYY_EFAS12 + t00.prevYY_EFAS26 + t00.prevYY_EFAS27 + t00.prevYY_EFAS48 + t00.prevYY_EFAS45 as prevYY_AMT 
FROM 
  	(
    SELECT DISTINCT 
    	t0.EFAS, 
	  	t0.DAMBO_TYPE, 
	  	-- 자동차(37) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '37' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS37, 
	  	SUM(CASE WHEN t0.EFAS = '37' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS37, 
	  	-- 조선(39) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '39' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS39, 
	  	SUM(CASE WHEN t0.EFAS = '39' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS39,
	  	-- 철강(22) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '22' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS22, 
	  	SUM(CASE WHEN t0.EFAS = '22' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS22,
	  	-- 정유(11) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '11' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS11, 
	  	SUM(CASE WHEN t0.EFAS = '11' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS11,
	  	-- 석유화학(12) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '12' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS12, 
	  	SUM(CASE WHEN t0.EFAS = '12' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS12,
	  	-- 반도체(26) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '26' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS26, 
	  	SUM(CASE WHEN t0.EFAS = '26' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS26,
	  	-- 디스플레이(27) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '27' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS27, 
	  	SUM(CASE WHEN t0.EFAS = '27' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS27,
	  	-- 해운(48) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '48' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS48, 
	  	SUM(CASE WHEN t0.EFAS = '48' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS48,
	  	-- 건설(45) 담보현황(현월, 전년동월)
	  	SUM(CASE WHEN t0.EFAS = '45' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS45, 
	  	SUM(CASE WHEN t0.EFAS = '45' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS45 
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
            CAST(t.GG_YM AS INTEGER) in (:inputGG_YM, :inputGG_YM - 100)	-- 당월 및 전년 동월 
        ) t0
  	) t00
WHERE 
	t00.EFAS in ('37', '39', '22', '11', '12', '26', '27', '48', '45')
ORDER BY 
  	To_number(t00.EFAS, '99'), DAMBO_TYPE;