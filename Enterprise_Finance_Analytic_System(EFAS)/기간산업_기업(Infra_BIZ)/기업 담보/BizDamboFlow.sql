/**************************************
 *             기업담보 유동성(FLOW)           
 * 활용 테이블 : BASIC_BIZ_DAMBO, TCB_NICE_FNST -> 기업 담보유동성 기반 테이블(BASIC_BIZ_DAMBO_FLOW) 생성
 **************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BASIC_BIZ_DAMBO_FLOW_TB;
-- (Standby) 테이블 생성 (기준년월, 법인번호, 기업규모, 담보가액, EFAS, 고객번호, 총자산, 담보가액비율)
SELECT 
  	t10.*, 
  	t20.COMP_CD, 
  	t20.TOT_ASSET,
  	t10.BIZ_DAMBO_AMT / NULLIF(t20.TOT_ASSET, 0) as "targetRatio"
  	INTO BASIC_BIZ_DAMBO_FLOW_TB 
FROM 
  	(
    -- 연도별, 기업별 담보가액 합 테이블 생성
    SELECT DISTINCT 
     	t.GG_YM, 
       	t.CORP_NO, 
       	t.BIZ_SIZE,
       	SUM(t.BRNO_DAMBO_AMT) OVER(PARTITION BY t.GG_YM, t.CORP_NO, t.BIZ_SIZE) AS BIZ_DAMBO_AMT,
       	t.EFAS
    FROM 
       	BASIC_BIZ_DAMBO t 
    WHERE 
    	CAST(t.GG_YM AS INTEGER) IN (	-- 조회기준년 포함 직전 3개년도까지 조회
    		CAST(CONCAT( '${inputYYYY}', '12') as integer),
    		CAST(CONCAT( '${inputYYYY}', '12') as integer) - 100,
    		CAST(CONCAT( '${inputYYYY}', '12') as integer) - 200,
    		CAST(CONCAT( '${inputYYYY}', '12') as integer) - 300)
       	AND t.DAMBO_TYPE = '6' -- 담보유형(총계)
       	AND t.BRWR_NO_TP_CD = '3'	-- 법인만
		AND NVL(t.EFAS, '') <> '55'	-- 금융보험업 제외
    ORDER BY 
      	t.CORP_NO, t.GG_YM
  	) t10, 
  	(
    SELECT DISTINCT 
    	t2.CORP_NO, 
      	t1.* 
    FROM 
      	(
        SELECT 
          t0.COMP_CD, 
          SUBSTR(t0.STD_DT, 1, 6) as STD_YM, 
          t0.TOT_ASSET -- 총 자산
        FROM 
          	(
            SELECT 
              	t.STD_YM, 
              	t.COMP_CD, 
              	t.STD_DT, 
              	ROUND(t.AMT/1000, 0) as TOT_ASSET, -- 단위 변환(천원 -> 백만원)
              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용 
              	CAST(MAX(TO_NUMBER(t.STD_YM, '999999')) OVER(PARTITION BY t.COMP_CD, t.STD_DT) AS VARCHAR) as LAST_STD_YM 
            FROM 
              	TCB_NICE_FNST t 
            WHERE 
              	t.REPORT_CD = '11' -- 제무상태표 테이블
              	AND t.ITEM_CD = '5000' -- 총자산 컬럼
              	AND t.SEAC_DIVN = 'K'	-- 결산 컬럼
                AND CAST(SUBSTR(t.STD_DT, 1, 4) AS INTEGER)  IN (
                	CAST('${inputYYYY}' as INTEGER),
                	CAST('${inputYYYY}' as INTEGER) - 1,
                	CAST('${inputYYYY}' as INTEGER) - 2,
                	CAST('${inputYYYY}' as INTEGER) - 3)
          	) t0 
        WHERE 
          	t0.STD_YM = t0.LAST_STD_YM -- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용
      	) t1, TCB_NICE_COMP_OUTL t2 
    WHERE 
      	t1.COMP_CD = t2.COMP_CD -- 고객번호로 join
    ORDER BY 
      	t2.CORP_NO, t1.STD_YM
  	) t20
WHERE 
  	t10.CORP_NO = t20.CORP_NO 
  	AND t10.GG_YM = t20.STD_YM;
-- 결과 테이블 조회
SELECT t.* FROM BASIC_BIZ_DAMBO_FLOW_TB t;



/********************************************************************
 * 기업 담보 유동성 - 자산 대비 담보가액 추이 (보고서 p.1)
 * RFP p.12 [그림1] 자산 대비 담보가액 추이
 * 기업규모별 자산 대비 담보설정가액 연도별 그래프
 *******************************************************************/
