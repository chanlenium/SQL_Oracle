/******************************************************
 * 업권별 기업 대출잔액 추이 - 은행/비은행 기업 대출잔액 추이 (보고서 p.3, [그림1])
 * RFP p.13 [그림1] 은행/비은행 기업 대출잔액 추이
 * 은행 : 01, 03, 05, 07  
 * 비은행 : 11, 13, 15, 21, 61, 71, 76, 31, 33, 35, 37, 44, 74, 79, 81, 85, 87, 89, 41, 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
 ******************************************************/
DROP TABLE IF EXISTS RESULT_BIZLoanTrend_UPKWON_SOI;
SELECT DISTINCT
	t00.GG_YM, 
	ROUND(SUM(t00.BRNO_AMT_BANK) OVER(PARTITION BY t00.GG_YM), 0) as BANK_LOAN,
	ROUND(SUM(t00.BRNO_AMT_nonBANK) OVER(PARTITION BY t00.GG_YM), 0) as nonBANK_LOAN,
	ROUND(SUM(t00.BRNO_AMT_BANK) OVER(PARTITION BY t00.GG_YM) + SUM(t00.BRNO_AMT_nonBANK) OVER(PARTITION BY t00.GG_YM), 0) as TOT_LOAN
	INTO RESULT_BIZLoanTrend_UPKWON_SOI
FROM
	(
	SELECT 
		t0.*,
		DECODE(t0.isBANK, '은행', t0.BRNO_AMT, 0) BRNO_AMT_BANK,
		DECODE(t0.isBANK, '비은행', t0.BRNO_AMT, 0) BRNO_AMT_nonBANK
	FROM
	  	(
	    SELECT 
	    	t.BRWR_NO_TP_CD,
	    	t.GG_YM, 
	    	t.BRNO, 
	    	t.SOI_CD, 
	    	t.EFAS,
	      	CASE WHEN t.SOI_CD in ('01', '03', '05', '07') THEN '은행' ELSE '비은행' END as isBANK, -- 은행/비은행 구분
	      	t.BRNO_AMT 
	    FROM 
	      	BASIC_BIZ_LOAN t 
	    WHERE
	    	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
	    	AND NVL(t.EFAS, '') <> '55'	-- 금융보험업 제외
	  	) t0
	) t00
ORDER BY 
	t00.GG_YM;
 



/******************************************************
 * 업권별 기업 대출잔액 추이 - 은행별 대출잔액 추이 (보고서 p.3, [그림2])  
 * RFP p.13 [그림2] 은행업권별 대출잔액 추이      
 * 특수은행 : 01
 * 일반은행 : 03, 05, 07
 ******************************************************/
DROP TABLE IF EXISTS RESULT_BIZLoanTrend_UPKWON_BANK;
SELECT DISTINCT 
  	t00.GG_YM, 
  	ROUND(SUM(t00.sBANK_BRNO_AMT) OVER(PARTITION BY t00.GG_YM), 2) as sBANK_LOAN, 
  	ROUND(SUM(t00.gBANK_BRNO_AMT) OVER(PARTITION BY t00.GG_YM), 2) as gBANK_LOAN,
  	ROUND(SUM(t00.sBANK_BRNO_AMT) OVER(PARTITION BY t00.GG_YM) + SUM(t00.gBANK_BRNO_AMT) OVER(PARTITION BY t00.GG_YM), 0) as TOT_BANK_LOAN
  	INTO RESULT_BIZLoanTrend_UPKWON_BANK
FROM 
	(
	SELECT 
		t0.*,
		DECODE(t0.BANK_TYPE, '특수은행', t0.BRNO_AMT, 0) as sBANK_BRNO_AMT,
		DECODE(t0.BANK_TYPE, '일반은행', t0.BRNO_AMT, 0) as gBANK_BRNO_AMT
	FROM
	  	(
	    SELECT 
	    	t.GG_YM, 
	      	t.BRWR_NO_TP_CD,
	      	t.BRNO, 
	      	t.SOI_CD, 
	      	t.EFAS,
	      	DECODE(t.SOI_CD, '01', '특수은행', '일반은행') AS BANK_TYPE, 
	      	t.BRNO_AMT
	    FROM 
	      	BASIC_BIZ_LOAN t 
	    WHERE 
	      	t.SOI_CD IN ('01', '03', '05', '07') 
	      	AND CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}	
			AND NVL(t.EFAS, '') <> '55'	-- 금융보험업 제외
	  	) t0 
	) t00
