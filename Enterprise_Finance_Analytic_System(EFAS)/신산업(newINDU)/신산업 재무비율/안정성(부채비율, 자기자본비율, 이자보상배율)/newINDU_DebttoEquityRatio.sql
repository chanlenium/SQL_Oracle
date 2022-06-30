/*****************************************************
 * 건전성 지표 추이 - 부채비율(=부채총액/자기자본) 추이 (p.6, [그림2])
 * 활용 테이블 : newGIUP_RAW, TCB_NICE_FNST(재무제표) -> DEBT_RATIO_TB 테이블 만듦
 *****************************************************/
-- (Standby) 월별, 산업별, 기업규모별 부채비율 테이블 생성 
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS DEBT_RATIO_TB;
-- 테이블 생성(기준년월, 법인번호, 기업규모, KSIC, newINDU, newINDU_NM, 부채, 총자산, EFAS)
SELECT 
	t10.*, 
	t20.EFIS as EFAS
	INTO DEBT_RATIO_TB 
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
      	t1.DEBT, 
      	t1.CAPITAL 
    FROM 
    	(
        SELECT 
          	t000.COMP_CD, 
          	t000.STD_DT, 
          	t000.DEBT, 
          	t000.CAPITAL 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
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
                  	t0.STD_DT, 
                  	SUM(t0.DEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as DEBT, 
                  	SUM(t0.CAPITAL) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as CAPITAL 
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, -- 데이터가 집중된 년월
                      	t.COMP_CD, 
                      	t.STD_DT,	-- 재무데이터 기준일
                      	t.ITEM_CD, 
                      	DECODE(t.ITEM_CD, '8000', t.AMT, 0) as DEBT, -- 부채
                      	DECODE(t.ITEM_CD, '8900', t.AMT, 0) as CAPITAL -- 자본
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	t.REPORT_CD = '11' -- 대차대조표 
                      	and t.ITEM_CD in ('8000', '8900')
                  	) t0 -- 부채총계(8000), 자본총계(8900)
                WHERE 
                  	t0.STD_DT IN (	 -- 최근 4개년
	                	CONCAT('${inputYYYY}', '1231'),
	                	CONCAT('${inputYYYY}' - 1, '1231'),
	                	CONCAT('${inputYYYY}' - 2, '1231'),
	                	CONCAT('${inputYYYY}' - 3, '1231')) 
                ORDER BY 
                  	t0.COMP_CD, t0.STD_DT
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'	-- 최근 데이터만 추출
      	) t1 
      	LEFT JOIN newGIUP_RAW t2
      		ON t1.COMP_CD = t2.COMP_CD
      			AND t2.OSIDE_ISPT_YN = 'Y'
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC
  	--AND t10.OSIDE_ISPT_YN = 'Y'	-- 외감 대상
  	--AND t10.BLIST_MRKT_DIVN_CD in ('1', '2')	-- 코스피(1), 코스닥(2)만 선택
  	AND t10.DEBT > 0; -- 마이너스 부채 제외
-- 결과 조회
SELECT * FROM DEBT_RATIO_TB ORDER BY STD_YM;



/*************************************************
 * 기업규모별(대/중/소) 연도별 부채비율 (1: 대기업, 2: 중소기업, 3: 중견기업, 0: 대상아님)
 *************************************************/
SELECT DISTINCT 
	t.STD_YM, 
  	CASE 
  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN t.COMP_SCL_DIVN_CD || ' 대기업'
  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN t.COMP_SCL_DIVN_CD || ' 중소기업'
  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN t.COMP_SCL_DIVN_CD || ' 중견기업'
  		ELSE t.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE,
  	SUM(t.DEBT) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_DEBT, 
  	SUM(t.CAPITAL) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_CAPITAL, 
  	ROUND(SUM(t.DEBT) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) / SUM(t.CAPITAL) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD), 4) as DEBT_RATIO 
FROM 
	(
	SELECT DISTINCT 
		t.STD_YM, 
		t.CORP_NO, 
		t.COMP_SCL_DIVN_CD, 
		t.DEBT,
		t.CAPITAL 
	FROM 
		DEBT_RATIO_TB t	-- 동일 법인번호에 newINDU가 여러개 매핑되는 경우 재무규모가 과대개상될 수 있어 이를 제거
	) t
ORDER BY 
  	t.STD_YM;

 
 
 
 
 /*****************************************************
 * 부채비율(=부채총액/자기자본) : 업종별 현황 (p.6, [표])
 * 활용 테이블 : DEBT_RATIO_TB -> INDU_DEBTRATIO_TB을 만듦
 *****************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS INDU_DEBTRATIO_TB;
-- (Step1) 테이블 생성
SELECT DISTINCT
  	t0.newINDU, 
  	t0.newINDU_NM, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), INDU_DEBT, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_DEBT, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), INDU_CAPITAL, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_CAPITAL, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), INDU_DEBT, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_DEBT, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), INDU_CAPITAL, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_CAPITAL 
  	INTO INDU_DEBTRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.newINDU, 
  		t.newINDU_NM,  
      	t.STD_YM, 
      	SUM(t.DEBT) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_DEBT,	-- 부채
      	SUM(t.CAPITAL) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_CAPITAL	-- 자본
    FROM 
      	DEBT_RATIO_TB t 
    WHERE 
      	t.STD_YM in (	-- 당월 및 전년동월 선택
      		CONCAT('${inputYYYY}', '12'),
      		CONCAT('${inputYYYY}' - 1, '12')) 
  	) t0;
-- 결과 조회
SELECT * FROM INDU_DEBTRATIO_TB;


-- (Step2) 총계를 계산하여 EFIS_DEBTRATIO_TB에 insert
INSERT INTO INDU_DEBTRATIO_TB 
SELECT 
  	'99', -- 총합은 INDU code '99'할당
  	'전체', 
  	SUM(t.ThisYY_INDU_DEBT), 
  	SUM(t.ThisYY_INDU_CAPITAL), 
  	SUM(t.PrevYY_INDU_DEBT), 
  	SUM(t.PrevYY_INDU_CAPITAL) 
FROM 
  	INDU_DEBTRATIO_TB t;
-- 결과 조회
SELECT * FROM INDU_DEBTRATIO_TB t;


-- (Step3) 당해년/전년 동월 부채비율 및 전년 동월 대비 증가율 계산
SELECT 
  	t.*, 
  	ROUND(t.thisYY_INDU_DEBT / t.thisYY_INDU_CAPITAL, 4) as thisYY_DEBITRATIO, 
  	ROUND(t.prevYY_INDU_DEBT / t.prevYY_INDU_CAPITAL, 4) as prevYY_DEBITRATIO, 
  	ROUND(t.thisYY_INDU_DEBT / t.thisYY_INDU_CAPITAL - t.prevYY_INDU_DEBT / t.prevYY_INDU_CAPITAL, 4) as DEBTRATIOINC 
FROM 
  	INDU_DEBTRATIO_TB t 
ORDER BY 
  	t.newINDU;