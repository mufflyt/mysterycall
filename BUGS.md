# mysterycall — bug report (for fixing)

_Found while using the package to model ENT appointment access/timeliness (grace-ent study), 2026-07-14. Items 1–4 surfaced during hands-on use; items 5–47 are from a **full audit of all 205 source files** across three waves (modeling, data/geo/NPI, stats/screening, reporting, rates/survival, data-integrity/joins, parsers/classifiers, sampling/scenario, plus the remaining logic & cosmetic tiers). Every finding was verified against source; the high-severity ones were re-confirmed by hand. **47 bugs total: 8 HIGH, 4 MED-HIGH, 21 MED, 14 LOW.**_

**Items 22–47 are documented in the "Wave 2–3 audit" section below** (the priority table and detailed entries 1–21 that follow cover the first-wave findings). **Items 48–50** (dataset-build + cross-function-contract audit) are in the "Wave 4" section.

> ### ⚠️ STATUS: source is under concurrent fixing (as of 2026-07-14 ~22:31)
> A separate effort is actively editing `~/mysterycall/R/` — ~20 files modified, uncommitted. Several catalogued bugs are **already fixed in source**, verified: **#22** (`exclusion_summary` now `n_included <- sum(col_vec == inclusion_value)`), **#41** (`plot_effects` now `as.data.frame(eff, type = type)`), plus reported-fixed **#9, #12, #13, #38, #39**. The whole emmeans `asymp.LCL`/`lower.CL` contract class is resolved (all 8 consumers now use `intersect(...)` + `type="response"`).
> **Treat the test suite as the arbiter of what is still live** — do not assume an item here is unfixed without re-checking current source. A full `devtools::test()` run was in progress at commit time.

> ### RECONCILIATION against current source (2026-07-14, verified by source inspection)
> The concurrent fixer resolved **most** of the 50. Verified **FIXED** in source:
> #1, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 17, 19, 20, 22, 23, 24, 27, 28, 31, 32, 33, 35, 36, 37, 38, 39, 40, 41, 43, 44, 45 (33 items).
>
> **STILL LIVE (not yet fixed — the actionable remaining work):**
> - **#50** `acceptance_waffle.R:57` — `"Blue Cross / Blue Shield"` label (file untouched) — MED
> - **#48** `city_state_to_lat_long.rda` — dataset not rebuilt; `$lat`/`$long` still NULL — MED-HIGH
> - **#2** `irr_to_days.R` — `"%s-insured callers"` wording still hardcoded (the `abs()` CI bug #1 was fixed, but the insurance-specific phrasing was not) — MED
> - **#16** `power_analysis.R` — unpaired branch still `n_total * 2L` (double-counts calls) — LOW
> - **#42** `create_density_plot.R` / `create_scatter_plot.R` — still `filter(x > 0)`, dropping same-day (0-day) appointments — LOW
> - **Not re-verified (likely still live, LOW):** #18 (`<=`/`<`), #25/#26 (caller-splitting balance/order), #29/#30 (doc), #34 (`fips` schema — `man/fips.Rd` was edited; re-check), #46/#47 (`lmm` SD-units label / fallback df), #49 (benchmark dead code).

---

## ⚠️ Critical context: installed binary and source are both `1.6.0` but differ

The installed package (R library) and the source tree in `~/mysterycall` are **both
version `1.6.0` but contain different code**. Source has fixes never rebuilt/installed,
and the version was never bumped. Users on installed `1.6.0` get stale behavior.

**Every fix must also bump `Version:` in `DESCRIPTION` and rebuild:**
```r
devtools::document("~/mysterycall"); devtools::install("~/mysterycall")
```

---

## Priority summary

| # | Sev | File:line | One-liner | Status |
|---|-----|-----------|-----------|--------|
| 1 | HIGH | irr_to_days.R:187–197 | `abs()` on day-CI bounds hides zero-crossing / reverses order | verified |
| 5 | HIGH | clean_phase_1_results.R:226 | `format()` turns missing NPI into string `"NA"`, defeating missing-NPI fallback → `doctor_id` collisions | verified |
| 6 | HIGH | wait_time_sentence.R:109 | p-value rounded to 3dp with no `<0.001` guard → prints "p = 0" | verified |
| 7 | MED | nb_power.R:92–108 | paired 2-calls-per-NPI design simulated as **unpaired** → overstates required N | verified |
| 8 | MED | sensitivity_both_insurance.R:143 | unpaired Welch t-test on a paired design → wrong SE/p | reviewer-verified |
| 9 | MED | model_mae_rmse.R:310 | `exp()` instead of `expm1()` to invert `log1p` → +1 bias, MAPE wrong | verified |
| 10 | MED | univariate_lmm_screen.R:135 | `exp()` of a linear day-coefficient labeled "IRR" | verified |
| 11 | MED | interaction_screen.R:159 | interaction significance = `min(p)` over **all** coefs incl. main effects | verified |
| 12 | MED | irr_plot.R:111,122 | significance colors permuted → forest plot marks wrong terms significant | verified |
| 13 | MED | write_results_paragraph.R:100 | opens "was significantly associated" **unconditionally** | verified |
| 14 | MED | icc.R:219 | CI labeled with `n_boot` → prints "500% CI" instead of "95% CI" | verified |
| 15 | MED | address_normalizer.R:371 | numeric ZIP with leading zero → `NA` (all of CT/MA/ME/NH/NJ/RI/VT/PR/VI) | verified |
| 2 | MED | irr_to_days.R:197; results_paragraph.R:143–152 | hardcoded "-insured callers" wording assumes insurance exposure | verified |
| 3 | MED | overdispersion_test.R (build) | NB-aware fix in source but not shipped in installed 1.6.0 | verified |
| 16 | LOW | power_analysis.R:172 | unpaired branch doubles call count (`n_total * 2`) | reviewer-verified |
| 17 | LOW | gt_irr_table.R:72 | default label typo "IRR (95 95% CI)" | reviewer-verified |
| 18 | LOW | interaction_screen.R:200 | doc says `<= alpha`, code uses `< alpha` | verified |
| 19 | LOW | address_utils.R:32–38 | `extract_zip5("7001-1234")` → "70011" (dropped-zero + ZIP+4) | reviewer-verified |
| 20 | LOW | impute_age.R:70–78 | near-future grad year yields bogus age instead of `NA` | reviewer-verified |
| 21 | LOW | clean_phase_1_results.R:348–370 | non-duplicate mode assigns insurance by row-number parity | reviewer-verified |
| 4 | LOW | overdispersion_test.R | φ from `df.residual` ignores random-effect df for GLMMs (doc caveat) | verified |

