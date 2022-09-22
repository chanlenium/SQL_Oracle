/***************************************************************************
 * 신산업 건정성지수(외감기업 대상) : 업종별 및 기업규모별 과다부채기업수 통계 작성              
 ***************************************************************************/



/*****************************************************
 * 과다부채기업 수 추이
 * 활용 테이블 : newGIUP_RAW, TCB_NICE_FNST(재무제표) -> DEBT_RATIO_TB 테이블 만듦
 *****************************************************/
-- (Standby) 월별, 산업별, 기업규모별 부채비율 테이블 생성 (기준년월, 법인번호, 기업규모, KSIC, 부채, 총자산, EFIS)
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS DEBT_RATIO_TB;
-- 테이블 생성
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
                  	t0.STD_DT in (	 -- 최근 4개년
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
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC
  	AND t10.OSIDE_ISPT_YN = 'Y'	-- 외감 대상
  	--AND t10.BLIST_MRKT_DIVN_CD in ('1', '2')	-- 코스피(1), 코스닥(2)만 선택
  	AND t10.DEBT > 0; -- 마이너스 부채 제외
-- 결과 조회
SELECT * FROM DEBT_RATIO_TB ORDER BY STD_YM;



/*****************************************************
 * 과다부채기업 비중
 *****************************************************/
SELECT DISTINCT
	t00.newINDU,
	t00.newINDU_NM,
	t00.BIZ_SIZE,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), t00.OVERDEBTCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as OVERDEBTCNT_N3,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), t00.TOTBIZCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as TOTBIZCNT_N3,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), t00.OVERDEBTCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as OVERDEBTCNT_N2,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), t00.TOTBIZCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as TOTBIZCNT_N2,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), t00.OVERDEBTCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as OVERDEBTCNT_N1,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), t00.TOTBIZCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as TOTBIZCNT_N1,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}', '12'), t00.OVERDEBTCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as OVERDEBTCNT_N0,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}', '12'), t00.TOTBIZCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as TOTBIZCNT_N0
FROM
	(
		(SELECT DISTINCT 
			t0.STD_YM, 
			t0.newINDU,
			t0.newINDU_NM,
		  	CASE 
		  		WHEN t0.COMP_SCL_DIVN_CD = 1 THEN t0.COMP_SCL_DIVN_CD || ' 대기업'
		  		WHEN t0.COMP_SCL_DIVN_CD = 2 THEN t0.COMP_SCL_DIVN_CD || ' 중소기업'
		  		WHEN t0.COMP_SCL_DIVN_CD = 3 THEN t0.COMP_SCL_DIVN_CD || ' 중견기업'
		  		ELSE t0.COMP_SCL_DIVN_CD
		  	END as BIZ_SIZE, 
		  	SUM(t0.isOVERDEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD, t0.newINDU) as OVERDEBTCNT, -- 기업규모별 과다부채 기업 수
		  	COUNT(t0.CORP_NO) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD, t0.newINDU) as TOTBIZCNT  -- 기업규모별 전체 기업 수
		FROM 
		  	(
		    SELECT 
		      	t.STD_YM, 
		      	t.CORP_NO, 
		      	t.COMP_SCL_DIVN_CD, 
		      	t.newINDU,
		      	t.newINDU_NM,
		      	CASE -- Dvision by zero 회피
		      		WHEN (t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL)) >= 2 THEN 1 ELSE 0 
		      	END as isOVERDEBT -- 부채비율이 200% 이상이면 1, 아니면 0으로 재코딩
		    FROM 
		      	DEBT_RATIO_TB t
		  	) t0 
		WHERE t0.COMP_SCL_DIVN_CD in ('1', '2', '3')
		ORDER BY 
		  	t0.STD_YM)
		UNION
		(SELECT DISTINCT -- 전체 합계 계산
			t0.STD_YM, 
			t0.newINDU,
			t0.newINDU_NM,
		  	'전체' as BIZ_SIZE, 
		  	SUM(t0.isOVERDEBT) OVER(PARTITION BY t0.STD_YM, t0.newINDU) as OVERDEBTCNT, -- 기업규모별 과다부채 기업 수
		  	COUNT(t0.CORP_NO) OVER(PARTITION BY t0.STD_YM, t0.newINDU) as TOTBIZCNT  -- 기업규모별 전체 기업 수
		FROM 
		  	(
		    SELECT 
		      	t.STD_YM, 
		      	t.CORP_NO, 
		      	t.COMP_SCL_DIVN_CD, 
		      	t.newINDU,
		      	t.newINDU_NM,
		      	CASE -- Dvision by zero 회피
		      		WHEN (t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL)) >= 2 THEN 1 ELSE 0 
		      	END as isOVERDEBT -- 부채비율이 200% 이상이면 1, 아니면 0으로 재코딩
		    FROM 
		      	DEBT_RATIO_TB t
		  	) t0 
		WHERE t0.COMP_SCL_DIVN_CD in ('1', '2', '3')
		ORDER BY 
		  	t0.STD_YM)
  	) t00
ORDER BY t00.newINDU, t00.BIZ_SIZE;