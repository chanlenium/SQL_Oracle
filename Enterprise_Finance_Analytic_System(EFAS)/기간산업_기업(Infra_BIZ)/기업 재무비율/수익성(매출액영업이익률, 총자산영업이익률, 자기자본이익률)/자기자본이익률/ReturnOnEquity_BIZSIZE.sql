/****************************************************************
 * ���ͼ� ��ǥ ���� - �ڱ��ں����ͷ�(=��������/�ڱ��ں�(�ں��Ѱ�)) ���� (p.6, [�׸�4])
 * Ȱ�� ���̺� : GIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> RETURN_ON_EQUITY_TB ���̺� ����
 ****************************************************************/
-- (Standby) ����, �����, ����Ը� �ڱ��ں����ͷ� ���̺� RETURN_ON_EQUITY_TB ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS RETURN_ON_EQUITY_TB;
-- (Step1) ���̺� ���� ����, �����, ����Ը� ��ä���� ���̺� ���� (�ֱ� 4���� ������)
-- (���س��, ���ι�ȣ, ����Ը�, �ܰ�����, ���忩��, KSIC, ��걸��, ��������, �ڱ��ں�, �ڱ��ں����ͷ�, EFAS)
SELECT 
	t0.STD_YM,
	t0.CORP_NO,
	t0.COMP_SCL_DIVN_CD,
	t0.OSIDE_ISPT_YN,
	t0.BLIST_MRKT_DIVN_CD,
	t0.KSIC,
	t0.SEAC_DIVN,
	t0.NetINCOME,
	t0.CapSTOCKS,
	t0.targetRatio,
	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
	INTO RETURN_ON_EQUITY_TB
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
			      	t1.NetINCOME, 
			      	t1.CapSTOCKS,
			      	t1.NetINCOME / t1.CapSTOCKS as "targetRatio"	-- ���� ����� �ڱ��ں����ͷ�
			    FROM 
			    	(
			        SELECT 
			          	t000.COMP_CD, 
			          	t000.SEAC_DIVN,
			          	t000.STD_DT, 
			          	t000.NetINCOME, 
			          	t000.CapSTOCKS 
			        FROM 
			          	(
			            SELECT 
			              	t00.STD_YM, 
			              	t00.COMP_CD, 
			              	t00.SEAC_DIVN,
			             	t00.STD_DT, 
			              	t00.NetINCOME, 
			              	t00.CapSTOCKS, 
			              	-- ���� ��������(STD_DT)�� ��ϵ� �繫 �����Ͱ� ������ ���س��(STD_YM)�� �ֱ��� ������ ��� 
			              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
			            FROM 
			              	(
			                SELECT DISTINCT 
			                	t0.STD_YM, 
			                  	t0.COMP_CD, 
			                  	t0.SEAC_DIVN,
			                  	t0.STD_DT, 
			                  	SUM(t0.NetINCOME) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as NetINCOME, 
			                  	SUM(t0.CapSTOCKS) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as CapSTOCKS 
			                FROM 
			                  	(
			                    SELECT 
			                      	t.STD_YM, -- �����Ͱ� ���ߵ� ���
			                      	t.COMP_CD, 
			                      	t.SEAC_DIVN,	-- ��걸�� (K: ���, B: �ݱ�, F: 1/4�б�, T: 3/4�б�)
			                      	t.STD_DT,	-- �繫������ ������
			                      	t.ITEM_CD, 
			                      	CASE WHEN t.REPORT_CD = '12' and t.ITEM_CD = '9000' THEN t.AMT ELSE 0 END as NetINCOME, -- ��������(�ս�)
                      				CASE WHEN t.REPORT_CD = '11' and t.ITEM_CD = '8900' THEN t.AMT ELSE 0 END as CapSTOCKS -- �ڱ��ں�
			                    FROM 
			                      	TCB_NICE_FNST t 
			                    WHERE 
			                      	(t.REPORT_CD = '12' and t.ITEM_CD = '9000')	-- ��������(�ս�)(12/9000)
                      				OR (t.REPORT_CD = '11' and t.ITEM_CD = '8900')	-- �ڱ��ں�(�ں��Ѱ�, 11/8900)
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
			                		CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 30000)
			                ORDER BY 
			                  	t0.COMP_CD, t0.STD_DT
			              	) t00
			          	) t000 
			        WHERE 
			          	t000.LAST_STD_YM = '1'	-- �ֱ� �����͸� ����
			          	AND t000.CapSTOCKS <> '0' -- Divided by zero ȸ��
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
WHERE t0.KSIC is not NULL and NVL(EFAS, '') <> '55';	-- ��������� ����			
-- ��� ��ȸ
SELECT * FROM RETURN_ON_EQUITY_TB ORDER BY STD_YM DESC;



-- (Step2) Calculate IQR cutoff
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS IQRcutOff_TB;
-- ���س��, LQ(Q1), UQ(Q3), IQR(=UQ-LQ), LowerCutoff, UpperCutoff
SELECT 
	t0.*,
	t0.LQ - 1.5 * (t0.UQ - t0.LQ) as "LowerCutoff",
	t0.UQ + 1.5 * (t0.UQ - t0.LQ) as "UpperCutoff"
	INTO IQRcutOff_TB
FROM 
	(
	SELECT DISTINCT
		t.STD_YM,
		t.COMP_SCL_DIVN_CD,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as "LQ",
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD) as "UQ"	
	FROM 	
		RETURN_ON_EQUITY_TB t
	) t0;
