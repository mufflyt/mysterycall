# mysterycall (development version)

## New functions

- **Small-sample categorical statistics toolkit** (`R/categorical.R`), the
  second roadmap item from the audit-study synthesis. A dependency-free layer
  for the contingency-table designs these studies actually use, where the GLMM
  core is overkill:
  - `mysterycall_test_categorical()` cross-tabulates two variables and tests
    association, auto-selecting between Pearson's chi-squared and an exact test
    (Fisher, or Fisher-Freeman-Halton for larger tables) by expected cell
    counts, reports Cramer's V, and can add Benjamini-Hochberg-adjusted
    post-hoc pairwise proportion comparisons for a binary outcome.
  - `mysterycall_cmh_test()` runs a Cochran-Mantel-Haenszel test across a
    matching stratum (within-unit / paired persona designs), with the common
    odds ratio for the 2x2xK case.
  - `mysterycall_prevalence_ci()` gives per-category prevalences with Wilson,
    Clopper-Pearson, or Wald intervals, optionally within a grouping variable.
  - `mysterycall_compare_ranks()` runs Kruskal-Wallis / Mann-Whitney with an
    effect size and per-group medians (IQR) for skewed numeric outcomes.

- **Guideline-concordance scoring engine** (`R/concordance.R`), scaffolded from a
  synthesis of eight mystery-caller audit studies. Scores what staff *said* or
  *did* against a reference standard at the item level, then rolls up to call-
  and study-level summaries:
  - `mysterycall_concordance_rubric()` builds the reference standard from four
    item types — `binary`, `expected_present`, `reference_match` (per-row gold
    standard), and `evidence_tier` (named options scored against a date-versioned
    lookup).
  - `mysterycall_score_concordance()` returns per-item concordance rates with
    Wilson CIs, per-call composite scores, an overall summary, and an optional
    per-group breakdown. Item denominators track applicability separately from
    the call count, so within-encounter conversation exits are handled natively.
  - `mysterycall_concordance_kappa()` computes per-item Cohen's kappa and percent
    agreement across two raters.
  - `mysterycall_concordance_sentence()` emits numbers-locked manuscript prose
    (overall composite or per item), in the existing prose-builder family.

# mysterycall 1.6.1

## Improvements

- `mysterycall_kaplan_meier()` figure polish:
  - New `legend_title` argument. The legend title now defaults to a prettified
    `group_col` (e.g. `"sub4"` -> `"Sub4"`, `"insurance_type"` -> `"Insurance
    Type"`) instead of the raw variable name; pass an explicit string
    (`legend_title = "Subspecialty"`) or `""` to drop it.
  - Empty factor levels in `group_col` are now dropped (`droplevels()`). An
    unused level previously desynced `nlevels()` from the fitted strata, which
    surfaced as stray `-N` suffixes on the risk-table row labels (or a hard
    row-count error).
  - Tightened styling: risk-table columns align with the curve gridlines (shared
    breaks), the first group sits at the top of the risk table, the number-at-
    risk counts at day 0 are no longer clipped, the risk-table row labels are
    bold and colour-matched to the curves, and the legend renders on a single
    row with thicker keys.

## New functions

- `mysterycall_get_direction()` and `mysterycall_get_change_verb()`: manuscript/
  abstract helpers that pick a direction word ("higher"/"lower",
  "increasing"/"decreasing", etc.) from the **sign of the data**, so prose can
  never contradict the numbers it describes. Vectorized, NA-safe, with a `tol`
  no-change band and fully configurable words per subspecialty/table.

## Bug fixes

- `mysterycall_clean_phase1(duplicate_rows = FALSE)` no longer fabricates an
  `insurance` label by row-number parity (which made a physician's insurance
  depend on alphabetical sort position). In non-paired mode the `insurance`
  column is now set to `NA` with a warning, so callers assign it from their own
  data. The default paired path (`duplicate_rows = TRUE`) is unchanged. (Bug 21)

## Documentation

- New vignette **"Writing the Results Section"** (`writing-results-section`):
  assembles a ready-to-paste manuscript Results narrative from the prose builders
  (`mysterycall_results_paragraph()`, `mysterycall_write_results_paragraph()`,
  `mysterycall_irr_to_days()`, `mysterycall_wait_time_sentence()`,
  `mysterycall_get_direction()` / `mysterycall_get_change_verb()`), with every
  direction word tied to the sign of the data so the prose can never contradict
  the tables. Runs on plain data frames, so it builds fast and needs no model
  fitting.

