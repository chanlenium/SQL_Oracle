/****************************************************************
 * ���ͼ� ��ǥ ���� - ���ڻ꿵�����ͷ�(=��������/�ڻ��Ѱ�) ���� (p.6, [�׸�4])
 * Ȱ�� ���̺� : GIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> RETURN_ON_ASSETS_TB ���̺� ����
 ****************************************************************/ 
-- (Standby) ����, �����, ����Ը� ���ڻ꿵�����ͷ� ���̺� RETURN_ON_ASSETS_TB ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS RETURN_ON_ASSETS_TB;
-- ���̺� ����(���س��, ���ι�ȣ, ����Ը�, KSIC, ��������, �ڻ��Ѱ�, EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO RETURN_ON_ASSETS_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC,
      	t1.INCOME, 
      	t1.ASSETS
    FROM 
      	(
        SELECT 
          t000.COMP_CD, 
          t000.STD_DT,
          t000.INCOME,
          t000.ASSETS 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT,
              	t00.INCOME,
              	t00.ASSETS,  
              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ��� 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.INCOME) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as INCOME, -- ��������
                  	SUM(t0.ASSETS) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as ASSETS	-- ���ڻ�
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	t.ITEM_CD,          
                      	CASE WHEN t.REPORT_CD = '12' and t.ITEM_CD = '5000' THEN t.AMT ELSE 0 END as INCOME, -- ��������
                      	CASE WHEN t.REPORT_CD = '11' and t.ITEM_CD = '5000' THEN t.AMT ELSE 0 END as ASSETS -- ���ڻ�
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	(t.REPORT_CD = '12' and t.ITEM_CD = '5000')
                      	OR (t.REPORT_CD = '11' and t.ITEM_CD = '5000')
                  	) t0 -- ��������(12/5000), ���ڻ�(11/5000) 
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
SELECT * FROM RETURN_ON_ASSETS_TB ORDER BY STD_YM;



/*************************************************
 * ����Ը�(��/��/��) ������ ���ڻ꿵�����ͷ� (1: ����, 2: �߼ұ��, 3: �߰߱��, 0: ���ƴ�)
 *************************************************/
SELECT DISTINCT 
	t.STD_YM, 
	CASE 
  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN t.COMP_SCL_DIVN_CD || ' ����'
  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN t.COMP_SCL_DIVN_CD || ' �߼ұ��'
  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN t.COMP_SCL_DIVN_CD || ' �߰߱��'
  		ELSE t.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE,  
  	SUM(t.INCOME) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_INCOME, 
  	SUM(t.ASSETS) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_ASSETS, 
  	ROUND(SUM(t.INCOME) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) / SUM(t.ASSETS) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD), 4) as RETURN_ON_ASSETS_RATIO 
FROM 
  	RETURN_ON_ASSETS_TB t 
ORDER BY 
  	t.STD_YM;
 

 

  
/****************************************************************
 * ���ڻ꿵�����ͷ� : ������ ��Ȳ (p.6, [ǥ])
 * Ȱ�� ���̺� : RETURN_ON_ASSETS_TB -> EFAS_RETURN_ON_ASSETS_TB ����
 ****************************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS EFAS_RETURN_ON_ASSETS_TB;
-- (Step1) ���̺� ����(�����ڵ�, ��� ��������, ��� ���ڻ�, ���⵿�� ��������, ���⵿�� ���ڻ�
SELECT 
  	t0.EFAS, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), EFAS_INCOME, 0)) as thisYY_EFAS_INCOME,
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), EFAS_ASSETS, 0)) as thisYY_EFAS_ASSETS, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), EFAS_INCOME, 0)) as prevYY_EFAS_INCOME,
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), EFAS_ASSETS, 0)) as prevYY_EFAS_ASSETS 
  	INTO EFAS_RETURN_ON_ASSETS_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.EFAS, 
      	t.STD_YM, 
      	SUM(t.INCOME) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_INCOME,
      	SUM(t.ASSETS) OVER(PARTITION BY t.EFAS, t.STD_YM) as EFAS_ASSETS 
    FROM 
      	RETURN_ON_ASSETS_TB t 
    WHERE 
      	t.STD_YM in (	-- ��� �� ���⵿�� ����
      		CONCAT('${inputYYYY}', '12'),
      		CONCAT('${inputYYYY}' - 1, '12')) 
  	) t0 
GROUP BY 
  	t0.EFAS;
-- ��� ��ȸ
SELECT * FROM EFAS_RETURN_ON_ASSETS_TB;


-- (Step 2) �Ѱ� ����Ͽ� insert
INSERT INTO EFAS_RETURN_ON_ASSETS_TB 
SELECT 
  	'99', -- ������ EFAS code '00'�Ҵ� 
  	SUM(t.thisYY_EFAS_INCOME), 
  	SUM(t.thisYY_EFAS_ASSETS), 
  	SUM(t.prevYY_EFAS_INCOME),
  	SUM(t.prevYY_EFAS_ASSETS) 
FROM 
  	EFAS_RETURN_ON_ASSETS_TB t;
-- ��� ��ȸ
SELECT * FROM EFAS_RETURN_ON_ASSETS_TB t; 


-- (Step3) ���س�/���� ���� ����׿������ͷ� �� ���� ���� ��� ������ ���
SELECT 
  	t.*, 
  	ROUND(t.thisYY_EFAS_INCOME / t.thisYY_EFAS_ASSETS, 4) as thisYY_RETURN_ON_ASSETS, 
  	ROUND(t.prevYY_EFAS_INCOME / t.prevYY_EFAS_ASSETS, 4) as prevYY_RETURN_ON_ASSETS, 
  	ROUND(t.thisYY_EFAS_INCOME / t.thisYY_EFAS_ASSETS - t.prevYY_EFAS_INCOME / t.prevYY_EFAS_ASSETS, 4) as RETURN_ON_ASSETS_INC 
FROM 
  	EFAS_RETURN_ON_ASSETS_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');
  	
  
--select * from tcb_nice_fnst
--select * from TCB_NICE_ACT_CD