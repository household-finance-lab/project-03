# Project 3 — CODEBOOK

Every variable used in the analysis: where it comes from, how it is coded, and its reference category. Special codes verified against the 2025 SCF codebook (`codebk2025.txt`).

**Sources**
- **Main** = full public data set (`p25i6.dta`), "X" variables
- **Extract** = Fed summary extract (`rscfp2025.dta`), built by the Fed from the main data set
- **Built** = constructed in `code/01_build.do` or `code/02_analyze.do`

**Whose characteristics:** the reference person (or the family) throughout. The public file has already reversed respondent and spouse variables where needed (X8000); do not re-reverse.

---

## 1. Identifiers and survey design

| Variable | Source | Content | Notes |
|---|---|---|---|
| `yy1` | Main / Extract | Family ID | Same across the five implicates |
| `y1` | Main / Extract | Record ID (family × implicate) | Merge key |
| `implic` | Built | Implicate number, 1–5 | `y1 − 10 × yy1` (codebook formula). Never derive from row order. |
| `x42001` | Main | Main analysis weight | Used as `pweight` on each implicate |
| `wgt` | Extract | Summary-extract weight (= X42001 / 5) | Used in the validation step of `01_build.do` |
| `rw1`–`rw999` | Built | Replicate weights | `WT1B# × MM#` from `p25_rw1.dta`; one record per family, attached to all implicates. Not in the analysis CSV. |

## 2. Dependent variable

| Variable | Source | Coding |
|---|---|---|
| **`sh_debt`** | Extract `MPDEBT` (= X9377) | Share of a hypothetical one-month windfall the family says it would use to pay down debts (any debts), 0–1 |
| `sh_spend`, `sh_save` | Extract `MPSPEND`, `MPSAVE` (= X9375, X9376) | Companion shares, 0–1 |
| `s_spend`, `s_save`, `s_debt` | Built | Shares rescaled to sum to exactly 1. Used only in robustness model R2. |
| `anydebt` | Built | 1 if `MPDEBT` > 0 (two-part model, part 1) |

The three shares sum to 100, or to 99 for an equal split (stored as 33/33/33).

## 3. Sample

| Variable | Source | Coding |
|---|---|---|
| `revolver` | Built from X413 | 1 if a card balance is still owed after the last payment (X413 > 0) |
| `insample` | Built | 1 if `revolver` and normal income > 0. Defined within each implicate; non-sample families are never dropped from the file. |

## 4. Independent variables

| Hypothesis | Variable | Source | Coding | Reference |
|---|---|---|---|---|
| H1 | **`coholder`** | Extract `LIQ`, `NORMINC` | 1 if liquid assets > `NORMINC` / 12 | Non-co-holder |
| H2 | **`cardrate`** | Main X7132 | Rate on the card with the largest balance, in percent. Stored as percent × 100 (2140 → 21.4). **−1 = no interest → 0.** 0 = not applicable. | Continuous |
| H3 | **`util3`** | Built from X413 ÷ X414 | < 0.50, 0.50–0.90, > 0.90 (Gross & Souleles cut points). **X414 = −1 (no limit) → missing**, utilization only. | < 0.50 |
| H3 | `util` | Built | Continuous utilization | — |

