/***************************************************************************
 *                 �� �� �� �� �⺻���̺�(BASIC_BIZ_LOAN) ����                            
 * ������� �⺻���̺� ���� (���� = ����ä�ǰ�(1901) + ����ä��CMA��������(5301) - ���޺��������ޱ�(1391))
 ***************************************************************************/
-- (Step1) CORP_BIZ_DATA ���̺��� ���(����, ���λ����) �����͸� �����ϰ�, ����ڹ�ȣ ������ ����
-- Ȱ�� ���̺�: CORP_BIZ_DATA -> BRNO_AMT_RAW ���̺��� ����               
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BRNO_AMT_RAW;
-- Table ���� (���س��, �������, ����(�ֹ�)��ȣ, ����ڹ�ȣ, SOI_CD, EI_ITT_CD, ����ڴ��� ����(BRNO_AMT))
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
	INTO BRNO_AMT_RAW
FROM 
	(
	SELECT
		t.GG_YM,
		t.BRWR_NO_TP_CD,
		TRIM(t.CORP_NO) as CORP_NO,
		SUBSTR(t.BRNO, 4) as BRNO,
		t.EI_ITT_CD,
		t.SOI_CD,	
		t.ACCT_CD,
		t.BR_ACT,
		DECODE(t.ACCT_CD, '1901', t.S_AMT, 0) as AMT1901, -- ����ä�ǰ�
       	DECODE(t.ACCT_CD, '5301', t.S_AMT, 0) as AMT5301, -- ����ä��(CMA��������)
       	DECODE(t.ACCT_CD, '1391', t.S_AMT, 0) as AMT1391 -- ���޺��������ޱ�
	FROM CORP_BIZ_DATA t
		WHERE t.RPT_CD = '31'	-- ���� ��ȣ 
		  	AND t.ACCT_CD IN ('1901', '5301', '1391') 
		  	AND t.SOI_CD IN (
		    	'01', '03', '05', '07', '11', '13', '15', '21', '31', '33', '35', '37', '41', 
		    	'43', '44', '46', '47', '61', '71', '74', '75', '76', '77', '79', '81', 
		    	'83', '85', '87', '89', '91', '94', '95', '97'
		  	)
		  	AND t.BRWR_NO_TP_CD in ('1', '3')	-- ���ΰ� ���θ� count
	) t0;
-- ��� ��ȸ
SELECT * FROM BRNO_AMT_RAW;





-- (Step2) BRNO_AMT_RAW�� BIZ_RAW, ITTtoSOI2 ���̺�� �����Ͽ� ��� ���� ���� add
-- Ȱ�� ���̺�: BRNO_AMT_RAW, BIZ_RAW, ITTtoSOI2 -> BASIC_BIZ_LOAN ���̺��� ����               
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BASIC_BIZ_LOAN;
-- Table ���� (���س��, �������, ����(�ֹ�)��ȣ, ����ڹ�ȣ, SOI_CD, EI_ITT_CD, ����ڴ��� ����, KSIC, EFAS, BIZ_SIZE, �ܰ�����, ���屸��, �ſ���, SOI_CD2)
SELECT
	t10.*,
	t20.SOI_CD2
	INTO BASIC_BIZ_LOAN
FROM
	(
	SELECT
		t1.*, 
	  	t2.KSIC, 
	  	t2.EFAS, 
	  	t2.BIZ_SIZE,
	  	t2.OSIDE_ISPT_YN,
	  	t2.BLIST_MRKT_DIVN_CD,
	  	t2.CORP_CRI
	FROM 
	  	BRNO_AMT_RAW t1
	LEFT JOIN 
		BIZ_RAW t2 
		ON (t1.GG_YM = t2.GG_YM 
	  		AND t1.CORP_NO = t2.CORP_NO
	  		AND t1.BRNO = t2.BRNO)
	 ) t10
	 LEFT JOIN ITTtoSOI2 t20	-- SOI_CD2�� ����
	 	ON To_number(t10.EI_ITT_CD, '9999') = To_number(t20.ITT_CD, '9999');
-- �����ȸ
SELECT count(gg_ym) FROM BASIC_BIZ_LOAN;	 








/***************************************************************************
 *                 �� �� �� Ȳ �⺻���̺�(BASIC_BIZ_DAMBO) ����                         
 * ����㺸 �⺻���̺� ���� (1:����, 2:����, 5:��Ÿ)
 ***************************************************************************/
