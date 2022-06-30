/****************************************************************
 * ���强 ��ǥ ���� - ����׼���� ���� (p.6, [�׸�4])
 * Ȱ�� ���̺� : newGIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> SALES_TB ���̺� ����
 ****************************************************************/
-- (Standby) ����, �����, ����Ը� ����� ���̺� SALES_TB ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS SALES_TB;
-- ���̺� ���� (���س��, ���ι�ȣ, ����Ը�, KSIC, newINDU, �����, EFAS)
SELECT 
  	t10.*, 
  	t20.EFIS as EFAS
  	INTO SALES_TB 
FROM 
  	(
    SELECT DISTINCT 
    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
      	t2.CORP_NO, 
      	t2.COMP_SCL_DIVN_CD, 
      	t2.KSIC,
      	t2.newINDU,
      	t2.newINDU_NM,
      	t1.SALES
    FROM 
      	(
        SELECT 
          t00.COMP_CD, 
          t00.STD_DT,
          t00.SALES 
        FROM 
          	(
            SELECT 
              	t0.STD_YM, 
              	t0.COMP_CD, 
              	t0.STD_DT,
              	t0.SALES,  
              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ��� 
              	ROW_NUMBER() OVER(PARTITION BY t0.COMP_CD, t0.STD_DT ORDER BY t0.STD_YM DESC) as LAST_STD_YM
            FROM 
              	(
                SELECT
                	t.STD_YM, 
                    t.COMP_CD, 
                    t.STD_DT, 
                    t.AMT as SALES	-- �����
                FROM 
                  	TCB_NICE_FNST t 
                WHERE 
                   	t.REPORT_CD = '12' 
                   	AND t.ITEM_CD = '1000'	-- �����(12/5000) 
                   	AND t.STD_DT in (	 -- �ֱ� 4����
	                	CONCAT('${inputYYYY}', '1231'),
	                	CONCAT('${inputYYYY}' - 1, '1231'),
	                	CONCAT('${inputYYYY}' - 2, '1231'),
	                	CONCAT('${inputYYYY}' - 3, '1231'))  
                ) t0 
          	) t00
        WHERE 
          	t00.LAST_STD_YM = '1'
      	) t1 
      	LEFT JOIN newGIUP_RAW t2 
      		ON t1.COMP_CD = t2.COMP_CD 
      			AND t2.OSIDE_ISPT_YN = 'Y'      		
  	) t10, KSICTOEFIS66 t20 
WHERE 
  	t10.KSIC = t20.KSIC;
-- ��� ��ȸ
SELECT * FROM SALES_TB ORDER BY STD_YM;





/*************************************************
 * ����Ը�(��/��/��) ������ ����׼���� (1: ����, 2: �߼ұ��, 3: �߰߱��, 0: ���ƴ�)
 *************************************************/
SELECT 
	t00.*,
	ROUND((t00.TOT_SALES_N2 / t00.TOT_SALES_N3 - 1), 4) as SALES_GROWTH_RATE_N2,
	ROUND((t00.TOT_SALES_N1 / t00.TOT_SALES_N2 - 1), 4) as SALES_GROWTH_RATE_N1,
	ROUND((t00.TOT_SALES_N0 / t00.TOT_SALES_N1 - 1), 4) as SALES_GROWTH_RATE_N0
FROM
	(
	SELECT DISTINCT 
		CASE 
	  		WHEN t0.COMP_SCL_DIVN_CD = 1 THEN t0.COMP_SCL_DIVN_CD || ' ����'
	  		WHEN t0.COMP_SCL_DIVN_CD = 2 THEN t0.COMP_SCL_DIVN_CD || ' �߼ұ��'
	  		WHEN t0.COMP_SCL_DIVN_CD = 3 THEN t0.COMP_SCL_DIVN_CD || ' �߰߱��'
	  		ELSE t0.COMP_SCL_DIVN_CD
	  	END as BIZ_SIZE,  
	  	SUM(t0.SALES_N3) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_SALES_N3, 
	  	SUM(t0.SALES_N2) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_SALES_N2,
	  	SUM(t0.SALES_N1) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_SALES_N1,
	  	SUM(t0.SALES_N0) OVER(PARTITION BY t0.COMP_SCL_DIVN_CD) as TOT_SALES_N0
	FROM 
	    (
	    SELECT DISTINCT
			t.CORP_NO,
			t.COMP_SCL_DIVN_CD,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N3,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N2,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N1,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}', '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N0
		FROM
			(
			SELECT DISTINCT 
				t.STD_YM, 
				t.CORP_NO, 
				t.COMP_SCL_DIVN_CD, 
				t.SALES 
			FROM 
				SALES_TB t	-- ���� ���ι�ȣ�� newINDU�� ������ ���εǴ� ��� �繫�Ը� ���밳��� �� �־� �̸� ����
			) t
	  	) t0
	) t00;





/*************************************************
 * ������(EFAS) ������ ����׼����
 *************************************************/
SELECT 
	t00.*,
	ROUND((t00.TOT_SALES_N2 / t00.TOT_SALES_N3 - 1), 4) as SALES_GROWTH_RATE_N2,
	ROUND((t00.TOT_SALES_N1 / t00.TOT_SALES_N2 - 1), 4) as SALES_GROWTH_RATE_N1,
	ROUND((t00.TOT_SALES_N0 / t00.TOT_SALES_N1 - 1), 4) as SALES_GROWTH_RATE_N0
FROM
	(
	SELECT DISTINCT 
		To_CHAR(t0.newINDU) as newINDU,  
		t0.newINDU_NM, 
  		SUM(t0.SALES_N3) OVER(PARTITION BY t0.newINDU) as TOT_SALES_N3, 
  		SUM(t0.SALES_N2) OVER(PARTITION BY t0.newINDU) as TOT_SALES_N2,
  		SUM(t0.SALES_N1) OVER(PARTITION BY t0.newINDU) as TOT_SALES_N1,
  		SUM(t0.SALES_N0) OVER(PARTITION BY t0.newINDU) as TOT_SALES_N0
	FROM 
    	(
    	SELECT DISTINCT
			t.CORP_NO,
			t.newINDU,
			t.newINDU_NM,
			t.COMP_SCL_DIVN_CD,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N3,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N2,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N1,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}', '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N0
		FROM SALES_TB t
  		) t0
	UNION
	SELECT DISTINCT -- �Ѱ�
		'99',
		'��ü',
	  	SUM(t0.SALES_N3) as TOT_SALES_N3, 
	  	SUM(t0.SALES_N2) as TOT_SALES_N2,
	  	SUM(t0.SALES_N1) as TOT_SALES_N1,
	  	SUM(t0.SALES_N0) as TOT_SALES_N0
	FROM 
	    (
	    SELECT DISTINCT
			t.CORP_NO,
			t.newINDU,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 3, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N3,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 2, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N2,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}' - 1, '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N1,
			SUM(DECODE(t.STD_YM, CONCAT('${inputYYYY}', '12'), SALES, 0)) OVER(PARTITION BY t.CORP_NO) as SALES_N0
		FROM SALES_TB t
		) t0
	) t00
ORDER BY TO_NUMBER(t00.newINDU);