ORDER BY 
  	t00.GG_YM;
 
 
 
  
  
 /******************************************************
 * 업권별 기업 대출잔액 추이 - 비은행별(보험/금투/여전/상호금융/저축은행/기타) 대출잔액 추이 (보고서 p.3, [그림3])     
 * RFP p.13 [그림3] 비은행 업권별 대출잔액 추이         
 * 보험 : 11, 13, 15
 * 금투 : 21, 61, 71, 76
 * 여전 : 31, 33, 35, 37
 * 상호금융 : 44, 74, 79, 81, 85, 87, 89
 * 저축은행 : 41
 * 기타 : 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
 ******************************************************/
DROP TABLE IF EXISTS RESULT_BIZLoanTrend_UPKWON_nonBANK;
SELECT DISTINCT 
  	t00.GG_YM, 
  	ROUND(SUM(t00.BOHUM_BRNO_AMT) OVER(PARTITION BY t00.GG_YM), 0) as BOHUM_LOAN,
  	ROUND(SUM(t00.KEUMTOO_BRNO_AMT) OVER(PARTITION BY t00.GG_YM), 0) as KEUMTOO_LOAN,
  	ROUND(SUM(t00.YEOJUN_BRNO_AMT) OVER(PARTITION BY t00.GG_YM), 0) as YEOJUN_LOAN,
  	ROUND(SUM(t00.SANGHO_BRNO_AMT) OVER(PARTITION BY t00.GG_YM), 0) as SANGHO_LOAN,
  	ROUND(SUM(t00.JUCHOOK_BRNO_AMT) OVER(PARTITION BY t00.GG_YM), 0) as JUCHOOK_LOAN,
  	ROUND(SUM(t00.ETC_BRNO_AMT) OVER(PARTITION BY t00.GG_YM), 0) as ETC_LOAN,
  	ROUND(SUM(t00.BOHUM_BRNO_AMT) OVER(PARTITION BY t00.GG_YM) + SUM(t00.KEUMTOO_BRNO_AMT) OVER(PARTITION BY t00.GG_YM)
  		+ SUM(t00.YEOJUN_BRNO_AMT) OVER(PARTITION BY t00.GG_YM) + SUM(t00.SANGHO_BRNO_AMT) OVER(PARTITION BY t00.GG_YM)
  		+ SUM(t00.JUCHOOK_BRNO_AMT) OVER(PARTITION BY t00.GG_YM) + SUM(t00.ETC_BRNO_AMT) OVER(PARTITION BY t00.GG_YM), 0) as TOT_LOAN
  	INTO RESULT_BIZLoanTrend_UPKWON_nonBANK
FROM 
	(
	SELECT
		t0.*,
		DECODE(t0.nonBANK_TYPE, '보험', t0.BRNO_AMT) as BOHUM_BRNO_AMT,
		DECODE(t0.nonBANK_TYPE, '금투', t0.BRNO_AMT) as KEUMTOO_BRNO_AMT,
		DECODE(t0.nonBANK_TYPE, '여전', t0.BRNO_AMT) as YEOJUN_BRNO_AMT,
		DECODE(t0.nonBANK_TYPE, '상호금융', t0.BRNO_AMT) as SANGHO_BRNO_AMT,
		DECODE(t0.nonBANK_TYPE, '저축은행', t0.BRNO_AMT) as JUCHOOK_BRNO_AMT,
		DECODE(t0.nonBANK_TYPE, '기타', t0.BRNO_AMT) as ETC_BRNO_AMT
	FROM
	  	(
	    SELECT 
	      	t.GG_YM, 
	      	t.BRNO, 
	      	t.SOI_CD, 
	      	t.EFAS,
	      	CASE 
	      		WHEN t.SOI_CD IN ('11', '13', '15') THEN '보험' 
	      		WHEN t.SOI_CD IN ('21', '61', '71', '76') THEN '금투' 
	      		WHEN t.SOI_CD IN ('31', '33', '35', '37') THEN '여전' 
	      		WHEN t.SOI_CD IN ('44', '74', '79', '81', '85', '87', '89') THEN '상호금융' 
	      		WHEN t.SOI_CD IN ('41') THEN '저축은행' 
	      		ELSE '기타' 
	      	END as nonBANK_TYPE, 
	      	t.BRNO_AMT
	    FROM 
	      	BASIC_BIZ_LOAN t 
	    WHERE 
	      	t.SOI_CD IN (
	        	'11', '13', '15', '21', '61', '71', '76', 
	        	'31', '33', '35', '37', '44', '74', 
	        	'79', '81', '85', '87', '89', '41', 
	        	'43', '46', '47', '75', '77', '83', 
	        	'91', '94', '95', '97'
	      	) 
	      	AND CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
			AND NVL(t.EFAS, '') <> '55'	-- 금융보험업 제외
	  	) t0 
	) t00
