/****************************************************************
 * ������ ��ǥ ���� - ���ں������(=��������/���ں��) ���� (p.6, [�׸�4])
 * Ȱ�� ���̺� : newGIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> INTCOVRATIO_TB ���̺� ����
 ****************************************************************/
-- (Standby) ����, �����, ����Ը� ���ں������ ���̺� INTCOVRATIO_TB ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS INTCOVRATIO_TB;
-- ���̺� ���� (���س��, ���ι�ȣ, ����Ը�, KSIC, newINDU, newINDU_NM, ��������, ���ں��, EFIS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO INTCOVRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC,
      	t2.newINDU,
      	t2.newINDU_NM,
      	t1.INT_EXP, 
      	t1.OP_PROFIT 
    FROM 
      	(
        SELECT 
          t000.COMP_CD, 
          t000.STD_DT, 
          t000.INT_EXP, 
          t000.OP_PROFIT 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT, 
              	t00.INT_EXP, 
              	t00.OP_PROFIT, 
              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ��� 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.INT_EXP) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as INT_EXP,	-- ���ں��
                  	SUM(t0.OP_PROFIT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as OP_PROFIT -- ��������
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	t.ITEM_CD, 
                      	DECODE(t.ITEM_CD, '6110', t.AMT, 0) as INT_EXP, -- ���ں��
                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as OP_PROFIT -- ��������
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	t.REPORT_CD = '12' 
                      	and t.ITEM_CD in ('6110', '5000')
                  	) t0 -- ���ں��(6110), ��������(5000)
                WHERE 
                  	t0.STD_DT IN (	 -- �ֱ� 4����
	                	CONCAT('${inputYYYY}', '1231'),
	                	CONCAT('${inputYYYY}' - 1, '1231'),
	                	CONCAT('${inputYYYY}' - 2, '1231'),
	                	CONCAT('${inputYYYY}' - 3, '1231')) 
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN newGIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
      			AND t2.OSIDE_ISPT_YN = 'Y'
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- ��� ��ȸ
SELECT * FROM INTCOVRATIO_TB ORDER BY STD_YM;


/*************************************************
 * ����Ը�(��/��/��) ������ ���ں������ (1: ����, 2: �߼ұ��, 3: �߰߱��, 0: ���ƴ�)
 *************************************************/
SELECT DISTINCT 
	t.STD_YM, 
	CASE 
  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN t.COMP_SCL_DIVN_CD || ' ����'
  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN t.COMP_SCL_DIVN_CD || ' �߼ұ��'
  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN t.COMP_SCL_DIVN_CD || ' �߰߱��'
  		ELSE t.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE,  
  	SUM(t.INT_EXP) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_INT_EXP, 
  	SUM(t.OP_PROFIT) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_OP_PROFIT, 
  	ROUND(SUM(t.OP_PROFIT) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) / SUM(t.INT_EXP) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD), 4) as DEBT_RATIO 
FROM 
	(
	SELECT DISTINCT 
		t.STD_YM, 
		t.CORP_NO, 
		t.COMP_SCL_DIVN_CD, 
		t.INT_EXP,
		t.OP_PROFIT 
	FROM 
		INTCOVRATIO_TB t	-- ���� ���ι�ȣ�� newINDU�� ������ ���εǴ� ��� �繫�Ը� ���밳��� �� �־� �̸� ����
	) t
ORDER BY 
  	t.STD_YM;
 
 
 
 
 
/****************************************************************
 * ���ں������ : ������ ��Ȳ (p.6, [ǥ])
 * Ȱ�� ���̺� : INTCOVRATIO_TB -> INDU_INTCOVRATIO_TB ����
 ****************************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS INDU_INTCOVRATIO_TB;
-- (Step1) ���̺� ����(�����ڵ�, ��� ���ں��, ��� ��������, ���⵿�� ���ں��(����), ���⵿�� ��������(�и�)
SELECT DISTINCT
  	t0.newINDU, 
  	t0.newINDU_NM, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), INDU_INT_EXP, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_INT_EXP, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), INDU_OP_PROFIT, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_OP_PROFIT, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), INDU_INT_EXP, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_INT_EXP, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), INDU_OP_PROFIT, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_OP_PROFIT 
  	INTO INDU_INTCOVRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.newINDU, 
  		t.newINDU_NM, 
      	t.STD_YM, 
      	SUM(t.INT_EXP) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_INT_EXP, 
      	SUM(t.OP_PROFIT) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_OP_PROFIT 
    FROM 
      	INTCOVRATIO_TB t 
    WHERE 
      	t.STD_YM in (	-- ��� �� ���⵿�� ����
      		CONCAT('${inputYYYY}', '12'),
      		CONCAT('${inputYYYY}' - 1, '12'))  
  	) t0;
-- ��� ��ȸ
SELECT * FROM INDU_INTCOVRATIO_TB;


-- (Step 2) �Ѱ� ����Ͽ� insert
INSERT INTO INDU_INTCOVRATIO_TB 
SELECT 
  	'99', -- ������ INDU code '99'�Ҵ�
  	'��ü', 
  	SUM(t.thisYY_INDU_INT_EXP), 
  	SUM(t.thisYY_INDU_OP_PROFIT), 
  	SUM(t.prevYY_INDU_INT_EXP), 
  	SUM(t.prevYY_INDU_OP_PROFIT) 
FROM 
  	INDU_INTCOVRATIO_TB t;
-- ��� ��ȸ
SELECT * FROM INDU_INTCOVRATIO_TB t; 


-- (Step3) ���س�/���� ���� ��ä���� �� ���� ���� ��� ������ ���
SELECT 
  	t.*, 
  	ROUND(t.thisYY_INDU_OP_PROFIT / t.thisYY_INDU_INT_EXP, 4) as thisYY_INTCOVRATIO, 
  	ROUND(t.prevYY_INDU_OP_PROFIT / t.prevYY_INDU_INT_EXP, 4) as prevYY_INTCOVRATIO, 
  	ROUND(t.thisYY_INDU_OP_PROFIT / t.thisYY_INDU_INT_EXP - t.prevYY_INDU_OP_PROFIT / t.prevYY_INDU_INT_EXP, 4) as INTCOVRATIOINC 
FROM 
  	INDU_INTCOVRATIO_TB t 
ORDER BY 
  	t.newINDU;