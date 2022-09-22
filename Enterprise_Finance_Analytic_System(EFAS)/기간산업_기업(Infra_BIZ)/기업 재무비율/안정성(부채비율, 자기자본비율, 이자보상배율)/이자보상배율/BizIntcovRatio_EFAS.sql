/****************************************************************
 * ������ ��ǥ ���� - ���ں������(=��������/���ں��) ���� (p.6, [�׸�4])
 * Ȱ�� ���̺� : GIUP_RAW, TCB_NICE_FNST(�繫��ǥ) -> INTCOVRATIO_TB ���̺� ����
 ****************************************************************/
-- (Standby) ����, �����, ����Ը� ���ں������ ���̺� INTCOVRATIO_TB ���� 
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS INTCOVRATIO_TB;
-- ���̺� ���� (���س��, ���ι�ȣ, ����Ը�, KSIC, ��������, ���ں��, EFAS)
SELECT 
  	t0.STD_YM,
	t0.CORP_NO,
	t0.COMP_SCL_DIVN_CD,
	t0.OSIDE_ISPT_YN,
	t0.BLIST_MRKT_DIVN_CD,
	t0.KSIC,
	t0.SEAC_DIVN,
	t0.INT_EXP,
	t0.OP_PROFIT,
	t0.targetRatio,
	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
  	INTO INTCOVRATIO_TB 
FROM
	(
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
			      	t1.OP_PROFIT,
			      	t1.INT_EXP, 
			      	t1.OP_PROFIT / t1.INT_EXP as "targetRatio"	-- ���� ����� ��ä����
			    FROM 
			      	(
			        SELECT 
			          t000.COMP_CD, 
			          t000.SEAC_DIVN,
			          t000.STD_DT, 
			          t000.OP_PROFIT,
			          t000.INT_EXP
			        FROM 
			          	(
			            SELECT 
			              	t00.STD_YM, 
			              	t00.COMP_CD, 
			              	t00.SEAC_DIVN,
			              	t00.STD_DT, 
			              	t00.OP_PROFIT, 
			              	t00.INT_EXP, 
			              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ��� 
			              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM
			            FROM 
			              	(
			                SELECT DISTINCT 
			                	t0.STD_YM, 
			                  	t0.COMP_CD, 
			                  	t0.SEAC_DIVN,
			                  	t0.STD_DT, 
			                  	SUM(t0.OP_PROFIT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as OP_PROFIT, -- ��������
			                  	SUM(t0.INT_EXP) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as INT_EXP	-- ���ں��                  	
			                FROM 
			                  	(
			                    SELECT 
			                      	t.STD_YM, 	-- �����Ͱ� ���ߵ� ���
			                      	t.COMP_CD, 
			                      	t.SEAC_DIVN,	-- ��걸�� (K: ���, B: �ݱ�, F: 1/4�б�, T: 3/4�б�)
			                      	t.STD_DT, 
			                      	t.ITEM_CD, 
			                      	DECODE(t.ITEM_CD, '6110', t.AMT, 0) as INT_EXP, -- ���ں��
			                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as OP_PROFIT -- ��������
			                    FROM 
			                      	TCB_NICE_FNST t 
			                    WHERE 
			                      	t.REPORT_CD = '12' 
			                      	and t.ITEM_CD in ('6110', '5000')
			                  	) t0 -- ���ں��(6110), ��������(5000)
			                WHERE 
				                CAST(t0.STD_DT AS INTEGER)  IN (		-- �ֱ� 4����
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
			          	t000.LAST_STD_YM = '1'
			          	AND t000.INT_EXP <> '0' -- Divided by zero ȸ��
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
WHERE t0.KSIC is not NULL and NVL(EFAS, '') <> '55';		
-- ��� ��ȸ
SELECT * FROM INTCOVRATIO_TB ORDER BY STD_YM DESC;



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
		t.EFAS,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.STD_YM, t.EFAS) as "LQ",
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.STD_YM, t.EFAS) as "UQ"	
	FROM 	
		INTCOVRATIO_TB t
	) t0;
-- ��� ��ȸ
SELECT * FROM IQRcutOff_TB ORDER BY STD_YM, EFAS;



-- (Step3) cutoff ���̺� ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS Cutoff_INTCOVRATIO_TB;
-- ���̺� ����
SELECT 
	t1.*
	INTO Cutoff_INTCOVRATIO_TB
FROM
	INTCOVRATIO_TB t1, IQRcutOff_TB t2
WHERE 
	t1.STD_YM = t2.STD_YM
	AND	t1.EFAS = t2.EFAS
	AND t1.targetRatio > t2.LowerCutoff
	AND t1.targetRatio < t2.UpperCutoff;
-- ��� ��ȸ
SELECT * FROM Cutoff_INTCOVRATIO_TB;



-- (Step4) ���ں������ ���� �׷��� (������)
SELECT 	
	t000.*,
	thisYY_EFAS_INTCOVRATIO - prevYY_EFAS_INTCOVRATIO as "INCRATIO"	-- ���� ���� ��� ������
FROM 
	(
	SELECT DISTINCT
		t00.EFAS,
		t00.thisYY,
		SUM(t00.thisYY_EFAS_INTCOVRATIO) OVER(PARTITION BY t00.EFAS) as thisYY_EFAS_INTCOVRATIO,-- ���� ���ں������
		SUM(t00.prevYY_EFAS_INTCOVRATIO) OVER(PARTITION BY t00.EFAS) as prevYY_EFAS_INTCOVRATIO	-- ���� ���� ���ں������
	FROM
		(	
		SELECT 
			t0.EFAS,
		  	t0.STD_YM,
		  	t0.thisYY,
		  	CASE	
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN DECODE(t0.STD_YM, t0.thisYY, t0.INTCOVRATIO, 0)
		  		ELSE DECODE(CONCAT(t0.STD_YM, '12'), t0.thisYY, t0.INTCOVRATIO, 0)
		  	END as "thisYY_EFAS_INTCOVRATIO",
		  	CASE	
		  		WHEN '${isSangJang}' = 'Y' 
		  		THEN DECODE(t0.STD_YM, t0.prevYY, t0.INTCOVRATIO, 0)
		  		ELSE DECODE(CONCAT(t0.STD_YM, '12'), t0.prevYY, t0.INTCOVRATIO, 0)
		  	END as "prevYY_EFAS_INTCOVRATIO"
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
			  	CASE	-- ���ں������
			  		WHEN '${isSangJang}' = 'Y' 
			  		THEN
			  			AVG(t.targetRatio) OVER(PARTITION BY t.STD_YM, t.EFAS)
			  		ELSE
			  			AVG(t.targetRatio) OVER(PARTITION BY SUBSTR(t.STD_YM, 1, 4), t.EFAS)
			  	END as INTCOVRATIO
			FROM 
			  	Cutoff_INTCOVRATIO_TB t 
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
DROP TABLE IF EXISTS INTCOVRATIO_TB;
DROP TABLE IF EXISTS IQRcutOff_TB;
DROP TABLE IF EXISTS Cutoff_INTCOVRATIO_TB;