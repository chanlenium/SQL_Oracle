/****************************************************************
 * ������ ��ǥ ���� - �ڱ��ں�����(=�ں�/���ں�) ���� (p.6, [�׸�4])
 * Ȱ�� ���̺� : GIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> EQUITYRATIO_TB ���̺� ����
 ****************************************************************/
-- (Standby) ����, �����, ����Ը� ���ں������ ���̺� EQUITYRATIO_TB ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS EQUITYRATIO_TB;
-- ���̺� ���� (���س��, ���ι�ȣ, ����Ը�, KSIC, �ں���, �ں��Ѱ�, EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO EQUITYRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC, 
      	t1.CAP_STOCK, 
      	t1.TOT_STOCK 
    FROM 
      	(
        SELECT 
          t000.COMP_CD, 
          t000.STD_DT, 
          t000.CAP_STOCK, 
          t000.TOT_STOCK 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT, 
              	t00.CAP_STOCK, 
              	t00.TOT_STOCK, 
              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ��� 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.CAP_STOCK) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as CAP_STOCK,	-- �ں���
                  	SUM(t0.TOT_STOCK) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as TOT_STOCK -- �ں��Ѱ�
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	t.ITEM_CD, 
                      	DECODE(t.ITEM_CD, '8100', t.AMT, 0) as CAP_STOCK, -- �ں���
                      	DECODE(t.ITEM_CD, '8900', t.AMT, 0) as TOT_STOCK -- �ں��Ѱ�(���ڻ�)
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	t.REPORT_CD = '11' 
                      	and t.ITEM_CD in ('8100', '8900')
                  	) t0 -- �ں���(8100), �ں��Ѱ�(8900) 
                WHERE 
                  	t0.STD_DT in (	 -- �ֱ� 4����
	                	CONCAT('${inputYYYY}', '1231'),
	                	CONCAT('${inputYYYY}' - 1, '1231'),
	                	CONCAT('${inputYYYY}' - 2, '1231'),
	                	CONCAT('${inputYYYY}' - 3, '1231'))  
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN GIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
      			AND t2.OSIDE_ISPT_YN = 'Y'
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- ��� ��ȸ
SELECT * FROM EQUITYRATIO_TB ORDER BY STD_YM;



/*************************************************
 * ����Ը�(��/��/��) ������ �ڱ��ں����� (1: ����, 2: �߼ұ��, 3: �߰߱��, 0: ���ƴ�)
 *************************************************/
SELECT DISTINCT 
	t.STD_YM, 
	CASE 
  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN t.COMP_SCL_DIVN_CD || ' ����'
  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN t.COMP_SCL_DIVN_CD || ' �߼ұ��'
  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN t.COMP_SCL_DIVN_CD || ' �߰߱��'
  		ELSE t.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE,  
  	SUM(t.CAP_STOCK) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_CAP_STOCK, 
  	SUM(t.TOT_STOCK) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_TOT_STOCK, 
  	ROUND(SUM(t.CAP_STOCK) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) / SUM(t.TOT_STOCK) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD), 4) as CAPITAL_ADEQUACY_RATIO 
FROM 
  	EQUITYRATIO_TB t 
ORDER BY 
  	t.STD_YM;
 

 

  
/****************************************************************
 * �ڱ��ں����� : ������ ��Ȳ (p.6, [ǥ])
 * Ȱ�� ���̺� : EQUITYRATIO_TB -> EFAS_EQUITYRATIO_TB ����
 ****************************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS EFAS_EQUITYRATIO_TB;
-- (Step1) ���̺� ����(�����ڵ�, ��� �ں���, ��� �ں��Ѱ�, ���⵿�� �ں���, ���⵿�� �ں��Ѱ�
SELECT 
  	t0.EFAS, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), EFAS_CAP_STOCK, 0)) as thisYY_EFAS_CAP_STOCK, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), EFAS_TOT_STOCK, 0)) as thisYY_EFAS_TOT_STOCK, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), EFAS_CAP_STOCK, 0)) as prevYY_EFAS_CAP_STOCK, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), EFAS_TOT_STOCK, 0)) as prevYY_EFAS_TOT_STOCK 
  	INTO EFAS_EQUITYRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.EFAS, 
      	t.STD_YM, 
      	SUM(t.CAP_STOCK) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_CAP_STOCK, 
      	SUM(t.TOT_STOCK) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_TOT_STOCK 
    FROM 
      	EQUITYRATIO_TB t 
    WHERE 
      	t.STD_YM in (	-- ��� �� ���⵿�� ����
      		CONCAT('${inputYYYY}', '12'),
      		CONCAT('${inputYYYY}' - 1, '12'))
  	) t0 
GROUP BY 
  	t0.EFAS;
-- ��� ��ȸ
SELECT * FROM EFAS_EQUITYRATIO_TB;


-- (Step 2) �Ѱ� ����Ͽ� insert
INSERT INTO EFAS_EQUITYRATIO_TB 
SELECT 
  	'99', -- ������ EFAS code '00'�Ҵ� 
  	SUM(t.thisYY_EFAS_CAP_STOCK), 
  	SUM(t.thisYY_EFAS_TOT_STOCK), 
  	SUM(t.prevYY_EFAS_CAP_STOCK), 
  	SUM(t.prevYY_EFAS_TOT_STOCK) 
FROM 
  	EFAS_EQUITYRATIO_TB t;
-- ��� ��ȸ
SELECT * FROM EFAS_EQUITYRATIO_TB t; 


-- (Step3) ���س�/���� ���� �ڱ��ں����� �� ���� ���� ��� ������ ���
SELECT 
  	t.*, 
  	ROUND(t.thisYY_EFAS_CAP_STOCK / t.thisYY_EFAS_TOT_STOCK, 4) as thisYY_CAPITAL_ADEQUACY_RATIO, 
  	ROUND(t.prevYY_EFAS_CAP_STOCK / t.prevYY_EFAS_TOT_STOCK, 4) as prevYY_CAPITAL_ADEQUACY_RATIO, 
  	ROUND(t.thisYY_EFAS_CAP_STOCK / t.thisYY_EFAS_TOT_STOCK - t.prevYY_EFAS_CAP_STOCK / t.prevYY_EFAS_TOT_STOCK, 4) as CAPITAL_ADEQUACY_RATIO_INC 
FROM 
  	EFAS_EQUITYRATIO_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');