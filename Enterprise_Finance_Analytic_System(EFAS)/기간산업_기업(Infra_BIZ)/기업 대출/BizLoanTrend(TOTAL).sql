/***********************************
 * ��� �����ܾ� ���� - ������� ����(��ü) (p.1, [�׸�1])
 * Ȱ�� ���̺� : BASIC_BIZ_LOAN
 * ����� �Է� : ��ȸ���س��(inputGG_YM)
 ***********************************/
SELECT DISTINCT
	t0.GG_YM,
	SUM(CASE WHEN t0.BRWR_NO_TP_CD = 1 THEN t0.BIZ_LOAN ELSE 0 END) OVER(PARTITION BY t0.GG_YM) as IND_BIZ_LOAN,
	SUM(CASE WHEN t0.BRWR_NO_TP_CD = 3 THEN t0.BIZ_LOAN ELSE 0 END) OVER(PARTITION BY t0.GG_YM) as CORP_BIZ_LOAN,
	SUM(CASE WHEN t0.BRWR_NO_TP_CD = 1 THEN t0.BIZ_LOAN ELSE 0 END) OVER(PARTITION BY t0.GG_YM)
	+ SUM(CASE WHEN t0.BRWR_NO_TP_CD = 3 THEN t0.BIZ_LOAN ELSE 0 END) OVER(PARTITION BY t0.GG_YM) as TOT_BIZ_LOAN
FROM
	(
	SELECT DISTINCT 
		t.GG_YM, 
		t.BRWR_NO_TP_CD, 
		SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRWR_NO_TP_CD) as BIZ_LOAN	-- ����� ����
	FROM
		BASIC_BIZ_LOAN t
	WHERE
		CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
	) t0;