/******************************************
 * ��� �����ܾ� ���� - ����� ����Ը�(����������� ��) (���� p.1, [�׸�3])
 * RFP p.11 [�׸�3] ������ ����Ը�(����������� ��)
 * Ȱ�� ���̺� : BASIC_BIZ_LOAN
 * ����� �Է� : ��ȸ���س��(inputGG_YM)
 * ����(inputGG_YM)�� ���⵿��(inputGG_YM-100)�� ���� �������� ���Ͽ� ���� �������� ���� ��� ������ ����
 ******************************************/
DROP TABLE IF EXISTS RESULT_BIZLoanTrend_EFAS;
SELECT 
	t1.GG_YM,
	t1.EFAS,
	t1.EFAS_AMT,
	t2.incAMTRatio
	INTO RESULT_BIZLoanTrend_EFAS
FROM 
  	(
    SELECT DISTINCT
    	t.GG_YM,
      	t.EFAS, 
      	ROUND(SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.EFAS), 0) as EFAS_AMT -- ����, ����� ������
    FROM 
      	BASIC_BIZ_LOAN t 
    WHERE
    	NVL(t.EFAS, '') <> '55'	-- ��������� ����
    ORDER BY 
      	t.EFAS
  	) t1, 
  	(
    SELECT DISTINCT -- ���� �� ���⵿�� ���� ���� ��� (�������� ������������ �����ϱ� ����)
    	t0.EFAS, 
      	SUM(DECODE(t0.GG_YM, ${inputGG_YM}, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) as thisAMT, -- ���� �����ܾ�
      	SUM(DECODE(t0.GG_YM, ${inputGG_YM} - 100, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) as prevAMT, -- ���⵿�� �����ܾ�
      	ROUND(SUM(DECODE(t0.GG_YM, ${inputGG_YM}, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) / SUM(DECODE(t0.GG_YM, ${inputGG_YM} - 100, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) - 1, 4) as incAMTRatio -- ���� ������
    FROM 
    	(
        SELECT DISTINCT 
        	t.GG_YM, 
        	t.BRWR_NO_TP_CD,
          	t.EFAS, 
          	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRWR_NO_TP_CD, t.EFAS) as EFAS_AMT -- ����, ����� ������
        FROM 
          	BASIC_BIZ_LOAN t 
        WHERE
    		NVL(t.EFAS, '') <> '55'	-- ��������� ����
        ORDER BY 
          t.EFAS
    	) t0 
    WHERE 
      	CAST(t0.GG_YM AS INTEGER) in (${inputGG_YM}-100, ${inputGG_YM})	-- ����(${inputGG_YM}), ����(${inputGG_YM}-100) ����
  	) t2 
WHERE 
  	t1.EFAS = t2.EFAS
ORDER BY 
  	t2.incAMTRatio DESC, t1.GG_YM;  -- �����ܾ� ������ ���� ������ ����(���� 5�� ������ �׷��� plot)

  
  
/*****************************************************
* ������������� �������� - ����������� ��� ���� ���� ��Ȳ (���� p.2, [ǥ])
* RFP p.12 [ǥ] ��� ���� ���� ��Ȳ(��ü)
******************************************************/
DROP TABLE IF EXISTS RESULT_BIZLoanTrend_EFAS_TABLE_TOTAL;
SELECT 
  	t000.EFAS, 
  	-- �� ���� �ܾ�
  	ROUND(t000.prevAMT, 0) as prevAMT,
  	ROUND(t000.thisAMT, 0) as thisAMT, 
  	ROUND(t000.thisAMT / NULLIF(t000.prevAMT, 0) - 1, 4) as AMTgrowth, -- �� �����ܾ� ������
  	-- ���ִ� ��� �����ܾ�
  	ROUND(t000.prevAVG_AMT, 0) as prevAVG_AMT,
  	ROUND(t000.thisAVG_AMT, 0) as thisAVG_AMT,
  	ROUND(t000.thisAVG_AMT / NULLIF(t000.prevAVG_AMT, 0) - 1, 4) as AVG_AMTgrowth -- ���ִ� ��� �����ܾ� ������
  	INTO RESULT_BIZLoanTrend_EFAS_TABLE_TOTAL
FROM 
  	(
    SELECT DISTINCT
    	t00.EFAS, 
    	SUM(DECODE(t00.GG_YM, ${inputGG_YM}, t00.EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS) as thisAMT, -- ���� �����ܾ�
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM} - 100, t00.EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS) as prevAMT, -- ���⵿�� �����ܾ�
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM}, t00.AVG_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS) as thisAVG_AMT, -- ���� �����ܾ�
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM} - 100, t00.AVG_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS) as prevAVG_AMT -- ���⵿�� �����ܾ�
    FROM 
      	(
        SELECT DISTINCT 
        	t0.GG_YM, 
          	t0.EFAS, 
          	SUM(t0.LOAN) OVER(PARTITION BY t0.EFAS, t0.GG_YM) as EFAS_AMT, -- ����� ������
          	COUNT(t0.BRNO) OVER(PARTITION BY t0.EFAS, t0.GG_YM) as EFAS_BRWR_CNT, -- ����� ���� ��
          	ROUND(SUM(t0.LOAN) OVER(PARTITION BY t0.EFAS, t0.GG_YM) / COUNT(t0.BRNO) OVER(PARTITION BY t0.EFAS, t0.GG_YM), 2) as AVG_EFAS_AMT -- ����� ���ִ� ��� �����ܾ�
        FROM 
          	(
            SELECT DISTINCT
            	t.GG_YM, 
              	t.BRNO,
              	DECODE(t.EFAS, NULL, '99', DECODE(t.EFAS, '', '99', t.EFAS)) as EFAS,
              	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRNO, t.EFAS) as LOAN 
            FROM 
              	BASIC_BIZ_LOAN t 
            WHERE 
              	CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}-100, ${inputGG_YM})	-- ����(${inputGG_YM}), ����(${inputGG_YM}-100) ����
              	AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
          	) t0 
      	) t00 
  	) t000 
