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
 * ���ٺ�ä������� : ������ ��Ȳ (p.6, [ǥ])
 * RFP p.16 [ǥ] ���ٺ�ä������� : ������ ��Ȳ
 * Ȱ�� ���̺� : DEBT_RATIO_TB -> EFAS_OVERDEBTRATIO_TB ����
 ****************************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS EFAS_OVERDEBTRATIO_TB;
-- (Step1) ���̺� ����(�����ڵ�, ���س���ٺ�ä�����, ��ü�����, ���⵵���ٺ�ä�����, ���⵵��ü�����)
SELECT DISTINCT
	t000.EFAS,
	SUM(t000.thisYY_EFAS_CNTOVERDEBTCORP) OVER(PARTITION BY t000.EFAS) as thisYY_EFAS_CNTOVERDEBTCORP,	-- ���� ���ٺ�ä ��� �� 
	SUM(t000.thisYY_EFAS_CNTCORP) OVER(PARTITION BY t000.EFAS) as thisYY_EFAS_CNTCORP,	-- ���� ��ü ��� ��
	SUM(t000.prevYY_EFAS_CNTOVERDEBTCORP) OVER(PARTITION BY t000.EFAS) as prevYY_EFAS_CNTOVERDEBTCORP,	-- ���� ���� ���ٺ�ä ��� ��
	SUM(t000.prevYY_EFAS_CNTCORP) OVER(PARTITION BY t000.EFAS) as prevYY_EFAS_CNTCORP	-- ���� ���� ��ü ��� ��
	INTO EFAS_OVERDEBTRATIO_TB 
FROM
	(
	SELECT 
	  	t00.EFAS, 
	  	t00.STD_YM,
	  	DECODE(t00.STD_YM, thisYY, t00.CNTOVERDEBTCORP, 0) as thisYY_EFAS_CNTOVERDEBTCORP, 
	  	DECODE(t00.STD_YM, thisYY, t00.CNTCORP, 0) as thisYY_EFAS_CNTCORP, 
	  	DECODE(t00.STD_YM, prevYY, t00.CNTOVERDEBTCORP, 0) as prevYY_EFAS_CNTOVERDEBTCORP, 
	  	DECODE(t00.STD_YM, prevYY, t00.CNTCORP, 0) as prevYY_EFAS_CNTCORP 
	FROM 
	  	(
	    SELECT DISTINCT 
	    	t0.EFAS, 
	      	t0.STD_YM, 
	      	t0.thisYY,
	      	t0.prevYY,
	      	SUM(t0.ISOVERDEBT) OVER(PARTITION BY t0.EFAS, t0.STD_YM) as CNTOVERDEBTCORP, 
	      	COUNT(t0.CORP_NO) OVER(PARTITION BY t0.EFAS, t0.STD_YM) as CNTCORP 
	    FROM 
	      	(
	        SELECT 
	          	t.EFAS, 
	          	t.CORP_NO, 
	          	t.STD_YM, 
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
	          	t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL) as DEBTRATIO, 
	          	-- ��ä����
	          	CASE -- Dvision by zero ȸ��
	          		WHEN (t.DEBT / DECODE(t.CAPITAL, 0, 1, t.CAPITAL)) >= 2 THEN 1 ELSE 0 
	          	END as isOVERDEBT -- ��ä������ 200% �̻��̸� 1, �ƴϸ� 0���� ���ڵ�
	        FROM 
	          	DEBT_RATIO_TB t 
	      	) t0
	    WHERE
			t0.STD_YM in (t0.thisYY, t0.prevYY)
	  	) t00 
	) t000 
ORDER BY 
  	t000.EFAS;

  
  
-- (Step2) ���س�/���� ���� ���ٺ�ä���� �� ���� ���� ��� ������ ��� */
DROP TABLE IF EXISTS RESULT_BIZ_OVERDEBTRATIO_EFAS;
SELECT 
  	t.EFAS, 
  	ROUND(t.thisYY_EFAS_CNTOVERDEBTCORP / NULLIF(t.thisYY_EFAS_CNTCORP, 0), 4) as thisYY_OVERDEBTCORPRATIO, -- ��� ���ٺ�ä�������
  	ROUND(t.prevYY_EFAS_CNTOVERDEBTCORP / NULLIF(t.prevYY_EFAS_CNTCORP, 0), 4) as prevYY_OVERDEBTCORPRATIO, -- ���⵿�� ���ٺ�ä�������
  	ROUND(t.thisYY_EFAS_CNTOVERDEBTCORP / NULLIF(t.thisYY_EFAS_CNTCORP, 0), 4) 
  	- ROUND(t.prevYY_EFAS_CNTOVERDEBTCORP / NULLIF(t.prevYY_EFAS_CNTCORP, 0), 4) as OVERDEBTCORPINC -- ���ٺ�ä������� ����
  	INTO RESULT_BIZ_OVERDEBTRATIO_EFAS
FROM 
  	EFAS_OVERDEBTRATIO_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');
  	

  
-- �ӽ����̺� ����
DROP TABLE IF EXISTS DEBT_RATIO_TB;
DROP TABLE IF EXISTS EFAS_OVERDEBTRATIO_TB;

-- ��� ��ȸ
SELECT * FROM RESULT_BIZ_OVERDEBTRATIO_EFAS;