-- (Step1) Calculate IQR cutoff
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS IQRcutOff_TB;
-- 기준년월, LQ(Q1), UQ(Q3), IQR(=UQ-LQ), LowerCutoff, UpperCutoff
SELECT 
	t0.*,
	t0.LQ - 1.5 * (t0.UQ - t0.LQ) as "LowerCutoff",
	t0.UQ + 1.5 * (t0.UQ - t0.LQ) as "UpperCutoff"
	INTO IQRcutOff_TB
FROM 
	(
	SELECT DISTINCT
		t.GG_YM,
		t.BIZ_SIZE,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as "LQ",
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as "UQ"	
	FROM 	
		BASIC_BIZ_DAMBO_FLOW_TB t
	) t0;
-- 결과 조회
SELECT * FROM IQRcutOff_TB ORDER BY GG_YM, BIZ_SIZE;



-- (Step2) cutoff 테이블 생성
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS Cutoff_BASIC_BIZ_DAMBO_FLOW_TB;
-- 테이블 생성
SELECT 
	t1.*
	INTO Cutoff_BASIC_BIZ_DAMBO_FLOW_TB
FROM
	BASIC_BIZ_DAMBO_FLOW_TB t1, IQRcutOff_TB t2
WHERE 
	t1.GG_YM = t2.GG_YM
	AND	t1.BIZ_SIZE = t2.BIZ_SIZE
	AND t1.targetRatio > t2.LowerCutoff
	AND t1.targetRatio < t2.UpperCutoff;
-- 결과 조회
SELECT * FROM Cutoff_BASIC_BIZ_DAMBO_FLOW_TB;



