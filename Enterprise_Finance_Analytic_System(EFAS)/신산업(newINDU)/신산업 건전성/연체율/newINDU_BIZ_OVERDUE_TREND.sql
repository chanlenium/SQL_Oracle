/*****************************************************
 * �Ż�� ��å���� ��Ȳ - �Ż���� ��ü��
 * �ſ�������� ���� ��� �� ��� ��ü ��� �� ���� ���
 * Ȱ�� ���̺� : BASIC_newBIZ_OVD -> ����, ����� ��ü�� ���
 *****************************************************/


/***********************************
 * �Ż���� ��ü�� (������Ȳ)
 * RFP p.17 [�׸�3] �Ż���� ��ü��
 ***********************************/
DROP TABLE IF EXISTS RESULT_newINDU_BIZ_OVERDUE_TREND;
SELECT DISTINCT
	t00.GG_YM,
	t00.TOT_OVERDUE_RATIO,
	SUM(t00.newINDU_OVERDUE_RATIO_1) OVER(PARTITION BY t00.GG_YM) as '1 ����������',
	SUM(t00.newINDU_OVERDUE_RATIO_2) OVER(PARTITION BY t00.GG_YM) as '2 IOT����',
	SUM(t00.newINDU_OVERDUE_RATIO_3) OVER(PARTITION BY t00.GG_YM) as '3 ����Ʈ �ｺ�ɾ�',
	SUM(t00.newINDU_OVERDUE_RATIO_4) OVER(PARTITION BY t00.GG_YM) as '4 ���̿��ž�',
	SUM(t00.newINDU_OVERDUE_RATIO_5) OVER(PARTITION BY t00.GG_YM) as '5 ������ݵ�ü',
	SUM(t00.newINDU_OVERDUE_RATIO_6) OVER(PARTITION BY t00.GG_YM) as '6 ��������÷���',
	SUM(t00.newINDU_OVERDUE_RATIO_7) OVER(PARTITION BY t00.GG_YM) as '7 �����������',
	SUM(t00.newINDU_OVERDUE_RATIO_8) OVER(PARTITION BY t00.GG_YM) as '8 ESS',
	SUM(t00.newINDU_OVERDUE_RATIO_9) OVER(PARTITION BY t00.GG_YM) as '9 ����Ʈ�׸���',
	SUM(t00.newINDU_OVERDUE_RATIO_10) OVER(PARTITION BY t00.GG_YM) as '10 ������'
	INTO RESULT_newINDU_BIZ_OVERDUE_TREND
FROM
	(
	SELECT 
		t0.GG_YM, 
		t0.newINDU,
		t0.newINDU_NM,
		t0.TOT_OVERDUE_RATIO,
		DECODE(t0.newINDU_NM, '����������', t0.newINDU_OVERDUE_RATIO, 0) as newINDU_OVERDUE_RATIO_1,
		DECODE(t0.newINDU_NM, 'IOT ����', t0.newINDU_OVERDUE_RATIO, 0) as newINDU_OVERDUE_RATIO_2,
		DECODE(t0.newINDU_NM, '����Ʈ �ｺ�ɾ�', t0.newINDU_OVERDUE_RATIO, 0) as newINDU_OVERDUE_RATIO_3,
		DECODE(t0.newINDU_NM, '���̿��ž�', t0.newINDU_OVERDUE_RATIO, 0) as newINDU_OVERDUE_RATIO_4,
		DECODE(t0.newINDU_NM, '������ݵ�ü', t0.newINDU_OVERDUE_RATIO, 0) as newINDU_OVERDUE_RATIO_5,
		DECODE(t0.newINDU_NM, '��������÷���', t0.newINDU_OVERDUE_RATIO, 0) as newINDU_OVERDUE_RATIO_6,
		DECODE(t0.newINDU_NM, '�����������', t0.newINDU_OVERDUE_RATIO, 0) as newINDU_OVERDUE_RATIO_7,
		DECODE(t0.newINDU_NM, 'ESS', t0.newINDU_OVERDUE_RATIO, 0) as newINDU_OVERDUE_RATIO_8,
		DECODE(t0.newINDU_NM, '����Ʈ�׸���', t0.newINDU_OVERDUE_RATIO, 0) as newINDU_OVERDUE_RATIO_9,
		DECODE(t0.newINDU_NM, '������', t0.newINDU_OVERDUE_RATIO, 0) as newINDU_OVERDUE_RATIO_10
	FROM 	
		(		
		SELECT DISTINCT 
		 	t.GG_YM, 
		 	t.newINDU,
		 	t.newINDU_NM,
		 	-- ����� ���
		 	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM) as TOT_NUM_OF_OVERDUE_BIZ,	-- �Ż�� ����� ��ü �����
		  	COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM) as TOT_NUM_OF_BIZ,  -- �Ż�� ����� ��ü ����� 
		  	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM) as TOT_OVERDUE_RATIO,	-- �Ż�� ����� ��ü��  
		 	-- �Ż�� ��ü ���
		  	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM, t.newINDU) as newINDU_NUM_OF_OVERDUE_BIZ,	-- �Ż���� ��ü �����
		  	COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM, t.newINDU) as newINDU_TOT_NUM_OF_BIZ,  -- �Ż���� ��ü ����� 
		  	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM, t.newINDU) / COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM, t.newINDU) as newINDU_OVERDUE_RATIO	-- �Ż���� ��ü��  
		FROM
			BASIC_newBIZ_OVD t
		WHERE
			CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
			AND NVL(t.EFAS, '') <> '55'		-- ��������� ����
		) t0
	) t00
ORDER BY 
	t00.GG_YM;






/*****************************************************
 * ��ü��� ��: ������, �б⺰ ��Ȳ
 * RFP p.18 [ǥ] ��ü��� ��
 *****************************************************/
