/*****************************************************
 * 신산업 정책금융 현황 - 신산업별 연체율
 * 신용공여정보 보유 기업 수 대비 연체 기업 수 비중 계산
 * 활용 테이블 : BASIC_newBIZ_OVD -> 월별, 산업별 연체율 계산
 *****************************************************/


/***********************************
 * 신산업별 연체율 (월별현황)
 ***********************************/
SELECT DISTINCT 
 	t.GG_YM, 
  	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM) as NUM_OF_OVERDUE_BIZ,	-- 연체 기업수
  	COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM) as TOT_NUM_OF_BIZ,  -- 전체 기업수 
  	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM) as OVERDUE_RATIO	-- 연체율  
FROM
	BASIC_newBIZ_OVD t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM};
	




/*****************************************************
 * 연체기업 수: 업종별, 분기별 현황
 *****************************************************/
SELECT DISTINCT
	t0.newINDU,
	t0.newINDU_NM,
	t0.BIZ_SIZE,
	-- 조회 기준년(연체 기업 수, 전체 기업 수)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR(TO_DATE('${inputYYYYMM}', 'YYYYMM')::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q0,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR(TO_DATE('${inputYYYYMM}', 'YYYYMM')::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q0,
	-- 1분기 직전(연체 기업 수, 전체 기업 수)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 90)::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q1,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 90)::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q1,
	-- 2분기 직전(연체 기업 수, 전체 기업 수)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 180)::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q2,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 180)::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q2,
	-- 3분기 직전(연체 기업 수, 전체 기업 수)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 270)::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q3,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 270)::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q3,
	-- 4분기 직전(연체 기업 수, 전체 기업 수)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 365)::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q4,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 365)::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q4,
	-- 5분기 직전(연체 기업 수, 전체 기업 수)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 90))::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q5,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 90))::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q5,
	-- 6분기 직전(연체 기업 수, 전체 기업 수)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 180))::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q6,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 180))::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q6,
	-- 7분기 직전(연체 기업 수, 전체 기업 수)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 270))::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q7,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 270))::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q7,
	-- 8분기 직전(연체 기업 수, 전체 기업 수)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 365))::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q8,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 365))::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q8
FROM
	(
		(SELECT DISTINCT
			t.GG_YM,
		  	t.newINDU,
		  	t.newINDU_NM,
		  	CASE 
		  		WHEN t.BIZ_SIZE = 1 THEN t.BIZ_SIZE || ' 대기업'
		  		WHEN t.BIZ_SIZE = 2 THEN t.BIZ_SIZE || ' 중소기업'
		  		WHEN t.BIZ_SIZE = 3 THEN t.BIZ_SIZE || ' 중견기업'
		  		ELSE t.BIZ_SIZE
		  	END as BIZ_SIZE,
		  	SUM(t.isOVERDUE) OVER(PARTITION BY t.GG_YM, t.newINDU, t.BIZ_SIZE) as newINDU_OVERDUE_BIZ_CNT, 	-- 연체 기업수
		  	COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM, t.newINDU, t.BIZ_SIZE) as newINDU_TOT_BIZ_CNT 	-- 총 기업수
		FROM 
			BASIC_newBIZ_OVD t 
		WHERE
			t.GG_YM in (
				TO_CHAR(TO_DATE('${inputYYYYMM}', 'YYYYMM')::date, 'YYYYMM'),	-- 조회 기준년
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 90)::date, 'YYYYMM'),	-- 1분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 180)::date, 'YYYYMM'),	-- 2분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 270)::date, 'YYYYMM'),	-- 3분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 365)::date, 'YYYYMM'),	-- 4분기 직전(전년 동월)
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 90))::date, 'YYYYMM'),	-- 5분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 180))::date, 'YYYYMM'),	-- 6분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 270))::date, 'YYYYMM'),	-- 7분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 365))::date, 'YYYYMM')	-- 8분기 직전(전전년 동월)
				)
			AND t.BIZ_SIZE in ('1', '2', '3')	-- 기업구분 없는 것 제외
		ORDER BY t.GG_YM, t.newINDU)
		UNION
		(SELECT DISTINCT
			t.GG_YM,
		  	t.newINDU,
		  	t.newINDU_NM,
		  	'전체' as BIZ_SIZE,
		  	SUM(t.isOVERDUE) OVER(PARTITION BY t.GG_YM, t.newINDU) as newINDU_OVERDUE_BIZ_CNT, 	-- 연체 기업수
		  	COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM, t.newINDU) as newINDU_TOT_BIZ_CNT 	-- 총 기업수
		FROM 
			BASIC_newBIZ_OVD t 
		WHERE
			t.GG_YM in (
				TO_CHAR(TO_DATE('${inputYYYYMM}', 'YYYYMM')::date, 'YYYYMM'),	-- 조회 기준년
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 90)::date, 'YYYYMM'),	-- 1분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 180)::date, 'YYYYMM'),	-- 2분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 270)::date, 'YYYYMM'),	-- 3분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 365)::date, 'YYYYMM'),	-- 4분기 직전(전년 동월)
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 90))::date, 'YYYYMM'),	-- 5분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 180))::date, 'YYYYMM'),	-- 6분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 270))::date, 'YYYYMM'),	-- 7분기 직전
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 365))::date, 'YYYYMM')	-- 8분기 직전(전전년 동월)
				)			
			AND t.BIZ_SIZE in ('1', '2', '3')	-- 기업구분 없는 것 제외
		ORDER BY t.GG_YM, t.newINDU)
	) t0
ORDER BY t0.newINDU;