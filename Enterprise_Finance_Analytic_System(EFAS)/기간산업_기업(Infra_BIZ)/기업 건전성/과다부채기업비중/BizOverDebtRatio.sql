/****************************************************************
 * ������ ��ǥ ���� - ���ٺ�ä(��ä���� 200% �ʰ�) ��� ���� ���� (p.6, [�׸�3])
 * Ȱ�� ���̺� : DEBT_RATIO_TB���� ����� ��ä���� ����Ͽ� ���ٺ�ä ��� ���� ���
 ****************************************************************/
SELECT DISTINCT 
	t0.STD_YM, 
  	CASE 
  		WHEN t0.COMP_SCL_DIVN_CD = 1 THEN t0.COMP_SCL_DIVN_CD || ' ����'
  		WHEN t0.COMP_SCL_DIVN_CD = 2 THEN t0.COMP_SCL_DIVN_CD || ' �߼ұ��'
  		WHEN t0.COMP_SCL_DIVN_CD = 3 THEN t0.COMP_SCL_DIVN_CD || ' �߰߱��'
  		ELSE t0.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE, 
  	SUM(t0.isOVERDEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD) as OVERDEBTCNT, -- ����Ը� ���ٺ�ä ��� ��
  	COUNT(t0.CORP_NO) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD) as TOTBIZCNT, 
  	-- ����Ը� ��� ��
  	ROUND(SUM(t0.isOVERDEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD) / COUNT(t0.CORP_NO) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD), 4) as OVERDEBTRATIO -- ���ٺ�ä��� ���� 
FROM 
  	(
    SELECT 
      	t.STD_YM, 
      	t.CORP_NO, 
      	t.COMP_SCL_DIVN_CD, 
      	t.EFAS, 
      	CASE -- Dvision by zero ȸ��
      		WHEN (t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL)) >= 2 THEN 1 ELSE 0 
      	END as isOVERDEBT -- ��ä������ 200% �̻��̸� 1, �ƴϸ� 0���� ���ڵ�
    FROM 
      	DEBT_RATIO_TB t
  	) t0 
WHERE 
	t0.COMP_SCL_DIVN_CD in ('1', '2', '3')
	AND CAST(t0.STD_YM AS INTEGER) <= ${inputGG_YM}
ORDER BY 
  	t0.STD_YM;
 
 

  
 
/****************************************************************
 * ���ٺ�ä������� : ������ ��Ȳ (p.6, [ǥ])
 * Ȱ�� ���̺� : DEBT_RATIO_TB -> EFAS_OVERDEBTRATIO_TB ����
 ****************************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS EFAS_OVERDEBTRATIO_TB;
-- (Step1) ���̺� ����(�����ڵ�, ���س���ٺ�ä�����, ��ü�����, ���⵵���ٺ�ä�����, ���⵵��ü�����)
SELECT 
  	t00.EFAS, 
  	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}', '12'), t00.CNTOVERDEBTCORP, 0)) as thisYY_EFAS_CNTOVERDEBTCORP, 
  	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}', '12'), t00.CNTCORP, 0)) as thisYY_EFAS_CNTCORP, 
  	SUM(DECODE(t00.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00.CNTOVERDEBTCORP, 0)) as prevYY_EFAS_CNTOVERDEBTCORP, 
  	SUM(DECODE(t00.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), t00.CNTCORP, 0)) as prevYY_EFAS_CNTCORP 
  	INTO EFAS_OVERDEBTRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t0.EFAS, 
      	t0.STD_YM, 
      	SUM(t0.ISOVERDEBT) OVER(PARTITION BY t0.EFAS, t0.STD_YM) as CNTOVERDEBTCORP, 
      	COUNT(t0.CORP_NO) OVER(PARTITION BY t0.EFAS, t0.STD_YM) as CNTCORP 
    FROM 
      	(
        SELECT 
          	t.EFAS, 
          	t.CORP_NO, 
          	t.STD_YM, 
          	t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL) as DEBTRATIO, 
          	-- ��ä����
          	CASE -- Dvision by zero ȸ��
          		WHEN (t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL)) >= 2 THEN 1 ELSE 0 
          	END as isOVERDEBT -- ��ä������ 200% �̻��̸� 1, �ƴϸ� 0���� ���ڵ�
        FROM 
          	DEBT_RATIO_TB t 
        WHERE 
          	CAST(t.STD_YM AS INTEGER) IN (	-- ��� �� ���⵿��
    			CAST(CONCAT( '${inputYYYY}', '12') as integer),
    			CAST(CONCAT( '${inputYYYY}', '12') as integer) - 100)
      	) t0
  	) t00 
GROUP BY 
  	t00.EFAS;

 
-- (Step2) �Ѱ� �ջ�
INSERT INTO EFAS_OVERDEBTRATIO_TB 
SELECT 
  	'99', 
  	-- ������ EFAS code '99'�Ҵ� 
  	SUM(t.thisYY_EFAS_CNTOVERDEBTCORP), 
  	SUM(t.thisYY_EFAS_CNTCORP), 
  	SUM(t.prevYY_EFAS_CNTOVERDEBTCORP), 
  	SUM(t.prevYY_EFAS_CNTCORP) 
FROM 
  	EFAS_OVERDEBTRATIO_TB t;
-- ��� ��ȸ
SELECT * FROM EFAS_OVERDEBTRATIO_TB;


-- (Step3) ���س�/���� ���� ���ٺ�ä���� �� ���� ���� ��� ������ ��� */
SELECT 
  	t.*, 
  	ROUND(t.thisYY_EFAS_CNTOVERDEBTCORP / t.thisYY_EFAS_CNTCORP, 4) as thisYY_OVERDEBTCORPRATIO, -- ��� ���ٺ�ä�������
  	ROUND(t.prevYY_EFAS_CNTOVERDEBTCORP / t.prevYY_EFAS_CNTCORP, 4) as prevYY_OVERDEBTCORPRATIO, -- ���⵿�� ���ٺ�ä�������
  	ROUND(t.thisYY_EFAS_CNTOVERDEBTCORP / t.thisYY_EFAS_CNTCORP - t.prevYY_EFAS_CNTOVERDEBTCORP / t.prevYY_EFAS_CNTCORP, 4) as OVERDEBTCORPINC -- ���ٺ�ä������� ����
FROM 
  	EFAS_OVERDEBTRATIO_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');