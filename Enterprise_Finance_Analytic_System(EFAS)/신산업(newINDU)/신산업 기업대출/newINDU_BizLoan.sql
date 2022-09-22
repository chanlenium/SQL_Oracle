/***************************************************************************
 *                 신산업금융 (기업금융보고서)                            
 * 기업대출 테이블(BASIC_BIZ_LOAN) 등을 활용하여 "신산업 금융권 익소포저", "신산업별 경영실적", "신산업별 연체율" 등 통계 작성
 ***************************************************************************/

		
/***********************************
 * 신산업별 금융권 익스포저
 * RFP p.17 [그림1] 신산업별 금융권 익스포저
 * 활용 테이블 : BASIC_newBIZ_LOAN
 * 사용자 입력 : 조회기준년월(inputGG_YM)
 ***********************************/
DROP TABLE IF EXISTS RESULT_newINDU_BIZLoan;
SELECT DISTINCT
	t00.GG_YM,
	ROUND(t00.TOT_newINDU_AMT, 0) as TOT_newINDU_AMT,
	ROUND(SUM(t00.newINDU_AMT_1) OVER(PARTITION BY t00.GG_YM), 0) as '1 자율주행차',
	ROUND(SUM(t00.newINDU_AMT_2) OVER(PARTITION BY t00.GG_YM), 0) as '2 IOT가전',
	ROUND(SUM(t00.newINDU_AMT_3) OVER(PARTITION BY t00.GG_YM), 0) as '3 스마트 헬스케어',
	ROUND(SUM(t00.newINDU_AMT_4) OVER(PARTITION BY t00.GG_YM), 0) as '4 바이오신약',
	ROUND(SUM(t00.newINDU_AMT_5) OVER(PARTITION BY t00.GG_YM), 0) as '5 차세대반도체',
	ROUND(SUM(t00.newINDU_AMT_6) OVER(PARTITION BY t00.GG_YM), 0) as '6 차세대디스플레이',
	ROUND(SUM(t00.newINDU_AMT_7) OVER(PARTITION BY t00.GG_YM), 0) as '7 신재생에너지',
	ROUND(SUM(t00.newINDU_AMT_8) OVER(PARTITION BY t00.GG_YM), 0) as '8 ESS',
	ROUND(SUM(t00.newINDU_AMT_9) OVER(PARTITION BY t00.GG_YM), 0) as '9 스마트그리드',
	ROUND(SUM(t00.newINDU_AMT_10) OVER(PARTITION BY t00.GG_YM), 0) as '10 전기차'
	INTO RESULT_newINDU_BIZLoan
FROM
	(
	SELECT 
		t0.*,
		DECODE(t0.newINDU_NM, '자율주행차', t0.newINDU_AMT, 0) as newINDU_AMT_1,
		DECODE(t0.newINDU_NM, 'IOT 가전', t0.newINDU_AMT, 0) as newINDU_AMT_2,
		DECODE(t0.newINDU_NM, '스마트 헬스케어', t0.newINDU_AMT, 0) as newINDU_AMT_3,
		DECODE(t0.newINDU_NM, '바이오신약', t0.newINDU_AMT, 0) as newINDU_AMT_4,
		DECODE(t0.newINDU_NM, '차세대반도체', t0.newINDU_AMT, 0) as newINDU_AMT_5,
		DECODE(t0.newINDU_NM, '차세대디스플레이', t0.newINDU_AMT, 0) as newINDU_AMT_6,
		DECODE(t0.newINDU_NM, '신재생에너지', t0.newINDU_AMT, 0) as newINDU_AMT_7,
		DECODE(t0.newINDU_NM, 'ESS', t0.newINDU_AMT, 0) as newINDU_AMT_8,
		DECODE(t0.newINDU_NM, '스마트그리드', t0.newINDU_AMT, 0) as newINDU_AMT_9,
		DECODE(t0.newINDU_NM, '전기차', t0.newINDU_AMT, 0) as newINDU_AMT_10
	FROM 	
		(
		SELECT DISTINCT
			t.GG_YM,
			t.newINDU,
			t.newINDU_NM,
			SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.newINDU) as newINDU_AMT,
			SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM) as TOT_newINDU_AMT
		FROM  BASIC_newBIZ_LOAN t
		WHERE
			CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
			AND NVL(t.EFAS, '') <> '55'	-- 금융보험업 제외
		) t0
	) t00;	



	

