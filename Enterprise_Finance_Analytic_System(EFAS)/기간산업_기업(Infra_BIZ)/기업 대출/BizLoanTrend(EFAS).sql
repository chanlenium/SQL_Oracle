/******************************************
 * ��� �����ܾ� ���� - ����� ����Ը�(����������� ��) (p.1, [�׸�3])
 * Ȱ�� ���̺� : BASIC_BIZ_LOAN
 * ����� �Է� : ��ȸ���س��(inputGG_YM)
 * ����(inputGG_YM)�� ���⵿��(inputGG_YM-100)�� ���� ������ ���Ͽ� ���� ������ ���� ��� ������ ����
 ******************************************/
SELECT 
	t1.GG_YM,
	t1.EFAS,
	t1.EFAS_AMT
FROM 
  	(
    SELECT DISTINCT
    	t.GG_YM, 
    	t.BRWR_NO_TP_CD, 
      	t.EFAS, 
      	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRWR_NO_TP_CD, t.EFAS) as EFAS_AMT -- ����, ����� ������
    FROM 
      	BASIC_BIZ_LOAN t 
    ORDER BY 
      	t.EFAS
  	) t1, 
  	(
    -- ���� �� ���⵿�� ���� ���� ��� (�������� ������������ �����ϱ� ����)
    SELECT DISTINCT 
    	t0.EFAS, 
      	SUM(DECODE(t0.GG_YM, ${inputGG_YM}, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) as thisAMT, -- ���� �����ܾ�
      	SUM(DECODE(t0.GG_YM, ${inputGG_YM} - 100, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) as prevAMT, -- ���⵿�� �����ܾ�
      	SUM(DECODE(t0.GG_YM, ${inputGG_YM}, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) - SUM(DECODE(t0.GG_YM, ${inputGG_YM}-100, t0.EFAS_AMT, 0)) OVER(PARTITION BY t0.EFAS) as incAMT -- ���� ����
    FROM 
    	(
        SELECT DISTINCT 
        	t.GG_YM, 
        	t.BRWR_NO_TP_CD,
          	t.EFAS, 
          	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRWR_NO_TP_CD, t.EFAS) as EFAS_AMT -- ����, ����� ������
        FROM 
          	BASIC_BIZ_LOAN t 
        ORDER BY 
          t.EFAS
    	) t0 
    WHERE 
      	CAST(t0.GG_YM AS INTEGER) in (${inputGG_YM}-100, ${inputGG_YM})	-- ����(${inputGG_YM}), ����(${inputGG_YM}-100) ����
  	) t2 
WHERE 
  	t1.EFAS = t2.EFAS 
ORDER BY 
  	t1.GG_YM, t2.incAMT DESC;  

  
  
  
  
/*****************************************************
* ������������� �������� - ����������� ��� ���� ���� ��Ȳ (p.2, [ǥ])
******************************************************/
SELECT 
  	t000.EFAS, 
  	-- �� ���� �ܾ�
  	t000.prevAMT, 
  	t000.thisAMT, 
  	ROUND(t000.thisAMT / t000.prevAMT - 1, 4) as AMTgrowth, -- �����ܾ� ������
  	-- ���ִ� ��� �����ܾ�
  	t000.prevAVG_AMT, 
  	t000.thisAVG_AMT, 
  	ROUND(t000.thisAVG_AMT / t000.prevAVG_AMT - 1, 4) as AVG_AMTgrowth -- ��մ����ܾ� ������
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
              	t.EFAS, 
              	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.BRNO, t.EFAS) as LOAN 
            FROM 
              	BASIC_BIZ_LOAN t 
            WHERE 
              	CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}-100, ${inputGG_YM})	-- ����(${inputGG_YM}), ����(${inputGG_YM}-100) ����
          	) t0 
      	) t00 
  	) t000 
ORDER BY To_number(t000.EFAS, '99');





/****************************************************************
 * ������������� �������� - ����������� ����Ը� ���� ���� ��Ȳ (����Ը�, p.2) *
 ****************************************************************/
SELECT 
	t000.BIZ_SIZE,
  	t000.EFAS, 
  	-- �� ���� �ܾ�
  	t000.prevAMT, 
  	t000.thisAMT, 
  	ROUND(t000.thisAMT / t000.prevAMT - 1, 4) as AMTgrowth, -- �����ܾ� ������
  	-- ���ִ� ��� �����ܾ�
  	t000.prevAVG_AMT, 
  	t000.thisAVG_AMT, 
  	ROUND(t000.thisAVG_AMT / t000.prevAVG_AMT - 1, 4) as AVG_AMTgrowth -- ��մ����ܾ� ������
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
              	t.EFAS, 
              	SUM(t.BRNO_AMT) OVER(PARTITION BY t.BIZ_SIZE, t.GG_YM, t.BRNO, t.EFAS) as LOAN 
            FROM 
              	BASIC_BIZ_LOAN t 
            WHERE 
              	CAST(t.GG_YM AS INTEGER) in (${inputGG_YM}-100, ${inputGG_YM})	-- ����(${inputGG_YM}), ����(${inputGG_YM}-100) ����
              	AND t.BIZ_SIZE in ('1', '2', '3') -- ����Ը�(t.BIZ_SIZE - 1: ����, 2: �߼ұ��, 3: �߰߱��)
          	) t0 
      	) t00 
  	) t000 
ORDER BY t000.BIZ_SIZE, To_number(t000.EFAS, '99');