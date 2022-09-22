/******************************************************
 * ���Ǻ� ��� �����ܾ� ���� - ����/������ ��� �����ܾ� ���� (���� p.3, [�׸�1])
 * RFP p.13 [�׸�1] ����/������ ��� �����ܾ� ����
 * ���� : 01, 03, 05, 07  
 * ������ : 11, 13, 15, 21, 61, 71, 76, 31, 33, 35, 37, 44, 74, 79, 81, 85, 87, 89, 41, 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
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
		DECODE(t0.isBANK, '����', t0.BRNO_AMT, 0) BRNO_AMT_BANK,
		DECODE(t0.isBANK, '������', t0.BRNO_AMT, 0) BRNO_AMT_nonBANK
	FROM
	  	(
	    SELECT 
	    	t.BRWR_NO_TP_CD,
	    	t.GG_YM, 
	    	t.BRNO, 
	    	t.SOI_CD, 
	    	t.EFAS,
	      	CASE WHEN t.SOI_CD in ('01', '03', '05', '07') THEN '����' ELSE '������' END as isBANK, -- ����/������ ����
	      	t.BRNO_AMT 
	    FROM 
	      	BASIC_BIZ_LOAN t 
	    WHERE
	    	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
	    	AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
	  	) t0
	) t00
ORDER BY 
	t00.GG_YM;
 



/******************************************************
 * ���Ǻ� ��� �����ܾ� ���� - ���ະ �����ܾ� ���� (���� p.3, [�׸�2])  
 * RFP p.13 [�׸�2] ������Ǻ� �����ܾ� ����      
 * Ư������ : 01
 * �Ϲ����� : 03, 05, 07
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
		DECODE(t0.BANK_TYPE, 'Ư������', t0.BRNO_AMT, 0) as sBANK_BRNO_AMT,
		DECODE(t0.BANK_TYPE, '�Ϲ�����', t0.BRNO_AMT, 0) as gBANK_BRNO_AMT
	FROM
	  	(
	    SELECT 
	    	t.GG_YM, 
	      	t.BRWR_NO_TP_CD,
	      	t.BRNO, 
	      	t.SOI_CD, 
	      	t.EFAS,
	      	DECODE(t.SOI_CD, '01', 'Ư������', '�Ϲ�����') AS BANK_TYPE, 
	      	t.BRNO_AMT
	    FROM 
	      	BASIC_BIZ_LOAN t 
	    WHERE 
	      	t.SOI_CD IN ('01', '03', '05', '07') 
	      	AND CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}	
			AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
	  	) t0 
	) t00
ORDER BY 
  	t00.GG_YM;
 
 
 
  
  
 /******************************************************
 * ���Ǻ� ��� �����ܾ� ���� - �����ະ(����/����/����/��ȣ����/��������/��Ÿ) �����ܾ� ���� (���� p.3, [�׸�3])     
 * RFP p.13 [�׸�3] ������ ���Ǻ� �����ܾ� ����         
 * ���� : 11, 13, 15
 * ���� : 21, 61, 71, 76
 * ���� : 31, 33, 35, 37
 * ��ȣ���� : 44, 74, 79, 81, 85, 87, 89
 * �������� : 41
 * ��Ÿ : 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
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
		DECODE(t0.nonBANK_TYPE, '����', t0.BRNO_AMT) as BOHUM_BRNO_AMT,
		DECODE(t0.nonBANK_TYPE, '����', t0.BRNO_AMT) as KEUMTOO_BRNO_AMT,
		DECODE(t0.nonBANK_TYPE, '����', t0.BRNO_AMT) as YEOJUN_BRNO_AMT,
		DECODE(t0.nonBANK_TYPE, '��ȣ����', t0.BRNO_AMT) as SANGHO_BRNO_AMT,
		DECODE(t0.nonBANK_TYPE, '��������', t0.BRNO_AMT) as JUCHOOK_BRNO_AMT,
		DECODE(t0.nonBANK_TYPE, '��Ÿ', t0.BRNO_AMT) as ETC_BRNO_AMT
	FROM
	  	(
	    SELECT 
	      	t.GG_YM, 
	      	t.BRNO, 
	      	t.SOI_CD, 
	      	t.EFAS,
	      	CASE 
	      		WHEN t.SOI_CD IN ('11', '13', '15') THEN '����' 
	      		WHEN t.SOI_CD IN ('21', '61', '71', '76') THEN '����' 
	      		WHEN t.SOI_CD IN ('31', '33', '35', '37') THEN '����' 
	      		WHEN t.SOI_CD IN ('44', '74', '79', '81', '85', '87', '89') THEN '��ȣ����' 
	      		WHEN t.SOI_CD IN ('41') THEN '��������' 
	      		ELSE '��Ÿ' 
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
			AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
	  	) t0 
	) t00
ORDER BY 
	t00.GG_YM;





/******************************************************
 * ����/������ ������ ������� ��Ȳ ���̺� (���� p.3, [ǥ])
 * RFP p.13 [ǥ] ����/������ : ������ ��� ���� ��Ȳ
 * ���� : 01, 03, 05, 07  
 * ������ : 11, 13, 15, 21, 61, 71, 76, 31, 33, 35, 37, 44, 74, 79, 81, 85, 87, 89, 41, 43, 46, 47, 75, 77, 83, 91, 94, 95, 97 
 * 
 * Ư������ : 01
 * �Ϲ����� : 03, 05, 07
 * ���� : 11, 13, 15
 * ���� : 21, 61, 71, 76
 * ���� : 31, 33, 35, 37
 * ��ȣ���� : 44, 74, 79, 81, 85, 87, 89
 * �������� : 41
 * ��Ÿ : 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
 *******************************************************/
