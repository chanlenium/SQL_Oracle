/***********************************
 * ���强 ���Ա� ������Ȳ - �Ⱓ��� ȸ��ä ���⺰ ���� ����(��ü, �ܱ�ä, �߱�ä, ���ä) - ȭ�����Ǽ� p.46
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_Infra_MANGI_SEC_AMT;
-- (Step1) �� �����, ȸ��ä ������(�ܱ�ä/�߱�ä/�ܱ�ä) �����
SELECT DISTINCT	
	t0.GG_YM,
	t0.EFAS,
	t0.MANGI_GBN,
	SUM(t0.SEC_AMT) OVER (PARTITION BY t0.GG_YM, t0.EFAS, t0.MANGI_GBN) as SEC_AMT
	INTO RESULT_KSD_Infra_MANGI_SEC_AMT
FROM
	(
	SELECT 
		t.*,
		CAST(t.SEC_ISS_DT as DATE) as SEC_ISS_DT_D,
		CAST(t.SEC_MATU_DT as DATE) as SEC_MATU_DT_D,
		SEC_MATU_DT_D - SEC_ISS_DT_D as date_Diff,
		CASE -- ���� ����
			WHEN date_Diff < 365 THEN '1'	-- �ܱ�ä(1)
			WHEN date_Diff BETWEEN 365 AND 365 * 5 THEN '2'	-- �߱�ä(2)
			WHEN date_Diff > 365 * 5 THEN '3'	-- ���ä(3)
		END as MANGI_GBN
	FROM 
		KSD_InfraStandBy t
	WHERE
		SUBSTR(t.SEC_ACCT_CD, 1, 1) = '1'	-- �Ϲ�ȸ��ä
	)t0;

-- (Step2) �� ����� �Ϲ�ȸ��ä ����� �հ� �߰�
INSERT INTO RESULT_KSD_Infra_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.EFAS,
	'0',	-- ���Ա� �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS)
FROM
	RESULT_KSD_Infra_MANGI_SEC_AMT t;

-- (Step3) ����� ���⺰(�ܱ�ä/�߱�ä/�ܱ�ä) �Ϲ�ȸ��ä ����� �߰�
INSERT INTO RESULT_KSD_Infra_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	t.MANGI_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.MANGI_GBN)
FROM
	(SELECT * FROM RESULT_KSD_Infra_MANGI_SEC_AMT WHERE MANGI_GBN <> '0') t;

-- (Step4) ����� �Ϲ�ȸ��ä ����� �հ� �߰�
INSERT INTO RESULT_KSD_Infra_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	'0',	-- ���Ա� �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_Infra_MANGI_SEC_AMT WHERE MANGI_GBN <> '0' AND EFAS <> '00') t;





/***********************************
 * ���强 ���Ա� ������Ȳ - �Ż�� ȸ��ä ���⺰ ���� ����(��ü, �ܱ�ä, �߱�ä, ���ä) - ȭ�����Ǽ� p.46
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_NewIndu_MANGI_SEC_AMT;
-- (Step1) �� �����, ȸ��ä ������(�ܱ�ä/�߱�ä/�ܱ�ä) �����
SELECT DISTINCT	
	t0.GG_YM,
	t0.NEW_INDU_CODE,
	t0.MANGI_GBN,
	SUM(t0.SEC_AMT) OVER (PARTITION BY t0.GG_YM, t0.NEW_INDU_CODE, t0.MANGI_GBN) as SEC_AMT
	INTO RESULT_KSD_NewIndu_MANGI_SEC_AMT
FROM
	(
	SELECT 
		t.*,
		CAST(t.SEC_ISS_DT as DATE) as SEC_ISS_DT_D,
		CAST(t.SEC_MATU_DT as DATE) as SEC_MATU_DT_D,
		SEC_MATU_DT_D - SEC_ISS_DT_D as date_Diff,
		CASE -- ���� ����
			WHEN date_Diff < 365 THEN '1'	-- �ܱ�ä(1)
			WHEN date_Diff BETWEEN 365 AND 365 * 5 THEN '2'	-- �߱�ä(2)
			WHEN date_Diff > 365 * 5 THEN '3'	-- ���ä(3)
		END as MANGI_GBN
	FROM 
		KSD_NewInduStandBy t
	WHERE
		SUBSTR(t.SEC_ACCT_CD, 1, 1) = '1'	-- �Ϲ�ȸ��ä
	)t0;

-- (Step2) �� ����� �Ϲ�ȸ��ä ����� �հ� �߰�
INSERT INTO RESULT_KSD_NewIndu_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.NEW_INDU_CODE,
	'0',	-- ���Ա� �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE)
FROM
	RESULT_KSD_NewIndu_MANGI_SEC_AMT t;

-- (Step3) ����� ���⺰(�ܱ�ä/�߱�ä/�ܱ�ä) �Ϲ�ȸ��ä ����� �߰�
INSERT INTO RESULT_KSD_NewIndu_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	t.MANGI_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.MANGI_GBN)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_MANGI_SEC_AMT WHERE MANGI_GBN <> '0') t;

-- (Step4) ����� �Ϲ�ȸ��ä ����� �հ� �߰�
INSERT INTO RESULT_KSD_NewIndu_MANGI_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	'0',	-- ���Ա� �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_NewIndu_MANGI_SEC_AMT WHERE MANGI_GBN <> '0' AND NEW_INDU_CODE <> '00') t;





/***********************************
 * ���强 ���Ա� ������Ȳ - �Ⱓ��� CP/�ܱ��ä ������ ��Ȳ(��ü, ABCP, PF-ABCP, AB�ܱ��ä, PF-AB�ܱ��ä) - ȭ�����Ǽ� p.47
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_Infra_CPSHORT_SEC_AMT;
-- (Step1) �� �����, CP(ABCP/PF-ABCP) �� �ܱ��ä(AB�ܱ��ä/PF-AB�ܱ��ä) ������ �����
SELECT DISTINCT	
	t.GG_YM,
	t.EFAS,
	t.SEC_ACCT_CD as CP_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS, t.SEC_ACCT_CD) as SEC_AMT	
	INTO RESULT_KSD_Infra_CPSHORT_SEC_AMT
FROM 
	KSD_InfraStandBy t
WHERE
	t.SEC_ACCT_CD in ('22', '23', '32', '33'); -- (AB�ܱ��ä: 22, PF-AB�ܱ��ä: 23, ABCP: 32, PF-ABCP: 33)

-- (Step2) �� ����� CP/�ܱ��ä ����� �հ� �߰�
INSERT INTO RESULT_KSD_Infra_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.EFAS,
	'0',	-- ���Ա� �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.EFAS)
FROM
	RESULT_KSD_Infra_CPSHORT_SEC_AMT t;

-- (Step3) ����� CP(ABCP/PF-ABCP) �� �ܱ��ä(AB�ܱ��ä/PF-AB�ܱ��ä) ������ ����� �߰�
INSERT INTO RESULT_KSD_Infra_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	t.CP_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.CP_GBN)
FROM
	(SELECT * FROM RESULT_KSD_Infra_CPSHORT_SEC_AMT WHERE CP_GBN <> '0') t;

-- (Step4) ����� CP/�ܱ��ä ����� �հ� �߰�
INSERT INTO RESULT_KSD_Infra_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	'0',	-- ���Ա� �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_Infra_CPSHORT_SEC_AMT WHERE CP_GBN <> '0' AND EFAS <> '00') t;





/***********************************
 * ���强 ���Ա� ������Ȳ - �Ż�� CP/�ܱ��ä ������ ��Ȳ(��ü, ABCP, PF-ABCP, AB�ܱ��ä, PF-AB�ܱ��ä) - ȭ�����Ǽ� p.47
 ***********************************/
