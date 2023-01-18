/***********************************
 * �Ⱓ��� ������ ���强 ���Ա� ��Ȳ (��/�߼�/�߰�, ���Ա���ü(0)/�Ϲ�ȸ��ä(1)/�ܱ��ä(2)/CP(3)) - ȭ�����Ǽ� p.48
 ***********************************/
-- (Step1) �Ⱓ��� ������ ���强 ���Ա� ����, ����, ���⵿�� ������ ������ ���� �ӽ����̺�(temp_KSD_INDU_TB) ����
DROP TABLE IF EXISTS temp_KSD_INDU_TB;
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	t.EFAS,
	SUBSTR(t.SEC_ACCT_CD, 1, 1) as KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS, t.SEC_ACCT_CD) as SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS, t.SEC_ACCT_CD) as SEC_BAL
	INTO temp_KSD_INDU_TB
FROM 
	KSD_InfraStandBy t;
	
INSERT INTO temp_KSD_INDU_TB
SELECT DISTINCT
	t.GG_YM,
	'0',	-- �� ��� BIZ_SIZE '0'�ڵ� �Ҵ�
	t.EFAS,
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS, t.KSD_GBN) as SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.EFAS, t.KSD_GBN) as SEC_BAL
FROM
	temp_KSD_INDU_TB t;

DROP TABLE IF EXISTS temp_KSD_INDU;
SELECT 
	t.*,
	CASE -- ����
		WHEN SUBSTR(t.GG_YM, 5, 2) = '01'	-- 1���� ��� 
		THEN REPLACE(CONCAT(TO_CHAR(SUBSTR(t.GG_YM, 1, 4) - 1, '0000'), '12'), ' ', '')
		ELSE REPLACE(CONCAT(SUBSTR(t.GG_YM, 1, 4), TO_CHAR(SUBSTR(t.GG_YM, 5, 2) - 1, '00')), ' ', '')
	END as prevMM,
	REPLACE(CONCAT(TO_CHAR(SUBSTR(t.GG_YM, 1, 4) - 1, '0000'), TO_CHAR(SUBSTR(t.GG_YM, 5, 2))), ' ', '') as prevYY
	INTO temp_KSD_INDU
FROM 
	temp_KSD_INDU_TB t;
DROP TABLE IF EXISTS temp_KSD_INDU_TB;

-- (Step2) �Ⱓ��� ������ ���强���Ա� ����, ����, ���⵿�� ������ ����
DROP TABLE IF EXISTS RESULT_KSD_Infra_BIZSIZE_SEC_AMT;
SELECT 
	t10.GG_YM,
	t10.BIZ_SIZE,	-- ����Ը�(�����: 0, ����: 1, �߼ұ��: 2, �߰߱��: 3)
	t10.EFAS,
	t10.KSD_GBN,	-- ���强���Ա� ����(ȸ��ä(1)/�ܱ��ä(2)/CP(3))
	t10.SEC_AMT,	-- ���� �����
	t10.prevMM_SEC_AMT,	-- ���� �����
	t20.SEC_AMT as prevYY_SEC_AMT,	-- ���⵿�� �����
	t10.SEC_BAL,	-- ���� �ܾ�
	t10.prevMM_SEC_BAL,	-- ���� �ܾ�
	t20.SEC_BAL as prevYY_SEC_BAL	-- ���⵿�� �ܾ�
	INTO RESULT_KSD_Infra_BIZSIZE_SEC_AMT
FROM
	(
	SELECT 
		t1.*,
		t2.SEC_AMT as prevMM_SEC_AMT,
		t2.SEC_BAL as prevMM_SEC_BAL
	FROM temp_KSD_INDU t1
		LEFT JOIN temp_KSD_INDU t2
		ON
			t1.prevMM = t2.GG_YM 
			AND t1.BIZ_SIZE = t2.BIZ_SIZE
			AND t1.EFAS = t2.EFAS
			AND t1.KSD_GBN = t2.KSD_GBN
	ORDER BY t1.GG_YM
	) t10
	LEFT JOIN temp_KSD_INDU t20
	ON 
		t10.prevYY = t20.GG_YM
		AND t10.BIZ_SIZE = t20.BIZ_SIZE
		AND t10.EFAS = t20.EFAS
		AND t10.KSD_GBN = t20.KSD_GBN
