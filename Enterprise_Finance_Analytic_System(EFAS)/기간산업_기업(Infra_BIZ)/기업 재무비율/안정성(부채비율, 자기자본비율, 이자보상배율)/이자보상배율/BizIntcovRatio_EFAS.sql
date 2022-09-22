/****************************************************************
 * 건전성 지표 추이 - 이자보상배율(=영업이익/이자비용) 추이 (p.6, [그림4])
 * 활용 테이블 : GIUP_RAW, TCB_NICE_FNST(재무제표) -> INTCOVRATIO_TB 테이블 만듦
 ****************************************************************/
-- (Standby) 월별, 산업별, 기업규모별 이자보상배율 테이블 INTCOVRATIO_TB 생성 
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS INTCOVRATIO_TB;
-- 테이블 생성 (기준년월, 법인번호, 기업규모, KSIC, 영업이익, 이자비용, EFAS)
SELECT 
  	t0.STD_YM,
	t0.CORP_NO,
	t0.COMP_SCL_DIVN_CD,
	t0.OSIDE_ISPT_YN,
	t0.BLIST_MRKT_DIVN_CD,
	t0.KSIC,
	t0.SEAC_DIVN,
	t0.INT_EXP,
	t0.OP_PROFIT,
	t0.targetRatio,
	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
  	INTO INTCOVRATIO_TB 
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
			      	t1.OP_PROFIT,
			      	t1.INT_EXP, 
			      	t1.OP_PROFIT / t1.INT_EXP as "targetRatio"	-- 개별 기업의 부채비율
			    FROM 
			      	(
			        SELECT 
			          t000.COMP_CD, 
			          t000.SEAC_DIVN,
			          t000.STD_DT, 
			          t000.OP_PROFIT,
			          t000.INT_EXP
			        FROM 
			          	(
			            SELECT 
			              	t00.STD_YM, 
			              	t00.COMP_CD, 
			              	t00.SEAC_DIVN,
			              	t00.STD_DT, 
			              	t00.OP_PROFIT, 
			              	t00.INT_EXP, 
			              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용 
			              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM
			            FROM 
			              	(
			                SELECT DISTINCT 
			                	t0.STD_YM, 
			                  	t0.COMP_CD, 
			                  	t0.SEAC_DIVN,
			                  	t0.STD_DT, 
			                  	SUM(t0.OP_PROFIT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as OP_PROFIT, -- 영업이익
			                  	SUM(t0.INT_EXP) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as INT_EXP	-- 이자비용                  	
			                FROM 
			                  	(
			                    SELECT 
			                      	t.STD_YM, 	-- 데이터가 집중된 년월
			                      	t.COMP_CD, 
			                      	t.SEAC_DIVN,	-- 결산구분 (K: 결산, B: 반기, F: 1/4분기, T: 3/4분기)
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
			          	t000.LAST_STD_YM = '1'
			          	AND t000.INT_EXP <> '0' -- Divided by zero 회피
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
WHERE t0.KSIC is not NULL and NVL(EFAS, '') <> '55';		
-- 결과 조회
SELECT * FROM INTCOVRATIO_TB ORDER BY STD_YM DESC;



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
		INTCOVRATIO_TB t
	) t0;
-- 결과 조회
SELECT * FROM IQRcutOff_TB ORDER BY STD_YM, EFAS;



-- (Step3) cutoff 테이블 생성
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS Cutoff_INTCOVRATIO_TB;
-- 테이블 생성
SELECT 
	t1.*
	INTO Cutoff_INTCOVRATIO_TB
FROM
	INTCOVRATIO_TB t1, IQRcutOff_TB t2
WHERE 
	t1.STD_YM = t2.STD_YM
	AND	t1.EFAS = t2.EFAS
	AND t1.targetRatio > t2.LowerCutoff
	AND t1.targetRatio < t2.UpperCutoff;
-- 결과 조회
SELECT * FROM Cutoff_INTCOVRATIO_TB;



-- (Step4) 이자보상배율 연별 그래프 (업종별)
SELECT 	
	t000.*,
	thisYY_EFAS_INTCOVRATIO - prevYY_EFAS_INTCOVRATIO as "INCRATIO"	-- 전년 동월 대비 증감율
FROM 
	(
	SELECT DISTINCT
		t00.EFAS,
		t00.thisYY,
		SUM(t00.thisYY_EFAS_INTCOVRATIO) OVER(PARTITION BY t00.EFAS) as thisYY_EFAS_INTCOVRATIO,-- 현월 이자보상배율
		SUM(t00.prevYY_EFAS_INTCOVRATIO) OVER(PARTITION BY t00.EFAS) as prevYY_EFAS_INTCOVRATIO	-- 전년 동월 이자보상배율
	FROM
		(	
		SELECT 
			t0.EFAS,
		  	t0.STD_YM,
		  	t0.thisYY,
		  	CASE	
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN DECODE(t0.STD_YM, t0.thisYY, t0.INTCOVRATIO, 0)
		  		ELSE DECODE(CONCAT(t0.STD_YM, '12'), t0.thisYY, t0.INTCOVRATIO, 0)
		  	END as "thisYY_EFAS_INTCOVRATIO",
		  	CASE	
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN DECODE(t0.STD_YM, t0.prevYY, t0.INTCOVRATIO, 0)
		  		ELSE DECODE(CONCAT(t0.STD_YM, '12'), t0.prevYY, t0.INTCOVRATIO, 0)
		  	END as "prevYY_EFAS_INTCOVRATIO"
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
			  	CASE	-- 이자보상배율
			  		WHEN '${isSangJang}' = 'Y' 
			  		THEN
			  			AVG(t.targetRatio) OVER(PARTITION BY t.STD_YM, t.EFAS)
			  		ELSE
			  			AVG(t.targetRatio) OVER(PARTITION BY SUBSTR(t.STD_YM, 1, 4), t.EFAS)
			  	END as INTCOVRATIO
			FROM 
			  	Cutoff_INTCOVRATIO_TB t 
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
DROP TABLE IF EXISTS INTCOVRATIO_TB;
DROP TABLE IF EXISTS IQRcutOff_TB;
DROP TABLE IF EXISTS Cutoff_INTCOVRATIO_TB;