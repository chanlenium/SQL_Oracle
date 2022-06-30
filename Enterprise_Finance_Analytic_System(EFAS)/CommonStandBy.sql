/**************************************
 * 기업개요 기본테이블(BIZ_RAW) 생성      
 **************************************/
-- (STEP_1) KSIC Table 생성 (보간없는 RAW 테이블)
-- 활용 테이블 : TCB_NICE_COMP_OUTL (NICE기업 개요 테이블) -> KSIC_RAW를 만듦
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS KSIC_RAW;
-- Table 생성 (기준년월, NICE고객번호, 사업자번호, 법인번호, 기업규모(대/중/소), 외감여부, 상장구분, KSIC)
SELECT 
	t.STD_YM, 
	t.COMP_CD,	-- NICE 업체 고유 ID
	t.BRNO,	-- 사업자번호
	t.CORP_NO,	-- 법인번호
	t.COMP_SCL_DIVN_CD as BIZ_SIZE,  -- 기업규모
	t.OSIDE_ISPT_YN,	-- 외부감사여부
	t.BLIST_MRKT_DIVN_CD,	-- 상장여부(1: 코스피, 2: 코스닥)
	SUBSTR(t.STDD_INDU_CLSF_CD, 2) as KSIC 
	INTO KSIC_RAW -- KSIC정보 추출
FROM 
  	TCB_NICE_COMP_OUTL t
WHERE t.BRNO is not NULL 
	AND t.CORP_NO is not NULL;
-- 중간결과 테이블 조회
SELECT t1.* FROM KSIC_RAW t1;


-- (STEP_2) KSIC 보간
-- 활용 테이블 : KSIC_RAW (보간하지 않은 KSIC 테이블) -> KSIC_INTERPOLATION를 만듦 (NICE 기업개요 테이블 내에서도 최대한 KSIC를 보간함)
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS KSIC_INTERPOLATION;
-- Table 생성 (기준년월, 법인번호, NICE고객번호, 사업자번호, 기업규모(대1/중소2/중견3), 외감여부, 상장구분, KSIC)
SELECT 
	DISTINCT t10.STD_YM, 
	t10.CORP_NO, 
	t20.COMP_CD, 
	t20.BRNO,
	t20.BIZ_SIZE,
	t20.OSIDE_ISPT_YN,
	t20.BLIST_MRKT_DIVN_CD,
	t20.KSIC 
	INTO KSIC_INTERPOLATION
FROM
	(
	SELECT 
	 	t1.STD_YM, 
	 	t1.CORP_NO, 
	 	NVL(
	 		To_number(t1.STD_YM, '999999') - MIN(CASE WHEN t1.STD_YM >= t2.STD_YM THEN (To_number(t1.STD_YM, '999999') - To_number(t2.STD_YM, '999999')) ELSE NULL END), 
	 		MIN(To_number(t2.STD_YM, '999999'))
	 	) AS KSIC_REF_YM 
	FROM 
		KSIC_RAW t1
	  	LEFT JOIN (SELECT t2.* FROM KSIC_RAW t2 WHERE t2.KSIC is not null) t2
	  	ON t1.CORP_NO = t2.CORP_NO
	GROUP BY t1.STD_YM, t1.CORP_NO
	) t10 
	LEFT JOIN KSIC_RAW t20 
		ON t10.CORP_NO = t20.CORP_NO AND t10.KSIC_REF_YM = t20.STD_YM
	ORDER BY t10.CORP_NO, t10.STD_YM;
-- 중간결과 테이블 조회
SELECT t1.* FROM KSIC_INTERPOLATION t1;


-- (STEP_3) 신용공여 보유 기업 리스트 Table 생성
-- 활용테이블 : CORP_BIZ_DATA -> CRE_BIZ_LIST를 만듦
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS CRE_BIZ_LIST;
-- Table 생성 (기준년월, 법인번호, 사업자번호)
SELECT DISTINCT 
	t.GG_YM, 
	CASE WHEN LENGTH(TRIM(t.CORP_NO)) > 13 THEN 'IND_BIZ' ELSE TRIM(t.CORP_NO) END as CORP_NO,	-- 개인사업자 표기
	SUBSTR(t.BRNO, 4) as BRNO
	INTO CRE_BIZ_LIST
