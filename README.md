# Cash in Hand, Debt on the Card

**Household Finance Lab · Project 3 · 2025 Survey of Consumer Finances**

Given an unexpected month of income, would you pay down your debt, or keep the cash?

Among U.S. families carrying a credit card balance, those who already held more than a month of income in cash said they would put about **12.5 percentage points less** of a windfall toward paying down debt than otherwise similar families (95% CI: 8.9 to 16.0 points).

**What it does not show:** what families actually do (the question is hypothetical), why co-holders answer as they do, or that holding cash *causes* anything. The survey asks about paying down debts of any kind, not credit cards specifically.

📖 [**Read the story**](docs/empirically-yours-03.md) (Empirically Yours №3) · 🔁 [**Reproduce it**](#reproduce-it) · 📎 [**Cite it**](CITATION.cff)

> **Research status:** observational analysis of cross-sectional survey data. Hypotheses and analysis plan were fixed before results were seen; every change since, including one post hoc check, is logged in [`ANALYTICAL-DECISIONS.md`](ANALYTICAL-DECISIONS.md). **Not peer reviewed.**

---

## Methodological lesson

**Know what kind of answer you are analyzing, and how many datasets you really have.** The outcome is what families *say they would do* with a windfall, not what they did, so every finding is about stated allocation. And the SCF releases five implicates (five completed versions of the imputed data), not five independent samples. Main estimates average across all five implicates and combine replicate-weight sampling variance with between-imputation variance, with the sample defined within each implicate. Selected exploratory diagnostics (clustering, the rank-sum check, the regression tree, permutation importance) use implicate 1 and are labeled as such. Treating the five implicates as separate observations would overstate the sample size; using one implicate alone would omit between-imputation uncertainty.

## What this study supports

- **H1, supported:** card borrowers who co-hold cash (liquid assets above one month of normal income) *say they would* allocate a smaller share of a windfall to paying down debt. The gap holds in all nine robustness checks, including different cash thresholds, a linear model, all three shares modeled together, and dropping families who usually pay in full.
- **H2, did not resolve:** the analysis did not resolve whether the card's interest rate is associated with the share families would put toward debt (95% CI: −0.22 to +0.19 points per percentage point of rate).
- **Prediction:** co-holder status improved out-of-sample prediction beyond income, age, and card balance, in every model and every imputation, but overall prediction is weak (best R² ≈ 0.11). Co-holding shifts the *average* answer. It adds some predictive information, but individual predictions remain imprecise.

## What changed along the way

- **One robustness model needed a fix after the plan was fixed.** The three shares were rescaled to sum to exactly 1 so the multinomial model could run (equal splits are stored as 33/33/33).
- **The cluster analysis was unstable with one random start**, so the final run used ten starts per solution. Even then, the statistic did not pick a best number of clusters; we report four for readability and say so.
- **Two Python runs did not match exactly.** Gradient boosting differed slightly across scikit-learn versions; linear and tree results were identical. Conclusions unchanged; versions recorded.
- **A pattern we checked and set aside.** A regression tree suggested the co-holder gap might depend on income. A post hoc check did not resolve whether it does: the estimate was unstable across the five implicates, the gap barely changed across income levels (−11.7 to −12.8 points), and the interaction did not improve prediction. Because the idea came from looking at the data, we tested no further subgroups.

## What's here

| File | What it is |
|---|---|
| [`DESIGN.md`](DESIGN.md) | The plan, fixed before analysis: question, hypotheses, variables, methods |
| [`ANALYTICAL-DECISIONS.md`](ANALYTICAL-DECISIONS.md) | Every choice and its alternative, all results, changes after the plan was fixed, Stata–Python reconciliation |
| [`CODEBOOK.md`](CODEBOOK.md) | Every variable: source, coding, special codes, reference categories |
| [`LITERATURE.md`](LITERATURE.md) | Who established what before us, the gap, and open questions for future research |
| [`data/README.md`](data/README.md) | Where to get the three Fed files, and the values the build checks |
| `code/` | Stata build and analysis; Python prediction |
| `output/` | Result tables |
| `tools/` | An automatic check, run on every update, for personal file paths, data files, and broken links |

## Reproduce it

**Data** (free, from the [Federal Reserve SCF page](https://www.federalreserve.gov/econres/scfindex.htm), 2025 survey, Stata format): the full public data set (`p25i6.dta`), the summary extract (`rscfp2025.dta`), and the replicate weight file (`p25_rw1.dta`). No survey data are redistributed here.

**Software:** Stata 19 (StataNow 19.5 used), with `fmlogit` from SSC. Python 3.10+: `pip install -r requirements.txt`.

**Run order:** put the three .dta files in `data/raw/`, then, from the repository folder:

```
do code/01_build.do         # merge, recode, define sample, validate   (~1 min)
do code/02_analyze.do       # all models, 999 replicate weights         (~20 min)
python code/03_predict.py   # out-of-sample prediction                 (~30 sec)
```

**How you know it worked:** `01_build.do` ends with `VALIDATION PASSED`, reproducing the Federal Reserve's published windfall shares (22.3% spend, 47.3% save, 30.3% debt). The build reports 4,360 families and 1,568 card revolvers in implicate 1. The primary marginal effect for co-holders is −0.1247.

## Authors

- **Lena Gan, PhD, CFP®, CIMA®**: research design, Stata inference, interpretation
- **Sara Kay** ([sarakay.me](https://sarakay.me)): prediction layer (Python), reproducibility

Analysis was assisted by Claude (Anthropic). All code was run, and all results verified, by the authors.

## Tell us we're wrong

Open an Issue or email householdfinancelab@gmail.com. Corrections, failed reproductions, and "you've mischaracterized my paper" messages are all welcome.

## Using this work

Code: MIT. Writing and documentation: CC BY 4.0. See [`LICENSE`](LICENSE). The SCF belongs to the Board of Governors of the Federal Reserve System.
