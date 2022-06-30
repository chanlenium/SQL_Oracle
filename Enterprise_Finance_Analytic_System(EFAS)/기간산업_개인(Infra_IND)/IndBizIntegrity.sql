/***********************************
 * 개인사업자대출 연체율 추이 - 개인사업자대출 잔액 추이 (p.8, [그림2])
 * 활용 테이블: IND_BRNO_OVD_RAW           
 ***********************************/
-- IND_BRNO_OVD_RAW 테이블에서 기업대출, 가계대출에 대한 연체율 추이 도출
SELECT DISTINCT 
	t.GG_YM, 
	ROUND(SUM(t.isBIZOVERDUE) OVER(PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM), 4) as BIZ_OVD_RATIO,	-- 기업대출 연체율
	ROUND(SUM(t.isHOUOVERDUE) OVER(PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM), 4) as HOU_OVD_RATIO,	-- 가계대출 연체율
	ROUND(SUM(CASE WHEN (t.isBIZOVERDUE = 0 AND t.isHOUOVERDUE = 0) THEN 0 ELSE 1 END) OVER(PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM), 4) as OVD_RATIO -- 기업 or 가계대출 연체율
FROM
	IND_BRNO_OVD_RAW t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM};