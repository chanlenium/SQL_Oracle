/****************************************************************
 * 건전성 지표 추이 - 자기자본비율(=자본/총자본) 추이 (p.6, [그림4])
 * 활용 테이블 : GIUP_RAW, TCB_NICE_FNST(재무제표) -> EQUITYRATIO_TB 테이블 만듦
 ****************************************************************/
-- (Standby) 월별, 산업별, 기업규모별 이자보상배율 테이블 EQUITYRATIO_TB 생성 
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS EQUITYRATIO_TB;
-- 테이블 생성 (기준년월, 법인번호, 기업규모, KSIC, 자본금, 자본총계, EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO EQUITYRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC, 
      	t1.CAP_STOCK, 
      	t1.TOT_STOCK 
    FROM 
      	(
        SELECT 
          t000.COMP_CD, 
          t000.STD_DT, 
          t000.CAP_STOCK, 
          t000.TOT_STOCK 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT, 
              	t00.CAP_STOCK, 
              	t00.TOT_STOCK, 
              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.CAP_STOCK) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as CAP_STOCK,	-- 자본금
                  	SUM(t0.TOT_STOCK) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as TOT_STOCK -- 자본총계
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	t.ITEM_CD, 
                      	DECODE(t.ITEM_CD, '8100', t.AMT, 0) as CAP_STOCK, -- 자본금
                      	DECODE(t.ITEM_CD, '8900', t.AMT, 0) as TOT_STOCK -- 자본총계(총자산)
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	t.REPORT_CD = '11' 
                      	and t.ITEM_CD in ('8100', '8900')
                  	) t0 -- 자본금(8100), 자본총계(8900) 
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
SELECT * FROM EQUITYRATIO_TB ORDER BY STD_YM;



/*************************************************
 * 기업규모별(대/중/소) 연도별 자기자본비율 (1: 대기업, 2: 중소기업, 3: 중견기업, 0: 대상아님)
 *************************************************/
SELECT DISTINCT 
	t.STD_YM, 
	CASE 
  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN t.COMP_SCL_DIVN_CD || ' 대기업'
  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN t.COMP_SCL_DIVN_CD || ' 중소기업'
  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN t.COMP_SCL_DIVN_CD || ' 중견기업'
  		ELSE t.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE,  
  	SUM(t.CAP_STOCK) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_CAP_STOCK, 
  	SUM(t.TOT_STOCK) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_TOT_STOCK, 
  	ROUND(SUM(t.CAP_STOCK) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) / SUM(t.TOT_STOCK) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD), 4) as CAPITAL_ADEQUACY_RATIO 
FROM 
  	EQUITYRATIO_TB t 
ORDER BY 
  	t.STD_YM;
 

 

  
/****************************************************************
 * 자기자본비율 : 업종별 현황 (p.6, [표])
 * 활용 테이블 : EQUITYRATIO_TB -> EFAS_EQUITYRATIO_TB 생성
 ****************************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS EFAS_EQUITYRATIO_TB;
-- (Step1) 테이블 생성(업종코드, 당월 자본금, 당월 자본총계, 전년동월 자본금, 전년동월 자본총계
SELECT 
  	t0.EFAS, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), EFAS_CAP_STOCK, 0)) as thisYY_EFAS_CAP_STOCK, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), EFAS_TOT_STOCK, 0)) as thisYY_EFAS_TOT_STOCK, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), EFAS_CAP_STOCK, 0)) as prevYY_EFAS_CAP_STOCK, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), EFAS_TOT_STOCK, 0)) as prevYY_EFAS_TOT_STOCK 
  	INTO EFAS_EQUITYRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.EFAS, 
      	t.STD_YM, 
      	SUM(t.CAP_STOCK) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_CAP_STOCK, 
      	SUM(t.TOT_STOCK) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_TOT_STOCK 
    FROM 
      	EQUITYRATIO_TB t 
    WHERE 
      	t.STD_YM in (	-- 당월 및 전년동월 선택
      		CONCAT('${inputYYYY}', '12'),
      		CONCAT('${inputYYYY}' - 1, '12'))
  	) t0 
GROUP BY 
  	t0.EFAS;
-- 결과 조회
SELECT * FROM EFAS_EQUITYRATIO_TB;


-- (Step 2) 총계 계산하여 insert
INSERT INTO EFAS_EQUITYRATIO_TB 
SELECT 
  	'99', -- 총합은 EFAS code '00'할당 
  	SUM(t.thisYY_EFAS_CAP_STOCK), 
  	SUM(t.thisYY_EFAS_TOT_STOCK), 
  	SUM(t.prevYY_EFAS_CAP_STOCK), 
  	SUM(t.prevYY_EFAS_TOT_STOCK) 
FROM 
  	EFAS_EQUITYRATIO_TB t;
-- 결과 조회
SELECT * FROM EFAS_EQUITYRATIO_TB t; 


-- (Step3) 당해년/전년 동월 자기자본비율 및 전년 동월 대비 증가율 계산
SELECT 
  	t.*, 
  	ROUND(t.thisYY_EFAS_CAP_STOCK / t.thisYY_EFAS_TOT_STOCK, 4) as thisYY_CAPITAL_ADEQUACY_RATIO, 
  	ROUND(t.prevYY_EFAS_CAP_STOCK / t.prevYY_EFAS_TOT_STOCK, 4) as prevYY_CAPITAL_ADEQUACY_RATIO, 
  	ROUND(t.thisYY_EFAS_CAP_STOCK / t.thisYY_EFAS_TOT_STOCK - t.prevYY_EFAS_CAP_STOCK / t.prevYY_EFAS_TOT_STOCK, 4) as CAPITAL_ADEQUACY_RATIO_INC 
FROM 
  	EFAS_EQUITYRATIO_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');