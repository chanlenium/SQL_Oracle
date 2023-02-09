/**************************************
 * (Step1) 기업개요 기본테이블(TCB_NICE_COMP_OUTL -> SAS_COMP_OUTL) 생성      
 **************************************/
DROP TABLE IF EXISTS SAS_COMP_OUTL;
SELECT DISTINCT
	SUBSTR(t00.STD_YM, 1, 4) as 'STD_YY',
	t00.COMP_CD,
	t00.CORP_NO,
	t00.BIZ_SIZE,
	t00.KSIC
	into SAS_COMP_OUTL
FROM(
	SELECT 
		t0.*,
		-- 동일 년월에 여러데이터가 있는 경우 이를 데이터 집중년월(STD_YM)으로 정렬
		ROW_NUMBER() OVER(PARTITION BY t0.COMP_CD, SUBSTR(t0.STD_YM, 1, 4) ORDER BY t0.STD_YM DESC) as LAST_STD_YM
	FROM(
		SELECT DISTINCT
			t.STD_YM,	-- 기준년월
			t.COMP_CD,	-- NICE 업체 고유 ID
			t.CORP_NO,	-- 법인번호
			t.COMP_SCL_DIVN_CD as BIZ_SIZE,  -- 기업규모
			SUBSTR(t.NICE_STDD_INDU_CLSF_CD, 4, 5) as KSIC 
		FROM 
		  	TCB_NICE_COMP_OUTL t
		WHERE 
			t.CORP_NO is not NULL
			AND t.OSIDE_ISPT_YN = 'Y'	-- 외감만
		ORDER BY 
			t.COMP_CD, t.STD_YM
		) t0
	) t00
WHERE 
	-- 동일년월에서는 최근 데이터만 추출
	t00.LAST_STD_YM = '1'
ORDER BY
	t00.COMP_CD, SUBSTR(t00.STD_YM, 1, 4);
-- 결과 조회
SELECT * FROM SAS_BIZ_RAW;



/**************************************
 * (Step2) 재무 데이터 생성(TCB_NICE_FNST -> SAS_NICE_FNST) 생성  
 **************************************/
DROP TABLE IF EXISTS SAS_NICE_FNST;
SELECT DISTINCT
	t000.STD_DT,
	t000.COMP_CD, 
  	t000.SEAC_DIVN,	
  	t000.SALES,
  	t000.PROFIT,
    t000.INTEREST,
    t000.INTCOVRATIO
    into SAS_NICE_FNST
FROM
	(	
    SELECT 
  		t00.STD_YM, 
      	t00.COMP_CD, 
      	t00.SEAC_DIVN,
     	t00.STD_DT,
     	t00.SALES,
     	t00.PROFIT,
     	t00.INTEREST,
     	t00.INTCOVRATIO,
     	-- 동일 재무데이터 기준일자(STD_DT)에 등록된 재무 데이터가 있으면 기준년월(STD_YM)이 최근인 데이터 사용 
      	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
    FROM 
      	(
      	SELECT DISTINCT
      		t0.STD_YM,
      		t0.COMP_CD, 
      		t0.SEAC_DIVN,
     		t0.STD_DT,
     		SUM(t0.SALES) OVER (PARTITION BY t0.STD_YM, t0.COMP_CD, t0.SEAC_DIVN, t0.STD_DT) as SALES,
     		SUM(t0.PROFIT) OVER (PARTITION BY t0.STD_YM, t0.COMP_CD, t0.SEAC_DIVN, t0.STD_DT) as PROFIT,
     		SUM(t0.INTEREST) OVER (PARTITION BY t0.STD_YM, t0.COMP_CD, t0.SEAC_DIVN, t0.STD_DT) as INTEREST,
     		SUM(t0.PROFIT) OVER (PARTITION BY t0.STD_YM, t0.COMP_CD, t0.SEAC_DIVN, t0.STD_DT) 
     		/ NULLIF(SUM(t0.INTEREST) OVER (PARTITION BY t0.STD_YM, t0.COMP_CD, t0.SEAC_DIVN, t0.STD_DT), 0) as INTCOVRATIO
      	FROM 	
      		(
      		SELECT
            	t.STD_YM, 
                t.COMP_CD, 
                t.SEAC_DIVN,	-- 결산구분 (K: 결산, B: 반기, F: 1/4분기, T: 3/4분기)
                t.STD_DT, 	-- 재무데이터 기준일
                t.ITEM_CD,
                DECODE(t.ITEM_CD, '1000', t.AMT, 0) as SALES,
                DECODE(t.ITEM_CD, '5000', t.AMT, 0) as PROFIT,
                DECODE(t.ITEM_CD, '6110', t.AMT, 0) as INTEREST,
                t.AMT
            FROM 
              	TCB_NICE_FNST t
            WHERE 
            	t.SEAC_DIVN = 'K'
            	AND t.REPORT_CD = '12' 
            	AND t.ITEM_CD in ('1000', '5000', '6110')	-- 매출액(12/1000), 영업이익(12/5000), 이자비용(12/6110)
        		AND TO_NUMBER(SUBSTR(t.STD_DT, 1, 4)) > 2010	-- 2010년 이후 데이터만 추출
      		) t0
      	) t00
  	) t000 
WHERE 
	-- 최근 데이터만 추출
	t000.LAST_STD_YM = '1'
ORDER BY
	t000.COMP_CD, t000.STD_DT;

-- 결과 조회	
SELEcT * FROM SAS_NICE_FNST;
-- 만약 동일 COMP, 동일 년도에 대해 복수의 STD_DT가 있으면 가장 최근 STD_DT만 남기고 나머지는 제거하는 작업 추가 수행
-- 남은 STD_DT를 SUBSTR(STD_DT, 1, 4)하여 STD_YY를 만들고 종료



/**************************************
 * (Step3) SAS_NICE_FNST와 SAS_COMP_OUTL 결합
 **************************************/
-- COMP_CD와 STD_YY를 결합키로 결합을 하는데..
-- 모형에 사용할 데이터는 SAS_NICE_FNST에 있으므로, SAS_NICE_FNST를 기준으로 SAS_COMP_OUTL left join
-- 그런데 Left join후에 NULL값인 기업개요 값이 존재함
-- 이 경우, 동일 기업에 대해 기업개요가 NULL인 STD_YY 시점을 기준으로 기업개요가 NULL이 아닌 가장 가까운 과거 시점의 기업개요를 끌어다 씀
-- 상기 작업에서 매칭되는 기업개요 정보가 없는 경우, 동일 기업에 대해 기업개요가 NULL인 STD_YY 시점을 기준으로 기업개요가 NULL이 아닌 가장 가까운 미래 시점의 기업개요를 끌어다 씀
-- 두 경우 모두 매칭되는 기업개요가 없으면 해당 레코드는 제거
   












          	
          	
