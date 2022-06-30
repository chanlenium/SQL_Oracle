/***********************************
 * 개인사업자대출 추이 - 개인사업자대출 잔액 추이 (p.8, [그림1])
 * 활용테이블 : BASIC_IND_BIZ_LOAN
 ***********************************/
SELECT DISTINCT 
	t.GG_YM, 
	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM) as '0. 기업대출',
	ROUND(SUM(t.LOAN_1) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '1. 가계대출(신용)',
	ROUND(SUM(t.LOAN_2) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '2. 가계대출(담보)',
	ROUND(SUM(t.LOAN_5) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '5. 가계대출(할부금융)',
	ROUND(SUM(t.LOAN_7) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '7. 가계대출(리스)',
	ROUND(SUM(t.LOAN_9) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '9. 가계대출(기타)',
	ROUND(SUM(t.HOU_LOAN) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '99. 가계대출(Total)'
FROM
	BASIC_IND_BIZ_LOAN t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM};