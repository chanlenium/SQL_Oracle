/**************************************/
/*  KSIC 이력정보 획득 (interpolation)  */
/**************************************/
-- KSIC 테이블이 불완전(공백)하므로 월별 신용공여정보가 있는 모든 기업에 대해 KSIC를 매핑하지 못함
-- kSIC 보간 규칙 : (1) 해당 년월에 KSIC정보가 없으면 가장 최근 과거 KSIC를 끌어다 쓰고
--                (2) 가장 최근 과거 KSIC가 없으면, 가장 가까운 미래의 KSIC를 끌어다 씀
-- (STEP_1) KSIC Table 생성 : 'TDB_DW.TCB_NICE_COMP_OUTL'에서 보유 기업의 월별 KSIC정보를 가져옴
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE sand_tdb_igs.ksic_tb IF EXISTS;
-- Table 생성 (기준년월, 법인번호, 기업규모(대/중/소), KSIC)
SELECT   To_number(t1.std_ym, '999999') AS STD_YM,
         t1.corp_no,
         t1.comp_scl_divn_cd,
         Substr(t1.stdd_indu_clsf_cd, 2) AS KSIC
INTO     ksic_tb
FROM     tdb_dw.tcb_nice_comp_outl t1
WHERE    t1.corp_no IS NOT NULL
AND      t1.stdd_indu_clsf_cd IS NOT NULL
ORDER BY t1.corp_no,
         t1.std_ym;

-- Table 조회
SELECT * FROM   sand_tdb_igs.ksic_tb;

-- (STEP_2)신용공여 보유 기업 리스트 Table 생성 : 'TDB_DW.CIF_GIUP'에서 보유 기업 정보(리스트)를 가져옴
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE cre_biz_list_tb IF EXISTS;
-- Table 생성 (기준년월, 법인번호)
SELECT DISTINCT To_number(t1.gg_ym, '999999') AS GG_YM, 
                t1.brwr_no
INTO            cre_biz_list_tb
FROM            tdb_dw.cif_giup t1
WHERE           t1.rpt_cd = '31'
AND             t1.acct_cd IN ('1901',
                               '5301',
                               '1391')
AND             Cast(t1.gg_ym AS INT) >= 201812
AND             t1.soi_cd IN ('01',
                              '03',
                              '05',
                              '07',
                              '11',
                              '13',
                              '15',
                              '21',
                              '31',
                              '33',
                              '35',
                              '37',
                              '41',
                              '43',
                              '44',
                              '46',
                              '61',
                              '71',
                              '74',
                              '75',
                              '76',
                              '77',
                              '79',
                              '81',
                              '83',
                              '85',
                              '87',
                              '89',
                              '91',
                              '94',
                              '95',
                              '97');

-- Table 조회
SELECT * FROM   sand_tdb_igs.cre_biz_list_tb;

-- (STEP_3)신용공여 기준년월과 KSIC 테이블 보유 년월 정보를 비교하여 'KSIC보간 규칙에 따른' KSIC 참조년월 데이터를 가져옴
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE biz_ksic_hist IF EXISTS;
-- 기준년월, 법인번호, KSIC, 기업규모 컬럼으로 구성
-- LEFT JOIN을 하더라도 multiple match가 있으면 row 수가 증가하므로 DISTINCT 적용
SELECT DISTINCT t10.gg_ym,
                t10.brwr_no,
                t20.ksic,
                t20.comp_scl_divn_cd
INTO            biz_ksic_hist
FROM            (
                                SELECT          t2.gg_ym,
                                                t2.brwr_no, -- MIN(case when (t2.GG_YM - t1.STD_YM) >= 0 then (t2.GG_YM - t1.STD_YM) end) AS min_positive,
                                                Nvl(t2.gg_ym - Min(
                                                CASE
                                                                WHEN (
                                                                                                t2.gg_ym - t1.std_ym) >= 0 THEN (t2.gg_ym - t1.std_ym)
                                                END), Min(t1.std_ym)) AS KSIC_REF_YM
                                FROM            sand_tdb_igs.cre_biz_list_tb t2
                                LEFT OUTER JOIN sand_tdb_igs.ksic_tb t1
                                ON              t2.brwr_no = t1.corp_no
                                GROUP BY        t2.gg_ym,
                                                t2.brwr_no
                                ORDER BY        t2.brwr_no,
                                                t2.gg_ym) AS t10
