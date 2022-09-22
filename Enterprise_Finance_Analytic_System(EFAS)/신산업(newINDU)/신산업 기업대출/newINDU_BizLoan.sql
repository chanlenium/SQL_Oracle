/***************************************************************************
 *                 �Ż������ (�����������)                            
 * ������� ���̺�(BASIC_BIZ_LOAN) ���� Ȱ���Ͽ� "�Ż�� ������ �ͼ�����", "�Ż���� �濵����", "�Ż���� ��ü��" �� ��� �ۼ�
 ***************************************************************************/

		
/***********************************
 * �Ż���� ������ �ͽ�����
 * RFP p.17 [�׸�1] �Ż���� ������ �ͽ�����
 * Ȱ�� ���̺� : BASIC_newBIZ_LOAN
 * ����� �Է� : ��ȸ���س��(inputGG_YM)
 ***********************************/
DROP TABLE IF EXISTS RESULT_newINDU_BIZLoan;
SELECT DISTINCT
	t00.GG_YM,
	ROUND(t00.TOT_newINDU_AMT, 0) as TOT_newINDU_AMT,
	ROUND(SUM(t00.newINDU_AMT_1) OVER(PARTITION BY t00.GG_YM), 0) as '1 ����������',
	ROUND(SUM(t00.newINDU_AMT_2) OVER(PARTITION BY t00.GG_YM), 0) as '2 IOT����',
	ROUND(SUM(t00.newINDU_AMT_3) OVER(PARTITION BY t00.GG_YM), 0) as '3 ����Ʈ �ｺ�ɾ�',
	ROUND(SUM(t00.newINDU_AMT_4) OVER(PARTITION BY t00.GG_YM), 0) as '4 ���̿��ž�',
	ROUND(SUM(t00.newINDU_AMT_5) OVER(PARTITION BY t00.GG_YM), 0) as '5 ������ݵ�ü',
	ROUND(SUM(t00.newINDU_AMT_6) OVER(PARTITION BY t00.GG_YM), 0) as '6 ��������÷���',
	ROUND(SUM(t00.newINDU_AMT_7) OVER(PARTITION BY t00.GG_YM), 0) as '7 �����������',
	ROUND(SUM(t00.newINDU_AMT_8) OVER(PARTITION BY t00.GG_YM), 0) as '8 ESS',
	ROUND(SUM(t00.newINDU_AMT_9) OVER(PARTITION BY t00.GG_YM), 0) as '9 ����Ʈ�׸���',
	ROUND(SUM(t00.newINDU_AMT_10) OVER(PARTITION BY t00.GG_YM), 0) as '10 ������'
	INTO RESULT_newINDU_BIZLoan
FROM
	(
	SELECT 
		t0.*,
		DECODE(t0.newINDU_NM, '����������', t0.newINDU_AMT, 0) as newINDU_AMT_1,
		DECODE(t0.newINDU_NM, 'IOT ����', t0.newINDU_AMT, 0) as newINDU_AMT_2,
		DECODE(t0.newINDU_NM, '����Ʈ �ｺ�ɾ�', t0.newINDU_AMT, 0) as newINDU_AMT_3,
		DECODE(t0.newINDU_NM, '���̿��ž�', t0.newINDU_AMT, 0) as newINDU_AMT_4,
		DECODE(t0.newINDU_NM, '������ݵ�ü', t0.newINDU_AMT, 0) as newINDU_AMT_5,
		DECODE(t0.newINDU_NM, '��������÷���', t0.newINDU_AMT, 0) as newINDU_AMT_6,
		DECODE(t0.newINDU_NM, '�����������', t0.newINDU_AMT, 0) as newINDU_AMT_7,
		DECODE(t0.newINDU_NM, 'ESS', t0.newINDU_AMT, 0) as newINDU_AMT_8,
		DECODE(t0.newINDU_NM, '����Ʈ�׸���', t0.newINDU_AMT, 0) as newINDU_AMT_9,
		DECODE(t0.newINDU_NM, '������', t0.newINDU_AMT, 0) as newINDU_AMT_10
	FROM 	
		(
		SELECT DISTINCT
			t.GG_YM,
			t.newINDU,
			t.newINDU_NM,
			SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM, t.newINDU) as newINDU_AMT,
			SUM(t.BRNO_AMT) OVER(PARTITION BY t.GG_YM) as TOT_newINDU_AMT
		FROM  BASIC_newBIZ_LOAN t
		WHERE
			CAST(t.GG_YM AS INTEGER) <= ${inputGG_YM}
			AND NVL(t.EFAS, '') <> '55'	-- ��������� ����
		) t0
	) t00;	



	

/******************************************************
 * �Ż�� ������Ȳ - ������ ���� �ܾ�([ǥ])
 * RFP p.17 [ǥ] ������ ���� �ܾ�
 * Ư������ : 01
 * �Ϲ����� : 03, 05, 07
 * ���� : 11, 13, 15
 * ���� : 21, 61, 71, 76
 * ���� : 31, 33, 35, 37
 * ��ȣ���� : 44, 74, 79, 81, 85, 87, 89
 * �������� : 41
 * ��Ÿ : 43, 46, 47, 75, 77, 83, 91, 94, 95, 97
 *******************************************************/
DROP TABLE IF EXISTS RESULT_newINDU_BIZLoan_Table;
SELECT
	t00.GG_YM,
	TO_NUMBER(t00.newINDU, '99') as "newINDU",
	t00.newINDU_NM,
  	-- �Ϲ����� ������Ȳ
  	ROUND(SUM(CASE WHEN t00.UPKWON = '�Ϲ�����' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as GBANK, 
  	-- Ư������ ������Ȳ
  	ROUND(SUM(CASE WHEN t00.UPKWON = 'Ư������' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as SBANK, 
  	-- ���� ������Ȳ
  	ROUND(SUM(CASE WHEN t00.UPKWON = '����' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as BOHUM, 
  	-- ���� ������Ȳ
  	ROUND(SUM(CASE WHEN t00.UPKWON = '����' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as KEUMTOO, 
  	-- ���� ������Ȳ
  	ROUND(SUM(CASE WHEN t00.UPKWON = '����' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as YEOJUN, 
  	-- ��ȣ���� ������Ȳ
  	ROUND(SUM(CASE WHEN t00.UPKWON = '��ȣ����' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as SANGHO, 
  	-- �������� ������Ȳ
  	ROUND(SUM(CASE WHEN t00.UPKWON = '��������' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as JUCHOOK, 
  	-- ��Ÿ ������Ȳ
  	ROUND(SUM(CASE WHEN t00.UPKWON = '��Ÿ' THEN t00.newINDU_AMT ELSE 0 END) OVER(PARTITION BY t00.GG_YM, t00.newINDU), 0) as ETC,
  	t00.newINDU_TOT_AMT,
  	t00.newINDU_CNT
  	INTO RESULT_newINDU_BIZLoan_Table
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
			AND NVL(t.EFAS, '') <> '55'
      	) t0 
  	) t00;
	

-- ��� ��ȸ
SELECT * FROM RESULT_newINDU_BIZLoan ORDER BY GG_YM;
SELECT DISTINCT * FROM RESULT_newINDU_BIZLoan_Table ORDER BY GG_YM, newINDU;