## Covariate reader hardening

- `mysterycall_get_cms_enrollment()` and `mysterycall_get_hrsa_ahrf()` now
  validate their input schema up front and fail with an explicit message that
  names the missing column(s)/table and what was actually found, instead of an
  opaque `dplyr::select()` or SQL error deep in the call. Both functions'
  documentation now spells out the exact expected schema (`get_hrsa_ahrf`
  requires a preprocessed `ahrf_county_data` DuckDB table — the raw fixed-width
  AHRF is not read directly; CSV input is not supported).
- `mysterycall_get_cms_enrollment()` matches FIPS leading-zero-safe:
  `read.csv()` parses `"08031"` as the integer `8031`, so numeric FIPS (in the
  CSV and in the `county_fips` argument) are now left-padded to five characters
  before matching, and the returned `FIPS` column is a zero-padded string.
- Added offline, fixture-based tests (temp CSV / temp DuckDB) for
  `mysterycall_get_cms_enrollment()`, `mysterycall_get_hrsa_ahrf()`, and
  `mysterycall_track_clinician_churn()`.

## Source-audit bug fixes (wave 4)

- `city_state_to_lat_long` dataset now matches its documented schema: columns
  `city`, `state` (two-letter USPS abbreviation incl. DC/PR), `lat`, `long`. It
  previously shipped `state` full names plus `latitude`/`longitude`, so `$lat` /
  `$long` returned `NULL` and any two-letter-`state` join matched zero rows. The
  `data-raw/` build script now performs the rename + abbreviation.
- `mysterycall_acceptance_waffle()` default `bcbs_label` corrected to the
  package-canonical `"Blue Cross/Blue Shield"` (no spaces); the old spaced
  default `stop()`ed with "No rows found" on canonical data.
- Removed a contradictory (always-FALSE) dead predicate in
  `data-raw/benchmark_name_parser.R`.

## Source-audit bug fixes (waves 1-3)

