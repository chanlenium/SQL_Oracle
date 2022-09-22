/***************************************************************************
 *                 ���λ���ڴ��� �⺻���̺�(BASIC_IND_BIZ_LOAN) ����                            
 * ������� �⺻���̺� ���� (���� = ����ä�ǰ�(1901) + ����ä��CMA��������(5301) - ���޺��������ޱ�(1391))
 * ������� ���̺�(CORP_BIZ_DATA) ���� Ȱ���Ͽ� "���λ���� ��������, ���λ���� ������Ȳ" �� ��� �ۼ�
 ***************************************************************************/
-- (Step1) CORP_BIZ_DATA ���̺��� ���(���λ����, ����) �����͸� �����ϰ�, ����ڹ�ȣ ������ ����
-- Ȱ�� ���̺�: CORP_BIZ_DATA -> IND_BRNO_AMT_RAW ���̺��� ����(���λ���� ����)               
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS IND_BRNO_AMT_RAW;
-- Table ���� (���س��, �������, �ֹι�ȣ, ����ڹ�ȣ, SOI_CD, EI_ITT_CD, ����ڴ��� ����(BRNO_AMT)
SELECT
	t0.GG_YM,
	t0.BRWR_NO_TP_CD,
	t0.CORP_NO,
	t0.BRNO,
	t0.SOI_CD,
	t0.EI_ITT_CD,
	t0.BR_ACT,
	
	-- (����) 1901�� �� ���
	-- t0.AMT1901 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD) as BRNO_AMT
			
	-- (����) 1901 + 5301 - 1391
	t0.AMT1901 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD)
	+ t0.AMT5301 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD)
	- t0.AMT1391 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.EI_ITT_CD, t0.CORP_NO, t0.ACCT_CD) as BRNO_AMT
	INTO IND_BRNO_AMT_RAW
FROM 
	(
	SELECT
		t.GG_YM,
		t.BRWR_NO_TP_CD,
		TRIM(t.CORP_NO) as CORP_NO,
		SUBSTR(t.BRNO, 4) as BRNO,
		t.BR_ACT, 
		t.EI_ITT_CD,
		t.SOI_CD,	
		t.ACCT_CD,
		DECODE(t.ACCT_CD, '1901', NVL(t.S_AMT, 0), 0) as AMT1901, -- ����ä�ǰ�
       	DECODE(t.ACCT_CD, '5301', NVL(t.S_AMT, 0), 0) as AMT5301, -- ����ä��(CMA��������)
       	DECODE(t.ACCT_CD, '1391', NVL(t.S_AMT, 0), 0) as AMT1391 -- ���޺��������ޱ�
	FROM CORP_BIZ_DATA t
		WHERE t.RPT_CD = '31'	-- ���� ��ȣ 
		  	AND t.ACCT_CD IN ('1901', '5301', '1391') 
		  	AND t.SOI_CD IN (
		    	'01', '03', '05', '07', '11', '13', '15', '21', '31', '33', '35', '37', '41', 
		    	'43', '44', '46', '47', '61', '71', '74', '75', '76', '77', '79', '81', 
		    	'83', '85', '87', '89', '91', '94', '95', '97'
		  	)
		  	AND t.BRWR_NO_TP_CD in ('1')	-- ���θ� ����
	) t0;
-- ��� ��ȸ
SELECT * FROM IND_BRNO_AMT_RAW;



-- (Step2) CORP_BIZ_DATA ���̺��� ���� ���� �����͸� �����ϰ�, ����ڹ�ȣ ������ ����
-- Ȱ�� ���̺�: CORP_BIZ_DATA -> HOU_BRNO_AMT_RAW ���̺��� ����(�������)               
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS HOU_BRNO_AMT_RAW;
-- Table ���� (���س��, �ֹι�ȣ, ����ڹ�ȣ, �������(LOAN 1, 2, 5, 7, 9)
SELECT	
	t0.GG_YM,
	t0.CORP_NO,
	t0.BRNO,
	t0.BR_ACT,
	-- ���� �ֹι�ȣ�� �ټ������ ���� ���
	t0.LOAN_1 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_1,
	t0.LOAN_2 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_2,
	t0.LOAN_5 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_5,
	t0.LOAN_7 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_7,
	t0.LOAN_9 / COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.CORP_NO) as LOAN_9
	INTO HOU_BRNO_AMT_RAW
