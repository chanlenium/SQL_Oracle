/******************************************************
 * ���Ǻ� ��� �����ܾ� ���� - ����/������ ��� �����ܾ� ���� (p.3, [�׸�1])
 * ���� : 01, 03, 05, 07  
 * ������ : 11, 13, 15, 21, 61, 71, 76, 31, 33, 35, 37, 44, 74, 79, 81, 85, 87, 89, 41, 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
 ******************************************************/
SELECT DISTINCT
	t0.isBANK, 
	t0.GG_YM, 
	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.GG_YM, t0.isBANK) as LOAN 
FROM 
  	(
    SELECT 
    	t.BRWR_NO_TP_CD,
    	t.GG_YM, 
    	t.BRNO, 
    	t.SOI_CD, 
      	CASE WHEN t.SOI_CD in ('01', '03', '05', '07') THEN '����' ELSE '������' END as isBANK, -- ����/������ ����
      	t.BRNO_AMT 
    FROM 
      	BASIC_BIZ_LOAN t 
  	) t0 
WHERE
    CAST(t0.GG_YM AS INTEGER) <= ${inputGG_YM}
ORDER BY 
	t0.isBANK, t0.GG_YM;
 



/******************************************************
 * ���Ǻ� ��� �����ܾ� ���� - ���ະ �����ܾ� ���� (p.3, [�׸�2])        
 * Ư������ : 01
 * �Ϲ����� : 03, 05, 07
 ******************************************************/
SELECT DISTINCT 
	t0.BANK_TYPE, 
  	t0.GG_YM, 
  	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.GG_YM, t0.BANK_TYPE) as BANK_LOAN 
FROM 
  	(
    SELECT 
    	t.GG_YM, 
      	t.BRWR_NO_TP_CD,
      	t.BRNO, 
      	t.SOI_CD, 
      	DECODE(t.SOI_CD, '01', 'Ư������', '�Ϲ�����') AS BANK_TYPE, 
      	t.BRNO_AMT
    FROM 
      	BASIC_BIZ_LOAN t 
    WHERE 
      	t.SOI_CD IN ('01', '03', '05', '07') 
  	) t0 
WHERE
	CAST(t0.GG_YM AS INTEGER) <= ${inputGG_YM}	
ORDER BY 
  	t0.BANK_TYPE, t0.GG_YM;
 
 
 
  
  
 /******************************************************
 * ���Ǻ� ��� �����ܾ� ���� - �����ະ(����/����/����/��ȣ����/��������/��Ÿ) �����ܾ� ���� (p.3, [�׸�3])        
 * ���� : 11, 13, 15
 * ���� : 21, 61, 71, 76
 * ���� : 31, 33, 35, 37
 * ��ȣ���� : 44, 74, 79, 81, 85, 87, 89
 * �������� : 41
 * ��Ÿ : 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
 ******************************************************/
SELECT DISTINCT 
	t0.nonBANK_TYPE, 
  	t0.GG_YM, 
  	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.GG_YM, t0.nonBANK_TYPE) as nonBANK_LOAN 
FROM 
  	(
    SELECT 
      	t.GG_YM, 
      	t.BRNO, 
      	t.SOI_CD, 
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
  	) t0 
WHERE 
	CAST(t0.GG_YM AS INTEGER) <= ${inputGG_YM}
ORDER BY 
	t0.nonBANK_TYPE, t0.GG_YM;