/******************************************************
 * 신산업 세부현황 - 업종별 대출 잔액([표])
 * RFP p.17 [표] 업종별 대출 잔액
 * 특수은행 : 01
 * 일반은행 : 03, 05, 07
 * 보험 : 11, 13, 15
 * 금투 : 21, 61, 71, 76
 * 여전 : 31, 33, 35, 37
 * 상호금융 : 44, 74, 79, 81, 85, 87, 89
 * 저축은행 : 41
 * 기타 : 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
 *******************************************************/
DROP TABLE IF EXISTS RESULT_newINDU_BIZLoan_Table;
SELECT
	t00.GG_YM,
	TO_NUMBER(t00.newINDU, '99') as "newINDU",
	t00.newINDU_NM,
  	-- 일반은행 대출현황
  	ROUND(SUM(CASE WHEN t00.UPKWON = '일반은행' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as GBANK, 
  	-- 특수은행 대출현황
  	ROUND(SUM(CASE WHEN t00.UPKWON = '특수은행' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as SBANK, 
  	-- 보험 대출현황
  	ROUND(SUM(CASE WHEN t00.UPKWON = '보험' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as BOHUM, 
  	-- 금투 대출현황
  	ROUND(SUM(CASE WHEN t00.UPKWON = '금투' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as KEUMTOO, 
  	-- 여전 대출현황
  	ROUND(SUM(CASE WHEN t00.UPKWON = '여전' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as YEOJUN, 
  	-- 상호금융 대출현황
  	ROUND(SUM(CASE WHEN t00.UPKWON = '상호금융' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as SANGHO, 
  	-- 저축은행 대출현황
  	ROUND(SUM(CASE WHEN t00.UPKWON = '저축은행' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as JUCHOOK, 
  	-- 기타 대출현황
  	ROUND(SUM(CASE WHEN t00.UPKWON = '기타' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as ETC,
  	t00.newINDU_TOT_AMT,
  	t00.newINDU_CNT
  	INTO RESULT_newINDU_BIZLoan_Table
FROM
  	(
    SELECT DISTINCT 
    	t0.GG_YM, 
      	t0.newINDU, 
      	t0.newINDU_NM,
      	t0.UPKWON, 
      	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.newINDU, t0.GG_YM, t0.UPKWON) as newINDU_AMT, -- 월별, 업권별, 신산업별 대출합
      	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.GG_YM, t0.newINDU) as newINDU_TOT_AMT,	-- 신산업별 총 대출 잔액
      	COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.newINDU) as newINDU_CNT	-- 신산업별 차주 수
    FROM 
      	(
        SELECT 
        	t.GG_YM, 
          	t.BRNO, 
          	t.SOI_CD, 
          	CASE 
          		WHEN t.SOI_CD in ('01') THEN '특수은행' 
          		WHEN t.SOI_CD in ('03', '05', '07') THEN '일반은행' 
          		WHEN t.SOI_CD in ('11', '13', '15') THEN '보험' 
          		WHEN t.SOI_CD in ('21', '61', '71', '76') THEN '금투' 
          		WHEN t.SOI_CD in ('31', '33', '35', '37') THEN '여전' 
          		WHEN t.SOI_CD in ('44', '74', '79', '81', '85', '87', '89') THEN '상호금융' 
          		WHEN t.SOI_CD in ('41') THEN '저축은행' 
          		ELSE '기타' 
          	END as UPKWON,	-- 세부 업권 구분
          	t.BRNO_AMT, 
          	t.newINDU,
          	t.newINDU_NM
        FROM 
          	BASIC_newBIZ_LOAN t 
        WHERE
			CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
			AND NVL(t.EFAS, '') <> '55'
      	) t0 
  	) t00;
	

-- 결과 조회
SELECT * FROM RESULT_newINDU_BIZLoan ORDER BY GG_YM;
SELECT DISTINCT * FROM RESULT_newINDU_BIZLoan_Table ORDER BY GG_YM, newINDU;
