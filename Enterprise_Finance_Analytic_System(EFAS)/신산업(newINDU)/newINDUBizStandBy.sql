/***************************************************************************
 *                 신산업 기 업 대 출 기본테이블(BASIC_newBIZ_LOAN) 생성                            
 * 신기술기업대출 기본테이블 생성 (대출 = 대출채권계(1901) + 대출채권CMA계정포함(5301) - 지급보증대지급금(1391))
 ***************************************************************************/
-- 혁신성장공동기준에서 혁신성장 정책금융 수혜 기업의 일반신용공여 현황 테이블 구성
-- 활용 테이블: BASIC_BIZ_LOAN, IT_D2_INPT_DATA_BY_DEGR(IGS D2 Table)  -> BASIC_newBIZ_LOAN 테이블을 만듦               
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE IF EXISTS BASIC_newBIZ_LOAN;
-- Table 생성 (기준년월, 기업구분, 법인(주민)번호, 사업자번호, SOI_CD, EI_ITT_CD, 사업자단위 대출(BRNO_AMT), 사업자단위 연체금(ODU_AMT))
SELECT 
	t1.GG_YM,
	t1.CORP_NO,
	t1.BRNO,
	t1.BRNO_AMT,
	t1.BIZ_SIZE,
	t1.OSIDE_ISPT_YN,
	t1.BLIST_MRKT_DIVN_CD,
	t1.SOI_CD,
	t1.EI_ITT_CD,
	t1.SOI_CD2,
	t1.KSIC,
	t1.EFAS,
	t2.newINDU_code as newINDU,
	t2.newINDU_NM
	INTO BASIC_newBIZ_LOAN
FROM BASIC_BIZ_LOAN t1
	JOIN (SELECT DISTINCT
			a1.CORP_RGST_NO, 
			a2.newINDU_NM, 
			a2.newINDU_code 
		FROM IT_D2_INPT_DATA_BY_DEGR a1, IGStoNewINDU a2
		WHERE a1.JSTD_ITMS_CD = a2.IGS_code
		) t2	-- D2기업 리스트 추출
	ON t1.CORP_NO = t2.CORP_RGST_NO;
-- 결과 조회
SELECT * FROM BASIC_newBIZ_LOAN;










/*****************************************************
 *          신산업 연 체 율 기본테이블 생성(BASIC_newBIZ_OVD)
 * 혁신성장공동기준에서 혁신성장 정책금융 수혜 기업의 연체율현황 테이블
 * 활용 테이블 : BASIC_BIZ_OVD, IT_D2_INPT_DATA_BY_DEGR -> BASIC_newBIZ_OVD 
 *****************************************************/
DROP TABLE IF EXISTS BASIC_newBIZ_OVD;
-- OVERDUE_TB 테이블 생성
SELECT 
	t1.GG_YM,
	t1.CORP_NO,
	t1.BRNO,
	t1.EFAS,
	t1.BIZ_SIZE,
	t1.OSIDE_ISPT_YN,
	t1.BLIST_MRKT_DIVN_CD,
	t1.isOVERDUE,
	t2.newINDU_code as newINDU,
	t2.newINDU_NM
	INTO BASIC_newBIZ_OVD
FROM
	(SELECT DISTINCT
		t.GG_YM,
		t.BRWR_NO_TP_CD,
		t.CORP_NO,
		t.BRNO,
		t.EFAS,
		t.BIZ_SIZE,
		t.OSIDE_ISPT_YN,	-- 외감여부
		t.BLIST_MRKT_DIVN_CD,	-- 상장여부
		CASE 
			WHEN SUM(t.ODU_AMT) OVER(PARTITION BY t.GG_YM, t.BRNO) > 0
			THEN 1
			ELSE 0
		END as isOVERDUE
	FROM BASIC_BIZ_OVD t) t1
	JOIN (SELECT DISTINCT
			a1.CORP_RGST_NO, 
			a2.newINDU_NM, 
			a2.newINDU_code 
		FROM IT_D2_INPT_DATA_BY_DEGR a1, IGStoNewINDU a2
		WHERE a1.JSTD_ITMS_CD = a2.IGS_code
		) t2	-- D2기업 리스트 추출
	ON t1.CORP_NO = t2.CORP_RGST_NO;
-- 결과 조회
SELECT * FROM BASIC_newBIZ_OVD;아