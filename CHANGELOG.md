# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Street-address agreement primitives: mysterycall_street_address_key(), mysterycall_street_address_agreement() and mysterycall_street_addresses_agree() (#282). A three-verdict vocabulary -- corroborates, conflicts, uninformative -- so a missing address is evidence of nothing rather than a disagreement. Unit designators dropped and roadway suffixes excluded before comparison, so "123 Main St" cannot corroborate "123 Oak St" on the strength of both being streets. Every verdict carries a reason from a closed vocabulary
- Organization-name agreement primitives: mysterycall_org_names_agree(), mysterycall_org_tokens(), mysterycall_count_meaningful_org_tokens(), mysterycall_weighted_token_similarity() and the exported MYSTERYCALL_GENERIC_ORG_TOKENS (#282). A substring match alone is insufficient: at least min_meaningful_tokens non-generic tokens must appear on both sides, so "University Medical Center" does not match "University Medical Center Hospital" on words half the market shares
- vignette("entity-agreement"): appendix on the agreement primitives, the three-verdict vocabulary, why absence is uninformative rather than a conflict, and how they relate to the safe-join guards. The eight new exports had reference documentation but appeared in no vignette
- Standard S3 accessors for the four fitted-model classes: coef(), vcov(), confint(), nobs(), formula(), fitted(), residuals() and summary() on mysterycall_poisson_model, mysterycall_nb_model, mysterycall_lmm and mysterycall_logistic_model. Each delegates to the underlying lme4 or glmmTMB fit. Previously coef(), fitted() and residuals() fell through to the *.default methods, found no matching list element, and returned NULL with no error -- a silent NULL where a coefficient vector was expected. Not defined for the table and report classes, which are formatted results rather than models
- confint() reports Wald intervals at the level the model was fitted with rather than a hard-coded 0.95, so it cannot disagree with the interval already in irr_table / coef_table / or_table; for mysterycall_lmm() it uses the Satterthwaite t quantile with the per-term degrees of freedom, as the fitter does. conf_level is now recorded on all four fitted-model objects
- strict_counts argument on the count fitters: the default keeps the existing warning for a fractional outcome, TRUE refuses the fit. A count of days is integer-valued by construction, whereas elapsed time in days may legitimately carry decimals -- in which case a count distribution is the wrong model. Values are never rounded or truncated either way
- dispersion_details on the count fitters: the method, the formula verbatim, the Pearson chi-square, the denominator used, observation and parameter counts, the engine's own residual df for comparison, how many residuals were not finite, and the assumptions -- so the dispersion statistic can be reproduced rather than taken on trust. pearson_chisq / df equals overdispersion exactly
- fit_warnings on the count fitters: every engine warning, de-duplicated, separate from the convergence verdict
- validate_coordinates() and validate_log_offset() internal guards, with coordinate-domain validation wired into mysterycall_calculate_spatial_density(), mysterycall_calculate_hq_distance() and mysterycall_assign_area_covariates()
- vignette("model-objects"): appendix on what a fitted object contains, the accessors it answers, and the analytic-cohort invariants -- including why NA, NaN, Inf and fractional counts are each handled differently
- vignette("statistical-analysis") section 3.9 on the standard accessors
- Direct tests for mysterycall_calculate_spatial_density(), which was exported with none, including agreement with sf::st_distance() as an independent geodesic reference; an analytic-cohort suite; a review-findings suite; and an adversarial contract suite for the count fitters that fails when a safety mechanism is absent rather than confirming the functions merely run
- srr/: first-pass assessment of all 285 rOpenSci statistical software standards, with per-standard evidence and the downloaded standards texts. Excluded from the package tarball
- audit/: verification evidence for the above -- the fault-injection results and the invariants each test defends
- mysterycall_flow_spec(): validates that a STROBE/CONSORT participant flow closes before anything is drawn -- each spine step minus its exclusions equals the next step, every split sums to its parent, and no count is negative, fractional, NA or duplicated. Failures are collected and name the step ("Screened (100) minus 5 excluded is 95, but the next step Analysed is 90"). Separating validation from rendering is the point: the same call runs in a test suite, where a stale figure is actually caught
- mysterycall_strobe_diagram(): draws a validated spec and refuses anything else. ggplot2 only, so no Graphviz or headless browser is needed and the figure rebuilds in a plain CI container. Handles a spine of any length, several exclusion reasons per step, and splits nested to any depth
- vignette("participant-flow"): appendix on why a renderer cannot catch a reporting error, what the validator checks, how to put that check in a test suite, and how the four flow functions relate
- mysterycall_sampl_checklist(): 27-item fillable SAMPL (Statistical Analyses and Methods in the Published Literature) reporting checklist across eight sections, tailored to the estimands a mystery-caller audit produces; companion to the STROBE and CRiSP checklists
- mysterycall_format_ci(): interval formatter with a `sep` argument defaulting to getOption("mysterycall.ci_sep", " to "), so the house style is one setting rather than 39 hardcoded call sites; follows gtsummary's JAMA/Lancet journal-theme pattern (MIT, cited in the docs)
- mysterycall_format_p(): exact p-value formatter, never emits "NS"; `name=` yields the prefixed "p < 0.001" prose form alongside the bare table-cell form
- vignette("reporting-conventions"): appendix documenting the SAMPL conventions the package enforces, the three places it deliberately departs from them, and the three reporting checklists
- .github/scripts/check-pkgdown-index.R: fails in about a second when a documented topic is missing from the pkgdown reference index, instead of after a ~15 minute site build; wired into repo-hygiene
- mysterycall_guard_contaminated_wait(): hard guard that refuses to analyse a fill-down (LOCF) contaminated wait-time column; checks for waits with no appointment date, waits on excluded calls, and unjustified carry-forward runs
- inst/contract/cohort_2019_fpmrs.yml: frozen cohort record for the 2019 FPMRS study (three nesting populations, the reproduced primary finding, retired figures, and the known-bad variable with its disposition), pinned behind a SHA-256
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
- mysterycall_irr_table(): publication-ready IRR gt table
- mysterycall_model_gt(): publication-ready model gt table
- mysterycall_dedup_by_insurance(): deduplicate rows by phone x insurance combination
- mysterycall_physicians_with_detail(): fetch full data rows for flagged physician IDs
- mysterycall_descriptive_stats(): compute median / Q1 / Q3 and return a prose sentence
- mysterycall_distribution_summary(): identify modal category and return a prose sentence
- mysterycall_demographics_sentence(): generate prose from gender/specialty/credential distributions
- mysterycall_wait_time_by_group(): grouped median / IQR wait-time table
- mysterycall_wait_time_sentence(): weave Poisson p-values into a manuscript sentence
- mysterycall_insurance_wait_sentence(): build a Medicaid vs BCBS IRR paragraph
- mysterycall_scenario_summary(): tabulate call counts by scenario with a prose sentence
- mysterycall_sensitivity_both_insurance(): run paired-insurance sensitivity analysis
- mysterycall_univariate_lmm_screen(): LMM univariate predictor screen returning IRR per variable
- mysterycall_interaction_screen(): pairwise interaction LMM screen with AIC comparison
- mysterycall_univariate_poisson_screen(): simple GLM Poisson predictor screen
- mysterycall_r2_sentence(): generate marginal / conditional R² prose from a fitted model
- mysterycall_random_effect_variance(): compute ICC and VarCorr table with interpretation
- mysterycall_overdispersion_sentence(): Pearson phi dispersion test with severity tiers
- mysterycall_clean_medicaid_col(): recode Medicaid acceptance column to binary 0/1
- mysterycall_facet_histogram(): faceted histogram with inline stats annotation
- mysterycall_log_histogram(): log-scale faceted histogram for skewed wait-time data
- mysterycall_simple_poisson(): simple Poisson GLM returning IRR table and manuscript sentence
- mysterycall_flag_repeat_physicians(): QC flag for repeated physician entries in call data
- mysterycall_flag_exclusion_discrepancy(): QC flag for excluded rows that still have wait times
- mysterycall_flag_excluded_with_appointments(): QC flag for excluded rows with days > 0
- mysterycall_flag_included_na_appointments(): QC flag for included rows with NA days
- mysterycall_sample_demographics(): physician sample summary with a prose sentence
- mysterycall_insurance_acceptance_rates(): compute Medicaid vs BCBS acceptance rates

### Fixed
- mysterycall_acceptance_rate_calc() computed reachability per call row rather than per physician (#288). With duplicate call rows a physician reachable in one row and unreachable in another was subtracted from the denominator, so the numerator could exceed it -- acceptance rates above 100%, and a crash when prop.test() inside the Wilson interval was handed k > n. One doubly-entered office was enough
- The ZIP-5 core fabricated valid-looking ZIPs from corruption (#287): a ZIP+4 that had lost its leading zero ("21011234") became 21011 instead of 02101, scientific notation ("1.2e5") was reassembled into 00001, and a phone number in the ZIP column became a ZIP. Digit runs must now match a shape a ZIP can have
- read_table() NPI coercion rounded fractional corruption into a different valid-looking NPI (#287): sprintf("%.0f") turned 123456789.5 into 123456790 and printed Inf as "Inf". Coercion now goes through mufflyaccess::canon_npi() and a fractional value becomes missing with a warning
- mysterycall_luhn_check() accepted checksum-passing values that cannot be NPIs (#283): CMS issues NPIs beginning 1 or 2, and about one in ten arbitrary ten-digit strings passes Luhn by chance, so "0103000788" was accepted. mysterycall_validate_npi() now delegates to it rather than npi::npi_is_valid(), so the two paths cannot disagree
- .mc_state_to_abbr() recognised neither DC nor Puerto Rico and passed unrecognised values through (#283)
- .safe_divide() was scalar-only and errored on vector input (#283)
- Physician-name parsing never stripped parentheticals, so a nickname was parsed into middle_name and a maiden name as the surname, and generational suffixes were only captured after a comma (#283)
- The nightly portability gate failed on two non-ASCII em-dashes in first-line comments of R/flow_spec.R and R/strobe_diagram.R, introduced in #265; escapes are not interpreted in comments
- mysterycall_street_addresses_agree() was exported but missing from the pkgdown reference index, failing repo-hygiene
- The nightly roxygen pin lagged Config/roxygen2/version, which makes doc-drift report a version mismatch instead of drift
- The reported analytic cohort could disagree with the cohort the model used. Fitting engines apply their own na.action, so a value that only becomes undefined inside the model formula -- log() of a non-positive offset -- was dropped by the engine without passing through the complete-case filter: a 120-row frame with three negative exposures produced a model fitted on 117 rows while the object reported n = 120, n_dropped = 0. Every denominator derived from that object was wrong by three and nothing said so. All five fitters that report an n now reconcile it against the rows the engine used and refuse a mismatch
- A log offset of zero, negative or non-finite exposure is refused before fitting, naming the column, the count, the offending values and the rows in the caller's data frame. Values are never replaced with a small positive constant; that choice belongs to the analyst
- NaN is distinguished from NA in outcomes and exposures. Because is.na(NaN) is TRUE, a NaN was previously swept into the missing-data count and excluded silently
- A latitude of 500 was accepted by mysterycall_calculate_spatial_density() and returned a plausible neighbour count, because the haversine formula is finite for any real argument. Coordinates outside [-90, 90] / [-180, 180], and non-numeric, NaN or infinite values, are now refused. Latitude and longitude are never silently reordered
- mysterycall_calculate_spatial_density() returned a density of 0 for a point with a missing coordinate, indistinguishable from a genuinely isolated practice; it now returns NA_integer_ and reports how many points were affected
- The negative binomial dispersion statistic was wrong for any fit that was not a plain NB2. It took its numerator from fitted() and its denominator from sqrt(mu + mu^2/theta), which are two different models: for a zero-inflated fit, fitted() is the zero-inflation-marginal mean while the variance term is the conditional variance, inflating the statistic by about 2.6x on a sample with 29% structural zeros. With a non-constant dispformula, sigma() returns NA, every residual was NA, and sum(na.rm = TRUE) reported a dispersion of exactly 0 -- read as extreme underdispersion. Both values reach a manuscript through mysterycall_strobe_checklist() and mysterycall_model_comparison_table(). The Pearson residual now comes from the fitting engine; a model without zero-inflation is numerically unchanged, verified to machine precision
- A non-integer count outcome produced roughly 1,900 muffled per-observation engine warnings, stored them all on the result object, and flipped convergence$converged to FALSE, misfiling a units error as an optimizer failure
- A convergence warning could be discarded by the warning de-duplication cap, leaving an object claiming a fit converged when glmmTMB's "extreme or very small eigenvalues detected" -- the only signal for a numerically singular covariance when the optimizer code is 0 -- had fired. Convergence-related warnings are never capped
- subset and na.action passed through ... are refused by name, because they make the engine fit a different set of rows than the function reports. The check uses pmatch(), so partial argument matching (subs =) cannot slip past
- vignette("statistical-analysis") described the confidence intervals in irr_table as "95 % profile likelihood confidence intervals ... preferred over Wald intervals". They are Wald intervals. The same mislabel appeared in three illustrative manuscript sentences, any of which a reader could have copied into a paper while stating a method the package did not use. (mysterycall_simple_poisson() does compute genuine profile intervals, so the label was wrong only for the GLMM fitters; the package's own prose generators emit a neutral "95% CI" and were never affected)
- vignette("statistical-analysis") documented $overdispersion as a list with $pearson_chisq, $residual_df, $ratio and $interpretation elements. It is a numeric scalar; the computation lives in $dispersion_details
- importFrom(stats, nobs) was missing. Because S3method(nobs, ...) needs the generic at load time, the package failed to load in any session where stats was not already attached
- mysterycall_multi_model_table() rendered a negative linear-mixed-model estimate as `-0.28 (-0.45--0.12)`, which is genuinely ambiguous. Now `-0.28 (-0.45 to -0.12)`. The same applied to percentage-point differences in mysterycall_disparities_table(); ratio measures hid the defect because they cannot be negative
- mysterycall_geocode_address() silently discarded the coordinates of every matched address in any Census batch that began with a No_Match, and errored outright on an all-unmatched batch. The API returns ragged rows (twelve fields matched, three unmatched) and readr::read_csv() sizes the frame from the first row, so the result depended on which address happened to sort first. Parsing now runs against the full twelve-column superset with short rows padded
- Stale roxygen in mysterycall_results_paragraph() still documented the confidence interval as `<lo>-<hi>` after the formatter changed to "<lo> to <hi>"
- README documented a `census_summaries` dataset that does not exist, and omitted seven that do (adi_zcta, svi_zcta, zcta_tract_xwalk, medicaid_expansion, medicaid_fee_index, kff_hhi, healthgrades_ages)
- Non-deterministic coverage failures: DESCRIPTION sets Config/testthat/parallel, so the suite fans across callr subprocesses and a dead worker collapsed the covr run into an opaque .Rout.fail. Coverage workflows now set TESTTHAT_PARALLEL=FALSE; the `tests` job still exercises the parallel path
- Nightly coverage job failed without reporting what failed; it now pins install_path and prints testthat.Rout.fail, matching test-coverage.yaml
- Two pull-request checks hung 77 minutes on r-lib/actions/setup-r with no timeout-minutes, so GitHub's six-hour default applied

### Changed
- mysterynpi and mufflyaccess are hard dependencies, in Imports with Remotes so pak installs the GitHub-only siblings automatically (#283), mirroring how mysterymaps and mysterymedicaid depend on mysterycall
- The three ZIP-5 normalisers share one .zip5_core() parameterised by their documented minimum-digit contracts rather than re-implementing extract/truncate/pad independently (#283)
- convergence$converged now reports the optimizer, and the Hessian for glmmTMB, rather than being cleared by any warning at all. A boundary-singular lme4 fit whose optimizer returned code 0 is reported as converged; singularity is a property of the data and continues to be reported in convergence$singular. $convergence keeps its previous shape and the content of its $messages
- Fitted-model objects gain conf_level, dispersion_details and fit_warnings elements. Code reading named elements is unaffected; code asserting an exact names() set will see them
- Confidence intervals, IQRs, and ranges now separate endpoints with " to " rather than a hyphen or en dash, across all 39 formatters that build them (tables, plots, sentence builders, print methods). Year ranges and wait-time band labels keep their dash: they are category names, not estimates, and cannot take a negative endpoint
- mysterycall_irr_table() no longer adds significance stars by default (add_significance_stars = FALSE) and its default footnote drops the "* p < 0.05" ladder; SAMPL asks for exact p-values rather than codes against alpha. Pass TRUE for a journal that requires them
- All 22 internal reimplementations of the `if (p < 0.001)` branch now route through mysterycall_format_p(); .mc_format_p() delegates to it, so its comment claiming to be the single source of truth is finally accurate. Output is unchanged, including results_paragraph()'s unspaced "p=", which is pinned by its own @return docs
- Suppressed lme4 singular-fit warnings via withCallingHandlers in lmm functions
- Pre-filter NA rows before ggplot construction in histogram functions
- p_adjust_method parameter added to univariate_lmm_screen, univariate_poisson_screen, and interaction_screen
- Input validation uses checkmate assertions across all new functions

### Infrastructure
- R-devel dropped from the per-push R-CMD-check matrix. RSPM ships binaries for released R, so on devel pak compiled all 57 Suggests from source and the job was cancelled on six of the last eight pushes to main, still inside "Installing system requirements". Those runs were not devel failing and being tolerated; devel was never being tested while the platform reported "cancelled". Coverage moves to nightly.yaml, which already allows it 150 minutes
- Frozen-cohort gate (.github/scripts/check-cohort-freeze.R): validates the cohort contract's structure and hash, re-proves that the contamination guard still rejects contaminated data and still passes honest data, and fails if a retired cohort figure reappears in prose. Wired into the nightly and the PR gate
- Scientific mutation campaign extended to 14 mutants, all killed; the two new ones reproduce the fill-down defect and the banded/numeric wait substitution
- Every job in every workflow now declares timeout-minutes (33 jobs across 9 files); the CI-of-CI assertion covers all workflows rather than only the nightly, and fails rather than warns
- R-devel check timeout raised to 150 minutes: it had been cancelled at 60 for five consecutive runs while still installing dependencies, so the platform was never actually verified
- Check matrix trimmed to six platforms; macos oldrel-1 (two unrelated segfaults) and ubuntu oldrel-2 (glmmTMB -> Deriv needs R >= 4.5) failed on causes outside this package
- pkgdown site configured (_pkgdown.yml with 131 exports indexed)
- covr test-coverage workflow added
- Mystery Caller Workflow vignette renders end-to-end (12-section walkthrough)

## [1.6.3] — 2026-07-19
- Earliest tagged release in this repository (v1.6.1, v1.6.2 and v1.6.3 exist; there is no v1.6.0 tag)

[Unreleased]: https://github.com/mufflyt/mysterycall/compare/v1.6.3...HEAD
[1.6.3]: https://github.com/mufflyt/mysterycall/releases/tag/v1.6.3
