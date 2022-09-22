/****************************************************************
 * �Ż�� ���� - �Ż���� �濵���� ���� (p.7, [�׸�2])
 * Ȱ�� ���̺� : newGIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> SALES_TB ���̺� ����
 ****************************************************************/
-- (Standby) ����, �����, ����Ը� ����� ���̺� SALES_TB ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS SALES_TB;
-- (Step1) ���̺� ����(���س��, ���ι�ȣ, ����Ը�, �ܰ�����, ���屸���ڵ�, KSIC, ��걸��, �����, EFAS)
SELECT 
	t0.STD_YM,
	t0.CORP_NO,
	t0.COMP_SCL_DIVN_CD,
	t0.OSIDE_ISPT_YN,
	t0.BLIST_MRKT_DIVN_CD,
	t0.KSIC,
	t0.newINDU,
	t0.newINDU_NM,
	t0.SEAC_DIVN,
  	t0.SALES, 
  	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
  	INTO SALES_TB 
FROM(
	SELECT DISTINCT
		t1000.*,
		t2000.EFAS_CD as EFAS_2
	FROM(
		SELECT DISTINCT
			t100.*,
			t200.EFAS_CD as EFAS_3
		FROM(
			SELECT 
				t10.*, 
				t20.EFAS_CD as EFAS_4
			FROM 
			  	(
			    SELECT DISTINCT 
			    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
			      	t1.SEAC_DIVN,
			      	t2.CORP_NO, 
			      	t2.COMP_SCL_DIVN_CD, 
			      	t2.OSIDE_ISPT_YN,
			      	t2.BLIST_MRKT_DIVN_CD,
			      	t2.KSIC, 
			      	t2.newINDU,
					t2.newINDU_NM,
			      	t1.SALES
			    FROM 
			    	(
			    	SELECT 
			    		t000.COMP_CD, 
			          	t000.SEAC_DIVN,
			          	t000.STD_DT, 
			          	t000.SALES 
			    	FROM
				  		(	
				        SELECT 
				      		t00.STD_YM, 
					      	t00.COMP_CD, 
					      	t00.SEAC_DIVN,
					     	t00.STD_DT,
					     	t00.SALES,  
					     	-- ���� ��������(STD_DT)�� ��ϵ� �繫 �����Ͱ� ������ ���س��(STD_YM)�� �ֱ��� ������ ��� 
				          	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
				        FROM 
				          	(
				            SELECT 
				              	t0.STD_YM, 
				              	t0.COMP_CD, 
				              	t0.SEAC_DIVN,
				              	t0.STD_DT,
				              	t0.SALES
				            FROM 
				              	(
				                SELECT
				                	t.STD_YM, 
				                    t.COMP_CD, 
				                    t.SEAC_DIVN,	-- ��걸�� (K: ���, B: �ݱ�, F: 1/4�б�, T: 3/4�б�)
				                    t.STD_DT, 	-- �繫������ ������
				                    t.AMT as SALES	-- �����
				                FROM 
				                  	TCB_NICE_FNST t 
				                WHERE 
				                   	t.REPORT_CD = '12' 
				                   	AND t.ITEM_CD = '1000'	-- �����(12/5000) 
				                ) t0 
				            WHERE 
				            	CAST(t0.STD_DT AS INTEGER)  IN (	-- �ֱ� 5���� �ڷ� ����
				            		CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER),
				            		CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER),
				            		CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER),
				            		CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER),
				            		CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 10000,
				            		CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 10000,
				            		CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 10000,
				            		CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 10000,
				            		CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 20000,
				            		CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 20000,
				            		CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 20000,
				            		CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 20000,
				            		CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 30000,
				            		CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 30000,
				            		CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 30000,
				            		CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 30000,
				            		CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 40000,
				            		CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 40000,
				            		CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 40000,
				            		CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 40000)
				            ORDER BY 
				              	t0.COMP_CD, t0.STD_DT
				          	) t00
				      	) t000 
				    WHERE 
						t000.LAST_STD_YM = '1'	-- �ֱ� �����͸� ����
					) t1
			      	LEFT JOIN newGIUP_RAW t2 
			      		ON t1.COMP_CD = t2.COMP_CD 
			      			AND t2.OSIDE_ISPT_YN = 'Y'	-- �ܰ� ���      		
			  	) t10
				LEFT JOIN EFASTOKSIC66 t20 
					ON SUBSTR(t10.KSIC, 1, 4) = t20.KSIC	-- KSIC 4�ڸ��� ����
			) t100
			LEFT JOIN EFASTOKSIC66 t200
				ON SUBSTR(t100.KSIC, 1, 3) = t200.KSIC	-- KSIC 3�ڸ��� ����
		)t1000
	  	LEFT JOIN EFASTOKSIC66 t2000
			ON SUBSTR(t1000.KSIC, 1, 2) = t2000.KSIC	-- KSIC 2�ڸ��� ����
	) t0