ORDER BY
	t10.GG_YM, t10.BIZ_SIZE, t10.EFAS, t10.KSD_GBN;

-- (Step3) �Ⱓ��� ������ ���强���Ա� �հ� �߰�
INSERT INTO RESULT_KSD_Infra_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	t.EFAS,
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.EFAS) as prevYY_SEC_BAL
FROM
	RESULT_KSD_Infra_BIZSIZE_SEC_AMT t;

-- (Step4) �Ⱓ��� ����� ���强���Ա�(�Ϲ�ȸ��ä/�ܱ��ä/CP) ������ �߰�
INSERT INTO RESULT_KSD_Infra_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	'00',	-- ������� '99'�ڵ� �Ҵ�
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevYY_SEC_BAL
FROM
	(SELECT * FROM RESULT_KSD_Infra_BIZSIZE_SEC_AMT WHERE KSD_GBN <> '0') t;

-- (Step5) �Ⱓ��� ����� ���强���Ա� �հ� �߰�
INSERT INTO RESULT_KSD_Infra_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	'00',	-- ������� '99'�ڵ� �Ҵ�
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevYY_SEC_BAL
FROM
	(SELECT * FROM RESULT_KSD_Infra_BIZSIZE_SEC_AMT WHERE KSD_GBN <> '0' AND EFAS <> '00') t;





/***********************************
 * �Ż�� ������ ���强 ���Ա� ��Ȳ (��/�߼�/�߰�, ���Ա���ü(0)/�Ϲ�ȸ��ä(1)/�ܱ��ä(2)/CP(3)) - ȭ�����Ǽ� p.48
 ***********************************/
-- (Step1) �Ż�� ������ ���强 ���Ա� ����, ����, ���⵿�� ������ ������ ���� �ӽ����̺�(temp_KSD_INDU_TB) ����
DROP TABLE IF EXISTS temp_KSD_INDU_TB;
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	t.NEW_INDU_CODE,
	SUBSTR(t.SEC_ACCT_CD, 1, 1) as KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE, t.SEC_ACCT_CD) as SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE, t.SEC_ACCT_CD) as SEC_BAL
	INTO temp_KSD_INDU_TB
FROM 
	KSD_NewInduStandBy t;
	
INSERT INTO temp_KSD_INDU_TB
SELECT DISTINCT
	t.GG_YM,
	'0',	-- �� ��� BIZ_SIZE '0'�ڵ� �Ҵ�
	t.NEW_INDU_CODE,
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE, t.KSD_GBN) as SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE, t.KSD_GBN) as SEC_BAL
FROM
	temp_KSD_INDU_TB t;

DROP TABLE IF EXISTS temp_KSD_INDU;
SELECT 
	t.*,
	CASE -- ����
		WHEN SUBSTR(t.GG_YM, 5, 2) = '01'	-- 1���� ��� 
		THEN REPLACE(CONCAT(TO_CHAR(SUBSTR(t.GG_YM, 1, 4) - 1, '0000'), '12'), ' ', '')
		ELSE REPLACE(CONCAT(SUBSTR(t.GG_YM, 1, 4), TO_CHAR(SUBSTR(t.GG_YM, 5, 2) - 1, '00')), ' ', '')
	END as prevMM,
	REPLACE(CONCAT(TO_CHAR(SUBSTR(t.GG_YM, 1, 4) - 1, '0000'), TO_CHAR(SUBSTR(t.GG_YM, 5, 2))), ' ', '') as prevYY
	INTO temp_KSD_INDU
FROM 
	temp_KSD_INDU_TB t;
DROP TABLE IF EXISTS temp_KSD_INDU_TB;