FROM 
	(
	SELECT DISTINCT
		t.GG_YM,
		TRIM(t.CORP_NO) as CORP_NO,
		SUBSTR(t.BRNO, 4) as BRNO,
		t.BR_ACT,
		t.LOAN_1,
		t.LOAN_2,
		t.LOAN_5, 
		t.LOAN_7, 
		t.LOAN_9
	FROM CORP_BIZ_DATA t
		WHERE t.BRWR_NO_TP_CD in ('1')	-- ���θ� ����
	) t0;
-- ��� ��ȸ
SELECT * FROM HOU_BRNO_AMT_RAW;



-- (Step3) IND_BRNO_AMT_RAW�� HOU_BRNO_AMT_RAW �����ϰ�, �� ����� BIZ_RAW ���̺�� �����Ͽ� ��� ���� ���� add
-- Ȱ�� ���̺�: IND_BRNO_AMT_RAW, HOU_BRNO_AMT_RAW, BIZ_RAW -> BASIC_BIZ_LOAN ���̺��� ����               
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BASIC_IND_BIZ_LOAN;
-- Table ���� (���س��, �������, ����(�ֹ�)��ȣ, ����ڹ�ȣ, SOI_CD, EI_ITT_CD, ����ڴ��� ����(BRNO_AMT), ����ڴ��� ��ü��(ODU_AMT), KSIC, EFAS, BIZ_SIZE, �ܰ�����, �ſ���, SOI_CD2)
SELECT
	t10000.*,
	t20000.SOI_CD2
	INTO BASIC_IND_BIZ_LOAN
FROM
	(
	SELECT
		t1000.*,
		t2000.KSIC, 
		t2000.EFAS, 
		t2000.BIZ_SIZE,
		t2000.OSIDE_ISPT_YN,
		t2000.BLIST_MRKT_DIVN_CD,
		t2000.CORP_CRI
	FROM 
		(
		SELECT 
			t100.*,
			t200.LOAN_1, 
			t200.LOAN_2, 
			t200.LOAN_5, 
			t200.LOAN_7, 
			t200.LOAN_9, 
			t200.LOAN_1 + t200.LOAN_2 + t200.LOAN_5 + t200.LOAN_7 + t200.LOAN_9 as HOU_LOAN
		FROM
			(
			SELECT
				t10.GG_YM,
				t10.CORP_NO,
				t10.BRNO,
				t10.BR_ACT,
				t20.SOI_CD,
				t20.EI_ITT_CD,
				t20.BRNO_AMT
			FROM
				(
				SELECT DISTINCT
					t.GG_YM,
					trim(t.CORP_NO) as CORP_NO,
					SUBSTR(t.BRNO, 4) as BRNO,
					NVL(t.BR_ACT, '99') as BR_ACT
				FROM 
					CORP_BIZ_DATA t 
				WHERE 
					t.BRWR_NO_TP_CD = '1'
				) t10
				LEFT JOIN IND_BRNO_AMT_RAW t20
				ON t10.GG_YM = t20.GG_YM
					AND t10.CORP_NO = t20.CORP_NO
					AND t10.BRNO = t20.BRNO
					AND t10.BR_ACT = NVL(t20.BR_ACT, '99')
			ORDER BY t20.BRNO_AMT desc
			) t100
			LEFT JOIN HOU_BRNO_AMT_RAW t200
			ON t100.GG_YM = t200.GG_YM
				AND t100.CORP_NO = t200.CORP_NO
				AND t100.BRNO = t200.BRNO
				AND t100.BR_ACT = NVL(t200.BR_ACT, '99')
		ORDER BY t100.BRNO_AMT desc
		) t1000
		LEFT JOIN BIZ_RAW t2000 
		ON t1000.GG_YM = t2000.GG_YM 
		  	AND t1000.CORP_NO = t2000.CORP_NO
		  	AND t1000.BRNO = t2000.BRNO
	ORDER BY t1000.BRNO_AMT desc
	) t10000
	LEFT JOIN ITTtoSOI2 t20000	-- SOI_CD2�� ����
	 	ON t10000.EI_ITT_CD = t20000.ITT_CD
