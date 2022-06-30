/***************************************************************************
 * �Ż�� ����������(�ܰ���� ���) : ������ �� ����Ը� ���ٺ�ä����� ��� �ۼ�              
 ***************************************************************************/



/*****************************************************
 * ���ٺ�ä��� �� ����
 * Ȱ�� ���̺� : newGIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> DEBT_RATIO_TB ���̺� ����
 *****************************************************/
-- (Standby) ����, �����, ����Ը� ��ä���� ���̺� ���� (���س��, ���ι�ȣ, ����Ը�, KSIC, ��ä, ���ڻ�, EFIS)
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS DEBT_RATIO_TB;
-- ���̺� ����
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
                  	t0.STD_DT in (	 -- �ֱ� 4����
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
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC
  	AND t10.OSIDE_ISPT_YN = 'Y'	-- �ܰ� ���
  	--AND t10.BLIST_MRKT_DIVN_CD in ('1', '2')	-- �ڽ���(1), �ڽ���(2)�� ����
  	AND t10.DEBT > 0; -- ���̳ʽ� ��ä ����
-- ��� ��ȸ
SELECT * FROM DEBT_RATIO_TB ORDER BY STD_YM;



/*****************************************************
 * ���ٺ�ä��� ����
 *****************************************************/
SELECT DISTINCT
	t00.newINDU,
	t00.newINDU_NM,
	t00.BIZ_SIZE,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), t00.OVERDEBTCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as OVERDEBTCNT_N3,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), t00.TOTBIZCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as TOTBIZCNT_N3,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), t00.OVERDEBTCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as OVERDEBTCNT_N2,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), t00.TOTBIZCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as TOTBIZCNT_N2,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), t00.OVERDEBTCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as OVERDEBTCNT_N1,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), t00.TOTBIZCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as TOTBIZCNT_N1,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}', '12'), t00.OVERDEBTCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as OVERDEBTCNT_N0,
	SUM(DECODE(t00.STD_YM, CONCAT('${inputYYYY}', '12'), t00.TOTBIZCNT, 0)) OVER(PARTITION BY t00.newINDU, t00.newINDU_NM, t00.BIZ_SIZE) as TOTBIZCNT_N0
FROM
	(
		(SELECT DISTINCT 
			t0.STD_YM, 
			t0.newINDU,
			t0.newINDU_NM,
		  	CASE 
		  		WHEN t0.COMP_SCL_DIVN_CD = 1 THEN t0.COMP_SCL_DIVN_CD || ' ����'
		  		WHEN t0.COMP_SCL_DIVN_CD = 2 THEN t0.COMP_SCL_DIVN_CD || ' �߼ұ��'
		  		WHEN t0.COMP_SCL_DIVN_CD = 3 THEN t0.COMP_SCL_DIVN_CD || ' �߰߱��'
		  		ELSE t0.COMP_SCL_DIVN_CD
		  	END as BIZ_SIZE, 
		  	SUM(t0.isOVERDEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD, t0.newINDU) as OVERDEBTCNT, -- ����Ը� ���ٺ�ä ��� ��
		  	COUNT(t0.CORP_NO) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD, t0.newINDU) as TOTBIZCNT  -- ����Ը� ��ü ��� ��
		FROM 
		  	(
		    SELECT 
		      	t.STD_YM, 
		      	t.CORP_NO, 
		      	t.COMP_SCL_DIVN_CD, 
		      	t.newINDU,
		      	t.newINDU_NM,
		      	CASE -- Dvision by zero ȸ��
		      		WHEN (t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL)) >= 2 THEN 1 ELSE 0 
		      	END as isOVERDEBT -- ��ä������ 200% �̻��̸� 1, �ƴϸ� 0���� ���ڵ�
		    FROM 
		      	DEBT_RATIO_TB t
		  	) t0 
		WHERE t0.COMP_SCL_DIVN_CD in ('1', '2', '3')
		ORDER BY 
		  	t0.STD_YM)
		UNION
		(SELECT DISTINCT -- ��ü �հ� ���
			t0.STD_YM, 
			t0.newINDU,
			t0.newINDU_NM,
		  	'��ü' as BIZ_SIZE, 
		  	SUM(t0.isOVERDEBT) OVER(PARTITION BY t0.STD_YM, t0.newINDU) as OVERDEBTCNT, -- ����Ը� ���ٺ�ä ��� ��
		  	COUNT(t0.CORP_NO) OVER(PARTITION BY t0.STD_YM, t0.newINDU) as TOTBIZCNT  -- ����Ը� ��ü ��� ��
		FROM 
		  	(
		    SELECT 
		      	t.STD_YM, 
		      	t.CORP_NO, 
		      	t.COMP_SCL_DIVN_CD, 
		      	t.newINDU,
		      	t.newINDU_NM,
		      	CASE -- Dvision by zero ȸ��
		      		WHEN (t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL)) >= 2 THEN 1 ELSE 0 
		      	END as isOVERDEBT -- ��ä������ 200% �̻��̸� 1, �ƴϸ� 0���� ���ڵ�
		    FROM 
		      	DEBT_RATIO_TB t
		  	) t0 
		WHERE t0.COMP_SCL_DIVN_CD in ('1', '2', '3')
		ORDER BY 
		  	t0.STD_YM)
  	) t00
ORDER BY t00.newINDU, t00.BIZ_SIZE;