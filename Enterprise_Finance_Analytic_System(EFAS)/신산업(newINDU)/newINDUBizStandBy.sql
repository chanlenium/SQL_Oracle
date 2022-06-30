/***************************************************************************
 *                 �Ż�� �� �� �� �� �⺻���̺�(BASIC_newBIZ_LOAN) ����                            
 * �ű��������� �⺻���̺� ���� (���� = ����ä�ǰ�(1901) + ����ä��CMA��������(5301) - ���޺��������ޱ�(1391))
 ***************************************************************************/
-- ���ż���������ؿ��� ���ż��� ��å���� ���� ����� �Ϲݽſ���� ��Ȳ ���̺� ����
-- Ȱ�� ���̺�: BASIC_BIZ_LOAN, IT_D2_INPT_DATA_BY_DEGR(IGS D2 Table)  -> BASIC_newBIZ_LOAN ���̺��� ����               
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BASIC_newBIZ_LOAN;
-- Table ���� (���س��, �������, ����(�ֹ�)��ȣ, ����ڹ�ȣ, SOI_CD, EI_ITT_CD, ����ڴ��� ����(BRNO_AMT), ����ڴ��� ��ü��(ODU_AMT))
SELECT 
	t1.GG_YM,
	t1.CORP_NO,
	t1.BRNO,
	t1.BRNO_AMT,
	t1.BIZ_SIZE,
	t1.OSIDE_ISPT_YN,
	t1.BLIST_MRKT_DIVN_CD,
	t1.SOI_CD,
	t1.EI_ITT_CD,
	t1.SOI_CD2,
	t1.KSIC,
	t1.EFAS,
	t2.newINDU_code as newINDU,
	t2.newINDU_NM
	INTO BASIC_newBIZ_LOAN
FROM BASIC_BIZ_LOAN t1
	JOIN (SELECT DISTINCT
			a1.CORP_RGST_NO, 
			a2.newINDU_NM, 
			a2.newINDU_code 
		FROM IT_D2_INPT_DATA_BY_DEGR a1, IGStoNewINDU a2
		WHERE a1.JSTD_ITMS_CD = a2.IGS_code
		) t2	-- D2��� ����Ʈ ����
	ON t1.CORP_NO = t2.CORP_RGST_NO;
-- ��� ��ȸ
SELECT * FROM BASIC_newBIZ_LOAN;










/*****************************************************
 *          �Ż�� �� ü �� �⺻���̺� ����(BASIC_newBIZ_OVD)
 * ���ż���������ؿ��� ���ż��� ��å���� ���� ����� ��ü����Ȳ ���̺�
 * Ȱ�� ���̺� : BASIC_BIZ_OVD, IT_D2_INPT_DATA_BY_DEGR -> BASIC_newBIZ_OVD 
 *****************************************************/
DROP TABLE IF EXISTS BASIC_newBIZ_OVD;
-- OVERDUE_TB ���̺� ����
SELECT 
	t1.GG_YM,
	t1.CORP_NO,
	t1.BRNO,
	t1.EFAS,
	t1.BIZ_SIZE,
	t1.OSIDE_ISPT_YN,
	t1.BLIST_MRKT_DIVN_CD,
	t1.isOVERDUE,
	t2.newINDU_code as newINDU,
	t2.newINDU_NM
	INTO BASIC_newBIZ_OVD
FROM
	(SELECT DISTINCT
		t.GG_YM,
		t.BRWR_NO_TP_CD,
		t.CORP_NO,
		t.BRNO,
		t.EFAS,
		t.BIZ_SIZE,
		t.OSIDE_ISPT_YN,	-- �ܰ�����
		t.BLIST_MRKT_DIVN_CD,	-- ���忩��
		CASE 
			WHEN SUM(t.ODU_AMT) OVER(PARTITION BY t.GG_YM, t.BRNO) > 0
			THEN 1
			ELSE 0
		END as isOVERDUE
	FROM BASIC_BIZ_OVD t) t1
	JOIN (SELECT DISTINCT
			a1.CORP_RGST_NO, 
			a2.newINDU_NM, 
			a2.newINDU_code 
		FROM IT_D2_INPT_DATA_BY_DEGR a1, IGStoNewINDU a2
		WHERE a1.JSTD_ITMS_CD = a2.IGS_code
		) t2	-- D2��� ����Ʈ ����
	ON t1.CORP_NO = t2.CORP_RGST_NO;
-- ��� ��ȸ
SELECT * FROM BASIC_newBIZ_OVD;��