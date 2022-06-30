/****************************************************************
 * 수익성 지표 추이 - 총자산영업이익률(=영업이익/자산총계) 추이 (p.6, [그림4])
 * 활용 테이블 : newGIUP_RAW, TCB_NICE_FNST(재무제표) -> RETURN_ON_ASSETS_TB 테이블 만듦
 ****************************************************************/
-- (Standby) 월별, 산업별, 기업규모별 총자산영업이익률 테이블 RETURN_ON_ASSETS_TB 생성 
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS RETURN_ON_ASSETS_TB;
-- 테이블 생성 (기준년월, 법인번호, 기업규모, KSIC, newINDU, newINDU_NM, 영업이익, 자산총계, EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO RETURN_ON_ASSETS_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC,
      	t2.newINDU,
      	t2.newINDU_NM,
      	t1.INCOME, 
      	t1.ASSETS
    FROM 
      	(
        SELECT 
          t000.COMP_CD, 
          t000.STD_DT,
          t000.INCOME,
          t000.ASSETS 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT,
              	t00.INCOME,
              	t00.ASSETS,  
              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.INCOME) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as INCOME, -- 영업이익
                  	SUM(t0.ASSETS) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as ASSETS	-- 총자산
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	t.ITEM_CD,          
                      	CASE WHEN t.REPORT_CD = '12' and t.ITEM_CD = '5000' THEN t.AMT ELSE 0 END as INCOME, -- 영업이익
                      	CASE WHEN t.REPORT_CD = '11' and t.ITEM_CD = '5000' THEN t.AMT ELSE 0 END as ASSETS -- 총자산
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	(t.REPORT_CD = '12' and t.ITEM_CD = '5000')
                      	OR (t.REPORT_CD = '11' and t.ITEM_CD = '5000')
                  	) t0 -- 영업이익(12/5000), 총자산(11/5000) 
                WHERE 
                  	t0.STD_DT IN (	 -- 최근 4개년
	                	CONCAT('${inputYYYY}', '1231'),
	                	CONCAT('${inputYYYY}' - 1, '1231'),
	                	CONCAT('${inputYYYY}' - 2, '1231'),
	                	CONCAT('${inputYYYY}' - 3, '1231')) 
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN newGIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
      			AND t2.OSIDE_ISPT_YN = 'Y'      		
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- 결과 조회
SELECT * FROM RETURN_ON_ASSETS_TB ORDER BY STD_YM;



/*************************************************
 * 기업규모별(대/중/소) 연도별 총자산영업이익률 (1: 대기업, 2: 중소기업, 3: 중견기업, 0: 대상아님)
 *************************************************/
SELECT DISTINCT 
	t.STD_YM, 
	CASE 
  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN t.COMP_SCL_DIVN_CD || ' 대기업'
  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN t.COMP_SCL_DIVN_CD || ' 중소기업'
  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN t.COMP_SCL_DIVN_CD || ' 중견기업'
  		ELSE t.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE,  
  	SUM(t.INCOME) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_INCOME, 
  	SUM(t.ASSETS) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_ASSETS, 
  	ROUND(SUM(t.INCOME) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) / SUM(t.ASSETS) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD), 4) as RETURN_ON_ASSETS_RATIO 
FROM 
	(
	SELECT DISTINCT 
		t.STD_YM, 
		t.CORP_NO, 
		t.COMP_SCL_DIVN_CD, 
		t.INCOME,
		t.ASSETS 
	FROM 
		RETURN_ON_ASSETS_TB t	-- 동일 법인번호에 newINDU가 여러개 매핑되는 경우 재무규모가 과대개상될 수 있어 이를 제거
	) t 
ORDER BY 
  	t.STD_YM;
 


  
  
/****************************************************************
 * 총자산영업이익률 : 업종별 현황 (p.6, [표])
 * 활용 테이블 : RETURN_ON_ASSETS_TB -> INDU_RETURN_ON_ASSETS_TB 생성
 ****************************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS INDU_RETURN_ON_ASSETS_TB;
-- (Step1) 테이블 생성(업종코드, 당월 영업이익, 당월 총자산, 전년동월 영업이익, 전년동월 총자산
SELECT DISTINCT
  	t0.newINDU, 
  	t0.newINDU_NM,  	
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), INDU_INCOME, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_INCOME,
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), INDU_ASSETS, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_ASSETS, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), INDU_INCOME, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_INCOME,
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), INDU_ASSETS, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_ASSETS 
  	INTO INDU_RETURN_ON_ASSETS_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.newINDU, 
    	t.newINDU_NM, 
      	t.STD_YM, 
      	SUM(t.INCOME) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_INCOME,
      	SUM(t.ASSETS) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_ASSETS 
    FROM 
      	RETURN_ON_ASSETS_TB t 
    WHERE 
      	t.STD_YM in (	-- 당월 및 전년동월 선택
      		CONCAT('${inputYYYY}', '12'),
      		CONCAT('${inputYYYY}' - 1, '12')) 
  	) t0;
-- 결과 조회
SELECT * FROM INDU_RETURN_ON_ASSETS_TB;


-- (Step 2) 총계 계산하여 insert
INSERT INTO INDU_RETURN_ON_ASSETS_TB 
SELECT 
  	'99', -- 총합은 newINDU code '00'할당
  	'전체', 
  	SUM(t.thisYY_INDU_INCOME), 
  	SUM(t.thisYY_INDU_ASSETS), 
  	SUM(t.prevYY_INDU_INCOME),
  	SUM(t.prevYY_INDU_ASSETS) 
FROM 
  	INDU_RETURN_ON_ASSETS_TB t;
-- 결과 조회
SELECT * FROM INDU_RETURN_ON_ASSETS_TB t; 


-- (Step3) 당해년/전년 동월 매출액영업이익률 및 전년 동월 대비 증가율 계산
SELECT 
  	t.*, 
  	ROUND(t.thisYY_INDU_INCOME / t.thisYY_INDU_ASSETS, 4) as thisYY_RETURN_ON_ASSETS, 
  	ROUND(t.prevYY_INDU_INCOME / t.prevYY_INDU_ASSETS, 4) as prevYY_RETURN_ON_ASSETS, 
  	ROUND(t.thisYY_INDU_INCOME / t.thisYY_INDU_ASSETS - t.prevYY_INDU_INCOME / t.prevYY_INDU_ASSETS, 4) as RETURN_ON_ASSETS_INC 
FROM 
  	INDU_RETURN_ON_ASSETS_TB t 
ORDER BY 
  	t.newINDU;