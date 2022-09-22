/*****************************************************
 * (StandBy) 부채비율 테이블 생성
 * 활용 테이블 : TCB_NICE_FNST(재무제표), GIUP_RAW(기업개요) -> DEBT_RATIO_TB 테이블 만듦
 *****************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS DEBT_RATIO_TB;
-- 테이블 생성 월별, 산업별, 기업규모별 부채비율 테이블 생성 (최근 4개년 데이터)
-- (기준년월, 법인번호, 기업규모, 외감여부, 상장여부, KSIC, 결산구분, 부채, 총자산, EFAS)
SELECT 
	t0.STD_YM,
	t0.CORP_NO,
	t0.COMP_SCL_DIVN_CD,
	t0.OSIDE_ISPT_YN,
	t0.BLIST_MRKT_DIVN_CD,
	t0.KSIC,
	t0.SEAC_DIVN,
	t0.DEBT,
	t0.CAPITAL,
	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
	INTO DEBT_RATIO_TB
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
			      	t1.DEBT, 
			      	t1.CAPITAL 
			    FROM 
			    	(
			        SELECT 
			          	t000.COMP_CD, 
			          	t000.SEAC_DIVN,
			          	t000.STD_DT, 
			          	t000.DEBT, 
			          	t000.CAPITAL 
			        FROM 
			          	(
			            SELECT 
			              	t00.STD_YM, 
			              	t00.COMP_CD, 
			              	t00.SEAC_DIVN,
			             	t00.STD_DT, 
			              	t00.DEBT, 
			              	t00.CAPITAL, 
			              	-- 동일 기준일자(STD_DT)에 등록된 재무 데이터가 있으면 기준년월(STD_YM)이 최근인 데이터 사용 
			              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
			            FROM 
			              	(
			                SELECT DISTINCT 
			                	t0.STD_YM, 
			                  	t0.COMP_CD, 
			                  	t0.SEAC_DIVN,
			                  	t0.STD_DT, 
			                  	SUM(t0.DEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as DEBT, 
			                  	SUM(t0.CAPITAL) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as CAPITAL 
			                FROM 
			                  	(
			                    SELECT 
			                      	t.STD_YM, -- 데이터가 집중된 년월
			                      	t.COMP_CD, 
			                      	t.SEAC_DIVN,	-- 결산구분 (K: 결산, B: 반기, F: 1/4분기, T: 3/4분기)
			                      	t.STD_DT,	-- 재무데이터 기준일
			                      	t.ITEM_CD, 
			                      	DECODE(t.ITEM_CD, '8000', ROUND(t.AMT/1000, 0), 0) as DEBT, -- 부채
			                      	DECODE(t.ITEM_CD, '8900', ROUND(t.AMT/1000, 0), 0) as CAPITAL -- 자본
			                    FROM 
			                      	TCB_NICE_FNST t 
			                    WHERE 
			                      	t.REPORT_CD = '11' -- 대차대조표 
			                      	and t.ITEM_CD in ('8000', '8900')	-- 부채총계(8000), 자본총계(8900)
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
WHERE t0.KSIC is not NULL;		
-- 결과 조회
SELECT * FROM DEBT_RATIO_TB;



/****************************************************************
 * 과다부채기업비중 : 업종별 현황 (p.6, [표])
 * RFP p.16 [표] 과다부채기업비중 : 업종별 현황
 * 활용 테이블 : DEBT_RATIO_TB -> EFAS_OVERDEBTRATIO_TB 생성
 ****************************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS EFAS_OVERDEBTRATIO_TB;
-- (Step1) 테이블 생성(업종코드, 당해년과다부채기업수, 전체기업수, 전년도과다부채기업수, 전년도전체기업수)
SELECT DISTINCT
	t000.EFAS,
	SUM(t000.thisYY_EFAS_CNTOVERDEBTCORP) OVER(PARTITION BY t000.EFAS) as thisYY_EFAS_CNTOVERDEBTCORP,	-- 현월 과다부채 기업 수 
	SUM(t000.thisYY_EFAS_CNTCORP) OVER(PARTITION BY t000.EFAS) as thisYY_EFAS_CNTCORP,	-- 현월 전체 기업 수
	SUM(t000.prevYY_EFAS_CNTOVERDEBTCORP) OVER(PARTITION BY t000.EFAS) as prevYY_EFAS_CNTOVERDEBTCORP,	-- 전년 동월 과다부채 기업 수
	SUM(t000.prevYY_EFAS_CNTCORP) OVER(PARTITION BY t000.EFAS) as prevYY_EFAS_CNTCORP	-- 전년 동월 전체 기업 수
	INTO EFAS_OVERDEBTRATIO_TB 
FROM
	(
	SELECT 
	  	t00.EFAS, 
	  	t00.STD_YM,
	  	DECODE(t00.STD_YM, thisYY, t00.CNTOVERDEBTCORP, 0) as thisYY_EFAS_CNTOVERDEBTCORP, 
	  	DECODE(t00.STD_YM, thisYY, t00.CNTCORP, 0) as thisYY_EFAS_CNTCORP, 
	  	DECODE(t00.STD_YM, prevYY, t00.CNTOVERDEBTCORP, 0) as prevYY_EFAS_CNTOVERDEBTCORP, 
	  	DECODE(t00.STD_YM, prevYY, t00.CNTCORP, 0) as prevYY_EFAS_CNTCORP 
	FROM 
	  	(
	    SELECT DISTINCT 
	    	t0.EFAS, 
	      	t0.STD_YM, 
	      	t0.thisYY,
	      	t0.prevYY,
	      	SUM(t0.ISOVERDEBT) OVER(PARTITION BY t0.EFAS, t0.STD_YM) as CNTOVERDEBTCORP, 
	      	COUNT(t0.CORP_NO) OVER(PARTITION BY t0.EFAS, t0.STD_YM) as CNTCORP 
	    FROM 
	      	(
	        SELECT 
	          	t.EFAS, 
	          	t.CORP_NO, 
	          	t.STD_YM, 
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
	          	t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL) as DEBTRATIO, 
	          	-- 부채비율
	          	CASE -- Dvision by zero 회피
	          		WHEN (t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL)) >= 2 THEN 1 ELSE 0 
	          	END as isOVERDEBT -- 부채비율이 200% 이상이면 1, 아니면 0으로 재코딩
	        FROM 
	          	DEBT_RATIO_TB t 
	      	) t0
	    WHERE
			t0.STD_YM in (t0.thisYY, t0.prevYY)
	  	) t00 
	) t000 
ORDER BY 
  	t000.EFAS;

  
  
-- (Step2) 당해년/전년 동월 과다부채비중 및 전년 동월 대비 증가율 계산 */
DROP TABLE IF EXISTS RESULT_BIZ_OVERDEBTRATIO_EFAS;
SELECT 
  	t.EFAS, 
  	ROUND(t.thisYY_EFAS_CNTOVERDEBTCORP / NULLIF(t.thisYY_EFAS_CNTCORP, 0), 4) as thisYY_OVERDEBTCORPRATIO, -- 당월 과다부채기업비중
  	ROUND(t.prevYY_EFAS_CNTOVERDEBTCORP / NULLIF(t.prevYY_EFAS_CNTCORP, 0), 4) as prevYY_OVERDEBTCORPRATIO, -- 전년동월 과다부채기업비중
  	ROUND(t.thisYY_EFAS_CNTOVERDEBTCORP / NULLIF(t.thisYY_EFAS_CNTCORP, 0), 4) 
  	- ROUND(t.prevYY_EFAS_CNTOVERDEBTCORP / NULLIF(t.prevYY_EFAS_CNTCORP, 0), 4) as OVERDEBTCORPINC -- 과다부채기업비중 증감
  	INTO RESULT_BIZ_OVERDEBTRATIO_EFAS
FROM 
  	EFAS_OVERDEBTRATIO_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');
  	

  
-- 임시테이블 삭제
DROP TABLE IF EXISTS DEBT_RATIO_TB;
DROP TABLE IF EXISTS EFAS_OVERDEBTRATIO_TB;

-- 결과 조회
SELECT * FROM RESULT_BIZ_OVERDEBTRATIO_EFAS;