`LIQ` = checking, savings, money market, and call accounts (the Fed's summary-extract definition).

## 5. Control variables (primary model)

| Variable | Source | Coding | Reference |
|---|---|---|---|
| `agecl` | Extract | < 35, 35–44, 45–54, 55–64, 65–74, 75+ | < 35 |
| `marital3` | Extract `MARRIED`, `HHSEX` | Married/partnered; single female; single male | Married/partnered |
| `dep_cat` | Extract `KIDS` | None, 1–2, 3+ | None |
| `education` | Extract `EDUC` (X5931 codes) | HS or less (−1 to 8); some college/associate (9–11); bachelor's (12); graduate (13–14). **−1 = less than 1st grade**, not missing. Public file merges doctorate into 14. | HS or less |
| `employment` | Main X4100 | Working (11–17, 20, 22, 24); unemployed (21, 23, 30); retired (50); not in labor force (52+) | Working |
| `racecl4` | Extract | White non-Hispanic; Black non-Hispanic; Hispanic; other. Fed-constructed for the revised 2025 question. | White non-Hispanic |
| `owner` | Extract `HOUSECL` | 1 if homeowner | Non-owner |
| `lnnorminc` | Extract `NORMINC` | Log of normal income | Continuous |
| `ihs_networth` | Extract `NETWORTH` | Inverse hyperbolic sine (handles negative net worth) | Continuous |
| `lncardbal` | Main X413 | Log of card balance owed | Continuous |
| `hprim_mort`, `hveh_inst`, `hedn_inst` | Extract | 1 if the family has a primary-residence mortgage, vehicle loan, student loan | Doesn't hold |

## 6. Exploratory and robustness variables

| Variable | Source | Coding |
|---|---|---|
| `credconstr` | Extract `TURNDOWN`, `FEARDENIAL` | 1 if denied credit or did not apply for fear of denial (past 5 years) |
| `knowl10` | Extract `KNOWL` (X7556) | Self-rated financial knowledge, 0–10. **−1 = "not at all" → 0.** |
| `finlit3` | Extract `FINLIT` | 1 if all three literacy questions correct |
| `atconstraint` | Extract `WSAVED` | 1 if spending was at or above income last year (WSAVED = 1 or 2) |
| `incuncertain` | Main X7366 | 1 if the family does not have a good idea of next year's income (5 = no, 1 = yes) |
| `hbnpl`, `late` | Extract | 1 if a buy-now-pay-later balance; 1 if any payment late in the past year |
| `liqmonths` | Built | Liquid assets in months of normal income |
| `lnliqm` | Built | log(1 + `liqmonths`), robustness R5 |
| `coh05`, `coh1`, `coh2`, `coh3` | Built | Co-holder at ½, 1, 2, 3 months of income, robustness R4 |
| `inc4` | Built | Normal-income quartiles (weighted cut points, implicate 1), descriptive A2 |

## 7. Descriptive only (never in a model)

| Variable | Source | Coding |
|---|---|---|
| `x432` | Main X432 | Pays the full card balance: 1 almost always, 3 sometimes, 5 hardly ever |
| `equalsplit` | Built | 1 if 33/33/33 |
| `roundresp` | Built | 1 if all three shares are multiples of 10 |
| `nwcat` | Extract | Net worth group |
| `k3`–`k6` | Built (`02_analyze.do`) | k-means cluster membership, 3–6 clusters, implicate-1 sample only |

## 8. Special codes: summary

| Variable | Code | Means | Handling |
|---|---|---|---|
| X7132 card rate | −1 | No interest | → 0 |
| X7132 card rate | values | Percent × 100 | ÷ 100 |
| X414 credit limit | −1 | No limit | → missing for utilization |
| X413, X414, X7132 | 0 | Not applicable (no card) | Outside sample |
| KNOWL / X7556 | −1 | Not at all knowledgeable | → 0 |
| EDUC / X5931 | −1 | Less than 1st grade | Lowest education group |
| X7366 | 1 / 5 | Yes / No | 5 → `incuncertain` = 1 |
| Windfall shares | 33/33/33 | Equal split (sum 99) | Accepted; rescaled only for R2 |

**Rule:** never assume a negative value or zero means missing in the SCF. Check the codebook. The Fed has already imputed true missing values (five implicates).

## 9. Notes for Python and R users (`analytic_dataset.csv`)

- **Five rows per family**, one per implicate. Fit on each implicate separately and combine; never pool.
- **Categories are exported as text labels** ("Co-holder", "35-44", "Bachelor's").
- **One label is the word "None"** (`dep_cat`). Python's pandas reads it as missing by default; load with `pd.read_csv(..., keep_default_na=False, na_values=[""])`. R's `read.csv` and `readr::read_csv` keep it as text by default.
- Replicate weights are not included. For design-based standard errors, use Stata and the full build.
