/***********************************
 * 개인사업자 대출 추이 - 개인사업자대출 잔액 추이 (p.10, [그림1])
 * RFP p.19 [그림1] 개인사업자대출 잔액 추이
 * 활용테이블 : BASIC_IND_BIZ_LOAN
 ***********************************/
DROP TABLE IF EXISTS RESULT_INDBIZLOAN;
SELECT DISTINCT 
	t.GG_YM, 
	ROUND(SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM), 0) as '0. 기업대출',
	ROUND(SUM(t.LOAN_1) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '1. 가계대출(신용)',
	ROUND(SUM(t.LOAN_2) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '2. 가계대출(담보)',
	ROUND(SUM(t.LOAN_5) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '5. 가계대출(할부금융)',
	ROUND(SUM(t.LOAN_7) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '7. 가계대출(리스)',
	ROUND(SUM(t.LOAN_9) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '9. 가계대출(기타)',
	ROUND(SUM(t.HOU_LOAN) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '99. 가계대출(Total)'
	INTO RESULT_INDBIZLOAN
FROM
	BASIC_IND_BIZ_LOAN t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
	AND 
	NVL(t.EFAS, '') <> '55';




/***********************************
 * 개인사업자 대출 현황 - 산업별 잔액 (p.10, [그림1])
 * RFP p.20 [그림1] 산업별 잔액
 * 활용테이블 : BASIC_IND_BIZ_LOAN
 ***********************************/
DROP TABLE IF EXISTS RESULT_INDBIZLOAN_EFAS;
SELECT DISTINCT
	t00.GG_YM,
	ROUND(SUM(t00.BRNO_AMT_37) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_37,
	ROUND(SUM(t00.BRNO_AMT_39) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_39,
	ROUND(SUM(t00.BRNO_AMT_22) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_22,
	ROUND(SUM(t00.BRNO_AMT_11) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_11,
	ROUND(SUM(t00.BRNO_AMT_12) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_12,
	ROUND(SUM(t00.BRNO_AMT_26) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_26,
	ROUND(SUM(t00.BRNO_AMT_27) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_27,
	ROUND(SUM(t00.BRNO_AMT_48) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_48,
	ROUND(SUM(t00.BRNO_AMT_45) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_54
	INTO RESULT_INDBIZLOAN_EFAS
FROM
	(
	SELECT
		t0.*,
		DECODE(t0.EFAS, '37', t0.BRNO_AMT, 0) as BRNO_AMT_37,	-- 자동차
		DECODE(t0.EFAS, '39', t0.BRNO_AMT, 0) as BRNO_AMT_39,	-- 조선
		DECODE(t0.EFAS, '22', t0.BRNO_AMT, 0) as BRNO_AMT_22,	-- 철강
		DECODE(t0.EFAS, '11', t0.BRNO_AMT, 0) as BRNO_AMT_11,	-- 정유
		DECODE(t0.EFAS, '12', t0.BRNO_AMT, 0) as BRNO_AMT_12,	-- 석유화학
		DECODE(t0.EFAS, '26', t0.BRNO_AMT, 0) as BRNO_AMT_26,	-- 반도체
		DECODE(t0.EFAS, '27', t0.BRNO_AMT, 0) as BRNO_AMT_27,	-- 디스플레이
		DECODE(t0.EFAS, '48', t0.BRNO_AMT, 0) as BRNO_AMT_48,	-- 해운
		DECODE(t0.EFAS, '45', t0.BRNO_AMT, 0) as BRNO_AMT_45	-- 건설
	FROM
		(
		SELECT 
			t1.GG_YM,
			t1.CORP_NO,
			t1.BRNO,
			t1.BR_ACT,
			t1.SOI_CD,
			t1.EI_ITT_CD,
			t1.BRNO_AMT,
			DECODE(t1.KSIC, NULL, t2.KSIC, t1.KSIC) as KSIC,
			DECODE(t1.EFAS, NULL, t2.EFAS, t1.EFAS) as EFAS,
			t1.BIZ_SIZE,
			t1.SOI_CD2,
			t2.ADDR_CD,
			t2.FND_YM,
			t2.CORP_CRI
		FROM 
			BASIC_IND_BIZ_LOAN t1
			LEFT JOIN BIZ_RAW t2
			ON t1.GG_YM = t2.GG_YM
				AND t1.BRNO = t2.BRNO	
				AND t1.CORP_NO = t2.CORP_NO
				AND NVL(t1.EFAS, '') <> '55'
		) t0
	WHERE t0.EFAS in ('37', '39', '22', '11', '12', '26', '27', '48', '45')
	) t00
ORDER BY t00.GG_YM;





/***********************************
 * 개인사업자 대출 현황 - 업력별 잔액 (p.10, [그림2])
 * RFP p.20 [그림2] 업력별 잔액
 * 활용테이블 : BASIC_IND_BIZ_LOAN
 ***********************************/
DROP TABLE IF EXISTS RESULT_INDBIZLOAN_UPREOK;
SELECT DISTINCT 
	t00.GG_YM,
	ROUND(SUM(t00.BRNO_AMT_NewFound) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_NewFound,
	ROUND(SUM(t00.BRNO_AMT_OldFound) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_OldFound
	INTO RESULT_INDBIZLOAN_UPREOK
FROM
	(
	SELECT
		t0.*,		
		CASE	-- 창업기업 
			WHEN (CAST(t0.FND_YM AS INTEGER) > CAST(t0.GG_YM AS INTEGER) - 100) 
				AND (CAST(t0.FND_YM AS INTEGER) <= CAST(t0.GG_YM AS INTEGER))
			THEN t0.BRNO_AMT
			ELSE 0
		END as BRNO_AMT_NewFound,	
		CASE	-- 기존기업 
			WHEN (CAST(t0.FND_YM AS INTEGER) <= CAST(t0.GG_YM AS INTEGER) - 100) 
			THEN t0.BRNO_AMT
			ELSE 0
		END as BRNO_AMT_OldFound
	FROM
		(
		SELECT 
			t1.GG_YM,
			t1.CORP_NO,
			t1.BRNO,
			t1.BR_ACT,
			t1.SOI_CD,
			t1.EI_ITT_CD,
			t1.BRNO_AMT,
			DECODE(t1.KSIC, NULL, t2.KSIC, t1.KSIC) as KSIC,
			DECODE(t1.EFAS, NULL, t2.EFAS, t1.EFAS) as EFAS,
			t1.BIZ_SIZE,
			t1.SOI_CD2,
			t2.ADDR_CD,
			NULLIF(t2.FND_YM, '') as FND_YM,
			t2.CORP_CRI
		FROM 
			BASIC_IND_BIZ_LOAN t1
			LEFT JOIN BIZ_RAW t2
			ON t1.GG_YM = t2.GG_YM
				AND t1.BRNO = t2.BRNO	
				AND t1.CORP_NO = t2.CORP_NO
				AND NVL(t1.EFAS, '') <> '55'
		) t0
		WHERE t0.FND_YM not like '%[0-9]%'
	) t00
ORDER BY t00.GG_YM;







/***********************************
 * 개인사업자 대출 현황 - 시도별 잔액 (p.10, [그림2])
 * RFP p.20 [그림3] 권역별 잔액
 * 활용테이블 : BASIC_IND_BIZ_LOAN
 ***********************************/
DROP TABLE IF EXISTS RESULT_INDBIZLOAN_LOCATION;
SELECT DISTINCT 
	t00.GG_YM, 
	ROUND(SUM(t00.BRNO_AMT_11) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_11,
	ROUND(SUM(t00.BRNO_AMT_26) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_26,
	ROUND(SUM(t00.BRNO_AMT_27) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_27,
	ROUND(SUM(t00.BRNO_AMT_28) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_28,
	ROUND(SUM(t00.BRNO_AMT_29) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_29,
	ROUND(SUM(t00.BRNO_AMT_30) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_30,
	ROUND(SUM(t00.BRNO_AMT_31) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_31,
	ROUND(SUM(t00.BRNO_AMT_36) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_36,
	ROUND(SUM(t00.BRNO_AMT_41) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_41,
	ROUND(SUM(t00.BRNO_AMT_42) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_42,
	ROUND(SUM(t00.BRNO_AMT_43) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_43,
	ROUND(SUM(t00.BRNO_AMT_44) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_44,
	ROUND(SUM(t00.BRNO_AMT_45) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_45,
	ROUND(SUM(t00.BRNO_AMT_46) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_46,
	ROUND(SUM(t00.BRNO_AMT_47) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_47,
	ROUND(SUM(t00.BRNO_AMT_48) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_48,
	ROUND(SUM(t00.BRNO_AMT_50) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_50,
	ROUND(SUM(t00.BRNO_AMT_99) OVER(PARTITION BY t00.GG_YM), 0) as IND_BIZ_LOAN_99
	INTO RESULT_INDBIZLOAN_LOCATION
FROM
	(
	SELECT
		t0.*,
		DECODE(t0.ADDR_CD, '11', t0.BRNO_AMT, 0) as BRNO_AMT_11,	-- 서울
		DECODE(t0.ADDR_CD, '26', t0.BRNO_AMT, 0) as BRNO_AMT_26,	-- 부산
		DECODE(t0.ADDR_CD, '27', t0.BRNO_AMT, 0) as BRNO_AMT_27,	-- 대구
		DECODE(t0.ADDR_CD, '28', t0.BRNO_AMT, 0) as BRNO_AMT_28,	-- 인천
		DECODE(t0.ADDR_CD, '29', t0.BRNO_AMT, 0) as BRNO_AMT_29,	-- 광주
		DECODE(t0.ADDR_CD, '30', t0.BRNO_AMT, 0) as BRNO_AMT_30,	-- 대전
		DECODE(t0.ADDR_CD, '31', t0.BRNO_AMT, 0) as BRNO_AMT_31,	-- 울산
		DECODE(t0.ADDR_CD, '36', t0.BRNO_AMT, 0) as BRNO_AMT_36,	-- 세종
		DECODE(t0.ADDR_CD, '41', t0.BRNO_AMT, 0) as BRNO_AMT_41,	-- 경기
		DECODE(t0.ADDR_CD, '42', t0.BRNO_AMT, 0) as BRNO_AMT_42,	-- 강원
		DECODE(t0.ADDR_CD, '43', t0.BRNO_AMT, 0) as BRNO_AMT_43,	-- 충북
		DECODE(t0.ADDR_CD, '44', t0.BRNO_AMT, 0) as BRNO_AMT_44,	-- 충남
		DECODE(t0.ADDR_CD, '45', t0.BRNO_AMT, 0) as BRNO_AMT_45,	-- 전북
		DECODE(t0.ADDR_CD, '46', t0.BRNO_AMT, 0) as BRNO_AMT_46,	-- 전남
		DECODE(t0.ADDR_CD, '47', t0.BRNO_AMT, 0) as BRNO_AMT_47,	-- 경북
		DECODE(t0.ADDR_CD, '48', t0.BRNO_AMT, 0) as BRNO_AMT_48,	-- 경남
		DECODE(t0.ADDR_CD, '50', t0.BRNO_AMT, 0) as BRNO_AMT_50,	-- 제주
		DECODE(t0.ADDR_CD, '99', t0.BRNO_AMT, 0) as BRNO_AMT_99		-- 기타
	FROM
		(
		SELECT
			t1.GG_YM,
			t1.CORP_NO,
			t1.BRNO,
			t1.BRNO_AMT,
			DECODE(t1.EFAS, NULL, t2.EFAS, t1.EFAS) as EFAS,
			NVL(NULLIF(t2.ADDR_CD, ''), '99') as ADDR_CD
		FROM 
			BASIC_IND_BIZ_LOAN t1
			LEFT JOIN BIZ_RAW t2
			ON t1.GG_YM = t2.GG_YM
				AND t1.CORP_NO = t2.CORP_NO
				AND t1.BRNO = t2.BRNO	
		) t0
	WHERE NVL(t0.EFAS, '') <> '55'
	)t00
ORDER BY t00.GG_YM;



	

/***********************************
 * 개인사업자대출 - 개인사업자대출 개요 (p.9, [그림1])
 * RFP 신규 추가내용
 * 활용테이블 : BASIC_IND_BIZ_LOAN
 ***********************************/
DROP TABLE IF EXISTS RESULT_INDBIZLOAN_SUMMARY;
SELECT DISTINCT
	t1.GG_YM,
	t1.noOwner_BIZLoan,
	t1.noBIZ_BIZLoan,
	t1.AMT_BIZLoan,
	t2.noOwner_HOULoan,
	t2.noBIZ_HOULoan,
	t2.AMT_HOULoan,
	t3.noOwner_BIZHOULoan, 
	t3.noBIZ_BIZHOULoan, 
	t3.AMT_BIZHOULoan,
	t4.noOwner_NoLoan, 
	t4.noBIZ_NoLoan, 
	t4.AMT_NoLoan
	--INTO RESULT_INDBIZLOAN_SUMMARY
FROM
	(
	SELECT DISTINCT	-- 사업자대출 그룹 (사업자, 가계 교집합 포함)
		t0.GG_YM,
		dense_Rank() over (partition by t0.GG_YM order by t0.CORP_NO) 
			+ dense_Rank() over (partition by t0.GG_YM order by t0.CORP_NO desc) - 1 as noOwner_BIZLoan,	-- 차주수
		dense_Rank() over (partition by t0.GG_YM order by t0.BRNO) 
			+ dense_Rank() over (partition by t0.GG_YM order by t0.BRNO desc) - 1 as noBIZ_BIZLoan,	-- 사업장수
		--ROUND(SUM(NVL(t0.BRNO_AMT, 0)) OVER(PARTITION BY t0.GG_YM), 0),
		--ROUND(SUM(NVL(t0.HOU_LOAN, 0) / 1000) OVER(PARTITION BY t0.GG_YM), 0),
		ROUND(SUM(NVL(t0.BRNO_AMT, 0) + NVL(t0.HOU_LOAN, 0) / 1000) OVER(PARTITION BY t0.GG_YM), 0) as AMT_BIZLoan	-- 대출잔액
	FROM
		(
		SELECT
			t.GG_YM,
			t.CORP_NO,
			t.BRNO,
			t.BRNO_AMT,	
			t.HOU_LOAN
		FROM
			BASIC_IND_BIZ_LOAN t
		WHERE 
			NVL(t.BR_ACT, '') <> '3'	-- 폐업 제외
			AND 
			NVL(t.BRNO_AMT, 0) <> 0		-- 사업자대출그룹 선택
			and NVL(t.EFAS, '') <> '55'
		ORDER BY
			t.GG_YM, t.BRNO
		) t0
	)t1,
	(
	SELECT DISTINCT	-- 가계대출 그룹 (사업자, 가계 교집합 포함)
		t0.GG_YM,
		dense_Rank() over (partition by t0.GG_YM order by t0.CORP_NO) 
			+ dense_Rank() over (partition by t0.GG_YM order by t0.CORP_NO desc) - 1 as noOwner_HOULoan,	-- 차주수
		dense_Rank() over (partition by t0.GG_YM order by t0.BRNO) 
			+ dense_Rank() over (partition by t0.GG_YM order by t0.BRNO desc) - 1 as noBIZ_HOULoan,	-- 사업장수
		ROUND(SUM(NVL(t0.BRNO_AMT, 0)) OVER(PARTITION BY t0.GG_YM), 0),
		ROUND(SUM(NVL(t0.HOU_LOAN, 0) / 1000) OVER(PARTITION BY t0.GG_YM), 0),
		ROUND(SUM(NVL(t0.BRNO_AMT, 0) + NVL(t0.HOU_LOAN, 0) / 1000) OVER(PARTITION BY t0.GG_YM), 0) as AMT_HOULoan	-- 대출잔액
	FROM
		(
		SELECT
			t.GG_YM,
			t.CORP_NO,
			t.BRNO,
			t.BRNO_AMT,
			t.HOU_LOAN
		FROM
			BASIC_IND_BIZ_LOAN t
		WHERE 
			NVL(t.BR_ACT, '') <> '3'	-- 폐업 제외
			AND 
			NVL(t.HOU_LOAN, 0) <> 0		-- 가계대출그룹 선택
			AND 
			NVL(t.EFAS, '') <> '55'
		ORDER BY
			t.GG_YM, t.BRNO
		) t0
	)t2,
	(
	SELECT DISTINCT	-- 사업자 & 가계 대출 모두 있는 case (교집합)
		t0.GG_YM,
		dense_Rank() over (partition by t0.GG_YM order by t0.CORP_NO) 
			+ dense_Rank() over (partition by t0.GG_YM order by t0.CORP_NO desc) - 1 as noOwner_BIZHOULoan,	-- 차주수
		dense_Rank() over (partition by t0.GG_YM order by t0.BRNO) 
			+ dense_Rank() over (partition by t0.GG_YM order by t0.BRNO desc) - 1 as noBIZ_BIZHOULoan,	-- 사업장수
		-- ROUND(SUM(NVL(t0.BRNO_AMT, 0)) OVER(PARTITION BY t0.GG_YM), 0),
		-- ROUND(SUM(NVL(t0.HOU_LOAN, 0) / 1000) OVER(PARTITION BY t0.GG_YM), 0),
		ROUND(SUM(NVL(t0.BRNO_AMT, 0) + NVL(t0.HOU_LOAN, 0) / 1000) OVER(PARTITION BY t0.GG_YM), 0) as AMT_BIZHOULoan	-- 대출잔액
	FROM
		(
		SELECT
			t.GG_YM,
			t.CORP_NO,
			t.BRNO,
			t.BRNO_AMT,
			t.HOU_LOAN
		FROM
			BASIC_IND_BIZ_LOAN t
		WHERE 
			NVL(t.BR_ACT, '') <> '3'	-- 폐업 제외
			AND 
			NVL(t.HOU_LOAN, 0) <> 0	AND NVL(t.BRNO_AMT, 0) <> 0	-- 사업자&가계대출그룹 선택
			AND 
			NVL(t.EFAS, '') <> '55'
		ORDER BY
			t.GG_YM, t.BRNO
		) t0
	) t3,
	(
	SELECT DISTINCT	-- 대출이 없는 case
		t0.GG_YM,
		dense_Rank() over (partition by t0.GG_YM order by t0.CORP_NO) 
			+ dense_Rank() over (partition by t0.GG_YM order by t0.CORP_NO desc) - 1 as noOwner_NoLoan,
		dense_Rank() over (partition by t0.GG_YM order by t0.BRNO) 
			+ dense_Rank() over (partition by t0.GG_YM order by t0.BRNO desc) - 1 as noBIZ_NoLoan,
		ROUND(SUM(NVL(t0.BRNO_AMT, 0) + NVL(t0.HOU_LOAN, 0) / 1000) OVER(PARTITION BY t0.GG_YM), 0) as AMT_NoLoan
	FROM
		(
		SELECT 
			t.GG_YM,
			t.CORP_NO,
			t.BRNO,
			t.BRNO_AMT,
			t.HOU_LOAN
		FROM
			BASIC_IND_BIZ_LOAN t
		WHERE 
			NVL(t.BR_ACT, '') <> '3'	-- 폐업 제외
			AND (NVL(t.BRNO_AMT, 0) = 0 AND NVL(t.HOU_LOAN, 0) = 0)
		) t0
	) t4
WHERE (t1.GG_YM = t2.GG_YM)
	AND (t2.GG_YM = t3.GG_YM)
	AND (t3.GG_YM = t4.GG_YM)
ORDER BY t1.GG_YM;


select * from RESULT_INDBIZLOAN_SUMMARY;




	
	



SELECT DISTINCT	-- 폐업 case
	t0.GG_YM,
	dense_Rank() over (partition by t0.GG_YM order by t0.CORP_NO) 
		+ dense_Rank() over (partition by t0.GG_YM order by t0.CORP_NO desc) - 1 as noOwner_Breakdwon,
	dense_Rank() over (partition by t0.GG_YM order by t0.BRNO) 
		+ dense_Rank() over (partition by t0.GG_YM order by t0.BRNO desc) - 1 as noBIZ_Breakdwon,
	ROUND(SUM(NVL(t0.BRNO_AMT, 0)) OVER(PARTITION BY t0.GG_YM), 0),
	ROUND(SUM(NVL(t0.HOU_LOAN, 0) / 1000) OVER(PARTITION BY t0.GG_YM), 0),
	ROUND(SUM(NVL(t0.BRNO_AMT, 0) + NVL(t0.HOU_LOAN, 0) / 1000) OVER(PARTITION BY t0.GG_YM), 0) as AMT_Breakdwon
FROM
	(
	SELECT 
		t.GG_YM,
		t.CORP_NO,
		t.BRNO,
		t.BRNO_AMT,
		t.HOU_LOAN
	FROM
		BASIC_IND_BIZ_LOAN t
	WHERE 
		NVL(t.BR_ACT, '') = '3'	-- 폐업
		and NVL(t.EFAS, '') <> '55'
	) t0;
	



-- 결과 조회
SELECT * FROM RESULT_INDBIZLOAN order by GG_YM;
SELECT * FROM RESULT_INDBIZLOAN_EFAS order by GG_YM;
SELECT * FROM RESULT_INDBIZLOAN_UPREOK order by GG_YM;
SELECT * FROM RESULT_INDBIZLOAN_LOCATION order by GG_YM;
SELECT * FROM RESULT_INDBIZLOAN_SUMMARY;