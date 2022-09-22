/**************************************
 *             ����㺸 ������(FLOW)           
 * Ȱ�� ���̺� : BASIC_BIZ_DAMBO, TCB_NICE_FNST -> ��� �㺸������ ��� ���̺�(BASIC_BIZ_DAMBO_FLOW) ����
 **************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BASIC_BIZ_DAMBO_FLOW_TB;
-- (Standby) ���̺� ���� (���س��, ���ι�ȣ, ����Ը�, �㺸����, EFAS, ����ȣ, ���ڻ�, �㺸���׺���)
SELECT 
  	t10.*, 
  	t20.COMP_CD, 
  	t20.TOT_ASSET,
  	t10.BIZ_DAMBO_AMT / NULLIF(t20.TOT_ASSET, 0) as "targetRatio"
  	INTO BASIC_BIZ_DAMBO_FLOW_TB 
FROM 
  	(
    -- ������, ����� �㺸���� �� ���̺� ����
    SELECT DISTINCT 
     	t.GG_YM, 
       	t.CORP_NO, 
       	t.BIZ_SIZE,
       	SUM(t.BRNO_DAMBO_AMT) OVER(PARTITION BY t.GG_YM, t.CORP_NO, t.BIZ_SIZE) AS BIZ_DAMBO_AMT,
       	t.EFAS
    FROM 
       	BASIC_BIZ_DAMBO t 
    WHERE 
    	CAST(t.GG_YM AS INTEGER) IN (	-- ��ȸ���س� ���� ���� 3���⵵���� ��ȸ
    		CAST(CONCAT( '${inputYYYY}', '12') as integer),
    		CAST(CONCAT( '${inputYYYY}', '12') as integer) - 100,
    		CAST(CONCAT( '${inputYYYY}', '12') as integer) - 200,
    		CAST(CONCAT( '${inputYYYY}', '12') as integer) - 300)
       	AND t.DAMBO_TYPE = '6' -- �㺸����(�Ѱ�)
       	AND t.BRWR_NO_TP_CD = '3'	-- ���θ�
		AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
    ORDER BY 
      	t.CORP_NO, t.GG_YM
  	) t10, 
  	(
    SELECT DISTINCT 
    	t2.CORP_NO, 
      	t1.* 
    FROM 
      	(
        SELECT 
          t0.COMP_CD, 
          SUBSTR(t0.STD_DT, 1, 6) as STD_YM, 
          t0.TOT_ASSET -- �� �ڻ�
        FROM 
          	(
            SELECT 
              	t.STD_YM, 
              	t.COMP_CD, 
              	t.STD_DT, 
              	ROUND(t.AMT/1000, 0) as TOT_ASSET, -- ���� ��ȯ(õ�� -> �鸸��)
              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ��� 
              	CAST(MAX(TO_NUMBER(t.STD_YM, '999999')) OVER(PARTITION BY t.COMP_CD, t.STD_DT) AS VARCHAR) as LAST_STD_YM 
            FROM 
              	TCB_NICE_FNST t 
            WHERE 
              	t.REPORT_CD = '11' -- ��������ǥ ���̺�
              	AND t.ITEM_CD = '5000' -- ���ڻ� �÷�
              	AND t.SEAC_DIVN = 'K'	-- ��� �÷�
                AND CAST(SUBSTR(t.STD_DT, 1, 4) AS INTEGER)  IN (
                	CAST('${inputYYYY}' as INTEGER),
                	CAST('${inputYYYY}' as INTEGER) - 1,
                	CAST('${inputYYYY}' as INTEGER) - 2,
                	CAST('${inputYYYY}' as INTEGER) - 3)
          	) t0 
        WHERE 
          	t0.STD_YM = t0.LAST_STD_YM -- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ���
      	) t1, TCB_NICE_COMP_OUTL t2 
    WHERE 
      	t1.COMP_CD = t2.COMP_CD -- ����ȣ�� join
    ORDER BY 
      	t2.CORP_NO, t1.STD_YM
  	) t20
WHERE 
  	t10.CORP_NO = t20.CORP_NO 
  	AND t10.GG_YM = t20.STD_YM;
-- ��� ���̺� ��ȸ
SELECT t.* FROM BASIC_BIZ_DAMBO_FLOW_TB t;



/********************************************************************
 * ��� �㺸 ������ - �ڻ� ��� �㺸���� ���� (���� p.1)
 * RFP p.12 [�׸�1] �ڻ� ��� �㺸���� ����
 * ����Ը� �ڻ� ��� �㺸�������� ������ �׷���
 *******************************************************************/
