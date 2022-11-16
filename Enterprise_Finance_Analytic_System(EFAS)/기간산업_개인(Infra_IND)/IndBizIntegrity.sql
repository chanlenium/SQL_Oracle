/***********************************
 * ���λ���ڴ��� ��ü�� ���� - ���λ���ڴ��� �ܾ� ���� (p.8, [�׸�2])
 * RFP p.19 [�׸�2] ���λ���� ��ü�� ����
 * Ȱ�� ���̺�: IND_BRNO_OVD_RAW           
 ***********************************/
-- IND_BRNO_OVD_RAW ���̺��� �������, ������⿡ ���� ��ü�� ���� ����
DROP TABLE IF EXISTS RESULT_IndBizIntegrity;
SELECT DISTINCT	
	t0.GG_YM,
	-- �������
	ROUND(SUM(t0.isBIZOVERDUE) OVER(PARTITION BY t0.GG_YM) / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM), 4) as BIZ_OVD_RATIO,	-- ������� ��ü��
	-- �������
	ROUND(SUM(t0.isHOUOVERDUE) OVER(PARTITION BY t0.GG_YM) / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM), 4) as HOU_OVD_RATIO,	-- ������� ��ü��
	-- ��ü����
	ROUND(SUM(t0.isTOTOVERDUE) OVER(PARTITION BY t0.GG_YM) / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM), 4) as TOT_OVD_RATIO	-- ��ü���� ��ü��
	INTO RESULT_IndBizIntegrity
FROM
	(
	SELECT DISTINCT
		t.GG_YM,
		t.BRNO,
		CASE WHEN sum(t.BRNO_ODU_AMT) over (partition by t.GG_YM, t.BRNO) > 0 THEN 1 ELSE 0 END as isBIZOVERDUE,	-- ����ڴ��⿬ü ����
		CASE WHEN sum(t.LOAN_OVD_AMT) over (partition by t.GG_YM, t.BRNO) > 0 THEN 1 ELSE 0 END as isHOUOVERDUE,	-- ������⿬ü ����
		CASE WHEN ((sum(t.BRNO_ODU_AMT) over (partition by t.GG_YM, t.BRNO) > 0) OR 
			(sum(t.LOAN_OVD_AMT) over (partition by t.GG_YM, t.BRNO) > 0)) THEN 1 ELSE 0 END as isTOTOVERDUE	-- ��ü��ü ����
	FROM
		BASIC_IND_BIZ_LOAN t
	WHERE 
		NVL(t.BR_ACT, '') <> '3'	-- ��� ����
		AND NVL(t.BRNO_AMT, 0) > 0	-- ����ڴ����� �ִ� ���� ����
		AND NVL(t.EFAS, '') <> '55'
	ORDER BY t.BRNO, t.GG_YM
	) t0;
	
---- ��� ��ȸ
SELECT * FROM RESULT_IndBizIntegrity ORDER BY GG_YM;



select * from BASIC_IND_BIZ_LOAN;