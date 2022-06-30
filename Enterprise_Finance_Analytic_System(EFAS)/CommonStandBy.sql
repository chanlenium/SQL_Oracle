/**************************************
 * ������� �⺻���̺�(BIZ_RAW) ����      
 **************************************/
-- (STEP_1) KSIC Table ���� (�������� RAW ���̺�)
-- Ȱ�� ���̺� : TCB_NICE_COMP_OUTL (NICE��� ���� ���̺�) -> KSIC_RAW�� ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS KSIC_RAW;
-- Table ���� (���س��, NICE����ȣ, ����ڹ�ȣ, ���ι�ȣ, ����Ը�(��/��/��), �ܰ�����, ���屸��, KSIC)
SELECT 
	t.STD_YM, 
	t.COMP_CD,	-- NICE ��ü ���� ID
	t.BRNO,	-- ����ڹ�ȣ
	t.CORP_NO,	-- ���ι�ȣ
	t.COMP_SCL_DIVN_CD as BIZ_SIZE,  -- ����Ը�
	t.OSIDE_ISPT_YN,	-- �ܺΰ��翩��
	t.BLIST_MRKT_DIVN_CD,	-- ���忩��(1: �ڽ���, 2: �ڽ���)
	SUBSTR(t.STDD_INDU_CLSF_CD, 2) as KSIC 
	INTO KSIC_RAW -- KSIC���� ����
FROM 
  	TCB_NICE_COMP_OUTL t
WHERE t.BRNO is not NULL 
	AND t.CORP_NO is not NULL;
-- �߰���� ���̺� ��ȸ
SELECT t1.* FROM KSIC_RAW t1;


-- (STEP_2) KSIC ����
-- Ȱ�� ���̺� : KSIC_RAW (�������� ���� KSIC ���̺�) -> KSIC_INTERPOLATION�� ���� (NICE ������� ���̺� �������� �ִ��� KSIC�� ������)
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS KSIC_INTERPOLATION;
-- Table ���� (���س��, ���ι�ȣ, NICE����ȣ, ����ڹ�ȣ, ����Ը�(��1/�߼�2/�߰�3), �ܰ�����, ���屸��, KSIC)
SELECT 
	DISTINCT t10.STD_YM, 
	t10.CORP_NO, 
	t20.COMP_CD, 
	t20.BRNO,
	t20.BIZ_SIZE,
	t20.OSIDE_ISPT_YN,
	t20.BLIST_MRKT_DIVN_CD,
	t20.KSIC 
	INTO KSIC_INTERPOLATION
FROM
	(
	SELECT 
	 	t1.STD_YM, 
	 	t1.CORP_NO, 
	 	NVL(
	 		To_number(t1.STD_YM, '999999') - MIN(CASE WHEN t1.STD_YM >= t2.STD_YM THEN (To_number(t1.STD_YM, '999999') - To_number(t2.STD_YM, '999999')) ELSE NULL END), 
	 		MIN(To_number(t2.STD_YM, '999999'))
	 	) AS KSIC_REF_YM 
	FROM 
		KSIC_RAW t1
	  	LEFT JOIN (SELECT t2.* FROM KSIC_RAW t2 WHERE t2.KSIC is not null) t2
	  	ON t1.CORP_NO = t2.CORP_NO
	GROUP BY t1.STD_YM, t1.CORP_NO
	) t10 
	LEFT JOIN KSIC_RAW t20 
		ON t10.CORP_NO = t20.CORP_NO AND t10.KSIC_REF_YM = t20.STD_YM
	ORDER BY t10.CORP_NO, t10.STD_YM;
-- �߰���� ���̺� ��ȸ
SELECT t1.* FROM KSIC_INTERPOLATION t1;


-- (STEP_3) �ſ���� ���� ��� ����Ʈ Table ����
-- Ȱ�����̺� : CORP_BIZ_DATA -> CRE_BIZ_LIST�� ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS CRE_BIZ_LIST;
-- Table ���� (���س��, ���ι�ȣ, ����ڹ�ȣ)
SELECT DISTINCT 
	t.GG_YM, 
	CASE WHEN LENGTH(TRIM(t.CORP_NO)) > 13 THEN 'IND_BIZ' ELSE TRIM(t.CORP_NO) END as CORP_NO,	-- ���λ���� ǥ��
	SUBSTR(t.BRNO, 4) as BRNO
	INTO CRE_BIZ_LIST
