# rOpenSci Statistical Software Standards — Compliance Assessment

**Package:** `mysterycall` 1.6.3.9000 — *Mystery Caller Study Tools for Healthcare Access Research*
**Assessed:** 2026-11-22, at commit `55bf9cc` (`main`, clean working tree)
**Standards source:** `statistical-software-review-book` `main` branch, downloaded to `srr/` (`general.Rmd`, `regression.Rmd`, `eda.Rmd`, `spatial.Rmd`, `ml.Rmd`); canonical ID checklist in `srr/srr-standards.md`

## What the package is

`mysterycall` is a workflow toolkit for mystery-caller (secret-shopper / audit)
studies that measure healthcare access disparities. Its statistical core is
Poisson and negative-binomial generalized linear mixed models for wait-time
outcomes, reported as incidence rate ratios with Wald confidence intervals,
supported by overdispersion diagnostics, ICCs, Monte Carlo power curves,
missing-data MAR/MNAR tests, and bootstrap stability checks. Around that core
sit a provider-roster pipeline (NPI registry search, phone and name validation,
safe-join wrappers), area-level covariate joins (ADI, SVI, RUCA, Census), and a
reporting layer that emits publication-ready tables, CONSORT/STROBE flow
diagrams, and auto-generated manuscript prose. Address geocoding is present;
drive-time isochrones and mapping are deliberately delegated to the companion
`mysterymaps` package.

Scale at the time of assessment: 265 files in `R/`, 316 exports and 89 S3
methods in `NAMESPACE` (66 `print`, 19 `as.data.frame`, 3 `tidy`, 1 `plot`),
484 test files in `tests/testthat/`, 28 vignettes, 14 exported datasets, and
10 GitHub Actions workflows including coverage and a comprehensive nightly run.

## Categories assessed

All four categories requested by the maintainer were assessed in full:
**regression** (RE, 48 standards), **eda** (EA, 34), **spatial** (SP, 45), and
**ml** (ML, 90), on top of the 68 **General** (G) standards — 285 individual
standard IDs in total.

## Scoring convention

Every standard receives one verdict:

- **Y** — already satisfied, or clearly achievable with reasonable engineering
  effort given the current architecture. Compliance is assessed on *potential*,
  not current-code, compliance. Each `Y` below is additionally marked
  **already-done** or **feasible**; both count identically toward the
  proportion, but the distinction is where follow-up work lives.
- **N** — would require a fundamentally new capability that conflicts with, or
  sits well outside, the package's current statistical or architectural scope.
- **NA** — does not apply: the workflow stage is deliberately delegated
  elsewhere, or the concept is absent from the package's scope.

The reported proportion is **Y / (Y + N + NA)** — every standard counts in the
denominator. `NA` verdicts are *not* free passes: a category whose standards
mostly do not apply scores genuinely lower, which is the intent. Note that this
is deliberately more conservative than rOpenSci's own convention of excluding
developer-asserted `@srrstatsNA` standards, because at this pre-implementation
stage the `NA` calls here are the assessor's estimates rather than the
developer's assertions.

## Headline result

| Standards set | Y | N | NA | Total | Y / (Y+N+NA) |
|---|---|---|---|---|---|
| General (G) | 66 | 0 | 2 | 68 | **0.971** |
| EDA (EA) | 32 | 1 | 1 | 34 | **0.941** |
| Regression (RE) | 43 | 2 | 3 | 48 | **0.896** |
| Spatial (SP) | 35 | 1 | 9 | 45 | **0.778** |
| Machine Learning (ML) | 69 | 6 | 15 | 90 | **0.767** |

---

## General Standards (G)

68 standards assessed individually.

### Per-subsection counts

| Subsection | Y | N | NA | Total |
|---|---|---|---|---|
| Documentation (G1.0–G1.6) | 8 | 0 | 0 | 8 |
| Input Structures (G2.0–G2.16) | 29 | 0 | 0 | 29 |
| Algorithms (G3.0–G3.1a) | 1 | 0 | 2 | 3 |
| Output Structures (G4.0) | 1 | 0 | 0 | 1 |
| Testing (G5.0–G5.12) | 27 | 0 | 0 | 27 |
| **Total** | **66** | **0** | **2** | **68** |

**Proportion: 66 / 68 = 0.971**

### Per-standard verdicts

| ID | Verdict | Status | Evidence |
|---|---|---|---|
| G1.0 | Y | already-done | `@references` with published citations in `R/power_analysis.R:35` (Cochran 1977), `R/power_analysis.R:336` (Donner & Klar 2000), `R/icc.R:47`, `R/lmm.R:119`, `R/simple_poisson.R:44`, `R/impute_age.R:40` |
| G1.1 | Y | feasible | `README.md:289` "How mysterycall compares to alternatives" positions the package against `npi`/`humaniformat`, but no explicit novelty statement ("improvement on other R implementations") exists |
| G1.2 | Y | feasible | `README.md:8` carries a `lifecycle-stable` badge; no prose *Life Cycle Statement* in README or `CONTRIBUTING.md` |
| G1.3 | Y | already-done | `R/poisson_model.R` "Interpreting IRRs" and "Overdispersion" `@section` blocks define IRR and the mean=variance assumption; `vignettes/statistical-analysis.Rmd`, `vignettes/reporting-conventions.Rmd` |
| G1.4 | Y | already-done | Roxygen throughout; 316 exports in `NAMESPACE`, all with `.Rd` files checked into `man/` |
| G1.4a | Y | feasible | 57 files use `@keywords internal`, 9 use `@noRd`, but 38 files containing internal `.mc_*`-style functions carry neither tag |
| G1.5 | Y | feasible | `data-raw/make-readme-flow-figure.R`, `data-raw/make-readme-reporting-figure.R` reproduce README figures; no performance-claim reproduction scripts (no associated publication benchmarks yet) |
| G1.6 | Y | feasible | `README.md:289` compares *capabilities* with alternatives; tests call `stats::glm`/`MASS`/`pwr` for cross-checks, but there is no dedicated benchmark-vs-alternatives script |
| G2.0 | Y | already-done | `checkmate::` assertions in 72 files; explicit `length(x) != 1L` guards e.g. `R/flag_date_outliers.R:89` |
| G2.0a | Y | already-done | Roxygen documents scalar expectations verbatim, e.g. `R/poisson_model.R` "`outcome` Character scalar", `R/flag_date_outliers.R:20` "Non-negative integer" |
| G2.1 | Y | already-done | `checkmate::assert_*` type assertions across 72 files; `R/utils-validation.R:11` `validate_dataframe()`, `:43` `validate_scalar_positive_numeric()` |
| G2.1a | Y | already-done | Every `@param` names the expected type (e.g. `R/poisson_model.R` params enumerate character/numeric/integer) |
| G2.2 | Y | already-done | Scalar-ness enforced, e.g. `R/flag_date_outliers.R:89` `length(tolerance_days) != 1L` → `stop()` |
| G2.3 | Y | already-done | `match.arg` used in 49 files for constrained character input |
| G2.3a | Y | already-done | Same: `match.arg` is the standard idiom across the public API |
| G2.3b | Y | feasible | `ignore.case = TRUE` appears in places (`R/export_results_docx.R:68`); case sensitivity is neither uniformly normalised nor uniformly documented |
| G2.4 | Y | feasible | Explicit coercion helpers exist (`R/concordance.R:38` `.mc_coerce_binary`, `R/access_cascade.R:161` `.mc_coerce_stage`); not offered uniformly across entry points |
| G2.4a | Y | feasible | Integer literals (`0L`, `1L`) used throughout; `as.integer()` conversion not systematic at input boundaries |
| G2.4b | Y | feasible | Numeric validation present; explicit `as.numeric()` conversion path not systematic |
| G2.4c | Y | already-done | `R/concordance.R:51` uses `as.character()` (not `paste`) for list/vector coercion |
| G2.4d | Y | feasible | `R/factor_utils.R`, `R/collapse_rare.R` handle factors; explicit `as.factor()` conversion documented only in places |
| G2.4e | Y | feasible | Factor→character/numeric conversion happens ad hoc; not a documented uniform mechanism |
| G2.5 | Y | feasible | Factor predictors documented for reference-level behaviour (`R/poisson_model.R` `predictors` param) but `ordered` vs unordered expectations are not stated |
| G2.6 | Y | feasible | `R/resolve_col.R` normalises column access; one-dimensional inputs with exotic class attributes are not explicitly pre-processed |
| G2.7 | Y | already-done | `R/utils-validation.R:11` `validate_dataframe()` accepts any `data.frame`-like object; `tibble`/`data.frame` both flow through the dplyr-based pipeline |
| G2.8 | Y | already-done | `validate_dataframe()` + `R/resolve_col.R` normalise input before sub-functions; `R/preflight_checks.R` runs entry-point validation |
| G2.9 | Y | feasible | `R/caller_drift.R:241` warns when a date column cannot be coerced; lossy conversions generally are not announced |
| G2.10 | Y | already-done | Column extraction uses `[[ ]]` consistently with `R/resolve_col.R` resolving names, so behaviour does not depend on tabular class |
| G2.11 | Y | feasible | No `units`-package or other non-standard column-class handling found (`grep` for `units::` returns nothing); would need per-entry-point tolerance |
| G2.12 | Y | feasible | `is.list()` guards exist locally (`R/forest_plot.R:264`, `R/flow_spec.R:208`, `R/call_outcomes.R:25`) but no systematic list-column policy at data entry |
| G2.13 | Y | already-done | `R/nb_model.R:149` `stats::complete.cases()` pre-fit, with `R/nb_model.R:160` error when nothing remains; `R/missing_data_analysis.R`, `R/missingness_mcar.R` |
| G2.14 | Y | feasible | Current behaviour is fixed (drop + report); no `na_action`-style argument exists anywhere (`grep na_action|na.action` in `R/` returns nothing) |
| G2.14a | Y | feasible | Error-on-missing happens only when *all* rows are incomplete (`R/nb_model.R:160`); not user-selectable |
| G2.14b | Y | already-done | `mysterycall_poisson_model()`/`mysterycall_nb_model()` return `n_dropped` and report the count of rows removed for missingness |
| G2.14c | Y | already-done | `R/impute_calls.R:117` `mysterycall_impute_calls()`, `R/impute_age.R` `mysterycall_impute_age()`; `mice` in Suggests |
| G2.15 | Y | already-done | 189 explicit `na.rm = TRUE` call sites, e.g. `R/descriptive_stats.R:81-83` (`median`, `quantile`), `R/nb_model.R:121` |
| G2.16 | Y | feasible | Finiteness is checked in places but `NaN`/`Inf` handling is not a documented, uniform option |
| G3.0 | Y | already-done | `R/concordance.R:90` uses `isTRUE(all.equal(pe, 1))` rather than `==`; integer comparisons use `L` suffixes (`R/missingness_mcar.R:186` `== 0L`) |
| G3.1 | NA | — | The package performs no covariance computations of its own; variance-covariance matrices come from fitted `lme4`/`glmmTMB` objects (`R/random_effect_variance.R`, `lme4::VarCorr`), so there is no covariance algorithm for a user to choose |
| G3.1a | NA | — | Follows G3.1: there is no arbitrary covariance method to document |
| G4.0 | Y | already-done | `R/utils-io.R:28` parses `tools::file_ext(path)`; `R/export_results_docx.R:68-69` checks the `.docx` suffix (warns rather than auto-appending — tightening this is small work) |
| G5.0 | Y | already-done | Tests exercise exported reference datasets (`data/fips.rda`, `data/physicians.rda`, `data/taxonomy.rda`, `data/medicaid_expansion.rda`) and `datasets::` is an Import |
| G5.1 | Y | already-done | 14 datasets exported in `data/` with `LazyData: true`; `tests/fixtures/` holds additional shared fixtures |
| G5.2 | Y | already-done | 1,682 `expect_error()` and 104 `expect_warning()` assertions across 484 test files |
| G5.2a | Y | feasible | 1,027 `stop()` call sites; message uniqueness is not currently verified by any meta-test |
| G5.2b | Y | feasible | Coverage is broad but not demonstrably exhaustive per message; a message-inventory meta-test would close this |
| G5.3 | Y | feasible | Return-object structure is tested extensively; explicit "no `NA`/`NaN`/`Inf` in return" assertions are not systematic |
| G5.4 | Y | already-done | `tests/testthat/test-check-normality-gold-standard.R`, `test-scientific-ci-reference.R` test against fixed expected values |
| G5.4a | Y | already-done | Trivial/simple-case tests, e.g. `test-cov-model_comparison_table.R`, `test-sanity-checks.R` |
| G5.4b | Y | already-done | Tests call reference implementations directly: `test-overdispersion-test.R`, `test-marginal-effects.R`, `test-adversarial-marginal-methods.R`, `test-cov-model_metrics.R` compare against `stats::glm`/`MASS`/`pwr` |
| G5.4c | Y | already-done | `test-scientific-ci-reference.R` stores published reference CI values |
| G5.5 | Y | already-done | `set.seed()` present in 246 test files |
| G5.6 | Y | already-done | `test-lmm.R` and `test-study-invariance-and-rng.R` recover parameters from simulated data |
| G5.6a | Y | already-done | Recovery assertions use `tolerance = ` rather than exact equality |
| G5.6b | Y | feasible | `test-study-invariance-and-rng.R` varies seeds in places; multi-seed recovery is not the general pattern |
| G5.7 | Y | feasible | `R/power_curve.R`/`R/marginal_power.R` make this natural (vary n, check behaviour), but no test asserts convergence-with-data-size |
| G5.8 | Y | already-done | Edge-condition tests widespread (see G5.8a–c) |
| G5.8a | Y | already-done | 111 test files construct zero-row/zero-length inputs |
| G5.8b | Y | already-done | Unsupported-type inputs are asserted to error (part of the 1,682 `expect_error()` assertions) |
| G5.8c | Y | already-done | 35 test files build all-`NA`/constant columns; `R/remove_constant_vars.R`, `R/remove_near_zero_var.R` are directly tested |
| G5.8d | Y | feasible | Out-of-scope data (p > n for the GLMM screens) is not explicitly tested |
| G5.9 | Y | feasible | `test-concordance-robustness.R:339` uses `.Machine$double.eps`; noise susceptibility is not tested as a class |
| G5.9a | Y | feasible | Single `double.eps` instance only; not generalised across algorithms |
| G5.9b | Y | feasible | `test-study-invariance-and-rng.R` is the seed-invariance scaffold; coverage is partial |
| G5.10 | Y | feasible | No `MYSTERYCALL_EXTENDED_TESTS` flag exists (`grep EXTENDED_TESTS` finds nothing), but `.github/workflows/nightly.yaml` is exactly the right place to hang one |
| G5.11 | Y | feasible | `R/download_large_file.R` and `R/data_cache.R` already provide the fetch/cache machinery; no extended-test asset set is wired up yet |
| G5.11a | Y | already-done | `skip_if_offline()` in 18 places, `skip_on_cran()` in 110, `skip_if_not_installed()` in 1,512 — network/optional-dependency failures skip rather than fail |
| G5.12 | Y | feasible | `CONTRIBUTING.md` documents development setup and points to `ARCHITECTURE.md`; no extended-test runtime/platform/artefact section, and no `tests/README.md` |

