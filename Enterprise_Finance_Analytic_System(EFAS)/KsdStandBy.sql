/***********************************
 * ���强 ���Ա� �Ⱓ��� �⺻���̺�(KSD_InfraStandBy)����
 ***********************************/
-- Ȱ�� ���̺� : KSD_DATA(���强���Ա�), TCB_NICE_COMP_OUTL(�������) -> KSD_InfraStandBy ���̺� ����
-- KSD_DATA�� KSIC, ����Ը� ���� ������ ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS KSD_InfraStandBy;
SELECT
	t0.GG_YM,
	t0.CORP_NO,
	t0.CORP_NM,
	t0.BRNO,
	t0.KSIC,
	t0.BIZ_SIZE,
	DECODE(t0.EFAS_4, NULL, DECODE(t0.EFAS_3, NULL, DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2), t0.EFAS_3), t0.EFAS_4) as EFAS,
	t0.SEC_ACCT_CD,
	t0.SEC_TYPE_CD,
	t0.SEC_ISS_DT,
	t0.SEC_MATU_DT,
	ROUND(t0.SEC_AMT / 1000000) as SEC_AMT,	-- �鸸�� ���� ��ȯ
	ROUND(t0.SEC_BAL / 1000000) as SEC_BAL,	-- �鸸�� ���� ��ȯ
	t0.SEC_INTR
	INTO KSD_InfraStandBy
FROM 
	(
	SELECT 
		t1000.*,
		t2000.EFAS_CD as EFAS_2
	FROM
		(
		SELECT 
			t100.*,
			t200.EFAS_CD as EFAS_3
		FROM
			(
			SELECT 
				t10.*,
				t20.EFAS_CD as EFAS_4
			FROM
				(
				SELECT DISTINCT 
					t2.*,
					SUBSTR(t1.NICE_STDD_INDU_CLSF_CD, 4,5) as KSIC,
					t1.COMP_SCL_DIVN_CD as BIZ_SIZE	-- (����:1, �߼ұ��:2, �߰߱��: 3)
				FROM 
					TCB_NICE_COMP_OUTL t1, KSD_DATA t2
				WHERE 
					t1.CORP_NO = t2.CORP_NO
				)t10
				LEFT JOIN EFAStoKSIC66 t20
					ON SUBSTR(t10.KSIC, 1, 4) = t20.KSIC	-- 4�ڸ� ����
			)t100
			LEFT JOIN EFAStoKSIC66 t200
				ON SUBSTR(t100.KSIC, 1, 3) = t200.KSIC	-- 3�ڸ� ����
		)t1000
		LEFT JOIN EFAStoKSIC66 t2000
			ON SUBSTR(t1000.KSIC, 1, 2) = t2000.KSIC	-- 2�ڸ� ����
	) t0;
-- ��� ��ȸ
SELECT * FROM KSD_InfraStandBy;





/***********************************
 * ���强 ���Ա� �Ż�� �⺻���̺�(KSD_NewInduStandBy)����
 ***********************************/
-- Ȱ�� ���̺� : KSD_InfraStandBy, NEWINDUtoKSIC -> KSD_NewInduStandBy ���̺� ����
-- KSD_InfraStandBy�� �Ż���ڵ带 ����
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS KSD_NewInduStandBy;
SELECT
	t0.*
	INTO KSD_NewInduStandBy
FROM
	(
	SELECT 
		t1.*,
		t2.NEW_INDU_CODE,
		t2.NEW_INDU_NM 
	FROM KSD_InfraStandBy t1
		LEFT JOIN NEWINDUtoKSIC t2
		ON t1.KSIC = t2.KSIC
	) t0
WHERE
	t0.NEW_INDU_CODE is not NULL;
-- ��� ��ȸ
SELECT * FROM KSD_NewInduStandBy;