-- ������ ��� ���� �����ܾ�/������ Table ���� (EFAS�ڵ�, �� ����, �Ϲ�����, Ư������, ����, ����, ����, ��ȣ����, ��������, ��Ÿ)
DROP TABLE IF EXISTS RESULT_BIZLoanTrend_UPKWON_SOI_TABLE;
SELECT 
  	t0000.EFAS, 
  	-- �� ���� �ܾ�
  	ROUND(t0000.TOT_prevY, 0) as TOT_prevY,
  	ROUND(t0000.TOT_thisY, 0) as TOT_thisY,  
  	round(COALESCE(t0000.TOT_thisY / NULLIF(t0000.TOT_prevY, 0), 1) - 1, 2) as TOT_Grate,	-- TOT_prevY�� 0�̸� 0%���� ����
  	-- �Ϲ�����
  	ROUND(t0000.GBANK_prevY, 0) as GBANK_prevY, 
  	ROUND(t0000.GBANK_thisY, 0) as GBANK_thisY, 
  	round(COALESCE(t0000.GBANK_thisY / NULLIF(t0000.GBANK_prevY, 0), 1) - 1, 2) as GBANK_Grate, 
  	-- Ư������
  	ROUND(t0000.SBANK_prevY, 0) as SBANK_prevY,
  	ROUND(t0000.SBANK_thisY, 0) as SBANK_thisY,  
  	round(COALESCE(t0000.SBANK_thisY / NULLIF(t0000.SBANK_prevY, 0), 1) - 1, 2) as SBANK_Grate, 
  	-- ����
  	ROUND(t0000.BOHUM_prevY, 0) as BOHUM_prevY,
  	ROUND(t0000.BOHUM_thisY, 0) as BOHUM_thisY,  
  	round(COALESCE(t0000.BOHUM_thisY / NULLIF(t0000.BOHUM_prevY, 0), 1) - 1, 2) as BOHUM_Grate, 
  	-- ����
  	ROUND(t0000.KEUMTOO_prevY, 0) as KEUMTOO_prevY,
  	ROUND(t0000.KEUMTOO_thisY, 0) as KEUMTOO_thisY,  
  	round(COALESCE(t0000.KEUMTOO_thisY / NULLIF(t0000.KEUMTOO_prevY, 0), 1) - 1, 2) as KEUMTOO_Grate, 
  	-- ����
  	ROUND(t0000.YEOJUN_prevY, 0) as YEOJUN_prevY,
  	ROUND(t0000.YEOJUN_thisY, 0) as YEOJUN_thisY, 
  	round(COALESCE(t0000.YEOJUN_thisY / NULLIF(t0000.YEOJUN_prevY, 0), 1) - 1, 2) as YEOJUN_Grate, 
  	-- ��ȣ����
  	ROUND(t0000.SANGHO_prevY, 0) as SANGHO_prevY, 
  	ROUND(t0000.SANGHO_thisY, 0) as SANGHO_thisY, 
  	round(COALESCE(t0000.SANGHO_thisY / NULLIF(t0000.SANGHO_prevY, 0), 1) - 1, 2) as SANGHO_Grate, 
  	-- ��������
  	ROUND(t0000.JUCHOOK_prevY, 0) as JUCHOOK_prevY, 
  	ROUND(t0000.JUCHOOK_thisY, 0) as JUCHOOK_thisY, 
  	round(COALESCE(t0000.JUCHOOK_thisY / NULLIF(t0000.JUCHOOK_prevY, 0), 1) - 1, 2) as JUCHOOK_Grate, 
  	-- ��Ÿ
  	ROUND(t0000.ETC_prevY, 0) as ETC_prevY,
  	ROUND(t0000.ETC_thisY, 0) as ETC_thisY,  
 	round(COALESCE(t0000.ETC_thisY / NULLIF(t0000.ETC_prevY, 0), 1) - 1, 2) as ETC_Grate  
 	INTO RESULT_BIZLoanTrend_UPKWON_SOI_TABLE
