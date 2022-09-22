/****************************************************************
 * 건전성 지표 추이 - 자기자본비율(=자기자본/총자산) 추이 (p.6, [그림4])
 * 활용 테이블 : GIUP_RAW, TCB_NICE_FNST(재무제표) -> EQUITYRATIO_TB 테이블 만듦
 ****************************************************************/
-- (Step1) 월별, 산업별, 기업규모별 이자보상배율 테이블 EQUITYRATIO_TB 생성 
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS CapitalAdequacyRatio_TB;
-- 테이블 생성 (기준년월, 법인번호, 기업규모, 외감여부, 상장여부, KSIC, 결산구분, 자기자본(자본총계), 총자산, 자기자본비율, EFAS)
SELECT 
	t0.STD_YM,
	t0.CORP_NO,
	t0.COMP_SCL_DIVN_CD,
	t0.OSIDE_ISPT_YN,
	t0.BLIST_MRKT_DIVN_CD,
	t0.KSIC,
	t0.SEAC_DIVN,
	t0.CAP_STOCK,
	t0.TOT_STOCK,
	t0.targetRatio,
	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
	INTO CapitalAdequacyRatio_TB
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
			      	t1.CAP_STOCK, 
			      	t1.TOT_STOCK,
			      	t1.CAP_STOCK / t1.TOT_STOCK as "targetRatio"	-- 개별 기업의 자기자본비율
			    FROM 
			    	(
			        SELECT 
			          	t000.COMP_CD, 
			          	t000.SEAC_DIVN,
			          	t000.STD_DT, 
			          	t000.CAP_STOCK, 
			          	t000.TOT_STOCK 
			        FROM 
			          	(
			            SELECT 
			              	t00.STD_YM, 
			              	t00.COMP_CD, 
			              	t00.SEAC_DIVN,
			             	t00.STD_DT, 
			              	t00.CAP_STOCK, 
			              	t00.TOT_STOCK, 
			              	-- 동일 기준일자(STD_DT)에 등록된 재무 데이터가 있으면 기준년월(STD_YM)이 최근인 데이터 사용 
			              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
			            FROM 
			              	(
			                SELECT DISTINCT 
			                	t0.STD_YM, 
			                  	t0.COMP_CD, 
			                  	t0.SEAC_DIVN,
			                  	t0.STD_DT, 
			                  	SUM(t0.CAP_STOCK) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as CAP_STOCK, 
			                  	SUM(t0.TOT_STOCK) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as TOT_STOCK 
			                FROM 
			                  	(
			                    SELECT 
			                      	t.STD_YM, -- 데이터가 집중된 년월
			                      	t.COMP_CD, 
			                      	t.SEAC_DIVN,	-- 결산구분 (K: 결산, B: 반기, F: 1/4분기, T: 3/4분기)
			                      	t.STD_DT,	-- 재무데이터 기준일
			                      	t.ITEM_CD, 
			                      	DECODE(t.ITEM_CD, '8900', ROUND(t.AMT/1000, 0), 0) as CAP_STOCK, -- 자본총계(자기자본)
			                      	DECODE(t.ITEM_CD, '5000', ROUND(t.AMT/1000, 0), 0) as TOT_STOCK -- 자산총계(총자산)
			                    FROM 
			                      	TCB_NICE_FNST t 
			                    WHERE 
			                      	t.REPORT_CD = '11' -- 대차대조표 
			                      	and t.ITEM_CD in ('8900', '5000')	-- 자본총계(자기자본, 11/8900), 자산총계(총자산, 11/5000)
			                  	) t0 
			                WHERE 
			                	CAST(t0.STD_DT AS INTEGER)  IN (	-- 최근 4개년 자료 선택
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
			                		CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 30000)
			                ORDER BY 
			                  	t0.COMP_CD, t0.STD_DT
			              	) t00
			          	) t000 
			        WHERE 
			          	t000.LAST_STD_YM = '1'	-- 최근 데이터만 추출
			          	AND t000.TOT_STOCK <> '0' -- Divided by zero 회피
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
WHERE t0.KSIC is not NULL and NVL(EFAS, '') <> '55';	-- 금융보험업 제외		
-- 결과조회
SELECT * FROM CapitalAdequacyRatio_TB;



-- (Step2) Calculate IQR cutoff
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
		t.EFAS,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.STD_YM, t.EFAS) as "LQ",
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.STD_YM, t.EFAS) as "UQ"	
	FROM 	
		CapitalAdequacyRatio_TB t
	) t0;
-- 결과 조회
SELECT * FROM IQRcutOff_TB ORDER BY STD_YM, EFAS;



