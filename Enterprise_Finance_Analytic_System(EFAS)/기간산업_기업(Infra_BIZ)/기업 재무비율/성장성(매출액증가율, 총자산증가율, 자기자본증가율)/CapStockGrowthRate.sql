/****************************************************************
 * 성장성 지표 추이 - 자기자본 증가율 추이 (p.6, [그림4])
 * 활용 테이블 : GIUP_RAW, TCB_NICE_FNST(재무제표) -> CapSTOCK_TB 테이블 만듦
 ****************************************************************/
-- (Standby) 월별, 산업별, 기업규모별 자기자본 테이블 CapSTOCK_TB 생성 
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS CapSTOCK_TB;
-- 테이블 생성 (기준년월, 법인번호, 기업규모, KSIC, 자본금, EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO CapSTOCK_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC,
      	t1.CapSTOCK
    FROM 
      	(
        SELECT 
          t00.COMP_CD, 
          t00.STD_DT,
          t00.CapSTOCK 
        FROM 
          	(
            SELECT 
              	t0.STD_YM, 
              	t0.COMP_CD, 
              	t0.STD_DT,
              	t0.CapSTOCK,  
              	-- 동일 기준일자에 등록된 재무제표가 있으면 기준년월이 최근인 데이터 사용 
              	ROW_NUMBER() OVER(PARTITION BY t0.COMP_CD, t0.STD_DT ORDER BY t0.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT
                	t.STD_YM, 
                    t.COMP_CD, 
                    t.STD_DT, 
                    t.AMT as CapSTOCK	-- 자본금
                FROM 
                  	TCB_NICE_FNST t 
                WHERE 
                   	t.REPORT_CD = '11' 
                   	AND t.ITEM_CD = '8100'	-- 자본금(11/8100) 
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
      	LEFT JOIN GIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
      			AND t2.OSIDE_ISPT_YN = 'Y'
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- 결과 조회
SELECT * FROM CapSTOCK_TB ORDER BY STD_YM;





/*************************************************
 * 기업규모별(대/중/소) 연도별 총자산증가율 (1: 대기업, 2: 중소기업, 3: 중견기업, 0: 대상아님)
 *************************************************/
SELECT 
	t00.*,
	ROUND((t00.TOT_CapSTOCK_N2 / t00.TOT_CapSTOCK_N3 - 1), 4) as CapSTOCK_GROWTH_RATE_N2,
	ROUND((t00.TOT_CapSTOCK_N1 / t00.TOT_CapSTOCK_N2 - 1), 4) as CapSTOCK_GROWTH_RATE_N1,
	ROUND((t00.TOT_CapSTOCK_N0 / t00.TOT_CapSTOCK_N1 - 1), 4) as CapSTOCK_GROWTH_RATE_N0
FROM
	(
	SELECT DISTINCT 
		CASE 
	  		WHEN t0.COMP_SCL_DIVN_CD = 1 THEN t0.COMP_SCL_DIVN_CD || ' 대기업'
	  		WHEN t0.COMP_SCL_DIVN_CD = 2 THEN t0.COMP_SCL_DIVN_CD || ' 중소기업'
	  		WHEN t0.COMP_SCL_DIVN_CD = 3 THEN t0.COMP_SCL_DIVN_CD || ' 중견기업'
	  		ELSE t0.COMP_SCL_DIVN_CD
	  	END as BIZ_SIZE,  
	  	SUM(t0.CapSTOCK_N3) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_CapSTOCK_N3, 
	  	SUM(t0.CapSTOCK_N2) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_CapSTOCK_N2,
	  	SUM(t0.CapSTOCK_N1) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_CapSTOCK_N1,
	  	SUM(t0.CapSTOCK_N0) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_CapSTOCK_N0
	FROM 
	    (
	    SELECT DISTINCT
			t.CORP_NO,
			t.EFAS,
			t.COMP_SCL_DIVN_CD,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N3,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N2,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N1,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}', '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N0
		FROM CapSTOCK_TB t
	  	) t0
	) t00;





/*************************************************
 * 업종별(EFAS) 연도별 자기자본 증가율
 *************************************************/
SELECT 
	t00.*,
	ROUND((t00.TOT_CapSTOCK_N2 / t00.TOT_CapSTOCK_N3 - 1), 4) as CapSTOCK_GROWTH_RATE_N2,
	ROUND((t00.TOT_CapSTOCK_N1 / t00.TOT_CapSTOCK_N2 - 1), 4) as CapSTOCK_GROWTH_RATE_N1,
	ROUND((t00.TOT_CapSTOCK_N0 / t00.TOT_CapSTOCK_N1 - 1), 4) as CapSTOCK_GROWTH_RATE_N0
FROM
	(
	SELECT DISTINCT 
		t0.EFAS,  
  		SUM(t0.CapSTOCK_N3) OVER(PARTITION BY t0.EFAS) as TOT_CapSTOCK_N3, 
  		SUM(t0.CapSTOCK_N2) OVER(PARTITION BY t0.EFAS) as TOT_CapSTOCK_N2,
  		SUM(t0.CapSTOCK_N1) OVER(PARTITION BY t0.EFAS) as TOT_CapSTOCK_N1,
  		SUM(t0.CapSTOCK_N0) OVER(PARTITION BY t0.EFAS) as TOT_CapSTOCK_N0
	FROM 
    	(
    	SELECT DISTINCT
			t.CORP_NO,
			t.EFAS,
			t.COMP_SCL_DIVN_CD,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N3,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N2,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N1,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}', '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N0
		FROM CapSTOCK_TB t
  		) t0
	UNION
	SELECT DISTINCT -- 총계
		'99',
	  	SUM(t0.CapSTOCK_N3) as TOT_CapSTOCK_N3, 
	  	SUM(t0.CapSTOCK_N2) as TOT_CapSTOCK_N2,
	  	SUM(t0.CapSTOCK_N1) as TOT_CapSTOCK_N1,
	  	SUM(t0.CapSTOCK_N0) as TOT_CapSTOCK_N0
	FROM 
	    (
	    SELECT DISTINCT
			t.CORP_NO,
			t.EFAS,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N3,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N2,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N1,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}', '12'), CapSTOCK, 0)) OVER(PARTITION BY t.CORP_NO) as CapSTOCK_N0
		FROM CapSTOCK_TB t
		) t0
	) t00
ORDER BY TO_NUMBER(t00.EFAS);