WHERE t0.KSIC is not NULL and NVL(EFAS, '') <> '55';	-- ��������� ����		  	
-- ��� ��ȸ
SELECT * FROM SALES_TB ORDER BY STD_YM;



/*************************************************
 * (Step2) �Ż���� ������ �б⺰ �����
 *************************************************/
SELECT DISTINCT
	t000.STD_YM,
	SUM(t000.newINDU_SALES_1) OVER(PARTITION BY t000.STD_YM) as '1 ����������',
	SUM(t000.newINDU_SALES_2) OVER(PARTITION BY t000.STD_YM) as '2 IOT����',
	SUM(t000.newINDU_SALES_3) OVER(PARTITION BY t000.STD_YM) as '3 ����Ʈ �ｺ�ɾ�',
	SUM(t000.newINDU_SALES_4) OVER(PARTITION BY t000.STD_YM) as '4 ���̿��ž�',
	SUM(t000.newINDU_SALES_5) OVER(PARTITION BY t000.STD_YM) as '5 ������ݵ�ü',
	SUM(t000.newINDU_SALES_6) OVER(PARTITION BY t000.STD_YM) as '6 ��������÷���',
	SUM(t000.newINDU_SALES_7) OVER(PARTITION BY t000.STD_YM) as '7 �����������',
	SUM(t000.newINDU_SALES_8) OVER(PARTITION BY t000.STD_YM) as '8 ESS',
	SUM(t000.newINDU_SALES_9) OVER(PARTITION BY t000.STD_YM) as '9 ����Ʈ�׸���',
	SUM(t000.newINDU_SALES_10) OVER(PARTITION BY t000.STD_YM) as '10 ������'
FROM
	(
	SELECT 
		t00.*,
		DECODE(t00.newINDU_NM, '����������', t00.newINDU_SALES, 0) as newINDU_SALES_1,
		DECODE(t00.newINDU_NM, 'IOT ����', t00.newINDU_SALES, 0) as newINDU_SALES_2,
		DECODE(t00.newINDU_NM, '����Ʈ �ｺ�ɾ�', t00.newINDU_SALES, 0) as newINDU_SALES_3,
		DECODE(t00.newINDU_NM, '���̿��ž�', t00.newINDU_SALES, 0) as newINDU_SALES_4,
		DECODE(t00.newINDU_NM, '������ݵ�ü', t00.newINDU_SALES, 0) as newINDU_SALES_5,
		DECODE(t00.newINDU_NM, '��������÷���', t00.newINDU_SALES, 0) as newINDU_SALES_6,
		DECODE(t00.newINDU_NM, '�����������', t00.newINDU_SALES, 0) as newINDU_SALES_7,
		DECODE(t00.newINDU_NM, 'ESS', t00.newINDU_SALES, 0) as newINDU_SALES_8,
		DECODE(t00.newINDU_NM, '����Ʈ�׸���', t00.newINDU_SALES, 0) as newINDU_SALES_9,
		DECODE(t00.newINDU_NM, '������', t00.newINDU_SALES, 0) as newINDU_SALES_10
	FROM 	
		(
		SELECT DISTINCT
			t0.STD_YM,
			t0.newINDU,
			t0.newINDU_NM,
			SUM(t0.SALES) OVER(PARTITION BY t0.STD_YM, t0.newINDU) as newINDU_SALES
		FROM
			(	
			SELECT DISTINCT 
				t.STD_YM, 
				t.CORP_NO,
				t.newINDU,
				t.newINDU_NM,
				ROUND(t.SALES/1000, 0) as SALES -- ���� ��ȯ(õ�� -> �鸸��) 
			FROM 
				SALES_TB t
			WHERE 
				t.BLIST_MRKT_DIVN_CD in ('1', '2')	-- ������(�ڽ���, �ڽ���)
				AND NVL(t.EFAS, '') <> '55'			-- ��������� ����
			) t0
		) t00
	) t000
ORDER BY t000.STD_YM;

  
  
  -- �ӽ����̺� ����
DROP TABLE IF EXISTS SALES_TB;