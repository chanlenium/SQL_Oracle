/*****************************************************
 * �㺸���� ��Ȳ - �㺸���� ���� (p.1, [�׸� 1]) 
 * Ȱ�� ���̺�: BASIC_BIZ_DAMBO       
 * ����� �Է� : ��ȸ���س��(inputGG_YM)        
 *****************************************************/
SELECT DISTINCT 
	t.GG_YM, 
	t.DAMBO_TYPE,	  	 -- �㺸����(1:����, 2:����, 5:��Ÿ, 6:�Ѱ�) 
	CASE 
  		WHEN t.BIZ_SIZE = 1 THEN t.BIZ_SIZE || ' ����'
  		WHEN t.BIZ_SIZE = 2 THEN t.BIZ_SIZE || ' �߼ұ��'
  		WHEN t.BIZ_SIZE = 3 THEN t.BIZ_SIZE || ' �߰߱��'
  		ELSE t.BIZ_SIZE
  	END as BIZ_SIZE,
  	round(SUM(t.BRNO_DAMBO_AMT) OVER(PARTITiON BY t.GG_YM, t.DAMBO_TYPE, t.BIZ_SIZE), 0) AS DAMBO_AMT -- �㺸���� �� ���س���� �㺸���� sum
FROM 
  	BASIC_BIZ_DAMBO t
WHERE
	CAST(t.GG_YM AS INTEGER) <= :inputGG_YM
ORDER BY 
	t.GG_YM;


 
 
  	
/*****************************************************
 * �㺸���� ��Ȳ - ���Ǻ�(����/������) ���� ���� ��� �㺸���� ��ȭ (p.1, [�׸� 1])
 * Ȱ�� ���̺�: BASIC_BIZ_DAMBO
 *****************************************************/
SELECT 
  	t000.isBANK, 
  	t000.DAMBO_TYPE, 
  	round(t000.BANK_thisYY + t000.nonBANK_thisYY, 0) as thisYY_AMT, -- ���� �㺸����
  	round(t000.BANK_prevYY + t000.nonBANK_prevYY, 0) as prevYY_AM -- ���� ���� �㺸����
FROM 
  	(
    SELECT DISTINCT 
    	t00.isBANK, 
      	t00.DAMBO_TYPE, -- ���� �㺸��Ȳ(����, ���⵿��)
      	SUM(CASE WHEN t00.isBANK = '����' AND t00.GG_YM = :inputGG_YM THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as BANK_thisYY, 
      	SUM(CASE WHEN t00.isBANK = '����' AND t00.GG_YM = :inputGG_YM - 100 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as BANK_prevYY, 
      	-- ������ �㺸��Ȳ(����, ���⵿��)
      	SUM(CASE WHEN t00.isBANK = '������' AND t00.GG_YM = :inputGG_YM THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as nonBANK_thisYY, 
      	SUM(CASE WHEN t00.isBANK = '������' AND t00.GG_YM = :inputGG_YM - 100 THEN t00.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t00.DAMBO_TYPE, t00.isBANK) as nonBANK_prevYY 
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
            	CAST(t.GG_YM AS INTEGER) in (:inputGG_YM, :inputGG_YM - 100)	-- ��� �� ���� ���� 
          	) t0 
      	) t00
  	) t000;

  
  
 
 
/*****************************************************
 * �㺸���� ��Ȳ - �ֿ����� �㺸����
 * �ֿ� ��� ���� ���� ��� ����/����/��Ÿ ��ȭ (p.1, [�׸� 1])
 * (�ڵ���: 37, ����: 39, ö��: 22, ����: 11, ����ȭ��: 12, �ݵ�ü: 26, ���÷���: 27, �ؿ�: 48, �Ǽ�: 45)
 * Ȱ�� ���̺�: BASIC_BIZ_DAMBO
 *****************************************************/
SELECT 
  	t00.EFAS, 
  	t00.DAMBO_TYPE, 
  	-- ���� �㺸����
  	t00.thisYY_EFAS37 + t00.thisYY_EFAS39 + t00.thisYY_EFAS22 + t00.thisYY_EFAS11 + t00.thisYY_EFAS12 + t00.thisYY_EFAS26 + t00.thisYY_EFAS27 + t00.thisYY_EFAS48 + t00.thisYY_EFAS45 as thisYY_AMT, 
  	-- ���� ���� �㺸����
  	t00.prevYY_EFAS37 + t00.prevYY_EFAS39 + t00.prevYY_EFAS22 + t00.prevYY_EFAS11 + t00.prevYY_EFAS12 + t00.prevYY_EFAS26 + t00.prevYY_EFAS27 + t00.prevYY_EFAS48 + t00.prevYY_EFAS45 as prevYY_AMT 
FROM 
  	(
    SELECT DISTINCT 
    	t0.EFAS, 
	  	t0.DAMBO_TYPE, 
	  	-- �ڵ���(37) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '37' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS37, 
	  	SUM(CASE WHEN t0.EFAS = '37' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS37, 
	  	-- ����(39) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '39' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS39, 
	  	SUM(CASE WHEN t0.EFAS = '39' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS39,
	  	-- ö��(22) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '22' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS22, 
	  	SUM(CASE WHEN t0.EFAS = '22' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS22,
	  	-- ����(11) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '11' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS11, 
	  	SUM(CASE WHEN t0.EFAS = '11' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS11,
	  	-- ����ȭ��(12) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '12' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS12, 
	  	SUM(CASE WHEN t0.EFAS = '12' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS12,
	  	-- �ݵ�ü(26) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '26' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS26, 
	  	SUM(CASE WHEN t0.EFAS = '26' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS26,
	  	-- ���÷���(27) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '27' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS27, 
	  	SUM(CASE WHEN t0.EFAS = '27' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS27,
	  	-- �ؿ�(48) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '48' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS48, 
	  	SUM(CASE WHEN t0.EFAS = '48' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS48,
	  	-- �Ǽ�(45) �㺸��Ȳ(����, ���⵿��)
	  	SUM(CASE WHEN t0.EFAS = '45' AND t0.GG_YM = :inputGG_YM THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as thisYY_EFAS45, 
	  	SUM(CASE WHEN t0.EFAS = '45' AND t0.GG_YM = :inputGG_YM - 100 THEN t0.DAMBO_AMT ELSE 0 END) OVER(PARTITION BY t0.DAMBO_TYPE, t0.EFAS) as prevYY_EFAS45 
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
            CAST(t.GG_YM AS INTEGER) in (:inputGG_YM, :inputGG_YM - 100)	-- ��� �� ���� ���� 
        ) t0
  	) t00
WHERE 
	t00.EFAS in ('37', '39', '22', '11', '12', '26', '27', '48', '45')
ORDER BY 
  	To_number(t00.EFAS, '99'), DAMBO_TYPE;