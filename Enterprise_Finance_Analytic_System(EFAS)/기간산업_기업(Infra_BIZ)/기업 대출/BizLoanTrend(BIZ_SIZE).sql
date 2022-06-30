/******************************************
 * ��� �����ܾ� ���� - ����Ը� ����(��/�߰�/�߼�) (p.1, [�׸�2])
 * Ȱ�� ���̺� : BASIC_BIZ_LOAN
 * ����� �Է� : ��ȸ���س��(inputGG_YM)
 ******************************************/
SELECT DISTINCT 
	t.GG_YM, 
	CASE
		WHEN t.BRWR_NO_TP_CD = 1 THEN t.BRWR_NO_TP_CD || ' ���λ����'
		ELSE t.BRWR_NO_TP_CD || ' ���λ����'
	END as BRWR_NO_TP_CD,
	CASE 
  		WHEN t.BIZ_SIZE = 1 THEN t.BIZ_SIZE || ' ����'
  		WHEN t.BIZ_SIZE = 2 THEN t.BIZ_SIZE || ' �߼ұ��'
  		WHEN t.BIZ_SIZE = 3 THEN t.BIZ_SIZE || ' �߰߱��'
  		ELSE t.BIZ_SIZE
  	END as BIZ_SIZE,
  	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRWR_NO_TP_CD, t.BIZ_SIZE) as LOAN 
FROM 
  	BASIC_BIZ_LOAN t 
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
ORDER BY 
  	t.GG_YM;