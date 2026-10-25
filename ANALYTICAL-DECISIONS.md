# Project 3 — ANALYTICAL DECISIONS

**Project:** Cash in Hand, Debt on the Card (2025 SCF windfall allocation)
**Analysts:** Lena Gan (inference, Stata 19.5) · Sara Kay (prediction, Python)

---

## 1. Sample flow

| Step | Families (implicate 1) |
|---|---|
| All families, 2025 SCF public file | 4,360 |
| Card revolvers: balance owed after last payment (X413 > 0) | 1,568 |
| Excluded: zero or negative normal income | 0 |
| **Analytic sample** | **1,568** |

Because card balances, liquid assets, and income are partly imputed, sample membership varies slightly across implicates: 1,568 / 1,571 / 1,566 / 1,572 / 1,568 families (34 families change membership; 114 change co-holder status). Sample restrictions are applied within each implicate; non-sample families are never dropped from the file.

## 2. Data and build decisions

| Decision | Chosen | Alternative not chosen | Why |
|---|---|---|---|
| Whose characteristics | Reference person throughout | Respondent, by re-reversing X8000 | The public file already reverses respondent/spouse where needed, and the summary extract describes the reference person. Re-reversing would mix people across variables. |
| Source of covariates | Fed summary extract; employment from X4100 | Building all from the main data set | Matches the Fed's published definitions and avoids re-coding. The extract's labor-force variable is binary, so the 4-category employment variable is built from X4100. Check: extract age equals X14 for every record. |
| Missing data | Use the Fed's five implicates; combine with the Fed's formula | Re-imputing (e.g., MICE) | Missing values are already multiply imputed by the Fed. Re-imputing would be an error. |
| Variance | Point estimates averaged over 5 implicates; sampling variance from 999 replicate weights (× multiplicity factors) on implicate 1; total = U + (6/5)B | Implicate 1 only; unweighted SEs | The SCF codebook's method. Implicate-1-only analysis understates uncertainty. |
| Income for the co-holder threshold | Normal income (NORMINC) | Total income (X5729) | The windfall question asks about one month of *normal* income. |
| Liquid assets | LIQ (checking, savings, money market, call accounts) | The Fed note's broader definition (adds CDs, funds, stocks, bonds) | Matches Gross & Souleles (2002), whose puzzle this tests. |
| Co-holder threshold | Liquid assets > one month of normal income | Other cutoffs | Same as Gross & Souleles (2002) and the same size as the windfall. Other cutoffs tested in R4. |
| Revolver definition | Balance owed after last payment (X413 > 0) | Payment habit (X432) | Measures carrying a balance at interview. 28% of revolvers say they "almost always" pay in full; R3 drops them. |
| Card interest rate (X7132) | Stored as percent × 100, divided by 100; −1 ("no interest") → 0 | Treating −1 as missing | −1 is a valid answer, not a missing value. 102 revolvers (6.5%) report 0%; R6 drops them. |
| Credit limit (X414) | −1 ("no limit") → missing for utilization only | Dropping these families | Affects 3 families, utilization (H3) only. |
| Self-rated knowledge | −1 → 0 | Treating −1 as missing | −1 is the code for "not at all knowledgeable." |
| Education | 4 levels from EDUC; −1 ("less than 1st grade") → lowest level | Summary-extract EDCL | Lab convention (separates bachelor's and graduate). |
| Equal splits | Shares summing to 99 (33/33/33) accepted | Rescaling everywhere | The Fed stores equal splits as 33/33/33 (FEDS Note fn. 6). Rescaled only where a model requires exactly 1 (R2). |
| Card balance as a control | Included (log) | Excluded | Families with larger balances have more to pay down; omitting it could make co-holding stand in for balance size. |
| Income and wealth in the primary model | Included (log normal income; IHS net worth) | Robustness only | Co-holders have more income and education (Section 4A): the most likely "headline-killer," so tested in the main model. |

## 3. Validation

| Measure | Fed (Aladangady et al., 2026) | Our build |
|---|---|---|
| Spend share | 22% | 22.3% |
| Save share | 47% | 47.3% |
| Debt share | 30% | 30.3% |
| Would spend none | about 47% | 46.3% |

Reproduced independently in Python from the Stata output; every count and category matched.

## 4. Results summary (final run, 999 replicate weights)

### A. Descriptive
- Revolvers would allocate 19.6% to spending, 35.4% to saving, **44.9% to debt** (all families: 30.3% to debt).
- Co-holding rises with income (about 27% to 49% across quartiles), education, and age 75+, and is lower among Black non-Hispanic families. These are descriptive patterns; the data do not explain them.
- 4.7% of revolvers chose an equal split; 74.5% gave three round-number (multiple of 10) shares.

### B. Confirmatory
| | Estimate | 95% CI | Verdict |
|---|---|---|---|
| Debt share, non-co-holders | 50.8% | 48.8 to 52.8 | — |
| Debt share, co-holders | 36.2% | 33.4 to 38.9 | — |
| H1, unadjusted gap | −14.6 points | −18.2 to −11.0 | — |
| **H1, adjusted (fractional logit, AME)** | **−12.5 points** | **−16.0 to −8.9** | **Supported** |
| **H2, card rate (per percentage point)** | −0.02 points | −0.22 to +0.19 | **Did not resolve** |

### C. Exploratory
- **H3, utilization:** did not resolve after adjustment (joint p = 0.37); the unadjusted difference is largely accounted for by card balance.
- **Two-part model:** co-holding is associated with lower odds of allocating anything to debt and a smaller share among those who allocate something (1,222 families).
- **Additional covariates:** co-holder coefficient −0.54 → −0.45, still clearly negative. Spending at or above income, and a late payment, are associated with a larger debt share.
- **Clusters:** see Section 5.

### D. Robustness: H1 holds in all nine checks
| Check | Co-holder gap (points) | 95% CI |
|---|---|---|
| R1 Linear regression | −12.5 | −16.1 to −8.9 |
| R2 Fractional multinomial (3 shares) | Shift from debt toward saving | p < 0.001 |
| R3 Habitual revolvers only (1,124) | −11.0 | −15.1 to −7.0 |
| R4 Cutoff ½ / 1 / 2 / 3 months | −11.8 / −12.5 / −10.7 / −8.8 | all exclude zero |
| R5 Continuous log liquid months | −7.9 per log unit | −10.8 to −5.0 |
| R6 Excluding 0% rates (1,466) | −11.4 | −14.9 to −7.9 |
| R7 Excluding equal splits (1,489) | −12.7 | −16.4 to −9.0 |
| R8 Race/ethnicity removed | −12.1 | −15.7 to −8.6 |
| R9 Rank-sum, unweighted | z = 7.2 | p < 0.001 |

H2 did not resolve in any check.

## 5. Changes after the plan was fixed

| Change | Reason | Effect on results |
|---|---|---|
| **R2: shares rescaled to sum to exactly 1** | Fractional multinomial logit failed to converge with equal splits stored as 99 | None on H1/H2 conclusions |
| **R2: replicate weights passed to fmlogit as pweights** | fmlogit does not accept the importance weights `svy bootstrap` passes | Coefficients per replicate identical either way |
| **C4: k-means run from 10 starts per solution, best kept** | A single random start gave unstable results | Calinski now rises steadily (1,900 / 2,745 / 2,934 / 3,350) |
| **C4: number of clusters chosen for interpretability (4)** | Calinski did not select a best number | 4-cluster solution reported; 5 and 6 in appendix. Stated plainly as a judgment call. |

The four allocation types (exploratory): debt payers (439 families; 92% to debt; 27% co-holders), balanced (574; 17/41/41), spenders (268; 66% spend), savers (287; 91% save; 59% co-holders).

## 6. Reconciling inference and prediction

**Where they agree**

| Finding | Stata | Python |
|---|---|---|
| Co-holding matters | −12.5 points (adjusted) | Adding co-holder raises out-of-sample R² in all 3 models and all 5 implicates (gain +0.009 to +0.048) |
| Card balance matters most | Strongest control (z ≈ 10) | Top permutation importance; first tree split |
| Card rate does not | H2 did not resolve | Not among top predictors |
| Net worth, vehicle loans, age 75+ | Significant | Among the leading predictors |
| Budget strain, late payment | Significant (C3, exploratory) | Adding exploratory variables helps gradient boosting most |

In the regression tree, co-holding is the second split on both branches, after card balance.

**Where they differ, and why this is not a contradiction**
1. **Prediction is weak overall** (best out-of-sample R² ≈ 0.11, linear regression). Co-holding shifts the *average* stated allocation reliably, but most of what drives an individual family's answer is not captured by the balance sheet. Answers are widely spread and mostly rounded, consistent with the heterogeneity the Fed note reports.
2. **Linear regression outperforms the flexible models.** No strong hidden nonlinearities or interactions; supports the fractional logit as the primary model.
3. **Adding all controls does not improve prediction** (linear R² 0.106 → 0.101). In inference the controls rule out confounding; in prediction they mostly add noise. Same data, different questions.

**Cautions carried into the write-up**
- Permutation importance comes from one implicate and about 310 held-out families; ranks 2–4 change between runs. Report only that card balance ranks first and co-holder is in the leading group.
- Race/ethnicity is associated with the stated debt share in both layers. It is reported as a pattern, without explanation; R8 shows H1 unchanged without it.

**One-sentence reconciliation:** inference and prediction agree that co-holding is associated with a lower stated debt share and that the card rate is not; prediction adds that individual stated allocations are largely unpredictable from the balance sheet, so the co-holder gap is a reliable shift in the average rather than a rule for sorting individual families.

## 7. Reproducibility

| Check | Result |
|---|---|
| Build reproduced in Python from Stata output | All counts, categories, and validation figures matched exactly |
| Final Stata run time | 1,211 seconds (about 20 minutes), StataNow 19.5 |
| Python, second environment | Linear and tree results identical; gradient-boosting R² differs by up to ±0.013, likely due to scikit-learn version (1.8.0 vs 1.9.1). Conclusions unchanged. |
| Python environment | Python 3.15.0, scikit-learn 1.9.1, pandas 3.1.0, numpy 2.5.4; run time about 30 seconds |

## 8. Post hoc exploratory check: co-holding × income

**Motivation:** the regression tree suggested the co-holder gap might depend on income among families with larger card balances. Because this idea came from inspecting results, it was tested as a post hoc exploratory check, not a hypothesis.

**Method:** fractional logit adding co-holder × log normal income to the primary model, fit on each implicate with the main weight; marginal effects of co-holding at the 25th, 50th, and 75th income percentiles; cross-validated comparison with and without the interaction .

**Results:**
- Interaction coefficients by implicate: −0.03, +0.02, −0.05, −0.08, −0.17 (mean −0.06). The between-implicate variance alone implies a standard error of at least about 0.08, so |z| ≤ 0.8 under the Fed's combining formula, whatever the replicate-weight variance.
- Co-holder gap at the 25th / 50th / 75th income percentile: −11.7 / −12.4 / −12.8 points.
- Adding the interaction lowered cross-validated R² in all five implicates (mean −0.0023).

**Conclusion:** the analysis did not resolve whether the co-holder gap varies with income; the estimate was too unstable across implicates to support either direction, and the interaction did not improve prediction. No further subgroup or three-way interactions were tested, to avoid searching the data for a pattern. Limitations: income percentiles were unweighted, and GLM standard errors were not design-based; neither affects the conclusion.

## 9. Limitations

- **Stated intentions:** the outcome is what families say they would do with a hypothetical windfall, not observed behavior.
- **Any debt, not card debt:** the question asks about paying down debts of any kind.
- **Cross-sectional and observational:** associations only; no causal claims.
- **Card rate:** the rate on new balances for the largest-balance card; promotional rates are not flagged in the public file.
- **Threshold choice:** one month of income follows Gross & Souleles (2002); results hold across ½ to 3 months (R4), with a smaller gap at higher cutoffs.
- **Response rounding:** about three in four answers are multiples of 10; dropping equal splits does not change H1 (R7).
- **Prediction:** low out-of-sample R²; most variation in stated allocations is unexplained.
