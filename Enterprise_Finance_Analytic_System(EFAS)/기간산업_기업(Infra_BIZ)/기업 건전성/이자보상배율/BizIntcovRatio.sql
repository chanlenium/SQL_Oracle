/****************************************************************
 * ������ ��ǥ ���� - ���ں������(=��������/���ں��) ���� (p.6, [�׸�4])
 * Ȱ�� ���̺� : GIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> INTCOVRATIO_TB ���̺� ����
 ****************************************************************/
-- (Standby) ����, �����, ����Ը� ���ں������ ���̺� INTCOVRATIO_TB ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS INTCOVRATIO_TB;
-- ���̺� ���� (���س��, ���ι�ȣ, ����Ը�, KSIC, ��������, ���ں��, EFAS)
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
	                CAST(t0.STD_DT AS INTEGER)  IN (		-- �ֱ� 4����
	                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER),
	                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 10000,
	                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 20000,
	                	CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 30000)
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN GIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- ��� ��ȸ
SELECT * FROM INTCOVRATIO_TB ORDER BY STD_YM;


-- ���ں������ ���� �׷��� (��/��/��) (1: ����, 2: �߼ұ��, 3: �߰߱��, 0: ���ƴ�)
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
  	INTCOVRATIO_TB t 
WHERE 
	CAST(t.STD_YM AS INTEGER) <= ${inputGG_YM}
ORDER BY 
  	t.STD_YM;
 
 
 
 
 
/****************************************************************
 * ���ں������ : ������ ��Ȳ (p.6, [ǥ])
 * Ȱ�� ���̺� : INTCOVRATIO_TB -> EFAS_INTCOVRATIO_TB ����
 ****************************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS EFAS_INTCOVRATIO_TB;
-- (Step1) ���̺� ����(�����ڵ�, ��� ���ں��, ��� ��������, ���⵿�� ���ں��(����), ���⵿�� ��������(�и�)
SELECT 
  	t0.EFAS, 
  	SUM(DECODE(t0.STD_YM, CONCAT( '${inputYYYY}', '12'), EFAS_INT_EXP, 0)) as thisYY_EFAS_INT_EXP, 
  	SUM(DECODE(t0.STD_YM, CONCAT( '${inputYYYY}', '12'), EFAS_OP_PROFIT, 0)) as thisYY_EFAS_OP_PROFIT, 
  	SUM(DECODE(t0.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), EFAS_INT_EXP, 0)) as prevYY_EFAS_INT_EXP, 
  	SUM(DECODE(t0.STD_YM, CONCAT(CAST('${inputYYYY}' - 1 as VARCHAR), '12'), EFAS_OP_PROFIT, 0)) as prevYY_EFAS_OP_PROFIT 
  	INTO EFAS_INTCOVRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.EFAS, 
      	t.STD_YM, 
      	SUM(t.INT_EXP) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_INT_EXP, 
      	SUM(t.OP_PROFIT) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_OP_PROFIT 
    FROM 
      	INTCOVRATIO_TB t 
    WHERE 
      	CAST(t.STD_YM AS INTEGER) IN (	-- ��� �� ���� ����
    			CAST(CONCAT( '${inputYYYY}', '12') as integer),
    			CAST(CONCAT( '${inputYYYY}', '12') as integer) - 100) 
  	) t0 
GROUP BY 
  	t0.EFAS;
-- ��� ��ȸ
SELECT * FROM EFAS_INTCOVRATIO_TB;


-- (Step 2) �Ѱ� ����Ͽ� insert
INSERT INTO EFAS_INTCOVRATIO_TB 
SELECT 
  	'99', -- ������ EFAS code '00'�Ҵ� 
  	SUM(t.thisYY_EFAS_INT_EXP), 
  	SUM(t.thisYY_EFAS_OP_PROFIT), 
  	SUM(t.prevYY_EFAS_INT_EXP), 
  	SUM(t.prevYY_EFAS_OP_PROFIT) 
FROM 
  	EFAS_INTCOVRATIO_TB t;
-- ��� ��ȸ
SELECT * FROM EFAS_INTCOVRATIO_TB t; 


-- (Step3) ���س�/���� ���� ��ä���� �� ���� ���� ��� ������ ���
SELECT 
  	t.*, 
  	ROUND(t.thisYY_EFAS_OP_PROFIT / t.thisYY_EFAS_INT_EXP, 4) as thisYY_INTCOVRATIO, 
  	ROUND(t.prevYY_EFAS_OP_PROFIT / t.prevYY_EFAS_INT_EXP, 4) as prevYY_INTCOVRATIO, 
  	ROUND(t.thisYY_EFAS_OP_PROFIT / t.thisYY_EFAS_INT_EXP - t.prevYY_EFAS_OP_PROFIT / t.prevYY_EFAS_INT_EXP, 4) as INTCOVRATIOINC 
FROM 
  	EFAS_INTCOVRATIO_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');