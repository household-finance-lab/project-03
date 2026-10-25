/*==============================================================================
  Household Finance Lab — Project 3: SCF 2025 windfall allocation
  01_build.do — merge, recode, construct, define sample, validate
  Lena Gan | StataNow 19.5 | Variables documented in CODEBOOK.md

  Inputs (data/raw), merged in this order:
     1. p25i6.dta      Full public data set (main survey data)
     2. rscfp2025.dta  Summary extract
     3. p25_rw1.dta    Replicate weights
  Output: data/derived/p3_analytic.dta  (all 5 implicates; 21,800 records)

  Rules: keep all five implicates; implicate from Y1/YY1, never row order;
         reference person throughout (no X8000 re-reversal);
         special codes per codebk2025.txt.
==============================================================================*/

clear all
set more off
version 19.5

*------------------------------------------------------------------------------
* 0. Paths
*------------------------------------------------------------------------------
* Paths: run from the project folder (in Stata: File > Change Working Directory).
* Put the three Fed .dta files in data/raw before running 01_build.do.
global raw     "data/raw"
global derived "data/derived"
global logs    "logs"
global out     "output"
foreach d in data data/derived logs output {
    capture mkdir "`d'"
}
capture log close
log using "$logs/01_build.log", replace text

*------------------------------------------------------------------------------
* 1. Full public data set (p25i6): only variables not in the summary extract
*------------------------------------------------------------------------------
use y1 yy1 x14 x42001 x413 x414 x7132 x432 x7366 x4100 using "$raw/p25i6.dta", clear
assert _N == 21800                        // 4,360 families x 5 implicates

*------------------------------------------------------------------------------
* 2. Merge summary extract (rscfp2025): one record per implicate
*------------------------------------------------------------------------------
merge 1:1 yy1 y1 using "$raw/rscfp2025.dta"
assert _merge == 3
drop _merge

* Check: summary extract age matches main dataset age (X14)
assert age == x14

*------------------------------------------------------------------------------
* 3. Merge replicate weights (p25_rw1): one record per family, all implicates
*------------------------------------------------------------------------------
preserve
    use "$raw/p25_rw1.dta", clear
    rename *, lower
    keep yy1 wt1b* mm*
    isid yy1                               // one record per family
    tempfile rw
    save `rw'
restore
merge m:1 yy1 using `rw'
assert _merge == 3
drop _merge

* Implicate number (codebook formula)
gen implic = y1 - 10*yy1
assert inrange(implic, 1, 5)
label var implic "Implicate (1-5)"

* Replicate weights x multiplicity factors (codebook)
forvalues r = 1/999 {
    quietly gen double rw`r' = wt1b`r' * mm`r'
}
drop wt1b* mm*

*==============================================================================
* 4. DEPENDENT VARIABLE
*==============================================================================
gen double sh_debt  = mpdebt/100
gen double sh_spend = mpspend/100
gen double sh_save  = mpsave/100
label var sh_debt  "DV: share of windfall to pay down debt (0-1)"
label var sh_spend "Share of windfall spent (0-1)"
label var sh_save  "Share of windfall saved (0-1)"

* Shares sum to 99 (equal split entered 33/33/33) or 100 (Fed FEDS Note fn. 6)
assert inlist(round(mpspend + mpsave + mpdebt), 99, 100)

*==============================================================================
* 5. SAMPLE
*==============================================================================
gen revolver = (x413 > 0)
label var revolver "Card balance owed after last payment (X413>0)"
gen insample = revolver & norminc > 0
label var insample "Analytic sample: revolver with positive normal income"

*==============================================================================
* 6. INDEPENDENT VARIABLES
*==============================================================================
* H1 — Co-holder: liquid assets > one month of normal income
gen coholder = (liq > norminc/12) if norminc > 0
label define coh_lbl 0 "Non-co-holder" 1 "Co-holder"
label values coholder coh_lbl
label var coholder "H1: liquid assets > 1 month normal income"