-- ��� ��ȸ
SELECT * FROM IQRcutOff_TB ORDER BY STD_YM, COMP_SCL_DIVN_CD;



-- (Step3) cutoff ���̺� ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS Cutoff_RETURN_ON_EQUITY_TB;
-- ���̺� ����
SELECT 
	t1.*
	INTO Cutoff_RETURN_ON_EQUITY_TB
FROM
	RETURN_ON_EQUITY_TB t1, IQRcutOff_TB t2
WHERE 
	t1.STD_YM = t2.STD_YM
	AND	t1.COMP_SCL_DIVN_CD = t2.COMP_SCL_DIVN_CD
	AND t1.targetRatio > t2.LowerCutoff
	AND t1.targetRatio < t2.UpperCutoff;
-- ��� ��ȸ
SELECT * FROM Cutoff_RETURN_ON_EQUITY_TB;



-- (Step4) �ڱ��ں����ͷ� ���� �׷��� (��/��/��) (1: ����, 2: �߼ұ��, 3: �߰߱��, 0: ���ƴ�)
SELECT DISTINCT
	t00.STD_YM,
	SUM(RETURN_ON_EQUITY_RATIO_BIZ_1) OVER(PARTITION BY t00.STD_YM) as RETURN_ON_EQUITY_RATIO_BIZ_1,
	SUM(RETURN_ON_EQUITY_RATIO_BIZ_2) OVER(PARTITION BY t00.STD_YM) as RETURN_ON_EQUITY_RATIO_BIZ_2,
	SUM(RETURN_ON_EQUITY_RATIO_BIZ_3) OVER(PARTITION BY t00.STD_YM) as RETURN_ON_EQUITY_RATIO_BIZ_3
FROM
	(	
	SELECT 
		t0.*,
		DECODE(t0.BIZ_SIZE, '����', t0.RETURN_ON_EQUITY_RATIO, 0) as RETURN_ON_EQUITY_RATIO_BIZ_1,
		DECODE(t0.BIZ_SIZE, '�߼ұ��', t0.RETURN_ON_EQUITY_RATIO, 0) as RETURN_ON_EQUITY_RATIO_BIZ_2,
		DECODE(t0.BIZ_SIZE, '�߰߱��', t0.RETURN_ON_EQUITY_RATIO, 0) as RETURN_ON_EQUITY_RATIO_BIZ_3
	FROM
		(
		SELECT DISTINCT 
			CASE
		  		WHEN '${isSangJang}' = 'Y' THEN t.STD_YM ELSE SUBSTR(t.STD_YM, 1, 4)
		  	END as STD_YM,
		  	CASE 
		  		WHEN t.COMP_SCL_DIVN_CD = 1 THEN '����'
		  		WHEN t.COMP_SCL_DIVN_CD = 2 THEN '�߼ұ��'
		  		WHEN t.COMP_SCL_DIVN_CD = 3 THEN '�߰߱��'
		  		ELSE t.COMP_SCL_DIVN_CD
		  	END as BIZ_SIZE,
		  	CASE	-- �ڱ��ں����ͷ�
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN
		  			AVG(t.targetRatio) OVER(PARTITION BY t.STD_YM, t.COMP_SCL_DIVN_CD)
		  		ELSE
		  			AVG(t.targetRatio) OVER(PARTITION BY SUBSTR(t.STD_YM, 1, 4), t.COMP_SCL_DIVN_CD)
		  	END as RETURN_ON_EQUITY_RATIO
		FROM 
		  	Cutoff_RETURN_ON_EQUITY_TB t 
		WHERE
			t.COMP_SCL_DIVN_CD in ('1', '2', '3')
			AND
			CASE 
				WHEN '${isSangJang}' = 'Y' 
				THEN t.BLIST_MRKT_DIVN_CD in ('1', '2')	-- �ڽ���(1), �ڽ���(2)�� ����
				ELSE t.SEAC_DIVN = 'K'	-- �������� �ƴҶ��� K��길 ���͸�
			END
		ORDER BY 
			CASE	
		  		WHEN '${isSangJang}' = 'Y' THEN t.STD_YM ELSE SUBSTR(t.STD_YM, 1, 4)
		  	END
		) t0
	) t00
ORDER BY t00.STD_YM;



-- �Ӽ����̺� ����
DROP TABLE IF EXISTS RETURN_ON_EQUITY_TB;
DROP TABLE IF EXISTS IQRcutOff_TB;
DROP TABLE IF EXISTS Cutoff_RETURN_ON_EQUITY_TB;