-- (Step3) cutoff 테이블 생성
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS Cutoff_CapitalAdequacyRatio_TB;
-- 테이블 생성
SELECT 
	t1.*
	INTO Cutoff_CapitalAdequacyRatio_TB
FROM
	CapitalAdequacyRatio_TB t1, IQRcutOff_TB t2
WHERE 
	t1.STD_YM = t2.STD_YM
	AND	t1.EFAS = t2.EFAS
	AND t1.targetRatio > t2.LowerCutoff
	AND t1.targetRatio < t2.UpperCutoff;
-- 결과 조회
SELECT * FROM Cutoff_CapitalAdequacyRatio_TB;



-- (Step4) 자기자본비율 연별 그래프 (업종별)
SELECT 	
	t000.*,
	thisYY_EFAS_CapitalAdequacyRatio - prevYY_EFAS_CapitalAdequacyRatio as "INCRATIO"	-- 전년 동월 대비 증감율
FROM 
	(
	SELECT DISTINCT
		t00.EFAS,
		t00.thisYY,
		SUM(t00.thisYY_CapitalAdequacyRatio) OVER(PARTITION BY t00.EFAS) as thisYY_EFAS_CapitalAdequacyRatio,	-- 현월 자기자본비율
		SUM(t00.prevYY_CapitalAdequacyRatio) OVER(PARTITION BY t00.EFAS) as prevYY_EFAS_CapitalAdequacyRatio	-- 전년 동월 자기자본비율
	FROM
		(	
		SELECT 
			t0.EFAS,
		  	t0.STD_YM,
		  	t0.thisYY,
		  	CASE	
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN DECODE(t0.STD_YM, t0.thisYY, t0.CapitalAdequacyRatio, 0)
		  		ELSE DECODE(CONCAT(t0.STD_YM, '12'), t0.thisYY, t0.CapitalAdequacyRatio, 0)
		  	END as "thisYY_CapitalAdequacyRatio",
		  	CASE	
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN DECODE(t0.STD_YM, t0.prevYY, t0.CapitalAdequacyRatio, 0)
		  		ELSE DECODE(CONCAT(t0.STD_YM, '12'), t0.prevYY, t0.CapitalAdequacyRatio, 0)
		  	END as "prevYY_CapitalAdequacyRatio"
		FROM
			(
			SELECT DISTINCT 
				t.EFAS,
				CASE
			  		WHEN '${isSangJang}' = 'Y' THEN t.STD_YM ELSE SUBSTR(t.STD_YM, 1, 4)
			  	END as STD_YM,
			  	CASE	
			  		WHEN '${isSangJang}' = 'Y' 
			  		THEN
			  			MAX(t.STD_YM) OVER(PARTITION BY t.EFAS)
			  		ELSE
			  			DECODE(SUBSTR(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS), 5), '12', 
			  			MAX(t.STD_YM) OVER(PARTITION BY t.EFAS),
			  			CONCAT(CAST(SUBSTR(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS), 1, 4) - 1 as VARCHAR), '12'))
			  	END as thisYY,
			  	CASE	
			  		WHEN '${isSangJang}' = 'Y' 
			  		THEN
			  			CAST(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS) - 100 as VARCHAR)
			  		ELSE
			  			DECODE(SUBSTR(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS), 5), '12', 
			  			CAST(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS) - 100 as VARCHAR),
			  			CONCAT(CAST(SUBSTR(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS), 1, 4) - 2 as VARCHAR), '12'))
			  	END as prevYY,
			  	CASE	-- 부채비율
			  		WHEN '${isSangJang}' = 'Y' 
			  		THEN
			  			AVG(t.targetRatio) OVER(PARTITION BY t.STD_YM, t.EFAS)
			  		ELSE
			  			AVG(t.targetRatio) OVER(PARTITION BY SUBSTR(t.STD_YM, 1, 4), t.EFAS)
			  	END as CapitalAdequacyRatio
			FROM 
			  	Cutoff_CapitalAdequacyRatio_TB t 
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
		WHERE
			CASE	
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN t0.STD_YM in (t0.thisYY, t0.prevYY)
		  		ELSE CONCAT(t0.STD_YM, '12') in (t0.thisYY, t0.prevYY)
		  	END
		) t00
	) t000
ORDER BY 
  	TO_NUMBER(t000.EFAS, '99');
  	
  
  
-- 임시테이블 삭제
DROP TABLE IF EXISTS CapitalAdequacyRatio_TB;
DROP TABLE IF EXISTS IQRcutOff_TB;
DROP TABLE IF EXISTS Cutoff_CapitalAdequacyRatio_TB;