-- (�����غ�) CORP_BIZ_DATA ���̺��� ���(����, ���λ����) �����͸� �����ϰ�, ����ڹ�ȣ ������ ������ �� �������(BIZ_RAW, ITTtoSOI2)�� ����
-- Ȱ�� ���̺�: CORP_BIZ_DATA, BIZ_RAW, ITTtoSOI2 -> BASIC_BIZ_DAMBO ���̺��� ����               
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BASIC_BIZ_DAMBO;
-- Table ���� (���س��, �������, ����(�ֹ�)��ȣ, ����ڹ�ȣ, SOI_CD, EI_ITT_CD, ����ڴ��� ����(BRNO_AMT), ����ڴ��� ��ü��(ODU_AMT), KSIC, EFAS, BIZ_SIZE, �ܰ�����, �ſ���, SOI_CD2)
SELECT
	t10.*,
	t20.SOI_CD2
	INTO BASIC_BIZ_DAMBO
FROM
	(SELECT
			t1.*, 
		  	t2.KSIC, 
		  	t2.EFAS, 
		  	t2.BIZ_SIZE
	FROM	  	
		(SELECT DISTINCT
			t0.GG_YM,
			t0.BRWR_NO_TP_CD,
			t0.BRNO,
			t0.CORP_NO,
			t0.ACCT_CD,
			t0.DAMBO_TYPE,
			t0.EI_ITT_CD,
			t0.SOI_CD,
			t0.DAMBO_AMT / t0.CNT_BRNO as BRNO_DAMBO_AMT	-- ����ڹ�ȣ ���� �㺸����
		FROM
			(SELECT DISTINCT 
				t.GG_YM, 
				t.BRWR_NO_TP_CD,
				trim(t.CORP_NO) as CORP_NO,
				t.EI_ITT_CD,
				t.SOI_CD,
				substr(t.BRNO, 4) as BRNO,
				t.ACCT_CD,
			  	SUBSTR(t.ACCT_CD, 1, 1) AS DAMBO_TYPE, -- �㺸����(1:����, 2:����, 5:��Ÿ, 6:�Ѱ�)
			  	S_AMT,
			  	SUM(t.S_AMT) OVER(PARTITiON BY t.GG_YM, t.CORP_NO, t.EI_ITT_CD, t.BRNO, t.ACCT_CD) AS DAMBO_AMT, -- �㺸���� �� ���س���� �㺸���� sum
			  	COUNT(t.BRNO) OVER(PARTITION BY t.GG_YM, t.CORP_NO, t.EI_ITT_CD, t.ACCT_CD) AS CNT_BRNO	-- ���� CORP_NO�� ����� ����ڹ�ȣ(BRNO)��
			FROM 
			 	 CORP_BIZ_DATA t 
			WHERE 
			  	t.RPT_CD = '33' -- �㺸��� ������ȣ: 33
			  	AND t.BRWR_NO_TP_CD in ('1', '3')	-- ���� & ���λ����
			ORDER BY 
			  t.GG_YM) t0) t1
		 	LEFT JOIN 
				BIZ_RAW t2 
			ON (t1.GG_YM = t2.GG_YM 
		  		AND t1.CORP_NO = t2.CORP_NO
		  		AND t1.BRNO = t2.BRNO)
		 ) t10
		 LEFT JOIN ITTtoSOI2 t20	-- SOI_CD2�� ����
		 	ON t10.EI_ITT_CD = t20.ITT_CD;
-- ��� ��ȸ
select * from BASIC_BIZ_DAMBO;	










/*****************************************************
 *             �� ü �� �⺻���̺� ����(BASIC_BIZ_OVD)
 * �ſ�������� ���� ��� �� ��� ��ü ��� �� ���� ���
 * Ȱ�� ���̺� : CORP_BIZ_DATA -> BRNO_OVD_RAW -> BASIC_BIZ_OVD 
 *****************************************************/
-- (Step1) CORP_BIZ_DATA ���̺��� ���(����, ���λ����) ��ü �����͸� �����ϰ�, ����ڹ�ȣ ������ ����
-- Ȱ�� ���̺�: CORP_BIZ_DATA -> BRNO_OVD_RAW ���̺��� ����               
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BRNO_OVD_RAW;
-- Table ���� (���س��, �������, ����(�ֹ�)��ȣ, ����ڹ�ȣ, SOI_CD, EI_ITT_CD, ����ڴ��� ��ü��(ODU_AMT))
SELECT DISTINCT 
	t.GG_YM,
	t.BRWR_NO_TP_CD,
	TRIM(t.CORP_NO) as CORP_NO,
	SUBSTR(t.BRNO, 4) as BRNO,
	t.SOI_CD,
	t.EI_ITT_CD,
	t.ODU_AMT
	INTO BRNO_OVD_RAW