ORDER BY 
	t00.GG_YM;





/******************************************************
 * 은행/비은행 업종별 기업대출 현황 테이블 (보고서 p.3, [표])
 * RFP p.13 [표] 은행/비은행 : 업종별 기업 대출 현황
 * 은행 : 01, 03, 05, 07  
 * 비은행 : 11, 13, 15, 21, 61, 71, 76, 31, 33, 35, 37, 44, 74, 79, 81, 85, 87, 89, 41, 43, 46, 47, 75, 77, 83, 91, 94, 95, 97 
 * 
 * 특수은행 : 01
 * 일반은행 : 03, 05, 07
 * 보험 : 11, 13, 15
 * 금투 : 21, 61, 71, 76
 * 여전 : 31, 33, 35, 37
 * 상호금융 : 44, 74, 79, 81, 85, 87, 89
 * 저축은행 : 41
 * 기타 : 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
 *******************************************************/
-- 업종별 기업 여신 대출잔액/증가율 Table 생성 (EFAS코드, 총 대출, 일반은행, 특수은행, 보험, 금투, 여전, 상호금융, 저축은행, 기타)
DROP TABLE IF EXISTS RESULT_BIZLoanTrend_UPKWON_SOI_TABLE;
SELECT 
  	t0000.EFAS, 
  	-- 총 대출 잔액
  	ROUND(t0000.TOT_prevY, 0) as TOT_prevY,
  	ROUND(t0000.TOT_thisY, 0) as TOT_thisY,  
  	round(COALESCE(t0000.TOT_thisY / NULLIF(t0000.TOT_prevY, 0), 1) - 1, 2) as TOT_Grate,	-- TOT_prevY가 0이면 0%값을 리턴
  	-- 일반은행
  	ROUND(t0000.GBANK_prevY, 0) as GBANK_prevY, 
  	ROUND(t0000.GBANK_thisY, 0) as GBANK_thisY, 
  	round(COALESCE(t0000.GBANK_thisY / NULLIF(t0000.GBANK_prevY, 0), 1) - 1, 2) as GBANK_Grate, 
  	-- 특수은행
  	ROUND(t0000.SBANK_prevY, 0) as SBANK_prevY,
  	ROUND(t0000.SBANK_thisY, 0) as SBANK_thisY,  
  	round(COALESCE(t0000.SBANK_thisY / NULLIF(t0000.SBANK_prevY, 0), 1) - 1, 2) as SBANK_Grate, 
  	-- 보험
  	ROUND(t0000.BOHUM_prevY, 0) as BOHUM_prevY,
  	ROUND(t0000.BOHUM_thisY, 0) as BOHUM_thisY,  
  	round(COALESCE(t0000.BOHUM_thisY / NULLIF(t0000.BOHUM_prevY, 0), 1) - 1, 2) as BOHUM_Grate, 
  	-- 금투
  	ROUND(t0000.KEUMTOO_prevY, 0) as KEUMTOO_prevY,
  	ROUND(t0000.KEUMTOO_thisY, 0) as KEUMTOO_thisY,  
  	round(COALESCE(t0000.KEUMTOO_thisY / NULLIF(t0000.KEUMTOO_prevY, 0), 1) - 1, 2) as KEUMTOO_Grate, 
  	-- 여전
  	ROUND(t0000.YEOJUN_prevY, 0) as YEOJUN_prevY,
  	ROUND(t0000.YEOJUN_thisY, 0) as YEOJUN_thisY, 
  	round(COALESCE(t0000.YEOJUN_thisY / NULLIF(t0000.YEOJUN_prevY, 0), 1) - 1, 2) as YEOJUN_Grate, 
  	-- 상호금융
  	ROUND(t0000.SANGHO_prevY, 0) as SANGHO_prevY, 
  	ROUND(t0000.SANGHO_thisY, 0) as SANGHO_thisY, 
  	round(COALESCE(t0000.SANGHO_thisY / NULLIF(t0000.SANGHO_prevY, 0), 1) - 1, 2) as SANGHO_Grate, 
  	-- 저축은행
  	ROUND(t0000.JUCHOOK_prevY, 0) as JUCHOOK_prevY, 
  	ROUND(t0000.JUCHOOK_thisY, 0) as JUCHOOK_thisY, 
  	round(COALESCE(t0000.JUCHOOK_thisY / NULLIF(t0000.JUCHOOK_prevY, 0), 1) - 1, 2) as JUCHOOK_Grate, 
  	-- 기타
  	ROUND(t0000.ETC_prevY, 0) as ETC_prevY,
  	ROUND(t0000.ETC_thisY, 0) as ETC_thisY,  
 	round(COALESCE(t0000.ETC_thisY / NULLIF(t0000.ETC_prevY, 0), 1) - 1, 2) as ETC_Grate  
 	INTO RESULT_BIZLoanTrend_UPKWON_SOI_TABLE
