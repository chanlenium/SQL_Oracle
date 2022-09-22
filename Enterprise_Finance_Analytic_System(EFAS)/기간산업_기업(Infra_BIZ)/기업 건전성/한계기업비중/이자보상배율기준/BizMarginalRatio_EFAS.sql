/*****************************************************
 * ������ ��ǥ ���� - �Ѱ��� ���� (���� p.6, [ǥ])
 * (����4) �����ٳ⵵ ���ں������ 1�̸�, (����5) 2�⿬�� ���ں������ 1�̸�, (����6) 3�⿬�� ���ں������ 1�̸�
 * Ȱ�� ���̺� : TCB_NICE_FNST, GIUP_RAW -> MARGINALCORP_TB ����
 *****************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS MARGINALCORP_TB;
-- (Standby) MARGICALCORP_TB ���̺� ����(���س��, ���ι�ȣ, ����Ը�, KSIC, ��������(�ս�), ���ں��, ���ں������, �̾����ڵ�)
SELECT 
  	t0.STD_YM,
	t0.CORP_NO,
	t0.COMP_SCL_DIVN_CD,
	t0.OSIDE_ISPT_YN,
	t0.BLIST_MRKT_DIVN_CD,
	t0.KSIC,
	t0.SEAC_DIVN,
	t0.OPPROFIT,
	t0.INTEXP,
	t0.INTCOVRATIO,
	DECODE(t0.EFAS_4, NULL, 
		DECODE(t0.EFAS_3, NULL, 
			DECODE(t0.EFAS_2, NULL, NULL, t0.EFAS_2)
		, t0.EFAS_3)
	, t0.EFAS_4) as EFAS
  	INTO MARGINALCORP_TB 
FROM 
	(
	SELECT DISTINCT
		t1000.*,
		t2000.EFAS_CD as EFAS_2
	FROM(
		SELECT DISTINCT
			t100.*,
			t200.EFAS_CD as EFAS_3
		FROM(
			SELECT 
				t10.*, 
				t20.EFAS_CD as EFAS_4
			FROM 
			  	(
			    SELECT DISTINCT 
			    	SUBSTR(t1.STD_DT, 1, 6) as STD_YM, 
			    	t1.SEAC_DIVN,
			      	t2.CORP_NO, 
			     	t2.COMP_SCL_DIVN_CD, 
			     	t2.OSIDE_ISPT_YN,
			      	t2.BLIST_MRKT_DIVN_CD,
			      	t2.KSIC, 
			      	t1.OPPROFIT, 
			      	t1.INTEXP, 
			      	-- ���ں������ ���
			      	ROUND(t1.OPPROFIT / DECODE(t1.INTEXP, 0, 1, t1.INTEXP), 2) as INTCOVRATIO 
			    FROM 
			      	(
			        SELECT 
			          	t000.COMP_CD, 
			          	t000.SEAC_DIVN,
			          	t000.STD_DT, 
			          	t000.INTEXP, 
			          	t000.OPPROFIT 
			        FROM 
			          	(
			            SELECT 
			              	t00.STD_YM, 
			              	t00.COMP_CD, 
			              	t00.SEAC_DIVN,
			              	t00.STD_DT, 
			              	t00.INTEXP, 
			              	t00.OPPROFIT, 
			              	-- ���� �������ڿ� ��ϵ� �繫��ǥ�� ������ ���س���� �ֱ��� ������ ��� 
			              	ROW_NUMBER() OVER(PARTITION BY t00.COMP_CD, t00.STD_DT ORDER BY t00.STD_YM DESC) as LAST_STD_YM 
			            FROM 
			              	(
			                SELECT DISTINCT 
			                	t0.STD_YM, 
			                  	t0.COMP_CD, 
			                  	t0.SEAC_DIVN,
			                  	t0.STD_DT, 
			                  	SUM(t0.INTEXP) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as INTEXP,	-- ���ں��
			                  	SUM(t0.OPPROFIT) OVER(PARTITION BY t0.STD_YM, t0.COMP_CD, t0.STD_DT) as OPPROFIT -- ��������
			                FROM 
			                  	(
			                    SELECT 
			                      	t.STD_YM, 	-- �����Ͱ� ���ߵ� ���
			                      	t.COMP_CD, 
			                      	t.SEAC_DIVN,	-- ��걸�� (K: ���, B: �ݱ�, F: 1/4�б�, T: 3/4�б�)
			                      	t.STD_DT, 	-- �繫������ ������
			                      	DECODE(t.ITEM_CD, '5000', t.AMT, 0) as OPPROFIT,	-- ��������(�ս�)
			                      	DECODE(t.ITEM_CD, '6110', t.AMT, 0) as INTEXP	-- ��������(�ս�)
			                    FROM 
			                      	TCB_NICE_FNST t 
			                    WHERE 
			                      	t.REPORT_CD = '12' 
			                      	AND t.ITEM_CD in ('5000', '6110') -- ��������(5000), ���ں��(6110) 
			                  	) t0
			                WHERE 
			                	CAST(t0.STD_DT AS INTEGER)  IN (		-- �ֱ� 5����
					                CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER),
							        CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER),
							        CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER),
							        CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER),
							        CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 10000,
							        CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 10000,
							        CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 10000,
							        CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 10000,
							        CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 20000,
							        CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 20000,
							        CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 20000,
							        CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 20000,
							        CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 30000,
							        CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 30000,
							        CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 30000,
							        CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 30000,
							        CAST(CONCAT( '${inputYYYY}', '1231') as INTEGER) - 40000,
							        CAST(CONCAT( '${inputYYYY}', '0930') as INTEGER) - 40000,
							        CAST(CONCAT( '${inputYYYY}', '0630') as INTEGER) - 40000,
							        CAST(CONCAT( '${inputYYYY}', '0331') as INTEGER) - 40000) 
			              	) t00
			          	) t000 
			        WHERE 
			          	t000.LAST_STD_YM = '1'
			      	) t1 
			      	LEFT JOIN GIUP_RAW t2 
			      		ON t1.COMP_CD = t2.COMP_CD 
			      		AND t2.OSIDE_ISPT_YN = 'Y'	-- �ܰ� ���
			  	) t10
				LEFT JOIN EFASTOKSIC66 t20 
					ON SUBSTR(t10.KSIC, 1, 4) = t20.KSIC	-- KSIC 4�ڸ��� ����
			) t100
			LEFT JOIN EFASTOKSIC66 t200
				ON SUBSTR(t100.KSIC, 1, 3) = t200.KSIC	-- KSIC 3�ڸ��� ����
		)t1000
	  	LEFT JOIN EFASTOKSIC66 t2000
			ON SUBSTR(t1000.KSIC, 1, 2) = t2000.KSIC	-- KSIC 2�ڸ��� ����
	) t0  	
WHERE t0.KSIC is not NULL
	AND 
	CASE
		WHEN '${isSangJang}' = 'Y'	-- �������� ���
		THEN t0.BLIST_MRKT_DIVN_CD in ('1', '2')
		ELSE t0.SEAC_DIVN = 'K'		-- �ܰ������ ���
	END;
-- ��� ��ȸ
SELECT * FROM MARGINALCORP_TB ORDER BY CORP_NO, STD_YM; 

  
  
/****************************************************************
 * �Ѱ�������(���� 4~6�� ����, ���ں������) : ������ ��Ȳ (���� p.6, [ǥ])
 * RFP p.16 [ǥ] �ѱ������� : ������ ��Ȳ
 * Ȱ�� ���̺� : INTCOVRATIO_TB -> EFAS_INTCOVRATIO_TB ����
 ****************************************************************/