FROM CORP_BIZ_DATA t
WHERE t.RPT_CD = '31'	-- ���� ��ȣ 
	AND t.ACCT_CD IN ('1901') -- ('1901', '5301', '1391') 
	AND CAST(t.GG_YM AS INT) >= 201812 
	AND t.SOI_CD IN (
		'01', '03', '05', '07', '11', '13', '15', 
		'21', '31', '33', '35', '37', '41', 
		'43', '44', '46', '47', '61', '71', 
		'74', '75', '76', '77', '79', '81', 
		'83', '85', '87', '89', '91', '94', 
		'95', '97'
	)
	AND t.BRWR_NO_TP_CD in ('1', '3');	-- ���ΰ� ���θ� ����
-- �߰���� ���̺� ��ȸ
SELECT * FROM CRE_BIZ_LIST WHERE CORP_NO <> 'IND_BIZ' ORDER BY GG_YM DESC;


-- (STEP_4) CRE_BIZ_LIST�� ���س��(GG_YM)�� KSIC_INTERPOLATION�� ���س��(STD_YM) ������ ���Ͽ� 'KSIC���� ��Ģ�� ����' KSIC ������� �����͸� ������
-- Ȱ�����̺� : CRE_BIZ_LIST, KSIC_INTERPOLATION -> BIZ_KSIC_HIST�� ����
-- KSIC �̷����� ���� ����� KSIC�� NULL�� �ڵ�
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BIZ_KSIC_HIST;
-- KSIC�̷� ���̺� ����(���س��, ���ι�ȣ, ����ڹ�ȣ, KSIC, ����Ը�, �ܰ�����, ���屸��)
SELECT DISTINCT -- LEFT JOIN�� �ϴ��� multiple match�� ������ row ���� �����ϹǷ� DISTINCT ����
	t10.GG_YM, 
	t10.CORP_NO, 
	t10.BRNO,
	t20.KSIC, 
	t20.BIZ_SIZE,
	t20.OSIDE_ISPT_YN,
	t20.BLIST_MRKT_DIVN_CD
	INTO BIZ_KSIC_HIST 
FROM 
	(
    SELECT 
    	t1.GG_YM, 
      	t1.CORP_NO,
      	t1.BRNO,
      	NVL(
	 		To_number(t1.GG_YM, '999999') - 
	 		MIN(CASE WHEN t1.GG_YM >= t2.STD_YM THEN (To_number(t1.GG_YM, '999999') - To_number(t2.STD_YM, '999999')) ELSE NULL END) OVER(PARTITION BY t1.GG_YM, t1.CORP_NO), 
	 		MIN(To_number(t2.STD_YM, '999999')) OVER(PARTITION BY t1.GG_YM, t1.CORP_NO)
	 	) AS KSIC_REF_YM
    FROM 
      	CRE_BIZ_LIST t1
      	LEFT JOIN KSIC_INTERPOLATION t2 
      		ON t1.CORP_NO = t2.CORP_NO 
	) t10 
  	LEFT JOIN KSIC_INTERPOLATION t20 
  		ON t10.CORP_NO = t20.CORP_NO AND t10.KSIC_REF_YM = t20.STD_YM;
-- �߰���� ���̺� ��ȸ
SELECT * FROM BIZ_KSIC_HIST ORDER BY CORP_NO, GG_YM DESC;
	
	
-- (STEP_5) KSIC to EFAS code ���� : KSIC�� �������� EFAS�ڵ�(�����ڵ�)�� ����      
-- Ȱ�����̺� : BIZ_KSIC_HIST, KSICTOEFIS66 -> BIZ_KSIC_EFAS_HIST ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BIZ_KSICtoEFAS_HIST;
-- ���̺� ���� (���س��, ���ι�ȣ, ����ڹ�ȣ, KSIC, EFIS, ����Ը�, �ܰ�����, ���������ڵ�)
SELECT DISTINCT 
	t1.GG_YM, 
	t1.CORP_NO,
	t1.BRNO,
	t1.KSIC,
	t2.EFIS,
	t1.BIZ_SIZE,
	t1.OSIDE_ISPT_YN,
	t1.BLIST_MRKT_DIVN_CD
	INTO BIZ_KSICtoEFAS_HIST
FROM 
	BIZ_KSIC_HIST t1 
	LEFT JOIN KSICTOEFIS66 t2 
	ON t1.KSIC = t2.KSIC;
-- ��� ���̺� ��ȸ
SELECT * FROM BIZ_KSICtoEFAS_HIST ORDER BY GG_YM DESC;





/**************************************
 * �ſ��� �̷����� ȹ��(interpolation)
 * �ſ��� ���̺�(TCB_NICE_COMP_CRDT_CLSS)�� �ҿ���(��������)�ϹǷ� ���� �ſ���������� �ִ� ��� ����� ���� �ſ����� �������� ����
 * �ſ���(CRI) ���� ��Ģ : (1) �ش� ����� CRI������ ������ ���� �ֱ� ���� CRI�� ����� ����
 *                      (2) ���� �ֱ� ���� CRI�� ������, �ش� ����� �������� ���� ����� �̷��� CRI�� ����� �� 
 **************************************/