DROP TABLE IF EXISTS RESULT_KSD_NewINDU_CPSHORT_SEC_AMT;
-- (Step1) �� �����, CP(ABCP/PF-ABCP) �� �ܱ��ä(AB�ܱ��ä/PF-AB�ܱ��ä) ������ �����
SELECT DISTINCT	
	t.GG_YM,
	t.NEW_INDU_CODE,
	t.SEC_ACCT_CD as CP_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE, t.SEC_ACCT_CD) as SEC_AMT	
	INTO RESULT_KSD_NewINDU_CPSHORT_SEC_AMT
FROM 
	KSD_NewInduStandBy t
WHERE
	t.SEC_ACCT_CD in ('22', '23', '32', '33'); -- (AB�ܱ��ä: 22, PF-AB�ܱ��ä: 23, ABCP: 32, PF-ABCP: 33)

-- (Step2) �� ����� CP/�ܱ��ä ����� �հ� �߰�
INSERT INTO RESULT_KSD_NewINDU_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	t.NEW_INDU_CODE,
	'0',	-- ���Ա� �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.NEW_INDU_CODE)
FROM
	RESULT_KSD_NewINDU_CPSHORT_SEC_AMT t;

-- (Step3) ����� CP(ABCP/PF-ABCP) �� �ܱ��ä(AB�ܱ��ä/PF-AB�ܱ��ä) ������ ����� �߰�
INSERT INTO RESULT_KSD_NewINDU_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	t.CP_GBN,
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM, t.CP_GBN)
FROM
	(SELECT * FROM RESULT_KSD_NewINDU_CPSHORT_SEC_AMT WHERE CP_GBN <> '0') t;

-- (Step4) ����� CP/�ܱ��ä ����� �հ� �߰�
INSERT INTO RESULT_KSD_NewINDU_CPSHORT_SEC_AMT
SELECT DISTINCT
	t.GG_YM,
	'00',	-- ������� '00'�ڵ� �Ҵ�
	'0',	-- ���Ա� �հ�� '0' �ڵ� �Ҵ�
	SUM(t.SEC_AMT) OVER (PARTITION BY t.GG_YM)
FROM
	(SELECT * FROM RESULT_KSD_NewINDU_CPSHORT_SEC_AMT WHERE CP_GBN <> '0' AND NEW_INDU_CODE <> '00') t;





-- ��� ��ȸ (���强 ���Ա� ������Ȳ - ȸ��ä ���⺰ ���� ����: �Ⱓ���)
SELECT * FROM RESULT_KSD_Infra_MANGI_SEC_AMT ORDER BY GG_YM, TO_NUMBER(EFAS, '00'), MANGI_GBN;
-- ��� ��ȸ (���强 ���Ա� ������Ȳ - ȸ��ä ���⺰ ���� ����: �Ż��)
SELECT * FROM RESULT_KSD_NewIndu_MANGI_SEC_AMT ORDER BY GG_YM, TO_NUMBER(NEW_INDU_CODE, '00'), MANGI_GBN;
-- ��� ��ȸ (���强 ���Ա� ������Ȳ - CP/�ܱ��ä ����ȭ ��Ȳ: �Ⱓ���)
SELECT * FROM RESULT_KSD_Infra_CPSHORT_SEC_AMT ORDER BY GG_YM, TO_NUMBER(EFAS, '00'), CP_GBN;
-- ��� ��ȸ (���强 ���Ա� ������Ȳ - CP/�ܱ��ä ����ȭ ��Ȳ: �Ż��)
SELECT * FROM RESULT_KSD_NewINDU_CPSHORT_SEC_AMT ORDER BY GG_YM, TO_NUMBER(NEW_INDU_CODE, '00'), CP_GBN;