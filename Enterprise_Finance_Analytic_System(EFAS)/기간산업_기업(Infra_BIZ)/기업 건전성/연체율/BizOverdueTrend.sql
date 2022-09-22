/*****************************************************
 * ������ ��ǥ ���� - ��ü�� ���� (���� p.6, [�׸�1], [ǥ])
 * RFP p.15 [�׸�1] ��ü��
 * Ȱ�� ���̺� : (1) BASIC_BIZ_OVD -> OVERDUE_TB ���̺� ����� ��ü�� ���
 *****************************************************/
-- (Step1) ����, �����, ����Ը�, �ܰ����κ�, ���忩�κ�, �����(����ڹ�ȣ ����) ��ü���� ���̺� ����
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
	t.BRWR_NO_TP_CD = '3' -- ����
	AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
	AND t.OSIDE_ISPT_YN = 'Y' -- �ܰ� ����
	AND 
	    CASE 
			WHEN '${isSangJang}' = 'Y' 
			THEN t.BLIST_MRKT_DIVN_CD IN ('1', '2')	-- ������(�ڽ���(1), �ڽ���(2))
			ELSE t.BLIST_MRKT_DIVN_CD IN ('1', '2', '3', '9')	-- �ܰ���ü
		END;
-- ��� ��ȸ
SELECT * FROM OVERDUE_TB;


-- ����, ����Ը� ��ü�� ��� 
DROP TABLE IF EXISTS OVERDUE_BIZSIZE;
SELECT DISTINCT
 	t0.GG_YM, 
 	SUM(t0.isOVERDUE_1) OVER (PARTITION BY t0.GG_YM) as NUM_OF_OVERDUE_BIZ_1,	-- ���� ��ü �����
 	SUM(t0.isBiz_1) OVER (PARTITION BY t0.GG_YM) as NUM_OF_BIZ_1,	-- ���� �����
 	ROUND(SUM(t0.isOVERDUE_1) OVER (PARTITION BY t0.GG_YM) 
 		/ NULLIF(SUM(t0.isBiz_1) OVER (PARTITION BY t0.GG_YM), 0), 4) as OVERDUE_RATIO_1,	-- ���� ��ü��	
 	SUM(t0.isOVERDUE_2) OVER (PARTITION BY t0.GG_YM) as NUM_OF_OVERDUE_BIZ_2,	-- �߼ұ�� ��ü �����
 	SUM(t0.isBiz_2) OVER (PARTITION BY t0.GG_YM) as NUM_OF_BIZ_2,	-- �߼ұ�� �����
 	ROUND(SUM(t0.isOVERDUE_2) OVER (PARTITION BY t0.GG_YM) 
 		/ NULLIF(SUM(t0.isBiz_2) OVER (PARTITION BY t0.GG_YM), 0), 4) as OVERDUE_RATIO_2,	-- �߼ұ�� ��ü��
 	SUM(t0.isOVERDUE_3) OVER (PARTITION BY t0.GG_YM) as NUM_OF_OVERDUE_BIZ_3,	-- �߰߱�� ��ü �����
 	SUM(t0.isBiz_3) OVER (PARTITION BY t0.GG_YM) as NUM_OF_BIZ_3,	-- �߰߱�� �����
 	ROUND(SUM(t0.isOVERDUE_3) OVER (PARTITION BY t0.GG_YM) 
 		/ NULLIF(SUM(t0.isBiz_3) OVER (PARTITION BY t0.GG_YM), 0), 4) as OVERDUE_RATIO_3,	-- �߰߱�� ��ü��
 	SUM(t0.isOVERDUE_0) OVER (PARTITION BY t0.GG_YM) as NUM_OF_OVERDUE_BIZ_0,	-- ��Ÿ��� ��ü �����
 	SUM(t0.isBiz_0) OVER (PARTITION BY t0.GG_YM) as NUM_OF_BIZ_0,	-- ��Ÿ��� �����
 	ROUND(SUM(t0.isOVERDUE_0) OVER (PARTITION BY t0.GG_YM) 
 		/ NULLIF(SUM(t0.isBiz_0) OVER (PARTITION BY t0.GG_YM), 0), 4) as OVERDUE_RATIO_0	-- ��Ÿ��� ��ü��
 	INTO OVERDUE_BIZSIZE
