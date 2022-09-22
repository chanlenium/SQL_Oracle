/*****************************************************
 * 건전성 지표 추이 - 한계기업 추이 (p.6, [그림5])
 * RFP p.16 [그림5] 한기기업비중 : 업종별 현황
 * (정의1) 최직근년도 영업적자, (정의2) 2년 연속 영업적자, (정의3) 3년 연속 영업적자
 * 활용 테이블 : TCB_NICE_FNST, GIUP_RAW -> MARGINALCORP_TB 생성
 *****************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS MARGINALCORP_TB;
-- (Step1) MARGICALCORP_TB 테이블 생성(기준년월, 법인번호, 기업규모, KSIC, 영업이익(손실), 업종코드)로 구성
SELECT 
  	t0.STD_YM,
	t0.CORP_NO,
	t0.COMP_SCL_DIVN_CD,
	t0.OSIDE_ISPT_YN,
	t0.BLIST_MRKT_DIVN_CD,
	t0.KSIC,
	t0.SEAC_DIVN,
	t0.OPPROFIT,
	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
  	INTO MARGINALCORP_TB 
FROM 
	(
	SELECT DISTINCT
		t1000.*,
		t2000.EFAS_CD as EFAS_2
	FROM(
		SELECT DISTINCT
			t100.*,
			t200.EFAS_CD as EFAS_3
		FROM(
			SELECT 
				t10.*, 
				t20.EFAS_CD as EFAS_4
			FROM 
			  	(
			    SELECT DISTINCT 
			    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
			    	t1.SEAC_DIVN,
					t2.CORP_NO, 
			      	t2.COMP_SCL_DIVN_CD, 
			      	t2.OSIDE_ISPT_YN,
			      	t2.BLIST_MRKT_DIVN_CD,
			      	t2.KSIC, 
			      	t1.OPPROFIT 
			    FROM 
			      	(
			        SELECT 
			          	t000.COMP_CD, 
			          	t000.SEAC_DIVN,
			          	t000.STD_DT, 
			          	t000.OPPROFIT 
			        FROM 
			          	(
			            SELECT 
			              	t00.STD_YM, 
			              	t00.COMP_CD, 
			              	t00.SEAC_DIVN,
			              	t00.STD_DT, 
			              	t00.OPPROFIT, 
			              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용
			              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
			            FROM 
			              	(
			                SELECT DISTINCT 
			                	t0.STD_YM, 
			                  	t0.COMP_CD, 
			                  	t0.SEAC_DIVN,
			                  	t0.STD_DT, 
			                  	SUM(t0.OPPROFIT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as OPPROFIT -- 영업이익
			                FROM 
			                  	(
			                    SELECT 
			                      	t.STD_YM,	-- 데이터가 집중된 년월
			                      	t.COMP_CD, 
			                      	t.SEAC_DIVN,	-- 결산구분 (K: 결산, B: 반기, F: 1/4분기, T: 3/4분기)
			                      	t.STD_DT,	-- 재무데이터 기준일
			                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as OPPROFIT -- 영업이익(손실)
			                    FROM 
			                      	TCB_NICE_FNST t 
			                    WHERE 
			                      	t.REPORT_CD = '12' 
			                      		AND t.ITEM_CD = '5000'	-- 영업이익(5000)
			                  	) t0 
			                WHERE 
			                	CAST(t0.STD_DT AS INTEGER)  IN (		-- 최근 4개년
					                CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER),
							        CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER),
							        CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER),
							        CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER),
							        CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 10000,
							        CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 10000,
							        CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 10000,
							        CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 10000,
							        CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 20000,
							        CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 20000,
							        CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 20000,
							        CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 20000,
							        CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 30000,
							        CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 30000,
							        CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 30000,
							        CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 30000,
							        CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 40000,
							        CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 40000,
							        CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 40000,
							        CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 40000)           	
			              	) t00
			          	) t000 
			        WHERE 
			          	t000.LAST_STD_YM = '1'
			      	) t1 
			      	LEFT JOIN GIUP_RAW t2 
			      		ON t1.COMP_CD = t2.COMP_CD 
			      		AND t2.OSIDE_ISPT_YN = 'Y'	-- 외감 대상
			  	) t10 
				LEFT JOIN EFASTOKSIC66 t20 
					ON SUBSTR(t10.KSIC, 1, 4) = t20.KSIC	-- KSIC 4자리로 매핑
			) t100
			LEFT JOIN EFASTOKSIC66 t200
				ON SUBSTR(t100.KSIC, 1, 3) = t200.KSIC	-- KSIC 3자리로 매핑
		)t1000
	  	LEFT JOIN EFASTOKSIC66 t2000
			ON SUBSTR(t1000.KSIC, 1, 2) = t2000.KSIC	-- KSIC 2자리로 매핑
	) t0
WHERE 
	t0.KSIC is not NULL
	AND 
	CASE
		WHEN '${isSangJang}' = 'Y'	-- 상장기업인 경우
		THEN t0.BLIST_MRKT_DIVN_CD in ('1', '2')
		ELSE t0.SEAC_DIVN = 'K'		-- 외감기업인 경우
	END;
-- 결과 조회
SELECT * FROM MARGINALCORP_TB ORDER BY CORP_NO, STD_YM;



-- (Step2) 연속 적자 년수를 구하고 한계 기업 정의에 따른 한계기업 비중 도출
DROP TABLE IF EXISTS RESULT_MARGINAL_RATIO_BIZSIZE;
SELECT 
	t000000.STD_YM,
	SUM(DECODE(t000000.COMP_SCL_DIVN_CD, '1', N1_LOSS_RATIO, 0)) as "BIZ1_N1_LOSS_RATIO",
	SUM(DECODE(t000000.COMP_SCL_DIVN_CD, '2', N1_LOSS_RATIO, 0)) as "BIZ2_N1_LOSS_RATIO",
	SUM(DECODE(t000000.COMP_SCL_DIVN_CD, '3', N1_LOSS_RATIO, 0)) as "BIZ3_N1_LOSS_RATIO",
	SUM(DECODE(t000000.COMP_SCL_DIVN_CD, '1', N2_LOSS_RATIO, 0)) as "BIZ1_N2_LOSS_RATIO",
	SUM(DECODE(t000000.COMP_SCL_DIVN_CD, '2', N2_LOSS_RATIO, 0)) as "BIZ2_N2_LOSS_RATIO",
	SUM(DECODE(t000000.COMP_SCL_DIVN_CD, '3', N2_LOSS_RATIO, 0)) as "BIZ3_N2_LOSS_RATIO",
	SUM(DECODE(t000000.COMP_SCL_DIVN_CD, '1', N3_LOSS_RATIO, 0)) as "BIZ1_N3_LOSS_RATIO",
	SUM(DECODE(t000000.COMP_SCL_DIVN_CD, '2', N3_LOSS_RATIO, 0)) as "BIZ2_N3_LOSS_RATIO",
	SUM(DECODE(t000000.COMP_SCL_DIVN_CD, '3', N3_LOSS_RATIO, 0)) as "BIZ3_N3_LOSS_RATIO"
	INTO RESULT_MARGINAL_RATIO_BIZSIZE
FROM 
	(
	SELECT 
	  	t00000.STD_YM, 
	  	t00000.COMP_SCL_DIVN_CD,
	  	ROUND(t00000.CNT_N1_LOSS / t00000.CNTTOTCORP, 4) as "N1_LOSS_RATIO",	-- 정의 1에 따른 한계 기업 비중
	  	ROUND(t00000.CNT_N2_LOSS / t00000.CNTTOTCORP, 4) as "N2_LOSS_RATIO",	-- 정의 2에 따른 한계 기업 비중
	  	ROUND(t00000.CNT_N3_LOSS / t00000.CNTTOTCORP, 4) as "N3_LOSS_RATIO" -- 정의 3에 따른 한계 기업 비중
	FROM 
	  	(
	    SELECT DISTINCT 
	    	CASE
				WHEN '${isSangJang}' = 'Y'	-- 상장기업인 경우
				THEN t0000.STD_YM
				ELSE SUBSTR(t0000.STD_YM, 1, 4)		-- 외감기업인 경우
			END as "STD_YM",
			t0000.COMP_SCL_DIVN_CD,
	      	-- 기준년월, 기업규모에 따른 전체 기업 수
			CASE
				WHEN '${isSangJang}' = 'Y'	-- 상장기업인 경우
				THEN COUNT(t0000.CORP_NO) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD)
				ELSE COUNT(t0000.CORP_NO) OVER(PARTITION BY SUBSTR(t0000.STD_YM, 1, 4), t0000.COMP_SCL_DIVN_CD)
			END as "CNTTOTCORP",
	      	-- (정의1 최직근년도 영업적자)에 따른 한계 기업 수 
			CASE
				WHEN '${isSangJang}' = 'Y'	-- 상장기업인 경우
				THEN SUM(CASE WHEN t0000.CONTLOSSYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD)
				ELSE SUM(CASE WHEN t0000.CONTLOSSYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY SUBSTR(t0000.STD_YM, 1, 4), t0000.COMP_SCL_DIVN_CD)
			END as "CNT_N1_LOSS",
	      	-- (정의2 2년 연속 영업적자)에 따른 한계 기업 수
			CASE
				WHEN '${isSangJang}' = 'Y'	-- 상장기업인 경우
				THEN SUM(CASE WHEN t0000.CONTLOSSYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD)
				ELSE SUM(CASE WHEN t0000.CONTLOSSYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY SUBSTR(t0000.STD_YM, 1, 4), t0000.COMP_SCL_DIVN_CD)
			END as "CNT_N2_LOSS",	
	      	-- (정의3 3년 연속 영업적자)에 따른 한계 기업 수
	      	CASE
				WHEN '${isSangJang}' = 'Y'	-- 상장기업인 경우
				THEN SUM(CASE WHEN t0000.CONTLOSSYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.COMP_SCL_DIVN_CD)
				ELSE SUM(CASE WHEN t0000.CONTLOSSYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY SUBSTR(t0000.STD_YM, 1, 4), t0000.COMP_SCL_DIVN_CD)
			END as "CNT_N3_LOSS"
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
	              	t00.BLIST_MRKT_DIVN_CD,
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
	                      	CAST(t1.STD_YM - 100 as VARCHAR),
	                      	t2.OPPROFIT as N_1_OPPROFIT -- 2년전 영업이익(손실)
	                    FROM 
	                      	MARGINALCORP_TB t1 
	                      	LEFT JOIN MARGINALCORP_TB t2 
	                      		ON t1.CORP_NO = t2.CORP_NO 
	                      		AND CAST(t1.STD_YM - 100 as VARCHAR) = t2.STD_YM
	                    ORDER BY t1.STD_YM DESC
	                  	) t10 
	                  	LEFT JOIN MARGINALCORP_TB t20 
	                  		ON t10.CORP_NO = t20.CORP_NO 
	                  		AND CAST(t10.STD_YM - 200 as VARCHAR) = t20.STD_YM
	              	) t00 -- 최근 3개년 조회
	            WHERE 
	            	SUBSTR(t00.STD_YM, 1, 4) IN (	-- 최근 3개년
				    	CAST('${inputYYYY}' as VARCHAR), 
				        CAST('${inputYYYY}' - 1 as VARCHAR), 
				        CAST('${inputYYYY}' - 2 as VARCHAR))  
	          	) t000
	      	) t0000
	  	) t00000
	 WHERE 
		t00000.COMP_SCL_DIVN_CD in ('1', '2', '3')
	) t000000
GROUP BY 
	t000000.STD_YM 
ORDER BY
	t000000.STD_YM; 
	

-- 임시테이블 삭제
DROP TABLE IF EXISTS MARGINALCORP_TB;
-- 결과 조회
SELECT * FROM RESULT_MARGINAL_RATIO_BIZSIZE order by STD_YM;