### Key evidence and gaps

**Strongest already-done evidence.** Documentation and testing infrastructure are the package's strength. Every one of the 316 exports is roxygen-documented with `.Rd` files checked into `man/`, and statistical terminology is defined in prose where it is used — `R/poisson_model.R` carries dedicated "Interpreting IRRs" and "Overdispersion" `@section` blocks rather than leaving IRR undefined (G1.3). Input validation is real rather than nominal: `checkmate::` assertions appear in 72 files, `match.arg` in 49, and `R/utils-validation.R` centralises `validate_dataframe()`/`validate_required_columns()` so sub-functions receive a single normalised class (G2.7, G2.8). Missing-data handling is explicit and audited — `R/nb_model.R:149` runs `stats::complete.cases()` before fitting and the returned object reports `n` and `n_dropped` (G2.13, G2.14b). The test suite is unusually deep for an unreviewed package: 484 files, 1,682 `expect_error()` assertions, `set.seed()` in 246 files, parameter recovery with tolerances in `test-lmm.R`, and genuine cross-implementation checks against `stats::glm`, `MASS` and `pwr` (G5.4b) — a standard most submissions fail. Ten CI workflows including `test-coverage.yaml` (Codecov) and a `nightly.yaml` comprehensive run cover the infrastructure expectations.

**Feasible but currently missing — where follow-up work goes.** Four clusters account for nearly every non-already-done verdict. (1) *The `G2.4`/`G2.14` option surface*: the package coerces and drops missing rows with sensible fixed behaviour, but exposes no `na_action`-style argument anywhere (`grep` for `na_action|na.action` in `R/` returns nothing) and no uniform documented conversion mechanism — this is argument plumbing across entry points, not new statistics. (2) *Defensive tolerance for exotic columns*: G2.11/G2.12 (`units`-class columns, list columns) have only local `is.list()` guards (`R/forest_plot.R:264`, `R/flow_spec.R:208`) and no `units` handling at all; a shared pre-processing guard in `validate_dataframe()` would cover all 250 entry points at once. (3) *Extended tests*: G5.10–G5.12 are entirely unbuilt — no `MYSTERYCALL_EXTENDED_TESTS` flag, no `tests/README.md` — though `nightly.yaml`, `R/download_large_file.R` and `R/data_cache.R` are the scaffolding that makes it cheap. (4) *Test-class gaps*: noise susceptibility (G5.9, one `.Machine$double.eps` use in `test-concordance-robustness.R:339`), multi-seed recovery (G5.6b), p > n edge cases (G5.8d), and message-uniqueness verification across 1,027 `stop()` sites (G5.2a). Documentation-side, the two cheapest wins are a prose *Life Cycle Statement* (G1.2 — only a badge today) and `@noRd`/`@keywords internal` on the 38 files whose internal helpers carry neither tag (G1.4a).

**N verdicts.** None. No General standard requires a capability that conflicts with this package's architecture: it is a tabular-input, data-frame-output analysis package, which is precisely the shape the General standards assume.

**NA verdicts.** Two, both in Algorithms: **G3.1** and **G3.1a** (covariance algorithm choice and its documentation). The package computes no covariances itself — variance components are read off fitted `lme4`/`glmmTMB` objects via `lme4::VarCorr()` in `R/random_effect_variance.R` and `R/poisson_model.R` — so there is no covariance method for a user to select or for the docs to describe. Note this is a whole-subsection NA in the sense that it leaves G3.0 as the only live standard in "Algorithms".

---

## Regression and Supervised Learning Standards (RE)

48 standards assessed individually.

### Per-subsection counts

| Subsection | Y | N | NA | Total |
|---|---|---|---|---|
| Input data structures and validation (RE1.0–RE1.4) | 6 | 0 | 0 | 6 |
| Pre-processing and Variable Transformation (RE2.0–RE2.4b) | 7 | 0 | 0 | 7 |
| Algorithms (RE3.0–RE3.3) | 4 | 0 | 0 | 4 |
| Return Results (RE4.0–RE4.18) | 17 | 1 | 1 | 19 |
| Documentation (RE5.0) | 1 | 0 | 0 | 1 |
| Visualization (RE6.0–RE6.3) | 3 | 0 | 1 | 4 |
| Testing (RE7.0–RE7.4) | 5 | 1 | 1 | 7 |
| **Total** | **43** | **2** | **3** | **48** |

**Proportion: 43 / 48 = 0.896** — Y split: 20 already-done, 23 feasible. No whole subsection is NA.

### Per-standard verdicts

