/*****************************************************
 * 신산업 건전성 지표 추이 - 한계기업 추이 (p.6, [그림5])
 * (정의1) 최직근년도 영업적자, (정의2) 2년 연속 영업적자, (정의3) 3년 연속 영업적자
 *****************************************************/
-- (Step1) TCB_NICE_FNST, newGIUP_RAW -> OP_PROFIT_TB 생성
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS OP_PROFIT_TB;
-- 테이블 생성(기준년월, 법인번호, 기업규모, 외감여부, 상장구분, KSIC, 신산업코드, 신산업명, 영업이익(손실), EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO OP_PROFIT_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.OSIDE_ISPT_YN,
      	t2.BLIST_MRKT_DIVN_CD,
      	t2.KSIC, 
      	t2.newINDU,
      	t2.newINDU_NM,
      	t1.OPPROFIT 
    FROM 
      	(
        SELECT 
          	t000.COMP_CD, 
          	t000.STD_DT, 
          	t000.OPPROFIT 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT, 
              	t00.OPPROFIT, 
              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.OPPROFIT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as OPPROFIT -- 영업이익
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as OPPROFIT -- 영업이익(손실)
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	t.REPORT_CD = '12' AND t.ITEM_CD = '5000'
                      	AND t.STD_DT in (	 -- 최근 5개년
	                			CONCAT('${inputYYYY}', '1231'),
	                			CONCAT('${inputYYYY}' - 1, '1231'),
	                			CONCAT('${inputYYYY}' - 2, '1231'),
	                			CONCAT('${inputYYYY}' - 3, '1231'),
	                			CONCAT('${inputYYYY}' - 4, '1231'))
                  	) t0                   	
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN newGIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
    ORDER BY 
      	t2.CORP_NO, 
      	SUBSTR(t1.STD_DT, 1, 6)
  	) t10, 
  	KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC
  	AND t10.OSIDE_ISPT_YN = 'Y';	-- 외감 대상
-- 결과 조회
SELECT * FROM OP_PROFIT_TB;

  
    
