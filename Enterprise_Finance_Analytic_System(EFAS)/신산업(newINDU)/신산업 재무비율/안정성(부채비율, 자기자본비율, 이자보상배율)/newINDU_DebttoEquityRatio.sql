/*****************************************************
 * ������ ��ǥ ���� - ��ä����(=��ä�Ѿ�/�ڱ��ں�) ���� (p.6, [�׸�2])
 * Ȱ�� ���̺� : newGIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> DEBT_RATIO_TB ���̺� ����
 *****************************************************/
-- (Standby) ����, �����, ����Ը� ��ä���� ���̺� ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS DEBT_RATIO_TB;
-- ���̺� ����(���س��, ���ι�ȣ, ����Ը�, KSIC, newINDU, newINDU_NM, ��ä, ���ڻ�, EFAS)
SELECT 
	t10.*, 
	t20.EFIS as EFAS
	INTO DEBT_RATIO_TB 
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
      	t1.DEBT, 
      	t1.CAPITAL 
    FROM 
    	(
        SELECT 
          	t000.COMP_CD, 
          	t000.STD_DT, 
          	t000.DEBT, 
          	t000.CAPITAL 
        FROM 
          	(
            SELECT 
              	t00.STD_YM, 
              	t00.COMP_CD, 
             	t00.STD_DT, 
              	t00.DEBT, 
              	t00.CAPITAL, 
              	-- ���� ��������(STD_DT)�� ��ϵ� �繫 �����Ͱ� ������ ���س��(STD_YM)�� �ֱ��� ������ ��� 
              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
            FROM 
              	(
                SELECT DISTINCT 
                	t0.STD_YM, 
                  	t0.COMP_CD, 
                  	t0.STD_DT, 
                  	SUM(t0.DEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as DEBT, 
                  	SUM(t0.CAPITAL) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as CAPITAL 
                FROM 
                  	(
                    SELECT 
                      	t.STD_YM, -- �����Ͱ� ���ߵ� ���
                      	t.COMP_CD, 
                      	t.STD_DT,	-- �繫������ ������
                      	t.ITEM_CD, 
                      	DECODE(t.ITEM_CD, '8000', t.AMT, 0) as DEBT, -- ��ä
                      	DECODE(t.ITEM_CD, '8900', t.AMT, 0) as CAPITAL -- �ں�
                    FROM 
                      	TCB_NICE_FNST t 
                    WHERE 
                      	t.REPORT_CD = '11' -- ��������ǥ 
                      	and t.ITEM_CD in ('8000', '8900')
                  	) t0 -- ��ä�Ѱ�(8000), �ں��Ѱ�(8900)
                WHERE 
                  	t0.STD_DT IN (	 -- �ֱ� 4����
	                	CONCAT('${inputYYYY}', '1231'),
	                	CONCAT('${inputYYYY}' - 1, '1231'),
	                	CONCAT('${inputYYYY}' - 2, '1231'),
	                	CONCAT('${inputYYYY}' - 3, '1231')) 
                ORDER BY 
                  	t0.COMP_CD, t0.STD_DT
              	) t00
          	) t000 
        WHERE 
          	t000.LAST_STD_YM = '1'	-- �ֱ� �����͸� ����
      	) t1 
      	LEFT JOIN newGIUP_RAW t2
      		ON t1.COMP_CD = t2.COMP_CD
      			AND t2.OSIDE_ISPT_YN = 'Y'
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC
  	--AND t10.OSIDE_ISPT_YN = 'Y'	-- �ܰ� ���
  	--AND t10.BLIST_MRKT_DIVN_CD in ('1', '2')	-- �ڽ���(1), �ڽ���(2)�� ����
  	AND t10.DEBT > 0; -- ���̳ʽ� ��ä ����
-- ��� ��ȸ
SELECT * FROM DEBT_RATIO_TB ORDER BY STD_YM;



/*************************************************
 * ����Ը�(��/��/��) ������ ��ä���� (1: ����, 2: �߼ұ��, 3: �߰߱��, 0: ���ƴ�)
 *************************************************/
SELECT DISTINCT 
	t.STD_YM, 
  	CASE 
  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN t.COMP_SCL_DIVN_CD || ' ����'
  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN t.COMP_SCL_DIVN_CD || ' �߼ұ��'
  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN t.COMP_SCL_DIVN_CD || ' �߰߱��'
  		ELSE t.COMP_SCL_DIVN_CD
  	END as BIZ_SIZE,
  	SUM(t.DEBT) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_DEBT, 
  	SUM(t.CAPITAL) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as TOT_CAPITAL, 
  	ROUND(SUM(t.DEBT) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) / SUM(t.CAPITAL) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD), 4) as DEBT_RATIO 
