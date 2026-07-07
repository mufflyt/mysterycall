# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
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

### Changed
- Suppressed lme4 singular-fit warnings via withCallingHandlers in lmm functions
- Pre-filter NA rows before ggplot construction in histogram functions
- p_adjust_method parameter added to univariate_lmm_screen, univariate_poisson_screen, and interaction_screen
- Input validation uses checkmate assertions across all new functions

### Infrastructure
- pkgdown site configured (_pkgdown.yml with 131 exports indexed)
- covr test-coverage workflow added
- Mystery Caller Workflow vignette renders end-to-end (12-section walkthrough)

## [1.6.0] — 2026-01-01
- Initial tracked release

[Unreleased]: https://github.com/mufflyt/mysterycall/compare/v1.6.0...HEAD
[1.6.0]: https://github.com/mufflyt/mysterycall/releases/tag/v1.6.0