-- ���� �����Ͱ� ������ table �����ϰ� ���� ����
DROP TABLE IF EXISTS EFAS_MARGINALCORP_TB;
-- (Step1) EFAS_MARGINALCORP_TB ���̺� ����
-- EFAS, ���س⵵ ���� ��ü �����, ���س⵵ ���� 1���⿬�� ���ں������<1 ��� ��, ���س⵵ ���� 2���⿬�� ���ں������<1 ��� ��, ���س⵵ ���� 3���⿬�� ���ں������<1 ��� ��
-- ���⵵ ���� ��ü �����, ���⵵ ���� 1���⿬�� ���ں������<1 ��� ��, ���⵵ ���� 2���⿬�� ���ں������<1 ��� ��, ���⵵ ���� 3���⿬�� ���ں������<1 ��� ��
SELECT DISTINCT 
	t00000.EFAS,
	t00000.thisYM,
	CASE	-- ���س⵵ ��ü �����
		WHEN '${isSangJang}' = 'Y'	
		THEN SUM(DECODE(t00000.STD_YM, t00000.thisYM, t00000.CNTTOTCORP, 0)) OVER(PARTITION BY t00000.EFAS)
		ELSE SUM(DECODE(t00000.STD_YM, SUBSTR(t00000.thisYM, 1, 4), t00000.CNTTOTCORP, 0)) OVER(PARTITION BY t00000.EFAS)
	END as "this_CNTTOTCORP",
	CASE	-- ���س⵵ ���� 1���� ���� ���ں������ < 1
		WHEN '${isSangJang}' = 'Y'	
		THEN SUM(DECODE(t00000.STD_YM, t00000.thisYM, t00000.CNT_N1_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
		ELSE SUM(DECODE(t00000.STD_YM, SUBSTR(t00000.thisYM, 1, 4), t00000.CNT_N1_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
	END as "this_CNT_N1_UNDERINTCOV",
	CASE	-- ���س⵵ ���� 2���� ���� ���ں������ < 1
		WHEN '${isSangJang}' = 'Y'	
		THEN SUM(DECODE(t00000.STD_YM, t00000.thisYM, t00000.CNT_N2_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
		ELSE SUM(DECODE(t00000.STD_YM, SUBSTR(t00000.thisYM, 1, 4), t00000.CNT_N2_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
	END as "this_CNT_N2_UNDERINTCOV",
	CASE	-- ���س⵵ ���� 3���� ���� ���ں������ < 1
		WHEN '${isSangJang}' = 'Y'	
		THEN SUM(DECODE(t00000.STD_YM, t00000.thisYM, t00000.CNT_N3_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
		ELSE SUM(DECODE(t00000.STD_YM, SUBSTR(t00000.thisYM, 1, 4), t00000.CNT_N3_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
	END as "this_CNT_N3_UNDERINTCOV",
	CASE	-- ���⵵ ��ü �����
		WHEN '${isSangJang}' = 'Y'	
		THEN SUM(DECODE(t00000.STD_YM, CAST(t00000.thisYM - 100 as VARCHAR), t00000.CNTTOTCORP, 0)) OVER(PARTITION BY t00000.EFAS)
		ELSE SUM(DECODE(t00000.STD_YM, SUBSTR(CAST(t00000.thisYM - 100 as VARCHAR), 1, 4), t00000.CNTTOTCORP, 0)) OVER(PARTITION BY t00000.EFAS)
	END as "prev_CNTTOTCORP",
	CASE	-- ���⵵ ���� 1���� ���� ���ں������ < 1
		WHEN '${isSangJang}' = 'Y'	
		THEN SUM(DECODE(t00000.STD_YM, CAST(t00000.thisYM - 100 as VARCHAR), t00000.CNT_N1_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
		ELSE SUM(DECODE(t00000.STD_YM, SUBSTR(CAST(t00000.thisYM - 100 as VARCHAR), 1, 4), t00000.CNT_N1_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
	END as "prev_CNT_N1_UNDERINTCOV",
	CASE	-- ���س⵵ ���� 2���� ���� ���ں������ < 1
		WHEN '${isSangJang}' = 'Y'	
		THEN SUM(DECODE(t00000.STD_YM, CAST(t00000.thisYM - 100 as VARCHAR), t00000.CNT_N2_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
		ELSE SUM(DECODE(t00000.STD_YM, SUBSTR(CAST(t00000.thisYM - 100 as VARCHAR), 1, 4), t00000.CNT_N2_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
	END as "prev_CNT_N2_UNDERINTCOV",
	CASE	-- ���س⵵ ���� 3���� ���� ���ں������ < 1
		WHEN '${isSangJang}' = 'Y'	
		THEN SUM(DECODE(t00000.STD_YM, CAST(t00000.thisYM - 100 as VARCHAR), t00000.CNT_N3_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
		ELSE SUM(DECODE(t00000.STD_YM, SUBSTR(CAST(t00000.thisYM - 100 as VARCHAR), 1, 4), t00000.CNT_N3_UNDERINTCOV, 0)) OVER(PARTITION BY t00000.EFAS)
	END as "prev_CNT_N3_UNDERINTCOV"
	INTO EFAS_MARGINALCORP_TB
FROM 
  	(
    SELECT DISTINCT 
    	CASE
			WHEN '${isSangJang}' = 'Y'	-- �������� ���
			THEN t0000.STD_YM
			ELSE SUBSTR(t0000.STD_YM, 1, 4)		-- �ܰ������ ���
		END as "STD_YM",
      	t0000.EFAS, 
      	CASE	-- ���س⵵	
	  		WHEN '${isSangJang}' = 'Y' 
	  		THEN
	  			MAX(t0000.STD_YM) OVER(PARTITION BY t0000.EFAS)
	  		ELSE
	  			DECODE(SUBSTR(MAX(t0000.STD_YM) OVER(PARTITION BY t0000.EFAS), 5), '12', 
	  			MAX(t0000.STD_YM) OVER(PARTITION BY t0000.EFAS),
	  			CONCAT(CAST(SUBSTR(MAX(t0000.STD_YM) OVER(PARTITION BY t0000.EFAS), 1, 4) - 1 as VARCHAR), '12'))
	  	END as thisYM,
	  	-- ���س��, �����ڵ忡 ���� ��ü ��� ��
	  	CASE
			WHEN '${isSangJang}' = 'Y'	-- �������� ���
			THEN COUNT(t0000.CORP_NO) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS)
			ELSE COUNT(t0000.CORP_NO) OVER(PARTITION BY SUBSTR(t0000.STD_YM, 1, 4), t0000.EFAS)
		END as "CNTTOTCORP",
	  	-- (����4 : �����ٳ⵵ ���ں������ <1)�� ���� �Ѱ� ��� ��
		CASE
			WHEN '${isSangJang}' = 'Y'	-- �������� ���
			THEN SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS)
			ELSE SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 1 THEN 1 ELSE 0 END) OVER(PARTITION BY SUBSTR(t0000.STD_YM, 1, 4), t0000.EFAS)
		END as "CNT_N1_UNDERINTCOV",
	  	-- (����5 : 2���� ���� ���ں������ <1)�� ���� �Ѱ� ��� ��
	  	CASE
			WHEN '${isSangJang}' = 'Y'	-- �������� ���
			THEN SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS)
			ELSE SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 2 THEN 1 ELSE 0 END) OVER(PARTITION BY SUBSTR(t0000.STD_YM, 1, 4), t0000.EFAS)
		END as "CNT_N2_UNDERINTCOV",
		-- (����6 : 3���� ���� ���ں������ <1)�� ���� �Ѱ� ��� ��
		CASE
			WHEN '${isSangJang}' = 'Y'	-- �������� ���
			THEN SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY t0000.STD_YM, t0000.EFAS)
			ELSE SUM(CASE WHEN t0000.CONTUNDERINTCOVYY >= 3 THEN 1 ELSE 0 END) OVER(PARTITION BY SUBSTR(t0000.STD_YM, 1, 4), t0000.EFAS)
		END as "CNT_N3_UNDERINTCOV"
	FROM 
      	(
        SELECT 
          	t000.*, 
          	CASE WHEN t000.INTCOVRATIO < 1 THEN 
          		CASE WHEN t000.N1_INTCOVRATIO < 1 THEN 
          			CASE WHEN t000.N2_INTCOVRATIO < 1 THEN 3 -- 3�⿬�� ���ں������� 1�̸�
          				ELSE 2 -- 2�⿬�� ���ں������� 1�̸�
          			END ELSE 1 -- �����ٳ⵵ ���ں������� 1�̸�
          		END ELSE 0 
          	END as CONTUNDERINTCOVYY -- ���� ���ں������� 1�̸� ���
        FROM 
          	(
            SELECT DISTINCT 
            	t00.STD_YM, 
              	t00.CORP_NO, 
              	t00.COMP_SCL_DIVN_CD, 
              	t00.BLIST_MRKT_DIVN_CD,
              	t00.EFAS, 
              	t00.INTCOVRATIO,	-- �����ٳ⵵ ���ں������
              	t00.N1_INTCOVRATIO,	-- 2���� ���ں������	
              	t00.N2_INTCOVRATIO	-- 3���� ���ں������
            FROM 
              	(
                SELECT 
                  	t10.*, 
                  	t20.INTCOVRATIO as N2_INTCOVRATIO	-- 3���� ���ں������ 
                FROM 
                  	(
                    SELECT 
                      	t1.*, 
                      	t2.INTCOVRATIO as N1_INTCOVRATIO	-- 2���� ���ں������ 
                    FROM 
                      	MARGINALCORP_TB t1 
                      	LEFT JOIN MARGINALCORP_TB t2 
                      		ON t1.CORP_NO = t2.CORP_NO 
                      		AND CAST(t1.STD_YM - 100 as VARCHAR) = t2.STD_YM
                  	) t10 
                  	LEFT JOIN MARGINALCORP_TB t20 
                  		ON t10.CORP_NO = t20.CORP_NO 
                  		AND CAST(t10.STD_YM - 200 as VARCHAR) = t20.STD_YM
              	) t00 
            WHERE 
            	SUBSTR(t00.STD_YM, 1, 4) IN (	-- �ֱ� 3����
			    	CAST('${inputYYYY}' as VARCHAR), 
			        CAST('${inputYYYY}' - 1 as VARCHAR), 
			        CAST('${inputYYYY}' - 2 as VARCHAR))  
          	) t000
      	) t0000
  	) t00000;
-- ��� ��ȸ
SELECT * FROM EFAS_MARGINALCORP_TB ORDER BY TO_NUMBER(EFAS, '999999');



-- (Step2) ���س�/���� ���� ��ä���� �� ���� ���� ��� ������ ���
DROP TABLE IF EXISTS RESULT_MARGINAL_RATIO_EFAS;
SELECT 
  	t.EFAS, 
  	t.thisYM,
  	-- �����ٳ⵵ ���ں�������<1 ���� �Ѱ���
  	ROUND(t.this_CNT_N1_UNDERINTCOV / NULLIF(t.this_CNTTOTCORP, 0), 4) as N1_this_MARGINALRATIO,	-- ���س⵵ 
  	ROUND(t.prev_CNT_N1_UNDERINTCOV / NULLIF(t.prev_CNTTOTCORP, 0), 4) as N1_prev_MARGINALRATIO, -- ���⵿��
  	-- 2�⿬�� ���ں�������<1 ���� �Ѱ���
  	ROUND(t.this_CNT_N2_UNDERINTCOV / NULLIF(t.this_CNTTOTCORP, 0), 4) as N2_this_MARGINALRATIO,	-- ���س⵵ 
  	ROUND(t.prev_CNT_N2_UNDERINTCOV / NULLIF(t.prev_CNTTOTCORP, 0), 4) as N2_prev_MARGINALRATIO, -- ���⵿��
  	-- 3�⿬�� ���ں�������<1 ���� �Ѱ���
  	ROUND(t.this_CNT_N3_UNDERINTCOV / NULLIF(t.this_CNTTOTCORP, 0), 4) as N3_this_MARGINALRATIO, -- ���س⵵ 
  	ROUND(t.prev_CNT_N3_UNDERINTCOV / NULLIF(t.prev_CNTTOTCORP, 0), 4) as N3_prev_MARGINALRATIO -- ���⵿��
  	INTO RESULT_MARGINAL_RATIO_EFAS
FROM 
  	EFAS_MARGINALCORP_TB t 
ORDER BY 
  	TO_NUMBER(t.EFAS, '99');
  	
  
  
-- �ӽ����̺� ����
DROP TABLE IF EXISTS MARGINALCORP_TB;
-- ��� ��ȸ
SELECT * FROM RESULT_MARGINAL_RATIO_EFAS order by TO_NUMBER(EFAS, '99');