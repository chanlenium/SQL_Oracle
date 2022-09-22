/****************************************************************
 * 신산업 실적 - 신산업별 경영실적 추이 (p.7, [그림2])
 * 활용 테이블 : newGIUP_RAW, TCB_NICE_FNST(재무제표) -> SALES_TB 테이블 만듦
 ****************************************************************/
-- (Standby) 월별, 산업별, 기업규모별 매출액 테이블 SALES_TB 생성 
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS SALES_TB;
-- (Step1) 테이블 생성(기준년월, 법인번호, 기업규모, 외감여부, 상장구분코드, KSIC, 결산구분, 매출액, EFAS)
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
  	t0.SALES, 
  	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
  	INTO SALES_TB 
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
			      	t1.SALES
			    FROM 
			    	(
			    	SELECT 
			    		t000.COMP_CD, 
			          	t000.SEAC_DIVN,
			          	t000.STD_DT, 
			          	t000.SALES 
			    	FROM
				  		(	
				        SELECT 
				      		t00.STD_YM, 
					      	t00.COMP_CD, 
					      	t00.SEAC_DIVN,
					     	t00.STD_DT,
					     	t00.SALES,  
					     	-- 동일 기준일자(STD_DT)에 등록된 재무 데이터가 있으면 기준년월(STD_YM)이 최근인 데이터 사용 
				          	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
				        FROM 
				          	(
				            SELECT 
				              	t0.STD_YM, 
				              	t0.COMP_CD, 
				              	t0.SEAC_DIVN,
				              	t0.STD_DT,
				              	t0.SALES
				            FROM 
				              	(
				                SELECT
				                	t.STD_YM, 
				                    t.COMP_CD, 
				                    t.SEAC_DIVN,	-- 결산구분 (K: 결산, B: 반기, F: 1/4분기, T: 3/4분기)
				                    t.STD_DT, 	-- 재무데이터 기준일
				                    t.AMT as SALES	-- 매출액
				                FROM 
				                  	TCB_NICE_FNST t 
				                WHERE 
				                   	t.REPORT_CD = '12' 
				                   	AND t.ITEM_CD = '1000'	-- 매출액(12/5000) 
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
SELECT * FROM SALES_TB ORDER BY STD_YM;



/*************************************************
 * (Step2) 신산업별 상장기업 분기별 매출액
 *************************************************/
SELECT DISTINCT
	t000.STD_YM,
	SUM(t000.newINDU_SALES_1) OVER(PARTITION BY t000.STD_YM) as '1 자율주행차',
	SUM(t000.newINDU_SALES_2) OVER(PARTITION BY t000.STD_YM) as '2 IOT가전',
	SUM(t000.newINDU_SALES_3) OVER(PARTITION BY t000.STD_YM) as '3 스마트 헬스케어',
	SUM(t000.newINDU_SALES_4) OVER(PARTITION BY t000.STD_YM) as '4 바이오신약',
	SUM(t000.newINDU_SALES_5) OVER(PARTITION BY t000.STD_YM) as '5 차세대반도체',
	SUM(t000.newINDU_SALES_6) OVER(PARTITION BY t000.STD_YM) as '6 차세대디스플레이',
	SUM(t000.newINDU_SALES_7) OVER(PARTITION BY t000.STD_YM) as '7 신재생에너지',
	SUM(t000.newINDU_SALES_8) OVER(PARTITION BY t000.STD_YM) as '8 ESS',
	SUM(t000.newINDU_SALES_9) OVER(PARTITION BY t000.STD_YM) as '9 스마트그리드',
	SUM(t000.newINDU_SALES_10) OVER(PARTITION BY t000.STD_YM) as '10 전기차'
FROM
	(
	SELECT 
		t00.*,
		DECODE(t00.newINDU_NM, '자율주행차', t00.newINDU_SALES, 0) as newINDU_SALES_1,
		DECODE(t00.newINDU_NM, 'IOT 가전', t00.newINDU_SALES, 0) as newINDU_SALES_2,
		DECODE(t00.newINDU_NM, '스마트 헬스케어', t00.newINDU_SALES, 0) as newINDU_SALES_3,
		DECODE(t00.newINDU_NM, '바이오신약', t00.newINDU_SALES, 0) as newINDU_SALES_4,
		DECODE(t00.newINDU_NM, '차세대반도체', t00.newINDU_SALES, 0) as newINDU_SALES_5,
		DECODE(t00.newINDU_NM, '차세대디스플레이', t00.newINDU_SALES, 0) as newINDU_SALES_6,
		DECODE(t00.newINDU_NM, '신재생에너지', t00.newINDU_SALES, 0) as newINDU_SALES_7,
		DECODE(t00.newINDU_NM, 'ESS', t00.newINDU_SALES, 0) as newINDU_SALES_8,
		DECODE(t00.newINDU_NM, '스마트그리드', t00.newINDU_SALES, 0) as newINDU_SALES_9,
		DECODE(t00.newINDU_NM, '전기차', t00.newINDU_SALES, 0) as newINDU_SALES_10
	FROM 	
		(
		SELECT DISTINCT
			t0.STD_YM,
			t0.newINDU,
			t0.newINDU_NM,
			SUM(t0.SALES) OVER(PARTITION BY t0.STD_YM, t0.newINDU) as newINDU_SALES
		FROM
			(	
			SELECT DISTINCT 
				t.STD_YM, 
				t.CORP_NO,
				t.newINDU,
				t.newINDU_NM,
				ROUND(t.SALES/1000, 0) as SALES -- 단위 변환(천원 -> 백만원) 
			FROM 
				SALES_TB t
			WHERE 
				t.BLIST_MRKT_DIVN_CD in ('1', '2')	-- 상장기업(코스피, 코스닥)
				AND NVL(t.EFAS, '') <> '55'			-- 금융보험업 제외
			) t0
		) t00
	) t000
ORDER BY t000.STD_YM;

  
  
  -- 임시테이블 삭제
DROP TABLE IF EXISTS SALES_TB;