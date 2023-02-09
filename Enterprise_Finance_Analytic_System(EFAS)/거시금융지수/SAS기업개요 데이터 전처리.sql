/**************************************
 * (Step1) ������� �⺻���̺�(TCB_NICE_COMP_OUTL -> SAS_COMP_OUTL) ����      
 **************************************/
DROP TABLE IF EXISTS SAS_COMP_OUTL;
SELECT DISTINCT
	SUBSTR(t00.STD_YM, 1, 4) as 'STD_YY',
	t00.COMP_CD,
	t00.CORP_NO,
	t00.BIZ_SIZE,
	t00.KSIC
	into SAS_COMP_OUTL
FROM(
	SELECT 
		t0.*,
		-- ���� ����� ���������Ͱ� �ִ� ��� �̸� ������ ���߳��(STD_YM)���� ����
		ROW_NUMBER() OVER(PARTITION BY t0.COMP_CD, SUBSTR(t0.STD_YM, 1, 4) ORDER BY t0.STD_YM DESC) as LAST_STD_YM
	FROM(
		SELECT DISTINCT
			t.STD_YM,	-- ���س��
			t.COMP_CD,	-- NICE ��ü ���� ID
			t.CORP_NO,	-- ���ι�ȣ
			t.COMP_SCL_DIVN_CD as BIZ_SIZE,  -- ����Ը�
			SUBSTR(t.NICE_STDD_INDU_CLSF_CD, 4, 5) as KSIC 
		FROM 
		  	TCB_NICE_COMP_OUTL t
		WHERE 
			t.CORP_NO is not NULL
			AND t.OSIDE_ISPT_YN = 'Y'	-- �ܰ���
		ORDER BY 
			t.COMP_CD, t.STD_YM
		) t0
	) t00
WHERE 
	-- ���ϳ�������� �ֱ� �����͸� ����
	t00.LAST_STD_YM = '1'
ORDER BY
	t00.COMP_CD, SUBSTR(t00.STD_YM, 1, 4);
-- ��� ��ȸ
SELECT * FROM SAS_BIZ_RAW;



/**************************************
 * (Step2) �繫 ������ ����(TCB_NICE_FNST -> SAS_NICE_FNST) ����  
 **************************************/
DROP TABLE IF EXISTS SAS_NICE_FNST;
SELECT DISTINCT
	t000.STD_DT,
	t000.COMP_CD, 
  	t000.SEAC_DIVN,	
  	t000.SALES,
  	t000.PROFIT,
    t000.INTEREST,
    t000.INTCOVRATIO
    into SAS_NICE_FNST
FROM
	(	
    SELECT 
  		t00.STD_YM, 
      	t00.COMP_CD, 
      	t00.SEAC_DIVN,
     	t00.STD_DT,
     	t00.SALES,
     	t00.PROFIT,
     	t00.INTEREST,
     	t00.INTCOVRATIO,
     	-- ���� �繫������ ��������(STD_DT)�� ��ϵ� �繫 �����Ͱ� ������ ���س��(STD_YM)�� �ֱ��� ������ ��� 
      	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
    FROM 
      	(
      	SELECT DISTINCT
      		t0.STD_YM,
      		t0.COMP_CD, 
      		t0.SEAC_DIVN,
     		t0.STD_DT,
     		SUM(t0.SALES) OVER (PARTITION BY t0.STD_YM, t0.COMP_CD, t0.SEAC_DIVN, t0.STD_DT) as SALES,
     		SUM(t0.PROFIT) OVER (PARTITION BY t0.STD_YM, t0.COMP_CD, t0.SEAC_DIVN, t0.STD_DT) as PROFIT,
     		SUM(t0.INTEREST) OVER (PARTITION BY t0.STD_YM, t0.COMP_CD, t0.SEAC_DIVN, t0.STD_DT) as INTEREST,
     		SUM(t0.PROFIT) OVER (PARTITION BY t0.STD_YM, t0.COMP_CD, t0.SEAC_DIVN, t0.STD_DT) 
     		/ NULLIF(SUM(t0.INTEREST) OVER (PARTITION BY t0.STD_YM, t0.COMP_CD, t0.SEAC_DIVN, t0.STD_DT), 0) as INTCOVRATIO
      	FROM 	
      		(
      		SELECT
            	t.STD_YM, 
                t.COMP_CD, 
                t.SEAC_DIVN,	-- ��걸�� (K: ���, B: �ݱ�, F: 1/4�б�, T: 3/4�б�)
                t.STD_DT, 	-- �繫������ ������
                t.ITEM_CD,
                DECODE(t.ITEM_CD, '1000', t.AMT, 0) as SALES,
                DECODE(t.ITEM_CD, '5000', t.AMT, 0) as PROFIT,
                DECODE(t.ITEM_CD, '6110', t.AMT, 0) as INTEREST,
                t.AMT
            FROM 
              	TCB_NICE_FNST t
            WHERE 
            	t.SEAC_DIVN = 'K'
            	AND t.REPORT_CD = '12' 
            	AND t.ITEM_CD in ('1000', '5000', '6110')	-- �����(12/1000), ��������(12/5000), ���ں��(12/6110)
        		AND TO_NUMBER(SUBSTR(t.STD_DT, 1, 4)) > 2010	-- 2010�� ���� �����͸� ����
      		) t0
      	) t00
  	) t000 
WHERE 
	-- �ֱ� �����͸� ����
	t000.LAST_STD_YM = '1'
ORDER BY
	t000.COMP_CD, t000.STD_DT;

-- ��� ��ȸ	
SELEcT * FROM SAS_NICE_FNST;
-- ���� ���� COMP, ���� �⵵�� ���� ������ STD_DT�� ������ ���� �ֱ� STD_DT�� ����� �������� �����ϴ� �۾� �߰� ����
-- ���� STD_DT�� SUBSTR(STD_DT, 1, 4)�Ͽ� STD_YY�� ����� ����



/**************************************
 * (Step3) SAS_NICE_FNST�� SAS_COMP_OUTL ����
 **************************************/
-- COMP_CD�� STD_YY�� ����Ű�� ������ �ϴµ�..
-- ������ ����� �����ʹ� SAS_NICE_FNST�� �����Ƿ�, SAS_NICE_FNST�� �������� SAS_COMP_OUTL left join
-- �׷��� Left join�Ŀ� NULL���� ������� ���� ������
-- �� ���, ���� ����� ���� ������䰡 NULL�� STD_YY ������ �������� ������䰡 NULL�� �ƴ� ���� ����� ���� ������ ������並 ����� ��
-- ��� �۾����� ��Ī�Ǵ� ������� ������ ���� ���, ���� ����� ���� ������䰡 NULL�� STD_YY ������ �������� ������䰡 NULL�� �ƴ� ���� ����� �̷� ������ ������並 ����� ��
-- �� ��� ��� ��Ī�Ǵ� ������䰡 ������ �ش� ���ڵ�� ����
   












          	
          	
