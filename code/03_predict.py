"""
Household Finance Lab — Project 3: SCF 2025 windfall allocation
03_predict.py — prediction | Sara Kay

QUESTION (see DESIGN.md):
  Does knowing whether a family is a co-holder (liquid assets > one month of
  normal income) improve OUT-OF-SAMPLE prediction of the share of a windfall
  it would put toward debt, beyond income, age, and card balance?

INPUT:   data/derived/analytic_dataset.csv  (written by code/02_analyze.do)
OUTPUT:  output/python_results.csv           all models x feature sets x implicates
         output/python_summary.csv           averaged over implicates (the table to report)
         output/python_importance.csv        permutation importance, full model

DESIGN:
  - Sample: card revolvers (insample == 1), fit separately on each of the
    5 implicates, results averaged (each family appears once per implicate).
  - Nested feature sets F0 -> F1 -> F2 -> F3 (F1 adds ONLY co-holder to F0).
  - Models: linear regression (benchmark), regression tree (CART, depth 4,
    readable), gradient boosting (flexible).
  - 5-fold cross-validation, weighted by the SCF main weight (x42001).
  - Metric: out-of-sample R^2 and RMSE (debt share on a 0-1 scale).

RUN TIME: about 25-40 seconds on a laptop (tested on the real file: 23 s).
          Set QUICK = True for a ~5-second check that everything runs.

REQUIRES: Python 3.10+, pandas, numpy, scikit-learn
          pip install pandas numpy scikit-learn
          Results in output/ used Python 3.15.0, scikit-learn 1.9.1,
          pandas 3.1.0, numpy 2.5.4. Linear and tree results are identical
          across versions; gradient-boosting R^2 can differ by about +/-0.01.
"""

import os
os.environ.setdefault("OMP_NUM_THREADS", "1")   # must come before sklearn import:
                                                # prevents gradient boosting stalling
                                                # on small data
import time
import numpy as np
import pandas as pd
from sklearn.model_selection import KFold
from sklearn.linear_model import LinearRegression
from sklearn.tree import DecisionTreeRegressor, export_text
from sklearn.ensemble import HistGradientBoostingRegressor
from sklearn.inspection import permutation_importance

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
DATA = "data/derived/analytic_dataset.csv"   # run from the project folder
QUICK = False                    # True = 1 implicate, 2 folds (fast check)
SEED = 20261022
N_FOLDS = 2 if QUICK else 5
IMPLICATES = [1] if QUICK else [1, 2, 3, 4, 5]

start = time.time()

# ---------------------------------------------------------------------------
# 1. Load. IMPORTANT: Stata exported category LABELS as text, and one label
#    is the word "None" (no children). By default pandas reads "None" as
#    missing, so default missing-value parsing is switched off.
# ---------------------------------------------------------------------------
df = pd.read_csv(DATA, keep_default_na=False, na_values=[""])
df = df[df["insample"] == 1].copy()

# Co-holder: text label -> 0/1
df["coholder"] = (df["coholder"] == "Co-holder").astype(int)

y_col = "sh_debt"                 # share of windfall to pay down debt (0-1)
w_col = "x42001"                  # SCF main weight

# ---------------------------------------------------------------------------
# 2. Feature sets (nested). Categorical variables become 0/1 dummies.
# ---------------------------------------------------------------------------
CATEG = ["agecl", "marital3", "dep_cat", "education", "employment", "racecl4"]

F0 = ["lnnorminc", "agecl", "lncardbal"]                       # income, age, balance
F1 = F0 + ["coholder"]                                          # + co-holder ONLY
F2 = F1 + ["cardrate", "marital3", "dep_cat", "education", "employment",
           "racecl4", "owner", "ihs_networth",
           "hprim_mort", "hveh_inst", "hedn_inst"]              # all controls
F3 = F2 + ["credconstr", "knowl10", "finlit3", "atconstraint",
           "incuncertain", "hbnpl", "late"]                     # exploratory extras
FEATURE_SETS = {"F0_base": F0, "F1_plus_coholder": F1,
                "F2_full": F2, "F3_full_plus_extra": F3}


def design_matrix(data, cols):
    """Numeric matrix with dummies for categorical columns (first level dropped)."""
    cats = [c for c in cols if c in CATEG]
    X = pd.get_dummies(data[cols], columns=cats, drop_first=True, dtype=float)
    return X.astype(float)


def models():
    return {
        "linear": LinearRegression(),
        "tree_cart": DecisionTreeRegressor(max_depth=4, min_samples_leaf=40,
                                           random_state=SEED),
        "gboost": HistGradientBoostingRegressor(max_iter=200, learning_rate=0.05,
                                                max_leaf_nodes=15,
                                                min_samples_leaf=30,
                                                random_state=SEED),
    }