| ID | Verdict | Status | Evidence |
|---|---|---|---|
| RE1.0 | Y | feasible | Main fitters take character `outcome`/`predictors`/`random_intercept` (`R/poisson_model.R:110`), but formula-first entry points already exist: `mysterycall_compare_count_families(data, formula)` `R/advanced_models.R:34`, `mysterycall_test_interaction_effect()` `R/model_validation.R:14`, `mysterycall_create_formula()` `R/poisson_formula_maker.R:29` |
| RE1.1 | Y | feasible | Dummy-coding/reference-level rule documented (`R/lmm.R:31-33`, `R/poisson_model.R:33-35`) but no `model.matrix`/contrasts write-up; `stats::model.matrix` already used at `R/predict_appointment.R:125` |
| RE1.2 | Y | already-done | `@param` blocks state accepted types and reject others with tested errors: `R/poisson_model.R:131-146` ("must be numeric (count of days)", "requires counts >= 0") |
| RE1.3 | Y | already-done | `mysterycall_predict_appointment()` returns the caller's `newdata` with three columns appended, preserving all input columns (`R/predict_appointment.R:24-31`) |
| RE1.3a | Y | already-done | `R/marginal_effects.R:60` — "Row names are not set. No special class attributes are added." |
| RE1.4 | Y | already-done | `@section Overdispersion` `R/poisson_model.R:81-86`; `vignettes/statistical-analysis.Rmd:250-253` on linear-model assumption violations; violation *tested at runtime* via Shapiro-Wilk plus an auto-triggered Poisson sensitivity fit, `R/lmm.R:369-418` |
| RE2.0 | Y | already-done | `auto_log` applies `log1p()` on skewness > 1, documented with an explicit opt-out, and back-transforms to `gmr_table` (`R/lmm.R:40-46, 350-360`) |
| RE2.1 | Y | feasible | Hard-coded `stats::complete.cases()` with no `na_action` parameter and no `NA`/`NaN` vs `Inf` distinction (`R/poisson_model.R:160`, `R/nb_model.R:149`) |
| RE2.2 | Y | feasible | Complete-case mask spans outcome and predictors jointly (`R/poisson_model.R:157-160`); the prediction half already exists (`R/predict_appointment.R`), so separating the two is additive |
| RE2.3 | Y | feasible | Offsetting present as `offset_col` → `offset(log(...))` (`R/poisson_model.R:41-44, 215-219`); no centering/z-score parameter anywhere in `R/` |
| RE2.4 | Y | feasible | No collinearity screening exists (verified by grep across `R/` and `tests/`); `performance` is already an Import, so `check_collinearity()` is one call away |
| RE2.4a | Y | feasible | Same; the validation block at `R/poisson_model.R:124-205` already performs EPV/df checks and is the natural insertion point |
| RE2.4b | Y | feasible | Nothing checks outcome-predictor determinism; cheap to add alongside the existing negative-value and zero-count checks |
| RE3.0 | Y | already-done | `withCallingHandlers` captures `glmer` warnings; `model@optinfo$conv$lme4$messages` plus `isSingular()` reported (`R/poisson_model.R:238-271`) |
| RE3.1 | Y | already-done | Diagnostics emitted via `message()` (suppressible) while `$convergence = list(converged, singular, messages)` is persisted on the object (`R/poisson_model.R:263-271, 300-307`) |
| RE3.2 | Y | feasible | `nAGQ` default documented (`R/poisson_model.R:38-41`); optimizer tolerances are inherited from `lme4`/`glmmTMB` and never stated |
| RE3.3 | Y | feasible | `...` already forwards `control = lme4::glmerControl()` to `glmer` (`R/poisson_model.R:244`) and the pattern is used internally at `R/screen_predictors.R:259`, but it is undocumented as a user knob |
| RE4.0 | Y | already-done | `structure(list(...), class = "mysterycall_poisson_model")` `R/poisson_model.R:300-316`; same pattern for nb/lmm/logistic/gee/hurdle/auto |
| RE4.1 | **N** | — | The class contract is defined by a *completed* fit (`irr_table`, `overdispersion`, `convergence`, `aic`) and every consumer reads it unconditionally — `mysterycall_forest_plot()`, `mysterycall_irr_to_days()`, `mysterycall_icc()`, `mysterycall_predicted_means()`. An unfitted-spec object requires a second, parallel object contract |
| RE4.2 | Y | feasible | `coef(summary(model))` used internally (`R/poisson_model.R:276`) and `$model` is stored, but no `coef.mysterycall_*` S3 method is registered (`NAMESPACE` has none) |
| RE4.3 | Y | feasible | CIs computed and stored in `$irr_table$ci_lower`/`$ci_upper` (`R/poisson_model.R:278-288`); no `confint` method registered |
| RE4.4 | Y | already-done | `$formula` stored (`R/poisson_model.R:305`) and asserted in `tests/testthat/test-poisson-model.R` ("formula contains random intercept term"); a thin `formula()` method would complete it |
| RE4.5 | Y | already-done | `$n`, `$n_dropped`, `$n_clusters` (`R/poisson_model.R:306-308`), tested against the complete-case count |
| RE4.6 | Y | feasible | `stats::vcov` already imported and used for delta-method SEs (`R/predict_appointment.R:71,125`); `mysterycall_gee()` offers robust sandwich SEs with a `corstr` choice (`R/gee.R:13,27`); no `vcov` method on the wrappers |
| RE4.7 | Y | already-done | `$convergence$converged`/`$singular`/`$messages` (`R/poisson_model.R:300-307`); shape asserted in `test-poisson-model.R` |
| RE4.8 | Y | already-done | Response recoverable from the stored fit — `model.response(model.frame(fit))` at `R/model_metrics.R:49`; `$outcome_original`/`$outcome_used` metadata on the LMM (`R/lmm.R:74-80`) |
| RE4.9 | Y | already-done | `mysterycall_predicted_means()` returns response-scale predicted means with SE and CI (`R/predicted_means.R:27-35`); `fitted()` used at `R/model_metrics.R:49`, `R/lmm.R:657` |
| RE4.10 | Y | already-done | `mysterycall_plot_residuals()` returns DHARMa quantile residuals or Pearson panels and documents handing them to `DHARMa::testDispersion()` (`R/plot_residuals.R:26-40`); `mysterycall_overdispersion_test()` documents the `residuals(type = "pearson")` contract (`R/overdispersion_test.R:22`) |
| RE4.11 | Y | already-done | `$aic`/`$bic`/`$overdispersion` (`R/poisson_model.R:314-315`), `$r_squared` marginal and conditional (`R/lmm.R:87-88`), plus `mysterycall_icc()` and `mysterycall_model_metrics()` MAE/RMSE |
| RE4.12 | Y | already-done | `log1p()` → `exp()` geometric-mean-ratio back-transform (`R/lmm.R:350-360`); `mysterycall_irr_to_days()` inverts the IRR scale to absolute days with the formula documented (`R/irr_to_days.R:12-13`) |
| RE4.13 | Y | already-done | `$factor_refs` records the reference level per factor/character predictor (`R/poisson_model.R:208-217`), printed by `print.mysterycall_poisson_model` and tested |
| RE4.14 | Y | already-done | Delta-method CIs on new profiles (`R/predict_appointment.R:99-130`); `predict(..., se.fit = TRUE)` ribbon at `R/advanced_models.R:137-141` |
| RE4.15 | NA | — | No forecasting or time-horizon modelling anywhere (grep for forecast/horizon/extrapolat across `R/` returns only unrelated word hits); predictors are categorical caller/payer/scenario factors, so there is no horizon along which errors could grow |
| RE4.16 | Y | already-done | `allow_new_levels = TRUE` default on `mysterycall_predict_appointment()`, documented as handling "new practice names" and passed to `allow.new.levels` (`R/predict_appointment.R:19-20, 96-98`) |
| RE4.17 | Y | already-done | 66 registered `print.mysterycall_*` methods; `print.mysterycall_poisson_model` shows n, clusters, AIC/BIC, convergence flags, reference levels and the IRR table (`R/poisson_model.R:352-402`) |
| RE4.18 | Y | feasible | No `summary.*` method exists anywhere (grep on `R/` and `NAMESPACE`); `mysterycall_bootstrap_ci()` (`R/bootstrap_ci.R:49`) is exactly the computationally non-trivial case the standard names |
| RE5.0 | Y | feasible | No benchmark or scaling documentation in any of the 28 vignettes (grep for benchmark/system.time/scaling over `vignettes/` returns nothing); a timings vignette is purely additive |
| RE6.0 | Y | feasible | Only `plot.mysterycall_lmm` is registered; poisson/nb/logistic/gee/hurdle/auto objects have no `plot` method |
| RE6.1 | Y | feasible | `mysterycall_irr_plot()` (`R/irr_plot.R:57`) and `mysterycall_forest_plot()` (`R/forest_plot.R:81`) accept the model objects directly, but no `plot.mysterycall_poisson_model` stub redirects users there |
| RE6.2 | Y | feasible | `plot.mysterycall_lmm` draws Q-Q and residuals-vs-fitted, not fitted values with CIs (`R/lmm.R:650-698`); the CI-bearing fitted values already exist in `mysterycall_predicted_means()` |
| RE6.3 | NA | — | Follows RE4.15: no interpolated-vs-extrapolated distinction exists because nothing forecasts |
| RE7.0 | Y | feasible | All fixtures are `rpois`/`rnorm`/`rnbinom` draws (`tests/testthat/test-poisson-model.R:1-11`, `test-adversarial-auto-model.R:20-45`); no perfectly collinear predictor fixture |
| RE7.0a | Y | feasible | No rejection test for noiseless/collinear input — matches the absent RE2.4 screening |
| RE7.1 | Y | feasible | No fixture with a deterministic outcome-predictor relationship; existing assertions are structural (`irr == exp(estimate)`, CI ordering, column names) rather than parameter recovery |
| RE7.1a | **N** | — | Would require asserting a wall-clock inequality over third-party optimizers the package does not own (`lme4::glmer` `R/poisson_model.R:240`, `glmmTMB` `R/nb_model.R`). Noiseless counts in a random-intercept GLMM typically trigger `isSingular()` and optimizer retries, so the "noiseless fits no slower" claim is neither guaranteed nor stable across platforms and BLAS builds |
| RE7.2 | Y | feasible | No test asserts row/case-name retention; `mysterycall_predict_appointment()` already preserves input columns, so the assertion is cheap |
| RE7.3 | Y | feasible | Grep for `coef(`/`confint(`/`nobs(`/`vcov(` across the poisson/lmm/nb/logistic test files returns no accessor tests; blocked behind RE4.2–RE4.6 methods existing |
| RE7.4 | NA | — | Extends RE4.15, which is NA |

### Key evidence and gaps

**Strongest already-done evidence.** The Algorithms and Return Results blocks look
deliberately engineered rather than incidental. `mysterycall_poisson_model()`
wraps the `glmer` call in `withCallingHandlers`, harvests both
`model@optinfo$conv$lme4$messages` and muffled warnings, surfaces them through
`message()` so users can suppress them, and still persists
`$convergence = list(converged, singular, messages)` on the returned object —
one construction that discharges RE3.0, RE3.1 and RE4.7 cleanly, with the object
shape asserted in `tests/testthat/test-poisson-model.R`. RE2.0 is unusually well
covered for a package that has done no srr work: `mysterycall_lmm()`'s `auto_log`
applies `log1p()` only on measured skewness, documents the trigger, exposes
`auto_log = FALSE` to defeat it, and returns both scales (`coef_table` plus
`gmr_table`) — which also discharges RE4.12 alongside `mysterycall_irr_to_days()`'s
documented IRR-to-absolute-days inversion. RE4.16 is a genuine non-obvious hit:
`mysterycall_predict_appointment(allow_new_levels = TRUE)` is explicitly documented
as handling practices unseen at fit time, and its delta-method CIs carry RE4.14.
RE1.4 is met through prose *and* behaviour — the LMM runs a Shapiro-Wilk test and
auto-triggers a Poisson sensitivity fit, which is an actual runtime test of an
assumption violation rather than a paragraph about one.

**Feasible but currently missing — where follow-up work goes.** Three clusters.
(1) *The accessor layer.* `NAMESPACE` registers 66 `print`, 19 `as.data.frame`
and 3 `tidy` methods — and not a single `coef`, `confint`, `formula`, `nobs`,
`vcov` or `summary` method (verified directly). Every ingredient is already on
the object (`$irr_table`, `$formula`, `$n`, `$model`), so RE4.2, RE4.3, RE4.6,
RE4.18 and the RE7.3 tests that depend on them are mechanical work, not
redesign. (2) *Missing-data and collinearity control.* The complete-case filter
is hard-wired over outcome and predictors jointly (`R/poisson_model.R:160`) with
no `na_action` parameter and no `Inf`/`NaN` separation, and nothing anywhere
screens for perfect collinearity; RE2.1, RE2.2, RE2.4a/b, RE7.0, RE7.0a and
RE7.1 all trace back to those two gaps, and `performance` is already an Import.
(3) *Visualization dispatch.* Only `plot.mysterycall_lmm` exists, so `plot()` on
a Poisson or NB fit falls through even though `mysterycall_irr_plot()` and
`mysterycall_forest_plot()` already accept those exact classes (RE6.0–RE6.2).

**N verdicts (2).** **RE4.1** (model object without fitting) conflicts with the
class contract: `mysterycall_poisson_model` objects are *defined* by `irr_table`,
`overdispersion`, `aic` and `convergence`, and four downstream consumers read
those fields unconditionally, so a deferred-fit mode means maintaining a second
parallel contract for a workflow where models fit in seconds. **RE7.1a** asks the
suite to assert that noiseless data fits at least as fast as noisy data, but all
fitting is delegated to `lme4`/`glmmTMB`; noiseless counts typically trigger
singular fits and optimizer retries, making the inequality neither guaranteed
nor platform-stable.

**NA verdicts (3).** **RE4.15**, **RE6.3** and **RE7.4** form one coherent group
gated by the standards' own precondition that extrapolation be "reasonably
unambiguously identifiable". A grep for forecast/horizon/extrapolat across all
265 `R/` files returns only unrelated word matches, and the predictors are
categorical payer/scenario/caller factors with no horizon dimension. Note that
RE4.14 remains **Y** rather than NA because prediction errors genuinely are
provided — it is specifically the *horizon-monotonicity* claims that are
inapplicable. No whole subsection is NA.

### Architectural fit

The fit is good but off-centre in one systematic way. Everything the RE category
cares about statistically is present and thoughtfully built: real link-function
model families, convergence diagnostics, dispersion checks, effect sizes with
CIs, marginal effects, residual diagnostics, ICC, predicted means, bootstrap
CIs, LRT model comparison — and the package already returns properly classed
model objects that retain the underlying `glmerMod`/`glmmTMB` fit, which is
exactly what RE4.0 asks for and what makes most remaining Y-feasible verdicts
cheap. The mismatch is interface idiom: RE assumes the canonical R modelling
API (formula in; `coef`/`confint`/`vcov`/`summary`/`plot` out), whereas
mysterycall's primary idiom is "character column names in, fully-rendered
manuscript artifact out" — an IRR table, a forest plot, a results paragraph.
That makes it a *reporting pipeline around* a regression core rather than a
regression package in the `lm` mould, which is why so many verdicts read "the
data is on the object but there is no method for it". None of that conflicts
with the RE category; a submission would need a deliberate accessor-and-dispatch
layer bolted onto existing objects plus a missing-data/collinearity
preprocessing contract, with no change to the statistics. Forecasting is the
only part of RE the design genuinely has nothing to say about, and that is a
legitimate NA rather than a weakness.

---

## EDA Standards (EA)

34 standards assessed individually.

### Per-subsection counts

| Subsection | Y | N | NA | Total |
|---|---|---|---|---|
| Documentation Standards (EA1.0–EA1.3) | 4 | 0 | 0 | 4 |
| Input Data (EA2.0–EA2.6, incl. index columns, multi-tabular, classes) | 8 | 1 | 0 | 9 |
| Analytic Algorithms (EA3.0–EA3.1) | 2 | 0 | 0 | 2 |
| Return Results / Output Data (EA4.0–EA4.2) | 3 | 0 | 0 | 3 |
| Visualization and Summary Output (EA5.0–EA5.6) | 8 | 0 | 1 | 9 |
| Testing (EA6.0–EA6.1) | 7 | 0 | 0 | 7 |
| **Total** | **32** | **1** | **1** | **34** |

**Proportion: 32 / 34 = 0.941** — Y split: 18 already-done, 14 feasible. No whole subsection is NA.

### Per-standard verdicts