**Suggested fix order:** 5, 6, 1 (wrong numbers/IDs into data & manuscript) → 7, 8, 16 (paired-design math) → 15, 19 (ZIP leading zeros) → 9–14 (reporting/stat correctness) → 2, 3 (generalization + rebuild) → 17–21, 4.

---

## Cross-cutting themes

1. **The paired insurance design (each NPI called under both insurances) is mishandled in the power/sensitivity machinery** — `nb_power.R` (#7) simulates it as unpaired, `sensitivity_both_insurance.R` (#8) tests it as unpaired, `power_analysis.R` (#16) double-counts calls. Consequence for study planning: the pre-specified power targets are miscomputed (they overstate required N for the within-physician comparison).
2. **ZIP leading zeros** — `normalize_zip5` (#15) and `extract_zip5` (#19) disagree on padding; unifying both on left-pad-after-coercion fixes both. Silent data loss for ~9 Northeast states/territories.
3. **Manuscript-facing functions can print flatly wrong claims** — "p = 0" (#6), unconditional "significantly associated" (#13), reversed forest-plot significance colors (#12), and abs()-collapsed CIs (#1). These go straight into a paper.

---

## HIGH severity

### 1 — `irr_to_days.R:187–192, 197` — `abs()` on CI bounds hides zero-crossing (and reverses order)
**Status: broken in BOTH source and installed 1.6.0.** The `$table` computes signed day-CI
(`days_ci_lower/upper`) correctly, but the sentence builder does `abs_lo <- abs(days_ci_lower)`,
`abs_hi <- abs(days_ci_upper)` before printing.
**Failure (real ENT output):** Facial Plastics true days CI = **[−6.5, +11.4]** (crosses zero,
p=0.852) prints as *"95% CI 6.5 to 11.4 days"* — a null result rendered as a positive bounded
effect. For IRR < 1 both bounds are negative → `abs()` flips sign **and** reverses order.
**Fix:** drop `abs()`; print signed bounds (`formatC(..., flag="+")`). Bounds are already
ordered (`days_ci_lower < days_ci_upper`). Optionally append "(not significant)" when the CI
spans 0.

### 5 — `clean_phase_1_results.R:226` — missing NPI becomes the string `"NA"`, defeating the missing-NPI fallback
```r
phase1_data[[npi_col_before_clean]] <- trimws(format(phase1_data[[npi_col_before_clean]],
                                                     scientific = FALSE, trim = TRUE))
```
`format()` renders `NA` as literal `"NA"` (verified). Every downstream `is.na(.data$npi)` check
(lines ~299–308, 420–424) is then always `FALSE` for these rows.
**Failure:** input `npi = c("1234567893", NA)` → column becomes `c("1234567893","NA")`. The
missing-NPI row gets no `random_id` (`random_id="NA"`), `original_npi="NA"`, and
`doctor_id = coalesce(npi, random_id) = "NA"`. **All missing-NPI rows collapse to the same
`doctor_id="NA"` and collide in downstream joins** — the exact placeholder-collision the package
claims to prevent. `completeness_npi` also miscounts them as present.
**Fix:** keep real `NA`: `ifelse(is.na(v), NA_character_, trimws(format(v, scientific=FALSE, trim=TRUE)))`.

### 6 — `wait_time_sentence.R:109 (rendered :151)` — p-value collapses to "0"
```r
p_values[lvl] <- round(p_raw, digits = digits_p)     # :109
... sprintf("The p-value for %s vs %s was %s.", ..., format(p_values[j], digits = digits_p))  # :151
```
No `<0.001` guard. Any p < 5e-4 rounds to `0`.
**Failure:** true p = 3e-8 → sentence reads *"The p-value for Medicaid vs BCBS was 0."*
**Fix:** `p_txt <- if (p_raw < 0.001) "< 0.001" else formatC(p_raw, digits = digits_p, format = "f")`;
never render a `round()`ed p through `format()`.

---

## MEDIUM severity

### 7 — `nb_power.R:92–108` — paired design simulated as unpaired (overstates required N)
Docstring: `calls_per_physician` "Default 2L (one Medicaid, one reference insurance)" — a
within-physician comparison. But the loop draws two disjoint physician sets (`u_ref` for
`R1..Rn`, `u_trt` for `T1..Tn`) and gives every physician's calls one insurance → insurance is
simulated **between** clusters. The random intercept then inflates the `ins` SE.
**Failure:** `mysterycall_nb_power(36, irr=0.75)` reports power/N for an unpaired 72-physician
design (`total_n = 144`), systematically overstating the N a paired study needs.
**Fix:** one physician set called under both arms; single `u` per physician added to both;
`ins` varies within physician.

### 8 — `sensitivity_both_insurance.R:143–146` — unpaired test on a paired design
Physicians are selected *because* called under both Medicaid and BCBS, then compared with an
unpaired Welch `t.test(outcome ~ insurance)`, ignoring pairing.
**Failure:** 30 physicians with within-physician-correlated waits → unpaired test inflates SE,
returns n.s. even when the paired difference is clearly significant.
**Fix:** paired test on per-physician differences (`t.test(medicaid, bcbs, paired=TRUE)` after
reshaping) or a mixed model.

### 9 — `model_mae_rmse.R:310–311` — `exp()` used to invert `log1p()` (should be `expm1()`)
LMM stores `log1p(days)` (`lmm.R:202,213`). Back-transform does `exp(actual_raw)` = `days + 1`.
**Failure:** 20-day wait → reported `actual = 21`; a same-day (0-day) appointment → `1`, and since
it's no longer `== 0` it's wrongly kept in the MAPE denominator, biasing MAPE. (MAE/RMSE/R²
unaffected because +1 cancels.)
**Fix:** `expm1(actual_raw)`, `expm1(predicted_raw)`.

### 10 — `univariate_lmm_screen.R:135–137` — `exp()` of a linear coefficient labeled "IRR"
Model is `lmerTest::lmer` on raw days, but code reports `irr <- exp(coef)`, `exp(coef ± 1.96 SE)`.
**Failure:** predictor adds +7 days → reported `IRR = exp(7) ≈ 1096` fed into forest plots.
**Fix:** report the additive estimate + `estimate ± 1.96 SE` as a mean difference; or fit
Poisson/NB if an IRR is wanted.

### 11 — `interaction_screen.R:151–163` — interaction significance = `min(p)` over ALL coefficients
`P_Value` per pair is `min()` over every non-intercept coefficient, **including the two main
effects** — so a pair is flagged "significant interaction" whenever any main effect is
significant. (Sibling `screen_interactions.R` filters to `:` terms correctly.)
**Failure:** `y ~ insurance * gender`, insurance main p<0.001 but interaction p=0.7 → reported as
a significant interaction.
**Fix:** restrict `p_vals` to rows whose names contain `":"` before `min()`.

### 12 — `irr_plot.R:111, 122` — significance colors permuted relative to rows
`color = tbl$.sig[order(as.integer(tbl$term))]`; `term` was just re-leveled to `rev(term)`, so
`as.integer(term)` is decreasing and `order()` is the reverse permutation. ggplot binds a manual
(non-aes) color vector to rows in existing order.
**Failure:** terms A,B,C with p = 0.01,0.5,0.5 (red,navy,navy) → colors applied as navy,navy,red;
significant A drawn non-significant, non-significant C drawn significant.
**Fix:** pass `color = tbl$.sig` unpermuted, or `aes(color=.sig) + scale_color_identity()`.

### 13 — `write_results_paragraph.R:100–103` — unconditional "significantly associated"
Intro sentence asserts significance regardless of p-values. (A second, correctly-gated definition
exists in `manuscript_helpers.R:269` — the two collide; the reviewed one overstates.)
**Failure:** table with all p > 0.2 still opens *"insurance was significantly associated with
appointment acceptance."*
**Fix:** gate on `any(matched$p_value < alpha, na.rm = TRUE)` → "was" vs "was not significantly".

### 14 — `icc.R:219` — CI label prints `n_boot` instead of confidence level
Object never stores `conf_level` (structure list at 110–121); print method fills `"%d%% CI"` with
`round(x$n_boot)`.
**Failure:** `print(mysterycall_icc(fit, n_boot=500, conf_level=0.95))` → *"500% CI = [...]"*.
**Fix:** store `conf_level` in the object; use `round(x$conf_level*100)` for the label, keep
`n_boot` only for the replicate count.

### 15 — `address_normalizer.R:371` (`mysterycall_normalize_zip5`) — numeric ZIP loses leading zero → `NA`
`z <- stringr::str_extract(as.character(zip), "\\d{5}")`. `@param`/`@examples` support numeric
input, but a numeric ZIP with a leading zero has only 4 digits → no 5-digit run → `NA`.
**Failure (verified):** `normalize_zip5(7001)` → `NA` (should be `"07001"`); blanks ZIP for all of
CT/MA/ME/NH/NJ/RI/VT/PR/VI in `normalize_address_df()`.
**Fix:** coerce + left-pad before extracting, mirroring `extract_zip5`: `sprintf("%05.0f", zip)`
for numerics, or strip non-digits then `formatC(width=5, flag="0")`.

### 2 — `irr_to_days.R:197`; `results_paragraph.R:143,148,152` — hardcoded insurance wording
Templates assume the exposure is insurance and unit is "callers": `"%s-insured callers ..."`,
`level, " callers were ", pct, "% less likely ..."`.
**Failure:** with `exposure_col="ent_type"` → *"Laryngology-insured callers ..."* / *"Pediatrics
callers were 126% more likely"* — nonsensical; this ENT study has **no insurance variable**.
**Fix:** add `subject = "callers"` and `exposure_descriptor = NULL` args; drop the `-insured`
infix when `NULL`. Keep insurance defaults so OB/GYN callers are unaffected.

### 3 — `overdispersion_test.R:159–186` — NB-aware fix in source but not shipped
Source has an `is_nb`/`is_mixed` branch ("normal for NB models"); installed 1.6.0 lacks it and
prints *"Underdispersion detected (phi=%s). Model may overfit."*
**Failure:** on a correct NB GLMM (residual φ=0.72 after absorbing Poisson φ=6.22), installed
package advises removing predictors.
**Fix:** primarily rebuild + version bump so the source fix ships. Harden: `is_nb` relies on
`tryCatch(stats::family(model)$family, "")`; the `is_mixed` branch is an adequate backstop — keep
the ordering.

---

## LOW severity

### 16 — `power_analysis.R:172–174` — unpaired branch doubles call count
`both_arms = FALSE` sets `n_total_calls <- n_total * 2L`, but unpaired = one call per provider so
calls = providers = `n_total`.
**Failure:** `poisson_power(irr=1.4, lambda_ref=14, both_arms=FALSE)`, `n_per_arm=63` → reports
`n_total_calls=252` (correct: 126). (`both_arms=TRUE` branch is correct.)
**Fix:** `n_total_calls <- n_total` in the `else` branch.

### 17 — `gt_irr_table.R:72` — default label typo
`outcome_label = "IRR (95 95% CI)"` (duplicated "95") becomes the gt column header.
**Fix:** `"IRR (95% CI)"`.

### 18 — `interaction_screen.R:200–202` — `<=` vs `<` doc/code mismatch
Docstring/`@param alpha` say significant when `p <= alpha`; filter uses `< alpha`. Boundary p =
alpha excluded.
**Fix:** use `<=` or correct the docstring.

### 19 — `address_utils.R:32–38` (`mysterycall_extract_zip5`) — dropped-zero + ZIP+4 grabs a +4 digit
`substr(digits, 1, 5)` crosses the 5/+4 boundary when the 5-digit part already lost its leading
zero.
**Failure (verified):** `extract_zip5("7001-1234")` → `"70011"` (should be `"07001"`). Bare
`"00501"`, `"8020"`, `"07001-1234"` all fine.
**Fix:** strip the `-`+4 suffix first (`sub("-.*$","",s)`) before taking the first 5 digits.

### 20 — `impute_age.R:70–78` — near-future graduation year yields a bogus age
Code messages that `grad_year > ref_year` rows "will produce NA," but they only become `NA` via
the `min_age` filter; a 1–2-year-future grad survives.
**Failure:** `impute_age(2027, ref_year=2026)` → `2026-2027+27 = 26`, and `26 >= min_age(25)` → returns
`26` (a physician who hasn't graduated).
**Fix:** `age[grad_year > ref_year] <- NA_integer_` explicitly.

### 21 — `clean_phase_1_results.R:348–370` — non-duplicate mode assigns insurance by row parity
`duplicate_rows = FALSE` → `processing_flag_is_duplicate = row_number() %% 2 == 0`, and insurance
derived from it (even → Medicaid, odd → BCBS). With one row per physician, insurance is labeled by
arbitrary sort position.
**Failure:** two physicians get "BCBS"/"Medicaid" purely because one sorts first by name.
**Fix:** in non-duplicate mode leave insurance/flag unset, or take insurance from a real input column.

### 4 — `overdispersion_test.R` — φ ignores random-effect df for GLMMs (doc caveat)
`df.residual()` on `glmmTMB` counts fixed params only, ignoring effective df from random
intercepts → φ is approximate for GLMMs. Not a wrong-output bug; add a `@section` caveat or use
`DHARMa::testDispersion` for mixed models.

---

---

# Wave 2–3 audit (items 22–47)

Full-package sweep beyond the first 21. Three recurring themes tie many of these together:

- **NA → the string `"NA"` in ID handling** — the catalogued bug #5 (`clean_phase_1_results`) is **not isolated**: it recurs in the *core shared reader* `utils-io.R` (#43, `sprintf("%.0f", NA)`). Any numeric NPI column with a missing value collapses all missing rows to `doctor_id="NA"` and collides in joins.
- **Unanchored substring classifiers corrupt covariates** — `classify_medical_school` (#31) and `classify_practice_setting` (#32) match country/institution tokens without `\b`, so "**India**na", "New **Mexico**", "**Penn**sylvania", "No**va**" are mislabeled IMG/Government/Academic.
- **Hardcoded "including the District of Columbia"** appears in three summary sentences (#40 `sample_demographics`, #45 `states_where_physicians_were_not_contacted`, and a near-identical construct) that contradict the excluded-states list when no DC row is present.

## Wave 2–3 priority table

| # | Sev | File:line | One-liner | Status |
|---|-----|-----------|-----------|--------|
| 43 | HIGH | utils-io.R:96 | `sprintf("%.0f", NA)`→`"NA"` in shared reader → doctor_id join collisions (bug #5 at the core reader) | verified |
| 22 | HIGH | exclusion_summary.R:236 | `inclusion_value` unused; unrecognized/NA reasons silently counted as "included" (overstates analytic N; table still sums to 100%) | verified |
| 36 | HIGH | prepare_calls.R:144,184 | drop branch doesn't subset `is_na_exc` → recycled logical injects phantom all-NA rows into logistic_data | verified |
| 31 | HIGH | classify_medical_school.R | unanchored `"india"`/`"mexico"` → Indiana/New-Mexico schools misclassified IMG | verified |
| 32 | HIGH | classify_practice_setting.R:23 | `"va "`/`"penn"` over-match → private ENT offices → Government/Academic | verified |
| 27 | MED-HIGH | wait_time_crossover.R:293 (+doc:17) | crossover direction **reversed** (says group2 longer; it's shorter) | verified |
| 33 | MED-HIGH | parse_physician_name.R:82 | documented "Last, First" mis-parsed (first→suffix, last lost) | verified |
| 44 | MED | lmm.R:340 | Wald CI uses `qnorm` z while p uses Satterthwaite t-df → CI and p can disagree (GMR table inherits) | verified |
| 28 | MED | insurance_acceptance_rates.R:145 | BCBS numerator gated on Medicaid-only field; num/denom NA mismatch → biased/0.0% rate | verified |
| 23 | MED | flag_repeat_physicians.R:66 | dup detection keyed on id+name → name variants defeat it (also save_quality_check_table.R:38) | verified |
| 34 | MED | fips.rda | ships 51-row state table; docs describe 3142-row county table → documented county merges error | reviewer-verified |
| 37 | MED | literature_table.R:354 | OR range includes current study but attributed to "N published studies" | reviewer-verified |
| 38 | MED | plot_emmeans_interaction.R:55,76 | no `type="response"`, hardcoded `lower.CL/upper.CL` → errors/log-scale on Poisson | reviewer-verified |
| 39 | MED | plot_disparities.R:138 | abs_diff error bars use one group's rate-CI half-width (too narrow; ref row nonzero) | reviewer-verified |
| 40 | MED | sample_demographics.R:129 | hardcoded "including the District of Columbia" contradicts excluded list | reviewer-verified |
| 41 | MED | plot_effects.R:65 | `type` drives label but not `as.data.frame(eff)` → response values under "Linear predictor" label | verified |
| 35 | LOW-MED | validate_phone (nanp csv) | PR primary code 787 (and 671/340) missing → valid territory numbers flagged invalid | reviewer-verified |
| 45 | LOW-MED | states_where...not_contacted.R:135 | hardcoded "including DC" self-contradicts when DC uncontacted | reviewer-verified |
| 42 | LOW | create_density_plot.R:65; create_scatter_plot.R:72 | drop `x>0` even for `transform="none"` → same-day (0-day) appts excluded from viz | reviewer-verified |
| 24 | LOW | collapse_rare.R:51 | phantom empty "Other" level added even when nothing collapsed | reviewer-verified |
| 25 | LOW | splitting_dataframe...R:169 | per-group round-robin restart breaks "≤1 row difference" balance | reviewer-verified |
| 26 | LOW | splitting_dataframe...R:201 | split return order alphabetical; zero-row assistants dropped | reviewer-verified |
| 46 | LOW | lmm.R:524,585 | residual/RE SD printed as "days" even when outcome is `log1p` | reviewer-verified |
| 47 | LOW | lmm.R:324,329 | fallback residual df `n-est_df-1` off by one (only if lmerTest absent) | reviewer-verified |
| 29 | LOW(doc) | outcome_analysis.R:267 | docstring says NA counts as not-accepted; code drops NA (code fine, doc wrong) | reviewer-verified |
| 30 | LOW(doc) | call_productivity.R:126 | numerator drops NA, denominator doesn't (doc/consistency) | reviewer-verified |

**Minor (dead code / boundary / doc, not wrong-output):** `classify_practice_setting.R:31` `.mc_private_patterns` never used; `hhi.R:191` `cut()` puts hhi==1000 in "un-concentrated" (DOJ boundary); `academic_indicators.R:44` bare `"UNIVERSITY OF"` at 0.99 conf matches "University of Phoenix"; `interaction_table.R:229` LRT p rounded to 2dp so 0.049/0.051 both print "0.05" with opposite conclusions; `assign_scenarios.R:126` round-robin restarts per location group (global imbalance); `create_and_plot_interaction.R:156` doc says link scale, values are response scale.

## HIGH (items 22–47)

### 43 — `utils-io.R:96` — `sprintf("%.0f", NA)` → `"NA"` in the shared reader
`df[["npi"]] <- sprintf("%.0f", npi_vals)` runs unconditionally for numeric NPI columns; `sprintf("%.0f", NA)` = `"NA"` (verified). This is bug #5 at the level of `mysterycall_read_table` — the reader used to load *every* roster — so all missing-NPI rows collapse to `doctor_id="NA"` and collide.
**Fix:** `out <- sprintf("%.0f", npi_vals); out[is.na(npi_vals)] <- NA_character_; df[["npi"]] <- out`.

### 22 — `exclusion_summary.R:234–236` — "included" is a residual that absorbs unrecognized rows
`inclusion_value` is validated then never used; `n_included = total − n_unreachable − n_excluded_among_reached`. Any reason not in the 6 known strings (typo/NA/other) is silently counted as reached+included.
**Failure:** 100 "Able to contact" + 10 voicemail + 5 "Deceased" → reports `n_included=105` (should be 100). The `$table` still sums to 100%, so the STROBE flow *looks* reconciled.
**Fix:** `n_included <- sum(col == inclusion_value, na.rm=TRUE)`; surface `total − included − unreachable − excluded` as an explicit "unrecognized" bucket.

### 36 — `prepare_calls.R:144, 163–189` — drop branch injects phantom NA rows
When `na_exclusions="drop"`, `d` and `exc` are subset to non-NA rows but `is_na_exc` keeps its original length. At Step 5 the `|`/`&` of reduced- and original-length vectors recycles, producing an `in_logistic` longer than `nrow(d)`; `d[in_logistic, ]` then selects out-of-range indices → all-NA rows.
**Failure:** `exclusions=c(0,NA,0,NA,7)`, `contacted1=1`, drop → `log_data` has 5 rows (2 all-NA) instead of 3; phantom rows get `appt_offered=0`, inflating the denominator; waterfall reports n=5. (Default `"warn"` path is fine.)
**Fix:** subset every parallel vector in the drop branch: `is_na_exc <- is_na_exc[!is_na_exc]` (or recompute after the drop).

### 31 — `classify_medical_school.R` — unanchored country substrings
`.mc_img_patterns`/`.mc_canadian_patterns` matched via `grepl(perl=TRUE)` without `\b`.
**Failure (verified):** "Indiana University School of Medicine" → IMG (`"india"`); "University of New Mexico" → IMG (`"mexico"`); "Western University of Health Sciences" (US DO) → CAN_MD.
**Fix:** anchor tokens (`"\\bindia\\b"`, `"\\bmexico\\b"`, …) or match country as a standalone token.

### 32 — `classify_practice_setting.R:14–24` — unanchored government/academic substrings
**Failure (verified):** "Nova Southeastern Medical Center" → Government (`"va "` inside "no**va** "); "Fairfax VA Otolaryngology" → Government; "Pennsylvania ENT Associates" → Academic (`"penn"`). Government is checked first, so mislabels are sticky.
**Fix:** replace bare `"va "` with `"veterans"`/`"\\bvamc\\b"`/`"\\bva medical"`; anchor short brand tokens (`"\\bpenn\\b"`, `"\\busc\\b"`).

## MED-HIGH / MED / LOW (items 22–47) — detail

### 27 — `wait_time_crossover.R:290–298 (+ @details:17–18)` — crossover direction reversed
Regression `y`=group2, `x`=group1; finite crossover needs slope `0<m<1`, so beyond the crossover `y−x=(m−1)x+b < 0` → group2 waits **shorter**. Sentence/docs say group2 longer.
**Failure:** `m=0.5,b=3` → crossover 6; at x=10, y=8<10 (group2 shorter), yet prints "[group2] patients experienced longer waits."
**Fix:** beyond the crossover it's group1 with the longer wait; fix sentence + `@details`.

### 33 — `parse_physician_name.R:82–96` — "Last, First" mis-parsed
Splits on first comma, treats the remainder as suffix; "Last, First" (documented format) misroutes.
**Failure:** `"Smith, John"` → first="Smith", last=NA, suffix="John"; `"Garcia, Robert, MD"` → first="Garcia", suffix="Robert, MD".
**Fix:** only treat the post-comma segment as suffix when it matches a suffix/credential pattern; else pass whole string to `humaniformat::parse_names()`.

### 44 — `lmm.R:340–341, 349–350` — Wald CI (z) vs Satterthwaite p (t-df) mismatch
CI uses `qnorm` z; p uses lmerTest Satterthwaite `Pr(>|t|)`. With small residual df they disagree; `gmr_table` inherits.
**Failure:** est=2, se=1, df=8 → z-CI [0.04, 3.96] (excludes 0) but Satterthwaite p=0.081.
**Fix:** `qt(1-(1-conf_level)/2, df=df_values)` per term.

### 28 — `insurance_acceptance_rates.R:112–155` — BCBS numerator gated on Medicaid field; num/denom NA mismatch
`bcbs_base`/`med_base` filter `!is.na(does_the_physician_accept_medicaid)` (Medicaid-only field) but denominators use unfiltered data. BCBS rate biased low, or **0.0%** if that field is NA on BCBS rows.
**Fix:** compute numerator and denominator from the same frame; `bcbs_base <- data` (never apply the Medicaid screen to BCBS).

### 23 — `flag_repeat_physicians.R:66` — dup detection keyed on id + name
`group_cols <- c(id_col, name_col)`; name variants split a duplicate id into singletons → not flagged. Same in `save_quality_check_table.R:38`.
**Fix:** group on `id_col` only; keep name as a display annotation.

### 34 — `fips.rda` — packaged dataset ≠ documented schema
`@format` documents 3142-row county table (`fips`, `county_fips`, `state_fips`, …); shipped object is 51-row state table (`state`, `state_code`, `state_name`). Documented county merges / `fips$fips` error. (`state_code` does keep leading zeros.)
**Fix:** regenerate as county table, or rewrite `@format` and rename `state_code`→`state_fips`.

### 37 — `literature_table.R:354–388` — OR range includes current study, attributed to prior
`or_range` spans `combined$or` (incl. current row) but the sentence says "N published studies … ranged from {or_range}".
**Fix:** compute `or_range` over prior rows only when `current_study` is non-NULL.

### 38 — `plot_emmeans_interaction.R:55, 76–77` — breaks on Poisson
No `type="response"`; hardcodes `lower.CL/upper.CL` (Poisson glmer yields `asymp.LCL/UCL`) → errors, or plots log-scale under a raw-outcome axis. Sibling `plot_emmeans_full`/`plot_and_save_emmeans` do it right.
**Fix:** add `type="response"`; detect CI cols via `intersect(c("asymp.LCL","lower.CL"), names(df))`.

### 39 — `plot_disparities.R:138–141` — abs_diff CI from one group's rate CI
`abs_diff ± (upper−lower)/2` uses the group's Wilson rate CI; a difference-of-proportions CI must include the reference variance. Too narrow; reference row (abs_diff=0) drawn with a spurious ± interval.
**Fix:** carry proper abs_diff CI from `mysterycall_disparities_table()`; set ref interval to 0.

### 40 / 45 — hardcoded "including the District of Columbia"
`sample_demographics.R:129` and `states_where_physicians_were_not_contacted.R:135` append "including the District of Columbia" unconditionally; when DC is absent it's also in the excluded list → self-contradiction.
**Fix:** gate the clause on `"District of Columbia" %in% included_states`.

### 41 — `plot_effects.R:65` — `type` not passed to data extraction
`type` picks the y-label but `as.data.frame(eff)` always returns response scale.
**Failure:** `type="link"` on a Poisson model draws response counts (10–31) under a "Linear predictor" label.
**Fix:** `df <- as.data.frame(eff, type = type)`.

### 35 — NANP lookup missing Puerto Rico 787
`inst/extdata/nanp_area_codes_us.csv` has PR overlay 939 but not primary 787 (nor 671 Guam, 340 USVI). Valid 787 numbers → `phone_validity_flag="unknown_area_code"`, `phone_e164_valid=FALSE`. `validate_phone.R` logic is otherwise correct.
**Fix:** add 787/671/340 to the CSV.

### 42 — `create_density_plot.R:65` / `create_scatter_plot.R:72` — drop zeros even when untransformed
`filter(x > 0)` runs for `transform="none"`, excluding same-day (0-day) appointments — a real, common primary-outcome value. `line_plot.R` keeps zeros → inconsistent.
**Fix:** in the `"none"` branch filter only `!is.na(x)`.

### 24 / 25 / 26 — `collapse_rare` / `splitting_dataframe_to_send_to_callers`
- **24** `collapse_rare.R:51`: appends `other_label` level unconditionally → phantom empty "Other" category when nothing was collapsed. Fix: guard on `length(rare) > 0`.
- **25** `splitting…R:169–177`: round-robin index restarts within each insurance group → assistant A can get 2+ more rows than B. Fix: round-robin over the full sorted frame, or carry the counter across groups.
- **26** `splitting…R:201–222`: `base::split()` returns groups alphabetically and omits zero-row assistants, contradicting the documented roster order. Fix: iterate `lab_assistant_names` explicitly.

### 46 / 47 — `lmm.R` print/df
- **46** `lmm.R:524–525, 585`: residual & RE SD printed as "days" even when `log_transformed=TRUE` (they're log units). Fix: use `log_label`.
- **47** `lmm.R:324, 329`: fallback (`lmerTest` absent) residual df `n − est_df − 1`; `est_df` already counts the intercept → should be `n − est_df`. Slightly conservative p.

### 29 / 30 — doc/consistency
- **29** `outcome_analysis.R:267–269`: docstring says NA counts as not-accepted; code drops NA from the denominator (code is the sound choice; fix the doc).
- **30** `call_productivity.R:126–129`: `n_accepted` uses `na.rm=TRUE` but `n_calls` includes NA-outcome rows → deflated per-caller rate. Align the denominator or document.

---

# Wave 4 — dataset-build & cross-function-contract audit (items 48–50)

Covers surfaces that reading `R/` cannot: the `data-raw/` scripts that build the packaged
`.rda` datasets, and producer→consumer column/scale contracts across functions.

| # | Sev | File:line | One-liner | Status |
|---|-----|-----------|-----------|--------|
| 48 | MED-HIGH | data-raw/city_state_to_lat_long_load.R | built `.rda` has `state`(full names)+`latitude`/`longitude`; docs promise 2-letter `state`+`lat`/`long` → `$lat` returns NULL, abbrev joins match 0 rows | verified (against built rda) |
| 50 | MED | acceptance_waffle.R:57 | `bcbs_label` default `"Blue Cross / Blue Shield"` (spaces) ≠ canonical `"Blue Cross/Blue Shield"` (23 other uses) → hard error on canonical data | verified |
| 49 | LOW | data-raw/benchmark_name_parser.R:47 | `is.na(x) & x == ""` is a contradiction (always FALSE); dead code | verified |

### 48 — `data-raw/city_state_to_lat_long_load.R` — built dataset doesn't match its documented schema
The build reads the source CSV verbatim (`read_csv` + `type_convert` + `use_data`) and never
renames/transforms. Verified from `data/city_state_to_lat_long.rda`: columns are
`state`("Alabama"), `city`, `latitude`, `longitude`. But `man/city_state_to_lat_long.Rd`/roxygen
`@format` document `city`, `state`(**2-letter postal**), `lat`, `long`.
**Failure:** `city_state_to_lat_long$lat`/`$long` return `NULL` (names don't exist); any join on a
2-letter `state` abbreviation matches **zero** rows (values are full names). 3 of 4 columns breach
the contract. (Lat/long *values* are correct — US range, no sign/swap.)
**Fix:** in the build rename `latitude→lat`, `longitude→long`, convert `state` full names → USPS
abbreviations (incl. DC), reorder to `city, state, lat, long` — or correct the `@format` docs.

### 50 — `acceptance_waffle.R:57` — BCBS label default doesn't match the package-canonical value
The canonical insurance string emitted by `clean_phase_1_results.R:381` (and defaulted in
`run_analysis`, `insurance_acceptance_rates`, `insurance_wait_sentence`, `acceptance_rate_calc`,
`splitting_dataframe_to_send_to_callers`) is `"Blue Cross/Blue Shield"` (no spaces). Only
`acceptance_waffle.R` defaults to `"Blue Cross / Blue Shield"` (spaces); at `:96` it filters
`insurance_type == bcbs_label` and `stop()`s on zero rows.
**Failure:** `mysterycall_acceptance_waffle(acc)` with defaults on canonical data →
`No rows found for insurance_type == 'Blue Cross / Blue Shield'`; the BCBS panel never renders.
**Fix:** `bcbs_label = "Blue Cross/Blue Shield"`.

### 49 — `data-raw/benchmark_name_parser.R:47–48` — contradictory predicate (dead code)
`dont_care <- is.na(x) & x == "" & is.na(y) & y == ""` can never be TRUE (`is.na(x) & x==""` is a
contradiction). Harmless today (never used downstream), but broken and misleading. **Fix:** remove,
or use `is.na(x) | x == ""` per field.

### Cross-function contract notes (latent, not runtime failures today)
- **Phase-2 short vs long column names:** `run_mystery_caller_workflow.R:130` renames to
  `exclusion_reasons`/`appt_date`/`transfer_count`, but analysis/QC consumers default to
  `reason_for_exclusions`/`business_days_until_appointment`. Piping cleaned phase-2 straight in
  without re-mapping args silently mismatches columns.
- **`prepare_calls.R:110`** emits the wait column as `calendar_days` vs the ecosystem default
  `business_days_until_appointment` (naming outlier; no in-package failure).
- **`p_value_fmt` spacing:** `nb_model`/`poisson_model` emit `"<0.001"`, `logistic_model`/`lmm`
  emit `"< 0.001"`; mixed tables print inconsistent spacing (parsers tolerate both).

**Resolved contract class (no bugs):** all 8 emmeans/effect consumers now resolve CI columns via
`intersect(c("asymp.LCL","lower.CL","lower.HPD"), names(df))` + `type="response"`; the
irr_table/or_table/coef_table/gmr_table producer→consumer chains are column- and scale-consistent.

---

## Audited and found CORRECT (no change needed — do not "fix")

- **`business_days.R` (the study's PRIMARY OUTCOME)** — all 11 federal holidays, Sat→Fri/Sun→Mon
  observance, floating-holiday weekday codes, weekend exclusion, start-exclusive/end-inclusive
  convention, `end<start`→NA, NA→NA, equal→0. **Correct.**
- **`npi_utils.R` Luhn (CMS 80840 prefix)** — `1234567893`,`1245319599`→TRUE; `1234567890`,`NA`→FALSE. Correct.
- **`classify_ruca.R`** — 1–3/4–6/7–10 boundaries, no off-by-one.
- **`impute_age.R` `mysterycall_age_category`** — `findInterval` binning correct at 30/40/70 boundaries.
- **ACS `acs_adults_18_90.R` / `acs_female_pop.R` / `summarize_census_data.R`** — B01001 age/sex
  regex, female 15–44 mapping, MOE sum-of-squares, denominators all correct.
- **`get_census_data.R`** — FIPS/GEOID kept as `str_pad`ded strings (no numeric coercion).
- **`assign_region.R`** — ACOG/AAO-HNS/Census lookup + abbreviation normalization correct.
- **`enrich_npi.R` / `dedup_by_insurance.R`** — dedup keeps intended row.
- **Modeling cores** — `nb_model`/`logistic_model`/`poisson_model`/`simple_poisson` Wald & profile
  CIs (`exp(est ± z·se)`, correct log→response), `predict_appointment` delta-method logit CI,
  `marginal_effects` central-difference AME, `overdispersion_sentence` χ²/df + upper-tail p. Correct.
- **Stats** — `check_normality` (`p>0.05` correct direction), `multiple_comparison` (`p.adjust`,
  fdr→BH), `bootstrap_ci` percentile quantiles, `power_calc`/`cochran_n` algebra. Correct.
  (Caveat, not a bug: `bootstrap_ci` and `power_curve` ignore within-physician clustering /
  reuse `seed=42` per cell — CIs too narrow / correlated noise, but each estimate is unbiased.)
- **Reporting** — `insurance_wait_sentence`, `disparities_table`, `table1/2`, `forest_plot`,
  `multi_model_table`, `r2_sentence`, `interaction_sentences`, `min/max_table`, `strobe_flow`,
  `flow_diagram`. Correct.

**Wave 2–3 additional clears** (audited, no wrong-output defect): `kaplan_meier` (log-rank, at-risk,
survfit CIs), `payer_mix`, `caller_reliability` (Cohen's κ + Shrout-Fleiss ICC), `caller_drift`,
`missingness_mcar` (Little's test), `physician_age`, `acceptance_rate_calc` (Wilson CI),
`wait_time_by_group`, `parse_redcap_labels`, `genderize_physicians`, `medicaid_expansion` (all 50+DC,
dates), `acog_districts` (52 rows incl DC+PR), `hhi`/`kff_hhi_data` scaling, `county_covariates`/
`demographic_covariates` FIPS padding, `validate_phone` logic, `join_safety`, `merge_utils`,
`flag_date_outliers`, `flag_exclusion_discrepancy`/`flag_included_na_appointments`/
`flag_excluded_with_appointments`, `reconcile_specialty`, `remove_constant_vars`/`remove_near_zero_var`,
`sanity_checks`/`preflight_checks`/`mysterycall-quality`, `factor_utils`/`specialty_utils`,
`data_utils`, `scenario_summary`, `run_analysis`, `table1_gtsummary`, `combined_results_table`
(uses the *signed* irr_to_days `$table`, avoiding bug #1), `supplemental_tables`, `poisson_formula_maker`,
`manuscript_helpers` (correctly-gated paragraph), `results_paragraph`, `plot_emmeans_full`/
`plot_and_save_emmeans` (both `type="response"`), `format_pct`, `compare_waves`, `spatial_density`
(Haversine), `data_cache`, `download_large_file`, `utils-validation`, `utils-tempdir`,
`utils-logging`/`utils-pipe`/progress utils, `deprecated` shims, `no_longer_in_service`, all
theme/palette files (`bw_theme`, `green_journal`, `mysterycall-palette`), `plot_source_venn` (set math),
`plot_stacked_bar` (label positions), `plot_residuals`, `plot_distribution`, `facet_histogram`.

---

## Verification snippets

```r
# Bug 1 — signed table vs abs()'d sentence
m <- readRDS("<grace-ent>/model_output/models.rds")$wait
res <- mysterycall::mysterycall_irr_to_days(m, baseline_mean=23.05,
                                            exposure_col="ent_type", ref_group="General")
res$table[1, c("days_ci_lower","days_ci_upper")]  # -6.5, 11.4 (crosses zero)
res$sentences[1]                                   # "...95% CI 6.5 to 11.4 days..." (wrong)

# Bug 5 — format() turns NA into "NA"
format(c(1234567893, NA), scientific=FALSE, trim=TRUE)  # "1234567893" "NA"

# Bug 15 — numeric ZIP loses leading zero
stringr::str_extract(as.character(7001), "\\d{5}")      # NA  (should be "07001")

# Bug 3 — installed lacks NB-aware branch
any(grepl("is_nb", deparse(body(mysterycall::mysterycall_overdispersion_test))))  # FALSE (installed)

# Bug 43 / 5 — NA NPI becomes "NA" in the shared reader
sprintf("%.0f", c(1234567893, NA))                 # "1234567893" "NA"

# Bugs 31 / 32 — unanchored classifier substrings
grepl("india",  "Indiana University School of Medicine")   # TRUE  -> misclassified IMG
grepl("mexico", "University of New Mexico")                # TRUE  -> misclassified IMG
grepl("va ",    "nova southeastern medical center")        # TRUE  -> misclassified Government
grepl("penn",   "pennsylvania ent associates")             # TRUE  -> misclassified Academic

# Bug 33 — "Last, First" mis-parsed (first name lands in suffix)
mysterycall::mysterycall_parse_physician_name("Smith, John")  # first="Smith", last=NA, suffix="John"
```

---

## Audit provenance

All 205 files in `R/` were read. Bugs 1–4 from hands-on use; 5–21 from wave 1 (4 reviewers:
modeling, data/geo/NPI, stats/screening, reporting); 22–47 from waves 2–3 (6 reviewers:
rates/survival, data-integrity/joins, parsers/classifiers, sampling/scenario, remaining-logic
incl. `lmm.R`, cosmetic/infra). HIGH/MED-HIGH items were re-verified by hand against source;
MED/LOW items marked "reviewer-verified" were verified in-R by the reviewing agent.
