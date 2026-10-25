# Project 3 — DESIGN

**Title:** Cash in Hand, Debt on the Card: How Card Borrowers Say They Would Use a Windfall
**Dataset:** Federal Reserve Board, 2025 Survey of Consumer Finances (public file, released October 9, 2026)
**Analysts:** Lena Gan (inference, Stata 19.5) · Sara Kay (prediction, Python)
**Status:** the hypotheses and analysis plan below were fixed before any results were seen.

---

## 1. Why this project

| Criterion | Assessment |
|---|---|
| Worth asking | The share of families behind on loan payments rose from about 12% (2022) to 19.6% (2025) in the SCF. How households would use extra money is a live policy question. |
| Answerable | All variables are in the 2025 public files (verified against the codebook and the summary extract). |
| Contributory | The windfall item is new in 2025. The Fed staff note covers the spending share; it does not examine the debt share among card revolvers, co-holding, card rates, or utilization. |
| Communicable | Would you pay down the card, or keep the cash? |

## 2. Research question

Among families carrying credit card debt, what share of a hypothetical windfall would they allocate to paying down debt, and does that share differ between families who already hold more than one month of normal income in liquid assets (co-holders) and those who do not, after accounting for household characteristics, income, wealth, and other debts?

*Note:* the survey question asks about paying down debts of any kind, not credit cards specifically. All wording says "pay down debt."

## 3. Hypotheses

**H1 — Co-holding (confirmatory).** Among card revolvers, co-holders allocate a smaller share of the windfall to debt repayment than non-co-holders, after adjustment.
*Basis:* Coibion et al. (2020) found households without a cash cushion shifted toward debt repayment; Aladangady et al. (2026) found lower-liquidity households would spend somewhat more. A cost-minimizing benchmark predicts co-holders should repay, so either direction is informative.

**H2 — Interest rate (confirmatory).** A higher interest rate on the largest-balance card is associated with a larger share allocated to debt repayment.
*Basis:* Gross & Souleles (2002) found card debt responds strongly to interest rates.

**H3 — Utilization (exploratory).** Higher card utilization is associated with a larger debt-repayment share.

## 4. Sample

Families with a card balance after the last payment (X413 > 0) and positive normal income. All five implicates kept; the sample is defined within each implicate.

| Step | Families (implicate 1) |
|---|---|
| All families, 2025 SCF public file | 4,360 |
| Card revolvers | 1,568 |
| Excluded: zero or negative normal income | 0 |
| **Analytic sample** | **1,568** (range 1,566–1,572 across implicates) |

## 5. Variables

Full coding, special codes, and reference categories are in CODEBOOK.md.

| Role | Variable | Source |
|---|---|---|
| **DV** | Share of windfall to pay down debt (0–1) | MPDEBT (= X9375–X9377 series) |
| DV companions | Spend share, save share | MPSPEND, MPSAVE |
| **IV, H1** | Co-holder: liquid assets > one month of normal income | LIQ, NORMINC |
| **IV, H2** | Card interest rate (%) | X7132 |
| **IV, H3** | Utilization group: < 0.50, 0.50–0.90, > 0.90 | X413 ÷ X414 |
| Controls | Age class; marital status × sex; children; education; employment; race/ethnicity; homeowner; log normal income; IHS net worth; log card balance; mortgage, vehicle loan, student loan | Summary extract; X4100; X413 |
| Exploratory | Credit constrained; self-rated knowledge; financial literacy; spending ≥ income; income uncertainty; BNPL; late payment; liquid-asset months | Summary extract; X7366 |
| Descriptive only | Payment habit (X432); equal split; round-number answers; net worth group | — |
| Design | X42001; replicate weights WT1B1–WT1B999 × MM1–MM999; implicate from Y1, YY1 | — |

## 6. Analysis plan

All estimates combine the five implicates and use the replicate weights, with the sample restricted within each implicate (subpopulation estimation; non-sample families are never dropped).

### A. Descriptive (run first)
- Weighted means of the three shares: all families and revolvers.
- Who co-holds: survey-adjusted chi-square tests of co-holding by age, education, race, and income group.
- Equal-split and round-number frequencies, compared with the Fed note.

### B. Confirmatory
| Test | Method |
|---|---|
| H1, unadjusted | Survey-weighted t-test of mean debt share, co-holders vs. non-co-holders |
| **H1 + H2, primary model** | Fractional logit (GLM, binomial family, logit link): debt share on co-holder, card rate, and all controls |
| Effect sizes | Average marginal effects (margins) |

### C. Exploratory
| Analysis | Method |
|---|---|
| H3 | Utilization groups added to the primary model; ANOVA-style joint test across groups |
| Two-part model | Logit for any money to debt; fractional logit for the share among those who allocate any |
| Additional covariates | Credit constraints, knowledge, literacy, budget position, income uncertainty, BNPL, late payment |
| Allocation types | k-means cluster analysis on the three shares; clusters described |

### D. Robustness
| ID | Check |
|---|---|
| R1 | Linear regression instead of fractional logit |
| R2 | Fractional multinomial logit across all three shares |
| R3 | Drop families who "almost always" pay the full balance (X432 = 1; 28% of the sample) |
| R4 | Sensitivity: co-holding cutoffs of ½, 1, 2, and 3 months of normal income |
| R5 | Continuous log liquid-asset months instead of the co-holder indicator |
| R6 | Drop families with a 0% card rate (102; H2 only) |
| R7 | Drop equal-split responses |
| R8 | Race/ethnicity removed |
| R9 | Unweighted rank-sum test of the H1 difference (implicate 1) |

### Reading rules
- H1 and H2 are judged on the primary model.
- Exploratory results are reported as exploratory.
- Robustness checks that weaken the headline stay in the write-up.
- Nulls are reported with the estimate, 95% CI, and "did not resolve."

### Prediction
Does co-holding status improve out-of-sample prediction of the debt share beyond income, age, and balances? Nested feature sets, fit on each implicate and averaged.

## 7. Validation

| Measure | Fed note | Our build |
|---|---|---|
| Spend share | 22% | 22.3% |
| Save share | 47% | 47.3% |
| Debt share | 30% | 30.3% |
| Would spend none | ~47% | 46.3% |

Independently reproduced in Python from the Stata output.
