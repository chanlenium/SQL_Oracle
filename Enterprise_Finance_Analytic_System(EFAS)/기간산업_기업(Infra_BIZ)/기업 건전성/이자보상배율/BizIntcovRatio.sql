/****************************************************************
 * 건전성 지표 추이 - 이자보상배율(=영업이익/이자비용) 추이 (p.6, [그림4])
 * 활용 테이블 : GIUP_RAW, TCB_NICE_FNST(재무제표) -> INTCOVRATIO_TB 테이블 만듦
 ****************************************************************/
-- (Standby) 월별, 산업별, 기업규모별 이자보상배율 테이블 INTCOVRATIO_TB 생성 
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS INTCOVRATIO_TB;
-- 테이블 생성 (기준년월, 법인번호, 기업규모, KSIC, 영업이익, 이자비용, EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO INTCOVRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC, 
      	t1.INT_EXP, 
      	t1.OP_PROFIT 
    FROM 
      	(
        SELECT 
          t000.COMP_CD, 
          t000.STD_DT, 
          t000.INT_EXP, 
          t000.OP_PROFIT 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT, 
              	t00.INT_EXP, 
              	t00.OP_PROFIT, 
              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.INT_EXP) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as INT_EXP,	-- 이자비용
                  	SUM(t0.OP_PROFIT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as OP_PROFIT -- 영업이익
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	t.ITEM_CD, 
                      	DECODE(t.ITEM_CD, '6110', t.AMT, 0) as INT_EXP, -- 이자비용
                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as OP_PROFIT -- 영업이익
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	t.REPORT_CD = '12' 
                      	and t.ITEM_CD in ('6110', '5000')
                  	) t0 -- 이자비용(6110), 영업이익(5000)
                WHERE 
	                CAST(t0.STD_DT AS INTEGER)  IN (		-- 최근 4개년
	                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER),
	                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 10000,
	                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 20000,
	                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 30000)
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN GIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- 결과 조회
SELECT * FROM INTCOVRATIO_TB ORDER BY STD_YM;


-- 이자보상배율 연별 그래프 (대/중/소) (1: 대기업, 2: 중소기업, 3: 중견기업, 0: 대상아님)
SELECT DISTINCT 
	t.STD_YM, 
	CASE 
  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN t.COMP_SCL_DIVN_CD || ' 대기업'
  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN t.COMP_SCL_DIVN_CD || ' 중소기업'
  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN t.COMP_SCL_DIVN_CD || ' 중견기업'
  		ELSE t.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE,  
  	SUM(t.INT_EXP) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_INT_EXP, 
  	SUM(t.OP_PROFIT) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_OP_PROFIT, 
  	ROUND(SUM(t.OP_PROFIT) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) / SUM(t.INT_EXP) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD), 4) as DEBT_RATIO 
FROM 
  	INTCOVRATIO_TB t 
WHERE 
	CAST(t.STD_YM AS INTEGER) <= ${inputGG_YM}
ORDER BY 
  	t.STD_YM;
 
 
 
 
 
/****************************************************************
 * 이자보상배율 : 업종별 현황 (p.6, [표])
 * 활용 테이블 : INTCOVRATIO_TB -> EFAS_INTCOVRATIO_TB 생성
 ****************************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS EFAS_INTCOVRATIO_TB;
-- (Step1) 테이블 생성(업종코드, 당월 이자비용, 당월 영업이익, 전년동월 이자비용(분자), 전년동월 영업이익(분모)
SELECT 
  	t0.EFAS, 
  	SUM(DECODE(t0.STD_YM, CONCAT( '${inputYYYY}', '12'), EFAS_INT_EXP, 0)) as thisYY_EFAS_INT_EXP, 
  	SUM(DECODE(t0.STD_YM, CONCAT( '${inputYYYY}', '12'), EFAS_OP_PROFIT, 0)) as thisYY_EFAS_OP_PROFIT, 
  	SUM(DECODE(t0.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), EFAS_INT_EXP, 0)) as prevYY_EFAS_INT_EXP, 
  	SUM(DECODE(t0.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), EFAS_OP_PROFIT, 0)) as prevYY_EFAS_OP_PROFIT 
  	INTO EFAS_INTCOVRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.EFAS, 
      	t.STD_YM, 
      	SUM(t.INT_EXP) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_INT_EXP, 
      	SUM(t.OP_PROFIT) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_OP_PROFIT 
    FROM 
      	INTCOVRATIO_TB t 
    WHERE 
      	CAST(t.STD_YM AS INTEGER) IN (	-- 당월 및 전년 동월
    			CAST(CONCAT( '${inputYYYY}', '12') as integer),
    			CAST(CONCAT( '${inputYYYY}', '12') as integer) - 100) 
  	) t0 
GROUP BY 
  	t0.EFAS;
-- 결과 조회
SELECT * FROM EFAS_INTCOVRATIO_TB;


-- (Step 2) 총계 계산하여 insert
INSERT INTO EFAS_INTCOVRATIO_TB 
SELECT 
  	'99', -- 총합은 EFAS code '00'할당 
  	SUM(t.thisYY_EFAS_INT_EXP), 
  	SUM(t.thisYY_EFAS_OP_PROFIT), 
  	SUM(t.prevYY_EFAS_INT_EXP), 
  	SUM(t.prevYY_EFAS_OP_PROFIT) 
FROM 
  	EFAS_INTCOVRATIO_TB t;
-- 결과 조회
SELECT * FROM EFAS_INTCOVRATIO_TB t; 


-- (Step3) 당해년/전년 동월 부채비율 및 전년 동월 대비 증가율 계산
SELECT 
  	t.*, 
  	ROUND(t.thisYY_EFAS_OP_PROFIT / t.thisYY_EFAS_INT_EXP, 4) as thisYY_INTCOVRATIO, 
  	ROUND(t.prevYY_EFAS_OP_PROFIT / t.prevYY_EFAS_INT_EXP, 4) as prevYY_INTCOVRATIO, 
  	ROUND(t.thisYY_EFAS_OP_PROFIT / t.thisYY_EFAS_INT_EXP - t.prevYY_EFAS_OP_PROFIT / t.prevYY_EFAS_INT_EXP, 4) as INTCOVRATIOINC 
FROM 
  	EFAS_INTCOVRATIO_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');