FROM 
	(
	SELECT 
		t.*,
		DECODE(t.BIZ_SIZE, '1', isOVERDUE, 0) as isOVERDUE_1,	-- ���� ��ü����
		DECODE(t.BIZ_SIZE, '1', 1, 0) as isBiz_1,				-- �����̸� ī��Ʈ
		DECODE(t.BIZ_SIZE, '2', isOVERDUE, 0) as isOVERDUE_2,	-- �߼ұ�� ��ü����
		DECODE(t.BIZ_SIZE, '2', 1, 0) as isBiz_2,				-- �߼ұ���̸� ī��Ʈ
		DECODE(t.BIZ_SIZE, '3', isOVERDUE, 0) as isOVERDUE_3,	-- �߰߱�� ��ü����
		DECODE(t.BIZ_SIZE, '3', 1, 0) as isBiz_3,				-- �߰߱���̸� ī��Ʈ
		DECODE(NVL(t.BIZ_SIZE, '0'), isOVERDUE, 0) as isOVERDUE_0,	-- ��Ÿ��� ��ü����
		DECODE(NVL(t.BIZ_SIZE, '0'), isOVERDUE, 0) as isBiz_0		-- ��Ÿ����̸� ī��Ʈ
	FROM
		OVERDUE_TB t
	WHERE
		CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
	) t0
ORDER BY t0.GG_YM;






/*****************************************************
 * ��ü��: ������ ��Ȳ (���� p.6 ǥ) - ��ü��, ���⵿����� ������ ����
 * RFP p.16 [ǥ] ��ü�� : ������ ��Ȳ
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
  	'00', -- ������� EFAS code '00'�Ҵ� 
  	SUM(t.thisYY_EFAS_OVERDUE_BIZ_CNT), 
  	SUM(t.thisYY_EFAS_TOT_BIZ_CNT), 
  	SUM(t.prevYY_EFAS_OVERDUE_BIZ_CNT), 
  	SUM(t.prevYY_EFAS_TOT_BIZ_CNT) 
FROM 
  	EFAS_OVERDUE_TB t;
-- ��� ��ȸ
SELECT * FROM EFAS_OVERDUE_TB t;


-- (Step3) ���س�/���� ���� ��ü�� �� ���� ���� ��� ������ ��� */
DROP TABLE IF EXISTS OVERDUE_EFAS;
SELECT 
  	TO_NUMBER(t.EFAS, '99') as EFAS, 
  	ROUND(t.thisYY_EFAS_OVERDUE_BIZ_CNT / t.thisYY_EFAS_TOT_BIZ_CNT, 4) as thisYY_OVERDUE_RATE, -- ��� ��ü��
  	ROUND(t.prevYY_EFAS_OVERDUE_BIZ_CNT / t.prevYY_EFAS_TOT_BIZ_CNT, 4) as prevYY_OVERDUE_RATE, -- ���� ���� ��ü��
  	ROUND(t.thisYY_EFAS_OVERDUE_BIZ_CNT / t.thisYY_EFAS_TOT_BIZ_CNT, 4) - ROUND(t.prevYY_EFAS_OVERDUE_BIZ_CNT / t.prevYY_EFAS_TOT_BIZ_CNT, 4) as INC_OVERDUE_RATE -- ���� ���� ��� ������
  	INTO OVERDUE_EFAS
FROM 
  	EFAS_OVERDUE_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');
  	
  
  
  
-- �ӽ����̺� ����
DROP TABLE IF EXISTS OVERDUE_TB;
DROP TABLE IF EXISTS EFAS_OVERDUE_TB;


-- �����ȸ
SELECT * FROM OVERDUE_BIZSIZE ORDER BY GG_YM;
SELECT * FROM OVERDUE_EFAS ORDER BY EFAS;