FROM CORP_BIZ_DATA t
	WHERE t.BRWR_NO_TP_CD in ('1', '3');	-- ����, ���θ� ����	
-- ��� ��ȸ
SELECT * FROM BRNO_OVD_RAW;


-- (Step2) BRNO_OVD_RAW�� BIZ_RAW ���̺�� �����Ͽ� ��� ���� ���� add
-- Ȱ�� ���̺�: BRNO_OVD_RAW, BIZ_RAW -> BASIC_BIZ_OVD ���̺��� ����               
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS BASIC_BIZ_OVD;
-- Table ���� (���س��, �������, ����(�ֹ�)��ȣ, ����ڹ�ȣ, SOI_CD, EI_ITT_CD, ����ڴ��� ��ü��(ODU_AMT), KSIC, EFAS, BIZ_SIZE, �ܰ�����, ���屸��, �ſ���, SOI_CD2)
SELECT
	t10.*,
	t20.SOI_CD2
	INTO BASIC_BIZ_OVD
FROM
	(
	SELECT
		t1.*, 
	  	t2.KSIC, 
	  	t2.EFAS, 
	  	t2.BIZ_SIZE,
	  	t2.OSIDE_ISPT_YN,
	  	t2.BLIST_MRKT_DIVN_CD,
	  	t2.CORP_CRI
	FROM 
	  	BRNO_OVD_RAW t1
	LEFT JOIN 
		BIZ_RAW t2 
		ON (t1.GG_YM = t2.GG_YM 
	  		AND t1.CORP_NO = t2.CORP_NO
	  		AND t1.BRNO = t2.BRNO)
	 ) t10
	 LEFT JOIN ITTtoSOI2 t20	-- SOI_CD2�� ����
	 	ON t10.EI_ITT_CD = t20.ITT_CD;
-- ��� ��ȸ
SELECT * FROM BASIC_BIZ_OVD;











/*****************************************************
 *             �Ⱓ��� �繫���� ����� ������̺� ����(GIUP_RAW)
 * Ȱ�� ���̺� : TCB_NICE_COMP_OUTL(�������) -> GIUP_RAW 
 * ������ ���翪 �ڵ� �ؿ� (�繫������ NICE ��� pool�� ������� ������)
 * �ֽ� ���� ������� ���̽��� ���, �����з��ڵ�� ���� �ֽſ��� ���°� ���
 *****************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS GIUP_RAW;
-- ���̺� ����(���س��, NICE����ڵ�, ����ڹ�ȣ, ���ι�ȣ, ����Ը�, �ܰ�����, ���屸��, KSIC)
SELECT 
  	a.STD_YM, 
  	a.COMP_CD, 
  	BRNO, 
  	CORP_NO, 
  	COMP_SCL_DIVN_CD, 
  	OSIDE_ISPT_YN, 
  	BLIST_MRKT_DIVN_CD,
  	KSIC 
  	INTO GIUP_RAW 
FROM 
  	(
    SELECT * 
    FROM
      	(
        SELECT 
          	ROW_NUMBER() OVER(PARTITION BY COMP_CD ORDER BY STD_YM DESC) as rn, * 
        FROM 
          	TCB_NICE_COMP_OUTL
      	) as a 
    WHERE 
      	rn = 1
  	) as a 
  	LEFT JOIN -- KSIC�� null�� ���� �����Ͽ� ������̺� ����
  	(
    SELECT 
      	COMP_CD, 
      	KSIC 
    FROM 
      	(
        -- STD_YM�� �������� ���� �ű��
        SELECT 
          	ROW_NUMBER() over (partition by COMP_CD order by STD_YM desc) as rn, * 
        FROM 
          	(
            SELECT DISTINCT 
              	STD_YM, 
              	COMP_CD, 
              	substr(NICE_STDD_INDU_CLSF_CD, 4, 5) as KSIC -- KSIC 5�ڸ��� ����
           	FROM 
              	TCB_NICE_COMP_OUTL 
            WHERE 
              	KSIC is not null -- null�� ���� ����
             ) as a
      	) as a 
    WHERE 
      	rn = 1 -- ���� �ֱ� ��ϵ� �����͸� ���
    ) as b using (COMP_CD);
-- ��� ��ȸ
select * from GIUP_RAW;  



-- �ӽ����̺� ����
--DROP TABLE IF EXISTS BRNO_AMT_RAW;
--DROP TABLE IF EXISTS BRNO_OVD_RAW;