A full read of `R/` surfaced correctness bugs that fed wrong numbers into data,
models, and manuscript text. Fixed in this version (BUGS.md #5-#20, #22-#47):

- **Data integrity / joins:** missing NPIs no longer stringify to `"NA"` in the
  shared reader (`utils-io.R`) or `clean_phase_1_results()`, which had collapsed
  every missing-NPI row to a colliding `doctor_id`; `flag_repeat_physicians()` /
  `save_quality_check_table()` now key duplicate detection on id only (not id +
  name); `prepare_calls()` no longer injects phantom all-NA rows in the
  `na_exclusions = "drop"` branch; `exclusion_summary()` reports an explicit
  `n_unrecognized` bucket instead of silently counting unknown reasons as
  included.
- **Statistics / models:** `nb_power()` and `sensitivity_both_insurance()` now
  treat the paired (within-physician) design as paired; `power_analysis()`
  no longer double-counts calls in the unpaired branch; `model_mae_rmse()` uses
  `expm1()` (not `exp()`) to invert `log1p`; `univariate_lmm_screen()` returns an
  additive `Estimate` (renamed from the meaningless exponentiated "IRR");
  `interaction_screen()` bases significance on interaction terms only (not
  `min(p)` over main effects) and uses `<= alpha`; `lmm.R` builds Wald CIs with a
  t quantile matching the Satterthwaite p-value.
- **Reporting / plots:** `wait_time_sentence()` prints `< 0.001` instead of `0`;
  `write_results_paragraph()` only claims significance when a level clears alpha;
  `wait_time_crossover()` reports the correct group beyond the crossover;
  `irr_plot()` no longer permutes significance colors; `icc` prints the
  confidence level (not `n_boot`) in its CI label; `plot_emmeans_interaction()`
  handles Poisson (`type = "response"`); `plot_effects()` respects `type`;
  `plot_disparities()` uses a proper difference-of-proportions CI; density/scatter
  plots keep same-day (0-day) appointments under `transform = "none"`.
- **Classifiers / parsers / data:** anchored country/brand substrings in
  `classify_medical_school()` and `classify_practice_setting()` (Indiana/New
  Mexico/Nova/Penn no longer misclassified); `parse_physician_name()` handles the
  documented "Last, First" format; NANP table adds PR 787 / GU 671 / VI 340; the
  `fips` dataset docs now match the shipped state table; hardcoded "including the
  District of Columbia" clauses are gated on DC actually being present.

  Note: BUGS.md #21 (non-duplicate-mode insurance assignment) was left as-is;
  the proposed change conflicts with the package's intended and tested
  insurance-assignment behavior and warrants a product decision.

## Bug fixes

- `mysterycall_irr_to_days()`: the narrative sentences no longer take `abs()`
  of the day-scale confidence-interval bounds. Signs are preserved, so a
  zero-crossing (non-significant) CI such as `[-6.5, +11.4]` is printed with
  its negative lower bound instead of being flipped to a spurious positive
  interval; interval-crossing estimates are now flagged
  "(difference not statistically significant)".
- `mysterycall_irr_to_days()` and `mysterycall_results_paragraph()`: report
  wording is parameterized via new `subject` (default `"callers"`) and, for
  `mysterycall_irr_to_days()`, `exposure_descriptor` (default `"insured"`)
  arguments. Set `exposure_descriptor = NULL` for non-insurance exposures so
  sentences read "Laryngology callers" rather than "Laryngology-insured
  callers". Defaults preserve existing insurance-study output.
- `mysterycall_overdispersion_test()`: documented (new "Mixed-effects caveat"
  section) that `df.residual()` counts only fixed-effect parameters for GLMMs,
  so phi is an approximation there; `DHARMa::testDispersion()` is recommended
  for a formal GLMM dispersion check. The NB/GLMM-aware interpretation branch
  (low residual phi is expected, not overfitting) is now shipped in the built
  package.

## New functions

### Environment / market covariates
- mysterycall_get_payer_mix(): county payer mix from ACS S2701 + coverage-type
  tables (B27002/B27003/C27006/C27007/B27001) — Private / Public / Medicaid /
  Medicare / Uninsured shares with propagated 90% MOEs
- mysterycall_get_county_provider_counts(): distinct providers per county FIPS,
  with optional per-100k density and specialty breakdown
- mysterycall_summarize_county_enrollment(): aggregate county Medicare/Medicaid
  enrollment (e.g. from mysterycall_get_cms_enrollment()) into a Medicaid-to-
  Medicare ratio and DOJ/FTC-style access category
- mysterycall_add_medicaid_expansion(): join ACA Medicaid-expansion status by
  state, with an as-of-call-date flag that correctly classifies NC (2023-12-01)
  and SD (2023-07-01) calls made before those states expanded
- mysterycall_read_kff_hhi() / mysterycall_add_hhi(): KFF per-MSA market-
  concentration HHI as a covariate (hhi, hhi_k = hhi/1000, DOJ/FTC hhi_cat)

### Covariate lookups (from consolidation / isochrones)
- mysterycall_medicaid_fee_index(): retrieve KFF state-level Medicaid-to-Medicare fee index ratios
- mysterycall_calculate_spatial_density(): compute local clinic concentration using vectorized Haversine distance
- mysterycall_model_zero_wait(): model same-day appointments (zero wait times) via binomial logistic regression
- mysterycall_compare_count_families(): compare Poisson, linear NB, and quadratic NB mixed models via AIC/BIC
- mysterycall_model_nonlinear(): fit natural cubic splines or polynomial terms for continuous predictors and plot curves
- mysterycall_calculate_hq_distance(): compute Haversine distance to private equity platform regional headquarters for instrumental variable analysis
- mysterycall_track_clinician_churn(): track longitudinal clinician staffing and annual churn rates at the practice level from NPPES history in DuckDB
- mysterycall_get_acs_female_insurance(): query Census API for female insurance enrollment percentages at the census tract level
- mysterycall_get_hrsa_ahrf(): retrieve county-level health resource and clinician metrics from HRSA AHRF
- mysterycall_get_cms_enrollment(): extract monthly Medicare/Medicaid enrollment from CMS reports

- mysterycall_run_analysis(): full 9-step pipeline orchestrator
- mysterycall_irr_table() / mysterycall_model_gt(): publication-ready gt tables
- mysterycall_dedup_by_insurance(): deduplicate by phone x insurance
- mysterycall_physicians_with_detail(): fetch full rows for flagged IDs
- mysterycall_descriptive_stats(): median / Q1 / Q3 with sentence
- mysterycall_distribution_summary(): modal category with sentence
- mysterycall_demographics_sentence(): prose from gender/specialty/credential distributions
- mysterycall_wait_time_by_group(): grouped median / IQR table
- mysterycall_wait_time_sentence(): Poisson p-values woven into prose
- mysterycall_insurance_wait_sentence(): Medicaid vs BCBS IRR paragraph
- mysterycall_scenario_summary(): call counts by scenario with sentence
- mysterycall_sensitivity_both_insurance(): paired-insurance sensitivity analysis
- mysterycall_univariate_lmm_screen(): LMM univariate predictor screen with IRR
- mysterycall_interaction_screen(): pairwise interaction LMM screen with AIC
- mysterycall_univariate_poisson_screen(): simple GLM Poisson predictor screen
- mysterycall_r2_sentence(): marginal / conditional R² prose
- mysterycall_random_effect_variance(): ICC + VarCorr table with interpretation
- mysterycall_overdispersion_sentence(): Pearson phi dispersion test with tiers
- mysterycall_clean_medicaid_col(): recode Medicaid acceptance to 0/1
- mysterycall_facet_histogram(): faceted histogram with stats annotation
- mysterycall_log_histogram(): log-scale faceted histogram
- mysterycall_simple_poisson(): simple Poisson GLM with IRR table and manuscript sentence
- mysterycall_flag_repeat_physicians(): QC flag for repeated physician entries
- mysterycall_flag_exclusion_discrepancy(): QC flag for excluded rows with wait times
- mysterycall_flag_excluded_with_appointments(): QC flag for excluded rows with days > 0
- mysterycall_flag_included_na_appointments(): QC flag for included rows with NA days
- mysterycall_sample_demographics(): physician sample summary with sentence
- mysterycall_insurance_acceptance_rates(): Medicaid vs BCBS acceptance rate computation

## Improvements
- Lme4 singular-fit warnings suppressed in lmm/interaction/r2/randeff functions
- NA rows pre-filtered in histogram functions before ggplot construction
- p_adjust_method parameter added to univariate_lmm_screen, univariate_poisson_screen, interaction_screen
- Input validation standardised with checkmate across all new functions

## Vignettes
- "Mystery Caller Workflow" vignette added: end-to-end 12-section walkthrough

# mysterycall 1.6.0

Released 2026-06-25.

## ✨ New functions

* **`mysterycall_predict_appointment()`** — generates predicted appointment-
  acceptance probabilities (plus optional delta-method 95% CIs) for new patient
  or practice profiles from a fitted `mysterycall_logistic_model` object.
  Population-level predictions (`re.form = NA`) are the default, appropriate
  for new practices unseen during model training.

* **`mysterycall_enrich_npi()`** — end-to-end NPI enrichment pipeline: validates
  NPIs, looks up clinician data, genderizes first names, classifies practice
  setting, and assigns ACOG/census regions. Returns a deduplicated data frame.

* **`mysterycall_parse_redcap_labels()`** — parses REDCap data-dictionary
  choice labels into tidy `data.frame`s matching scenario × insurance × NPI
  patterns used in mystery-caller study designs.

* **`mysterycall_calendar_sensitivity()`** — side-by-side comparison of
  wait-time LMMs fit on calendar days vs. business days, reporting
  coefficient deltas and flagging results that differ meaningfully between
  the two timescales.

* **`medicaid_expansion`** data object — 51-row KFF-sourced dataset recording
  each state's Medicaid expansion status (adopted / not adopted) for use in
  stratified analyses.

## ✨ Improvements

* **broom-compatible `tidy()` methods** added for `mysterycall_lmm`,
  `mysterycall_logistic_model`, and `mysterycall_poisson_model` result objects
  via the `generics` package (now in `Imports`).

* **`mysterycall_lmm()`** — auto log-transform now reports geometric-mean
  ratios (GMR) with confidence intervals alongside the standard coefficient
  table.

* **`assign_region()`** — factor inputs are now silently coerced to character
  rather than erroring; non-character, non-factor input gives a clear error.

* **`mysterycall_get_clinician_data()`** — duplicate columns are dropped before
  column-binding to prevent `cbind` errors when API responses overlap with
  base data frame columns.

* **`caller_reliability()`** — emits a `warning()` (not an error) when fewer
  than 30 complete pairs are found, noting that ICC and kappa estimates are
  unreliable at small *n*.

* **`mysterycall_table1()`** — gains an `as.data.frame()` S3 method so results
  can be piped directly into `flextable` or `knitr::kable()`.

* **`bizdays` fallback** — `mysterycall_business_days()` now falls back to
  calendar days with a `message()` instead of `stop()`-ing when the `bizdays`
  package is not installed.

## 🐛 Bug fixes

* Fixed a namespace-locking bug in the test suite: 37 test files were calling
  `library(mysterycall)` inside `devtools::test()`, which locked the package
  namespace and silently broke all subsequent `with_mocked_bindings()` calls.
  All such calls have been removed.

* Fixed 11-digit NPI generation in regression-match-rate mocks when *n* > 10
  (changed from `paste0("123456789", 0:(n-1))` to `sprintf("1%09d", seq_len(n))`).

* Corrected ACOG district for Texas: District XI (not VII).

---

# mysterycall 1.5.0

Released 2026-06-15.

## ✨ New functions

* **`mysterycall_prepare_calls()`** — merges phase-1 provider list with REDCap
  wave schedule, assigns callers, and exports call sheets ready for upload.

* **`mysterycall_strobe_flow()`** — generates a STROBE-compliant participant
  flow diagram (DiagrammeR / Graphviz) from a named list of screening counts.

* **`mysterycall_logistic_model()`** — fits a mixed-effects logistic regression
  for binary outcomes (e.g., appointment offered yes/no), returns odds ratios,
  CIs, and a publication-ready OR table.

* **`mysterycall_forest_plot()`** — renders a forest plot from any `tidy()`-
  compatible model object, with optional reference-line and faceting by
  outcome variable.

* **`mysterycall_auto_model()`** — selects the best GLMM family (Poisson,
  negative-binomial, zero-inflated) by AIC/BIC and overdispersion diagnostics,
  with an optional linear mixed-model evaluation step.

## ✨ Improvements

* `mysterycall_auto_model()` gained an LMM evaluation step that fits a
  log-transformed LMM as an additional candidate and includes it in the AIC
  comparison table.

* Comprehensive adversarial + semantic test suite for `mysterycall_auto_model`
  (52 passing tests, 1 skip).

---

# mysterycall 1.4.0

Released 2026-06-02.

## 💥 Breaking changes

* **Data objects renamed to snake_case** to align with package style:
  * `cityStateToLatLong` → `city_state_to_lat_long`
  * `ACOG_Districts` → `acog_districts`
  Update code that referenced these objects directly. The .rda files in
  `data/` were renamed accordingly.

* **Many internal helpers removed from the public API.** 79 functions were
  demoted from exported to internal as part of rOpenSci submission prep —
  logging helpers (`mysterycall_log_*`), progress-bar primitives
  (`mysterycall_progress_*`, `mysterycall_multi_*`, `mysterycall_spinner_*`),
  address-normalizer field helpers (now wrapped by
  `mysterycall_normalize_address_df()`), sanity-check internals, and
  unprefixed deprecation shims. Total exports dropped from 230 to 152.
  If your code used any of these, switch to a `mysterycall:::name()` call
  or refactor to use the higher-level wrappers.

* **`provider` package dependency removed.** The optional GitHub-only
  `provider` package is no longer listed in `Suggests`.
  `mysterycall_get_clinician_data()` still detects it dynamically if
  installed.

## ✨ Improvements

* **CRAN-readiness fixes.** `R CMD check --as-cran` now passes with zero
  errors, zero warnings, and only the standard "New submission" NOTE.
  Highlights:
  * Stripped `install.packages('X')` instructions from ~70 error messages.
  * Replaced `ggforce::geom_circle` in `mysterycall_plot_source_venn()`
    with a base-ggplot2 `geom_polygon` implementation (no `ggforce` dep).
  * Replaced `tigris::fips_codes` example with a hardcoded vector (no
    `tigris` dep).
  * Fixed 301/404 URLs (HERE developer portal, ACGME, USDA ERS).
  * Soft-fail in `mysterycall_preflight_check()` when optional Suggests
    are missing.
  * Vignettes guard chunks that use Suggests-only deps with
    `requireNamespace()`.

* **rOpenSci alignment.** R/ filenames lowercased (`ACOG_Districts.R`,
  `Splitting_dataframe_to_send_to_callers.R`, `cityStateToLatLong.R`,
  `states_where_physicians_were_NOT_contacted.R` →
  snake_case equivalents). All 12 publication/green-journal theme and
  palette functions now carry the `mysterycall_` prefix (e.g.,
  `mysterycall_theme_green_journal()`,
  `mysterycall_palette_publication()`).

* **Suggests dependency reduction.** Dropped four unused packages
  (`imager`, `leaflet.extras`, `tmap`, `tigris`) plus `ggforce`. Suggests
  count: 48 → 43.

* **Documentation hygiene.** `devtools::document()` now runs cleanly;
  data documentation converted from the trailing-string-literal pattern
  to the universal `@name + NULL` pattern. New tests added for
  `R/academic_indicators.R` and `R/audit-verify.R`. ORCID and R-version
  badges added to README and pkgdown index.

# mysterycall 1.3.0

Released 2026-05-08.

## 💥 Breaking changes (with backward compatibility)

* Package renamed from `mysterycall` to `mysterycall`. `library(mysterycall)` will no longer
  work; use `library(mysterycall)`.
* All 100 exported functions now carry the `mysterycall_` prefix (e.g.,
  `mysterycall_geocode()`, `mysterycall_search_and_process_npi()`).
  The previous `mysterycall_` prefix names are retained as deprecated shims that
  emit a warning and forward to the new name. The even-older unprefixed names
  (e.g., `check_normality()`) continue to work as double-deprecated shims.

## ✨ New functions

**Data quality and validation**

* `mysterycall_validate_phone()` — validates US phone numbers against NANP
  structural rules (NPA/NXX first-digit constraints, N11 service codes) and
  optionally checks that the area code belongs to the provider's reported
  practice state via a bundled lookup table. Returns a tidy data frame with
  `phone_e164_valid`, `phone_npa`, `phone_state_from_npa`,
  `phone_area_code_matches_state`, and `phone_validity_flag` columns.
  Fully vectorised; lookup table is lazy-loaded and cached per session.

* `mysterycall_parse_physician_name()` — converts free-text physician name
  strings (board certification data, NPPES, CMS sources) into structured
  first / middle / last / suffix / title fields with confidence scoring
  (`high` / `medium` / `low`) and warning flags. Handles DO credential vs.
  Vietnamese surname disambiguation (`"Robert Smith DO"` → suffix `"DO"`;
  `"Linda Do"` → last name `"Do"`), three-part comma format
  (`"Smith, John, Jr."`), hyphenated names, and name particles.

* `mysterycall_validate_parsed_names()` — extends parse output with quality
  flags: `has_first`, `has_last`, `is_valid`, `last_is_credential`,
  `last_is_suffix`, `last_too_short`, `middle_has_particle`, `quality_issue`.

* `mysterycall_format_physician_name()` — reassembles parsed components into
  `"last_first"`, `"first_last"`, or `"formal"` display strings; vectorised.

* `mysterycall_test_name_parser()` — runs a 13-case edge-case accuracy suite
  and prints a per-case report to the console. An extended 30-case benchmark
  corpus is available in `inst/extdata/name_benchmark_corpus.csv`; the
  evaluation script is in `data-raw/benchmark_name_parser.R`.

**Safe join wrappers**

* `mysterycall_safe_left_join()` — wraps `dplyr::left_join()` with key-type
  harmonisation, right-side uniqueness assertion, coverage threshold
  enforcement (`min_coverage`, default 0.98), row-multiplication guard
  (`max_duplication`, default 1.02×), and optional CSV audit report.

* `mysterycall_safe_inner_join()` — wraps `dplyr::inner_join()` with the same
  guards; default `min_coverage = 0.90`.

* `mysterycall_safe_semi_join()` — wraps `dplyr::semi_join()` with a
  keep-rate threshold; default `min_coverage = 0.50`.

* `mysterycall_safe_anti_join()` — wraps `dplyr::anti_join()` with an
  over-exclusion cap (`max_matched`, default 1.0).

* `mysterycall_assert_unique_keys()` — asserts that specified columns form a
  unique key; optionally deduplicates (first row kept) instead of erroring.

**Package infrastructure**

* `humaniformat` moved from `Suggests` → `Imports`; the runtime
  `requireNamespace()` guard has been removed.
* 119 new `test_that` blocks across three new test files
  (`test-validate-phone.R`, `test-parse-physician-name.R`,
  `test-join-safety.R`).
* Five new vignettes: `data-quality`, `statistical-analysis`,
  `provider-classification`, `workflow-orchestration`, `table-generation`.
* `CITATION.cff` updated with full abstract, keywords, and affiliation.
* `CONTRIBUTING.md` expanded to a full developer guide.

## ✅ rOpenSci compliance

* Replaced all 34 `\dontrun{}` blocks with `@examplesIf interactive()`.
* Replaced 18 live `print()` calls with `message()` or `invisible()`.
* Moved `sf` from `Imports` to `Suggests`; added `requireNamespace()` guards
  in 8 geospatial functions to avoid forcing GDAL/GEOS/PROJ on all users.
* Bumped minimum R version from 3.5.0 to 4.1.0.
* Removed duplicate `Maintainer:` field from `DESCRIPTION`.
* Added GitHub issue/PR templates and `repostatus.org` badge.

---

# mysterycall 1.2.2

Released 2026-05-04.

## 🐛 Bug fixes

* `library(mysterycall)` no longer crashes R or causes system memory exhaustion.
  Seven heavy packages (`ggmap`, `ggspatial`, `hereR`, `leaflet`,
  `leaflet.extras`, `lme4`, `censusapi`) were moved from `Imports` to
  `Suggests` so their compiled spatial libraries (GDAL, GEOS, PROJ) are
  loaded **only when the relevant function is first called**, not on package
  attach. Two packages declared in `Imports` but never called (`tigris`,
  `effects`) were removed entirely.

* `create_isochrones()` no longer accumulates memoized results in RAM
  indefinitely. The internal memoization object is now exposed through
  `mysterycall_clear_isochrone_cache()`. Call it after processing a large
  batch to reclaim memory.

* `create_isochrones_for_dataframe()` and `create_individual_isochrone_plots()`
  previously called `beepr::beep()` unconditionally even though `beepr` is a
  suggested package. Both calls are now guarded with `requireNamespace()`.

## ✨ New features

* `mysterycall_search_taxonomy()` gains three new arguments:
  - **`states`** — loops over each state and deduplicates on NPI, bypassing
    the NPI API's hard 1,200-record-per-query cap. Pass all 50 state
    abbreviations to perform a complete national search.
  - **`city`** — optional city filter passed directly to `npi::npi_search()`.
  - **`limit`** — controls records per API call (max 1,200).

* All mapping and geospatial functions now emit a clear `stop()` message with
  the exact `install.packages()` command if a required optional package is
  not installed.

---

# mysterycall 1.2.1

Released 2025-10-23.

## 📝 Documentation

* Released to align all metadata artifacts with the package website and
  codemeta specification.
* Introduced an **Imotive News & Changelog** vignette centralizing release notes.
* Documented how `mysterycall_run_workflow()` coordinates roster creation,
  validation, call preparation, and QA for Imotive projects.

## ✨ New features

* `mysterycall_not_contacted_states()` now ignores rows without affirmative
  contact outcomes and reports the number of unique physicians reached.

## 🗑️ Deprecated

* `search_npi()` → use `mysterycall_search_and_process_npi()`
* `test_and_process_isochrones()` → use `mysterycall_isochrones_for_df()`
* `process_and_save_isochrones()` → use `mysterycall_isochrones_for_df()`

---

# mysterycall 0.0.0.9000

## 🌱 Initial development

* Added `NEWS.md` to track changes.
* Verified R-CMD-check workflows on macOS, Windows, and Ubuntu.
* Moved `provider` to `Suggests`; added runtime checks throughout.
* Refactored `mysterycall_genderize()` to use the Genderize.io API, removing
  the dependency on the non-CRAN `genderdata` package.
* Added `mysterycall_geocode()` to simplify geocoding lists of addresses.
* Added vignette skeleton on aggregating provider data.
