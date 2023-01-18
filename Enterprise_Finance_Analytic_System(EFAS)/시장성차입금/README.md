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
