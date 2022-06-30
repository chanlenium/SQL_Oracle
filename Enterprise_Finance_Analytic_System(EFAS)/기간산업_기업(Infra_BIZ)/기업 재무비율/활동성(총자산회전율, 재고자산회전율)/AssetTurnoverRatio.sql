/****************************************************************
 * 활동성 지표 추이 - 총자산회전율(=매출액/자산총계) 추이 (p.6, [그림4])
 * 활용 테이블 : GIUP_RAW, TCB_NICE_FNST(재무제표) -> ASSET_TURNOVER_RATIO_TB 테이블 만듦
 ****************************************************************/
-- (Standby) 월별, 산업별, 기업규모별 총자산회전율 테이블 ASSET_TURNOVER_RATIO_TB 생성 
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS ASSET_TURNOVER_RATIO_TB;
-- 테이블 생성 (기준년월, 법인번호, 기업규모, KSIC, 매출액, 총자산, EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO ASSET_TURNOVER_RATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC, 
      	t1.SALES, 
      	t1.ASSETS 
    FROM 
      	(
        SELECT 
          t000.COMP_CD, 
          t000.STD_DT, 
          t000.SALES, 
          t000.ASSETS 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT, 
              	t00.SALES, 
              	t00.ASSETS, 
              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.SALES) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as SALES,	-- 매출액
                  	SUM(t0.ASSETS) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as ASSETS -- 자산총계
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	t.ITEM_CD, 
                      	DECODE(t.ITEM_CD, '1000', t.AMT, 0) as SALES, -- 매출액
                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as ASSETS -- 자산총계
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	(t.REPORT_CD = '12' and t.ITEM_CD = '1000')
                      	OR (t.REPORT_CD = '11' and t.ITEM_CD = '5000')
                  	) t0 -- 매출액(1000), 자산총계(5000) 
                WHERE 
                  	t0.STD_DT in (	 -- 최근 4개년
	                	CONCAT('${inputYYYY}', '1231'),
	                	CONCAT('${inputYYYY}' - 1, '1231'),
	                	CONCAT('${inputYYYY}' - 2, '1231'),
	                	CONCAT('${inputYYYY}' - 3, '1231'))
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN GIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
      			AND t2.OSIDE_ISPT_YN = 'Y'
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- 결과 조회
SELECT * FROM ASSET_TURNOVER_RATIO_TB ORDER BY STD_YM;



/*************************************************
 * 기업규모별(대/중/소) 연도별 총자산회전율 (1: 대기업, 2: 중소기업, 3: 중견기업, 0: 대상아님)
 *************************************************/
SELECT DISTINCT 
	t.STD_YM, 
	CASE 
  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN t.COMP_SCL_DIVN_CD || ' 대기업'
  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN t.COMP_SCL_DIVN_CD || ' 중소기업'
  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN t.COMP_SCL_DIVN_CD || ' 중견기업'
  		ELSE t.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE,  
  	SUM(t.SALES) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_SALES, 
  	SUM(t.ASSETS) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_ASSETS, 
  	ROUND(SUM(t.SALES) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) / SUM(t.ASSETS) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD), 4) as ASSET_TURNOVER_RATIO 
FROM 
  	ASSET_TURNOVER_RATIO_TB t 
ORDER BY 
  	t.STD_YM;
 

 

  
/****************************************************************
 * 자기자본비율 : 업종별 현황 (p.6, [표])
 * 활용 테이블 : ASSET_TURNOVER_RATIO_TB -> EFAS_ASSET_TURNOVER_RATIO_TB 생성
 ****************************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS EFAS_ASSET_TURNOVER_RATIO_TB;
-- (Step1) 테이블 생성(업종코드, 당월 자본금, 당월 자본총계, 전년동월 자본금, 전년동월 자본총계
SELECT 
  	t0.EFAS, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), EFAS_SALES, 0)) as thisYY_EFAS_SALES, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), EFAS_ASSETS, 0)) as thisYY_EFAS_ASSETS, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), EFAS_SALES, 0)) as prevYY_EFAS_SALES, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), EFAS_ASSETS, 0)) as prevYY_EFAS_ASSETS 
  	INTO EFAS_ASSET_TURNOVER_RATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.EFAS, 
      	t.STD_YM, 
      	SUM(t.SALES) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_SALES, 
      	SUM(t.ASSETS) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_ASSETS 
    FROM 
      	ASSET_TURNOVER_RATIO_TB t 
    WHERE 
      	t.STD_YM in (	-- 당월 및 전년동월 선택
      		CONCAT('${inputYYYY}', '12'),
      		CONCAT('${inputYYYY}' - 1, '12')) 
  	) t0 
GROUP BY 
  	t0.EFAS;
-- 결과 조회
SELECT * FROM EFAS_ASSET_TURNOVER_RATIO_TB;


-- (Step 2) 총계 계산하여 insert
INSERT INTO EFAS_ASSET_TURNOVER_RATIO_TB 
SELECT 
  	'99', -- 총합은 EFAS code '00'할당 
  	SUM(t.thisYY_EFAS_SALES), 
  	SUM(t.thisYY_EFAS_ASSETS), 
  	SUM(t.prevYY_EFAS_SALES), 
  	SUM(t.prevYY_EFAS_ASSETS) 
FROM 
  	EFAS_ASSET_TURNOVER_RATIO_TB t;
-- 결과 조회
SELECT * FROM EFAS_ASSET_TURNOVER_RATIO_TB t; 


-- (Step3) 당해년/전년 동월 자기자본비율 및 전년 동월 대비 증가율 계산
SELECT 
  	t.*, 
  	ROUND(t.thisYY_EFAS_SALES / t.thisYY_EFAS_ASSETS, 4) as thisYY_ASSET_TURNOVER_RATIO, 
  	ROUND(t.prevYY_EFAS_SALES / t.prevYY_EFAS_ASSETS, 4) as prevYY_ASSET_TURNOVER_RATIO, 
  	ROUND(t.thisYY_EFAS_SALES / t.thisYY_EFAS_ASSETS - t.prevYY_EFAS_SALES / t.prevYY_EFAS_ASSETS, 4) as ASSET_TURNOVER_RATIO_INC 
FROM 
  	EFAS_ASSET_TURNOVER_RATIO_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');