ORDER BY 
	To_number(t000.EFAS, '99');



/****************************************************************
 * ������������� �������� - ����������� ����Ը� ���� ���� ��Ȳ (����Ը�, p.2)
 * RFP p.12 [ǥ] ��� ���� ���� ��Ȳ(����/�߰߱��/�߼ұ��)
 ****************************************************************/
DROP TABLE IF EXISTS RESULT_BIZLoanTrend_EFAS_TABLE_BIZSIZE;
SELECT 
	t000.BIZ_SIZE,
  	t000.EFAS, 
  	-- �� ���� �ܾ�
  	ROUND(t000.prevAMT, 0) as prevAMT,
  	ROUND(t000.thisAMT, 0) as thieAMT,
  	ROUND(t000.thisAMT / NULLIF(t000.prevAMT, 0) - 1, 4) as AMTgrowth, -- �� �����ܾ� ������
  	-- ���ִ� ��� �����ܾ�
  	ROUND(t000.prevAVG_AMT, 0) as prevAVG_AMT, 
  	ROUND(t000.thisAVG_AMT, 0) as thisAVG_AMT, 
  	ROUND(t000.thisAVG_AMT / NULLIF(t000.prevAVG_AMT, 0) - 1, 4) as AVG_AMTgrowth -- ���ִ� ��� �����ܾ� ������
  	INTO RESULT_BIZLoanTrend_EFAS_TABLE_BIZSIZE