-- (STEP_1) ����� ���� �ֱ� �ſ������ڿ� �ش��ϴ� �ſ��� ����
-- Ȱ�����̺� : TCB_NICE_COMP_CRDT_CLSS, TCB_NICE_COMP_OUTL -> CORP_CRI�� ����
-- ���� ������ �� ����� �ټ� �ſ����� �ִ� ��� ���� ��� ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS CORP_CRI;
-- Table ���� (��޽��۳��, ���ι�ȣ, ����ڹ�ȣ, �ſ���)
SELECT DISTINCT 
	t1000.LAST_CRI_YM,
	t2000.CORP_NO, 
  	t2000.BRNO,
  	-- ���ι�ȣ ����(COMP_CD�� CORP ����)
  	-- ���ϳ���� ����ȣ(COMP_CD)�� 2���� ����� ����. 
  	-- �� ��� old COMP_CD���� �ſ��� ������ ���� 1(�ſ��޹̺ο��Ǵ¾���)�� �Ҵ�Ǵ� �ݸ�, new COMP_CD���� �ش� ����� �ſ������� �Ҵ��
  	-- new COMP_CD�� old COMP_CD�� ������ ��� �ϳ��� ���ι�ȣ�� ���ϳ���� 2���� �ſ����� ��Ÿ���Ƿ�, 
  	-- �� ��� MAX�Լ��� ����Ͽ� new COMP_CD�� �ο��� �ſ����� ���������� ���� ���� (���� query�� distinct�� ������ ó��)
  	MAX(t1000.CORP_CRI) OVER(PARTITION BY t2000.CORP_NO, t1000.LAST_CRI_YM) AS CORP_CRI 
  	INTO CORP_CRI 
FROM 
  	(
    SELECT 
      	t100.COMP_CD, 
      	t100.LAST_CRI_YM, 
      	MIN(t100.LAST_CRI_CLSS) AS CORP_CRI -- ���� ������ �� ����� �ټ� �ſ����� �ִ� ��� ���� ��� ����
    FROM 
      	(
        SELECT 
          	t10.COMP_CD, 
          	SUBSTR(CAST(t10.LAST_CLSS_START_DT AS VARCHAR(8)), 1, 6) AS LAST_CRI_YM, 
          	-- �ſ��� ġȯ (����: 4, ����: 3, ��ȯ�Ҵ�: 2, �ſ��޹̺ο��Ǵ¾���: 1)
          	CASE 
          		WHEN t20.CRI_CLSS = 'AAA+' THEN 24 
          		WHEN t20.CRI_CLSS = 'AA+' THEN 23 
          		WHEN t20.CRI_CLSS = 'AA0' THEN 22 
          		WHEN t20.CRI_CLSS = 'AA-' THEN 21 
          		WHEN t20.CRI_CLSS = 'A+' THEN 20 
          		WHEN t20.CRI_CLSS = 'A0' THEN 19 
          		WHEN t20.CRI_CLSS = 'A-' THEN 18 
          		WHEN t20.CRI_CLSS = 'BBB+' THEN 17 
          		WHEN t20.CRI_CLSS = 'BBB0' THEN 16 
          		WHEN t20.CRI_CLSS = 'BBB-' THEN 15 
          		WHEN t20.CRI_CLSS = 'BB+' THEN 14 
          		WHEN t20.CRI_CLSS = 'BB0' THEN 13 
          		WHEN t20.CRI_CLSS = 'BB-' THEN 12 
          		WHEN t20.CRI_CLSS = 'B+' THEN 11 
          		WHEN t20.CRI_CLSS = 'B0' THEN 10 
          		WHEN t20.CRI_CLSS = 'B-' THEN 9 
          		WHEN t20.CRI_CLSS = 'CCC+' THEN 8 
          		WHEN t20.CRI_CLSS = 'CCC0' THEN 7 
          		WHEN t20.CRI_CLSS = 'CCC-' THEN 6 
          		WHEN t20.CRI_CLSS = 'CC+' THEN 5 
          		WHEN t20.CRI_CLSS = 'C+' THEN 4 
          		WHEN t20.CRI_CLSS = 'D' THEN 3 
          		WHEN t20.CRI_CLSS = 'R' THEN 2 
          		WHEN t20.CRI_CLSS = 'NR' THEN 1 
          		ELSE NULL 
          		END AS LAST_CRI_CLSS 
        FROM 
          	(
            SELECT 
            	t1.COMP_CD, 
              	MAX(to_number(t1.CLSS_START_DT, '99999999')) AS LAST_CLSS_START_DT -- ����� ���� �ֱ� �ſ����� ���� ����
            FROM 
              	TCB_NICE_COMP_CRDT_CLSS t1 
            GROUP BY 
              	t1.COMP_CD
          	) AS t10, 
          	TCB_NICE_COMP_CRDT_CLSS t20 
        WHERE 
        	t10.COMP_CD = t20.COMP_CD 
          	AND t10.LAST_CLSS_START_DT = t20.CLSS_START_DT
      	) t100 
    	GROUP BY 
      	t100.COMP_CD, t100.LAST_CRI_YM
  	) t1000, TCB_NICE_COMP_OUTL t2000 