DROP TABLE IF EXISTS RESULT_newINDU_BIZ_OVERDUE_TREND_TABLE;
SELECT DISTINCT
	t0.newINDU,
	t0.newINDU_NM,
	t0.BIZ_SIZE,
	-- ��ȸ ���س�(��ü ��� ��, ��ü ��� ��)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR(TO_DATE('${inputYYYYMM}', 'YYYYMM')::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q0,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR(TO_DATE('${inputYYYYMM}', 'YYYYMM')::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q0,
	-- 1�б� ����(��ü ��� ��, ��ü ��� ��)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 90)::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q1,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 90)::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q1,
	-- 2�б� ����(��ü ��� ��, ��ü ��� ��)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 180)::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q2,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 180)::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q2,
	-- 3�б� ����(��ü ��� ��, ��ü ��� ��)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 270)::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q3,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 270)::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q3,
	-- 4�б� ����(��ü ��� ��, ��ü ��� ��)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 365)::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q4,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 365)::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q4,
	-- 5�б� ����(��ü ��� ��, ��ü ��� ��)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 90))::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q5,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 90))::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q5,
	-- 6�б� ����(��ü ��� ��, ��ü ��� ��)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 180))::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q6,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 180))::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q6,
	-- 7�б� ����(��ü ��� ��, ��ü ��� ��)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 270))::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q7,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 270))::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q7,
	-- 8�б� ����(��ü ��� ��, ��ü ��� ��)
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 365))::date, 'YYYYMM') THEN t0.newINDU_OVERDUE_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as OVERDUE_BIZ_CNT_Q8,
	SUM(CASE WHEN t0.GG_YM = TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 365))::date, 'YYYYMM') THEN t0.newINDU_TOT_BIZ_CNT ELSE 0 END) OVER(PARTITION BY t0.newINDU, t0.BIZ_SIZE) as TOT_BIZ_CNT_Q8
	INTO RESULT_newINDU_BIZ_OVERDUE_TREND_TABLE
FROM
	(
		(SELECT DISTINCT
			t.GG_YM,
		  	t.newINDU,
		  	t.newINDU_NM,
		  	CASE 
		  		WHEN t.BIZ_SIZE = 1 THEN t.BIZ_SIZE || ' ����'
		  		WHEN t.BIZ_SIZE = 2 THEN t.BIZ_SIZE || ' �߼ұ��'
		  		WHEN t.BIZ_SIZE = 3 THEN t.BIZ_SIZE || ' �߰߱��'
		  		ELSE t.BIZ_SIZE
		  	END as BIZ_SIZE,
		  	SUM(t.isOVERDUE) OVER(PARTITION BY t.GG_YM, t.newINDU, t.BIZ_SIZE) as newINDU_OVERDUE_BIZ_CNT, 	-- ��ü �����
		  	COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM, t.newINDU, t.BIZ_SIZE) as newINDU_TOT_BIZ_CNT 	-- �� �����
		FROM 
			BASIC_newBIZ_OVD t 
		WHERE
			t.GG_YM in (
				TO_CHAR(TO_DATE('${inputYYYYMM}', 'YYYYMM')::date, 'YYYYMM'),	-- ��ȸ ���س�
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 90)::date, 'YYYYMM'),	-- 1�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 180)::date, 'YYYYMM'),	-- 2�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 270)::date, 'YYYYMM'),	-- 3�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 365)::date, 'YYYYMM'),	-- 4�б� ����(���� ����)
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 90))::date, 'YYYYMM'),	-- 5�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 180))::date, 'YYYYMM'),	-- 6�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 270))::date, 'YYYYMM'),	-- 7�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 365))::date, 'YYYYMM')	-- 8�б� ����(������ ����)
				)
			AND t.BIZ_SIZE in ('1', '2', '3')	-- ������� ���� �� ����
		ORDER BY t.GG_YM, t.newINDU)
		UNION
		(SELECT DISTINCT
			t.GG_YM,
		  	t.newINDU,
		  	t.newINDU_NM,
		  	'��ü' as BIZ_SIZE,
		  	SUM(t.isOVERDUE) OVER(PARTITION BY t.GG_YM, t.newINDU) as newINDU_OVERDUE_BIZ_CNT, 	-- ��ü �����
		  	COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM, t.newINDU) as newINDU_TOT_BIZ_CNT 	-- �� �����
		FROM 
			BASIC_newBIZ_OVD t 
		WHERE
			t.GG_YM in (
				TO_CHAR(TO_DATE('${inputYYYYMM}', 'YYYYMM')::date, 'YYYYMM'),	-- ��ȸ ���س�
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 90)::date, 'YYYYMM'),	-- 1�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 180)::date, 'YYYYMM'),	-- 2�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 270)::date, 'YYYYMM'),	-- 3�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - 365)::date, 'YYYYMM'),	-- 4�б� ����(���� ����)
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 90))::date, 'YYYYMM'),	-- 5�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 180))::date, 'YYYYMM'),	-- 6�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 270))::date, 'YYYYMM'),	-- 7�б� ����
				TO_CHAR((TO_DATE('${inputYYYYMM}', 'YYYYMM') - (365 + 365))::date, 'YYYYMM')	-- 8�б� ����(������ ����)
				)			
			AND t.BIZ_SIZE in ('1', '2', '3')	-- ������� ���� �� ����
		ORDER BY t.GG_YM, t.newINDU)
	) t0
ORDER BY t0.newINDU;


-- ��� ��ȸ
SELECT * FROM RESULT_newINDU_BIZ_OVERDUE_TREND;
SELECT * FROM RESULT_newINDU_BIZ_OVERDUE_TREND_TABLE ORDER BY TO_NUMBER(newINDU, '99'), BIZ_SIZE;