/*****************************************************
 * �Ż�� ������ ��ǥ ���� - �Ѱ��� ���� (p.6, [�׸�5])
 * (����1) �����ٳ⵵ ��������, (����2) 2�� ���� ��������, (����3) 3�� ���� ��������
 *****************************************************/
-- (Step1) TCB_NICE_FNST, newGIUP_RAW -> OP_PROFIT_TB ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS OP_PROFIT_TB;
-- ���̺� ����(���س��, ���ι�ȣ, ����Ը�, �ܰ�����, ���屸��, KSIC, �Ż���ڵ�, �Ż����, ��������(�ս�), EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO OP_PROFIT_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.OSIDE_ISPT_YN,
      	t2.BLIST_MRKT_DIVN_CD,
      	t2.KSIC, 
      	t2.newINDU,
      	t2.newINDU_NM,
      	t1.OPPROFIT 
    FROM 
      	(
        SELECT 
          	t000.COMP_CD, 
          	t000.STD_DT, 
          	t000.OPPROFIT 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT, 
              	t00.OPPROFIT, 
              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ���
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.OPPROFIT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as OPPROFIT -- ��������
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as OPPROFIT -- ��������(�ս�)
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	t.REPORT_CD = '12' AND t.ITEM_CD = '5000'
                      	AND t.STD_DT in (	 -- �ֱ� 5����
	                			CONCAT('${inputYYYY}', '1231'),
	                			CONCAT('${inputYYYY}' - 1, '1231'),
	                			CONCAT('${inputYYYY}' - 2, '1231'),
	                			CONCAT('${inputYYYY}' - 3, '1231'),
	                			CONCAT('${inputYYYY}' - 4, '1231'))
                  	) t0                   	
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN newGIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
    ORDER BY 
      	t2.CORP_NO, 
      	SUBSTR(t1.STD_DT, 1, 6)
  	) t10, 
  	KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC
  	AND t10.OSIDE_ISPT_YN = 'Y';	-- �ܰ� ���
-- ��� ��ȸ
SELECT * FROM OP_PROFIT_TB;

  
    
