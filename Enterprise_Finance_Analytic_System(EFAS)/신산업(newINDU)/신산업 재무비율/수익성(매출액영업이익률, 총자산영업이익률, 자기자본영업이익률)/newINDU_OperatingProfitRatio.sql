/****************************************************************
 * ���ͼ� ��ǥ ���� - ����׿������ͷ�(=��������/�����) ���� (p.6, [�׸�4])
 * Ȱ�� ���̺� : newGIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> Operating_Profit_Ratio_TB ���̺� ����
 ****************************************************************/
-- (Standby) ����, �����, ����Ը� ����׿������ͷ� ���̺� OPERATING_PROFIT_RATIO_TB ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS OPERATING_PROFIT_RATIO_TB;
-- ���̺� ����(���س��, ���ι�ȣ, ����Ը�, KSIC, newINDU, newINDU_NM, ��������, �����, EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO OPERATING_PROFIT_RATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC,
      	t2.newINDU,
      	t2.newINDU_NM,
      	t1.INCOME, 
      	t1.SALES
    FROM 
      	(
        SELECT 
          t000.COMP_CD, 
          t000.STD_DT,
          t000.INCOME,
          t000.SALES 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT,
              	t00.INCOME,
              	t00.SALES,  
              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ��� 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.INCOME) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as INCOME, -- ����ڻ�
                  	SUM(t0.SALES) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as SALES	-- �����
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	t.ITEM_CD,          
                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as INCOME, -- ��������
                      	DECODE(t.ITEM_CD, '1000', t.AMT, 0) as SALES -- �����
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	t.REPORT_CD = '12' 
                      	and t.ITEM_CD in ('1000', '5000')
                  	) t0 -- �����(1000), ��������(�ս�)(5000) 
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
      	LEFT JOIN newGIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
      			AND t2.OSIDE_ISPT_YN = 'Y'      		
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- ��� ��ȸ
SELECT * FROM OPERATING_PROFIT_RATIO_TB ORDER BY STD_YM;



/*************************************************
 * ����Ը�(��/��/��) ������ ����׿������ͷ� (1: ����, 2: �߼ұ��, 3: �߰߱��, 0: ���ƴ�)
 *************************************************/
SELECT DISTINCT 
	t.STD_YM, 
	CASE 
  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN t.COMP_SCL_DIVN_CD || ' ����'
  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN t.COMP_SCL_DIVN_CD || ' �߼ұ��'
  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN t.COMP_SCL_DIVN_CD || ' �߰߱��'
  		ELSE t.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE,  
  	SUM(t.SALES) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_SALES, 
  	SUM(t.INCOME) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_INCOME, 
  	ROUND(SUM(t.SALES) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) / SUM(t.INCOME) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD), 4) as OPERATING_PROFIT_RATIO 
FROM 
	(
	SELECT DISTINCT 
		t.STD_YM, 
		t.CORP_NO, 
		t.COMP_SCL_DIVN_CD, 
		t.INCOME,
		t.SALES 
	FROM 
		OPERATING_PROFIT_RATIO_TB t	-- ���� ���ι�ȣ�� newINDU�� ������ ���εǴ� ��� �繫�Ը� ���밳��� �� �־� �̸� ����
	) t
ORDER BY 
  	t.STD_YM;
 

 

  
/****************************************************************
 * ����׿������ͷ� : ������ ��Ȳ (p.6, [ǥ])
 * Ȱ�� ���̺� : OPERATING_PROFIT_RATIO_TB -> INDU_OPERATING_PROFIT_RATIO_TB ����
 ****************************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS INDU_OPERATING_PROFIT_RATIO_TB;
-- (Step1) ���̺� ����(�����ڵ�, ��� ��������, ��� �����, ���⵿�� ��������, ���⵿�� �����
SELECT DISTINCT
  	t0.newINDU, 
  	t0.newINDU_NM,
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), t0.INDU_INCOME, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_INCOME,
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), t0.INDU_SALES, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_SALES, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), t0.INDU_INCOME, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_INCOME,
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), t0.INDU_SALES, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_SALES 
  	INTO INDU_OPERATING_PROFIT_RATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.newINDU, 
    	t.newINDU_NM,
      	t.STD_YM, 
      	SUM(t.INCOME) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_INCOME,
      	SUM(t.SALES) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_SALES 
    FROM 
      	OPERATING_PROFIT_RATIO_TB t 
    WHERE 
      	t.STD_YM in (	-- ��� �� ���⵿�� ����
      		CONCAT('${inputYYYY}', '12'),
      		CONCAT('${inputYYYY}' - 1, '12'))  
  	) t0;
-- ��� ��ȸ
SELECT * FROM INDU_OPERATING_PROFIT_RATIO_TB;


-- (Step 2) �Ѱ� ����Ͽ� insert
INSERT INTO INDU_OPERATING_PROFIT_RATIO_TB 
SELECT 
  	'99', -- ������ newINDU code '99'�Ҵ�
  	'��ü',
  	SUM(t.thisYY_INDU_INCOME), 
  	SUM(t.thisYY_INDU_SALES), 
  	SUM(t.prevYY_INDU_INCOME),
  	SUM(t.prevYY_INDU_SALES) 
FROM 
  	INDU_OPERATING_PROFIT_RATIO_TB t;
-- ��� ��ȸ
SELECT * FROM INDU_OPERATING_PROFIT_RATIO_TB t; 


-- (Step3) ���س�/���� ���� ����׿������ͷ� �� ���� ���� ��� ������ ���
SELECT 
  	t.*, 
  	ROUND(t.thisYY_INDU_INCOME / t.thisYY_INDU_SALES, 4) as thisYY_OPERATING_PROFIT_RATIO, 
  	ROUND(t.prevYY_INDU_INCOME / t.prevYY_INDU_SALES, 4) as prevYY_OPERATING_PROFIT_RATIO, 
  	ROUND(t.thisYY_INDU_INCOME / t.thisYY_INDU_SALES - t.prevYY_INDU_INCOME / t.prevYY_INDU_SALES, 4) as OPERATING_PROFIT_RATIO_INC 
FROM 
  	INDU_OPERATING_PROFIT_RATIO_TB t 
ORDER BY 
  	t.newINDU;