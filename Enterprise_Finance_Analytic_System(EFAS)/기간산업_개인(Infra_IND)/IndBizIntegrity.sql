/***********************************
 * ���λ���ڴ��� ��ü�� ���� - ���λ���ڴ��� �ܾ� ���� (p.8, [�׸�2])
 * Ȱ�� ���̺�: IND_BRNO_OVD_RAW           
 ***********************************/
-- IND_BRNO_OVD_RAW ���̺��� �������, ������⿡ ���� ��ü�� ���� ����
SELECT DISTINCT 
	t.GG_YM, 
	ROUND(SUM(t.isBIZOVERDUE) OVER(PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM), 4) as BIZ_OVD_RATIO,	-- ������� ��ü��
	ROUND(SUM(t.isHOUOVERDUE) OVER(PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM), 4) as HOU_OVD_RATIO,	-- ������� ��ü��
	ROUND(SUM(CASE WHEN (t.isBIZOVERDUE = 0 AND t.isHOUOVERDUE = 0) THEN 0 ELSE 1 END) OVER(PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM), 4) as OVD_RATIO -- ��� or ������� ��ü��
FROM
	IND_BRNO_OVD_RAW t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM};