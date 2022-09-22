/***********************************
 * ��� �����ܾ� ���� - ������� ����(��ü) (���� p.1, [�׸�1])
 * RFP p.11 [�׸�1] ������� ����(��ü)
 * Ȱ�� ���̺� : BASIC_BIZ_LOAN
 ***********************************/
DROP TABLE IF EXISTS RESULT_BIZLOANTREND_TOTAL;
SELECT DISTINCT
	t00.GG_YM,
	t00.IND_BIZ_LOAN,
	t00.CORP_BIZ_LOAN,
	t00.IND_BIZ_LOAN + t00.CORP_BIZ_LOAN as "TOT_BIZ_LOAN"
	INTO RESULT_BIZLOANTREND_TOTAL
FROM
	(
	SELECT
		t0.GG_YM,
		ROUND(SUM(CASE WHEN t0.BRWR_NO_TP_CD = 1 THEN t0.BIZ_LOAN ELSE 0 END) OVER(PARTITION BY t0.GG_YM), 0) as "IND_BIZ_LOAN",
		ROUND(SUM(CASE WHEN t0.BRWR_NO_TP_CD = 3 THEN t0.BIZ_LOAN ELSE 0 END) OVER(PARTITION BY t0.GG_YM), 0) as "CORP_BIZ_LOAN"
	FROM
		(
		SELECT DISTINCT 
			t.GG_YM, 
			t.BRWR_NO_TP_CD, 
			SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRWR_NO_TP_CD) as "BIZ_LOAN"	-- ����� ����
		FROM
			BASIC_BIZ_LOAN t
		WHERE
			t.GG_YM <= TO_CHAR(SYSDATE, 'YYYYMM')
		    AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
		) t0
	) t00
ORDER BY
	t00.GG_YM;
-- �����ȸ
SELECT * FROM RESULT_BIZLOANTREND_TOTAL ORDER BY GG_YM;