-- (Step3) 기업규모별 자산 대비 담보설정가액 비율
DROP TABLE IF EXISTS RESULT_DAMBO_TO_ASSET_RATIO;
SELECT
	t0.GG_YM,
	t0.TOT_DAMBO_TO_ASSET_RATIO,
	SUM(DECODE(t0.BIZ_SIZE, '1', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_BIZ_1",	-- 대기업
	SUM(DECODE(t0.BIZ_SIZE, '2', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_BIZ_2",	-- 중소기업
	SUM(DECODE(t0.BIZ_SIZE, '3', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_BIZ_3"	-- 중견기업
	INTO RESULT_DAMBO_TO_ASSET_RATIO
FROM 	
	(
	SELECT DISTINCT 
		t.GG_YM, 
		t.BIZ_SIZE,
		-- 기업규모별 자산 대비 담보설정가액 비율(Ratio)
		ROUND(AVG(targetRatio) OVER(PARTITION BY t.GG_YM, t.BIZ_SIZE), 4) as "DAMBO_TO_ASSET_RATIO",
		-- 전기업 자산 대비 담보설정가액 비율(Ratio)
		ROUND(AVG(targetRatio) OVER(PARTITION BY t.GG_YM), 4) as "TOT_DAMBO_TO_ASSET_RATIO"
	FROM 
	  	Cutoff_BASIC_BIZ_DAMBO_FLOW_TB t 
	ORDER BY 
	  	t.GG_YM
	) t0
WHERE 
	t0.BIZ_SIZE in ('1', '2', '3')
GROUP BY
	t0.GG_YM, t0.TOT_DAMBO_TO_ASSET_RATIO
ORDER BY
	t0.GG_YM;
 
 
 
 
  
  
  
  
  
   
/********************************************************************
 * 기업 담보 유동성 - 업종별 자산 대비 담보가액 (p.1)
 * RFP p.12 [그림2] 업종별 자산 대비 담보가액
 * 주요 산업 최근 3개년 그래프
 * (자동차: 37, 조선: 39, 철강: 22, 정유: 11, 석유화학: 12, 반도체: 26, 디스플레이: 27, 해운: 48, 건설: 45)
 *******************************************************************/
-- (Step1) Calculate IQR cutoff
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS IQRcutOff_TB;
-- 기준년월, LQ(Q1), UQ(Q3), IQR(=UQ-LQ), LowerCutoff, UpperCutoff
SELECT 
	t0.*,
	t0.LQ - 1.5 * (t0.UQ - t0.LQ) as "LowerCutoff",
	t0.UQ + 1.5 * (t0.UQ - t0.LQ) as "UpperCutoff"
	INTO IQRcutOff_TB
FROM 
	(
	SELECT DISTINCT
		t.GG_YM,
		t.EFAS,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.GG_YM, t.EFAS) as "LQ",
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.GG_YM, t.EFAS) as "UQ"	
	FROM 	
		BASIC_BIZ_DAMBO_FLOW_TB t
	) t0;
-- 결과 조회
SELECT * FROM IQRcutOff_TB ORDER BY GG_YM, EFAS;



-- (Step2) cutoff 테이블 생성
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS Cutoff_BASIC_BIZ_DAMBO_FLOW_TB;
-- 테이블 생성
SELECT 
	t1.*
	INTO Cutoff_BASIC_BIZ_DAMBO_FLOW_TB
FROM
	BASIC_BIZ_DAMBO_FLOW_TB t1, IQRcutOff_TB t2
WHERE 
	t1.GG_YM = t2.GG_YM
	AND	t1.EFAS = t2.EFAS
	AND t1.targetRatio > t2.LowerCutoff
	AND t1.targetRatio < t2.UpperCutoff;
-- 결과 조회
SELECT * FROM Cutoff_BASIC_BIZ_DAMBO_FLOW_TB;



-- (Step3) 주요산업별 자산 대비 담보설정가액 비율
DROP TABLE IF EXISTS RESULT_DAMBO_TO_ASSET_RATIO_EFAS;
SELECT
	t0.GG_YM,
	SUM(DECODE(t0.EFAS, '11', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS11",	-- 정유
	SUM(DECODE(t0.EFAS, '12', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS12",	-- 석유화학
	SUM(DECODE(t0.EFAS, '22', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS22",	-- 철강
	SUM(DECODE(t0.EFAS, '26', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS26",	-- 반도체
	SUM(DECODE(t0.EFAS, '27', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS27",	-- 디스플레이
	SUM(DECODE(t0.EFAS, '37', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS37",	-- 자동차
	SUM(DECODE(t0.EFAS, '39', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS39",	-- 조선
	SUM(DECODE(t0.EFAS, '45', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS45",	-- 건설
	SUM(DECODE(t0.EFAS, '48', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS48"		-- 해운
	INTO RESULT_DAMBO_TO_ASSET_RATIO_EFAS
FROM 	
	(
	SELECT DISTINCT 
		t.GG_YM, 
		t.EFAS,
		-- 주요산업별 자산 대비 담보설정가액 비율(Ratio)
		ROUND(AVG(targetRatio) OVER(PARTITION BY t.GG_YM, t.EFAS), 4) as "DAMBO_TO_ASSET_RATIO"
	FROM 
	  	Cutoff_BASIC_BIZ_DAMBO_FLOW_TB t 
	ORDER BY 
	  	t.GG_YM
	) t0
WHERE 
	t0.EFAS in ('37', '39', '22', '11', '12', '26', '27', '48', '45')
GROUP BY
	t0.GG_YM
ORDER BY
	t0.GG_YM;
	


-- 임시테이블 삭제
DROP TABLE IF EXISTS BASIC_BIZ_DAMBO_FLOW_TB;
DROP TABLE IF EXISTS IQRcutOff_TB;
DROP TABLE IF EXISTS Cutoff_BASIC_BIZ_DAMBO_FLOW_TB;


-- 결과 조회
SELECT * FROM RESULT_DAMBO_TO_ASSET_RATIO ORDER BY GG_YM;
SELECT * FROM RESULT_DAMBO_TO_ASSET_RATIO_EFAS ORDER BY GG_YM;