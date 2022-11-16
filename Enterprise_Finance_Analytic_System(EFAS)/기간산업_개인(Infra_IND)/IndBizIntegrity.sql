/***********************************
 * 개인사업자대출 연체율 추이 - 개인사업자대출 잔액 추이 (p.8, [그림2])
 * RFP p.19 [그림2] 개인사업자 연체율 추이
 * 활용 테이블: IND_BRNO_OVD_RAW           
 ***********************************/
-- IND_BRNO_OVD_RAW 테이블에서 기업대출, 가계대출에 대한 연체율 추이 도출
DROP TABLE IF EXISTS RESULT_IndBizIntegrity;
SELECT DISTINCT	
	t0.GG_YM,
	-- 기업대출
	ROUND(SUM(t0.isBIZOVERDUE) OVER(PARTITION BY t0.GG_YM) / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM), 4) as BIZ_OVD_RATIO,	-- 기업대출 연체율
	-- 가계대출
	ROUND(SUM(t0.isHOUOVERDUE) OVER(PARTITION BY t0.GG_YM) / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM), 4) as HOU_OVD_RATIO,	-- 가계대출 연체율
	-- 전체대출
	ROUND(SUM(t0.isTOTOVERDUE) OVER(PARTITION BY t0.GG_YM) / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM), 4) as TOT_OVD_RATIO	-- 전체대출 연체율
	INTO RESULT_IndBizIntegrity
FROM
	(
	SELECT DISTINCT
		t.GG_YM,
		t.BRNO,
		CASE WHEN sum(t.BRNO_ODU_AMT) over (partition by t.GG_YM, t.BRNO) > 0 THEN 1 ELSE 0 END as isBIZOVERDUE,	-- 사업자대출연체 여부
		CASE WHEN sum(t.LOAN_OVD_AMT) over (partition by t.GG_YM, t.BRNO) > 0 THEN 1 ELSE 0 END as isHOUOVERDUE,	-- 가계대출연체 여부
		CASE WHEN ((sum(t.BRNO_ODU_AMT) over (partition by t.GG_YM, t.BRNO) > 0) OR 
			(sum(t.LOAN_OVD_AMT) over (partition by t.GG_YM, t.BRNO) > 0)) THEN 1 ELSE 0 END as isTOTOVERDUE	-- 전체연체 여부
	FROM
		BASIC_IND_BIZ_LOAN t
	WHERE 
		NVL(t.BR_ACT, '') <> '3'	-- 폐업 제외
		AND NVL(t.BRNO_AMT, 0) > 0	-- 사업자대출이 있는 차주 선택
		AND NVL(t.EFAS, '') <> '55'
	ORDER BY t.BRNO, t.GG_YM
	) t0;
	
---- 결과 조회
SELECT * FROM RESULT_IndBizIntegrity ORDER BY GG_YM;



select * from BASIC_IND_BIZ_LOAN;