-- (Step2) OP_PROFIT_TB -> newINDU_OP_PROFIT_TB 생성
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS newINDU_OP_PROFIT_TB;
-- 테이블 생성
SELECT DISTINCT 
	t0000.STD_YM, 
  	t0000.newINDU,
  	t0000.newINDU_NM,
  	CASE 
		WHEN t0000.COMP_SCL_DIVN_CD = 1 THEN t0000.COMP_SCL_DIVN_CD || ' 대기업'
		WHEN t0000.COMP_SCL_DIVN_CD = 2 THEN t0000.COMP_SCL_DIVN_CD || ' 중소기업'
		WHEN t0000.COMP_SCL_DIVN_CD = 3 THEN t0000.COMP_SCL_DIVN_CD || ' 중견기업'
	ELSE t0000.COMP_SCL_DIVN_CD
	END as BIZ_SIZE,
  	SUM(CASE WHEN t0000.CONTLOSSYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N1_LOSS,	-- 1개년 적자 기업수
  	SUM(CASE WHEN t0000.CONTLOSSYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N2_LOSS, 	-- 2개년 연속 적자 기업수
  	SUM(CASE WHEN t0000.CONTLOSSYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N3_LOSS, 	-- 3개년 연속 적자 기업수
  	COUNT(t0000.CORP_NO) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNTTOTCORP	-- 전체기업수
  	INTO newINDU_OP_PROFIT_TB
FROM 
  	(
    SELECT 
      t000.*, 
      CASE WHEN t000.OPPROFIT < 0 THEN 
      	CASE WHEN t000.N_1_OPPROFIT < 0 THEN 
      		CASE WHEN t000.N_2_OPPROFIT < 0 THEN 3 -- 3년연속 적자 
      		ELSE 2 -- 2년연속 적자
      	END ELSE 1 -- 최직근년도 적자
      END ELSE 0 END as CONTLOSSYY -- 연속 적자 년수
    FROM 
      	(
        SELECT DISTINCT 
        	t00.STD_YM, 
          	t00.CORP_NO, 
         	t00.COMP_SCL_DIVN_CD, 
          	t00.EFAS, 
          	t00.newINDU,
          	t00.newINDU_NM,
          	t00.OPPROFIT, -- 최직근년도 영업이익(손실)
          	t00.N_1_OPPROFIT,	-- 2년전 영업이익(손실)
          	t00.N_2_OPPROFIT -- 3년전 영업이익(손실)
        FROM 
          	(
            SELECT 
              	t10.*, 
              	t20.OPPROFIT as N_2_OPPROFIT -- 3년전 영업이익(손실)
            FROM 
              	(
                SELECT 
                  	t1.*, 
                  	t2.OPPROFIT as N_1_OPPROFIT -- 2년전 영업이익(손실)
                FROM 
                  	OP_PROFIT_TB t1 
                  	LEFT JOIN OP_PROFIT_TB t2 
                  		ON t1.CORP_NO = t2.CORP_NO 
                  		AND TO_NUMBER(t1.STD_YM) -100 = TO_NUMBER(t2.STD_YM)
              	) t10 
              	LEFT JOIN OP_PROFIT_TB t20 
              		ON t10.CORP_NO = t20.CORP_NO 
              		AND TO_NUMBER(t10.STD_YM) -200 = TO_NUMBER(t20.STD_YM)
          	) t00 
        WHERE 
          	t00.STD_YM in (	 -- 최근 3개년
	        	CONCAT('${inputYYYY}', '12'),
	            CONCAT('${inputYYYY}' - 1, '12'),
	            CONCAT('${inputYYYY}' - 2, '12'))
      	) t000
  	) t0000;
-- 결과 조회
SELECT * FROM newINDU_OP_PROFIT_TB ORDER BY STD_YM, newINDU, BIZ_SIZE;


-- (Step3) 총계 계산하여 insert
INSERT INTO newINDU_OP_PROFIT_TB 
SELECT DISTINCT
	t.STD_YM,
  	t.newINDU,
  	t.newINDU_NM,
  	'99 전체' as BIZ_SIZE,	-- 대/중/소 전제 
  	SUM(t.CNT_N1_LOSS) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N1_LOSS, 
  	SUM(t.CNT_N2_LOSS) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N2_LOSS, 
  	SUM(t.CNT_N3_LOSS) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N3_LOSS,
  	SUM(t.CNTTOTCORP) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNTTOTCORP
FROM 
  	newINDU_OP_PROFIT_TB t;
-- 결과 조회
SELECT * FROM newINDU_OP_PROFIT_TB t ORDER BY t.STD_YM, t.newINDU, t.BIZ_SIZE;






  
  
  
  
  
/*****************************************************
 * 건전성 지표 추이 - 한계기업 추이 (p.6, [그림5])
 * (정의4) 최직근년도 이자보상배율 1미만, (정의5) 2년연속 이자보상배율 1미만, (정의6) 3년연속 이자보상배율 1미만
 * 활용 테이블 : TCB_NICE_FNST, newGIUP_RAW -> InterestCoverageRatio_TB 생성
 *****************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS InterestCoverageRatio_TB;
-- (Standby) InterestCoverageRatio_TB 테이블 생성(기준년월, 법인번호, 기업규모, KSIC, 영업이익(손실), 업종코드)로 구성
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO InterestCoverageRatio_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
     	t2.COMP_SCL_DIVN_CD, 
     	t2.OSIDE_ISPT_YN,
      	t2.BLIST_MRKT_DIVN_CD,
      	t2.KSIC,
      	t2.newINDU,
      	t2.newINDU_NM,
      	t1.OPPROFIT, 
      	t1.INTEXP, 
      	ROUND(t1.OPPROFIT / DECODE(t1.INTEXP, 0, 1, t1.INTEXP), 2) as INTCOVRATIO 
    FROM 
      	(
        SELECT 
          	t000.COMP_CD, 
          	t000.STD_DT, 
          	t000.INTEXP, 
          	t000.OPPROFIT 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT, 
              	t00.INTEXP, 
              	t00.OPPROFIT, 
              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.INTEXP) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as INTEXP,	-- 이자비용
                  	SUM(t0.OPPROFIT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as OPPROFIT -- 영업이익
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as OPPROFIT,	-- 영업이익(손실)
                      	DECODE(t.ITEM_CD, '6110', t.AMT, 0) as INTEXP	-- 영업이익(손실)
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	t.REPORT_CD = '12' 
                      	AND t.ITEM_CD in ('5000', '6110') -- 영업이익(5000), 이자비용(6110) 
                      	AND t.STD_DT in (	 -- 최근 5개년
	                		CONCAT('${inputYYYY}', '1231'),
	                		CONCAT('${inputYYYY}' - 1, '1231'),
	                		CONCAT('${inputYYYY}' - 2, '1231'),
	                		CONCAT('${inputYYYY}' - 3, '1231'),
	                		CONCAT('${inputYYYY}' - 4, '1231'))
                  	) t0
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN newGIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
  	) t10, 
  	KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC
  	AND t10.OSIDE_ISPT_YN = 'Y';	-- 외감 대상;
-- 결과 조회
SELECT * FROM InterestCoverageRatio_TB; 


  
-- (Step2) InterestCoverageRatio_TB -> newINDU_InterestCoverageRatio_TB 생성
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS newINDU_InterestCoverageRatio_TB;
-- 테이블 생성
SELECT DISTINCT 
	t0000.STD_YM, 
  	t0000.newINDU,
    t0000.newINDU_NM,
    CASE 
		WHEN t0000.COMP_SCL_DIVN_CD = 1 THEN t0000.COMP_SCL_DIVN_CD || ' 대기업'
		WHEN t0000.COMP_SCL_DIVN_CD = 2 THEN t0000.COMP_SCL_DIVN_CD || ' 중소기업'
		WHEN t0000.COMP_SCL_DIVN_CD = 3 THEN t0000.COMP_SCL_DIVN_CD || ' 중견기업'
		ELSE t0000.COMP_SCL_DIVN_CD
	END as BIZ_SIZE,
  	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N1_UNDERINTCOV, 
  	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N2_UNDERINTCOV, 
  	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N3_UNDERINTCOV,
  	COUNT(t0000.CORP_NO) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNTTOTCORP
  	INTO newINDU_InterestCoverageRatio_TB
FROM 
  	(
    SELECT 
      	t000.*, 
      	CASE WHEN t000.INTCOVRATIO < 1 THEN 
      		CASE WHEN t000.N_1_INTCOVRATIO < 1 THEN 
      			CASE WHEN t000.N_2_INTCOVRATIO < 1 THEN 3 -- 3년연속 이자보생배율 1미만
      				ELSE 2 -- 2년연속 이자보생배율 1미만
      			END ELSE 1 -- 최직근년도 이자보생배율 1미만
      		END ELSE 0 
      	END as CONTUNDERINTCOVYY -- 연속 이자보생배율 1미만 년수
    FROM 
      	(
        SELECT DISTINCT 
        	t00.STD_YM, 
          	t00.CORP_NO, 
          	t00.COMP_SCL_DIVN_CD, 
          	t00.EFAS, 
          	t00.newINDU,
      		t00.newINDU_NM,
          	t00.INTCOVRATIO, 
          	t00.N_1_INTCOVRATIO, 
          	t00.N_2_INTCOVRATIO 
        FROM 
          	(
            SELECT 
              	t10.*, 
              	t20.INTCOVRATIO as N_2_INTCOVRATIO 
            FROM 
              	(
                SELECT 
                  	t1.*, 
                  	t2.INTCOVRATIO as N_1_INTCOVRATIO 
                FROM 
                  	InterestCoverageRatio_TB t1 
                  	LEFT JOIN InterestCoverageRatio_TB t2 
                  		ON t1.CORP_NO = t2.CORP_NO 
                  		AND TO_NUMBER(t1.STD_YM) -100 = TO_NUMBER(t2.STD_YM)
              	) t10 
              	LEFT JOIN InterestCoverageRatio_TB t20 
              		ON t10.CORP_NO = t20.CORP_NO 
              		AND TO_NUMBER(t10.STD_YM) -200 = TO_NUMBER(t20.STD_YM)
          	) t00 
        WHERE 
          	t00.STD_YM in (	 -- 최근 3개년
	        	CONCAT('${inputYYYY}', '12'),
	            CONCAT('${inputYYYY}' - 1, '12'),
	            CONCAT('${inputYYYY}' - 2, '12'))
      	) t000
  	) t0000;
-- 결과 조회
SELECT * FROM newINDU_InterestCoverageRatio_TB ORDER BY STD_YM, newINDU;


-- (Step3) 총계 계산하여 insert
INSERT INTO newINDU_InterestCoverageRatio_TB 
SELECT DISTINCT 
	t.STD_YM,
	t.newINDU,
	t.newINDU_NM,
  	'전체' as BIZ_SIZE, 
  	SUM(t.CNT_N1_UNDERINTCOV) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N1_UNDERINTCOV, 
  	SUM(t.CNT_N2_UNDERINTCOV) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N2_UNDERINTCOV,
  	SUM(t.CNT_N3_UNDERINTCOV) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N3_UNDERINTCOV,
  	SUM(t.CNTTOTCORP) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNTTOTCORP
FROM 
  	newINDU_InterestCoverageRatio_TB t;
-- 결과 조회
SELECT * FROM newINDU_InterestCoverageRatio_TB ORDER BY STD_YM, newINDU;