FROM 
	(
	SELECT DISTINCT 
		t.STD_YM, 
		t.CORP_NO, 
		t.COMP_SCL_DIVN_CD, 
		t.DEBT,
		t.CAPITAL 
	FROM 
		DEBT_RATIO_TB t	-- ���� ���ι�ȣ�� newINDU�� ������ ���εǴ� ��� �繫�Ը� ���밳��� �� �־� �̸� ����
	) t
ORDER BY 
  	t.STD_YM;

 
 
 
 
 /*****************************************************
 * ��ä����(=��ä�Ѿ�/�ڱ��ں�) : ������ ��Ȳ (p.6, [ǥ])
 * Ȱ�� ���̺� : DEBT_RATIO_TB -> INDU_DEBTRATIO_TB�� ����
 *****************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS INDU_DEBTRATIO_TB;
-- (Step1) ���̺� ����
SELECT DISTINCT
  	t0.newINDU, 
  	t0.newINDU_NM, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), INDU_DEBT, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_DEBT, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}', '12'), INDU_CAPITAL, 0)) OVER(PARTITION BY t0.newINDU) as thisYY_INDU_CAPITAL, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), INDU_DEBT, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_DEBT, 
  	SUM(DECODE(t0.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), INDU_CAPITAL, 0)) OVER(PARTITION BY t0.newINDU) as prevYY_INDU_CAPITAL 
  	INTO INDU_DEBTRATIO_TB 
FROM 
  	(
    SELECT DISTINCT 
    	t.newINDU, 
  		t.newINDU_NM,  
      	t.STD_YM, 
      	SUM(t.DEBT) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_DEBT,	-- ��ä
      	SUM(t.CAPITAL) OVER(PARTITION BY t.newINDU, t.STD_YM) as INDU_CAPITAL	-- �ں�
    FROM 
      	DEBT_RATIO_TB t 
    WHERE 
      	t.STD_YM in (	-- ��� �� ���⵿�� ����
      		CONCAT('${inputYYYY}', '12'),
      		CONCAT('${inputYYYY}' - 1, '12')) 
  	) t0;
-- ��� ��ȸ
SELECT * FROM INDU_DEBTRATIO_TB;


-- (Step2) �Ѱ踦 ����Ͽ� EFIS_DEBTRATIO_TB�� insert
INSERT INTO INDU_DEBTRATIO_TB 
SELECT 
  	'99', -- ������ INDU code '99'�Ҵ�
  	'��ü', 
  	SUM(t.ThisYY_INDU_DEBT), 
  	SUM(t.ThisYY_INDU_CAPITAL), 
  	SUM(t.PrevYY_INDU_DEBT), 
  	SUM(t.PrevYY_INDU_CAPITAL) 
FROM 
  	INDU_DEBTRATIO_TB t;
-- ��� ��ȸ
SELECT * FROM INDU_DEBTRATIO_TB t;


-- (Step3) ���س�/���� ���� ��ä���� �� ���� ���� ��� ������ ���
SELECT 
  	t.*, 
  	ROUND(t.thisYY_INDU_DEBT / t.thisYY_INDU_CAPITAL, 4) as thisYY_DEBITRATIO, 
  	ROUND(t.prevYY_INDU_DEBT / t.prevYY_INDU_CAPITAL, 4) as prevYY_DEBITRATIO, 
  	ROUND(t.thisYY_INDU_DEBT / t.thisYY_INDU_CAPITAL - t.prevYY_INDU_DEBT / t.prevYY_INDU_CAPITAL, 4) as DEBTRATIOINC 
FROM 
  	INDU_DEBTRATIO_TB t 
ORDER BY 
  	t.newINDU;