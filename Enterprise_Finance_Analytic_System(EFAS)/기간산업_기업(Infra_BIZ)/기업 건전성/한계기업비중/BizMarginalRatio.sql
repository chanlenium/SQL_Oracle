/*****************************************************
 * 건전성 지표 추이 - 한계기업 추이 (p.6, [그림5])
 * (정의1) 최직근년도 영업적자, (정의2) 2년 연속 영업적자, (정의3) 3년 연속 영업적자
 * 활용 테이블 : TCB_NICE_FNST, GIUP_RAW -> MARGINALCORP_TB 생성
 *****************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS MARGINALCORP_TB;
-- (Step1) MARGICALCORP_TB 테이블 생성(기준년월, 법인번호, 기업규모, KSIC, 영업이익(손실), 업종코드)로 구성
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO MARGINALCORP_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC, 
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
                      	t.REPORT_CD = '12' 
                      		and t.ITEM_CD = '5000'
                  	) t0 
                WHERE 
                	CAST(t0.STD_DT AS INTEGER)  IN (	 -- 최근 4개년
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
    ORDER BY 
      	t2.CORP_NO, 
      	SUBSTR(t1.STD_DT, 1, 6)
  	) t10, 
  	KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- 결과 조회
SELECT * FROM MARGINALCORP_TB;


-- (Step2) 연속 적자 년수를 구하고 한계 기업 정의에 따른 한계기업 비중 도출
SELECT 
  	t00000.*, 
  	ROUND(t00000.CNT_N1_LOSS / t00000.CNTTOTCORP, 4) as N1_LOSS_RATIO,	-- 정의 1에 따른 한계 기업 비중
  	ROUND(t00000.CNT_N2_LOSS / t00000.CNTTOTCORP, 4) as N2_LOSS_RATIO,	-- 정의 2에 따른 한계 기업 비중
  	ROUND(t00000.CNT_N3_LOSS / t00000.CNTTOTCORP, 4) as N3_LOSS_RATIO -- 정의 3에 따른 한계 기업 비중
FROM 
  	(
    SELECT DISTINCT 
    	t0000.STD_YM, 
    	CASE 
  			WHEN t0000.COMP_SCL_DIVN_CD = 1 THEN t0000.COMP_SCL_DIVN_CD || ' 대기업'
  			WHEN t0000.COMP_SCL_DIVN_CD = 2 THEN t0000.COMP_SCL_DIVN_CD || ' 중소기업'
  			WHEN t0000.COMP_SCL_DIVN_CD = 3 THEN t0000.COMP_SCL_DIVN_CD || ' 중견기업'
  			ELSE t0000.COMP_SCL_DIVN_CD
  		END as BIZ_SIZE, 
      	-- 기준년월, 기업규모에 따른 전체 기업 수
      	COUNT(t0000.CORP_NO) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD) as CNTTOTCORP,	-- (정의1 최직근년도 영업적자)에 따른 한계 기업 수 
      	SUM(CASE WHEN t0000.CONTLOSSYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD) as CNT_N1_LOSS,	-- (정의2 2년 연속 영업적자)에 따른 한계 기업 수
      	SUM(CASE WHEN t0000.CONTLOSSYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD) as CNT_N2_LOSS,	-- (정의3 3년 연속 영업적자)에 따른 한계 기업 수
      	SUM(CASE WHEN t0000.CONTLOSSYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD) as CNT_N3_LOSS 
    FROM 
      	(
        SELECT 
          	t000.*, 
          	CASE WHEN t000.OPPROFIT < 0 THEN 
          		CASE WHEN t000.N_1_OPPROFIT < 0 THEN 
          			CASE WHEN t000.N_2_OPPROFIT < 0 THEN 3 -- 3년연속 적자 
          				ELSE 2 -- 2년연속 적자
          			END ELSE 1 -- 최직근년도 적자
          		END ELSE 0 
          	END as CONTLOSSYY -- 연속 적자 년수
        FROM 
          	(
            SELECT DISTINCT 
            	t00.STD_YM, 
              	t00.CORP_NO, 
              	t00.COMP_SCL_DIVN_CD, 
              	t00.EFAS, 
              	t00.OPPROFIT, 
              	t00.N_1_OPPROFIT, 
              	t00.N_2_OPPROFIT 
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
                      	MARGINALCORP_TB t1 
                      	LEFT JOIN MARGINALCORP_TB t2 
                      		ON t1.CORP_NO = t2.CORP_NO 
                      		AND TO_NUMBER(t1.STD_YM) -100 = TO_NUMBER(t2.STD_YM)
                  	) t10 
                  	LEFT JOIN MARGINALCORP_TB t20 
                  		ON t10.CORP_NO = t20.CORP_NO 
                  		AND TO_NUMBER(t10.STD_YM) -200 = TO_NUMBER(t20.STD_YM)
              	) t00 -- 최근 3개년 조회
            WHERE 
            	CAST(t00.STD_YM AS INTEGER) IN (	-- 최근 3개년
	    			CAST(CONCAT( '${inputYYYY}', '12') as integer),
	    			CAST(CONCAT( '${inputYYYY}', '12') as integer) - 100,
	    			CAST(CONCAT( '${inputYYYY}', '12') as integer) - 200) 
          	) t000
      	) t0000
  	) t00000; 
  
  
  
  
  
/****************************************************************
 * 한계기업비중(정의 1~3에 의함) : 업종별 현황 (p.6, [표])
 * 활용 테이블 : INTCOVRATIO_TB -> EFAS_INTCOVRATIO_TB 생성
 ****************************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS EFAS_MARGINALCORP_TB;
-- (Step1) 테이블 생성(EFAS, 당해년도 전체기업수, 당해년도 기준 1개년 연숙 적자기업수, 당해년도 기준 2개년 연속 적자기업수, 당해년도 기준 3개년 연속 적자기업수, 전년도 전체기업수, 전년도 기준 1개년 연숙 적자기업수, 전년도 기준 2개년 연속 적자기업수, 전년도 기준 3개년 연속 적자기업수)
SELECT DISTINCT 
	t00000.EFAS, 
  	SUM(DECODE(t00000.STD_YM, CONCAT( '${inputYYYY}', '12'), t00000.CNTTOTCORP, 0)) OVER(PARTITION BY t00000.EFAS) as thisYY_CNTTOTCORP, 
  	SUM(DECODE(t00000.STD_YM, CONCAT( '${inputYYYY}', '12'), t00000.CNT_N1_LOSS, 0)) OVER(PARTITION BY t00000.EFAS) as thisYY_CNT_N1_LOSS, 
  	SUM(DECODE(t00000.STD_YM, CONCAT( '${inputYYYY}', '12'), t00000.CNT_N2_LOSS, 0)) OVER(PARTITION BY t00000.EFAS) as thisYY_CNT_N2_LOSS, 
  	SUM(DECODE(t00000.STD_YM, CONCAT( '${inputYYYY}', '12'), t00000.CNT_N3_LOSS, 0)) OVER(PARTITION BY t00000.EFAS) as thisYY_CNT_N3_LOSS, 
  	SUM(DECODE(t00000.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00000.CNTTOTCORP, 0)) OVER(PARTITION BY t00000.EFAS) as prevYY_CNTTOTCORP, 
  	SUM(DECODE(t00000.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00000.CNT_N1_LOSS, 0)) OVER(PARTITION BY t00000.EFAS) as prevYY_CNT_N1_LOSS, 
  	SUM(DECODE(t00000.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00000.CNT_N2_LOSS, 0)) OVER(PARTITION BY t00000.EFAS) as prevYY_CNT_N2_LOSS, 
  	SUM(DECODE(t00000.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00000.CNT_N3_LOSS, 0)) OVER(PARTITION BY t00000.EFAS) as prevYY_CNT_N3_LOSS 
  	INTO EFAS_MARGINALCORP_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t0000.STD_YM, 
      	t0000.EFAS, 
      	COUNT(t0000.CORP_NO) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS) as CNTTOTCORP, 
      	SUM(CASE WHEN t0000.CONTLOSSYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS) as CNT_N1_LOSS, 
      	SUM(CASE WHEN t0000.CONTLOSSYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS) as CNT_N2_LOSS, 
      	SUM(CASE WHEN t0000.CONTLOSSYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS) as CNT_N3_LOSS 
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
                      	MARGINALCORP_TB t1 
                      	LEFT JOIN MARGINALCORP_TB t2 
                      		ON t1.CORP_NO = t2.CORP_NO 
                      		AND TO_NUMBER(t1.STD_YM) -100 = TO_NUMBER(t2.STD_YM)
                  	) t10 
                  	LEFT JOIN MARGINALCORP_TB t20 
                  		ON t10.CORP_NO = t20.CORP_NO 
                  		AND TO_NUMBER(t10.STD_YM) -200 = TO_NUMBER(t20.STD_YM)
              	) t00 
            WHERE 
            	CAST(t00.STD_YM AS INTEGER) IN (	-- 당월, 전년 동월, 전전년 동월
	    			CAST(CONCAT( '${inputYYYY}', '12') as integer),
	    			CAST(CONCAT( '${inputYYYY}', '12') as integer) - 100,
	    			CAST(CONCAT( '${inputYYYY}', '12') as integer) - 200) 
          	) t000
      	) t0000
  	) t00000;
-- 결과 조회
SELECT * FROM EFAS_MARGINALCORP_TB ORDER BY TO_NUMBER(EFAS, '999999');


-- (Step2) 총계 계산하여 insert
INSERT INTO EFAS_MARGINALCORP_TB 
SELECT 
  	'99',	-- 총합은 EFIS code '00'할당 
 	SUM(t.thisYY_CNTTOTCORP), 
  	SUM(t.thisYY_CNT_N1_LOSS), 
  	SUM(t.thisYY_CNT_N2_LOSS), 
  	SUM(t.thisYY_CNT_N3_LOSS), 
  	SUM(t.prevYY_CNTTOTCORP), 
  	SUM(t.prevYY_CNT_N1_LOSS), 
  	SUM(t.prevYY_CNT_N2_LOSS), 
  	SUM(t.prevYY_CNT_N3_LOSS) 
FROM 
  	EFAS_MARGINALCORP_TB t;
-- 결과 조회
SELECT * FROM EFAS_MARGINALCORP_TB t ORDER BY TO_NUMBER(t.EFAS, '999999');


-- (Step3) 당해년/전년 동월 부채비율 및 전년 동월 대비 증가율 계산
SELECT 
  	t.EFAS, 
  	-- 최직근년도 영업적자 기준 한계기업
  	ROUND(t.thisYY_CNT_N1_LOSS / t.thisYY_CNTTOTCORP, 4) as N1_thisYY_MARGINALRATIO, -- 당해년도 
  	ROUND(t.prevYY_CNT_N1_LOSS / t.prevYY_CNTTOTCORP, 4) as N1_prevYY_MARGINALRATIO, -- 전년동기
  	ROUND(t.thisYY_CNT_N1_LOSS / t.thisYY_CNTTOTCORP - t.prevYY_CNT_N1_LOSS / t.prevYY_CNTTOTCORP, 4) as N1_MARGINALRATIO_INC,	-- 증가율 
  	
  	-- 2년연속 영업적자 기준 한계기업
  	ROUND(t.thisYY_CNT_N2_LOSS / t.thisYY_CNTTOTCORP, 4) as N2_thisYY_MARGINALRATIO,	-- 당해년도 
  	ROUND(t.prevYY_CNT_N2_LOSS / t.prevYY_CNTTOTCORP, 4) as N2_prevYY_MARGINALRATIO, 	-- 전년동기
  	ROUND(t.thisYY_CNT_N2_LOSS / t.thisYY_CNTTOTCORP - t.prevYY_CNT_N2_LOSS / t.prevYY_CNTTOTCORP, 4) as N2_MARGINALRATIO_INC, 
  
  	-- 3년연속 영업적자 기준 한계기업
  	ROUND(t.thisYY_CNT_N3_LOSS / t.thisYY_CNTTOTCORP, 4) as N3_thisYY_MARGINALRATIO, -- 당해년도 
  	ROUND(t.prevYY_CNT_N3_LOSS / t.prevYY_CNTTOTCORP, 4) as N3_prevYY_MARGINALRATIO, -- 전년동기
  	ROUND(t.thisYY_CNT_N3_LOSS / t.thisYY_CNTTOTCORP - t.prevYY_CNT_N3_LOSS / t.prevYY_CNTTOTCORP, 4) as N3_MARGINALRATIO_INC 
FROM 
  	EFAS_MARGINALCORP_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');
  
  
  
  
  
  
  
  
  
  
/*****************************************************
 * 건전성 지표 추이 - 한계기업 추이 (p.6, [그림5])
 * (정의4) 최직근년도 이자보상배율 1미만, (정의5) 2년연속 이자보상배율 1미만, (정의6) 3년연속 이자보상배율 1미만
 * 활용 테이블 : TCB_NICE_FNST, GIUP_RAW -> MARGINALCORP_TB 생성
 *****************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS MARGINALCORP_TB;
-- (Standby) MARGICALCORP_TB 테이블 생성(기준년월, 법인번호, 기업규모, KSIC, 영업이익(손실), 이자비용, 이자보상배율, 이업종코드)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO MARGINALCORP_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
     	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC, 
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
                      	AND CAST(t.STD_DT AS INTEGER)  IN (	 -- 최근 4개년
			                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER),
			                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 10000,
			                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 20000,
			                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 30000) 
                  	) t0
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN GIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
  	) t10, 
  	KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- 결과 조회
SELECT * FROM MARGINALCORP_TB; 


-- 연속 이자보상배율 1미만 년수를 구하고 한계 기업 정의에 따른 한계기업 비중 도출
SELECT 
  	t00000.STD_YM, 
  	CASE 
  		WHEN t00000.COMP_SCL_DIVN_CD = 1 THEN t00000.COMP_SCL_DIVN_CD || ' 대기업'
  		WHEN t00000.COMP_SCL_DIVN_CD = 2 THEN t00000.COMP_SCL_DIVN_CD || ' 중소기업'
  		WHEN t00000.COMP_SCL_DIVN_CD = 3 THEN t00000.COMP_SCL_DIVN_CD || ' 중견기업'
  		ELSE t00000.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE,  
  	ROUND(t00000.CNT_N1_UNDERINTCOV / t00000.CNTTOTCORP, 4) as N1_UNDERINTCOVRATIO, 
  	ROUND(t00000.CNT_N2_UNDERINTCOV / t00000.CNTTOTCORP, 4) as N2_UNDERINTCOVRATIO, 
  	ROUND(t00000.CNT_N3_UNDERINTCOV / t00000.CNTTOTCORP, 4) as N3_UNDERINTCOVRATIO 
FROM 
  	(
    SELECT DISTINCT 
    	t0000.STD_YM, 
      	t0000.COMP_SCL_DIVN_CD, 
      	COUNT(t0000.CORP_NO) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD) as CNTTOTCORP, 
      	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD) as CNT_N1_UNDERINTCOV, 
      	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD) as CNT_N2_UNDERINTCOV, 
      	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD) as CNT_N3_UNDERINTCOV 
    FROM 
      	(
        SELECT 
          	t000.*, 
          	CASE WHEN t000.INTCOVRATIO < 1 THEN 
          		CASE WHEN t000.N_1_INTCOVRATIO < 1 THEN 
          			CASE WHEN t000.N_2_INTCOVRATIO < 1 THEN 3 -- 3년연속 이자보생배율 1미만
          			ELSE 2 -- 2년연속 이자보생배율 1미만
          		END ELSE 1 -- 최직근년도 이자보생배율 1미만
          END ELSE 0 END as CONTUNDERINTCOVYY -- 연속 이자보생배율 1미만 년수
        FROM 
          	(
            SELECT DISTINCT 
            	t00.STD_YM, 
              	t00.CORP_NO, 
              	t00.COMP_SCL_DIVN_CD, 
              	t00.EFAS, 
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
                      	MARGINALCORP_TB t1 
                      	LEFT JOIN MARGINALCORP_TB t2 
                      		ON t1.CORP_NO = t2.CORP_NO 
                      		AND TO_NUMBER(t1.STD_YM) -100 = TO_NUMBER(t2.STD_YM)
                  	) t10 
                  	LEFT JOIN MARGINALCORP_TB t20 
                  		ON t10.CORP_NO = t20.CORP_NO 
                  		AND TO_NUMBER(t10.STD_YM) -200 = TO_NUMBER(t20.STD_YM)
              	) t00 
            	WHERE 
            		CAST(t00.STD_YM AS INTEGER) IN (	-- 당월 및 전년 동월
		    			CAST(CONCAT( '${inputYYYY}', '12') as integer),
		    			CAST(CONCAT( '${inputYYYY}', '12') as integer) - 100)
          	) t000
      	) t0000
  	) t00000;
  
  
  
  
  
/****************************************************************
 * 한계기업비중(정의 4~6에 의함, 이자보상배율) : 업종별 현황 (p.6, [표])
 * 활용 테이블 : INTCOVRATIO_TB -> EFAS_INTCOVRATIO_TB 생성
 ****************************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS EFAS_MARGINALCORP_TB;
-- (Step1) EFAS_MARGINALCORP_TB 테이블 생성
-- EFAS, 당해년도 기준 전체 기업수, 당해년도 기준 1개년연속 이자보상배율<1 기업 수, 당해년도 기준 2개년연속 이자보상배율<1 기업 수, 당해년도 기준 3개년연속 이자보상배율<1 기업 수
-- 전년도 기준 전체 기업수, 전년도 기준 1개년연속 이자보상배율<1 기업 수, 전년도 기준 2개년연속 이자보상배율<1 기업 수, 전년도 기준 3개년연속 이자보상배율<1 기업 수
SELECT DISTINCT 
	t00000.EFAS, 
  	SUM(DECODE(t00000.STD_YM, CONCAT( '${inputYYYY}', '12'), t00000.CNTTOTCORP, 0)) OVER(PARTITION BY t00000.EFAS) as thisYY_CNTTOTCORP, 
  	SUM(DECODE(t00000.STD_YM, CONCAT( '${inputYYYY}', '12'), t00000.CNT_N1_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS) as thisYY_CNT_N1_UNDERINTCOV, 
  	SUM(DECODE(t00000.STD_YM, CONCAT( '${inputYYYY}', '12'), t00000.CNT_N2_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS) as thisYY_CNT_N2_UNDERINTCOV, 
  	SUM(DECODE(t00000.STD_YM, CONCAT( '${inputYYYY}', '12'), t00000.CNT_N3_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS) as thisYY_CNT_N3_UNDERINTCOV, 
  	SUM(DECODE(t00000.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00000.CNTTOTCORP, 0)) OVER(PARTITION BY t00000.EFAS) as prevYY_CNTTOTCORP, 
  	SUM(DECODE(t00000.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00000.CNT_N1_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS) as prevYY_CNT_N1_UNDERINTCOV, 
 	SUM(DECODE(t00000.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00000.CNT_N2_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS) as prevYY_CNT_N2_UNDERINTCOV, 
  	SUM(DECODE(t00000.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00000.CNT_N3_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS) as prevYY_CNT_N3_UNDERINTCOV  	
  	INTO EFAS_MARGINALCORP_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t0000.STD_YM, 
      	t0000.EFAS, 
      	COUNT(t0000.CORP_NO) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS) as CNTTOTCORP, 
      	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS) as CNT_N1_UNDERINTCOV, 
      	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS) as CNT_N2_UNDERINTCOV, 
      	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS) as CNT_N3_UNDERINTCOV 
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
                      	MARGINALCORP_TB t1 
                      	LEFT JOIN MARGINALCORP_TB t2 
                      		ON t1.CORP_NO = t2.CORP_NO 
                      		AND TO_NUMBER(t1.STD_YM) -100 = TO_NUMBER(t2.STD_YM)
                  	) t10 
                  	LEFT JOIN MARGINALCORP_TB t20 
                  		ON t10.CORP_NO = t20.CORP_NO 
                  		AND TO_NUMBER(t10.STD_YM) -200 = TO_NUMBER(t20.STD_YM)
              	) t00 
            WHERE 
            	CAST(t00.STD_YM AS INTEGER) IN (	-- 당월, 전년 동월, 전전년 동월
	    			CAST(CONCAT( '${inputYYYY}', '12') as integer),
	    			CAST(CONCAT( '${inputYYYY}', '12') as integer) - 100,
	    			CAST(CONCAT( '${inputYYYY}', '12') as integer) - 200)
          	) t000
      	) t0000
  	) t00000;
-- 결과 조회
SELECT * FROM EFAS_MARGINALCORP_TB ORDER BY TO_NUMBER(EFAS, '999999');


-- (Step2) 총계 계산하여 insert
INSERT INTO EFAS_MARGINALCORP_TB 
SELECT 
  	'99',	-- 총합은 EFIS code '00'할당 
  	SUM(t.thisYY_CNTTOTCORP), 
  	SUM(t.thisYY_CNT_N1_UNDERINTCOV), 
  	SUM(t.thisYY_CNT_N2_UNDERINTCOV), 
  	SUM(t.thisYY_CNT_N3_UNDERINTCOV), 
  	SUM(t.prevYY_CNTTOTCORP), 
  	SUM(t.prevYY_CNT_N1_UNDERINTCOV), 
  	SUM(t.prevYY_CNT_N2_UNDERINTCOV), 
  	SUM(t.prevYY_CNT_N3_UNDERINTCOV) 
FROM 
  	EFAS_MARGINALCORP_TB t;
-- 결과 조회
SELECT * FROM EFAS_MARGINALCORP_TB t ORDER BY TO_NUMBER(t.EFAS, '999999');


-- (Step3) 당해년/전년 동월 부채비율 및 전년 동월 대비 증가율 계산
SELECT 
  	t.EFAS, 
  	-- 최직근년도 영업적자 기준 한계기업
  	ROUND(t.thisYY_CNT_N1_UNDERINTCOV / t.thisYY_CNTTOTCORP, 4) as N1_thisYY_MARGINALRATIO,	-- 당해년도 
  	ROUND(t.prevYY_CNT_N1_UNDERINTCOV / t.prevYY_CNTTOTCORP, 4) as N1_prevYY_MARGINALRATIO, -- 전년동기
  	ROUND(t.thisYY_CNT_N1_UNDERINTCOV / t.thisYY_CNTTOTCORP - t.prevYY_CNT_N1_UNDERINTCOV / t.prevYY_CNTTOTCORP, 4) as N1_MARGINALRATIO_INC, 
  
  	-- 2년연속 영업적자 기준 한계기업
  	ROUND(t.thisYY_CNT_N2_UNDERINTCOV / t.thisYY_CNTTOTCORP, 4) as N2_thisYY_MARGINALRATIO,	-- 당해년도 
  	ROUND(t.prevYY_CNT_N2_UNDERINTCOV / t.prevYY_CNTTOTCORP, 4) as N2_prevYY_MARGINALRATIO, -- 전년동기
  	ROUND(t.thisYY_CNT_N2_UNDERINTCOV / t.thisYY_CNTTOTCORP - t.prevYY_CNT_N2_UNDERINTCOV / t.prevYY_CNTTOTCORP, 4) as N2_MARGINALRATIO_INC, 
  
  	-- 3년연속 영업적자 기준 한계기업
  	ROUND(t.thisYY_CNT_N3_UNDERINTCOV / t.thisYY_CNTTOTCORP, 4) as N3_thisYY_MARGINALRATIO, -- 당해년도 
  	ROUND(t.prevYY_CNT_N3_UNDERINTCOV / t.prevYY_CNTTOTCORP, 4) as N3_prevYY_MARGINALRATIO, -- 전년동기
  	ROUND(t.thisYY_CNT_N3_UNDERINTCOV / t.thisYY_CNTTOTCORP - t.prevYY_CNT_N3_UNDERINTCOV / t.prevYY_CNTTOTCORP, 4) as N3_MARGINALRATIO_INC 
FROM 
  	EFAS_MARGINALCORP_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');