WHERE 
  	t1000.COMP_CD = t2000.COMP_CD;
-- �߰���� ���̺� ��ȸ
SELECT * FROM CORP_CRI;


-- (STEP_2) �ſ���� ���̺� �ſ��� ������ ����
-- Ȱ�����̺� : CRE_BIZ_LIST, CORP_CRI -> BIZ_CRI_HIST�� ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BIZ_CRI_HIST;
-- ���̺� ����(���س��, ���ι�ȣ, ����ڹ�ȣ, �ſ���)
SELECT DISTINCT
	t10.GG_YM, 
	t10.CORP_NO, 
    t10.BRNO, 
	NVL(t20.CORP_CRI, 1) AS CORP_CRI 
	INTO BIZ_CRI_HIST 
FROM 
  	(
    SELECT DISTINCT 
    	t1.GG_YM, 
      	t1.CORP_NO, 
      	t1.BRNO,
      	-- GG_YM�� �������� �ſ��� ������ �ִ� ���� �ֱ� ���� ��� �����͸� �ҷ��� (���� �ֱ� ���� �����Ͱ� ������ ���� �ֱ� �̷� �����͸� �����))
      	NVL(
	 		To_number(t1.GG_YM, '999999') - 
	 		MIN(CASE WHEN t1.GG_YM >= t2.LAST_CRI_YM THEN (To_number(t1.GG_YM, '999999') - To_number(t2.LAST_CRI_YM, '999999')) ELSE NULL END) OVER(PARTITION BY t1.GG_YM, t1.CORP_NO), 
	 		MIN(To_number(t2.LAST_CRI_YM, '999999')) OVER(PARTITION BY t1.GG_YM, t1.CORP_NO)
	 	) AS CRI_REF_YM
    FROM 
    	CRE_BIZ_LIST t1 -- �ſ���� �������Ʈ ���̺�
      	LEFT JOIN CORP_CRI t2 -- �ſ��� ���̺�
      		ON t1.CORP_NO = t2.CORP_NO 
  	) t10 
  	LEFT JOIN CORP_CRI t20 
  		ON (t10.CORP_NO = t20.CORP_NO) AND (t10.CRI_REF_YM = t20.LAST_CRI_YM);
-- ��� ���̺� ��ȸ
SELECT * FROM BIZ_CRI_HIST ORDER BY GG_YM DESC;





/**************************************************
 * ��� ���� ���̺� ���� (BIZ_RAW)
 **************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BIZ_RAW;
-- ���̺� ���� (���س��, ���ι�ȣ, ����ڹ�ȣ, KSIC, �����ڵ�(EFAS), ����Ը�, �ܰ�����, ���屸��, �ſ���)
SELECT DISTINCT
	t1.*, 
  	t2.CORP_CRI 
  	INTO BIZ_RAW
FROM 
  	BIZ_KSICtoEFAS_HIST t1, BIZ_CRI_HIST t2 
WHERE 
  	t1.GG_YM = t2.GG_YM 
  	AND t1.CORP_NO = t2.CORP_NO
  	AND t1.BRNO = t2.BRNO;
-- ��� ���̺� ��ȸ
SELECT * FROM BIZ_RAW ORDER BY GG_YM DESC;




-- ���� ��� ���̺��� �����ϰ�� ��� DROP
DROP TABLE IF EXISTS KSIC_RAW;
DROP TABLE IF EXISTS KSIC_INTERPOLATION;
DROP TABLE IF EXISTS CRE_BIZ_LIST;
DROP TABLE IF EXISTS BIZ_KSIC_HIST;
DROP TABLE IF EXISTS BIZ_KSICtoEFAS_HIST;
DROP TABLE IF EXISTS CORP_CRI;
DROP TABLE IF EXISTS BIZ_CRI_HIST;