/******************************************
 * 기업 대출잔액 추이 - 기업규모별 대출(대/중견/중소) (p.1, [그림2])
 * 활용 테이블 : BASIC_BIZ_LOAN
 * 사용자 입력 : 조회기준년월(inputGG_YM)
 ******************************************/
SELECT DISTINCT 
	t.GG_YM, 
	CASE
		WHEN t.BRWR_NO_TP_CD = 1 THEN t.BRWR_NO_TP_CD || ' 개인사업자'
		ELSE t.BRWR_NO_TP_CD || ' 법인사업자'
	END as BRWR_NO_TP_CD,
	CASE 
  		WHEN t.BIZ_SIZE = 1 THEN t.BIZ_SIZE || ' 대기업'
  		WHEN t.BIZ_SIZE = 2 THEN t.BIZ_SIZE || ' 중소기업'
  		WHEN t.BIZ_SIZE = 3 THEN t.BIZ_SIZE || ' 중견기업'
  		ELSE t.BIZ_SIZE
  	END as BIZ_SIZE,
  	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRWR_NO_TP_CD, t.BIZ_SIZE) as LOAN 
FROM 
  	BASIC_BIZ_LOAN t 
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
ORDER BY 
  	t.GG_YM;