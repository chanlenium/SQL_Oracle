/****************************************************************
 * 성장성 지표 추이 - 총자산증가율 추이 (p.6, [그림4])
 * 활용 테이블 : newGIUP_RAW, TCB_NICE_FNST(재무제표) -> ASSETS_TB 테이블 만듦
 ****************************************************************/
-- (Standby) 월별, 산업별, 기업규모별 총자산 테이블 ASSETS_TB 생성 
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS ASSETS_TB;
-- (Step1) 테이블 생성(기준년월, 법인번호, 기업규모, 외감여부, 상장구분코드, KSIC, 신산업코드, 신산업명, 결산구분, 총자산, EFAS)
SELECT 
	t0.STD_YM,
	t0.CORP_NO,
	t0.COMP_SCL_DIVN_CD,
	t0.OSIDE_ISPT_YN,
	t0.BLIST_MRKT_DIVN_CD,
	t0.KSIC,
	t0.newINDU,
	t0.newINDU_NM,
	t0.SEAC_DIVN,
  	t0.ASSETS, 
  	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
  	INTO ASSETS_TB 
FROM(
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
			      	t2.newINDU,
					t2.newINDU_NM,
			      	t1.ASSETS
			    FROM 
			    	(
			    	SELECT 
			    		t000.COMP_CD, 
			          	t000.SEAC_DIVN,
			          	t000.STD_DT, 
			          	t000.ASSETS 
			    	FROM
				  		(	
				        SELECT 
				      		t00.STD_YM, 
					      	t00.COMP_CD, 
					      	t00.SEAC_DIVN,
					     	t00.STD_DT,
					     	t00.ASSETS,  
					     	-- 동일 기준일자(STD_DT)에 등록된 재무 데이터가 있으면 기준년월(STD_YM)이 최근인 데이터 사용 
				          	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
				        FROM 
				          	(
				            SELECT 
				              	t0.STD_YM, 
				              	t0.COMP_CD, 
				              	t0.SEAC_DIVN,
				              	t0.STD_DT,
				              	t0.ASSETS
				            FROM 
				              	(
				                SELECT
				                	t.STD_YM, 
				                    t.COMP_CD, 
				                    t.SEAC_DIVN,	-- 결산구분 (K: 결산, B: 반기, F: 1/4분기, T: 3/4분기)
				                    t.STD_DT, 	-- 재무데이터 기준일
				                    t.AMT as ASSETS	-- 총자산
				                FROM 
				                  	TCB_NICE_FNST t 
				                WHERE 
				                   	t.REPORT_CD = '11' 
				                   	AND t.ITEM_CD = '5000'	-- 총자산(11/5000) 
				                ) t0 
				            WHERE 
				            	CAST(t0.STD_DT AS INTEGER)  IN (	-- 최근 5개년 자료 선택
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
				            ORDER BY 
				              	t0.COMP_CD, t0.STD_DT
				          	) t00
				      	) t000 
				    WHERE 
						t000.LAST_STD_YM = '1'	-- 최근 데이터만 추출
					) t1
			      	LEFT JOIN newGIUP_RAW t2 
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
WHERE t0.KSIC is not NULL and NVL(EFAS, '') <> '55';	-- 금융보험업 제외		  	
-- 결과 조회
SELECT * FROM ASSETS_TB ORDER BY CORP_NO, STD_YM;



--(Step2) 실질총자산을 구함 : 상장기업의 경우에도 매출액 성장률과는 달리 집중된 총자산을 그대로 실질총자산으로 사용
DROP TABLE IF EXISTS EFFECTIVE_ASSETS_TB;
-- 테이블 생성(기업규모, 기준년월, 당해 총자산, 직전 총자산, 실질총자산)
SELECT DISTINCT
	t00.STD_YM,
	t00.prevSTD_YM,
	t00.CORP_NO,
	t00.COMP_SCL_DIVN_CD,
	t00.OSIDE_ISPT_YN,
	t00.BLIST_MRKT_DIVN_CD,
	t00.KSIC,
	t00.SEAC_DIVN,
	t00.EFAS,
	t00.newINDU,
	t00.newINDU_NM,
	t00.effASSETS
	INTO EFFECTIVE_ASSETS_TB
FROM 
	(
	SELECT
		t0.*,
		t0.ASSETS as "effASSETS"
	FROM 
		(
		SELECT 
			t1.*,
			t2.ASSETS as "prevASSETS"
		FROM 
			(
			SELECT 
				DECODE('${isSangJang}', 'Y', t0.STD_YM, SUBSTR(t0.STD_YM, 1, 4)) as "STD_YM",
				CASE 
					WHEN '${isSangJang}' = 'Y'
					THEN
						DECODE(SUBSTR(t0.STD_YM, 5), '03', CONCAT(CAST(SUBSTR(t0.STD_YM, 1, 4) - 1 as VARCHAR), '12'), CAST(t0.STD_YM - 3 as VARCHAR))
					ELSE 
						SUBSTR(CAST(t0.STD_YM - 100 as VARCHAR), 1, 4)
				END as prevSTD_YM,				
				t0.CORP_NO,
				t0.COMP_SCL_DIVN_CD,
				t0.OSIDE_ISPT_YN,
				t0.BLIST_MRKT_DIVN_CD,
				t0.KSIC,
				t0.newINDU,
				t0.newINDU_NM,
				t0.SEAC_DIVN,
				t0.ASSETS,
				t0.EFAS
			FROM 
				ASSETS_TB t0
			WHERE t0.COMP_SCL_DIVN_CD in ('1', '2', '3')
				AND
				CASE 
					WHEN '${isSangJang}' = 'Y' 
					THEN t0.BLIST_MRKT_DIVN_CD in ('1', '2')	-- 코스피(1), 코스닥(2)만 선택
					ELSE t0.SEAC_DIVN = 'K'	-- 상장기업이 아닐때는 K결산만 필터링
				END
			ORDER BY t0.CORP_NO, t0.STD_YM
			) t1, 
			ASSETS_TB t2
			WHERE 
				t1.CORP_NO = t2.CORP_NO AND
				t1.COMP_SCL_DIVN_CD = t2.COMP_SCL_DIVN_CD AND
				t1.OSIDE_ISPT_YN = t2.OSIDE_ISPT_YN AND
				t1.BLIST_MRKT_DIVN_CD = t2.BLIST_MRKT_DIVN_CD AND 
				t1.KSIC = t2.KSIC AND
				t1.EFAS = t2.EFAS AND	
				t1.newINDU = t1.newINDU AND
				CASE 
					WHEN '${isSangJang}' = 'Y' 
					THEN t1.prevSTD_YM = t2.STD_YM	-- 6자리
					ELSE t1.prevSTD_YM = SUBSTR(t2.STD_YM, 1, 4)	-- 4자리
				END
			ORDER BY t1.CORP_NO, t1.STD_YM
		) t0	
		ORDER BY t0.CORP_NO, t0.STD_YM
	) t00
ORDER BY t00.CORP_NO, t00.STD_YM;
-- 결과 조회
SELECT t.* FROM EFFECTIVE_ASSETS_TB t ORDER BY t.CORP_NO, t.STD_YM;



-- (Step3) 실질 총자산(effASSETS)을 활용하여 총자산 증감률 도출
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS ASSETS_INC_RATIO_TB;
-- 테이블 생성(기준년월, 직전년월, 법인번호, 기업규모, 외감여부, 상장구분코드, KSIC, 결산구분, EFAS, 실질총자산, 실질직전총자산, 총자산증감률)
SELECT 
	t0.*,
	t0.effASSETS / NULLIF(t0.prevASSETS, 0) - 1 as "targetRatio"
	INTO ASSETS_INC_RATIO_TB
FROM 	
	(
	SELECT 
		t1.*,
		t2.effASSETS as "prevASSETS"
	FROM 
		EFFECTIVE_ASSETS_TB t1, EFFECTIVE_ASSETS_TB t2
	WHERE 
		t1.prevSTD_YM = t2.STD_YM
		AND t1.CORP_NO = t2.CORP_NO
	) t0
ORDER BY t0.CORP_NO, t0.STD_YM;
-- 결과 조회
SELECT * FROM ASSETS_INC_RATIO_TB ORDER BY CORP_NO, STD_YM;



-- (Step4) Calculate IQR cutoff
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
		t.STD_YM,
		t.COMP_SCL_DIVN_CD,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as "LQ",
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as "UQ"	
	FROM 	
		ASSETS_INC_RATIO_TB t
	) t0;
-- 결과 조회
SELECT * FROM IQRcutOff_TB ORDER BY STD_YM, COMP_SCL_DIVN_CD;



-- (Step5) cutoff 테이블 생성
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS Cutoff_ASSETS_INC_RATIO_TB;
-- 테이블 생성
SELECT 
	t1.*
	INTO Cutoff_ASSETS_INC_RATIO_TB
FROM
	ASSETS_INC_RATIO_TB t1, IQRcutOff_TB t2
WHERE 
	t1.STD_YM = t2.STD_YM
	AND	t1.COMP_SCL_DIVN_CD = t2.COMP_SCL_DIVN_CD
	AND t1.targetRatio > t2.LowerCutoff
	AND t1.targetRatio < t2.UpperCutoff;
-- 결과 조회
SELECT * FROM Cutoff_ASSETS_INC_RATIO_TB;



-- (Step6) 총자산 증감률 연별 그래프 (대/중/소) (1: 대기업, 2: 중소기업, 3: 중견기업, 0: 대상아님)
DROP TABLE IF EXISTS Result_newINDU_AssetsGrowthRate_BIZSIZE;
SELECT DISTINCT
	t00.STD_YM,
	SUM(ASSETS_INC_RATIO_BIZ_1) OVER(PARTITION BY t00.STD_YM) as ASSETS_INC_RATIO_BIZ_1,
	SUM(ASSETS_INC_RATIO_BIZ_2) OVER(PARTITION BY t00.STD_YM) as ASSETS_INC_RATIO_BIZ_2,
	SUM(ASSETS_INC_RATIO_BIZ_3) OVER(PARTITION BY t00.STD_YM) as ASSETS_INC_RATIO_BIZ_3
	INTO Result_newINDU_AssetsGrowthRate_BIZSIZE
FROM
	(	
	SELECT 
		t0.*,
		DECODE(t0.BIZ_SIZE, '대기업', t0.ASSETS_INC_RATIO, 0) as "ASSETS_INC_RATIO_BIZ_1",
		DECODE(t0.BIZ_SIZE, '중소기업', t0.ASSETS_INC_RATIO, 0) as "ASSETS_INC_RATIO_BIZ_2",
		DECODE(t0.BIZ_SIZE, '중견기업', t0.ASSETS_INC_RATIO, 0) as "ASSETS_INC_RATIO_BIZ_3"
	FROM
		(
		SELECT DISTINCT 
			CASE
		  		WHEN '${isSangJang}' = 'Y' THEN t.STD_YM ELSE SUBSTR(t.STD_YM, 1, 4)
		  	END as "STD_YM",
		  	CASE 
		  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN '대기업'
		  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN '중소기업'
		  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN '중견기업'
		  		ELSE t.COMP_SCL_DIVN_CD
		  	END as BIZ_SIZE,
		  	CASE	-- 총자산 증감률
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN
		  			AVG(t.targetRatio) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD)
		  		ELSE
		  			AVG(t.targetRatio) OVER(PARTITION BY SUBSTR(t.STD_YM, 1, 4), t.COMP_SCL_DIVN_CD)
		  	END as ASSETS_INC_RATIO
		FROM 
		  	Cutoff_ASSETS_INC_RATIO_TB t 
		WHERE
			t.COMP_SCL_DIVN_CD in ('1', '2', '3')
			AND
			CASE 
				WHEN '${isSangJang}' = 'Y' 
				THEN t.BLIST_MRKT_DIVN_CD in ('1', '2')	-- 코스피(1), 코스닥(2)만 선택
				ELSE t.SEAC_DIVN = 'K'	-- 상장기업이 아닐때는 K결산만 필터링
			END
		ORDER BY 
			CASE	
		  		WHEN '${isSangJang}' = 'Y' THEN t.STD_YM ELSE SUBSTR(t.STD_YM, 1, 4)
		  	END
		) t0
	) t00
ORDER BY t00.STD_YM;
-- 결과 조회
SELECT * FROM Result_newINDU_AssetsGrowthRate_BIZSIZE ORDER BY STD_YM;



-- 임시테이블 삭제
DROP TABLE IF EXISTS ASSETS_TB;
DROP TABLE IF EXISTS EFFECTIVE_ASSETS_TB;
DROP TABLE IF EXISTS ASSETS_INC_RATIO_TB;
DROP TABLE IF EXISTS IQRcutOff_TB;
DROP TABLE IF EXISTS Cutoff_ASSETS_INC_RATIO_TB;