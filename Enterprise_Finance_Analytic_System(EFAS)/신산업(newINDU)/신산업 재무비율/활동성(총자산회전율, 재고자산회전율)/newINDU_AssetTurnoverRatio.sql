/****************************************************************
 * Ȱ���� ��ǥ ���� - ���ڻ�ȸ����(=�����/�ڻ��Ѱ�) ���� (p.6, [�׸�4])
 * Ȱ�� ���̺� : newGIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> ASSET_TURNOVER_RATIO_TB ���̺� ����
 ****************************************************************/
-- (Standby) ����, �����, ����Ը� ���ڻ�ȸ���� ���̺� ASSET_TURNOVER_RATIO_TB ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS ASSET_TURNOVER_RATIO_TB;
-- ���̺� ���� (���س��, ���ι�ȣ, ����Ը�, KSIC, newINDU, newINDU_NM, �����, ���ڻ�, EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO ASSET_TURNOVER_RATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC, 
      	t2.newINDU,
      	t2.newINDU_NM,
      	t1.SALES, 
      	t1.ASSETS 
    FROM 
      	(
        SELECT 
          t000.COMP_CD, 
          t000.STD_DT, 
          t000.SALES, 
          t000.ASSETS 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT, 
              	t00.SALES, 
              	t00.ASSETS, 
              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ��� 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.SALES) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as SALES,	-- �����
                  	SUM(t0.ASSETS) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as ASSETS -- �ڻ��Ѱ�
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	t.ITEM_CD, 
                      	DECODE(t.ITEM_CD, '1000', t.AMT, 0) as SALES, -- �����
                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as ASSETS -- �ڻ��Ѱ�
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	(t.REPORT_CD = '12' and t.ITEM_CD = '1000')
                      	OR (t.REPORT_CD = '11' and t.ITEM_CD = '5000')
                  	) t0 -- �����(1000), �ڻ��Ѱ�(5000) 
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
SELECT * FROM ASSET_TURNOVER_RATIO_TB ORDER BY STD_YM;



/*************************************************
 * ����Ը�(��/��/��) ������ ���ڻ�ȸ���� (1: ����, 2: �߼ұ��, 3: �߰߱��, 0: ���ƴ�)
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
  	SUM(t.ASSETS) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_ASSETS, 
  	ROUND(SUM(t.SALES) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) / SUM(t.ASSETS) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD), 4) as ASSET_TURNOVER_RATIO 
FROM 
	(
	SELECT DISTINCT 
		t.STD_YM, 
		t.CORP_NO, 
		t.COMP_SCL_DIVN_CD, 
		t.SALES,
		t.ASSETS 
	FROM 
		ASSET_TURNOVER_RATIO_TB t	-- ���� ���ι�ȣ�� newINDU�� ������ ���εǴ� ��� �繫�Ը� ���밳��� �� �־� �̸� ����
	) t
ORDER BY 
  	t.STD_YM;
 

 

  
/****************************************************************
 * �ڱ��ں����� : ������ ��Ȳ (p.6, [ǥ])
 * Ȱ�� ���̺� : ASSET_TURNOVER_RATIO_TB -> INDU_ASSET_TURNOVER_RATIO_TB ����
 ****************************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS INDU_ASSET_TURNOVER_RATIO_TB;
-- (Step1) ���̺� ����(�����ڵ�, ��� �ں���, ��� �ں��Ѱ�, ���⵿�� �ں���, ���⵿�� �ں��Ѱ�
SELECT DISTINCT
  	t0.newINDU, 
  	t0.newINDU_NM,
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), INDU_SALES, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_SALES, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), INDU_ASSETS, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_ASSETS, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), INDU_SALES, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_SALES, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), INDU_ASSETS, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_ASSETS 
  	INTO INDU_ASSET_TURNOVER_RATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.newINDU, 
  		t.newINDU_NM,  
      	t.STD_YM, 
      	SUM(t.SALES) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_SALES, 
      	SUM(t.ASSETS) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_ASSETS 
    FROM 
      	ASSET_TURNOVER_RATIO_TB t 
    WHERE 
      	t.STD_YM in (	-- ��� �� ���⵿�� ����
      		CONCAT('${inputYYYY}', '12'),
      		CONCAT('${inputYYYY}' - 1, '12'))   
  	) t0;
-- ��� ��ȸ
SELECT * FROM INDU_ASSET_TURNOVER_RATIO_TB;


-- (Step 2) �Ѱ� ����Ͽ� insert
INSERT INTO INDU_ASSET_TURNOVER_RATIO_TB 
SELECT 
  	'99', -- ������ EFAS code '00'�Ҵ� 
  	'��ü',
  	SUM(t.thisYY_INDU_SALES), 
  	SUM(t.thisYY_INDU_ASSETS), 
  	SUM(t.prevYY_INDU_SALES), 
  	SUM(t.prevYY_INDU_ASSETS) 
FROM 
  	INDU_ASSET_TURNOVER_RATIO_TB t;
-- ��� ��ȸ
SELECT * FROM INDU_ASSET_TURNOVER_RATIO_TB t; 


-- (Step3) ���س�/���� ���� �ڱ��ں����� �� ���� ���� ��� ������ ���
SELECT 
  	t.*, 
  	ROUND(t.thisYY_INDU_SALES / t.thisYY_INDU_ASSETS, 4) as thisYY_ASSET_TURNOVER_RATIO, 
  	ROUND(t.prevYY_INDU_SALES / t.prevYY_INDU_ASSETS, 4) as prevYY_ASSET_TURNOVER_RATIO, 
  	ROUND(t.thisYY_INDU_SALES / t.thisYY_INDU_ASSETS - t.prevYY_INDU_SALES / t.prevYY_INDU_ASSETS, 4) as ASSET_TURNOVER_RATIO_INC 
FROM 
  	INDU_ASSET_TURNOVER_RATIO_TB t 
ORDER BY 
  	t.newINDU;