def weighted_r2_rmse(y, yhat, w):
    ybar = np.average(y, weights=w)
    sse = np.sum(w * (y - yhat) ** 2)
    sst = np.sum(w * (y - ybar) ** 2)
    return 1 - sse / sst, np.sqrt(sse / np.sum(w))


# ---------------------------------------------------------------------------
# 3. Cross-validated fit: each implicate x feature set x model
# ---------------------------------------------------------------------------
rows = []
for m in IMPLICATES:
    dm = df[df["implic"] == m].reset_index(drop=True)
    y = dm[y_col].to_numpy()
    w = dm[w_col].to_numpy()
    w = w / w.mean()                                   # rescale (does not change fit)
    kf = KFold(n_splits=N_FOLDS, shuffle=True, random_state=SEED + m)
    for fs_name, cols in FEATURE_SETS.items():
        X = design_matrix(dm, cols).to_numpy()
        for mod_name, model in models().items():
            pred = np.zeros(len(y))
            for train, test in kf.split(X):
                model.fit(X[train], y[train], sample_weight=w[train])
                pred[test] = model.predict(X[test])
            pred = np.clip(pred, 0, 1)                 # shares live in [0, 1]
            r2, rmse = weighted_r2_rmse(y, pred, w)
            rows.append({"implicate": m, "feature_set": fs_name, "model": mod_name,
                         "n_families": len(y), "cv_r2": r2, "cv_rmse": rmse})
    print(f"Implicate {m} done ({time.time() - start:.0f} s)")

res = pd.DataFrame(rows)
res.to_csv("output/python_results.csv", index=False)

# ---------------------------------------------------------------------------
# 4. Summary: average over implicates; gain from adding co-holder (F1 - F0)
# ---------------------------------------------------------------------------
summ = (res.groupby(["model", "feature_set"])
           .agg(cv_r2=("cv_r2", "mean"), cv_r2_min=("cv_r2", "min"),
                cv_r2_max=("cv_r2", "max"), cv_rmse=("cv_rmse", "mean"))
           .reset_index())
summ.to_csv("output/python_summary.csv", index=False)

wide = res.pivot_table(index=["implicate", "model"], columns="feature_set",
                       values="cv_r2").reset_index()
wide["gain_coholder"] = wide["F1_plus_coholder"] - wide["F0_base"]
gain = (wide.groupby("model")["gain_coholder"]
            .agg(["mean", "min", "max"]).round(4))

pd.set_option("display.width", 120)
print("\n=== Out-of-sample R^2 (mean over implicates; min-max in brackets) ===")
for _, r in summ.iterrows():
    print(f"{r['model']:10s} {r['feature_set']:20s} R2 = {r['cv_r2']:.3f} "
          f"[{r['cv_r2_min']:.3f}, {r['cv_r2_max']:.3f}]  RMSE = {r['cv_rmse']:.3f}")
print("\n=== Gain in out-of-sample R^2 from adding co-holder (F1 minus F0) ===")
print(gain)

# ---------------------------------------------------------------------------
# 5. Which variables matter? Permutation importance, gradient boosting,
#    full model (F2), implicate 1, on a held-out 20% of families.
# ---------------------------------------------------------------------------
d1 = df[df["implic"] == 1].reset_index(drop=True)
X1 = design_matrix(d1, F2)
y1 = d1[y_col].to_numpy()
w1 = (d1[w_col] / d1[w_col].mean()).to_numpy()
rng = np.random.default_rng(SEED)
test_idx = rng.random(len(y1)) < 0.2
gb = models()["gboost"].fit(X1[~test_idx], y1[~test_idx], sample_weight=w1[~test_idx])
pi = permutation_importance(gb, X1[test_idx], y1[test_idx],
                            sample_weight=w1[test_idx],
                            n_repeats=5 if QUICK else 20, random_state=SEED)
imp = (pd.DataFrame({"feature": X1.columns, "importance": pi.importances_mean,
                     "sd": pi.importances_std})
         .sort_values("importance", ascending=False))
imp.to_csv("output/python_importance.csv", index=False)
print("\n=== Top 10 features (permutation importance, gradient boosting, F2) ===")
print(imp.head(10).round(4).to_string(index=False))

# ---------------------------------------------------------------------------
# 6. A readable tree (CART, F1, implicate 1) for the write-up
# ---------------------------------------------------------------------------
X1b = design_matrix(d1, F1)
tree = DecisionTreeRegressor(max_depth=3, min_samples_leaf=60, random_state=SEED)
tree.fit(X1b, y1, sample_weight=w1)
print("\n=== Regression tree (F1, depth 3): predicted debt share at each leaf ===")
print(export_text(tree, feature_names=list(X1b.columns), decimals=2))

print(f"\nTotal run time: {time.time() - start:.0f} seconds")
