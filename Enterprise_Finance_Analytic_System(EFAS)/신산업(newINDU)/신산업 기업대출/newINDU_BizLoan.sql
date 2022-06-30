/***************************************************************************
 *                 �Ż������ (�����������)                            
 * ������� ���̺�(BASIC_BIZ_LOAN) ���� Ȱ���Ͽ� "�Ż�� ������ �ͼ�����", "�Ż���� �濵����", "�Ż���� ��ü��" �� ��� �ۼ�
 ***************************************************************************/

		
/***********************************
 * �Ż���� ������ �ͽ�����
 * Ȱ�� ���̺� : BASIC_newBIZ_LOAN
 * ����� �Է� : ��ȸ���س��(inputGG_YM)
 ***********************************/
SELECT DISTINCT
	t.GG_YM,
	SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM) as newINDU_AMT
FROM  BASIC_newBIZ_LOAN t
WHERE
	CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM};





/******************************************************
 * �Ż�� ������Ȳ - ������ ���� �ܾ�([ǥ])
 * Ư������ : 01
 * �Ϲ����� : 03, 05, 07
 * ���� : 11, 13, 15
 * ���� : 21, 61, 71, 76
 * ���� : 31, 33, 35, 37
 * ��ȣ���� : 44, 74, 79, 81, 85, 87, 89
 * �������� : 41
 * ��Ÿ : 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
 *******************************************************/
SELECT DISTINCT 
	t00.GG_YM,
	t00.newINDU,
	t00.newINDU_NM,
  	-- �Ϲ����� ������Ȳ
  	SUM(CASE WHEN t00.UPKWON = '�Ϲ�����' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as GBANK, 
  	-- Ư������ ������Ȳ
  	SUM(CASE WHEN t00.UPKWON = 'Ư������' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as SBANK, 
  	-- ���� ������Ȳ
  	SUM(CASE WHEN t00.UPKWON = '����' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as BOHUM, 
  	-- ���� ������Ȳ
  	SUM(CASE WHEN t00.UPKWON = '����' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as KEUMTOO, 
  	-- ���� ������Ȳ
  	SUM(CASE WHEN t00.UPKWON = '����' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as YEOJUN, 
  	-- ��ȣ���� ������Ȳ
  	SUM(CASE WHEN t00.UPKWON = '��ȣ����' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as SANGHO, 
  	-- �������� ������Ȳ
  	SUM(CASE WHEN t00.UPKWON = '��������' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as JUCHOOK, 
  	-- ��Ÿ ������Ȳ
  	SUM(CASE WHEN t00.UPKWON = '��Ÿ' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU) as ETC,
  	t00.newINDU_TOT_AMT,
  	t00.newINDU_CNT
FROM
  	(
    SELECT DISTINCT 
    	t0.GG_YM, 
      	t0.newINDU, 
      	t0.newINDU_NM,
      	t0.UPKWON, 
      	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.newINDU, t0.GG_YM, t0.UPKWON) as newINDU_AMT, -- ����, ���Ǻ�, �Ż���� ������
      	SUM(t0.BRNO_AMT) OVER(PARTITION BY t0.GG_YM, t0.newINDU) as newINDU_TOT_AMT,	-- �Ż���� �� ���� �ܾ�
      	COUNT(t0.BRNO) OVER(PARTITION BY t0.GG_YM, t0.newINDU) as newINDU_CNT	-- �Ż���� ���� ��
    FROM 
      	(
        SELECT 
        	t.GG_YM, 
          	t.BRNO, 
          	t.SOI_CD, 
          	CASE 
          		WHEN t.SOI_CD in ('01') THEN 'Ư������' 
          		WHEN t.SOI_CD in ('03', '05', '07') THEN '�Ϲ�����' 
          		WHEN t.SOI_CD in ('11', '13', '15') THEN '����' 
          		WHEN t.SOI_CD in ('21', '61', '71', '76') THEN '����' 
          		WHEN t.SOI_CD in ('31', '33', '35', '37') THEN '����' 
          		WHEN t.SOI_CD in ('44', '74', '79', '81', '85', '87', '89') THEN '��ȣ����' 
          		WHEN t.SOI_CD in ('41') THEN '��������' 
          		ELSE '��Ÿ' 
          	END as UPKWON,	-- ���� ���� ����
          	t.BRNO_AMT, 
          	t.newINDU,
          	t.newINDU_NM
        FROM 
          	BASIC_newBIZ_LOAN t 
        WHERE
			CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
      	) t0 
  	) t00
ORDER BY 
	t00.GG_YM, t00.newINDU;