FROM CORP_BIZ_DATA t
WHERE t.RPT_CD = '31'	-- 보고서 번호 
	AND t.ACCT_CD IN ('1901') -- ('1901', '5301', '1391') 
	AND CAST(t.GG_YM AS INT) >= 201812 
	AND t.SOI_CD IN (
		'01', '03', '05', '07', '11', '13', '15', 
		'21', '31', '33', '35', '37', '41', 
		'43', '44', '46', '47', '61', '71', 
		'74', '75', '76', '77', '79', '81', 
		'83', '85', '87', '89', '91', '94', 
		'95', '97'
	)
	AND t.BRWR_NO_TP_CD in ('1', '3');	-- 법인과 개인만 선택
-- 중간결과 테이블 조회
SELECT * FROM CRE_BIZ_LIST WHERE CORP_NO <> 'IND_BIZ' ORDER BY GG_YM DESC;


-- (STEP_4) CRE_BIZ_LIST의 기준년월(GG_YM)과 KSIC_INTERPOLATION의 기준년월(STD_YM) 정보를 비교하여 'KSIC보간 규칙에 따른' KSIC 참조년월 데이터를 가져옴
-- 활용테이블 : CRE_BIZ_LIST, KSIC_INTERPOLATION -> BIZ_KSIC_HIST를 만듦
-- KSIC 이력조차 없는 기업은 KSIC를 NULL로 코딩
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BIZ_KSIC_HIST;
-- KSIC이력 테이블 생성(기준년월, 법인번호, 사업자번호, KSIC, 기업규모, 외감여부, 상장구분)
SELECT DISTINCT -- LEFT JOIN을 하더라도 multiple match가 있으면 row 수가 증가하므로 DISTINCT 적용
	t10.GG_YM, 
	t10.CORP_NO, 
	t10.BRNO,
	t20.KSIC, 
	t20.BIZ_SIZE,
	t20.OSIDE_ISPT_YN,
	t20.BLIST_MRKT_DIVN_CD
	INTO BIZ_KSIC_HIST 
FROM 
	(
    SELECT 
    	t1.GG_YM, 
      	t1.CORP_NO,
      	t1.BRNO,
      	NVL(
	 		To_number(t1.GG_YM, '999999') - 
	 		MIN(CASE WHEN t1.GG_YM >= t2.STD_YM THEN (To_number(t1.GG_YM, '999999') - To_number(t2.STD_YM, '999999')) ELSE NULL END) OVER(PARTITION BY t1.GG_YM, t1.CORP_NO), 
	 		MIN(To_number(t2.STD_YM, '999999')) OVER(PARTITION BY t1.GG_YM, t1.CORP_NO)
	 	) AS KSIC_REF_YM
    FROM 
      	CRE_BIZ_LIST t1
      	LEFT JOIN KSIC_INTERPOLATION t2 
      		ON t1.CORP_NO = t2.CORP_NO 
	) t10 
  	LEFT JOIN KSIC_INTERPOLATION t20 
  		ON t10.CORP_NO = t20.CORP_NO AND t10.KSIC_REF_YM = t20.STD_YM;
-- 중간결과 테이블 조회
SELECT * FROM BIZ_KSIC_HIST ORDER BY CORP_NO, GG_YM DESC;
	
	
-- (STEP_5) KSIC to EFAS code 매핑 : KSIC를 기준으로 EFAS코드(업종코드)와 매핑      
-- 활용테이블 : BIZ_KSIC_HIST, KSICTOEFIS66 -> BIZ_KSIC_EFAS_HIST 만듦
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BIZ_KSICtoEFAS_HIST;
-- 테이블 생성 (기준년월, 법인번호, 사업자번호, KSIC, EFIS, 기업규모, 외감여부, 상정구분코드)
SELECT DISTINCT 
	t1.GG_YM, 
	t1.CORP_NO,
	t1.BRNO,
	t1.KSIC,
	t2.EFIS,
	t1.BIZ_SIZE,
	t1.OSIDE_ISPT_YN,
	t1.BLIST_MRKT_DIVN_CD
	INTO BIZ_KSICtoEFAS_HIST
FROM 
	BIZ_KSIC_HIST t1 
	LEFT JOIN KSICTOEFIS66 t2 
	ON t1.KSIC = t2.KSIC;
-- 결과 테이블 조회
SELECT * FROM BIZ_KSICtoEFAS_HIST ORDER BY GG_YM DESC;