FROM 
  	(
    SELECT DISTINCT
    	t00.BIZ_SIZE,
    	t00.EFAS, 
    	SUM(DECODE(t00.GG_YM, ${inputGG_YM}, t00.BIZ_SIZE_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS, t00.BIZ_SIZE) as thisAMT, -- ����Ը� ���� �����ܾ�
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM} - 100, t00.BIZ_SIZE_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS, t00.BIZ_SIZE) as prevAMT, -- ����Ը� ���⵿�� �����ܾ�
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM}, t00.AVG_BIZ_SIZE_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS, t00.BIZ_SIZE) as thisAVG_AMT, -- ����Ը� ���� �����ܾ�
      	SUM(DECODE(t00.GG_YM, ${inputGG_YM} - 100, t00.AVG_BIZ_SIZE_EFAS_AMT, 0)) OVER(PARTITION BY t00.EFAS, t00.BIZ_SIZE) as prevAVG_AMT -- ����Ը� ���⵿�� �����ܾ�
    FROM 
      	(
        SELECT DISTINCT 
        	t0.BIZ_SIZE,
        	t0.GG_YM, 
          	t0.EFAS, 
          	SUM(t0.LOAN) OVER(PARTITION BY t0.BIZ_SIZE, t0.EFAS, t0.GG_YM) as BIZ_SIZE_EFAS_AMT, -- �����/����Ը� ���� ������
          	COUNT(t0.BRNO) OVER(PARTITION BY t0.BIZ_SIZE, t0.EFAS, t0.GG_YM) as BIZ_SIZE_EFAS_BRNO_CNT, -- �����/����Ը� ���� ���� ��
          	ROUND(SUM(t0.LOAN) OVER(PARTITION BY t0.BIZ_SIZE, t0.EFAS, t0.GG_YM) / COUNT(t0.BRNO) OVER(PARTITION BY t0.BIZ_SIZE, t0.EFAS, t0.GG_YM), 2) as AVG_BIZ_SIZE_EFAS_AMT -- �����/����Ը� ���� ���ִ� ��� �����ܾ�
        FROM 
          	(
            SELECT DISTINCT
            	t.BIZ_SIZE,
            	t.GG_YM, 
              	t.BRNO, 
              	DECODE(t.EFAS, NULL, '99', DECODE(t.EFAS, '', '99', t.EFAS)) as EFAS, 
              	SUM(t.BRNO_AMT) OVER(PARTITION BY t.BIZ_SIZE, t.GG_YM, t.BRNO, t.EFAS) as LOAN 
            FROM 
            	(
				SELECT
					t0.GG_YM,
					t0.BRWR_NO_TP_CD,
					t0.CORP_NO,
					t0.BRNO,
					t0.SOI_CD,
					t0.EI_ITT_CD,
					t0.BR_ACT,
					t0.BRNO_AMT,
					t0.KSIC,
					t0.EFAS,
					DECODE(t0.BRWR_NO_TP_CD, '1', '2', t0.BIZ_SIZE) as BIZ_SIZE,
					t0.OSIDE_ISPT_YN,
					t0.BLIST_MRKT_DIVN_CD,
					t0.CORP_CRI,
					t0.SOI_CD2
				FROM 
					BASIC_BIZ_LOAN t0
            	) t 
            WHERE 
              	CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}-100, ${inputGG_YM})	-- ����(${inputGG_YM}), ����(${inputGG_YM}-100) ����
              	AND t.BIZ_SIZE in ('1', '2', '3') -- ����Ը�(t.BIZ_SIZE - 1: ����, 2: �߼ұ��, 3: �߰߱��)
              	AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
          	) t0 
      	) t00 
  	) t000 
ORDER BY 
	t000.BIZ_SIZE, To_number(t000.EFAS, '99');




-- ��� ��ȸ
SELECT * FROM RESULT_BIZLoanTrend_EFAS ORDER BY incAMTRatio DESC, GG_YM;
SELECT * FROM RESULT_BIZLoanTrend_EFAS_TABLE_TOTAL ORDER BY To_number(EFAS, '99');
SELECT * FROM RESULT_BIZLoanTrend_EFAS_TABLE_BIZSIZE ORDER BY BIZ_SIZE, To_number(EFAS, '99');