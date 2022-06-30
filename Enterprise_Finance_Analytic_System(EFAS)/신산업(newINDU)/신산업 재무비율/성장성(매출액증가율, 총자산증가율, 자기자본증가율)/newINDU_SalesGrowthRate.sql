/****************************************************************
 * 성장성 지표 추이 - 매출액성장률 추이 (p.6, [그림4])
 * 활용 테이블 : newGIUP_RAW, TCB_NICE_FNST(재무제표) -> SALES_TB 테이블 만듦
 ****************************************************************/
-- (Standby) 월별, 산업별, 기업규모별 매출액 테이블 SALES_TB 생성 
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS SALES_TB;
-- 테이블 생성 (기준년월, 법인번호, 기업규모, KSIC, newINDU, 매출액, EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO SALES_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC,
      	t2.newINDU,
      	t2.newINDU_NM,
      	t1.SALES
    FROM 
      	(
        SELECT 
          t00.COMP_CD, 
          t00.STD_DT,
          t00.SALES 
        FROM 
          	(
            SELECT 
              	t0.STD_YM, 
              	t0.COMP_CD, 
              	t0.STD_DT,
              	t0.SALES,  
              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용 
              	ROW_NUMBER() OVER(PARTITION BY t0.COMP_CD, t0.STD_DT ORDER BY t0.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT
                	t.STD_YM, 
                    t.COMP_CD, 
                    t.STD_DT, 
                    t.AMT as SALES	-- 매출액
                FROM 
                  	TCB_NICE_FNST t 
                WHERE 
                   	t.REPORT_CD = '12' 
                   	AND t.ITEM_CD = '1000'	-- 매출액(12/5000) 
                   	AND t.STD_DT in (	 -- 최근 4개년
	                	CONCAT('${inputYYYY}', '1231'),
	                	CONCAT('${inputYYYY}' - 1, '1231'),
	                	CONCAT('${inputYYYY}' - 2, '1231'),
	                	CONCAT('${inputYYYY}' - 3, '1231'))  
                ) t0 
          	) t00
        WHERE 
          	t00.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN newGIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
      			AND t2.OSIDE_ISPT_YN = 'Y'      		
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- 결과 조회
SELECT * FROM SALES_TB ORDER BY STD_YM;





/*************************************************
 * 기업규모별(대/중/소) 연도별 매출액성장률 (1: 대기업, 2: 중소기업, 3: 중견기업, 0: 대상아님)
 *************************************************/
SELECT 
	t00.*,
	ROUND((t00.TOT_SALES_N2 / t00.TOT_SALES_N3 - 1), 4) as SALES_GROWTH_RATE_N2,
	ROUND((t00.TOT_SALES_N1 / t00.TOT_SALES_N2 - 1), 4) as SALES_GROWTH_RATE_N1,
	ROUND((t00.TOT_SALES_N0 / t00.TOT_SALES_N1 - 1), 4) as SALES_GROWTH_RATE_N0
FROM
	(
	SELECT DISTINCT 
		CASE 
	  		WHEN t0.COMP_SCL_DIVN_CD = 1 THEN t0.COMP_SCL_DIVN_CD || ' 대기업'
	  		WHEN t0.COMP_SCL_DIVN_CD = 2 THEN t0.COMP_SCL_DIVN_CD || ' 중소기업'
	  		WHEN t0.COMP_SCL_DIVN_CD = 3 THEN t0.COMP_SCL_DIVN_CD || ' 중견기업'
	  		ELSE t0.COMP_SCL_DIVN_CD
	  	END as BIZ_SIZE,  
	  	SUM(t0.SALES_N3) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_SALES_N3, 
	  	SUM(t0.SALES_N2) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_SALES_N2,
	  	SUM(t0.SALES_N1) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_SALES_N1,
	  	SUM(t0.SALES_N0) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_SALES_N0
	FROM 
	    (
	    SELECT DISTINCT
			t.CORP_NO,
			t.COMP_SCL_DIVN_CD,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N3,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N2,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N1,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}', '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N0
		FROM
			(
			SELECT DISTINCT 
				t.STD_YM, 
				t.CORP_NO, 
				t.COMP_SCL_DIVN_CD, 
				t.SALES 
			FROM 
				SALES_TB t	-- 동일 법인번호에 newINDU가 여러개 매핑되는 경우 재무규모가 과대개상될 수 있어 이를 제거
			) t
	  	) t0
	) t00;





/*************************************************
 * 업종별(EFAS) 연도별 매출액성장률
 *************************************************/
SELECT 
	t00.*,
	ROUND((t00.TOT_SALES_N2 / t00.TOT_SALES_N3 - 1), 4) as SALES_GROWTH_RATE_N2,
	ROUND((t00.TOT_SALES_N1 / t00.TOT_SALES_N2 - 1), 4) as SALES_GROWTH_RATE_N1,
	ROUND((t00.TOT_SALES_N0 / t00.TOT_SALES_N1 - 1), 4) as SALES_GROWTH_RATE_N0
FROM
	(
	SELECT DISTINCT 
		To_CHAR(t0.newINDU) as newINDU,  
		t0.newINDU_NM, 
  		SUM(t0.SALES_N3) OVER(PARTITION BY t0.newINDU) as TOT_SALES_N3, 
  		SUM(t0.SALES_N2) OVER(PARTITION BY t0.newINDU) as TOT_SALES_N2,
  		SUM(t0.SALES_N1) OVER(PARTITION BY t0.newINDU) as TOT_SALES_N1,
  		SUM(t0.SALES_N0) OVER(PARTITION BY t0.newINDU) as TOT_SALES_N0
	FROM 
    	(
    	SELECT DISTINCT
			t.CORP_NO,
			t.newINDU,
			t.newINDU_NM,
			t.COMP_SCL_DIVN_CD,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N3,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N2,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N1,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}', '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N0
		FROM SALES_TB t
  		) t0
	UNION
	SELECT DISTINCT -- 총계
		'99',
		'전체',
	  	SUM(t0.SALES_N3) as TOT_SALES_N3, 
	  	SUM(t0.SALES_N2) as TOT_SALES_N2,
	  	SUM(t0.SALES_N1) as TOT_SALES_N1,
	  	SUM(t0.SALES_N0) as TOT_SALES_N0
	FROM 
	    (
	    SELECT DISTINCT
			t.CORP_NO,
			t.newINDU,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N3,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N2,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N1,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}', '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N0
		FROM SALES_TB t
		) t0
	) t00
ORDER BY TO_NUMBER(t00.newINDU);