ORDER BY t10000.BRNO_AMT;
-- ��� ��ȸ
SELECT * FROM BASIC_IND_BIZ_LOAN ORDER BY BRNO_AMT desc;












/***************************************************************************
 *                 ���λ����/������� ��ü�� �⺻���̺�(IND_BRNO_OVD_RAW) ����                            
 * ���λ���� ��ü �⺻���̺� ����
 * ������� ���̺�(CORP_BIZ_DATA) ���� Ȱ���Ͽ� "���λ���ڴ��� ��ü�� ����" ��� �ۼ�
 ***************************************************************************/
-- Ȱ�� ���̺�: CORP_BIZ_DATA -> IND_BRNO_OVD_RAW ���̺��� ����(���λ���� ��ü : CORP_NO, BRNO������ �׷���)               
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS IND_BRNO_OVD_RAW;
-- Table ���� (���س��, �ֹι�ȣ, ����ڹ�ȣ, ������⿬ü����, ������⿬ü����)
SELECT	
	t1.GG_YM,
	t1.CORP_NO,
	t1.BRNO,
	t2.BR_ACT,
	CASE WHEN t1.ODU_AMT > 0 THEN 1 ELSE 0 END as isBIZOVERDUE,
	-- ���ֿ��� ��ü�� ������ �ش� ����ڿ��� ��ü�� �ִ� ������ ����
	CASE WHEN t2.AVG_LOAN_OVD_AMT > 0 THEN 1 ELSE 0 END as isHOUOVERDUE
	INTO IND_BRNO_OVD_RAW
FROM
	(
	SELECT DISTINCT 
		t.GG_YM,
		TRIM(t.CORP_NO) as CORP_NO,
		SUBSTR(t.BRNO, 4) as BRNO,
		t.ODU_AMT	-- �����ü(����� ������ ���еǾ� ����)
	FROM CORP_BIZ_DATA t
		WHERE t.BRWR_NO_TP_CD in ('1')	-- ���θ� ����
		AND t.SOI_CD IN (
		    	'01', '03', '05', '07', '11', '13', '15', '21', '31', '33', '35', '37', '41', 
		    	'43', '44', '46', '47', '61', '71', '74', '75', '76', '77', '79', '81', 
		    	'83', '85', '87', '89', '91', '94', '95', '97'
		  	)
	) t1,
	(
	SELECT DISTINCT
		t.GG_YM,
		TRIM(t.CORP_NO) as CORP_NO,
		SUBSTR(t.BRNO, 4) as BRNO,
		t.BR_ACT,
		COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM, t.CORP_NO) as BIZ_CNT,
		t.LOAN_OVD_AMT,	-- ���迬ü(�ֹι�ȣ ������ ���еǾ� ����)
		t.LOAN_OVD_AMT / COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM, t.CORP_NO) as AVG_LOAN_OVD_AMT
	FROM CORP_BIZ_DATA t
		WHERE t.BRWR_NO_TP_CD in ('1')	-- ���θ� ����
		AND t.SOI_CD IN (
		    	'01', '03', '05', '07', '11', '13', '15', '21', '31', '33', '35', '37', '41', 
		    	'43', '44', '46', '47', '61', '71', '74', '75', '76', '77', '79', '81', 
		    	'83', '85', '87', '89', '91', '94', '95', '97'
		  	)
	) t2
WHERE
	t1.GG_YM = t2.GG_YM 
	AND t1.CORP_NO = t2.CORP_NO
	AND t1.BRNO = t2.BRNO;
-- ��� ��ȸ
SELECT * FROM IND_BRNO_OVD_RAW;




-- �ӽ����̺� ����
-- DROP TABLE IF EXISTS IND_BRNO_AMT_RAW;
-- DROP TABLE IF EXISTS HOU_BRNO_AMT_RAW;	