* H2 — Card interest rate (X7132 stored as percent*100; -1 = no interest)
gen double cardrate = .
replace cardrate = 0          if x7132 == -1
replace cardrate = x7132/100  if x7132 > 0
label var cardrate "H2: rate on largest-balance card (%)"

* H3 — Utilization groups (Gross & Souleles cut points); X414 -1 = no limit
gen double util = x413/x414 if revolver & x414 > 0
gen util3 = .
replace util3 = 1 if util <  0.50
replace util3 = 2 if util >= 0.50 & util <= 0.90
replace util3 = 3 if util >  0.90 & !missing(util)
label define util_lbl 1 "<0.50" 2 "0.50-0.90" 3 ">0.90"
label values util3 util_lbl
label var util3 "H3: card utilization group (exploratory)"

*==============================================================================
* 7. CONTROL VARIABLES (primary model) — reference category = first level
*==============================================================================
* Age: agecl as-is (1 <35, 2 35-44, 3 45-54, 4 55-64, 5 65-74, 6 75+)
label define age_lbl 1 "<35" 2 "35-44" 3 "45-54" 4 "55-64" 5 "65-74" 6 "75+"
label values agecl age_lbl

* Marital status x sex
gen marital3 = .
replace marital3 = 1 if married == 1
replace marital3 = 2 if married == 2 & hhsex == 2
replace marital3 = 3 if married == 2 & hhsex == 1
label define mar_lbl 1 "Married/partnered" 2 "Single female" 3 "Single male"
label values marital3 mar_lbl

* Children
gen dep_cat = cond(kids == 0, 0, cond(kids <= 2, 1, 2))
label define dep_lbl 0 "None" 1 "1-2" 2 "3+"
label values dep_cat dep_lbl

* Education (EDUC uses X5931 codes; -1 = less than 1st grade)
gen education = .
replace education = 1 if inrange(educ, -1, 8)
replace education = 2 if inrange(educ, 9, 11)
replace education = 3 if educ == 12
replace education = 4 if inlist(educ, 13, 14)
label define edu_lbl 1 "HS or less" 2 "Some college/assoc." 3 "Bachelor's" 4 "Graduate"
label values education edu_lbl

* Employment (X4100 recode, reference person)
gen employment = .
replace employment = 1 if inrange(x4100, 11, 17) | inlist(x4100, 20, 22, 24)
replace employment = 2 if inlist(x4100, 21, 23, 30)
replace employment = 3 if x4100 == 50
replace employment = 4 if x4100 >= 52 & !missing(x4100)
label define emp_lbl 1 "Working" 2 "Unemployed" 3 "Retired" 4 "Not in labor force"
label values employment emp_lbl

* Race/ethnicity: racecl4 as-is
label define race_lbl 1 "White non-Hispanic" 2 "Black non-Hispanic" 3 "Hispanic" 4 "Other"
label values racecl4 race_lbl

* Homeowner
gen owner = (housecl == 1)
label var owner "Homeowner"

* Income, net worth, card balance
gen double lnnorminc    = ln(norminc) if norminc > 0
gen double ihs_networth = asinh(networth)
gen double lncardbal    = ln(x413) if x413 > 0
label var lnnorminc    "Log normal income"
label var ihs_networth "Net worth (inverse hyperbolic sine)"
label var lncardbal    "Log card balance owed"

* Other debts: hprim_mort, hveh_inst, hedn_inst (0/1, summary extract)

