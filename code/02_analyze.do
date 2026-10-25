/*==============================================================================
  Household Finance Lab — Project 3: SCF 2025 windfall allocation
  02_analyze.do — inference | Lena Gan | StataNow 19.5
  Follows the analysis plan in DESIGN.md

  Sections:  0 Setup + helper programs     A Descriptive
             B Confirmatory (H1, H2)       C Exploratory (H3, two-part,
             D Robustness (R1-R9)            covariates, clusters)
             E Export results + analysis dataset for Python

  Variance (Fed method, codebook): point estimate = mean over 5 implicates;
  sampling variance U from 999 replicate weights on implicate 1;
  total V = U + (6/5) * between-implicate variance B.
  Sample restricted with "if" inside each implicate (valid with replicate
  weights, which carry the design). Non-sample families are never dropped
  from the file.
==============================================================================*/

clear all
set more off
version 19.5

*==============================================================================
* 0. SETUP
*==============================================================================
* Paths: run from the project folder (in Stata: File > Change Working Directory).
* Put the three Fed .dta files in data/raw before running 01_build.do.
global raw     "data/raw"
global derived "data/derived"
global logs    "logs"
global out     "output"
foreach d in data data/derived logs output {
    capture mkdir "`d'"
}
global REPS 999       // replicate weights (use 20 for a quick test run)

timer clear
timer on 1

capture log close
log using "$logs/02_analyze.log", replace text

use "$derived/p3_analytic.dta", clear

* Control variables (see CODEBOOK.md)
global ctrl "i.agecl i.marital3 i.dep_cat i.education i.employment i.racecl4 owner lnnorminc ihs_networth lncardbal hprim_mort hveh_inst hedn_inst"
global ctrl_norace "i.agecl i.marital3 i.dep_cat i.education i.employment owner lnnorminc ihs_networth lncardbal hprim_mort hveh_inst hedn_inst"
global extra "credconstr knowl10 finlit3 atconstraint incuncertain hbnpl late"

* Results frame: every scfmi call with save() adds rows here
capture frame drop results
frame create results str20 model str40 term double(b se z p) int nfam