FROM 
  	(
    SELECT 
      	t000.*, 
      	-- 총 대출 잔액(현월, 전년동월)
      	t000.GBANK_thisY + t000.SBANK_thisY + t000.BOHUM_thisY + t000.KEUMTOO_thisY + t000.YEOJUN_thisY + t000.SANGHO_thisY + t000.JUCHOOK_thisY + t000.ETC_thisY as TOT_thisY, 
      	t000.GBANK_prevY + t000.SBANK_prevY + t000.BOHUM_prevY + t000.KEUMTOO_prevY + t000.YEOJUN_prevY + t000.SANGHO_prevY + t000.JUCHOOK_prevY + t000.ETC_prevY as TOT_prevY 
    FROM 
      	(
        SELECT DISTINCT 
        	t00.EFAS, 
          	-- 일반은행 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '일반은행' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as GBANK_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '일반은행' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as GBANK_prevY, 
          	-- 특수은행 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '특수은행' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as SBANK_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '특수은행' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as SBANK_prevY, 
          	-- 보험 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '보험' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as BOHUM_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '보험' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as BOHUM_prevY, 
          	-- 금투 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '금투' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as KEUMTOO_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '금투' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as KEUMTOO_prevY, 
          	-- 여전 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '여전' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as YEOJUN_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '여전' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as YEOJUN_prevY, 
          	-- 상호금융 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '상호금융' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as SANGHO_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '상호금융' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as SANGHO_prevY, 
          	-- 저축은행 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '저축은행' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as JUCHOOK_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '저축은행' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as JUCHOOK_prevY, 
          	-- 기타 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '기타' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as ETC_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '기타' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as ETC_prevY 
        FROM
          	(
            SELECT DISTINCT 
            	t0.GG_YM, 
              	t0.EFAS, 
              	t0.UPKWON, 
              	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.EFAS, t0.GG_YM, t0.UPKWON) as EFAS_AMT -- 월별, 업권별, 산업별 대출합
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
                  	DECODE(t.EFAS, NULL, '99', DECODE(t.EFAS, '', '99', t.EFAS)) as EFAS
                FROM 
                  	BASIC_BIZ_LOAN t 
                WHERE 
                  CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}, ${inputGG_YM} - 100) 
              	) t0 
          	) t00
      	) t000
  	) t0000 
