/***************************************************************************
 *                 신산업금융 (기업금융보고서)                            
 * 기업대출 테이블(BASIC_BIZ_LOAN) 등을 활용하여 "신산업 금융권 익소포저", "신산업별 경영실적", "신산업별 연체율" 등 통계 작성
 ***************************************************************************/

		
/***********************************
 * 신산업별 금융권 익스포저
 * 활용 테이블 : BASIC_newBIZ_LOAN
 * 사용자 입력 : 조회기준년월(inputGG_YM)
 ***********************************/
SELECT DISTINCT
	t.GG_YM,
	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM) as newINDU_AMT
FROM  BASIC_newBIZ_LOAN t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM};





/******************************************************
 * 신산업 세부현황 - 업종별 대출 잔액([표])
 * 특수은행 : 01
 * 일반은행 : 03, 05, 07
 * 보험 : 11, 13, 15
 * 금투 : 21, 61, 71, 76
 * 여전 : 31, 33, 35, 37
 * 상호금융 : 44, 74, 79, 81, 85, 87, 89
 * 저축은행 : 41
 * 기타 : 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
 *******************************************************/
SELECT DISTINCT 
	t00.GG_YM,
	t00.newINDU,
	t00.newINDU_NM,
  	-- 일반은행 대출현황
  	SUM(CASE WHEN t00.UPKWON = '일반은행' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as GBANK, 
  	-- 특수은행 대출현황
  	SUM(CASE WHEN t00.UPKWON = '특수은행' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as SBANK, 
  	-- 보험 대출현황
  	SUM(CASE WHEN t00.UPKWON = '보험' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as BOHUM, 
  	-- 금투 대출현황
  	SUM(CASE WHEN t00.UPKWON = '금투' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as KEUMTOO, 
  	-- 여전 대출현황
  	SUM(CASE WHEN t00.UPKWON = '여전' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as YEOJUN, 
  	-- 상호금융 대출현황
  	SUM(CASE WHEN t00.UPKWON = '상호금융' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as SANGHO, 
  	-- 저축은행 대출현황
  	SUM(CASE WHEN t00.UPKWON = '저축은행' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as JUCHOOK, 
  	-- 기타 대출현황
  	SUM(CASE WHEN t00.UPKWON = '기타' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as ETC,
  	t00.newINDU_TOT_AMT,
  	t00.newINDU_CNT
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
      	) t0 
  	) t00
ORDER BY 
	t00.GG_YM, t00.newINDU;