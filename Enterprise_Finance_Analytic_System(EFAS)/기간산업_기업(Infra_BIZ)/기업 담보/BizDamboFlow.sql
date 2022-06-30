/**************************************
 *             ����㺸 ������(FLOW)           
 * Ȱ�� ���̺� : BASIC_BIZ_DAMBO, TCB_NICE_FNST -> ��� �㺸������ ��� ���̺�(BASIC_BIZ_DAMBO_FLOW) ����
 **************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BASIC_BIZ_DAMBO_FLOW;
-- ���̺� ���� 
SELECT 
  	t10.*, 
  	t20.COMP_CD, 
  	t20.TOT_ASSET   	INTO BASIC_BIZ_DAMBO_FLOW 
FROM 
  	(
    -- ������, ����� �㺸���� �� ���̺� ����
    SELECT DISTINCT 
     	t.GG_YM, 
       	t.CORP_NO, 
       	SUM(t.BRNO_DAMBO_AMT) OVER(PARTITION BY t.GG_YM, t.CORP_NO) AS BIZ_DAMBO_AMT,
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
              	t.AMT as TOT_ASSET, 
              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ��� 
              	CAST(MAX(TO_NUMBER(t.STD_YM, '999999')) OVER(PARTITION BY t.COMP_CD, t.STD_DT) AS VARCHAR) as LAST_STD_YM 
            FROM 
              	TCB_NICE_FNST t 
            WHERE 
              	t.REPORT_CD = '11' -- ��������ǥ ���̺�
              	AND t.ITEM_CD = '5000' -- ���ڻ� �÷�
                AND CAST(t.STD_DT AS INTEGER)  IN (
                	CAST(CONCAT('${inputYYYY}', '1231') as INTEGER),
                	CAST(CONCAT('${inputYYYY}', '1231') as INTEGER) - 10000,
                	CAST(CONCAT('${inputYYYY}', '1231') as INTEGER) - 20000,
                	CAST(CONCAT('${inputYYYY}', '1231') as INTEGER) - 30000)
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
SELECT t.* FROM BASIC_BIZ_DAMBO_FLOW t;
 
 
 


/********************************************************************
 * ��� �㺸 ������ - �ڻ� ��� �㺸���� ���� (p.1)
 * �ڻ� ��� �㺸�������� ������ �׷���
 *******************************************************************/
SELECT DISTINCT 
	t.GG_YM, 
	-- ������ �㺸��������
  	SUM(t.BIZ_DAMBO_AMT) OVER(PARTITION BY t.GG_YM) as DAMBO_YY, 
  	-- ������ ���ڻ�
  	ROUND(SUM(t.TOT_ASSET / 1000) OVER(PARTITION BY t.GG_YM), 0) as TOT_ASSET_YY, 
  	-- �ڻ� ��� �㺸�������� ����(Ratio)
  	ROUND((SUM(t.BIZ_DAMBO_AMT) OVER(PARTITION BY t.GG_YM)) / (SUM(t.TOT_ASSET / 1000) OVER(PARTITION BY t.GG_YM)), 4) as DAMBO_TO_ASSET_RATIO 
FROM 
  	BASIC_BIZ_DAMBO_FLOW t 
ORDER BY 
  	t.GG_YM;
 
 
 
 
 
/********************************************************************
 * ��� �㺸 ������ - ����� �ڻ� ��� �㺸���� (p.1)
 * �ֿ� ��� �ֱ� 3���� �׷���
 * (�ڵ���: 37, ����: 39, ö��: 22, ����: 11, ����ȭ��: 12, �ݵ�ü: 26, ���÷���: 27, �ؿ�: 48, �Ǽ�: 45)
 *******************************************************************/
SELECT DISTINCT 
	TO_NUMBER(t.EFAS, '99'), 
  	t.GG_YM, 
  	-- ������ �㺸��������
  	SUM(t.BIZ_DAMBO_AMT) OVER(PARTITION BY t.GG_YM, t.EFAS) as EFAS_DAMBO_YY, 
  	 -- ������ ���ڻ�
  	ROUND(SUM(t.TOT_ASSET / 1000) OVER(PARTITION BY t.GG_YM, t.EFAS), 0) as EFAS_TOT_ASSET_YY, 
   -- ����� �ڻ� ��� �㺸�������� ����(Ratio)
  	ROUND((SUM(t.BIZ_DAMBO_AMT) OVER(PARTITION BY t.GG_YM, t.EFAS)) / (SUM(t.TOT_ASSET / 1000) OVER(PARTITION BY t.GG_YM, t.EFAS)), 2) as DAMBO_TO_ASSET_RATIO 
FROM 
  	BASIC_BIZ_DAMBO_FLOW t
WHERE t.EFAS in ('37', '39', '22', '11', '12', '26', '27', '48', '45')
ORDER BY 
  	TO_NUMBER(t.EFAS, '99'), 
  	t.GG_YM;