*==============================================================================
* 8. EXPLORATORY / ROBUSTNESS VARIABLES
*==============================================================================
gen credconstr   = (turndown == 1 | feardenial == 1)
gen knowl10      = cond(knowl == -1, 0, knowl)          // -1 = "not at all" = 0
gen finlit3      = (finlit == 3)
gen atconstraint = inlist(wsaved, 1, 2)                 // spending >= income
gen incuncertain = (x7366 == 5) if inlist(x7366, 1, 5)  // 1 yes, 5 no
gen double liqmonths = liq/(norminc/12) if norminc > 0
label var credconstr   "Denied credit or feared denial"
label var knowl10      "Self-rated financial knowledge (0-10)"
label var finlit3      "All 3 literacy questions correct"
label var atconstraint "Spending at or above income last year"
label var incuncertain "No good idea of next year's income"
label var liqmonths    "Liquid assets in months of normal income"
* hbnpl, late: 0/1 as-is from summary extract

*==============================================================================
* 9. DESCRIPTIVE ONLY
*==============================================================================
gen equalsplit = (mpspend == 33 & mpsave == 33 & mpdebt == 33)
gen roundresp  = (mod(mpspend,10)==0 & mod(mpsave,10)==0 & mod(mpdebt,10)==0)
label var equalsplit "Equal split (33/33/33)"
label var roundresp  "All three shares multiples of 10"
* x432 (payment habit) and nwcat kept as-is

*==============================================================================
* 10. CHECKS (implicate 1 = unique families)
*==============================================================================
assert !missing(education)
assert !missing(employment) if insample

count if implic == 1
count if implic == 1 & revolver
count if implic == 1 & revolver & norminc <= 0      // excluded
count if implic == 1 & insample

misstable summarize sh_debt coholder cardrate util3 lnnorminc ihs_networth ///
    lncardbal incuncertain if insample & implic == 1

foreach v in coholder util3 agecl marital3 dep_cat education employment ///
             racecl4 owner hprim_mort hveh_inst hedn_inst ///
             credconstr finlit3 atconstraint incuncertain hbnpl late ///
             equalsplit roundresp x432 {
    tab `v' if insample & implic == 1, missing
}
summarize cardrate lnnorminc ihs_networth lncardbal knowl10 liqmonths ///
    if insample & implic == 1

*==============================================================================
* 11. VALIDATION: reproduce the Fed's published figures. STOP if off.
*     Target: Aladangady et al. (2026), FEDS Notes. Fed used internal data;
*     public-file values should be within about 1 point.
*==============================================================================
foreach v in mpspend mpsave mpdebt {
    local tot = 0
    forvalues i = 1/5 {
        quietly summarize `v' [aw=wgt] if implic==`i'
        local tot = `tot' + r(mean)
    }
    local m_`v' = `tot'/5
    display "`v' (average over implicates) = " %5.1f `m_`v''
}
assert abs(`m_mpspend' - 22) <= 1        // Fed: 22% spend
assert abs(`m_mpsave'  - 47) <= 1        // Fed: 47% save
assert abs(`m_mpdebt'  - 30) <= 1        // Fed: 30% pay down debt

tempvar zerospend
gen `zerospend' = (mpspend == 0)
local tot = 0
forvalues i = 1/5 {
    quietly summarize `zerospend' [aw=wgt] if implic==`i'
    local tot = `tot' + r(mean)
}
display "Share spending none = " %5.3f `tot'/5
assert abs(`tot'/5 - 0.47) <= 0.02       // Fed: about 47% spend none
display "VALIDATION PASSED"

*==============================================================================
* 12. SAVE (analysis variables only)
*==============================================================================
keep y1 yy1 implic x42001 wgt rw1-rw999 insample revolver ///
     sh_debt sh_spend sh_save mpdebt mpspend mpsave ///
     coholder cardrate util util3 ///
     agecl marital3 dep_cat education employment racecl4 owner ///
     lnnorminc ihs_networth lncardbal hprim_mort hveh_inst hedn_inst ///
     credconstr knowl10 finlit3 atconstraint incuncertain hbnpl late liqmonths ///
     equalsplit roundresp x432 nwcat norminc liq networth x413 x414 x7132
compress
save "$derived/p3_analytic.dta", replace
log close
