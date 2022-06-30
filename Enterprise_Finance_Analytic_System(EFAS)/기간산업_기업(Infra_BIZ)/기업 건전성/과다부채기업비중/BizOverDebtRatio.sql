/****************************************************************
 * 건전성 지표 추이 - 과다부채(부채비율 200% 초과) 기업 비중 추이 (p.6, [그림3])
 * 활용 테이블 : DEBT_RATIO_TB에서 기업별 부채비율 계산하여 과다부채 기업 비중 계산
 ****************************************************************/
SELECT DISTINCT 
	t0.STD_YM, 
  	CASE 
  		WHEN t0.COMP_SCL_DIVN_CD = 1 THEN t0.COMP_SCL_DIVN_CD || ' 대기업'
  		WHEN t0.COMP_SCL_DIVN_CD = 2 THEN t0.COMP_SCL_DIVN_CD || ' 중소기업'
  		WHEN t0.COMP_SCL_DIVN_CD = 3 THEN t0.COMP_SCL_DIVN_CD || ' 중견기업'
  		ELSE t0.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE, 
  	SUM(t0.isOVERDEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD) as OVERDEBTCNT, -- 기업규모별 과다부채 기업 수
  	COUNT(t0.CORP_NO) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD) as TOTBIZCNT, 
  	-- 기업규모별 기업 수
  	ROUND(SUM(t0.isOVERDEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD) / COUNT(t0.CORP_NO) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD), 4) as OVERDEBTRATIO -- 과다부채기업 비중 
FROM 
  	(
    SELECT 
      	t.STD_YM, 
      	t.CORP_NO, 
      	t.COMP_SCL_DIVN_CD, 
      	t.EFAS, 
      	CASE -- Dvision by zero 회피
      		WHEN (t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL)) >= 2 THEN 1 ELSE 0 
      	END as isOVERDEBT -- 부채비율이 200% 이상이면 1, 아니면 0으로 재코딩
    FROM 
      	DEBT_RATIO_TB t
  	) t0 
WHERE 
	t0.COMP_SCL_DIVN_CD in ('1', '2', '3')
	AND CAST(t0.STD_YM AS INTEGER) <= ${inputGG_YM}
ORDER BY 
  	t0.STD_YM;
 
 

  
 
/****************************************************************
 * 과다부채기업비중 : 업종별 현황 (p.6, [표])
 * 활용 테이블 : DEBT_RATIO_TB -> EFAS_OVERDEBTRATIO_TB 생성
 ****************************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS EFAS_OVERDEBTRATIO_TB;
-- (Step1) 테이블 생성(업종코드, 당해년과다부채기업수, 전체기업수, 전년도과다부채기업수, 전년도전체기업수)
SELECT 
  	t00.EFAS, 
  	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}', '12'), t00.CNTOVERDEBTCORP, 0)) as thisYY_EFAS_CNTOVERDEBTCORP, 
  	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}', '12'), t00.CNTCORP, 0)) as thisYY_EFAS_CNTCORP, 
  	SUM(DECODE(t00.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00.CNTOVERDEBTCORP, 0)) as prevYY_EFAS_CNTOVERDEBTCORP, 
  	SUM(DECODE(t00.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00.CNTCORP, 0)) as prevYY_EFAS_CNTCORP 
  	INTO EFAS_OVERDEBTRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t0.EFAS, 
      	t0.STD_YM, 
      	SUM(t0.ISOVERDEBT) OVER(PARTITION BY t0.EFAS, t0.STD_YM) as CNTOVERDEBTCORP, 
      	COUNT(t0.CORP_NO) OVER(PARTITION BY t0.EFAS, t0.STD_YM) as CNTCORP 
    FROM 
      	(
        SELECT 
          	t.EFAS, 
          	t.CORP_NO, 
          	t.STD_YM, 
          	t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL) as DEBTRATIO, 
          	-- 부채비율
          	CASE -- Dvision by zero 회피
          		WHEN (t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL)) >= 2 THEN 1 ELSE 0 
          	END as isOVERDEBT -- 부채비율이 200% 이상이면 1, 아니면 0으로 재코딩
        FROM 
          	DEBT_RATIO_TB t 
        WHERE 
          	CAST(t.STD_YM AS INTEGER) IN (	-- 당월 및 전년동월
    			CAST(CONCAT( '${inputYYYY}', '12') as integer),
    			CAST(CONCAT( '${inputYYYY}', '12') as integer) - 100)
      	) t0
  	) t00 
GROUP BY 
  	t00.EFAS;

 
-- (Step2) 총계 합산
INSERT INTO EFAS_OVERDEBTRATIO_TB 
SELECT 
  	'99', 
  	-- 총합은 EFAS code '99'할당 
  	SUM(t.thisYY_EFAS_CNTOVERDEBTCORP), 
  	SUM(t.thisYY_EFAS_CNTCORP), 
  	SUM(t.prevYY_EFAS_CNTOVERDEBTCORP), 
  	SUM(t.prevYY_EFAS_CNTCORP) 
FROM 
  	EFAS_OVERDEBTRATIO_TB t;
-- 결과 조회
SELECT * FROM EFAS_OVERDEBTRATIO_TB;


-- (Step3) 당해년/전년 동월 과다부채비중 및 전년 동월 대비 증가율 계산 */
SELECT 
  	t.*, 
  	ROUND(t.thisYY_EFAS_CNTOVERDEBTCORP / t.thisYY_EFAS_CNTCORP, 4) as thisYY_OVERDEBTCORPRATIO, -- 당월 과다부채기업비중
  	ROUND(t.prevYY_EFAS_CNTOVERDEBTCORP / t.prevYY_EFAS_CNTCORP, 4) as prevYY_OVERDEBTCORPRATIO, -- 전년동월 과다부채기업비중
  	ROUND(t.thisYY_EFAS_CNTOVERDEBTCORP / t.thisYY_EFAS_CNTCORP - t.prevYY_EFAS_CNTOVERDEBTCORP / t.prevYY_EFAS_CNTCORP, 4) as OVERDEBTCORPINC -- 과다부채기업비중 증감
FROM 
  	EFAS_OVERDEBTRATIO_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');