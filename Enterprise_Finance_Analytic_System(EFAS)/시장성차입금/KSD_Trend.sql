/***********************************
 * ���强 ���Ա� ���� - �Ⱓ��� ���强 ���Ա� �����(��ü, �Ϲ�ȸ��ä, CP, �ܱ��ä) - ȭ�����Ǽ� p.43
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_Infra_SEC_AMT;
-- (Step1) �� �����, ���Ա� ������ �����
SELECT DISTINCT	
	t0.GG_YM,
	t0.EFAS,
	SUBSTR(t0.SEC_ACCT_CD, 1, 1) as KSD_GBN,	--(�Ϲ�ȸ��ä:1, �ܱ��ä:2, CP:3)
	SUM(t0.SEC_AMT) OVER (PARTITION BY t0.GG_YM, t0.EFAS, SUBSTR(t0.SEC_ACCT_CD, 1, 1)) as SEC_AMT
	INTO RESULT_KSD_Infra_SEC_AMT
FROM
	KSD_InfraStandBy t0;

-- (Step2) �� ��� ���Ա� ������ ����� �հ� �߰�
INSERT INTO RESULT_KSD_Infra_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.EFAS,
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS)
FROM
	RESULT_KSD_Infra_SEC_AMT t;

-- (Step3) ����� ���Ա� ������ ����� �߰�
INSERT INTO RESULT_KSD_Infra_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.KSD_GBN)
FROM
	(SELECT * FROM RESULT_KSD_Infra_SEC_AMT WHERE KSD_GBN <> '0') t;

-- (Step4) ����� ���Ա� ������ ����� �հ� �߰�
INSERT INTO RESULT_KSD_Infra_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_Infra_SEC_AMT WHERE KSD_GBN <> '0' AND EFAS <> '00') t;





/***********************************
 * ���强 ���Ա� ���� - �Ż�� ���强 ���Ա� �����(��ü, �Ϲ�ȸ��ä, CP, �ܱ��ä) - ȭ�����Ǽ� p.43
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_NewIndu_SEC_AMT;
-- (Step1) �� �����, ���Ա� ������ �ܾ�
SELECT DISTINCT	
	t0.GG_YM,
	t0.NEW_INDU_CODE,
	SUBSTR(t0.SEC_ACCT_CD, 1, 1) as KSD_GBN,	--(�Ϲ�ȸ��ä:1, �ܱ��ä:2, CP:3)
	SUM(t0.SEC_AMT) OVER (PARTITION BY t0.GG_YM, t0.NEW_INDU_CODE, SUBSTR(t0.SEC_ACCT_CD, 1, 1)) as SEC_AMT
	INTO RESULT_KSD_NewIndu_SEC_AMT
FROM
	KSD_NewInduStandBy t0;

-- (Step2) �� ��� ���Ա� ������ �ܾ� �հ� �߰�
INSERT INTO RESULT_KSD_NewIndu_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.NEW_INDU_CODE,
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE)
FROM
	RESULT_KSD_NewIndu_SEC_AMT t;

-- (Step3) ����� ���Ա� ������ �ܾ� �߰�
INSERT INTO RESULT_KSD_NewIndu_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	t.KSD_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.KSD_GBN)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_SEC_AMT WHERE KSD_GBN <> '0') t;

-- (Step4) ����� ���Ա� ������ �ܾ� �հ� �߰�
INSERT INTO RESULT_KSD_NewIndu_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_SEC_AMT WHERE KSD_GBN <> '0' AND NEW_INDU_CODE <> '00') t;





/***********************************
 * ���强 ���Ա� ���� - �Ⱓ��� ���强 ���Ա� �ܾ�(��ü, �Ϲ�ȸ��ä, CP, �ܱ��ä) - ȭ�����Ǽ� p.44
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_Infra_SEC_BAL;
-- (Step1) �� �����, ���Ա� ������ �����
SELECT DISTINCT	
	t0.GG_YM,
	t0.EFAS,
	SUBSTR(t0.SEC_ACCT_CD, 1, 1) as KSD_GBN,	--(�Ϲ�ȸ��ä:1, �ܱ��ä:2, CP:3)
	SUM(t0.SEC_BAL) OVER (PARTITION BY t0.GG_YM, t0.EFAS, SUBSTR(t0.SEC_ACCT_CD, 1, 1)) as SEC_BAL
	INTO RESULT_KSD_Infra_SEC_BAL
FROM
	KSD_InfraStandBy t0;

-- (Step2) �� ��� ���Ա� ������ ����� �հ� �߰�
INSERT INTO RESULT_KSD_Infra_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	t.EFAS,
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.EFAS)
FROM
	RESULT_KSD_Infra_SEC_BAL t;

-- (Step3) ����� ���Ա� ������ ����� �߰�
INSERT INTO RESULT_KSD_Infra_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	t.KSD_GBN,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.KSD_GBN)
FROM
	(SELECT * FROM RESULT_KSD_Infra_SEC_BAL WHERE KSD_GBN <> '0') t;

-- (Step4) ����� ���Ա� ������ ����� �հ� �߰�
INSERT INTO RESULT_KSD_Infra_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_Infra_SEC_BAL WHERE KSD_GBN <> '0' AND EFAS <> '00') t;





/***********************************
 * ���强 ���Ա� ���� - �Ż�� ���强 ���Ա� �ܾ�(��ü, �Ϲ�ȸ��ä, CP, �ܱ��ä) - ȭ�����Ǽ� p.44
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_NewIndu_SEC_BAL;
-- (Step1) �� �����, ���Ա� ������ �ܾ�
SELECT DISTINCT	
	t0.GG_YM,
	t0.NEW_INDU_CODE,
	SUBSTR(t0.SEC_ACCT_CD, 1, 1) as KSD_GBN,	--(�Ϲ�ȸ��ä:1, �ܱ��ä:2, CP:3)
	SUM(t0.SEC_BAL) OVER (PARTITION BY t0.GG_YM, t0.NEW_INDU_CODE, SUBSTR(t0.SEC_ACCT_CD, 1, 1)) as SEC_BAL
	INTO RESULT_KSD_NewIndu_SEC_BAL
FROM
	KSD_NewInduStandBy t0;

-- (Step2) �� ��� ���Ա� ������ �ܾ� �հ� �߰�
INSERT INTO RESULT_KSD_NewIndu_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	t.NEW_INDU_CODE,
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE)
FROM
	RESULT_KSD_NewIndu_SEC_BAL t;

-- (Step3) ����� ���Ա� ������ �ܾ� �߰�
INSERT INTO RESULT_KSD_NewIndu_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	t.KSD_GBN,
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM, t.KSD_GBN)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_SEC_BAL WHERE KSD_GBN <> '0') t;

-- (Step4) ����� ���Ա� ������ �ܾ� �հ� �߰�
INSERT INTO RESULT_KSD_NewIndu_SEC_BAL
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	'0',	-- ���Ա� ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_BAL) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_SEC_BAL WHERE KSD_GBN <> '0' AND NEW_INDU_CODE <> '00') t;





/***********************************
 * ���强 ���Ա� ���� - ������ ���Ա� ���� �����(��ü����ä, �Ϲ�����ä, �Һα���ä, �ſ�ī��ä, ��Ÿ ����ä) - ȭ�����Ǽ� p.45
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_Infra_FIN_SEC_AMT;
-- (Step1) ��������� ����ä ������ �����
SELECT DISTINCT	-- ����ä
	t0.GG_YM,
	t0.EFAS,
	t0.SEC_ACCT_CD as KSD_GBN,	
	SUM(t0.SEC_AMT) OVER (PARTITION BY t0.GG_YM, t0.EFAS, t0.SEC_ACCT_CD) as SEC_AMT
	INTO RESULT_KSD_Infra_FIN_SEC_AMT
FROM
	KSD_InfraStandBy t0
WHERE
	t0.EFAS = '55'	-- ���������
	AND t0.SEC_ACCT_CD in ('11', '12', '13', '14', '15')	--(�Ϲ�ȸ��ä: 11, �Ϲ�����ä: 12, �Һα���ä:13, �ſ�ī��ä:14, ��Ÿ����ä:15)
ORDER BY
	t0.GG_YM, t0.SEC_ACCT_CD;
-- ��� ��ȸ
SELECT * FROM RESULT_KSD_Infra_FIN_SEC_AMT ORDER BY GG_YM, KSD_GBN;

-- (Step2) ��������� ����ä ����� �հ� �߰�
INSERT INTO RESULT_KSD_Infra_FIN_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.EFAS,
	'0',	-- ����ä ������ �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS)
FROM
	RESULT_KSD_Infra_FIN_SEC_AMT t;





-- ��� ��ȸ (���强 ���Ա� ���� - ���强 ���Ա� �����: �Ⱓ���)
SELECT * FROM RESULT_KSD_Infra_SEC_AMT ORDER BY GG_YM, TO_NUMBER(EFAS, '00'), KSD_GBN;
-- ��� ��ȸ (���强 ���Ա� ���� - ���强 ���Ա� �����: �Ż��)
SELECT * FROM RESULT_KSD_NewIndu_SEC_AMT ORDER BY GG_YM, TO_NUMBER(NEW_INDU_CODE, '00'), KSD_GBN;
-- ��� ��ȸ (���强 ���Ա� ���� - ���强 ���Ա� �ܾ�: �Ⱓ���)
SELECT * FROM RESULT_KSD_Infra_SEC_BAL ORDER BY GG_YM, TO_NUMBER(EFAS, '00'), KSD_GBN;
-- ��� ��ȸ (���强 ���Ա� ���� - ���强 ���Ա� �ܾ�: �Ż��)
SELECT * FROM RESULT_KSD_NewIndu_SEC_BAL ORDER BY GG_YM, TO_NUMBER(NEW_INDU_CODE, '00'), KSD_GBN;
-- ��� ��ȸ (���强 ���Ա� ���� - ������ ���Ա� �����: ����������� ����)
SELECT * FROM RESULT_KSD_Infra_FIN_SEC_AMT ORDER BY GG_YM, KSD_GBN;