LEFT JOIN       sand_tdb_igs.ksic_tb                      AS t20
ON              t10.brwr_no = t20.corp_no
AND             t10.ksic_ref_ym = t20.std_ym
ORDER BY        t10.gg_ym,
                t10.brwr_no;

-- 테이블 조회
SELECT * FROM   sand_tdb_igs.biz_ksic_hist;

-- KSIC 이력정보 끝
-- SELECT COUNT(gg_YM) from SAND_TDB_IGS.BIZ_KSIC_HIST
/**************************************/
/*       KSIC to EFIS code 매핑       */
/**************************************/
-- 활용테이블 : SAND_TDB_IGS.BIZ_KSIC_HIST, SAND_TDB_IGS.KSICTOEFIS66
-- KSIC를 기준으로 EFIS코드와 매핑, KSIC가 null이면 '66'코드 매핑
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE biz_ksic_efis_hist IF EXISTS;
-- 테이블 생성 (KSIC가 null이면 기타코드(66) 매핑)
SELECT DISTINCT t1.gg_ym,
                t1.brwr_no,
                t1.comp_scl_divn_cd,
                t1.ksic,
                Nvl(t2.efis, '66') AS EFIS
INTO            biz_ksic_efis_hist
FROM            sand_tdb_igs.biz_ksic_hist t1
LEFT JOIN       sand_tdb_igs.ksictoefis66 t2
ON              t1.ksic = t2.ksic;

-- 테이블 조회SELECT *
FROM   sand_tdb_igs.biz_ksic_efis_hist;

/**************************************/
/* 신용등급 이력정보 획득(interpolation) */
/**************************************/
-- (STEP_1) 기업별 가장 최근 신용등급일자에 해당하는 신용등급 추출
-- 활용테이블 : TDB_DW.TCB_NICE_COMP_CRDT_CLSS, TDB_DW.TCB_NICE_COMP_OUTL
-- 동일 연월에 한 기업에 다수 신용등급이 있는 경우 최저 등급 선택
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE sand_tdb_igs.corp_cri IF EXISTS;
-- Table 생성 (법인번호, 등급시작년월, 신용등급)
SELECT t2000.corp_no,
       To_number(t1000.last_cri_ym, '999999') AS LAST_CRI_YM,
       t1000.corp_cri
INTO   corp_cri-- 법인번호 붙임(COMP_CD와 CORP 매핑)
FROM  (
                SELECT   t100.comp_cd,
                         t100.last_cri_ym,
                         Min(t100.last_cri_clss) AS CORP_CRI -- 동일 연월에 한 기업에 다수 신용등급이 있는 경우 최저 등급 선택
                FROM     (
                                SELECT t10.comp_cd,
                                       Substr(Cast(t10.last_clss_start_dt AS NVARCHAR(8)), 1, 6) AS LAST_CRI_YM,
                                       -- 신용등급 치환 (투자: 4, 투기: 3, 상환불능: 2, 신용등급미부여또는없음: 1)
                                       CASE
                                              WHEN t20.cri_clss IN ('AAA+',
                                                                    'AA+',
                                                                    'AA0',
                                                                    'AA-',
                                                                    'A+',
                                                                    'A0',
                                                                    'A-',
                                                                    'BBB+',
                                                                    'BBB0',
                                                                    'BBB-') THEN 4
                                              WHEN t20.cri_clss IN ('BB+',
                                                                    'BB0',
                                                                    'BB-',
                                                                    'B+',
                                                                    'B0',
                                                                    'B-',
                                                                    'CCC+',
                                                                    'CCC0',
                                                                    'CCC-',
                                                                    'CC+',
                                                                    'C+') THEN 3
                                              WHEN t20.cri_clss IN ('D') THEN 2
                                              WHEN t20.cri_clss IN ('R',
                                                                    'NR') THEN 1
                                              ELSE NULL
                                       END AS LAST_CRI_CLSS
                                FROM   (
                                                SELECT   t1.comp_cd,
                                                         Max(To_number(t1.clss_start_dt, '99999999')) AS LAST_CLSS_START_DT -- 기업별 가장 최근 신용등급평가 일자 선택
                                                FROM     tdb_dw.tcb_nice_comp_crdt_clss t1
                                                GROUP BY t1.comp_cd) AS t10,
                                       tdb_dw.tcb_nice_comp_crdt_clss t20
                                WHERE  t10.comp_cd = t20.comp_cd
                                AND    t10.last_clss_start_dt = t20.clss_start_dt) t100
                GROUP BY t100.comp_cd,
                         t100.last_cri_ym) AS t1000,
       tdb_dw.tcb_nice_comp_outl           AS t2000