ORDER BY 
	To_number(t0000.EFAS, '99');
 

 
 
 
 /******************************************************
 * 업권별 기업 대출잔액 추이 - 금융위가 정한 새 업권 SOI_CD2 기준 대출잔액 추이 (p.3, [그림4] 추가)   
 * RFP p.13 [그림1]관련 추가 내용     
 * 정책금융기관 : 0
 * 제1금융권 : 1
 * 제2금융권 : 2
 * 대부업 등 : 3
 ******************************************************/ 
DROP TABLE IF EXISTS RESULT_BIZLoanTrend_UPKWON_SOI2;
SELECT DISTINCT
	t00.GG_YM, 
	ROUND(SUM(t00.BRNO_AMT_0) OVER(PARTITION BY t00.GG_YM), 0) as LOAN_0,
	ROUND(SUM(t00.BRNO_AMT_1) OVER(PARTITION BY t00.GG_YM), 0) as LOAN_1,
	ROUND(SUM(t00.BRNO_AMT_2) OVER(PARTITION BY t00.GG_YM), 0) as LOAN_2,
	ROUND(SUM(t00.BRNO_AMT_3) OVER(PARTITION BY t00.GG_YM), 0) as LOAN_3,	
	ROUND(SUM(t00.BRNO_AMT_0) OVER(PARTITION BY t00.GG_YM) + SUM(t00.BRNO_AMT_1) OVER(PARTITION BY t00.GG_YM)
		+ SUM(t00.BRNO_AMT_2) OVER(PARTITION BY t00.GG_YM) + SUM(t00.BRNO_AMT_3) OVER(PARTITION BY t00.GG_YM), 0) as TOT_LOAN
	INTO RESULT_BIZLoanTrend_UPKWON_SOI2
FROM 
	(
	SELECT 
		t0.*,
		DECODE(t0.newUPKWON_TYPE, '정책금융기관', t0.BRNO_AMT, 0) BRNO_AMT_0,
		DECODE(t0.newUPKWON_TYPE, '제1금융권', t0.BRNO_AMT, 0) BRNO_AMT_1,
		DECODE(t0.newUPKWON_TYPE, '제2금융권', t0.BRNO_AMT, 0) BRNO_AMT_2,
		DECODE(t0.newUPKWON_TYPE, '대부업 등', t0.BRNO_AMT, 0) BRNO_AMT_3
	FROM
	  	(
	    SELECT 
	    	t.BRWR_NO_TP_CD,
	    	t.GG_YM, 
	    	t.BRNO, 
	    	t.SOI_CD2, 
	    	t.EFAS,
	      	CASE 
	      		WHEN t.SOI_CD2 = 0 THEN '정책금융기관'
	      		WHEN t.SOI_CD2 = 1 THEN '제1금융권'
	      		WHEN t.SOI_CD2 = 2 THEN '제2금융권'
	      		ELSE '대부업 등' 
	      	END as newUPKWON_TYPE, -- 업권 구분
	      	t.BRNO_AMT 
	    FROM 
	      	BASIC_BIZ_LOAN t
	    WHERE
	    	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
			AND NVL(t.EFAS, '') <> '55'	-- 금융보험업 제외
	  	) t0
	) t00
ORDER BY 
	t00.GG_YM;





/******************************************************
 * 新업권별(SOI_CD2) 업종별 기업대출 현황 테이블 (p.3, [표] 추가)
 * RFP p.13 [표] 업종별 기업 대출 현황 관련 추가 내용 
 * 정책금융기관 : 0
 * 제1금융권 : 1
 * 제2금융권 : 2
 * 대부업 등 : 3
 *******************************************************/