-- (Step2) OP_PROFIT_TB -> newINDU_OP_PROFIT_TB ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS newINDU_OP_PROFIT_TB;
-- ���̺� ����
SELECT DISTINCT 
	t0000.STD_YM, 
  	t0000.newINDU,
  	t0000.newINDU_NM,
  	CASE 
		WHEN t0000.COMP_SCL_DIVN_CD = 1 THEN t0000.COMP_SCL_DIVN_CD || ' ����'
		WHEN t0000.COMP_SCL_DIVN_CD = 2 THEN t0000.COMP_SCL_DIVN_CD || ' �߼ұ��'
		WHEN t0000.COMP_SCL_DIVN_CD = 3 THEN t0000.COMP_SCL_DIVN_CD || ' �߰߱��'
	ELSE t0000.COMP_SCL_DIVN_CD
	END as BIZ_SIZE,
  	SUM(CASE WHEN t0000.CONTLOSSYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N1_LOSS,	-- 1���� ���� �����
  	SUM(CASE WHEN t0000.CONTLOSSYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N2_LOSS, 	-- 2���� ���� ���� �����
  	SUM(CASE WHEN t0000.CONTLOSSYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N3_LOSS, 	-- 3���� ���� ���� �����
  	COUNT(t0000.CORP_NO) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNTTOTCORP	-- ��ü�����
  	INTO newINDU_OP_PROFIT_TB
FROM 
  	(
    SELECT 
      t000.*, 
      CASE WHEN t000.OPPROFIT < 0 THEN 
      	CASE WHEN t000.N_1_OPPROFIT < 0 THEN 
      		CASE WHEN t000.N_2_OPPROFIT < 0 THEN 3 -- 3�⿬�� ���� 
      		ELSE 2 -- 2�⿬�� ����
      	END ELSE 1 -- �����ٳ⵵ ����
      END ELSE 0 END as CONTLOSSYY -- ���� ���� ���
    FROM 
      	(
        SELECT DISTINCT 
        	t00.STD_YM, 
          	t00.CORP_NO, 
         	t00.COMP_SCL_DIVN_CD, 
          	t00.EFAS, 
          	t00.newINDU,
          	t00.newINDU_NM,
          	t00.OPPROFIT, -- �����ٳ⵵ ��������(�ս�)
          	t00.N_1_OPPROFIT,	-- 2���� ��������(�ս�)
          	t00.N_2_OPPROFIT -- 3���� ��������(�ս�)
        FROM 
          	(
            SELECT 
              	t10.*, 
              	t20.OPPROFIT as N_2_OPPROFIT -- 3���� ��������(�ս�)
            FROM 
              	(
                SELECT 
                  	t1.*, 
                  	t2.OPPROFIT as N_1_OPPROFIT -- 2���� ��������(�ս�)
                FROM 
                  	OP_PROFIT_TB t1 
                  	LEFT JOIN OP_PROFIT_TB t2 
                  		ON t1.CORP_NO = t2.CORP_NO 
                  		AND TO_NUMBER(t1.STD_YM) -100 = TO_NUMBER(t2.STD_YM)
              	) t10 
              	LEFT JOIN OP_PROFIT_TB t20 
              		ON t10.CORP_NO = t20.CORP_NO 
              		AND TO_NUMBER(t10.STD_YM) -200 = TO_NUMBER(t20.STD_YM)
          	) t00 
        WHERE 
          	t00.STD_YM in (	 -- �ֱ� 3����
	        	CONCAT('${inputYYYY}', '12'),
	            CONCAT('${inputYYYY}' - 1, '12'),
	            CONCAT('${inputYYYY}' - 2, '12'))
      	) t000
  	) t0000;
-- ��� ��ȸ
SELECT * FROM newINDU_OP_PROFIT_TB ORDER BY STD_YM, newINDU, BIZ_SIZE;


-- (Step3) �Ѱ� ����Ͽ� insert
INSERT INTO newINDU_OP_PROFIT_TB 
SELECT DISTINCT
	t.STD_YM,
  	t.newINDU,
  	t.newINDU_NM,
  	'99 ��ü' as BIZ_SIZE,	-- ��/��/�� ���� 
  	SUM(t.CNT_N1_LOSS) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N1_LOSS, 
  	SUM(t.CNT_N2_LOSS) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N2_LOSS, 
  	SUM(t.CNT_N3_LOSS) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N3_LOSS,
  	SUM(t.CNTTOTCORP) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNTTOTCORP
FROM 
  	newINDU_OP_PROFIT_TB t;
-- ��� ��ȸ
SELECT * FROM newINDU_OP_PROFIT_TB t ORDER BY t.STD_YM, t.newINDU, t.BIZ_SIZE;






  
  
  
  
  
/*****************************************************
 * ������ ��ǥ ���� - �Ѱ��� ���� (p.6, [�׸�5])
 * (����4) �����ٳ⵵ ���ں������ 1�̸�, (����5) 2�⿬�� ���ں������ 1�̸�, (����6) 3�⿬�� ���ں������ 1�̸�
 * Ȱ�� ���̺� : TCB_NICE_FNST, newGIUP_RAW -> InterestCoverageRatio_TB ����
 *****************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS InterestCoverageRatio_TB;
-- (Standby) InterestCoverageRatio_TB ���̺� ����(���س��, ���ι�ȣ, ����Ը�, KSIC, ��������(�ս�), �����ڵ�)�� ����
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO InterestCoverageRatio_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
     	t2.COMP_SCL_DIVN_CD, 
     	t2.OSIDE_ISPT_YN,
      	t2.BLIST_MRKT_DIVN_CD,
      	t2.KSIC,
      	t2.newINDU,
      	t2.newINDU_NM,
      	t1.OPPROFIT, 
      	t1.INTEXP, 
      	ROUND(t1.OPPROFIT / DECODE(t1.INTEXP, 0, 1, t1.INTEXP), 2) as INTCOVRATIO 
    FROM 
      	(
        SELECT 
          	t000.COMP_CD, 
          	t000.STD_DT, 
          	t000.INTEXP, 
          	t000.OPPROFIT 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
              	t00.STD_DT, 
              	t00.INTEXP, 
              	t00.OPPROFIT, 
              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ��� 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.INTEXP) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as INTEXP,	-- ���ں��
                  	SUM(t0.OPPROFIT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as OPPROFIT -- ��������
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, 
                      	t.COMP_CD, 
                      	t.STD_DT, 
                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as OPPROFIT,	-- ��������(�ս�)
                      	DECODE(t.ITEM_CD, '6110', t.AMT, 0) as INTEXP	-- ��������(�ս�)
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	t.REPORT_CD = '12' 
                      	AND t.ITEM_CD in ('5000', '6110') -- ��������(5000), ���ں��(6110) 
                      	AND t.STD_DT in (	 -- �ֱ� 5����
	                		CONCAT('${inputYYYY}', '1231'),
	                		CONCAT('${inputYYYY}' - 1, '1231'),
	                		CONCAT('${inputYYYY}' - 2, '1231'),
	                		CONCAT('${inputYYYY}' - 3, '1231'),
	                		CONCAT('${inputYYYY}' - 4, '1231'))
                  	) t0
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN newGIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
  	) t10, 
  	KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC
  	AND t10.OSIDE_ISPT_YN = 'Y';	-- �ܰ� ���;
-- ��� ��ȸ
SELECT * FROM InterestCoverageRatio_TB; 


  
-- (Step2) InterestCoverageRatio_TB -> newINDU_InterestCoverageRatio_TB ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS newINDU_InterestCoverageRatio_TB;
-- ���̺� ����
SELECT DISTINCT 
	t0000.STD_YM, 
  	t0000.newINDU,
    t0000.newINDU_NM,
    CASE 
		WHEN t0000.COMP_SCL_DIVN_CD = 1 THEN t0000.COMP_SCL_DIVN_CD || ' ����'
		WHEN t0000.COMP_SCL_DIVN_CD = 2 THEN t0000.COMP_SCL_DIVN_CD || ' �߼ұ��'
		WHEN t0000.COMP_SCL_DIVN_CD = 3 THEN t0000.COMP_SCL_DIVN_CD || ' �߰߱��'
		ELSE t0000.COMP_SCL_DIVN_CD
	END as BIZ_SIZE,
  	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N1_UNDERINTCOV, 
  	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N2_UNDERINTCOV, 
  	SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNT_N3_UNDERINTCOV,
  	COUNT(t0000.CORP_NO) OVER(PARTITION BY t0000.STD_YM, t0000.newINDU, t0000.COMP_SCL_DIVN_CD) as CNTTOTCORP
  	INTO newINDU_InterestCoverageRatio_TB
FROM 
  	(
    SELECT 
      	t000.*, 
      	CASE WHEN t000.INTCOVRATIO < 1 THEN 
      		CASE WHEN t000.N_1_INTCOVRATIO < 1 THEN 
      			CASE WHEN t000.N_2_INTCOVRATIO < 1 THEN 3 -- 3�⿬�� ���ں������� 1�̸�
      				ELSE 2 -- 2�⿬�� ���ں������� 1�̸�
      			END ELSE 1 -- �����ٳ⵵ ���ں������� 1�̸�
      		END ELSE 0 
      	END as CONTUNDERINTCOVYY -- ���� ���ں������� 1�̸� ���
    FROM 
      	(
        SELECT DISTINCT 
        	t00.STD_YM, 
          	t00.CORP_NO, 
          	t00.COMP_SCL_DIVN_CD, 
          	t00.EFAS, 
          	t00.newINDU,
      		t00.newINDU_NM,
          	t00.INTCOVRATIO, 
          	t00.N_1_INTCOVRATIO, 
          	t00.N_2_INTCOVRATIO 
        FROM 
          	(
            SELECT 
              	t10.*, 
              	t20.INTCOVRATIO as N_2_INTCOVRATIO 
            FROM 
              	(
                SELECT 
                  	t1.*, 
                  	t2.INTCOVRATIO as N_1_INTCOVRATIO 
                FROM 
                  	InterestCoverageRatio_TB t1 
                  	LEFT JOIN InterestCoverageRatio_TB t2 
                  		ON t1.CORP_NO = t2.CORP_NO 
                  		AND TO_NUMBER(t1.STD_YM) -100 = TO_NUMBER(t2.STD_YM)
              	) t10 
              	LEFT JOIN InterestCoverageRatio_TB t20 
              		ON t10.CORP_NO = t20.CORP_NO 
              		AND TO_NUMBER(t10.STD_YM) -200 = TO_NUMBER(t20.STD_YM)
          	) t00 
        WHERE 
          	t00.STD_YM in (	 -- �ֱ� 3����
	        	CONCAT('${inputYYYY}', '12'),
	            CONCAT('${inputYYYY}' - 1, '12'),
	            CONCAT('${inputYYYY}' - 2, '12'))
      	) t000
  	) t0000;
-- ��� ��ȸ
SELECT * FROM newINDU_InterestCoverageRatio_TB ORDER BY STD_YM, newINDU;


-- (Step3) �Ѱ� ����Ͽ� insert
INSERT INTO newINDU_InterestCoverageRatio_TB 
SELECT DISTINCT 
	t.STD_YM,
	t.newINDU,
	t.newINDU_NM,
  	'��ü' as BIZ_SIZE, 
  	SUM(t.CNT_N1_UNDERINTCOV) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N1_UNDERINTCOV, 
  	SUM(t.CNT_N2_UNDERINTCOV) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N2_UNDERINTCOV,
  	SUM(t.CNT_N3_UNDERINTCOV) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNT_N3_UNDERINTCOV,
  	SUM(t.CNTTOTCORP) OVER(PARTITION BY t.STD_YM, t.newINDU) as CNTTOTCORP
FROM 
  	newINDU_InterestCoverageRatio_TB t;
-- ��� ��ȸ
SELECT * FROM newINDU_InterestCoverageRatio_TB ORDER BY STD_YM, newINDU;