*------------------------------------------------------------------------------
* Helper 1: scfmi — run a model on 5 implicates + replicate weights, combine
*   model()   command and variables, e.g. "glm sh_debt i.coholder"
*   options() the command's options, e.g. "family(binomial) link(logit)"
*   sample()  condition defining the analytic sample (default: insample)
*   save()    short label; results are written to the results frame
*------------------------------------------------------------------------------
capture program drop scfmi
program define scfmi, eclass
    version 19.5
    syntax , MODEL(string asis) [OPTions(string asis) SAMPle(string asis) SAVE(string)]
    if `"`sample'"' == "" local sample "insample"
    tempname bsum bbar B d U V
    * 1. Point estimate on each implicate (main weight)
    forvalues m = 1/5 {
        quietly `model' if (`sample') & implic==`m' [pw=x42001], `options'
        matrix scfmi_b`m' = e(b)
        if `m' == 1 matrix `bsum' = scfmi_b`m'
        else        matrix `bsum' = `bsum' + scfmi_b`m'
    }
    matrix `bbar' = `bsum'/5
    * 2. Between-implicate (imputation) variance
    matrix `B' = J(colsof(`bbar'), colsof(`bbar'), 0)
    forvalues m = 1/5 {
        matrix `d' = scfmi_b`m' - `bbar'
        matrix `B' = `B' + `d'' * `d'
    }
    matrix `B' = `B'/4
    * 3. Sampling variance from replicate weights, implicate 1
    preserve
        quietly keep if implic == 1
        quietly count if (`sample')
        local nfam = r(N)
        quietly svyset [pw=x42001], bsrweight(rw1-rw$REPS) vce(bootstrap)
        quietly svy bootstrap _b, nodots: `model' if (`sample'), `options'
        matrix `U' = e(V)
    restore
    * 4. Combine: V = U + (6/5)B
    matrix `V' = `U' + (6/5)*`B'
    local names : colfullnames `bbar'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    ereturn post `bbar' `V'
    ereturn local cmd "scfmi"
    ereturn scalar N_fam = `nfam'
    display as text _n "Families in sample (implicate 1): " `nfam'
    ereturn display
    * 5. Save to results frame
    if "`save'" != "" {
        tempname bb vv
        matrix `bb' = e(b)
        matrix `vv' = e(V)
        local k = colsof(`bb')
        forvalues j = 1/`k' {
            local t : word `j' of `names'
            local se = sqrt(`vv'[`j',`j'])
            if `se' > 0 {
                local bj = `bb'[1,`j']
                frame post results ("`save'") ("`t'") (`bj') (`se') ///
                    (`bj'/`se') (2*normal(-abs(`bj'/`se'))) (`nfam')
            }
        }
    }
    forvalues m = 1/5 {
        matrix drop scfmi_b`m'
    }
end

*------------------------------------------------------------------------------
* Helper 2: p3_ame — fractional logit + average marginal effects
*------------------------------------------------------------------------------
capture program drop p3_ame
program define p3_ame, eclass properties(svyb)
    version 19.5
    syntax [if] [pweight iweight] , MODEL(string asis) DYDX(string)
    quietly glm `model' `if' [`weight'`exp'], family(binomial) link(logit)
    quietly margins, dydx(`dydx') post
end

*==============================================================================
* A. DESCRIPTIVE
*==============================================================================
* A1. Weighted mean shares: all families, then the analytic sample
scfmi, model(mean sh_spend sh_save sh_debt) sample(1) save(A1_all)
scfmi, model(mean sh_spend sh_save sh_debt) save(A1_sample)

* A2. Who co-holds: survey-adjusted Wald tests of equal co-holding rates
*     across groups (design-based equivalent of a chi-square test)
scfmi, model(regress coholder i.agecl) save(A2_age)
test 2.agecl 3.agecl 4.agecl 5.agecl 6.agecl
scfmi, model(regress coholder i.education) save(A2_educ)
test 2.education 3.education 4.education
scfmi, model(regress coholder i.racecl4) save(A2_race)
test 2.racecl4 3.racecl4 4.racecl4
* Income quartiles (cut points from implicate 1, weighted)
_pctile norminc [pw=x42001] if insample & implic==1, p(25 50 75)
gen inc4 = 1 + (norminc > r(r1)) + (norminc > r(r2)) + (norminc > r(r3))
scfmi, model(regress coholder i.inc4) save(A2_inc)
test 2.inc4 3.inc4 4.inc4

* A3. Response behavior (compare with Fed FEDS Note)
scfmi, model(mean equalsplit roundresp) sample(1) save(A3_all)
scfmi, model(mean equalsplit roundresp) save(A3_sample)

*==============================================================================
* B. CONFIRMATORY  (H1, H2 — judged on B3/B4)
*==============================================================================
* B1. Mean debt share by co-holding
scfmi, model(mean sh_debt) options(over(coholder)) save(B1_means)

* B2. H1 unadjusted: survey-weighted t-test (difference = 1.coholder)
scfmi, model(regress sh_debt i.coholder) save(B2_ttest)

* B3. PRIMARY MODEL: fractional logit (GLM, binomial, logit)
scfmi, model(glm sh_debt i.coholder cardrate $ctrl) ///
       options(family(binomial) link(logit)) save(B3_primary)

* B4. Average marginal effects for H1 and H2
scfmi, model(p3_ame) ///
       options(model(sh_debt i.coholder cardrate $ctrl) dydx(coholder cardrate)) ///
       save(B4_AME)

*==============================================================================
* C. EXPLORATORY (labeled as such in all write-ups)
*==============================================================================
* C1. H3 utilization in the primary model + joint test
scfmi, model(glm sh_debt i.coholder cardrate i.util3 $ctrl) ///
       options(family(binomial) link(logit)) save(C1_H3)
test 2.util3 3.util3
scfmi, model(p3_ame) ///
       options(model(sh_debt i.coholder cardrate i.util3 $ctrl) dydx(util3)) ///
       save(C1_H3_AME)
* C1b. ANOVA-style test: debt share across utilization groups
scfmi, model(regress sh_debt i.util3) save(C1b_anova)
test 2.util3 3.util3

* C2. Two-part model
gen anydebt = (mpdebt > 0) if !missing(mpdebt)
scfmi, model(logit anydebt i.coholder cardrate $ctrl) save(C2_part1)
scfmi, model(glm sh_debt i.coholder cardrate $ctrl) ///
       options(family(binomial) link(logit)) ///
       sample(insample & anydebt==1) save(C2_part2)

* C3. Additional covariates
scfmi, model(glm sh_debt i.coholder cardrate $ctrl $extra) ///
       options(family(binomial) link(logit)) save(C3_extra)

* C4. Allocation types: k-means cluster analysis
*     Implicate 1, analytic sample, unweighted (kmeans takes no weights);
*     clusters then described with weights. Exploratory.
*     k-means depends on its random starting points, so each solution is run
*     from 10 starts and the start with the smallest within-cluster sum of
*     squares (W) is kept. Calinski-Harabasz = (B/(k-1)) / (W/(n-k)).
preserve
    keep if implic == 1 & insample
    local n = _N
    * Total sum of squares T (does not depend on k)
    local T = 0
    foreach v in sh_spend sh_save sh_debt {
        quietly summarize `v'
        local T = `T' + r(Var)*(r(N)-1)
    }
    forvalues k = 3/6 {
        local bestW = .
        forvalues s = 1/10 {
            capture cluster drop tmp
            capture drop tmp
            quietly cluster kmeans sh_spend sh_save sh_debt, k(`k') ///
                start(prandom(`=20261022 + 100*`k' + `s'')) name(tmp)
            local W = 0
            foreach v in sh_spend sh_save sh_debt {
                tempvar mu sq
                quietly bysort tmp: egen double `mu' = mean(`v')
                quietly gen double `sq' = (`v' - `mu')^2
                quietly summarize `sq', meanonly
                local W = `W' + r(sum)
                drop `mu' `sq'
            }
            if `W' < `bestW' {
                capture drop k`k'
                quietly gen k`k' = tmp
                local bestW = `W'
            }
        }
        capture cluster drop tmp
        capture drop tmp
        local CH = ((`T' - `bestW')/(`k' - 1)) / (`bestW'/(`n' - `k'))
        display as result "k = `k': best W = " %9.3f `bestW' ///
                "   Calinski-Harabasz = " %9.1f `CH'
    }
    * Describe each solution (weighted means; N = unweighted families)
    forvalues k = 3/6 {
        display _n as text "---- `k'-cluster solution ----"
        tabstat sh_spend sh_save sh_debt coholder cardrate [aw=x42001], ///
            by(k`k') stat(mean n)
    }
    keep yy1 k3 k4 k5 k6
    tempfile clusters
    save `clusters'
restore

*==============================================================================
* D. ROBUSTNESS
*==============================================================================
* R1. Linear regression
scfmi, model(regress sh_debt i.coholder cardrate $ctrl) save(R1_ols)

* R2. Three shares jointly: fractional multinomial logit (fmlogit, SSC).
*     Run once if needed:  ssc install fmlogit
*     fmlogit does not accept factor notation, so dummies are built here.
foreach v in agecl marital3 dep_cat education employment racecl4 {
    quietly tab `v', gen(D_`v'_)
    drop D_`v'_1                                   // base category
}
unab dctrl : D_* 
global ctrl_d "`dctrl' owner lnnorminc ihs_networth lncardbal hprim_mort hveh_inst hedn_inst"
* Shares rescaled to sum to exactly 1 (equal splits are stored as 33/33/33 = 99)
gen double s_spend = mpspend/(mpspend + mpsave + mpdebt)
gen double s_save  = mpsave /(mpspend + mpsave + mpdebt)
gen double s_debt  = mpdebt /(mpspend + mpsave + mpdebt)
capture program drop p3_fml
program define p3_fml, eclass properties(svyb)
    version 19.5
    syntax [if] [pweight iweight] , ETA(string asis)
    quietly fmlogit s_spend s_save s_debt `if' [pw`exp'], eta(`eta')   // fmlogit takes pweights only
end
scfmi, model(p3_fml) options(eta(coholder cardrate $ctrl_d)) save(R2_fmlogit)

* R3. Drop families who "almost always" pay the full balance (X432 = 1)
scfmi, model(p3_ame) ///
       options(model(sh_debt i.coholder cardrate $ctrl) dydx(coholder cardrate)) ///
       sample(insample & x432 != 1) save(R3_habitual)

* R4. Sensitivity: co-holding cutoffs of 1/2, 1, 2, 3 months of income
gen coh05 = (liqmonths > 0.5) if !missing(liqmonths)
gen coh1  = (liqmonths > 1)   if !missing(liqmonths)
gen coh2  = (liqmonths > 2)   if !missing(liqmonths)
gen coh3  = (liqmonths > 3)   if !missing(liqmonths)
foreach c in coh05 coh1 coh2 coh3 {
    scfmi, model(p3_ame) ///
           options(model(sh_debt i.`c' cardrate $ctrl) dydx(`c')) ///
           save(R4_`c')
}

* R5. Continuous liquid-asset months (logged)
gen lnliqm = ln(1 + liqmonths)
scfmi, model(p3_ame) ///
       options(model(sh_debt lnliqm cardrate $ctrl) dydx(lnliqm cardrate)) ///
       save(R5_lnliq)

* R6. Drop 0% card rates (H2)
scfmi, model(p3_ame) ///
       options(model(sh_debt i.coholder cardrate $ctrl) dydx(coholder cardrate)) ///
       sample(insample & cardrate > 0) save(R6_nozero)

* R7. Drop equal-split responses
scfmi, model(p3_ame) ///
       options(model(sh_debt i.coholder cardrate $ctrl) dydx(coholder cardrate)) ///
       sample(insample & equalsplit == 0) save(R7_noequal)

* R8. Race/ethnicity removed
scfmi, model(p3_ame) ///
       options(model(sh_debt i.coholder cardrate $ctrl_norace) dydx(coholder cardrate)) ///
       save(R8_norace)

* R9. Nonparametric: Wilcoxon rank-sum, unweighted, implicate 1
ranksum sh_debt if insample & implic == 1, by(coholder)

*==============================================================================
* E. EXPORT
*==============================================================================
* E1. Results table
frame results: export delimited using "$out/stata_primary_results.csv", replace

* E2. Analysis dataset for Python (no replicate weights; 5 rows per family)
preserve
    merge m:1 yy1 using `clusters', nogenerate
    drop rw1-rw999 D_*
    export delimited using "$derived/analytic_dataset.csv", replace
restore

timer off 1
timer list 1
log close