| ID | Verdict | Status | Evidence |
|---|---|---|---|
| EA1.0 | Y | already-done | `README.md` Statement of Need: "The target users are clinical researchers and health-services researchers who conduct mystery-caller or audit studies and need reproducible, auditable workflows" |
| EA1.1 | Y | already-done | README Statement of Need (provider rosters, call outcomes, NPI records, Census covariates) plus `inst/glossary.md`, which defines "Phase 1 data" and "Phase 2 data" as the two input tables |
| EA1.2 | Y | already-done | `vignettes/table-generation.Rmd:30-60` states what each table communicates and to whom; `vignettes/writing-results-section.Rmd:28-35` frames the associative/disparity question explicitly |
| EA1.3 | Y | feasible | Uneven: `R/table1.R:265-267` documents input kinds well ("Numeric columns are treated as continuous; all others are categorical"), but `R/wait_time_by_group.R:7` and `R/categorical.R:76` say only "`@param data` A data frame." |
| EA2.0 | Y | already-done | `R/join_safety.R` — the safe-join family (`mysterycall_safe_left_join`/`_inner`/`_semi`/`_anti`) keyed on an explicit required `by`, with NPI as the canonical index and `by_columns` recorded in the CSV audit report via `.write_join_report()` |
| EA2.1 | Y | feasible | `mysterycall_assert_unique_keys()` runs by default (`expect_unique_right = TRUE`) on join paths and `R/preflight_checks.R:571` counts duplicates — but no EDA entry point (`mysterycall_table1()`, `mysterycall_disparities_table()`) affirms index uniqueness on input |
| EA2.2 | Y | feasible | Satisfiable by either sub-route below; keys currently travel as `by`/`id_col` arguments (23 `R/` files use `id_col`/`npi_col`) rather than as declared index metadata |
| EA2.2a | Y | feasible | A class system already exists to hang this on: `R/prepare_calls.R:266-275` returns `structure(..., class = "mysterycall_prepared")`; it simply carries no index slot yet |
| EA2.2b | Y | feasible | `grep 'attr(.*"index")'` over `R/` returns nothing. Survivability was tested directly: an `attr(x, "index")` on a data frame survives `dplyr::filter`, `mutate`, `left_join` and `as_tibble` under this package's dplyr version, so the attribute route is not blocked by the pipeline |
| EA2.3 | Y | already-done | `R/join_safety.R` — `by` is mandatory in all four wrappers (`stop("`by` is required. Specify join column(s) or use dplyr::join_by().")`), and `.resolve_by()` handles named vectors and `join_by()`, so nothing is inferred from column names |
| EA2.4 | **N** | — | No relational class system: multi-table input arrives as bare data-frame pairs (`mysterycall_safe_*_join(left, right)`; `R/matched_controls.R:27` "present in both frames") across roughly 49 join sites. See justification below |
| EA2.5 | Y | feasible | `mysterycall_safe_inner_join(expect_unique_both = TRUE)` already asserts key uniqueness on *both* tables; extending the EA2.2 declared-index work to each table is the same change |
| EA2.6 | Y | already-done | Verified empirically: `mysterycall_plot_distribution(structure(1:30, class = "notvector", extra = "a"))` returns plots, and `mysterycall_descriptive_stats()` on a `class = "notvector"` column returns median 10.5 |
| EA3.0 | Y | already-done | `mysterycall_auto_model()` (`R/auto_model.R:79`) automates Poisson-vs-NB selection and returns `$selection` with a `reason`; `mysterycall_screen_predictors()` (`R/screen_predictors.R:129`); `mysterycall_abstract_numbers()` auto-extracts OR/IRR/beta from fitted objects into an abstract sentence (`R/abstract_numbers.R:30-80`) |
| EA3.1 | Y | already-done | `mysterycall_model_comparison_table()` (`R/model_comparison_table.R:41`) standardizes multi-model comparison; `mysterycall_disparities_table()` standardizes reference-group comparison (rate, CI, abs_diff, rel_risk, RR CI, p) under one contract; `mysterycall_literature_table()` standardizes comparison against prior studies |
| EA4.0 | Y | feasible | Verified inconsistency: `mysterycall_table_percentages()` preserves input class (tibble in → `tbl_df` out; data.frame in → data.frame out), but `mysterycall_disparities_table()` always returns `data.frame` and `mysterycall_table1()$table` is always `tbl_df`, regardless of input |
| EA4.1 | Y | already-done | `digits`-style parameters in 64 of 265 `R/` files: `mysterycall_table1(digits = 1L)` (`R/table1.R:338`), `mysterycall_wait_time_by_group(digits_median, digits_q)` (`R/wait_time_by_group.R:55-56`), `mysterycall_descriptive_stats(digits, digits_q)`, `mysterycall_table2(digits = 2L)`. Gap: `mysterycall_disparities_table()` has none |
| EA4.2 | Y | feasible | 66 `print` methods registered including `print.mysterycall_table1` (`R/table1.R:487`) and `print.mysterycall_disparities_table` (`R/disparities_table.R:297`); but `getS3method("plot", "mysterycall_table1")` fails, only `plot.mysterycall_lmm` is registered, `mysterycall_plot_disparities()` is not wired up as a `plot` method, and there are no `summary` methods |
| EA5.0 | Y | already-done | `R/green_journal.R:1-10` header states the accessibility spec it implements (Arial/sans 8–12 pt, 6 pt minimum; Okabe-Ito colorblind-safe; no gray panel) |
| EA5.0a | Y | feasible | Defaults are reasonable but unharmonized and justified in only one place: `R/green_journal.R:33-34` documents the pt range, while `plot_raincloud.R:65` uses 13, `plot_emmeans_full.R:176` uses 14, `forest_plot.R:214` 11, `plot_disparities.R:267` 11, `bw_theme.R:32` 12 |
| EA5.0b | Y | already-done | `mysterycall_palette_green_journal()` (`R/green_journal.R:172-215`) is Okabe-Ito with the Wong (2011) `\doi{10.1038/nmeth.1618}` citation and documented deuteranopia/protanopia/tritanopia plus grayscale safety; `create_density_plot.R:92` uses `scale_fill_viridis_d()`. Gap: `mysterycall_standard_palette("primary")` (`R/mysterycall-palette.R:40-47`) is not accessibility-verified |
| EA5.1 | Y | already-done | `mysterycall_theme_green_journal(base_family = "Arial")` (`R/green_journal.R:47-55`) overrides the typeface with a documented journal-accessibility rationale and falls back to `"sans"` when Arial is unavailable |
| EA5.2 | Y | already-done | 1,237 `sprintf`, 272 `round(` and 31 `formatC` calls across `R/`; `print.mysterycall_disparities_table` (`R/disparities_table.R:303-327`) formats every numeric via `sprintf("%.1f%%")`, `"%+.1f pp"`, `"%.2f (%.2f to %.2f)"`; `.t1_fmt_pct`/`.t1_fmt_median_iqr` (`R/table1.R:52-85`) build format strings from `digits` |
| EA5.3 | Y | feasible | No summary reports column `storage.mode`/`class`: `grep storage.mode R/` returns nothing, and `mysterycall_table1()$table` rows carry only `variable`/`level`. (`print.mysterycall_table1` delegates to `print.tbl_df`, the standard's own exemplar, so the *output* table's types show — the *input* columns' classes are never reported) |
| EA5.4 | Y | feasible | Partial: `pretty()` at `R/kaplan_meier.R:373`, `scales::percent_format(accuracy = 1)` at `plot_disparities.R:255`, `power_curve.R:153`, `kaplan_meier.R:438`, and `round(100*v)` at `cumulative_access_curve.R:128`; most other plots (`facet_histogram.R`, `log_histogram.R`, `create_scatter_plot.R`) rely on ggplot2 defaults with no explicit rounding |
| EA5.5 | Y | feasible | Partial: `R/cumulative_access_curve.R:131-136` labels axes "Business days since call" / "Cumulative proportion of calls with an appointment", and `mysterycall_standard_labels()` (`R/mysterycall-palette.R:16-27`) supplies unit-bearing labels ("Call Duration (minutes)") — but `create_density_plot.R:80` defaults `x_label` to the bare column name and nothing wires `mysterycall_standard_labels()` into the plot functions |
| EA5.6 | NA | — | No bundled dynamic-visualization library: `find . -name "*.js"` (excluding `.git`/`docs`) returns nothing, and `leaflet`/`DiagrammeR` appear only under `Suggests:` and are called as ordinary dependencies — nothing is re-bundled, so there is nothing to explain |
| EA6.0 | Y | already-done | 484 test files in `tests/testthat/`; return values of table, plot and summary functions are asserted throughout (see sub-items) |
| EA6.0a | Y | already-done | 995 `expect_s3_class` plus 592 `expect_type` calls; e.g. `tests/testthat/test-cov-table1.R:33` asserts `"mysterycall_table1"`, `test-cov-plot_distribution.R:33-35` |
| EA6.0b | Y | already-done | 597 `expect_equal(nrow(...))` plus 44 `expect_equal(ncol(...))`; e.g. `tests/testthat/test-table-functions-gold-standard.R:11-16` asserts `nrow(result) == 1L` |
| EA6.0c | Y | already-done | 149 `expect_named` calls; `test-cov-table1.R:48-50` checks `variable`/`level`/`Overall`; `test-cov-plot_distribution.R:32` checks `c("raw", "sqrt_transformed")` |
| EA6.0d | Y | feasible | Partial: 144 `expect_true(is.numeric(...))`, 92 `is.character(`, 76 `expect_s3_class(result$...)` assert individual columns, but no test enumerates the class of *all* columns of a returned data frame |
| EA6.0e | Y | already-done | 165 `tolerance` usages; `test-table-functions-gold-standard.R:27` asserts `result$percent == rep(100/3, 3)` within `1e-6` and `:60` against a hand-counted gold standard (63/862) |
| EA6.1 | Y | feasible | `vdiffr` is absent from DESCRIPTION and no figure snapshots exist; plot tests assert only `expect_s3_class(result, "ggplot")` (`test-plot-functions-invariants.R:33`). Property testing is started but rare: `test-log-histogram.R:132,149` use `ggplot2::ggplot_build()`, `test-irr-plot.R:27` uses `layer_data()` |

### Key evidence and gaps

**Strongest already-done evidence.** Three clusters. First, numeric formatting
and precision control: 1,237 `sprintf`, 272 `round(` and 31 `formatC` calls, a
`digits`-style parameter in 64 of 265 `R/` files, and print methods such as
`print.mysterycall_disparities_table` that format every numeric explicitly —
EA4.1 and EA5.2 are satisfied about as thoroughly as one could ask. Second,
accessibility: `R/green_journal.R` implements Okabe-Ito with the Wong (2011)
DOI, documents the 8–12 pt (6 pt minimum) typeface range it targets, and falls
back from Arial to `"sans"` gracefully, covering EA5.0, EA5.0b and EA5.1
outright. Third, testing: 484 test files with 995 `expect_s3_class`, 597
`expect_equal(nrow(...))`, 149 `expect_named` and 165 `tolerance` usages,
including genuine hand-computed gold standards
(`test-table-functions-gold-standard.R:60` asserts 63/862 against the bundled
taxonomy dataset) — EA6.0a–c and EA6.0e are already met. `R/join_safety.R`
deserves separate mention: a mandatory `by`, default right-side uniqueness
assertion, coverage and fan-out thresholds, and a CSV audit record make EA2.0,
EA2.3 and most of EA2.1 a solved problem rather than an aspiration.

**Feasible but currently missing — where follow-up work goes.** EA4.2 is the
cheapest high-value fix: 66 `print` methods exist but
`plot.mysterycall_disparities_table` is simply unregistered even though
`mysterycall_plot_disparities()` already produces the figure, and
`getS3method("plot", "mysterycall_table1")` fails. EA4.0 is a real inconsistency
confirmed by running the code — `mysterycall_table_percentages()` round-trips
the input class while `mysterycall_disparities_table()` always downgrades to
`data.frame` and `mysterycall_table1()$table` always upgrades to `tbl_df`.
EA6.1 is the biggest testing hole: every plot test stops at
`expect_s3_class(result, "ggplot")`, only three files reach into
`ggplot_build()`/`layer_data()`, and `vdiffr` is not a dependency at all. EA5.5
and EA5.3 are small mechanical jobs for which the tooling already exists and was
then not wired up: `mysterycall_standard_labels()` holds unit-bearing axis labels
that no plot function consumes, and a `class`/`storage.mode` column on the
Table 1 summary is a handful of lines.

**N verdict (1).** **EA2.4** (multi-tabular input via a relational class). This
is an N rather than an NA because the standard is genuinely triggered — the
package accepts multi-table input in earnest, with four exported safe-join
wrappers taking `(left, right)` data-frame pairs, `mysterycall_matched_controls()`
documenting an `id_col` "present in both frames", and roughly 49 join call sites
across `R/` operating on table pairs. Complying would mean demanding a `dm`-style
relational class on input, replacing the plain-data-frame contract that all 316
exports and 28 vignettes are written against, and which the safe-join design
deliberately rejects in favour of per-call key declaration plus coverage
auditing. That is a different input contract, not a missing feature.

**NA verdict (1).** **EA5.6** (explaining re-bundled dynamic-visualization
libraries) is a clean NA: there is no `.js` file anywhere in the package, no
`htmlwidgets` dependency, and `leaflet`/`DiagrammeR` sit in `Suggests` as
ordinary consumers, so nothing is re-bundled.

A second N was looked for deliberately. The leading candidate was EA2.2b, on the
theory that an `attr(x, "index")` would be destroyed by this package's
dplyr-heavy pipeline — but testing showed the attribute survives `filter`,
`mutate`, `left_join` and `as_tibble`, so that verdict became Y/feasible. EA5.3
and EA4.0 carry a real but surmountable tension with the publication-table
output contract (cells are deliberately formatted character strings, and a
journal table cannot carry `<chr>`/`<dbl>` annotations); print-path-only
compliance keeps both at Y.

### Architectural fit

The fit is strong but asymmetric. On the **output** side mysterycall is an
excellent EA citizen: its reason for existing is descriptive tables, disparity
summaries, distribution plots and auto-generated results prose; it has a
palette-and-theme layer with a cited accessibility basis; it has 66 print
methods and a `digits` parameter nearly everywhere; and
`mysterycall_auto_model()` / `mysterycall_abstract_numbers()` are exactly the
"meta-level automated extraction" EA3.0 asks for and that most candidate
packages struggle to demonstrate. On the **input** side it is the opposite of
what the EA category envisages. The EA standards imagine general-purpose EDA —
universal input handling, "accept and appropriately transform as many diverse
kinds of input data as possible", index columns as a first-class declared
concept. mysterycall instead requires named domain columns (`outcome_col`,
`group_col`, `insurance`, `wait_days`, `npi`), binary 0/1 outcomes, and a
specific long/paired structure in which an NPI deliberately appears more than
once (`R/clean_phase_1_results.R:29-30` duplicates rows to build the paired
insurance design, so the unique key is compound rather than a single index
column). That is a study-design toolkit with an EDA surface, not an EDA engine.
The practical consequence is that nearly all remaining EA work sits in the Input
Data subsection plus EA4.0/EA5.3/EA6.1 — and that a reviewer may reasonably ask
whether a package whose descriptive functions accept only one domain-specific
table shape belongs in EA at all. The answer the package can make is that its
EDA *outputs*, not its input genericity, are the contribution, and that EA3.0
and EA3.1 — the two standards asking what the software automates that reference
implementations do by hand — are already met convincingly.

---

## Spatial Standards (SP)

45 standards assessed individually.

### Per-subsection counts

| Subsection | Y | N | NA | Total |
|---|---|---|---|---|
| Spatial Domains (SP1.0–SP1.1) | 2 | 0 | 0 | 2 |
| Input data structures and validation (SP2.0–SP2.9) | 16 | 0 | 0 | 16 |
| Algorithms (SP3.0–SP3.6) | 4 | 1 | 4 | 9 |
| Return Results (SP4.0–SP4.2) | 5 | 0 | 0 | 5 |
| Visualization (SP5.0–SP5.3) | 1 | 0 | 3 | 4 |
| Testing (SP6.0–SP6.6) | 7 | 0 | 2 | 9 |
| **Total** | **35** | **1** | **9** | **45** |

**Proportion: 35 / 45 = 0.778** — Y split: 11 already-done, 24 feasible. Visualization is a near-wholly NA subsection (3 of 4).

### Per-standard verdicts

| ID | Verdict | Status | Evidence |
|---|---|---|---|
| SP1.0 | Y | feasible | Geographic/curvilinear domain is implicit only — `assign_area_covariates.R:25` says "decimal degrees (WGS84)", `spatial_density.R:5` says "Haversine formula for spherical distance"; no package-level domain statement in `README.md` |
| SP1.1 | Y | feasible | 2-D lat/long throughout (`spatial_density.R:7-8`, `geocode_address.R:34-38`); no elevation or 3-D anywhere; needs one documented sentence |
| SP2.0 | Y | feasible | Accepts bare data frames with numeric coordinate columns (`mysterycall_assign_area_covariates`, `assign_area_covariates.R:49-55`; `mysterycall_calculate_spatial_density`, `spatial_density.R:20`); `sf` is already in Suggests and used (`hhi.R:96`), so accepting `sf` input is a small change |
| SP2.0a | Y | feasible | No new spatial class exists today; documenting `sf::st_as_sf()` conversion is a docs task (likely vacuous if the SP2.0 route is "accept `sf`") |
| SP2.0b | Y | feasible | Structural errors exist (`spatial_density.R:21-23`, `geocode_address.R:58-61` checkmate), but **no coordinate-domain check anywhere** — grep found no lat ∈ [-90, 90] / lon ∈ [-180, 180] assertion in `R/` (independently re-verified) |
| SP2.1 | Y | already-done | `grep "sp::\|CRS(\|proj4"` over `R/` returns nothing; spatial deps are `sf` plus `tigris` (`hhi.R:88-99`, `green_journal.R:405`) |
| SP2.2 | Y | feasible | Parent of SP2.2a/b; `tigris::core_based_statistical_areas()` plus `sf::st_drop_geometry()` interop already present at `hhi.R:96-98` |
| SP2.2a | Y | feasible | `vignettes/adding-covariates.Rmd` and `get_census_data.Rmd` show no `sf`/`tigris`/`tidycensus` spatial workflow; `README.md:102-106` points that path at `mysterymaps` |
| SP2.2b | Y | feasible | No test round-trips package output into `sf`; one `skip_if_not_installed("sf")` test over `mysterycall_geocode_address()` output would do it |
| SP2.3 | Y | feasible | All bundled spatial data are R data frames via `LazyData` (`fips.R`, `zcta_tract_xwalk.R`); no GeoJSON or shapefile example — shipping one in `inst/extdata` is trivial |
| SP2.4 | Y | already-done | The only CRS object in the package is `sf::st_crs(5070)` (`green_journal.R:405`), an EPSG code that sf renders as WKT2 under PROJ ≥ 6 |
| SP2.4a | Y | already-done | No PROJ4 string in the codebase (`grep "+proj=\|proj4"` is empty) |
| SP2.5 | Y | feasible | Coordinates carried as bare numerics; CRS asserted in prose only (`assign_area_covariates.R:25`), not as object metadata — accepting `sf` supplies it for free |
| SP2.5a | Y | feasible | As SP2.0a — no new input class to convert from yet |
| SP2.6 | Y | already-done | Every `@param` names its expected type: `assign_area_covariates.R:23-29`, `spatial_density.R:7-13`, `geocode_address.R:17-32` |
| SP2.7 | Y | already-done | `checkmate::assert_data_frame`/`assert_subset`/`assert_int` at `geocode_address.R:58-61` and `assign_area_covariates.R:54-56`; explicit `stop()` guards at `spatial_density.R:21-33` (coordinate-range check still absent — see SP2.0b) |
| SP2.8 | Y | feasible | No single pre-processor: each function coerces independently (`as.numeric(data[[lat_col]])` at `assign_area_covariates.R:58-59`; `toupper(trimws())` at `geocode_city_state.R:31-32`) and the haversine is duplicated in `geocode_city_state.R:63` and `spatial_density.R:36-54` |
| SP2.9 | Y | feasible | Input frame preserved wholesale with columns appended (`assign_area_covariates.R:114-123`, `geocode_address.R:114-120`) plus an attribute (`attr(data, "coverage")`); CRS metadata would follow once SP2.5/SP2.8 land |
| SP3.0 | Y | already-done | `mysterycall_calculate_spatial_density(radius = 15)` (`spatial_density.R:13, 20`) and `caliper_miles` in `matched_controls.R:33` give users control of neighbourhood size |
| SP3.0a | NA | — | No regular grid or raster anywhere (`grep "terra::\|stars::"` is empty; "raster" hits are all image DPI), so rook/queen adjacency has no referent |
| SP3.0b | Y | already-done | Irregular-space neighbourhood controlled by a distance-defined area: `radius` miles at `spatial_density.R:13`, applied at `spatial_density.R:57` |
| SP3.1 | Y | feasible | `sum(dists <= radius, na.rm = TRUE)` (`spatial_density.R:57`) is exactly a uniform-weight circular cut-off; a `weight_fn` argument on that loop is a few lines |
| SP3.2 | Y | feasible | `mysterycall_matched_controls()` samples under a haversine caliper (`matched_controls.R:33, 133`) and `mysterycall_calculate_spatial_density()` already computes local density — wiring density into selection is a small change |
| SP3.3 | **N** | — | The regression surface is Poisson/NB GLMM with physician random effects; area covariates (ADI/SVI/RUCA) enter as plain fixed effects (`assign_area_covariates.R:96-113`). No spatial weights matrix, no CAR/SAR/SPDE term — distinguishing autoregressive from non-spatial covariance needs a whole neighbourhood-weights framework and would change the stated IRR estimand |
| SP3.4 | NA | — | No clustering of any kind (`grep "kmeans\|hclust\|dbscan\|cutree"` over `R/` is empty) |
| SP3.5 | NA | — | No machine learning model in the package, so no broadcasting of differing-dimension spatial inputs |
| SP3.6 | NA | — | Same: no spatial ML, so no sampling-procedure effects to document |
| SP4.0 | Y | already-done | Satisfied via SP4.0a |
| SP4.0a | Y | already-done | Returns the input object with columns appended: `assign_area_covariates.R:123`, `geocode_address.R:120` |
| SP4.0b | Y | feasible | Spatial returns are plain data frames, but the package already defines ~20 S3 result classes, so a class-defined spatial return is an established pattern |
| SP4.1 | Y | already-done | Units documented and never silently converted: `arealand_part` in square metres (`zcta_tract_xwalk.R:24-26`), distances in miles (`spatial_density.R:13, 81`), coordinates in decimal degrees (`city_state_to_lat_long.R:14-15`). No `units` objects, but no unit loss either |
| SP4.2 | Y | already-done | `@return` blocks are unusually explicit: `geocode_address.R:34-38` names all six appended columns and their value sets; `get_census_data.R:10-24` types each column |
| SP5.0 | Y | feasible | No spatial class today, but `plot.mysterycall_lmm` shows the pattern; accepting/returning `sf` inherits `plot.sf` at zero cost |
| SP5.1 | NA | — | No coordinate-axis plot in the package; `mysterycall_crs_albers_conus()` (`green_journal.R:400-406`) only hands a CRS to the caller's `coord_sf`. Mapping delegated (`README.md:102-106`) |
| SP5.2 | NA | — | Same: the only plots are wait-time and trend figures (`create_density_plot.R`, `subspecialist_trend.R`), not spatial axes |
| SP5.3 | NA | — | Interactive output delegated: `leaflet` appears only in `R/deprecated.R` and one vignette; live Leaflet maps are `mysterymaps::mysterymaps_map_base()` (`README.md:102-106, 316`) |
| SP6.0 | Y | feasible | The package implements no coordinate transform (`grep "st_transform"` over `R/` is empty — re-verified), only serves a target CRS; a WGS84 → 5070 → WGS84 round-trip test over `mysterycall_crs_albers_conus()` is one test |
| SP6.1 | Y | feasible | The haversine path is curvilinear-only by construction (`spatial_density.R:36-54`); no Cartesian/projected comparison tested |
| SP6.1a | Y | feasible | Feasible as a planar-degree vs haversine comparison at high latitude (Alaska is in scope — `assign_region.R:33`), asserting the planar version is worse |
| SP6.1b | Y | feasible | Feasible by comparing `.mc_haversine_miles()` against `sf::st_distance()` on EPSG:5070 for CONUS points |
| SP6.2 | Y | feasible | No extreme-coordinate test exists: `test-geocode-city-state.R:3-10` uses only Denver/Boston, `test-geocode_address.R` only Aurora CO; no ±90 or antimeridian case anywhere in `tests/testthat` |
| SP6.3 | Y | feasible | `mysterycall_calculate_spatial_density()` has **zero tests** (independently re-verified: no test file references it); a radius sweep plus a k-nearest comparison is straightforward |
| SP6.4 | Y | feasible | Conditional on SP3.1's weighting argument; testable in the same commit |
| SP6.5 | NA | — | No clustering algorithm to compare against a non-spatial one (see SP3.4) |
| SP6.6 | NA | — | No spatial ML train/test split on which to demonstrate spatial leakage (see SP3.5) |

### Key evidence and gaps

**Strongest already-done evidence.** It is concentrated in the
metadata-and-contract standards rather than the algorithmic ones. SP2.4/SP2.4a
are clean passes by construction: the package's only CRS object is
`sf::st_crs(5070)`, there is no `sp` dependency, and not a single PROJ4 string
appears in 265 R files, so the WKT2 standards are met without further work.
SP4.2 and SP2.6 are met unusually well — `geocode_address.R:34-38` enumerates
every appended column and the exact value set of `geo_match` and `geo_source`,
and `zcta_tract_xwalk.R:18-54` documents not only the units (square metres) but
the difference between area-weighted and HUD's address-weighted allocation,
which is the provenance SP4.1 is really asking for. Census vintage pinning
(`.MC_CENSUS_BENCHMARK`/`.MC_CENSUS_VINTAGE`, `assign_area_covariates.R:126-140`)
plus the layer-rename warning at `assign_area_covariates.R:83-92` is better than
most spatial packages manage.

**Feasible but currently missing — where follow-up work goes.** Three items.
First, **no coordinate-domain validation exists anywhere** — a grep for a
lat/lon range assertion over all of `R/` comes back empty, so a latitude of 500
flows straight into the haversine at `spatial_density.R:53` and silently returns
a number; that is SP2.0b, and it is a one-line
`checkmate::assert_numeric(lat, lower = -90, upper = 90)` per entry point.
Second, **SP2.8's single pre-processing routine does not exist**, and the cost is
already visible as duplicated haversine code in `geocode_city_state.R:63` and
`spatial_density.R:36-54` plus per-function ad hoc coercion; consolidating is a
refactor, not a new capability. Third and worst, **`mysterycall_calculate_spatial_density()`
and `mysterycall_calculate_hq_distance()` are exported with zero tests** — the
whole Testing subsection (SP6.1–SP6.4) hangs off that absence, and SP6.2's
±90-degree case is especially pointed because the package's region tables include
Alaska and Hawaii (`assign_region.R:33-37`) while every geocoding test uses
Denver, Boston or Aurora.

**N verdict (1).** **SP3.3** (distinguishing spatial-autoregressive from
non-spatial covariance). The regression surface is Poisson/NB GLMMs with
physician-level random effects, and ADI/SVI/RUCA enter as ordinary fixed effects;
there is no spatial weights matrix, no CAR/SAR/SPDE term, and nothing that could
quantify autoregressive spatial covariance distinctly from covariate effects.
Satisfying it means building a neighbourhood-weights framework and respecifying
the estimand away from the insurance-type IRR the package exists to produce.

**NA verdicts (9), in three honest clusters.** The **raster/grid** cluster
(SP3.0a) is NA because `terra`, `stars` and any grid data structure are entirely
absent; census tracts and ZCTAs are irregular polygons and rook/queen adjacency
has no referent. The **ML and clustering** cluster (SP3.4, SP3.5, SP3.6, SP6.5,
SP6.6) is NA because `kmeans`, `hclust`, `dbscan` and `cutree` do not appear in
`R/` at all and the package fits no learner. **Visualization is a near-wholly NA
subsection** (SP5.1, SP5.2, SP5.3 of 4): `README.md:102-106, 316` explicitly move
geocoding-adjacent mapping, drive-time isochrones and Leaflet output to
`mysterymaps`; `leaflet` survives in `mysterycall` only inside `R/deprecated.R`;
and the one surviving spatial-viz artifact, `mysterycall_crs_albers_conus()`, is
a CRS *supplier* for the caller's `coord_sf`, not a plot. SP5.0 stays Y because
the package already ships ~20 S3 classes with a plot method pattern, so a spatial
return class would inherit it cheaply.

### Architectural fit

This is a **tabular package that joins area-level attributes**, not a spatial
package in the sense the SP standards mean, and the evidence is structural
rather than stylistic. `sf` is in Suggests and appears at exactly two call sites,
one of which (`hhi.R:96`) calls `st_drop_geometry()` — the package reaches for sf
specifically to *discard* geometry and obtain a data frame of CBSA GEOIDs. There
is no geometry column, no CRS carried as metadata, no `st_transform`,
`st_distance`, `st_buffer` or `st_centroid` anywhere (re-verified), and no
polygon operations; every "spatial" step is a key-based `match()` or
`inner_join()` on a ZCTA, tract, FIPS or CBSA string
(`assign_area_covariates.R:98-111`). The genuine geometric content is narrow:
two copies of a haversine formula and a radius cut-off neighbour count. It is not
*non*-spatial either — geocoding, ZCTA/tract crosswalking, radius-based neighbour
counting and a distance caliper for matched sampling are real spatial operations,
and the delegation of isochrones and mapping to `mysterymaps` is a deliberate,
documented boundary rather than an omission. The practical consequence for review
is that the 24 "feasible" Y verdicts split cleanly: the validation and
documentation standards (SP1.x, SP2.x, SP4.x) are achievable with modest,
mostly-docs-and-asserts work, whereas the algorithmic standards (SP3.1, SP3.2)
and all of Testing would require the package to take its one real geometric
routine seriously enough to give it arguments and a test file it currently lacks
entirely.

---

## Machine Learning Standards (ML)

90 standards assessed individually.

### Per-subsection counts

| Subsection | Y | N | NA | Total |
|---|---|---|---|---|
| Input Data Specification (ML1.x, incl. missing values) | 12 | 0 | 4 | 16 |
| Pre-processing (ML2.x) | 11 | 0 | 1 | 12 |
| Model and Algorithm Specification (ML3.x, incl. control parameters, CPU/GPU) | 14 | 0 | 4 | 18 |
| Model Training (ML4.x, incl. batch processing, re-sampling) | 6 | 5 | 2 | 13 |
| Model Output and Performance (ML5.x) | 11 | 0 | 1 | 12 |
| Documentation (ML6.x) | 3 | 0 | 0 | 3 |
| Testing (ML7.x) | 12 | 1 | 3 | 16 |
| **Total** | **69** | **6** | **15** | **90** |

**Proportion: 69 / 90 = 0.767** — Y split: 26 already-done, 43 feasible.

### Per-standard verdicts

| ID | Verdict | Status | Evidence |
|---|---|---|---|
| ML1.0 | Y | feasible | `mysterycall_temporal_validation()` `R/internal_validation.R:29` does split train/test, but its roxygen never defines the terms conceptually — docs-only change |
| ML1.0a | Y | feasible | Terms are not eschewed, merely undocumented; same roxygen edit |
| ML1.1 | Y | feasible | Input is one unlabelled frame; a `split_col` convention parallels the existing `time_col`/`threshold` pair (`R/internal_validation.R:38-39`) |
| ML1.1a | Y | feasible | `clean_complete_cases()` `R/internal_validation.R:2` is the existing pre-processing hook where label confirmation would sit |
| ML1.1b | Y | feasible | Case-insensitive/partial matching is already the idiom elsewhere (`.mc_academic_patterns` regex matching, `R/classify_practice_setting.R:8`) |
| ML1.2 | Y | already-done | `mysterycall_temporal_validation(data, time_col, threshold)` and `mysterycall_provider_split_simulation(data, cluster_col, k)` each take one tabular object and derive the split from a variable in it (`R/internal_validation.R:29, 151`) |
| ML1.3 | Y | feasible | The split is derived, not passed; needs an explicit label parameter on those same two functions |
| ML1.4 | NA | — | All input is one in-memory REDCap export (`mysterycall_prepare_calls()` `R/prepare_calls.R:106`); `R/data_cache.R` caches only downloaded shapefiles. No on-disk partitioned dataset stage exists, which `srr/ml.Rmd:38-41` explicitly licenses |
| ML1.5 | Y | feasible | `mysterycall_assess_data_quality()` `R/preflight_checks.R:537` and `print.mysterycall_prepared()` `R/prepare_calls.R:303` already summarise counts and the waterfall for one set, and hashing exists in `R/provenance.R` — needs per-split extension |
| ML1.6 | NA | — | The package *admits* missing values (`clean_complete_cases()`, `mysterycall_impute_calls()`), so this conditional standard does not apply |
| ML1.6a | NA | — | Conditional on ML1.6 |
| ML1.6b | NA | — | Conditional on ML1.6 (imputation examples do exist, `R/impute_calls.R:86-116`) |
| ML1.7 | Y | feasible | MICE/Rubin processing documented in depth (`R/impute_calls.R:12-82`), but the silent complete-case drop in `clean_complete_cases()` `R/internal_validation.R:12` is an undocumented internal |
| ML1.7a | Y | feasible | `mice::mice()` is called without exposing `method`/`predictorMatrix` (`R/impute_calls.R:230-236`); forwarding them gives user-defined imputation |
| ML1.7b | Y | feasible | Rubin's rules given in LaTeX (`R/impute_calls.R:21-29`); the per-variable mice method is undocumented |
| ML1.8 | Y | feasible | `clean_complete_cases()` is applied to the pooled frame *before* splitting (`R/internal_validation.R:35`), so equal treatment already holds; a control parameter is the gap |
| ML2.0 | Y | already-done | `mysterycall_prepare_calls()` `R/prepare_calls.R:106` — a dedicated, parametrized pre-processing function (`col_*`, `logistic_include_codes`, `na_exclusions`) |
| ML2.0a | Y | already-done | Returns `$logistic_data`/`$waittime_data` fed directly to the model functions (`R/prepare_calls.R:15-22`) |
| ML2.0b | Y | already-done | Class `mysterycall_prepared` with `print.mysterycall_prepared()` `R/prepare_calls.R:303` printing n, outcome counts and the filtering waterfall |
| ML2.1 | NA | — | No broadcasting or dimension reconciliation anywhere; every input is one rectangular frame |
| ML2.2 | Y | already-done | Transformation targets are user-specified, not generic: `mysterycall_impute_age(age_offset, min_age, max_age)` `R/impute_age.R:54`; `mysterycall_categorize_wait(threshold_days, bin_width, max_bin)` `R/categorize_wait.R:28`; `mysterycall_remove_near_zero(freqCut, uniqueCut)` |
| ML2.2a | Y | already-done | `age_offset = 27` justified as a "validated median… r = 0.962, MAE = 2.1 years" (`R/impute_age.R:17-19`); `threshold_days = 14` as "a two-week wait" (`R/categorize_wait.R:13`) |
| ML2.2b | Y | feasible | `vignettes/data-cleaning.Rmd` and `provider-classification.Rmd` demonstrate the functions but never justify the numeric values chosen |
| ML2.3 | Y | feasible | `$waterfall` records every filter step's n and reason (`R/prepare_calls.R:270-280`) but not the numeric transformation parameters |
| ML2.4 | Y | already-done | Every default documented in `@param` (`R/categorize_wait.R:10-18`, `R/collapse_rare.R:12-16`, `R/remove_near_zero_var.R:6-7`) and exercised in `vignettes/data-cleaning.Rmd` |
| ML2.5 | Y | feasible | `na_exclusions = "include"` plus `col_*` overrides give partial bypass; no global off-switch, though each transform is a separate exported call |
| ML2.6 | Y | already-done | All transforms exported: `mysterycall_collapse_rare`, `_categorize_wait`, `_impute_age`, `_remove_near_zero`, `_remove_constants`, `_reorder_by_freq` |
| ML2.7 | Y | already-done | log1p reversal documented and implemented with `expm1()`, including why not `exp()` (`R/model_mae_rmse.R:304-310`, `@param back_transform`) |
| ML3.0 | Y | feasible | `mysterycall_create_formula()` `R/poisson_formula_maker.R:29` specifies without fitting, but is not wired to the `mysterycall_prepared` object |
| ML3.0a | Y | feasible | Fit functions build `model_formula` before `lme4::glmer()` (`R/poisson_model.R:236-247`); a `nofit=` early return is mechanical |
| ML3.0b | Y | feasible | Fit functions take `data` plus column names, not the `mysterycall_prepared` object; a dispatch addition |
| ML3.0c | Y | feasible | Same change as ML3.0a/b |
| ML3.0d | Y | feasible | The classed-list-plus-`print` pattern exists for every *fitted* object; there is no untrained-spec class yet |
| ML3.1 | Y | feasible | Pre-trained fits are already consumed: `mysterycall_predict_appointment(fit, newdata)` `R/predict_appointment.R:73`, `stats::update(fit, data = sub)` `R/leave_one_out.R:66` — but no spec function accepts either |
| ML3.2 | Y | already-done | One prepared data object feeds logistic/Poisson/NB/LMM; `mysterycall_compare_count_families()` `R/advanced_models.R:33` fits three families to one formula and data set |
| ML3.3 | Y | feasible | Classes are thin wrappers over `glmerMod`/`glmmTMB` with `tidy()` methods; the comparative vignette is writing, not engineering |
| ML3.4 | NA | — | No training or learning rates exist; GLMM fitting is likelihood maximisation. A repo-wide grep for `learning_rate|epoch|hyperparam` returns nothing (independently re-verified) |
| ML3.4a | NA | — | Conditional on ML3.4 |
| ML3.4b | NA | — | Conditional on ML3.4 |
| ML3.5 | Y | feasible | Parent of ML3.5a/b |
| ML3.5a | Y | feasible | `...` is forwarded verbatim to `lme4::glmer()` (`R/poisson_model.R:246`), so `control = glmerControl(optimizer=)` already works; it is simply not documented as a control parameter (hardcoded `"bobyqa"` at `R/screen_predictors.R:259`) |
| ML3.5b | Y | already-done | Loss is the family likelihood, and `family=` is a documented parameter on `mysterycall_temporal_validation()`, `_provider_split_simulation()`, `_screen_predictors()`, `_test_interaction_effect()` |
| ML3.6 | Y | feasible | Parent of ML3.6a/b |
| ML3.6a | Y | already-done | bobyqa / Nelder_Mead / nloptwrap all reachable via `...` → `glmerControl` (`R/poisson_model.R:246`; used at `R/screen_predictors.R:259`) |
| ML3.6b | Y | already-done | Poisson, nbinom1, nbinom2, binomial and Gaussian LMM (`R/advanced_models.R:33-55`; `R/internal_validation.R:49-55`) |
| ML3.7 | NA | — | No compiled code at all — there is no `src/` directory (re-verified), so there is no C++/GPU surface |
| ML4.0 | Y | feasible | `mysterycall_auto_model()` `R/auto_model.R:79` already routes between Poisson and NB specs and returns one class; broadening it to an arbitrary spec object is incremental |
| ML4.1 | **N** | — | No optimizer-path retention; only terminal convergence status is captured (`sprintf("optimizer code %d", conv_code)` `R/nb_model.R:236`). Per-iteration state capture through lme4/glmmTMB/TMB is a new monitoring subsystem outside the package's inferential scope |
| ML4.1a | **N** | — | No per-iteration parameter vectors or hashes anywhere |
| ML4.1b | **N** | — | No per-iteration loss values retained |
| ML4.1c | **N** | — | No gradient quantification retained |
| ML4.2 | **N** | — | Nothing to extract or document; follows from ML4.1 |
| ML4.3 | NA | — | No batch/epoch training stage; nothing in `R/` takes a batch size or epoch count (the only "batch" is NPI API lookup, not training) |
| ML4.4 | NA | — | No batch-size/epoch trade-off exists to advise on |
| ML4.5 | Y | feasible | The pattern exists: `mysterycall_estimate_resources(n_rows)` projects runtime and memory from per-row constants (`R/preflight_checks.R:652`) — but for the data pipeline, not model fitting |
| ML4.6 | Y | already-done | On by default: `utils::txtProgressBar` over bootstrap replicates (`R/internal_validation.R:245`), `mysterycall_progress_tracker(quiet=)` `R/progress_tracker.R:34`, `verbose=` on `_screen_predictors()`/`_impute_calls()`. Gap: the bootstrap bar has no suppression switch |
| ML4.7 | Y | already-done | Single iteration-count parameters: `n_boot` (`R/bootstrap_ci.R:49`, `R/internal_validation.R:224`), `k` folds (`R/internal_validation.R:151`), `m` imputations (`R/impute_calls.R`), `n_sim` (`R/model_validation.R:39`) |
| ML4.8 | Y | feasible | `mysterycall_provider_split_simulation()` splits clusters into k equal folds with no reference to original test/train proportions (`R/internal_validation.R:164-165`) |
| ML4.8a | Y | feasible | `k` controls fold size today; needs an explicit `prop_test` override on the same function |
| ML5.0 | Y | already-done | One classed object holds the fit plus derived tables (`R/poisson_model.R:313-332`) |
| ML5.0a | Y | already-done | `class = "mysterycall_poisson_model"` `R/poisson_model.R:332`, plus `_nb_model`, `_lmm`, `_logistic_model`, `_auto_model` |
| ML5.0b | Y | already-done | `S3method(print, mysterycall_poisson_model)` and 65 sibling print methods |
| ML5.1 | Y | feasible | As ML3.3: no benchmark or comparison against raw `glmerMod`/`glmmTMB` trained objects exists |
| ML5.2 | Y | already-done | `@return` blocks enumerate every element (`R/poisson_model.R`; `R/model_mae_rmse.R:56-75`) |
| ML5.2a | Y | already-done | `@family outcomes` tags plus `_pkgdown.yml` reference sections list all attached functionality (`_pkgdown.yml:442-467, 733, 806-827`) along with the `tidy()` methods |
| ML5.2b | Y | feasible | No save/re-load example anywhere; `saveRDS()` on these plain lists works (already used at `R/mysterycall-paths.R:95`) |
| ML5.2c | NA | — | `saveRDS()` *is* appropriate for these S3 lists wrapping lme4/glmmTMB fits, so no bespoke serializer is warranted |
| ML5.3 | Y | already-done | Assessment is separate from fitting: `mysterycall_model_metrics()` `R/model_metrics.R:36`, `_model_mae_rmse()`, `_recalibration_assessment()` `R/internal_validation.R:91`, `_select_best_model()` `R/model_selection.R:37` |
| ML5.4 | Y | already-done | MAE, RMSE, Pearson R², MAPE (`R/model_mae_rmse.R:56-87`), MSE (`R/internal_validation.R:64`), calibration intercept/slope (`R/internal_validation.R:112-113`), AIC/BIC/LRT (`R/model_selection.R`) |
| ML5.4a | Y | already-done | `@section Metrics:` gives each metric's formula and interpretation (`R/model_mae_rmse.R:77-87`) |
| ML5.4b | Y | feasible | No `metrics=` hook; `mysterycall_model_mae_rmse()` already materialises an `actual`/`predicted`/`residual` frame to pass to one |
| ML6.0 | Y | feasible | No vignette or DESCRIPTION text frames a train/test workflow; grep of `vignettes/*.Rmd` finds cross-validation discussion in only one file (`my-vignette.Rmd`), and `_temporal_validation()`/`_provider_split_simulation()` appear in no vignette |
| ML6.1 | Y | feasible | This restricted-subset framing is the honest one; a short "where this sits in an ML workflow" section is writing work |
| ML6.1a | Y | feasible | `caret` and `mice` are already in DESCRIPTION Suggests and `caret::nearZeroVar()` is already called (`R/remove_near_zero_var.R:35`) |
| ML7.0 | Y | feasible | Follows ML1.1; the test idioms exist (dedicated `test-cov-*` coverage suites per function) |
| ML7.1 | Y | already-done | `tests/testthat/test-categorize-wait.R:27-28` varies `bin_width`/`max_bin` and asserts the effect; `test-adversarial-auto-model.R:299-319` varies `phi_threshold`; `test-academic_indicators.R:35-37` varies `confidence_threshold` |
| ML7.2 | Y | feasible | Imputation tests assert only structure and FMI ranges (`tests/testthat/test-impute-calls.R:133-220`); the reference-implementation idiom already exists ("a leave-out estimate matches a manual refit", `test-leave-one-out.R:33`) and Rubin's rules are hand-coded |
| ML7.3 | Y | feasible | No test compares `mysterycall_poisson_model` with a bare `glmerMod`; `lme4` is already an Import |
| ML7.3a | Y | feasible | Same |
| ML7.3b | Y | feasible | Same |
| ML7.4 | NA | — | No training rates exist (see ML3.4) |
| ML7.5 | NA | — | No optimal-training-rate routine exists (see ML3.4a) |
| ML7.6 | NA | — | No epochs exist (see ML4.3) |
| ML7.7 | Y | feasible | `...` → `glmerControl(optimizer=)` is the existing mechanism (`R/poisson_model.R:246`); no test varies it |
| ML7.8 | Y | already-done | `test-overdispersion-test.R`, `test-cov-screen_interactions.R` and `test-adversarial-sensitivity-comparison.R` all fit across `family = "poisson"`/`"nb"`/`"logistic"` |
| ML7.9 | Y | feasible | `expand.grid` over family × optimizer is easy since both are parameters; not done |
| ML7.9a | Y | feasible | Same |
| ML7.10 | **N** | — | Follows ML4.1: there are no optimizer paths to extract, so there is nothing to test |
| ML7.11 | Y | already-done | `tests/testthat/test-model-mae-rmse.R:60-134` asserts MAE ≥ 0, RMSE ≥ MAE, R² ∈ [0,1], the residual identity and the exact-zero case; `test-model-metrics.R` plus `test-cov-model_metrics.R` cover the second metric function |
| ML7.11a | Y | feasible | Metrics are tested individually, never contrasted across differently-fit models to show relative advantages |

### Key evidence and gaps

**Strongest already-done evidence.** It clusters in pre-processing and model
output, and is genuinely strong rather than incidental.
`mysterycall_prepare_calls()` (`R/prepare_calls.R:106`) is a real ML2.0 object —
a dedicated, parametrized pre-processing function returning a classed
`mysterycall_prepared` list whose `print` method reports input counts and a
step-by-step filtering waterfall, and whose `$logistic_data`/`$waittime_data`
slots feed the model functions unchanged, which also satisfies ML3.2 outright.
Every model fit returns its own S3 class with a `print` method and
`broom::tidy()` support, performance assessment lives in functions strictly
separate from fitting (`mysterycall_model_metrics()`,
`mysterycall_model_mae_rmse()`, `mysterycall_recalibration_assessment()`), and
the metric set is both varied and documented formula-by-formula
(`R/model_mae_rmse.R:77-87`) — ML5.0 through ML5.4a are effectively met today.
The transformation helpers are all exported with justified, user-overridable
numeric parameters (`age_offset = 27` is defended with validation statistics at
`R/impute_age.R:17-19`), and ML2.7 is satisfied by the explicit `expm1()`
back-transform rationale at `R/model_mae_rmse.R:304-310`.

**Feasible but currently missing — where follow-up work goes.** A labelled
train/test input convention (ML1.1–ML1.3, ML7.0): the split functions exist but
derive the partition internally and never speak the vocabulary. The complete
absence of any ML-workflow framing in the documentation (ML6.0–ML6.1a):
`mysterycall_temporal_validation()` and `mysterycall_provider_split_simulation()`
are exported and pkgdown-listed yet mentioned in no vignette. Plus a custom-metric
hook (ML5.4b), save/re-load examples (ML5.2b), comparison with other packages'
model objects (ML3.3/ML5.1/ML7.3), and a `method=` passthrough on `mice::mice()`
(ML1.7a).

**N verdicts (6), all one gap.** ML4.1, ML4.1a, ML4.1b, ML4.1c, ML4.2 and ML7.10
require retaining and documenting per-iteration optimizer paths — parameter
states, loss values, local gradients. The package captures only terminal
convergence codes (`R/nb_model.R:236`), and building iteration-level monitoring
through lme4/glmmTMB/TMB would be a different package, not an extension of this
one.

**NA verdicts (15), with three substantially-NA subsections.** **Batch
Processing** is NA on ML4.3/ML4.4 because no batch size or epoch parameter exists
anywhere in `R/` (ML4.5/ML4.6 remain Y because `mysterycall_estimate_resources()`
and the progress tracker map onto them for long-running resampling jobs).
**CPU and GPU processing** (ML3.7) is NA because there is no `src/` directory and
no compiled code at all. The **training-rate** standards (ML3.4, ML3.4a, ML3.4b,
ML7.4, ML7.5) and **epochs** (ML7.6) are NA because GLMM likelihood maximisation
has no learning rate — a repo-wide grep for `learning_rate|epoch|hyperparam`
returns nothing. ML1.4 is NA on the authority of `srr/ml.Rmd:38-41`, which
explicitly allows dropping the on-disk-partition stages when all data fit in
memory, which they do here (one REDCap export). ML1.6/1.6a/1.6b and ML5.2c are
conditional standards whose antecedents are false (the package admits missing
values, and `saveRDS()` is appropriate for these lists). ML2.1 is NA because no
broadcasting or dimension reconciliation occurs.

### Architectural fit

This is an inferential-statistics package with a handful of predictive helpers
bolted to the side, not an ML package. Its centre of gravity is Poisson/NB GLMM
estimation for publication: incidence rate ratios with Wald intervals,
overdispersion routing, ICCs, DHARMa residual diagnostics, STROBE/CONSORT flow
diagrams, and one-call manuscript generators — the outputs are sentences and
tables for a methods section, not a serialized model artifact plus a test-set
score. The ML-adjacent surface is real but peripheral and, tellingly,
undocumented in the vignettes: cluster-wise k-fold CV and temporal hold-out exist
in `R/internal_validation.R`, prediction with delta-method CIs in
`R/predict_appointment.R`, MAE/RMSE/R²/MAPE in `R/model_mae_rmse.R`, plus
bootstrap stability and univariable screening — yet essentially no vignette
discusses cross-validation, hold-out data or a training/testing split, and
`caret` is a Suggest used for exactly one call (`nearZeroVar`). Crucially, the
four pillars the ML category assumes are structurally absent rather than merely
unimplemented: no loss function the user selects independently of the
distributional family, no optimiser the user is expected to reason about
(hardcoded `"bobyqa"`, reachable only through `...`), no hyper-parameter tuning
or learning rate, and no model persistence/re-load story. The high Y count
(69/90) reflects that most ML standards reduce to documentation, labelling
conventions and parameter passthroughs that this well-structured codebase could
absorb — but a submission under ML would be fighting the package's own
self-description.

---

## Task 3 — Scope and category-fit conclusions

### Is the package in scope?

Yes, under every category assessed, by a wide margin. The scope threshold is
compliance with at least 50% of applicable standards (General plus the
category-specific set):

| General + category | Y | Total | Proportion | ≥ 50%? |
|---|---|---|---|---|
| General + EDA | 98 | 102 | **0.961** | Yes |
| General + Regression | 109 | 116 | **0.940** | Yes |
| General + Spatial | 101 | 113 | **0.894** | Yes |
| General + Machine Learning | 135 | 158 | **0.854** | Yes |

The General set alone scores 0.971 (66/68), with zero `N` verdicts — no General
standard asks for a capability that conflicts with this package's architecture,
because `mysterycall` is a tabular-input, data-frame-output analysis package,
which is precisely the shape the General standards assume. That result is driven
by infrastructure the package already has: 316 documented exports with `.Rd`
files checked in, `checkmate` assertions in 72 files, `match.arg` in 49, 484 test
files with 1,682 `expect_error()` assertions, `set.seed()` in 246 of them,
genuine cross-implementation correctness tests against `stats::glm`/`MASS`/`pwr`
(standard G5.4b, which most submissions fail), and 10 CI workflows including
coverage and a comprehensive nightly run.

An important caveat on reading these numbers: they measure **potential**
compliance as the methodology requires, and roughly half of the `Y` verdicts are
"feasible" rather than "already-done" (General: 66 Y = 35 already-done + 31
feasible; RE: 20 + 23; EA: 18 + 14; SP: 11 + 24; ML: 26 + 43). A real srr
submission requires `@srrstats` tags asserting each standard against actual code,
so these proportions are an estimate of how much of that tagging work would be
honest today versus how much needs engineering first.

### Which single category is the best fit?

**EDA (`eda`), at 0.941 (32/34)** — the highest category proportion. The runner-up
is **Regression (`regression`) at 0.896 (43/48)**, and the two are closer than
the numbers suggest: the 0.045 gap is 1.5 standards, and EA's denominator is
29% smaller, so a single verdict reversal in either direction would swap the
ranking. Both conclusions deserve their qualitative reasoning.

**Why EA scores highest.** The package's entire delivery layer is EDA output, and
unusually mature EDA output at that. It has one `N` and one `NA` in 34 standards.
The two standards that ask what the software *automates* that reference
implementations do by hand — EA3.0 and EA3.1 — are met convincingly by
`mysterycall_auto_model()` (automated Poisson-vs-NB routing that returns its own
`$selection$reason`), `mysterycall_abstract_numbers()` (extracts OR/IRR/beta from
a fitted object straight into abstract prose), and `mysterycall_disparities_table()`
(a single standardized reference-group comparison contract). The visualization
subsection is the package's strongest showing anywhere in this assessment:
`R/green_journal.R` implements an Okabe-Ito palette with the Wong (2011) DOI,
documents its deuteranopia/protanopia/tritanopia and grayscale safety, targets a
documented 8–12 pt typeface range, and falls back from Arial to `"sans"`
gracefully — EA5.0, EA5.0b and EA5.1 are met outright, which is rare. Numeric
precision control (EA4.1, EA5.2) is near-exhaustive, and `R/join_safety.R`
largely solves the index-column standards EA2.0/EA2.3 with a mandatory `by`,
default uniqueness assertion, and a CSV audit trail.

**Why EA's fit is nonetheless asymmetric.** EA's standards imagine
*general-purpose* EDA — universal input handling, "as many diverse kinds of input
data as possible", index columns as a declared first-class concept. mysterycall
requires named domain columns (`outcome_col`, `group_col`, `insurance`,
`wait_days`, `npi`), binary 0/1 outcomes, and a specific long/paired structure in
which an NPI deliberately repeats (`R/clean_phase_1_results.R:29-30` duplicates
rows to build the paired insurance design, so the unique key is compound). Every
remaining EA gap sits on the input side, and the one `N` (EA2.4, relational
multi-table class) is there precisely because the package accepts multi-table
input in earnest — roughly 49 join sites on bare data-frame pairs — while
deliberately rejecting a `dm`-style contract in favour of per-call key
declaration plus coverage auditing. A reviewer may reasonably ask whether a
package whose descriptive functions accept only one domain-specific table shape
belongs in EA. The defensible answer is that its EDA *outputs*, not its input
genericity, are the contribution.

**Why Regression is the architecturally natural home.** The package's own
DESCRIPTION and README lead with GLMMs, and the statistics bear that out: real
link-function model families, convergence diagnostics harvested from
`model@optinfo$conv$lme4$messages` and persisted on the returned object,
dispersion checks, effect sizes with CIs, marginal effects, DHARMa residual
diagnostics, ICC, predicted means, bootstrap CIs, and LRT model comparison — all
returning properly classed objects that retain the underlying
`glmerMod`/`glmmTMB` fit, which is exactly RE4.0. RE's one systematic mismatch is
interface *idiom*, not substance: RE assumes the canonical R modelling API
(formula in; `coef`/`confint`/`vcov`/`summary`/`plot` out), whereas mysterycall's
idiom is "column names in, manuscript artifact out". `NAMESPACE` registers 66
`print`, 19 `as.data.frame`, 3 `tidy` and 1 `plot` method — and no `coef`,
`confint`, `vcov`, `nobs`, `formula` or `summary` method at all, even though
every ingredient is already on the objects. That single gap accounts for RE4.2,
RE4.3, RE4.6, RE4.18, RE6.0–RE6.2 and RE7.3, and closing it is mechanical work
on existing data structures rather than new statistics.

### Secondary categories

**Regression is independently viable as a second category** at 0.896 (43/48)
with only 2 `N` and 3 `NA` verdicts, and the three `NA`s form one coherent,
legitimate group (RE4.15, RE6.3, RE7.4 — all gated on forecasting/extrapolation
along a time horizon, which does not exist here since predictors are categorical
payer/scenario/caller factors). rOpenSci permits submission under multiple
categories, and EA plus RE is the honest description of this package: an
inferential regression core wrapped in a publication-grade EDA and reporting
layer.

**Spatial (0.778) is not viable as a primary or secondary category.** The score
is depressed by 9 `NA`s that are genuinely NA, not conveniently so: there is no
raster or grid data structure (`terra`/`stars` absent), no clustering
(`kmeans`/`hclust`/`dbscan` absent), and three of four Visualization standards
are NA because mapping, isochrones and Leaflet output are explicitly delegated to
the companion `mysterymaps` package. More decisively, this is a tabular package
that joins area-level attributes rather than a spatial package: `sf` appears at
exactly two call sites, one of which calls `st_drop_geometry()` to *discard*
geometry; there is no geometry column, no CRS carried as metadata, and no
`st_transform`/`st_distance`/`st_buffer`/`st_centroid` anywhere. The genuine
geometric content is two duplicated copies of a haversine formula and a radius
cut-off count — and `mysterycall_calculate_spatial_density()`, the one real
geometric routine, is exported with zero tests and no coordinate-range
validation.

**Machine Learning (0.767) is the weakest fit and should not be pursued.** Its 6
`N` verdicts all stem from one structural absence (no per-iteration optimizer
path retention), and its 15 `NA`s cover three subsections that do not exist here
at all: batch/epoch training, CPU/GPU processing (no `src/` directory, no
compiled code), and learning rates (GLMM likelihood maximisation has none). The
high Y count mostly reflects that many ML standards reduce to documentation and
parameter passthroughs a well-structured codebase could absorb — but the four
pillars ML assumes (user-selected loss independent of family, a user-reasoned
optimiser, hyper-parameter tuning, model persistence) are all absent, and no
vignette so much as frames a train/test workflow even though
`mysterycall_temporal_validation()` and `mysterycall_provider_split_simulation()`
are exported.

### Recommendation

**Submit under `eda` as the primary category, with `regression` declared as a
second category.** EA has the highest proportion (0.941) and the strongest
already-done evidence per standard, and the package's delivery layer — tables,
disparity summaries, accessible figures, auto-generated results prose — is
unambiguously what it offers users. Declaring `regression` alongside it is well
supported at 0.896 and matches the package's self-description and statistical
core; it also pre-empts the reviewer question that EA alone invites ("is this
really general-purpose EDA?"). Do not claim `spatial` or `ml`.

If the maintainer would rather lead with the GLMM core, submitting `regression`
first with `eda` second is defensible — both clear 50% by a factor of nearly two,
and the choice is within this assessment's margin of error.

**Highest-value work before submission**, ordered by standards unlocked per unit
of effort:

1. **Register the accessor and dispatch layer** — `coef`, `confint`, `vcov`,
   `nobs`, `formula`, `summary` methods on the model classes, and `plot` methods
   routing to the existing `mysterycall_irr_plot()`/`mysterycall_forest_plot()`/
   `mysterycall_plot_disparities()`. Every ingredient is already on the objects.
   Unlocks RE4.2, RE4.3, RE4.6, RE4.18, RE6.0–RE6.2, RE7.3, EA4.2.
2. **Add an `na_action` contract and collinearity screening** to the fitters.
   `performance` is already an Import. Unlocks RE2.1, RE2.2, RE2.4, RE2.4a/b,
   RE7.0, RE7.0a, RE7.1, G2.14, G2.14a.
3. **Build the extended-test scaffold** — a `MYSTERYCALL_EXTENDED_TESTS` flag
   wired into the existing `nightly.yaml`, plus a `tests/README.md`. Unlocks
   G5.10, G5.11, G5.12.
4. **Harmonize return classes and plot-test depth** — make table functions
   round-trip their input class, and move plot tests past
   `expect_s3_class(result, "ggplot")` into `ggplot_build()`/`layer_data()` or
   `vdiffr` snapshots. Unlocks EA4.0, EA6.1, EA6.0d.
5. **Write a prose Life Cycle Statement** and tag the 38 files whose internal
   helpers carry neither `@noRd` nor `@keywords internal`. Unlocks G1.2, G1.4a.