WHERE  t1000.comp_cd = t2000.comp_cd;

-- 테이블 조회SELECT *
FROM   sand_tdb_igs.corp_cri;

-- (STEP_2) 신용공여 테이블에 신용등급 정보를 붙임
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE biz_cri_hist IF EXISTS;
-- 활용테이블 : SAND_TDB_IGS.CRE_BIZ_LIST_TB, SAND_TDB_IGS.CORP_CRI
SELECT    t10.gg_ym,
          t10.brwr_no,
          Nvl(t20.corp_cri, 1) AS CORP_CRI
INTO      biz_cri_hist
FROM      (
                          SELECT DISTINCT t2.gg_ym,
                                          t2.brwr_no,
                                          -- GG_YM을 기준으로 신용등급 정보가 있는 가장 최근 과거 년월 데이터를 불러옴 (가장 최근 과거 데이터가 없으면 가장 최근 미래 데이터를 갖고옴))
                                          Nvl(t2.gg_ym - Min(
                                          CASE
                                                          WHEN (
                                                                                          t2.gg_ym - t1.last_cri_ym) >= 0 THEN (t2.gg_ym - t1.last_cri_ym)
                                          END), Min(t1.last_cri_ym)) AS CRI_REF_YM
                          FROM            sand_tdb_igs.cre_biz_list_tb t2 -- 신용공여 테이블
                          LEFT OUTER JOIN sand_tdb_igs.corp_cri t1        -- 신용등급 테이블
                          ON              t2.brwr_no = t1.corp_no
                          GROUP BY        t2.gg_ym,
                                          t2.brwr_no
                          ORDER BY        t2.brwr_no,
                                          t2.gg_ym) AS t10
LEFT JOIN sand_tdb_igs.corp_cri                     AS t20
ON        (
                    t10.brwr_no = t20.corp_no)
AND       (
                    t10.cri_ref_ym = t20.last_cri_ym)
GROUP BY  t10.gg_ym,
          t10.brwr_no,
          t10.cri_ref_ym,
          t20.corp_cri
ORDER BY  t10.brwr_no;

-- 테이블 조회
SELECT * FROM   sand_tdb_igs.biz_cri_hist;

-- 신용등급 이력정보 끝
/******************************/
/*     기업 개요 테이블 생성     */
/******************************/
-- 과거 데이터가 있으면 table 삭제하고 새로 생성
DROP TABLE sand_tdb_igs.biz_summary IF EXISTS;
-- 테이블 생성 (기준년월, 법인번호, 기업규모, KSIC, 기업금융코드(EFIS), 신용등급그룹)
SELECT DISTINCT Cast(t1.gg_ym AS   NVARCHAR(6))  AS GG_YM,
                Cast(t1.brwr_no AS NVARCHAR(13)) AS BRWR_NO,
                t1.comp_scl_divn_cd,
                t1.ksic,
                t1.efis,
                t2.corp_cri
INTO            biz_summary
FROM            sand_tdb_igs.biz_ksic_efis_hist t1,
                sand_tdb_igs.biz_cri_hist t2
WHERE           t1.gg_ym = t2.gg_ym
AND             t1.brwr_no = t2.brwr_no
AND             Substr(t1.brwr_no, 1, 1) <> 0;

-- 테이블 조회
SELECT   * FROM     sand_tdb_igs.biz_summary
ORDER BY brwr_no,
         gg_ym;

-- 테이블 속성 확인
SELECT * FROM   information_schema.columns
WHERE  table_name = 'BIZ_SUMMARY';

-- SELECT 1 FROM _v_dual;
-- 최종 결과 테이블을 제외하고 나머지는 제거
DROP TABLE sand_tdb_igs.biz_cri_hist IF EXISTS;
DROP TABLE sand_tdb_igs.biz_ksic_efis_hist IF EXISTS;
DROP TABLE sand_tdb_igs.biz_ksic_hist IF EXISTS;
DROP TABLE sand_tdb_igs.corp_cri IF EXISTS;
DROP TABLE sand_tdb_igs.cre_biz_list_tb IF EXISTS;
DROP TABLE sand_tdb_igs.ksic_tb IF EXISTS;
