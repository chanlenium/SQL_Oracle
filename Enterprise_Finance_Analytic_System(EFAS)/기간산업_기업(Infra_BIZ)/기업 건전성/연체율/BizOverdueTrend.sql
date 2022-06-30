/*****************************************************
 * ������ ��ǥ ���� - ��ü�� ���� (p.6, [�׸�1], [ǥ])
 * Ȱ�� ���̺� : (1) BASIC_BIZ_OVD -> OVERDUE_TB ���̺� ����� ��ü�� ���
 *****************************************************/
-- (Standby) ����, �����, ����Ը�, �ܰ����κ�, ���忩�κ�, �����(����ڹ�ȣ ����) ��ü���� ���̺� ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS OVERDUE_TB;
-- OVERDUE_TB ���̺� ����(���س��, �������, ���ι�ȣ, ����ڹ�ȣ, EFAS, ����Ը�, �ܰ�����, ���屸��, ��ü����)
SELECT DISTINCT
		t.GG_YM,
		t.BRWR_NO_TP_CD,
		t.CORP_NO,
		t.BRNO,
		t.EFAS,
		t.BIZ_SIZE,
		t.OSIDE_ISPT_YN,	-- �ܰ�����
		t.BLIST_MRKT_DIVN_CD,	-- ���忩��
		CASE 
			WHEN SUM(t.ODU_AMT) OVER(PARTITION BY t.GG_YM, t.BRNO) > 0
			THEN 1
			ELSE 0
		END as isOVERDUE
	INTO OVERDUE_TB
FROM BASIC_BIZ_OVD t
WHERE 
	t.BRWR_NO_TP_CD = 3 -- ����
	AND t.OSIDE_ISPT_YN = 'Y'; -- �ܰ� ����
--	AND t.BLIST_MRKT_DIVN_CD in ('1', '2')	-- �ڽ���(1), �ڽ���(2)
-- ��� ��ȸ
SELECT * FROM OVERDUE_TB;


-- ����, ����Ը� ��ü�� ��� 
SELECT DISTINCT 
 	t.GG_YM, 
  	CASE 
  		WHEN t.BIZ_SIZE = 1 THEN t.BIZ_SIZE || ' ����'
  		WHEN t.BIZ_SIZE = 2 THEN t.BIZ_SIZE || ' �߼ұ��'
  		WHEN t.BIZ_SIZE = 3 THEN t.BIZ_SIZE || ' �߰߱��'
  		ELSE t.BIZ_SIZE
  	END as BIZ_SIZE,
  	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as NUM_OF_OVERDUE_BIZ,	-- ��ü �����
  	COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as TOT_NUM_OF_BIZ,  -- ����Ը� ��ü ����� 
  	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) / COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as OVERDUE_RATIO	-- ����Ը� ��ü��  
FROM
	OVERDUE_TB t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM};





/*****************************************************
 * ��ü��: ������ ��Ȳ (p.6 ǥ) - ��ü��, ���⵿����� ������ ����
 *****************************************************/
-- (Step1) ������ ��� �� ���⵿���� ��ü��� ��, ��ü��� �� ������ ������ ���̺�(EFAS_OVERDUE_TB) ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS EFAS_OVERDUE_TB;
-- ���̺� ����
SELECT DISTINCT 
	t00.EFAS, 
  	-- �ݳ� ���� ��ü�����, �� �����
  	SUM(CASE WHEN t00.GG_YM = ${inputGG_YM} THEN EFAS_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as thisYY_EFAS_OVERDUE_BIZ_CNT,
  	SUM(CASE WHEN t00.GG_YM = ${inputGG_YM} THEN EFAS_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as thisYY_EFAS_TOT_BIZ_CNT,
  	-- ���� ���� ��ü�����, �� �����
  	SUM(CASE WHEN t00.GG_YM = ${inputGG_YM} - 100 THEN EFAS_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as prevYY_EFAS_OVERDUE_BIZ_CNT,
  	SUM(CASE WHEN t00.GG_YM = ${inputGG_YM} - 100 THEN EFAS_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t00.EFAS) as prevYY_EFAS_TOT_BIZ_CNT
  	INTO EFAS_OVERDUE_TB
FROM 
  	(
    SELECT DISTINCT
    	t0.GG_YM,
      	t0.EFAS, 
      	-- �ݳ� ���� ��ü�����, �� �����
      	SUM(t0.isOVERDUE) OVER(PARTITION BY t0.GG_YM, t0.EFAS) as EFAS_OVERDUE_BIZ_CNT, 
      	COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EFAS) as EFAS_TOT_BIZ_CNT 
    FROM 
      	(
        SELECT 
        	t.*
        FROM 
          	OVERDUE_TB t 
        WHERE 
          	CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}, ${inputGG_YM} - 100)	-- ��� �� ���� ���� 
      	) t0
  	) t00;
-- ��� ��ȸ
SELECT * FROM EFAS_OVERDUE_TB t;


-- (Step2) �Ѱ� ����Ͽ� ����
INSERT INTO EFAS_OVERDUE_TB 
SELECT 
  	'99', -- ������ EFIS code '00'�Ҵ� 
  	SUM(t.thisYY_EFAS_OVERDUE_BIZ_CNT), 
  	SUM(t.thisYY_EFAS_TOT_BIZ_CNT), 
  	SUM(t.prevYY_EFAS_OVERDUE_BIZ_CNT), 
  	SUM(t.prevYY_EFAS_TOT_BIZ_CNT) 
FROM 
  	EFAS_OVERDUE_TB t;
-- ��� ��ȸ
SELECT * FROM EFAS_OVERDUE_TB t;


-- (Step3) ���س�/���� ���� ��ü�� �� ���� ���� ��� ������ ��� */
SELECT 
  	TO_NUMBER(t.EFAS, '99') as EFAS, 
  	ROUND(t.thisYY_EFAS_OVERDUE_BIZ_CNT / t.thisYY_EFAS_TOT_BIZ_CNT, 4) as thisYY_OVERDUE_RATE, -- ��� ��ü��
  	ROUND(t.prevYY_EFAS_OVERDUE_BIZ_CNT / t.prevYY_EFAS_TOT_BIZ_CNT, 4) as prevYY_OVERDUE_RATE, -- ���� ���� ��ü��
  	ROUND(t.thisYY_EFAS_OVERDUE_BIZ_CNT / t.thisYY_EFAS_TOT_BIZ_CNT, 4) - ROUND(t.prevYY_EFAS_OVERDUE_BIZ_CNT / t.prevYY_EFAS_TOT_BIZ_CNT, 4) as INC_OVERDUE_RATE -- ���� ���� ��� ������
FROM 
  	EFAS_OVERDUE_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');