FROM 
  	(
    SELECT 
      	t000.*, 
      	-- �� ���� �ܾ�(����, ���⵿��)
      	t000.GBANK_thisY + t000.SBANK_thisY + t000.BOHUM_thisY + t000.KEUMTOO_thisY + t000.YEOJUN_thisY + t000.SANGHO_thisY + t000.JUCHOOK_thisY + t000.ETC_thisY as TOT_thisY, 
      	t000.GBANK_prevY + t000.SBANK_prevY + t000.BOHUM_prevY + t000.KEUMTOO_prevY + t000.YEOJUN_prevY + t000.SANGHO_prevY + t000.JUCHOOK_prevY + t000.ETC_prevY as TOT_prevY 
    FROM 
      	(
        SELECT DISTINCT 
        	t00.EFAS, 
          	-- �Ϲ����� ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = '�Ϲ�����' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as GBANK_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '�Ϲ�����' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as GBANK_prevY, 
          	-- Ư������ ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = 'Ư������' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as SBANK_thisY, 
          	SUM(CASE WHEN t00.UPKWON = 'Ư������' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as SBANK_prevY, 
          	-- ���� ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = '����' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as BOHUM_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '����' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as BOHUM_prevY, 
          	-- ���� ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = '����' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as KEUMTOO_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '����' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as KEUMTOO_prevY, 
          	-- ���� ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = '����' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as YEOJUN_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '����' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as YEOJUN_prevY, 
          	-- ��ȣ���� ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = '��ȣ����' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as SANGHO_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '��ȣ����' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as SANGHO_prevY, 
          	-- �������� ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = '��������' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as JUCHOOK_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '��������' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as JUCHOOK_prevY, 
          	-- ��Ÿ ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = '��Ÿ' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as ETC_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '��Ÿ' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as ETC_prevY 
        FROM
          	(
            SELECT DISTINCT 
            	t0.GG_YM, 
              	t0.EFAS, 
              	t0.UPKWON, 
              	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.EFAS, t0.GG_YM, t0.UPKWON) as EFAS_AMT -- ����, ���Ǻ�, ����� ������
            FROM 
              	(
                SELECT 
                	t.GG_YM, 
                  	t.BRNO, 
                  	t.SOI_CD, 
                  	CASE 
                  		WHEN t.SOI_CD in ('01') THEN 'Ư������' 
                  		WHEN t.SOI_CD in ('03', '05', '07') THEN '�Ϲ�����' 
                  		WHEN t.SOI_CD in ('11', '13', '15') THEN '����' 
                  		WHEN t.SOI_CD in ('21', '61', '71', '76') THEN '����' 
                  		WHEN t.SOI_CD in ('31', '33', '35', '37') THEN '����' 
                  		WHEN t.SOI_CD in ('44', '74', '79', '81', '85', '87', '89') THEN '��ȣ����' 
                  		WHEN t.SOI_CD in ('41') THEN '��������' 
                  		ELSE '��Ÿ' 
                  	END as UPKWON,	-- ���� ���� ����
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
 * ���Ǻ� ��� �����ܾ� ���� - �������� ���� �� ���� SOI_CD2 ���� �����ܾ� ���� (p.3, [�׸�4] �߰�)   
 * RFP p.13 [�׸�1]���� �߰� ����     
 * ��å������� : 0
 * ��1������ : 1
 * ��2������ : 2
 * ��ξ� �� : 3
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
		DECODE(t0.newUPKWON_TYPE, '��å�������', t0.BRNO_AMT, 0) BRNO_AMT_0,
		DECODE(t0.newUPKWON_TYPE, '��1������', t0.BRNO_AMT, 0) BRNO_AMT_1,
		DECODE(t0.newUPKWON_TYPE, '��2������', t0.BRNO_AMT, 0) BRNO_AMT_2,
		DECODE(t0.newUPKWON_TYPE, '��ξ� ��', t0.BRNO_AMT, 0) BRNO_AMT_3
	FROM
	  	(
	    SELECT 
	    	t.BRWR_NO_TP_CD,
	    	t.GG_YM, 
	    	t.BRNO, 
	    	t.SOI_CD2, 
	    	t.EFAS,
	      	CASE 
	      		WHEN t.SOI_CD2 = 0 THEN '��å�������'
	      		WHEN t.SOI_CD2 = 1 THEN '��1������'
	      		WHEN t.SOI_CD2 = 2 THEN '��2������'
	      		ELSE '��ξ� ��' 
	      	END as newUPKWON_TYPE, -- ���� ����
	      	t.BRNO_AMT 
	    FROM 
	      	BASIC_BIZ_LOAN t
	    WHERE
	    	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
			AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
	  	) t0
	) t00
ORDER BY 
	t00.GG_YM;





/******************************************************
 * ����Ǻ�(SOI_CD2) ������ ������� ��Ȳ ���̺� (p.3, [ǥ] �߰�)
 * RFP p.13 [ǥ] ������ ��� ���� ��Ȳ ���� �߰� ���� 
 * ��å������� : 0
 * ��1������ : 1
 * ��2������ : 2
 * ��ξ� �� : 3
 *******************************************************/
-- ������ ��� ���� �����ܾ�/������ Table ���� (EFAS�ڵ�, �� ����, ��å�������, ��1������, ��2������, ��ξ� ��)
DROP TABLE IF EXISTS RESULT_BIZLoanTrend_UPKWON_SOI2_TABLE;
SELECT 
  	t0000.EFAS, 
  	-- �� ���� �ܾ�
  	ROUND(t0000.TOT_prevY, 0) as TOT_prevY, 
  	ROUND(t0000.TOT_thisY, 0) as TOT_thisY, 
  	round(COALESCE(t0000.TOT_thisY / NULLIF(t0000.TOT_prevY, 0), 1) - 1, 2) as TOT_Grate,	-- TOT_prevY�� 0�̸� 0%���� ����
  	-- ��å������� ���� �ܾ�
  	ROUND(t0000.POLFIN_prevY, 0) as POLFIN_prevY,
  	ROUND(t0000.POLFIN_thisY, 0) as POLFIN_thisY,  
  	round(COALESCE(t0000.POLFIN_thisY / NULLIF(t0000.POLFIN_prevY, 0), 1) - 1, 2) as POLFIN_Grate, 
  	-- ��1������ ���� �ܾ�
  	ROUND(t0000.FIN1_prevY, 0) as FIN1_prevY,
  	ROUND(t0000.FIN1_thisY, 0) as FIN1_thisY,
  	round(COALESCE(t0000.FIN1_thisY / NULLIF(t0000.FIN1_prevY, 0), 1) - 1, 2) as FIN1_Grate, 
  	-- ��2������ ���� �ܾ�
  	ROUND(t0000.FIN2_prevY, 0) as FIN2_prevY,
  	ROUND(t0000.FIN2_thisY, 0) as FIN2_thisY,  
  	round(COALESCE(t0000.FIN2_thisY / NULLIF(t0000.FIN2_prevY, 0), 1) - 1, 2) as FIN2_Grate, 
  	-- ��ξ� �� �����ܾ�
  	ROUND(t0000.DAEBOO_prevY, 0) as DAEBOO_prevY,
  	ROUND(t0000.DAEBOO_thisY, 0) as DAEBOO_thisY,  
  	round(COALESCE(t0000.DAEBOO_thisY / NULLIF(t0000.DAEBOO_prevY, 0), 1) - 1, 2) as DAEBOO_Grate 
	INTO RESULT_BIZLoanTrend_UPKWON_SOI2_TABLE
FROM 
  	(
    SELECT 
      	t000.*, 
      	-- �� ���� �ܾ�(����, ���⵿��)
      	t000.POLFIN_thisY + t000.FIN1_thisY + t000.FIN2_thisY + t000.DAEBOO_thisY as TOT_thisY, 
      	t000.POLFIN_prevY + t000.FIN1_prevY + t000.FIN2_prevY + t000.DAEBOO_prevY as TOT_prevY 
    FROM 
      	(
        SELECT DISTINCT 
        	t00.EFAS, 
          	-- ��å������� ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = '��å�������' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as POLFIN_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '��å�������' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as POLFIN_prevY, 
          	-- ��1������ ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = '��1������' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as FIN1_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '��1������' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as FIN1_prevY, 
          	-- ��2������ ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = '��2������' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as FIN2_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '��2������' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as FIN2_prevY, 
          	-- ��ξ� �� ������Ȳ(����, ���⵿��)
          	SUM(CASE WHEN t00.UPKWON = '��ξ� ��' AND t00.GG_YM = ${inputGG_YM} THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as DAEBOO_thisY, 
          	SUM(CASE WHEN t00.UPKWON = '��ξ� ��' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.EFAS_AMT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as DAEBOO_prevY
        FROM
          	(
            SELECT DISTINCT 
            	t0.GG_YM, 
              	t0.EFAS, 
              	t0.UPKWON, 
              	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.EFAS, t0.GG_YM, t0.UPKWON) as EFAS_AMT -- ����, ���Ǻ�, ����� ������
            FROM 
              	(
                SELECT 
                	t.GG_YM, 
                  	t.BRNO, 
                  	t.SOI_CD2, 
                  	CASE 
                  		WHEN t.SOI_CD2 = 0 THEN '��å�������' 
                  		WHEN t.SOI_CD2 = 1 THEN '��1������' 
                  		WHEN t.SOI_CD2 = 2 THEN '��2������'  
                  		ELSE '��ξ� ��'
                  	END as UPKWON,	-- ���� ���� ����
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




-- ��� ��ȸ
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_SOI;
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_BANK;
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_nonBANK;
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_SOI_TABLE;
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_SOI2;
SELECT * FROM RESULT_BIZLoanTrend_UPKWON_SOI2_TABLE;