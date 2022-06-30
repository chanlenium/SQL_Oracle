/***********************************
 * ���λ���ڴ��� ���� - ���λ���ڴ��� �ܾ� ���� (p.8, [�׸�1])
 * Ȱ�����̺� : BASIC_IND_BIZ_LOAN
 ***********************************/
SELECT DISTINCT 
	t.GG_YM, 
	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM) as '0. �������',
	ROUND(SUM(t.LOAN_1) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '1. �������(�ſ�)',
	ROUND(SUM(t.LOAN_2) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '2. �������(�㺸)',
	ROUND(SUM(t.LOAN_5) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '5. �������(�Һα���)',
	ROUND(SUM(t.LOAN_7) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '7. �������(����)',
	ROUND(SUM(t.LOAN_9) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '9. �������(��Ÿ)',
	ROUND(SUM(t.HOU_LOAN) OVER(PARTITION BY t.GG_YM) / 1000, 0) as '99. �������(Total)'
FROM
	BASIC_IND_BIZ_LOAN t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM};