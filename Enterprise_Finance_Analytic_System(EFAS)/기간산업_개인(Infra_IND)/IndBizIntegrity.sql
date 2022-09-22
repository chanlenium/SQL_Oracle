/***********************************
 * ���λ���ڴ��� ��ü�� ���� - ���λ���ڴ��� �ܾ� ���� (p.8, [�׸�2])
 * RFP p.19 [�׸�2] ���λ���� ��ü�� ����
 * Ȱ�� ���̺�: IND_BRNO_OVD_RAW           
 ***********************************/
-- IND_BRNO_OVD_RAW ���̺��� �������, ������⿡ ���� ��ü�� ���� ����
DROP TABLE IF EXISTS RESULT_IndBizIntegrity;
SELECT DISTINCT 
	t.GG_YM, 
	ROUND(SUM(t.isBIZOVERDUE) OVER(PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM), 4) as BIZ_OVD_RATIO,	-- ������� ��ü��
	ROUND(SUM(t.isHOUOVERDUE) OVER(PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM), 4) as HOU_OVD_RATIO,	-- ������� ��ü��
	ROUND(SUM(CASE WHEN (t.isBIZOVERDUE = 0 AND t.isHOUOVERDUE = 0) THEN 0 ELSE 1 END) OVER(PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM), 4) as OVD_RATIO -- ��� or ������� ��ü��
	INTO RESULT_IndBizIntegrity
FROM
	IND_BRNO_OVD_RAW t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM};
	

-- ��� ��ȸ
SELECT * FROM RESULT_IndBizIntegrity ORDER BY GG_YM;