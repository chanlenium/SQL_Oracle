/*****************************************************
 * (StandBy) ��ä���� ���̺� ����
 * Ȱ�� ���̺� : TCB_NICE_FNST(�繫��ǥ), GIUP_RAW(�������) -> DEBT_RATIO_TB ���̺� ����
 *****************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS DEBT_RATIO_TB;
-- ���̺� ���� ����, �����, ����Ը� ��ä���� ���̺� ���� (�ֱ� 4���� ������)
-- (���س��, ���ι�ȣ, ����Ը�, �ܰ�����, ���忩��, KSIC, ��걸��, ��ä, ���ڻ�, EFAS)
SELECT 
	t0.STD_YM,
	t0.CORP_NO,
	t0.COMP_SCL_DIVN_CD,
	t0.OSIDE_ISPT_YN,
	t0.BLIST_MRKT_DIVN_CD,
	t0.KSIC,
	t0.SEAC_DIVN,
	t0.DEBT,
	t0.CAPITAL,
	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
	INTO DEBT_RATIO_TB
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
			      	t1.DEBT, 
			      	t1.CAPITAL 
			    FROM 
			    	(
			        SELECT 
			          	t000.COMP_CD, 
			          	t000.SEAC_DIVN,
			          	t000.STD_DT, 
			          	t000.DEBT, 
			          	t000.CAPITAL 
			        FROM 
			          	(
			            SELECT 
			              	t00.STD_YM, 
			              	t00.COMP_CD, 
			              	t00.SEAC_DIVN,
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
			                  	t0.SEAC_DIVN,
			                  	t0.STD_DT, 
			                  	SUM(t0.DEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as DEBT, 
			                  	SUM(t0.CAPITAL) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as CAPITAL 
			                FROM 
			                  	(
			                    SELECT 
			                      	t.STD_YM, -- �����Ͱ� ���ߵ� ���
			                      	t.COMP_CD, 
			                      	t.SEAC_DIVN,	-- ��걸�� (K: ���, B: �ݱ�, F: 1/4�б�, T: 3/4�б�)
			                      	t.STD_DT,	-- �繫������ ������
			                      	t.ITEM_CD, 
			                      	DECODE(t.ITEM_CD, '8000', ROUND(t.AMT/1000, 0), 0) as DEBT, -- ��ä
			                      	DECODE(t.ITEM_CD, '8900', ROUND(t.AMT/1000, 0), 0) as CAPITAL -- �ں�
			                    FROM 
			                      	TCB_NICE_FNST t 
			                    WHERE 
			                      	t.REPORT_CD = '11' -- ��������ǥ 
			                      	and t.ITEM_CD in ('8000', '8900')	-- ��ä�Ѱ�(8000), �ں��Ѱ�(8900)
			                  	) t0 
			                WHERE 
			                	CAST(t0.STD_DT AS INTEGER)  IN (	-- �ֱ� 4���� �ڷ� ����
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
			                		CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 30000)
			                ORDER BY 
			                  	t0.COMP_CD, t0.STD_DT
			              	) t00
			          	) t000 
			        WHERE 
			          	t000.LAST_STD_YM = '1'	-- �ֱ� �����͸� ����
			      	) t1 
			      	LEFT JOIN GIUP_RAW t2
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
WHERE t0.KSIC is not NULL;		
-- ��� ��ȸ
SELECT * FROM DEBT_RATIO_TB;





/****************************************************************
 * ������ ��ǥ ���� - ���ٺ�ä(��ä���� 200% �ʰ�) ��� ���� ���� (p.6, [�׸�3])
 * RFP p.15 [�׸�2] ��ä����
 * Ȱ�� ���̺� : DEBT_RATIO_TB���� ����� ��ä���� ����Ͽ� ���ٺ�ä ��� ���� ���
 ****************************************************************/
DROP TABLE IF EXISTS RESULT_BIZ_OVERDEBTRATIO_BIZSIZE;
SELECT DISTINCT
	t00.STD_YM,
	SUM(OVERDEBT_RATIO_BIZ_1) OVER(PARTITION BY t00.STD_YM) as OVERDEBT_RATIO_BIZ_1,
	SUM(OVERDEBT_RATIO_BIZ_2) OVER(PARTITION BY t00.STD_YM) as OVERDEBT_RATIO_BIZ_2,
	SUM(OVERDEBT_RATIO_BIZ_3) OVER(PARTITION BY t00.STD_YM) as OVERDEBT_RATIO_BIZ_3
	INTO RESULT_BIZ_OVERDEBTRATIO_BIZSIZE
FROM
	(	
	SELECT 
		t0.*,
		DECODE(t0.BIZ_SIZE, '����', t0.OVERDEBT_RATIO, 0) as OVERDEBT_RATIO_BIZ_1,
		DECODE(t0.BIZ_SIZE, '�߼ұ��', t0.OVERDEBT_RATIO, 0) as OVERDEBT_RATIO_BIZ_2,
		DECODE(t0.BIZ_SIZE, '�߰߱��', t0.OVERDEBT_RATIO, 0) as OVERDEBT_RATIO_BIZ_3
	FROM
		(
		SELECT DISTINCT 
			CASE
		  		WHEN '${isSangJang}' = 'Y' THEN t0.STD_YM ELSE SUBSTR(t0.STD_YM, 1, 4)
		  	END as STD_YM,
		  	CASE 
		  		WHEN t0.COMP_SCL_DIVN_CD = 1 THEN '����'
		  		WHEN t0.COMP_SCL_DIVN_CD = 2 THEN '�߼ұ��'
		  		WHEN t0.COMP_SCL_DIVN_CD = 3 THEN '�߰߱��'
		  		ELSE t0.COMP_SCL_DIVN_CD
		  	END as BIZ_SIZE, 
		  	CASE	-- ���ٺ�ä ��� ��
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN
		  			SUM(t0.isOVERDEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD)
		  		ELSE
		  			SUM(t0.isOVERDEBT) OVER(PARTITION BY SUBSTR(t0.STD_YM, 1, 4), t0.COMP_SCL_DIVN_CD)
		  	END as OVERDEBTCNT,
		  	CASE	-- ��ü ��� ��
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN
		  			COUNT(t0.CORP_NO) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD)
		  		ELSE
		  			COUNT(t0.CORP_NO) OVER(PARTITION BY SUBSTR(t0.STD_YM, 1, 4), t0.COMP_SCL_DIVN_CD)
		  	END as TOTBIZCNT,
			CASE	-- ���ٺ�ä��� ����
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN
		  			ROUND(SUM(t0.isOVERDEBT) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD) / COUNT(t0.CORP_NO) OVER(PARTITION BY t0.STD_YM, t0.COMP_SCL_DIVN_CD), 4)
		  		ELSE
		  			ROUND(SUM(t0.isOVERDEBT) OVER(PARTITION BY SUBSTR(t0.STD_YM, 1, 4), t0.COMP_SCL_DIVN_CD) / COUNT(t0.CORP_NO) OVER(PARTITION BY SUBSTR(t0.STD_YM, 1, 4), t0.COMP_SCL_DIVN_CD), 4)
		  	END as OVERDEBT_RATIO
		FROM 
		  	(
		    SELECT 
		      	t.*, 
		      	CASE -- Dvision by zero ȸ��
		      		WHEN (t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL)) >= 2 THEN 1 ELSE 0 
		      	END as isOVERDEBT -- ��ä������ 200% �̻��̸� 1, �ƴϸ� 0���� ���ڵ�
		    FROM 
		      	DEBT_RATIO_TB t
		    WHERE 
		    	t.COMP_SCL_DIVN_CD in ('1', '2', '3')
		  	) t0 
		WHERE 
			CASE 
				WHEN '${isSangJang}' = 'Y' 
				THEN t0.BLIST_MRKT_DIVN_CD in ('1', '2')	-- �ڽ���(1), �ڽ���(2)�� ����
				ELSE t0.SEAC_DIVN = 'K'	-- �������� �ƴҶ��� K��길 ���͸�
			END
		ORDER BY 
		  	CASE	
		  		WHEN '${isSangJang}' = 'Y' THEN t0.STD_YM ELSE SUBSTR(t0.STD_YM, 1, 4)
		  	END
		) t0
	) t00
ORDER BY
	t00.STD_YM;
	

-- �ӽ����̺� ����
DROP TABLE IF EXISTS DEBT_RATIO_TB;

-- ��� ��ȸ
SELECT * FROM RESULT_BIZ_OVERDEBTRATIO_BIZSIZE ORDER BY STD_YM;