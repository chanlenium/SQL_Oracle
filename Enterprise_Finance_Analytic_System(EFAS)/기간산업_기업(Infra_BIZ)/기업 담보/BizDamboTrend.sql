/*****************************************************
 * �㺸���� ��Ȳ - �㺸���� ���� (���� p.1, [�׸� 1]) 
 * RFP p.12 [�׸�1] �㺸���� ���� 
 * Ȱ�� ���̺�: BASIC_BIZ_DAMBO       
 * ����� �Է� : ��ȸ���س��(inputGG_YM)        
 *****************************************************/
DROP TABLE IF EXISTS RESULT_BIZDamboTrend;
SELECT DISTINCT 
	t.GG_YM, 
	t.DAMBO_TYPE,	  	 -- �㺸����(1:����, 2:����, 5:��Ÿ, 6:�Ѱ�) 
  	round(SUM(t.BRNO_DAMBO_AMT) OVER(PARTITiON BY t.GG_YM, t.DAMBO_TYPE), 0) AS DAMBO_AMT -- �㺸���� �� ���س���� �㺸���� sum
  	INTO RESULT_BIZDamboTrend
FROM 
  	BASIC_BIZ_DAMBO t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
	AND t.BRWR_NO_TP_CD = '3'	-- ���θ�
	AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
ORDER BY 
	t.GG_YM;


 
 
  	
/*****************************************************
 * �㺸���� ��Ȳ - ���Ǻ�(����/������) ���� ���� ��� �㺸���� ��ȭ (p.1, [�׸� 1])
 * RFP p.12 [�׸�2] �������Ǻ� �㺸���� 
 * Ȱ�� ���̺�: BASIC_BIZ_DAMBO
 *****************************************************/
DROP TABLE IF EXISTS RESULT_BIZDamboTrend_UPKWON;
SELECT 
  	t000.isBANK, 
  	t000.DAMBO_TYPE, 
  	round(t000.BANK_N1 + t000.nonBANK_N1, 0) as AMT_N2,  -- ������ ���� �㺸����
  	round(t000.BANK_N1 + t000.nonBANK_N1, 0) as AMT_N1, -- ���� ���� �㺸����
  	round(t000.BANK_N0 + t000.nonBANK_N0, 0) as AMT_N0  -- ���� �㺸����
  	INTO RESULT_BIZDamboTrend_UPKWON