/******************************************************
 * ����/������ ������ ������� ��Ȳ ���̺� (p.3, [ǥ])
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
SELECT 
  	t0000.EFAS, 
  	-- �� ���� �ܾ�
  	t0000.TOT_thisY, 
  	t0000.TOT_prevY, 
  	round(COALESCE(t0000.TOT_thisY / NULLIF(t0000.TOT_prevY, 0), 1) - 1, 2) as TOT_Grate,	-- TOT_prevY�� 0�̸� 0%���� ����
  	-- �Ϲ�����
  	t0000.GBANK_thisY, 
  	t0000.GBANK_prevY, 
  	round(COALESCE(t0000.GBANK_thisY / NULLIF(t0000.GBANK_prevY, 0), 1) - 1, 2) as GBANK_Grate, 
  	-- Ư������
  	t0000.SBANK_thisY, 
 	t0000.SBANK_prevY, 
  	round(COALESCE(t0000.SBANK_thisY / NULLIF(t0000.SBANK_prevY, 0), 1) - 1, 2) as SBANK_Grate, 
  	-- ����
  	t0000.BOHUM_thisY, 
 	t0000.BOHUM_prevY, 
  	round(COALESCE(t0000.BOHUM_thisY / NULLIF(t0000.BOHUM_prevY, 0), 1) - 1, 2) as BOHUM_Grate, 
  	-- ����
  	t0000.KEUMTOO_thisY, 
  	t0000.KEUMTOO_prevY, 
  	round(COALESCE(t0000.KEUMTOO_thisY / NULLIF(t0000.KEUMTOO_prevY, 0), 1) - 1, 2) as KEUMTOO_Grate, 
  	-- ����
  	t0000.YEOJUN_thisY, 
  	t0000.YEOJUN_prevY, 
  	round(COALESCE(t0000.YEOJUN_thisY / NULLIF(t0000.YEOJUN_prevY, 0), 1) - 1, 2) as YEOJUN_Grate, 
  	-- ��ȣ����
  	t0000.SANGHO_thisY, 
  	t0000.SANGHO_prevY, 
  	round(COALESCE(t0000.SANGHO_thisY / NULLIF(t0000.SANGHO_prevY, 0), 1) - 1, 2) as SANGHO_Grate, 
  	-- ��������
  	t0000.JUCHOOK_thisY, 
  	t0000.JUCHOOK_prevY, 
  	round(COALESCE(t0000.JUCHOOK_thisY / NULLIF(t0000.JUCHOOK_prevY, 0), 1) - 1, 2) as JUCHOOK_Grate, 
  	-- ��Ÿ
  	t0000.ETC_thisY, 
  	t0000.ETC_prevY, 
 	round(COALESCE(t0000.ETC_thisY / NULLIF(t0000.ETC_prevY, 0), 1) - 1, 2) as ETC_Grate  
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
                  	t.EFAS 
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
 * ��å������� : 0
 * ��1������ : 1
 * ��2������ : 2
 * ��ξ� �� : 3
 ******************************************************/ 
SELECT DISTINCT
	t0.newUPKWON_TYPE, 
	t0.GG_YM, 
	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.GG_YM, t0.newUPKWON_TYPE) as LOAN 
FROM 
  	(
    SELECT 
    	t.BRWR_NO_TP_CD,
    	t.GG_YM, 
    	t.BRNO, 
    	t.SOI_CD2, 
      	CASE 
      		WHEN t.SOI_CD2 = 0 THEN '��å�������'
      		WHEN t.SOI_CD2 = 1 THEN '��1������'
      		WHEN t.SOI_CD2 = 2 THEN '��2������'
      		ELSE '��ξ� ��' 
      	END as newUPKWON_TYPE, -- ���� ����
      	t.BRNO_AMT 
    FROM 
      	BASIC_BIZ_LOAN t 
  	) t0 
WHERE
	CAST(t0.GG_YM AS INTEGER) <= ${inputGG_YM}
ORDER BY 
	t0.newUPKWON_TYPE, t0.GG_YM;





/******************************************************
 * ����Ǻ�(SOI_CD2) ������ ������� ��Ȳ ���̺� (p.3, [ǥ] �߰�)
 * ��å������� : 0
 * ��1������ : 1
 * ��2������ : 2
 * ��ξ� �� : 3
 *******************************************************/
-- ������ ��� ���� �����ܾ�/������ Table ���� (EFAS�ڵ�, �� ����, ��å�������, ��1������, ��2������, ��ξ� ��)
SELECT 
  	t0000.EFAS, 
  	-- �� ���� �ܾ�
  	t0000.TOT_thisY, 
  	t0000.TOT_prevY, 
  	round(COALESCE(t0000.TOT_thisY / NULLIF(t0000.TOT_prevY, 0), 1) - 1, 2) as TOT_Grate,	-- TOT_prevY�� 0�̸� 0%���� ����
  	-- ��å������� ���� �ܾ�
  	t0000.POLFIN_thisY, 
  	t0000.POLFIN_prevY, 
  	round(COALESCE(t0000.POLFIN_thisY / NULLIF(t0000.POLFIN_prevY, 0), 1) - 1, 2) as POLFIN_Grate, 
  	-- ��1������ ���� �ܾ�
  	t0000.FIN1_thisY, 
 	t0000.FIN2_prevY, 
  	round(COALESCE(t0000.FIN1_thisY / NULLIF(t0000.FIN1_prevY, 0), 1) - 1, 2) as FIN1_Grate, 
  	-- ��2������ ���� �ܾ�
  	t0000.FIN2_thisY, 
 	t0000.FIN2_prevY, 
  	round(COALESCE(t0000.FIN2_thisY / NULLIF(t0000.FIN2_prevY, 0), 1) - 1, 2) as FIN2_Grate, 
  	-- ��ξ� �� �����ܾ�
  	t0000.DAEBOO_thisY, 
  	t0000.DAEBOO_prevY, 
  	round(COALESCE(t0000.DAEBOO_thisY / NULLIF(t0000.DAEBOO_prevY, 0), 1) - 1, 2) as DAEBOO_Grate 
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
                  	t.EFAS 
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