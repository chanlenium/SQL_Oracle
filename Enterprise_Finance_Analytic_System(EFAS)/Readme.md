# Enterprise_Finance_Analytic_System(EFAS) related SQL code

## Data Table list
* CORP_BIZ_DATA (기업신용공여, 개인대출 및 연체현황)
* TCB_NICE_COMP_OUTL (NICE 업체개요)
* TCB_NICE_COMP_CRDT_CLSS (NICE 신용등급)
* TCB_NICE_FNST (NICE 업체개요)
* TCB_NICE_ACT_CD (NICE 개정코드)
* IT_D2_INPT_DATA_BY_DEGR (혁신성장정책금융 공급현황)
* KICStoEFIS66 (KSIC와 EFAS 코드 매핑)
* ITTtoSOI2 (금융기관코드 ITT와 업종코드 SOI2 간 매핑)
* IGStoNewINDU (혁신성장코드와 신산업 코드 간 매핑)

## Code Structure
* `CommonStandBy.sql`
* 기간산업_기업(Infra_BIZ)
  - `InfraBizStandBy.sql`
  - 기업 대출
    + `BizLoanTrend(TOTAL).sql`
    + `BizLoanTrend(BIZ_SIZE).sql`
    + `BizLoanTrend(EFAS).sql`
    + `BizLoanTrend(UPKWON).sql`
  - 기업 담보
    + `BizDamboTrend.sql`
    + `BizDamboFlow.sql` 
  - 기업 건전성
    + (연체율) `BizOverdueTrend.sql`
    + (부채비율) `BizDebtRatio.sql`
    + (과다부채기업비중) `BizOverDebtRatio.sql`
    + (이자보상배율) `BizIntcovRatio.sql`
    + (한계기업비중) `BizMarginalRatio.sql`
  - 기업 재무비율
    + (성장성) 매출액증가율 `SalesGrowthRate.sql`, 총자산증가율 `AssetsGrowthRate.sql`, 자기자본증가율 `CapStockGrowthRate.sql`
    + (수익성) 매출액영업이익률 `OperatingProfitRatio.sql`, 총자산영업이익률 `ReturnOnAssets`, 자기자본이익률 `ReturnOnEquity.sql`
    + (안정성) 부채비율 `DebttoEquityRatio.sql`, 자기자본비율 `CapitalAdequacyRatio.sql`, 이자보상배율 `InterestCoverageRatio.sql`
    + (활동성) 총자산회전율 `AssetTurnoverRatio.sql`, 재고자산회전율 `InventoryTurnoverRatio.sql`
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
  - 신산업 재무비율
    + (성장성) 매출액증가율 `newINDU_SalesGrowthRate.sql`, 총자산증가율 `newINDU_AssetsGrowthRate.sql`, 자기자본증가율 `newINDU_CapStockGrowthRate.sql`
    + (수익성) 매출액영업이익률 `newINDU_OperatingProfitRatio.sql`, 총자산영업이익률 `newINDU_ReturnOnAssets`, 자기자본이익률 `newINDU_ReturnOnEquity.sql`
    + (안정성) 부채비율 `newINDU_DebttoEquityRatio.sql`, 자기자본비율 `newINDU_CapitalAdequacyRatio.sql`, 이자보상배율 `newINDU_InterestCoverageRatio.sql`
    + (활동성) 총자산회전율 `newINDU_AssetTurnoverRatio.sql`, 재고자산회전율 `newINDU_InventoryTurnoverRatio.sql`

## Running Procedure
1. `CommonStandBy.sql` 실행
2. 기간산업_기업(Infra_BIZ) 실행
    - `InfraBizStandBy.sql`을 우선 실행하고 나머지 SQL파일 실행 (순서 무관)
3. 기간산업_개인(Infra_IND) 실행
    - `IndBizStandBy.sql`을 우선 실행하고 나머지 SQL파일 실행 (순서 무관)
4. 신산업(newINDU) 실행 
    - `newINDUBizStandBy.sql`을 우선 실행하고 나머지 SQL파일 실행 (순서 무관)