FROM 
  	(
    SELECT DISTINCT 
    	t00.isBANK, 
      	t00.DAMBO_TYPE, 
      	-- ���� �㺸��Ȳ(����, ���⵿��)
      	SUM(CASE WHEN t00.isBANK = '����' AND t00.GG_YM = ${inputGG_YM} THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as BANK_N0, 
      	SUM(CASE WHEN t00.isBANK = '����' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as BANK_N1, 
      	SUM(CASE WHEN t00.isBANK = '����' AND t00.GG_YM = ${inputGG_YM} - 200 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as BANK_N2,
      	-- ������ �㺸��Ȳ(����, ���⵿��)
      	SUM(CASE WHEN t00.isBANK = '������' AND t00.GG_YM = ${inputGG_YM} THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as nonBANK_N0, 
      	SUM(CASE WHEN t00.isBANK = '������' AND t00.GG_YM = ${inputGG_YM} - 100 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as nonBANK_N1,
      	SUM(CASE WHEN t00.isBANK = '������' AND t00.GG_YM = ${inputGG_YM} - 200 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as nonBANK_N2
    FROM 
      	(
        SELECT DISTINCT 
        	t0.GG_YM, 
          	t0.isBANK, 
          	t0.DAMBO_TYPE,	-- �㺸����(1:����, 2:����, 5:��Ÿ, 6:�Ѱ�)
          	round(SUM(t0.BRNO_DAMBO_AMT) OVER(PARTITiON BY t0.GG_YM, t0.DAMBO_TYPE, t0.isBANK), 0) AS DAMBO_AMT -- �㺸���� �� ���س���� �㺸���� sum
          	--t0.BRNO_DAMBO_AMT
        FROM 
          	(
            SELECT 
              	t.*, 
              	CASE WHEN t.SOI_CD in ('01', '03', '05', '07') THEN '����' ELSE '������' END as isBANK -- ���� ����
            FROM 
              	BASIC_BIZ_DAMBO t 
            WHERE 
            	CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}, ${inputGG_YM} - 100, ${inputGG_YM} - 200)	-- �ֱ� 3���� 
            	AND t.BRWR_NO_TP_CD = '3'	-- ���θ�
				AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
          	) t0 
      	) t00
  	) t000;

  
  
 
 
/*****************************************************
 * �㺸���� ��Ȳ - �ֿ����� �㺸����
 * �ֿ� ��� ���� ���� ��� ����/����/��Ÿ ��ȭ (p.1, [�׸� 1])
 * RFP p.12 [�׸�2] ������ �㺸���� 
 * (�ڵ���: 37, ����: 39, ö��: 22, ����: 11, ����ȭ��: 12, �ݵ�ü: 26, ���÷���: 27, �ؿ�: 48, �Ǽ�: 45)
 * Ȱ�� ���̺�: BASIC_BIZ_DAMBO
 *****************************************************/
DROP TABLE IF EXISTS RESULT_BIZDamboTrend_EFAS;
SELECT 
  	t00.EFAS, 
  	t00.DAMBO_TYPE,
  	-- ������ ���� �㺸����
  	t00.N2_EFAS37 + t00.N2_EFAS39 + t00.N2_EFAS22 + t00.N2_EFAS11 + t00.N2_EFAS12 + t00.N2_EFAS26 + t00.N2_EFAS27 + t00.N2_EFAS48 + t00.N2_EFAS45 as N2_AMT,
  	-- ���� ���� �㺸����
  	t00.N1_EFAS37 + t00.N1_EFAS39 + t00.N1_EFAS22 + t00.N1_EFAS11 + t00.N1_EFAS12 + t00.N1_EFAS26 + t00.N1_EFAS27 + t00.N1_EFAS48 + t00.N1_EFAS45 as N1_AMT,
  	-- ���� �㺸����
  	t00.N0_EFAS37 + t00.N0_EFAS39 + t00.N0_EFAS22 + t00.N0_EFAS11 + t00.N0_EFAS12 + t00.N0_EFAS26 + t00.N0_EFAS27 + t00.N0_EFAS48 + t00.N0_EFAS45 as AMT_N0 	
  	INTO RESULT_BIZDamboTrend_EFAS
FROM 
  	(
    SELECT DISTINCT 
    	t0.EFAS, 
	  	t0.DAMBO_TYPE, 
	  	-- �ڵ���(37) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '37' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS37, 
	  	SUM(CASE WHEN t0.EFAS = '37' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS37, 
	  	SUM(CASE WHEN t0.EFAS = '37' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS37,
	  	-- ����(39) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '39' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS39, 
	  	SUM(CASE WHEN t0.EFAS = '39' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS39,
	  	SUM(CASE WHEN t0.EFAS = '39' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS39,
	  	-- ö��(22) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '22' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS22, 
	  	SUM(CASE WHEN t0.EFAS = '22' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS22,
	  	SUM(CASE WHEN t0.EFAS = '22' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS22,
	  	-- ����(11) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '11' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS11, 
	  	SUM(CASE WHEN t0.EFAS = '11' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS11,
	  	SUM(CASE WHEN t0.EFAS = '11' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS11,
	  	-- ����ȭ��(12) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '12' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS12, 
	  	SUM(CASE WHEN t0.EFAS = '12' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS12,
	  	SUM(CASE WHEN t0.EFAS = '12' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS12,
	  	-- �ݵ�ü(26) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '26' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS26, 
	  	SUM(CASE WHEN t0.EFAS = '26' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS26,
	  	SUM(CASE WHEN t0.EFAS = '26' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS26,
	  	-- ���÷���(27) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '27' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS27, 
	  	SUM(CASE WHEN t0.EFAS = '27' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS27,
	  	SUM(CASE WHEN t0.EFAS = '27' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS27,
	  	-- �ؿ�(48) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '48' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS48, 
	  	SUM(CASE WHEN t0.EFAS = '48' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS48,
	  	SUM(CASE WHEN t0.EFAS = '48' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS48,
	  	-- �Ǽ�(45) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '45' AND t0.GG_YM = ${inputGG_YM} THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N0_EFAS45, 
	  	SUM(CASE WHEN t0.EFAS = '45' AND t0.GG_YM = ${inputGG_YM} - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N1_EFAS45,
	  	SUM(CASE WHEN t0.EFAS = '45' AND t0.GG_YM = ${inputGG_YM} - 200 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as N2_EFAS45
    FROM 
      	(
        SELECT DISTINCT 
        	t.GG_YM, 
          	t.EFAS, 
          	t.DAMBO_TYPE,	-- �㺸����(1:����, 2:����, 5:��Ÿ, 6:�Ѱ�)
          	round(SUM(t.BRNO_DAMBO_AMT) OVER(PARTITiON BY t.GG_YM, t.DAMBO_TYPE, t.EFAS), 0) AS DAMBO_AMT -- �㺸���� �� ���س���� �㺸���� sum
        FROM 
            BASIC_BIZ_DAMBO t 
        WHERE 
            CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}, ${inputGG_YM} - 100, ${inputGG_YM} - 200)	-- �ֱ� 3���� 
            AND t.BRWR_NO_TP_CD = '3'	-- ���θ�
			AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
        ) t0
  	) t00
WHERE 
	t00.EFAS in ('37', '39', '22', '11', '12', '26', '27', '48', '45')
ORDER BY 
  	To_number(t00.EFAS, '99'), DAMBO_TYPE;
  	
  

  
  
-- ��� ��ȸ
SELECT * FROM RESULT_BIZDamboTrend ORDER BY GG_YM, DAMBO_TYPE;
SELECT * FROM RESULT_BIZDamboTrend_UPKWON ORDER BY isBANK, DAMBO_TYPE;
SELECT * FROM RESULT_BIZDamboTrend_EFAS ORDER BY TO_NUMBER(EFAS, '99'), DAMBO_TYPE;