-- (Step2) �Ż�� ������ ���强���Ա� ����, ����, ���⵿�� ������ ����
DROP TABLE IF EXISTS RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT;
SELECT 
	t10.GG_YM,
	t10.BIZ_SIZE,	-- ����Ը�(�����: 0, ����: 1, �߼ұ��: 2, �߰߱��: 3)
	t10.NEW_INDU_CODE,
	t10.KSD_GBN,	-- ���强���Ա� ����(ȸ��ä(1)/�ܱ��ä(2)/CP(3))
	t10.SEC_AMT,	-- ���� �����
	t10.prevMM_SEC_AMT,	-- ���� �����
	t20.SEC_AMT as prevYY_SEC_AMT,	-- ���⵿�� �����
	t10.SEC_BAL,	-- ���� �ܾ�
	t10.prevMM_SEC_BAL,	-- ���� �ܾ�
	t20.SEC_BAL as prevYY_SEC_BAL	-- ���⵿�� �ܾ�
	INTO RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT
FROM
	(
	SELECT 
		t1.*,
		t2.SEC_AMT as prevMM_SEC_AMT,
		t2.SEC_BAL as prevMM_SEC_BAL
	FROM temp_KSD_INDU t1
		LEFT JOIN temp_KSD_INDU t2
		ON
			t1.prevMM = t2.GG_YM 
			AND t1.BIZ_SIZE = t2.BIZ_SIZE
			AND t1.NEW_INDU_CODE = t2.NEW_INDU_CODE
			AND t1.KSD_GBN = t2.KSD_GBN
	ORDER BY t1.GG_YM
	) t10
	LEFT JOIN temp_KSD_INDU t20
	ON 
		t10.prevYY = t20.GG_YM
		AND t10.BIZ_SIZE = t20.BIZ_SIZE
		AND t10.NEW_INDU_CODE = t20.NEW_INDU_CODE
		AND t10.KSD_GBN = t20.KSD_GBN
ORDER BY
	t10.GG_YM, t10.BIZ_SIZE, t10.NEW_INDU_CODE, t10.KSD_GBN;

-- (Step3) �Ż�� ������ ���强���Ա� �հ� �߰�
INSERT INTO RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	t.NEW_INDU_CODE,
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.NEW_INDU_CODE) as prevYY_SEC_BAL
FROM
	RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT t;

-- (Step4) �Ż�� ����� ���强���Ա�(�Ϲ�ȸ��ä/�ܱ��ä/CP) ������ �߰�
INSERT INTO RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	'00',	-- ������� '99'�ڵ� �Ҵ�
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE, t.KSD_GBN) as prevYY_SEC_BAL
FROM
	(SELECT * FROM RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT WHERE KSD_GBN <> '0') t;

-- (Step5) �Ż�� ����� ���强���Ա� �հ� �߰�
INSERT INTO RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.BIZ_SIZE,
	'00',	-- ������� '99'�ڵ� �Ҵ�
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as SEC_AMT,
	SUM(t.prevMM_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevMM_SEC_AMT,
	SUM(t.prevYY_SEC_AMT) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevYY_SEC_AMT,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as SEC_BAL,
	SUM(t.prevMM_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevMM_SEC_BAL,
	SUM(t.prevYY_SEC_BAL) OVER (PARTITION BY t.GG_YM, t.BIZ_SIZE) as prevYY_SEC_BAL
FROM
	(SELECT * FROM RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT WHERE KSD_GBN <> '0' AND NEW_INDU_CODE <> '00') t;





-- ��� ��ȸ (���强 ���Ա� ����� �м� - ������ ���强 ���Ա� ��Ȳ: �Ⱓ���)
SELECT * FROM RESULT_KSD_Infra_BIZSIZE_SEC_AMT ORDER BY GG_YM, BIZ_SIZE, EFAS, KSD_GBN;
-- ��� ��ȸ (���强 ���Ա� ����� �м� - ������ ���强 ���Ա� ��Ȳ: �Ż��)
SELECT * FROM RESULT_KSD_NewINDU_BIZSIZE_SEC_AMT ORDER BY GG_YM, BIZ_SIZE, NEW_INDU_CODE, KSD_GBN;