-- 업종별 기업 여신 대출잔액/증가율 Table 생성 (EFAS코드, 총 대출, 정책금융기관, 제1금융권, 제2금융권, 대부업 등)
DROP TABLE IF EXISTS RESULT_BIZLoanTrend_UPKWON_SOI2_TABLE;
SELECT 
  	t0000.EFAS, 
  	-- 총 대출 잔액
  	ROUND(t0000.TOT_prevY, 0) as TOT_prevY, 
  	ROUND(t0000.TOT_thisY, 0) as TOT_thisY, 
  	round(COALESCE(t0000.TOT_thisY / NULLIF(t0000.TOT_prevY, 0), 1) - 1, 2) as TOT_Grate,	-- TOT_prevY가 0이면 0%값을 리턴
  	-- 정책금융기관 대출 잔액
  	ROUND(t0000.POLFIN_prevY, 0) as POLFIN_prevY,
  	ROUND(t0000.POLFIN_thisY, 0) as POLFIN_thisY,  
  	round(COALESCE(t0000.POLFIN_thisY / NULLIF(t0000.POLFIN_prevY, 0), 1) - 1, 2) as POLFIN_Grate, 
  	-- 제1금융권 대출 잔액
  	ROUND(t0000.FIN1_prevY, 0) as FIN1_prevY,
  	ROUND(t0000.FIN1_thisY, 0) as FIN1_thisY,
  	round(COALESCE(t0000.FIN1_thisY / NULLIF(t0000.FIN1_prevY, 0), 1) - 1, 2) as FIN1_Grate, 
  	-- 제2금융권 대출 잔액
  	ROUND(t0000.FIN2_prevY, 0) as FIN2_prevY,
  	ROUND(t0000.FIN2_thisY, 0) as FIN2_thisY,  
  	round(COALESCE(t0000.FIN2_thisY / NULLIF(t0000.FIN2_prevY, 0), 1) - 1, 2) as FIN2_Grate, 
  	-- 대부업 등 대출잔액
  	ROUND(t0000.DAEBOO_prevY, 0) as DAEBOO_prevY,
  	ROUND(t0000.DAEBOO_thisY, 0) as DAEBOO_thisY,  
  	round(COALESCE(t0000.DAEBOO_thisY / NULLIF(t0000.DAEBOO_prevY, 0), 1) - 1, 2) as DAEBOO_Grate 
	INTO RESULT_BIZLoanTrend_UPKWON_SOI2_TABLE
FROM 
  	(
    SELECT 
      	t000.*, 
      	-- 총 대출 잔액(현월, 전년동월)
      	t000.POLFIN_thisY + t000.FIN1_thisY + t000.FIN2_thisY + t000.DAEBOO_thisY as TOT_thisY, 
      	t000.POLFIN_prevY + t000.FIN1_prevY + t000.FIN2_prevY + t000.DAEBOO_prevY as TOT_prevY 
    FROM 
      	(
        SELECT DISTINCT 
        	t00.EFAS, 
          	-- 정책금융기관 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '정책금융기관' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as POLFIN_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '정책금융기관' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as POLFIN_prevY, 
          	-- 제1금융권 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '제1금융권' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as FIN1_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '제1금융권' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as FIN1_prevY, 
          	-- 제2금융권 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '제2금융권' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as FIN2_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '제2금융권' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as FIN2_prevY, 
          	-- 대부업 등 대출현황(현월, 전년동월)
          	SUM(CASE WHEN t00.UPKWON = '대부업 등' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as DAEBOO_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '대부업 등' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as DAEBOO_prevY
        FROM
          	(
            SELECT DISTINCT 
            	t0.GG_YM, 
              	t0.EFAS, 
              	t0.UPKWON, 
              	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.EFAS, t0.GG_YM, t0.UPKWON) as EFAS_AMT -- 월별, 업권별, 산업별 대출합
            FROM 
              	(
                SELECT 
                	t.GG_YM, 
                  	t.BRNO, 
                  	t.SOI_CD2, 
                  	CASE 
                  		WHEN t.SOI_CD2 = 0 THEN '정책금융기관' 
                  		WHEN t.SOI_CD2 = 1 THEN '제1금융권' 
                  		WHEN t.SOI_CD2 = 2 THEN '제2금융권'  
                  		ELSE '대부업 등'
                  	END as UPKWON,	-- 세부 업권 구분
                  	t.BRNO_AMT, 
                  	DECODE(t.EFAS, NULL, '99', DECODE(t.EFAS, '', '99', t.EFAS)) as EFAS 
                FROM 
                  	BASIC_BIZ_LOAN t 
                WHERE 
                	CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}, ${inputGG_YM} - 100) 
              	) t0 
          	) t00
      	) t000
  	) t0000 
ORDER BY 
To_number(t0000.EFAS, '99');




-- 결과 조회
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_SOI;
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_BANK;
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_nonBANK;
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_SOI_TABLE;
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_SOI2;
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_SOI2_TABLE;