/**************************************
 * 신용등급 이력정보 획득(interpolation)
 * 신용등급 테이블(TCB_NICE_COMP_CRDT_CLSS)이 불완전(공백존재)하므로 월별 신용공여정보가 있는 모든 기업에 대해 신용등급을 매핑하지 못함
 * 신용등급(CRI) 보간 규칙 : (1) 해당 년월에 CRI정보가 없으면 가장 최근 과거 CRI를 끌어다 쓰고
 *                      (2) 가장 최근 과거 CRI가 없으면, 해당 년월을 기준으로 가장 가까운 미래의 CRI를 끌어다 씀 
 **************************************/
-- (STEP_1) 기업별 가장 최근 신용등급일자에 해당하는 신용등급 추출
-- 활용테이블 : TCB_NICE_COMP_CRDT_CLSS, TCB_NICE_COMP_OUTL -> CORP_CRI를 만듦
-- 동일 연월에 한 기업에 다수 신용등급이 있는 경우 최저 등급 선택
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS CORP_CRI;
-- Table 생성 (등급시작년월, 법인번호, 사업자번호, 신용등급)
SELECT DISTINCT 
	t1000.LAST_CRI_YM,
	t2000.CORP_NO, 
  	t2000.BRNO,
  	-- 법인번호 붙임(COMP_CD와 CORP 매핑)
  	-- 동일년월에 고객번호(COMP_CD)가 2개인 기업이 있음. 
  	-- 이 경우 old COMP_CD에는 신용등급 정보가 없어 1(신용등급미부여또는없음)이 할당되는 반면, new COMP_CD에는 해당 기업의 신용정보가 할당됨
  	-- new COMP_CD와 old COMP_CD가 공존할 경우 하나의 법인번호에 동일년월에 2개의 신용등급이 나타나므로, 
  	-- 이 경우 MAX함수를 사용하여 new COMP_CD에 부여된 신용등급을 가져오도록 로직 구현 (이후 query는 distinct로 마무리 처리)
  	MAX(t1000.CORP_CRI) OVER(PARTITION BY t2000.CORP_NO, t1000.LAST_CRI_YM) AS CORP_CRI 
  	INTO CORP_CRI 
FROM 
  	(
    SELECT 
      	t100.COMP_CD, 
      	t100.LAST_CRI_YM, 
      	MIN(t100.LAST_CRI_CLSS) AS CORP_CRI -- 동일 연월에 한 기업에 다수 신용등급이 있는 경우 최저 등급 선택
    FROM 
      	(
        SELECT 
          	t10.COMP_CD, 
          	SUBSTR(CAST(t10.LAST_CLSS_START_DT AS VARCHAR(8)), 1, 6) AS LAST_CRI_YM, 
          	-- 신용등급 치환 (투자: 4, 투기: 3, 상환불능: 2, 신용등급미부여또는없음: 1)
          	CASE 
          		WHEN t20.CRI_CLSS = 'AAA+' THEN 24 
          		WHEN t20.CRI_CLSS = 'AA+' THEN 23 
          		WHEN t20.CRI_CLSS = 'AA0' THEN 22 
          		WHEN t20.CRI_CLSS = 'AA-' THEN 21 
          		WHEN t20.CRI_CLSS = 'A+' THEN 20 
          		WHEN t20.CRI_CLSS = 'A0' THEN 19 
          		WHEN t20.CRI_CLSS = 'A-' THEN 18 
          		WHEN t20.CRI_CLSS = 'BBB+' THEN 17 
          		WHEN t20.CRI_CLSS = 'BBB0' THEN 16 
          		WHEN t20.CRI_CLSS = 'BBB-' THEN 15 
          		WHEN t20.CRI_CLSS = 'BB+' THEN 14 
          		WHEN t20.CRI_CLSS = 'BB0' THEN 13 
          		WHEN t20.CRI_CLSS = 'BB-' THEN 12 
          		WHEN t20.CRI_CLSS = 'B+' THEN 11 
          		WHEN t20.CRI_CLSS = 'B0' THEN 10 
          		WHEN t20.CRI_CLSS = 'B-' THEN 9 
          		WHEN t20.CRI_CLSS = 'CCC+' THEN 8 
          		WHEN t20.CRI_CLSS = 'CCC0' THEN 7 
          		WHEN t20.CRI_CLSS = 'CCC-' THEN 6 
          		WHEN t20.CRI_CLSS = 'CC+' THEN 5 
          		WHEN t20.CRI_CLSS = 'C+' THEN 4 
          		WHEN t20.CRI_CLSS = 'D' THEN 3 
          		WHEN t20.CRI_CLSS = 'R' THEN 2 
          		WHEN t20.CRI_CLSS = 'NR' THEN 1 
          		ELSE NULL 
          		END AS LAST_CRI_CLSS 
        FROM 
          	(
            SELECT 
            	t1.COMP_CD, 
              	MAX(to_number(t1.CLSS_START_DT, '99999999')) AS LAST_CLSS_START_DT -- 기업별 가장 최근 신용등급평가 일자 선택
            FROM 
              	TCB_NICE_COMP_CRDT_CLSS t1 
            GROUP BY 
              	t1.COMP_CD
          	) AS t10, 
          	TCB_NICE_COMP_CRDT_CLSS t20 
        WHERE 
        	t10.COMP_CD = t20.COMP_CD 
          	AND t10.LAST_CLSS_START_DT = t20.CLSS_START_DT
      	) t100 
    	GROUP BY 
      	t100.COMP_CD, t100.LAST_CRI_YM
  	) t1000, TCB_NICE_COMP_OUTL t2000 