-- (Step1) Calculate IQR cutoff
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
		t.GG_YM,
		t.BIZ_SIZE,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as "LQ",
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as "UQ"	
	FROM 	
		BASIC_BIZ_DAMBO_FLOW_TB t
	) t0;
-- ��� ��ȸ
SELECT * FROM IQRcutOff_TB ORDER BY GG_YM, BIZ_SIZE;



-- (Step2) cutoff ���̺� ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS Cutoff_BASIC_BIZ_DAMBO_FLOW_TB;
-- ���̺� ����
SELECT 
	t1.*
	INTO Cutoff_BASIC_BIZ_DAMBO_FLOW_TB
FROM
	BASIC_BIZ_DAMBO_FLOW_TB t1, IQRcutOff_TB t2
WHERE 
	t1.GG_YM = t2.GG_YM
	AND	t1.BIZ_SIZE = t2.BIZ_SIZE
	AND t1.targetRatio > t2.LowerCutoff
	AND t1.targetRatio < t2.UpperCutoff;
-- ��� ��ȸ
SELECT * FROM Cutoff_BASIC_BIZ_DAMBO_FLOW_TB;



-- (Step3) ����Ը� �ڻ� ��� �㺸�������� ����
DROP TABLE IF EXISTS RESULT_DAMBO_TO_ASSET_RATIO;
SELECT
	t0.GG_YM,
	t0.TOT_DAMBO_TO_ASSET_RATIO,
	SUM(DECODE(t0.BIZ_SIZE, '1', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_BIZ_1",	-- ����
	SUM(DECODE(t0.BIZ_SIZE, '2', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_BIZ_2",	-- �߼ұ��
	SUM(DECODE(t0.BIZ_SIZE, '3', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_BIZ_3"	-- �߰߱��
	INTO RESULT_DAMBO_TO_ASSET_RATIO
FROM 	
	(
	SELECT DISTINCT 
		t.GG_YM, 
		t.BIZ_SIZE,
		-- ����Ը� �ڻ� ��� �㺸�������� ����(Ratio)
		ROUND(AVG(targetRatio) OVER(PARTITION BY t.GG_YM, t.BIZ_SIZE), 4) as "DAMBO_TO_ASSET_RATIO",
		-- ����� �ڻ� ��� �㺸�������� ����(Ratio)
		ROUND(AVG(targetRatio) OVER(PARTITION BY t.GG_YM), 4) as "TOT_DAMBO_TO_ASSET_RATIO"
	FROM 
	  	Cutoff_BASIC_BIZ_DAMBO_FLOW_TB t 
	ORDER BY 
	  	t.GG_YM
	) t0
WHERE 
	t0.BIZ_SIZE in ('1', '2', '3')
GROUP BY
	t0.GG_YM, t0.TOT_DAMBO_TO_ASSET_RATIO
ORDER BY
	t0.GG_YM;
 
 
 
 
  
  
  
  
  
   
/********************************************************************
 * ��� �㺸 ������ - ������ �ڻ� ��� �㺸���� (p.1)
 * RFP p.12 [�׸�2] ������ �ڻ� ��� �㺸����
 * �ֿ� ��� �ֱ� 3���� �׷���
 * (�ڵ���: 37, ����: 39, ö��: 22, ����: 11, ����ȭ��: 12, �ݵ�ü: 26, ���÷���: 27, �ؿ�: 48, �Ǽ�: 45)
 *******************************************************************/
-- (Step1) Calculate IQR cutoff
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
		t.GG_YM,
		t.EFAS,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.GG_YM, t.EFAS) as "LQ",
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY targetRatio) OVER (PARTITION BY t.GG_YM, t.EFAS) as "UQ"	
	FROM 	
		BASIC_BIZ_DAMBO_FLOW_TB t
	) t0;
-- ��� ��ȸ
SELECT * FROM IQRcutOff_TB ORDER BY GG_YM, EFAS;



-- (Step2) cutoff ���̺� ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS Cutoff_BASIC_BIZ_DAMBO_FLOW_TB;
-- ���̺� ����
SELECT 
	t1.*
	INTO Cutoff_BASIC_BIZ_DAMBO_FLOW_TB
FROM
	BASIC_BIZ_DAMBO_FLOW_TB t1, IQRcutOff_TB t2
WHERE 
	t1.GG_YM = t2.GG_YM
	AND	t1.EFAS = t2.EFAS
	AND t1.targetRatio > t2.LowerCutoff
	AND t1.targetRatio < t2.UpperCutoff;
-- ��� ��ȸ
SELECT * FROM Cutoff_BASIC_BIZ_DAMBO_FLOW_TB;



-- (Step3) �ֿ����� �ڻ� ��� �㺸�������� ����
DROP TABLE IF EXISTS RESULT_DAMBO_TO_ASSET_RATIO_EFAS;
SELECT
	t0.GG_YM,
	SUM(DECODE(t0.EFAS, '11', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS11",	-- ����
	SUM(DECODE(t0.EFAS, '12', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS12",	-- ����ȭ��
	SUM(DECODE(t0.EFAS, '22', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS22",	-- ö��
	SUM(DECODE(t0.EFAS, '26', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS26",	-- �ݵ�ü
	SUM(DECODE(t0.EFAS, '27', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS27",	-- ���÷���
	SUM(DECODE(t0.EFAS, '37', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS37",	-- �ڵ���
	SUM(DECODE(t0.EFAS, '39', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS39",	-- ����
	SUM(DECODE(t0.EFAS, '45', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS45",	-- �Ǽ�
	SUM(DECODE(t0.EFAS, '48', t0.DAMBO_TO_ASSET_RATIO, 0)) as "DAMBO_TO_ASSET_RATIO_EFAS48"		-- �ؿ�
	INTO RESULT_DAMBO_TO_ASSET_RATIO_EFAS
FROM 	
	(
	SELECT DISTINCT 
		t.GG_YM, 
		t.EFAS,
		-- �ֿ����� �ڻ� ��� �㺸�������� ����(Ratio)
		ROUND(AVG(targetRatio) OVER(PARTITION BY t.GG_YM, t.EFAS), 4) as "DAMBO_TO_ASSET_RATIO"
	FROM 
	  	Cutoff_BASIC_BIZ_DAMBO_FLOW_TB t 
	ORDER BY 
	  	t.GG_YM
	) t0
WHERE 
	t0.EFAS in ('37', '39', '22', '11', '12', '26', '27', '48', '45')
GROUP BY
	t0.GG_YM
ORDER BY
	t0.GG_YM;
	


-- �ӽ����̺� ����
DROP TABLE IF EXISTS BASIC_BIZ_DAMBO_FLOW_TB;
DROP TABLE IF EXISTS IQRcutOff_TB;
DROP TABLE IF EXISTS Cutoff_BASIC_BIZ_DAMBO_FLOW_TB;


-- ��� ��ȸ
SELECT * FROM RESULT_DAMBO_TO_ASSET_RATIO ORDER BY GG_YM;
SELECT * FROM RESULT_DAMBO_TO_ASSET_RATIO_EFAS ORDER BY GG_YM;