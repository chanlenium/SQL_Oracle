/*****************************************************
 * �Ż�� ��å���� ��Ȳ - �Ż���� ��ü��
 * �ſ�������� ���� ��� �� ��� ��ü ��� �� ���� ���
 * Ȱ�� ���̺� : BASIC_newBIZ_OVD -> ����, ����� ��ü�� ���
 *****************************************************/


/***********************************
 * �Ż���� ��ü�� (������Ȳ)
 ***********************************/
SELECT DISTINCT 
 	t.GG_YM, 
  	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM) as NUM_OF_OVERDUE_BIZ,	-- ��ü �����
  	COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM) as TOT_NUM_OF_BIZ,  -- ��ü ����� 
  	SUM(t.isOVERDUE) OVER (PARTITION BY t.GG_YM) / COUNT(t.BRNO) OVER (PARTITION BY t.GG_YM) as OVERDUE_RATIO	-- ��ü��  
FROM
	BASIC_newBIZ_OVD t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM};
	




/*****************************************************
 * ��ü��� ��: ������, �б⺰ ��Ȳ
 *****************************************************/
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