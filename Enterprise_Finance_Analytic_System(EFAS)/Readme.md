# Enterprise Finance Analytic System(EFAS) related SQL code

## Data Table list
* CORP_BIZ_DATA (기업신용공여, 개인대출 및 연체현황)
* TCB_NICE_COMP_OUTL (NICE 업체개요)
* TCB_NICE_COMP_CRDT_CLSS (NICE 신용등급)
* TCB_NICE_FNST (NICE 업체개요)
* TCB_NICE_ACT_CD (NICE 개정코드)
* IT_D2_INPT_DATA_BY_DEGR (혁신성장정책금융 공급현황)
* EFAStoKICS66 (KSIC와 EFAS 코드 매핑)
* ITTtoSOI2 (금융기관코드 ITT와 업종코드 SOI2 간 매핑)
* IGStoNewINDU (혁신성장코드와 신산업 코드 간 매핑)

## Code Structure
* `CommonStandBy.sql`
* 기간산업_기업(Infra_BIZ)
  - `InfraBizStandBy.sql`
  - 기업 대출
    + `BizLoanTrend_TOTAL.sql`
    + `BizLoanTrend_BIZSIZE.sql`
    + `BizLoanTrend_EFAS.sql`
    + `BizLoanTrend_UPKWON.sql`
  - 기업 담보
    + `BizDamboTrend.sql`
    + `BizDamboFlow.sql` 
  - 기업 건전성
    + (연체율) `BizOverdueTrend.sql`
    + (과다부채기업비중) `BizOverDebtRatio_BIZSIZE.sql`, `BizOverDebtRatio_EFAS.sql`
    + 한계기업비중
      + (영업손실기준) `BizMarginalRatio_BIZSIZE.sql`, `BizMarginalRatio_EFAS.sql`
      + (이자보상배율기준) `BizMarginalRatio_BIZSIZE.sql`, `BizMarginalRatio_EFAS.sql`
  - 기업 재무비율
    + 성장성
      + (매출액증가율) `SalesGrowthRate_BIZSIZE.sql`, `SalesGrowthRate_EFAS`
      + (총자산증가율) `AssetsGrowthRate_BIZSIZE.sql`, `AssetsGrowthRate_EFAS.sql`
      + (자기자본증가율) `StockholderGrowthRate_BIZSIZE.sql`, `StockholderGrowthRate_EFAS.sql`
    + 수익성
      + (매출액영업이익률) `OperatingProfitRatio_BIZSIZE.sql`, `OperatingProfitRatio_EFAS.sql`
      + (총자산영업이익률) `ReturnOnAssets_BIZSIZE.sql`, `ReturnOnAssets_EFAS.sql`
      + (자기자본이익률) `ReturnOnEquity_BIZSIZE.sql`, `ReturnOnEquity_EFAS.sql`
    + 안정성
      + (부채비율) `BizDebtRatio_BIZSIZE.sql`, `BizDebtRatio_EFAS.sql`
      + (자기자본비율) `CapitalAdequacyRatio_BIZSIZE.sql`, `CapitalAdequacyRatio_EFAS.sql`
      + (이자보상배율) `BizIntcovRatio_BIZSIZE.sql`, `BizIntcovRatio_EFAS.sql`
    + 활동성
      + (총자산회전율) `AssetTurnoverRatio_BIZSIZE.sql`, `AssetTurnoverRatio_EFAS.sql`
      + (재고자산회전율) `InventoryTurnoverRatio_BIZSIZE.sql`, `InventoryTurnoverRatio_EFAS.sql`


* 기간산업_개인(Infra_IND)
   - `IndBizStandBy.sql`
   - `IndBizLoan.sql`
   - `IndBizIntegrity.sql`


* 신산업(newINDU)
  - `newINDUBizStandBy.sql`
  - 신산업 기업대출
    + `newINDU_BizLoan.sql`
  - 신산업 건전성
    + (연체율) `newINDU_BizLoan.sql`
    + (과다부채기업비중) `newINDU_BizOverDebtRatio.sql`
    + (한계기업비중) `newINDU_BizMarginalRatio.sql`
  - 신산업 경영별 경영실적
    + `OperatingProfitRatio_newINDU.sql`
    + `Sales_newINDU.sql`
  - 신산업 재무비율
    + 성장성
      + (매출액증가율) `SalesGrowthRate_BIZSIZE.sql`, `SalesGrowthRate_EFAS`
      + (총자산증가율) `AssetsGrowthRate_BIZSIZE.sql`, `AssetsGrowthRate_EFAS.sql`
      + (자기자본증가율) `StockholderGrowthRate_BIZSIZE.sql`, `StockholderGrowthRate_EFAS.sql`
    + 수익성
      + (매출액영업이익률) `OperatingProfitRatio_BIZSIZE.sql`, `OperatingProfitRatio_EFAS.sql`
      + (총자산영업이익률) `ReturnOnAssets_BIZSIZE.sql`, `ReturnOnAssets_EFAS.sql`
      + (자기자본이익률) `ReturnOnEquity_BIZSIZE.sql`, `ReturnOnEquity_EFAS.sql`
    + 안정성
      + (부채비율) `BizDebtRatio_BIZSIZE.sql`, `BizDebtRatio_EFAS.sql`
      + (자기자본비율) `CapitalAdequacyRatio_BIZSIZE.sql`, `CapitalAdequacyRatio_EFAS.sql`
      + (이자보상배율) `BizIntcovRatio_BIZSIZE.sql`, `BizIntcovRatio_EFAS.sql`
    + 활동성
      + (총자산회전율) `AssetTurnoverRatio_BIZSIZE.sql`, `AssetTurnoverRatio_EFAS.sql`
      + (재고자산회전율) `InventoryTurnoverRatio_BIZSIZE.sql`, `InventoryTurnoverRatio_EFAS.sql`

## Running Procedure
1. `CommonStandBy.sql` 실행
2. 기간산업_기업(Infra_BIZ) 실행
    - `InfraBizStandBy.sql`을 우선 실행하고 나머지 SQL파일 실행 (순서 무관)
3. 기간산업_개인(Infra_IND) 실행
    - `IndBizStandBy.sql`을 우선 실행하고 나머지 SQL파일 실행 (순서 무관)
4. 신산업(newINDU) 실행 
    - `newINDUBizStandBy.sql`을 우선 실행하고 나머지 SQL파일 실행 (순서 무관)
