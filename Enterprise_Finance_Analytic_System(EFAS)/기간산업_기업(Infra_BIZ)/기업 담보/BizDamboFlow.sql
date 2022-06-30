/**************************************
 *             기업담보 유동성(FLOW)           
 * 활용 테이블 : BASIC_BIZ_DAMBO, TCB_NICE_FNST -> 기업 담보유동성 기반 테이블(BASIC_BIZ_DAMBO_FLOW) 생성
 **************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BASIC_BIZ_DAMBO_FLOW;
-- 테이블 생성 
SELECT 
  	t10.*, 
  	t20.COMP_CD, 
  	t20.TOT_ASSET   	INTO BASIC_BIZ_DAMBO_FLOW 
FROM 
  	(
    -- 연도별, 기업별 담보가액 합 테이블 생성
    SELECT DISTINCT 
     	t.GG_YM, 
       	t.CORP_NO, 
       	SUM(t.BRNO_DAMBO_AMT) OVER(PARTITION BY t.GG_YM, t.CORP_NO) AS BIZ_DAMBO_AMT,
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
              	t.AMT as TOT_ASSET, 
              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용 
              	CAST(MAX(TO_NUMBER(t.STD_YM, '999999')) OVER(PARTITION BY t.COMP_CD, t.STD_DT) AS VARCHAR) as LAST_STD_YM 
            FROM 
              	TCB_NICE_FNST t 
            WHERE 
              	t.REPORT_CD = '11' -- 제무상태표 테이블
              	AND t.ITEM_CD = '5000' -- 총자산 컬럼
                AND CAST(t.STD_DT AS INTEGER)  IN (
                	CAST(CONCAT('${inputYYYY}', '1231') as INTEGER),
                	CAST(CONCAT('${inputYYYY}', '1231') as INTEGER) - 10000,
                	CAST(CONCAT('${inputYYYY}', '1231') as INTEGER) - 20000,
                	CAST(CONCAT('${inputYYYY}', '1231') as INTEGER) - 30000)
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
SELECT t.* FROM BASIC_BIZ_DAMBO_FLOW t;
 
 
 


/********************************************************************
 * 기업 담보 유동성 - 자산 대비 담보가액 추이 (p.1)
 * 자산 대비 담보설정가액 연도별 그래프
 *******************************************************************/
SELECT DISTINCT 
	t.GG_YM, 
	-- 연도별 담보설정가액
  	SUM(t.BIZ_DAMBO_AMT) OVER(PARTITION BY t.GG_YM) as DAMBO_YY, 
  	-- 연도별 총자산
  	ROUND(SUM(t.TOT_ASSET / 1000) OVER(PARTITION BY t.GG_YM), 0) as TOT_ASSET_YY, 
  	-- 자산 대비 담보설정가액 비율(Ratio)
  	ROUND((SUM(t.BIZ_DAMBO_AMT) OVER(PARTITION BY t.GG_YM)) / (SUM(t.TOT_ASSET / 1000) OVER(PARTITION BY t.GG_YM)), 4) as DAMBO_TO_ASSET_RATIO 
FROM 
  	BASIC_BIZ_DAMBO_FLOW t 
ORDER BY 
  	t.GG_YM;
 
 
 
 
 
/********************************************************************
 * 기업 담보 유동성 - 산업별 자산 대비 담보가액 (p.1)
 * 주요 산업 최근 3개년 그래프
 * (자동차: 37, 조선: 39, 철강: 22, 정유: 11, 석유화학: 12, 반도체: 26, 디스플레이: 27, 해운: 48, 건설: 45)
 *******************************************************************/
SELECT DISTINCT 
	TO_NUMBER(t.EFAS, '99'), 
  	t.GG_YM, 
  	-- 연도별 담보설정가액
  	SUM(t.BIZ_DAMBO_AMT) OVER(PARTITION BY t.GG_YM, t.EFAS) as EFAS_DAMBO_YY, 
  	 -- 연도별 총자산
  	ROUND(SUM(t.TOT_ASSET / 1000) OVER(PARTITION BY t.GG_YM, t.EFAS), 0) as EFAS_TOT_ASSET_YY, 
   -- 산업별 자산 대비 담보설정가액 비율(Ratio)
  	ROUND((SUM(t.BIZ_DAMBO_AMT) OVER(PARTITION BY t.GG_YM, t.EFAS)) / (SUM(t.TOT_ASSET / 1000) OVER(PARTITION BY t.GG_YM, t.EFAS)), 2) as DAMBO_TO_ASSET_RATIO 
FROM 
  	BASIC_BIZ_DAMBO_FLOW t
WHERE t.EFAS in ('37', '39', '22', '11', '12', '26', '27', '48', '45')
ORDER BY 
  	TO_NUMBER(t.EFAS, '99'), 
  	t.GG_YM;