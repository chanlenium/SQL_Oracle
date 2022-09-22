/****************************************************************
 * ���强 ��ǥ ���� - ���ڻ������� ���� (p.6, [�׸�4])
 * Ȱ�� ���̺� : GIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> ASSETS_TB ���̺� ����
 ****************************************************************/
-- (Standby) ����, �����, ����Ը� ���ڻ� ���̺� ASSETS_TB ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS ASSETS_TB;
-- (Step1) ���̺� ����(���س��, ���ι�ȣ, ����Ը�, �ܰ�����, ���屸���ڵ�, KSIC, ��걸��, ���ڻ�, EFAS)
SELECT 
	t0.STD_YM,
	t0.CORP_NO,
	t0.COMP_SCL_DIVN_CD,
	t0.OSIDE_ISPT_YN,
	t0.BLIST_MRKT_DIVN_CD,
	t0.KSIC,
	t0.SEAC_DIVN,
  	t0.ASSETS, 
  	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
  	INTO ASSETS_TB 
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
			      	t1.ASSETS
			    FROM 
			    	(
			    	SELECT 
			    		t000.COMP_CD, 
			          	t000.SEAC_DIVN,
			          	t000.STD_DT, 
			          	t000.ASSETS 
			    	FROM
				  		(	
				        SELECT 
				      		t00.STD_YM, 
					      	t00.COMP_CD, 
					      	t00.SEAC_DIVN,
					     	t00.STD_DT,
					     	t00.ASSETS,  
					     	-- ���� ��������(STD_DT)�� ��ϵ� �繫 �����Ͱ� ������ ���س��(STD_YM)�� �ֱ��� ������ ��� 
				          	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
				        FROM 
				          	(
				            SELECT 
				              	t0.STD_YM, 
				              	t0.COMP_CD, 
				              	t0.SEAC_DIVN,
				              	t0.STD_DT,
				              	t0.ASSETS
				            FROM 
				              	(
				                SELECT
				                	t.STD_YM, 
				                    t.COMP_CD, 
				                    t.SEAC_DIVN,	-- ��걸�� (K: ���, B: �ݱ�, F: 1/4�б�, T: 3/4�б�)
				                    t.STD_DT, 	-- �繫������ ������
				                    t.AMT as ASSETS	-- ���ڻ�
				                FROM 
				                  	TCB_NICE_FNST t 
				                WHERE 
				                   	t.REPORT_CD = '11' 
				                   	AND t.ITEM_CD = '5000'	-- ���ڻ�(11/5000)  
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
SELECT * FROM ASSETS_TB WHERE SEAC_DIVN = 'K' ORDER BY STD_YM;



--(Step2) �������ڻ��� ���� : �������� ��쿡�� ����� ��������� �޸� ���ߵ� ���ڻ��� �״�� �������ڻ����� ���
DROP TABLE IF EXISTS EFFECTIVE_ASSETS_TB;
-- ���̺� ����(����Ը�, ���س��, ���� ���ڻ�, ���� ���ڻ�, ���ڻ� ������)
SELECT DISTINCT
	t00.STD_YM,
	t00.prevSTD_YM,
	t00.CORP_NO,
	t00.COMP_SCL_DIVN_CD,
	t00.OSIDE_ISPT_YN,
	t00.BLIST_MRKT_DIVN_CD,
	t00.KSIC,
	t00.SEAC_DIVN,
	t00.EFAS,
	t00.effASSETS
	INTO EFFECTIVE_ASSETS_TB
FROM 
	(
	SELECT
		t0.*,
		t0.ASSETS as "effASSETS"
	FROM 
		(
		SELECT 
			t1.*,
			t2.ASSETS as "prevASSETS"
		FROM 
			(
			SELECT 
				DECODE('${isSangJang}', 'Y', t0.STD_YM, SUBSTR(t0.STD_YM, 1, 4)) as "STD_YM",
				CASE 
					WHEN '${isSangJang}' = 'Y'
					THEN
						DECODE(SUBSTR(t0.STD_YM, 5), '03', CONCAT(CAST(SUBSTR(t0.STD_YM, 1, 4) - 1 as VARCHAR), '12'), CAST(t0.STD_YM - 3 as VARCHAR))
					ELSE 
						SUBSTR(CAST(t0.STD_YM - 100 as VARCHAR), 1, 4)
				END as prevSTD_YM,				
				t0.CORP_NO,
				t0.COMP_SCL_DIVN_CD,
				t0.OSIDE_ISPT_YN,
				t0.BLIST_MRKT_DIVN_CD,
				t0.KSIC,
				t0.SEAC_DIVN,
				t0.ASSETS,
				t0.EFAS
			FROM 
				ASSETS_TB t0
			WHERE t0.COMP_SCL_DIVN_CD in ('1', '2', '3')
				AND
				CASE 
					WHEN '${isSangJang}' = 'Y' 
					THEN t0.BLIST_MRKT_DIVN_CD in ('1', '2')	-- �ڽ���(1), �ڽ���(2)�� ����
					ELSE t0.SEAC_DIVN = 'K'	-- �������� �ƴҶ��� K��길 ���͸�
				END
			ORDER BY t0.CORP_NO, t0.STD_YM
			) t1, 
			ASSETS_TB t2
			WHERE 
				t1.CORP_NO = t2.CORP_NO AND
				t1.COMP_SCL_DIVN_CD = t2.COMP_SCL_DIVN_CD AND
				t1.OSIDE_ISPT_YN = t2.OSIDE_ISPT_YN AND
				t1.BLIST_MRKT_DIVN_CD = t2.BLIST_MRKT_DIVN_CD AND 
				t1.KSIC = t2.KSIC AND
				t1.EFAS = t2.EFAS AND				
				CASE 
					WHEN '${isSangJang}' = 'Y' 
					THEN t1.prevSTD_YM = t2.STD_YM	-- 6�ڸ�
					ELSE t1.prevSTD_YM = SUBSTR(t2.STD_YM, 1, 4)	-- 4�ڸ�
				END
			ORDER BY t1.CORP_NO, t1.STD_YM
		) t0	
		ORDER BY t0.CORP_NO, t0.STD_YM
	) t00
ORDER BY t00.CORP_NO, t00.STD_YM;
-- ��� ��ȸ
SELECT t.* FROM EFFECTIVE_ASSETS_TB t ORDER BY t.CORP_NO, t.STD_YM;



-- (Step3) ���� �������(effASSETS)�� Ȱ���Ͽ� ���ڻ� ������ ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS ASSETS_INC_RATIO_TB;
-- ���̺� ����(���س��, �������, ���ι�ȣ, ����Ը�, �ܰ�����, ���屸���ڵ�, KSIC, ��걸��, EFAS, �������ڻ�, �����������ڻ�, ���ڻ�������)
SELECT 
	t0.*,
	t0.effASSETS / NULLIF(t0.prevASSETS, 0) - 1 as "targetRatio"
	INTO ASSETS_INC_RATIO_TB
FROM 	
	(
	SELECT 
		t1.*,
		t2.effASSETS as "prevASSETS"
	FROM 
		EFFECTIVE_ASSETS_TB t1, EFFECTIVE_ASSETS_TB t2
	WHERE 
		t1.prevSTD_YM = t2.STD_YM
		AND t1.CORP_NO = t2.CORP_NO
	) t0
ORDER BY t0.CORP_NO, t0.STD_YM;
-- ��� ��ȸ
SELECT * FROM ASSETS_INC_RATIO_TB;



-- (Step4) Calculate IQR cutoff
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
		t.EFAS,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.STD_YM, t.EFAS) as "LQ",
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.STD_YM, t.EFAS) as "UQ"	
	FROM 	
		ASSETS_INC_RATIO_TB t
	) t0;
-- ��� ��ȸ
SELECT * FROM IQRcutOff_TB ORDER BY STD_YM, EFAS;



-- (Step5) cutoff ���̺� ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS Cutoff_ASSETS_INC_RATIO_TB;
-- ���̺� ����
SELECT 
	t1.*
	INTO Cutoff_ASSETS_INC_RATIO_TB
FROM
	ASSETS_INC_RATIO_TB t1, IQRcutOff_TB t2
WHERE 
	t1.STD_YM = t2.STD_YM
	AND	t1.EFAS = t2.EFAS
	AND t1.targetRatio > t2.LowerCutoff
	AND t1.targetRatio < t2.UpperCutoff;
-- ��� ��ȸ
SELECT * FROM Cutoff_ASSETS_INC_RATIO_TB;



-- (Step6) ���ڻ� ������ ���� �׷��� (������)
SELECT 	
	t000.*,
	thisYY_EFAS_ASSETS_INC_RATIO - prevYY_EFAS_ASSETS_INC_RATIO as "INCRATIO"	-- ���� ���� ��� ������
FROM 
	(
	SELECT DISTINCT
		t00.EFAS,
		t00.thisYY,
		SUM(t00.thisYY_EFAS_ASSETS_INC_RATIO) OVER(PARTITION BY t00.EFAS) as thisYY_EFAS_ASSETS_INC_RATIO,	-- ���� ���ڻ�������
		SUM(t00.prevYY_EFAS_ASSETS_INC_RATIO) OVER(PARTITION BY t00.EFAS) as prevYY_EFAS_ASSETS_INC_RATIO	-- ���� ���� ���ڻ�������
	FROM
		(	
		SELECT 
			t0.EFAS,
		  	t0.STD_YM,
		  	t0.thisYY,
		  	CASE	
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN DECODE(t0.STD_YM, t0.thisYY, t0.ASSETS_INC_RATIO, 0)
		  		ELSE DECODE(CONCAT(t0.STD_YM, '12'), t0.thisYY, t0.ASSETS_INC_RATIO, 0)
		  	END as "thisYY_EFAS_ASSETS_INC_RATIO",
		  	CASE	
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN DECODE(t0.STD_YM, t0.prevYY, t0.ASSETS_INC_RATIO, 0)
		  		ELSE DECODE(CONCAT(t0.STD_YM, '12'), t0.prevYY, t0.ASSETS_INC_RATIO, 0)
		  	END as "prevYY_EFAS_ASSETS_INC_RATIO"
		FROM
			(
			SELECT DISTINCT 
				t.EFAS,
				CASE
			  		WHEN '${isSangJang}' = 'Y' THEN t.STD_YM ELSE SUBSTR(t.STD_YM, 1, 4)
			  	END as STD_YM,
			  	CASE	
			  		WHEN '${isSangJang}' = 'Y' 
			  		THEN
			  			MAX(t.STD_YM) OVER(PARTITION BY t.EFAS)
			  		ELSE
			  			DECODE(SUBSTR(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS), 5), '12', 
			  			MAX(t.STD_YM) OVER(PARTITION BY t.EFAS),
			  			CONCAT(CAST(SUBSTR(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS), 1, 4) - 1 as VARCHAR), '12'))
			  	END as thisYY,
			  	CASE	
			  		WHEN '${isSangJang}' = 'Y' 
			  		THEN
			  			CAST(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS) - 100 as VARCHAR)
			  		ELSE
			  			DECODE(SUBSTR(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS), 5), '12', 
			  			CAST(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS) - 100 as VARCHAR),
			  			CONCAT(CAST(SUBSTR(MAX(t.STD_YM) OVER(PARTITION BY t.EFAS), 1, 4) - 2 as VARCHAR), '12'))
			  	END as prevYY,
			  	CASE	-- ���ڻ� ������
			  		WHEN '${isSangJang}' = 'Y' 
			  		THEN
			  			AVG(t.targetRatio) OVER(PARTITION BY t.STD_YM, t.EFAS)
			  		ELSE
			  			AVG(t.targetRatio) OVER(PARTITION BY SUBSTR(t.STD_YM, 1, 4), t.EFAS)
			  	END as ASSETS_INC_RATIO
			FROM 
			  	Cutoff_ASSETS_INC_RATIO_TB t 
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
		WHERE
			CASE	
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN t0.STD_YM in (t0.thisYY, t0.prevYY)
		  		ELSE CONCAT(t0.STD_YM, '12') in (t0.thisYY, t0.prevYY)
		  	END
		) t00
	) t000
ORDER BY 
  	TO_NUMBER(t000.EFAS, '99');
  	
  
  
  -- �ӽ����̺� ����
DROP TABLE IF EXISTS ASSETS_TB;
DROP TABLE IF EXISTS EFFECTIVE_ASSETS_TB;
DROP TABLE IF EXISTS ASSETS_INC_RATIO_TB;
DROP TABLE IF EXISTS IQRcutOff_TB;
DROP TABLE IF EXISTS Cutoff_ASSETS_INC_RATIO_TB;