WHERE 
  	t1000.COMP_CD = t2000.COMP_CD;
-- 중간결과 테이블 조회
SELECT * FROM CORP_CRI;


-- (STEP_2) 신용공여 테이블에 신용등급 정보를 붙임
-- 활용테이블 : CRE_BIZ_LIST, CORP_CRI -> BIZ_CRI_HIST를 만듦
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BIZ_CRI_HIST;
-- 테이블 생성(기준년월, 법인번호, 사업자번호, 신용등급)
SELECT DISTINCT
	t10.GG_YM, 
	t10.CORP_NO, 
    t10.BRNO, 
	NVL(t20.CORP_CRI, 1) AS CORP_CRI 
	INTO BIZ_CRI_HIST 
FROM 
  	(
    SELECT DISTINCT 
    	t1.GG_YM, 
      	t1.CORP_NO, 
      	t1.BRNO,
      	-- GG_YM을 기준으로 신용등급 정보가 있는 가장 최근 과거 년월 데이터를 불러옴 (가장 최근 과거 데이터가 없으면 가장 최근 미래 데이터를 갖고옴))
      	NVL(
	 		To_number(t1.GG_YM, '999999') - 
	 		MIN(CASE WHEN t1.GG_YM >= t2.LAST_CRI_YM THEN (To_number(t1.GG_YM, '999999') - To_number(t2.LAST_CRI_YM, '999999')) ELSE NULL END) OVER(PARTITION BY t1.GG_YM, t1.CORP_NO), 
	 		MIN(To_number(t2.LAST_CRI_YM, '999999')) OVER(PARTITION BY t1.GG_YM, t1.CORP_NO)
	 	) AS CRI_REF_YM
    FROM 
    	CRE_BIZ_LIST t1 -- 신용공여 기업리스트 테이블
      	LEFT JOIN CORP_CRI t2 -- 신용등급 테이블
      		ON t1.CORP_NO = t2.CORP_NO 
  	) t10 
  	LEFT JOIN CORP_CRI t20 
  		ON (t10.CORP_NO = t20.CORP_NO) AND (t10.CRI_REF_YM = t20.LAST_CRI_YM);
-- 결과 테이블 조회
SELECT * FROM BIZ_CRI_HIST ORDER BY GG_YM DESC;





/**************************************************
 * 기업 개요 테이블 생성 (BIZ_RAW)
 **************************************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BIZ_RAW;
-- 테이블 생성 (기준년월, 법인번호, 사업자번호, KSIC, 업종코드(EFAS), 기업규모, 외감여부, 상장구분, 신용등급)
SELECT DISTINCT
	t1.*, 
  	t2.CORP_CRI 
  	INTO BIZ_RAW
FROM 
  	BIZ_KSICtoEFAS_HIST t1, BIZ_CRI_HIST t2 
WHERE 
  	t1.GG_YM = t2.GG_YM 
  	AND t1.CORP_NO = t2.CORP_NO
  	AND t1.BRNO = t2.BRNO;
-- 결과 테이블 조회
SELECT * FROM BIZ_RAW ORDER BY GG_YM DESC;




-- 최종 결과 테이블을 제외하고는 모두 DROP
DROP TABLE IF EXISTS KSIC_RAW;
DROP TABLE IF EXISTS KSIC_INTERPOLATION;
DROP TABLE IF EXISTS CRE_BIZ_LIST;
DROP TABLE IF EXISTS BIZ_KSIC_HIST;
DROP TABLE IF EXISTS BIZ_KSICtoEFAS_HIST;
DROP TABLE IF EXISTS CORP_CRI;
DROP TABLE IF EXISTS BIZ_CRI_HIST;