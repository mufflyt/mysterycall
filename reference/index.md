# Package index

## Data and Datasets

- [`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md)
  : ACOG Districts Data
- [`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md) :
  ACGME OBGYN Residency Data
- [`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md)
  : ACOG Past Presidents
- [`census_summaries`](https://mufflyt.github.io/mysterycall/reference/census_summaries.md)
  : Summarize Census Block Group Demographics
- [`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md)
  : City/state latitude and longitude reference data
- [`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md) :
  State-level FIPS codes
- [`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md)
  : KFF Hospital-Market Concentration (HHI) by Metropolitan Area, 2024
- [`medicaid_fee_index`](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md)
  : KFF Medicaid-to-Medicare Fee Index (All Services), 2024
- [`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md)
  : Physician Location and Specialty Data
- [`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)
  : Taxonomy Codes for Obstetricians and Gynecologists
- [`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md)
  : Area Deprivation Index (ADI) by ZCTA
- [`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md)
  : Social Vulnerability Index (SVI) by ZCTA
- [`zcta_tract_xwalk`](https://mufflyt.github.io/mysterycall/reference/zcta_tract_xwalk.md)
  : ZCTA to Census Tract crosswalk (area-weighted)
- [`healthgrades_ages`](https://mufflyt.github.io/mysterycall/reference/healthgrades_ages.md)
  : Healthgrades Physician Ages (current-year-adjusted)

## Provider Search and NPI

Find, validate, and enrich physician records via the NPI registry.

- [`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)
  : Search and Process NPI Numbers
- [`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
  : Search NPI Database by Taxonomy
- [`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md)
  : Validate and Remove Invalid NPI Numbers
- [`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md)
  : Retrieve Clinician Data
- [`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md)
  : Infer physician gender from first names via Genderize.io
- [`mysterycall_luhn_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_luhn_check.md)
  : Validate NPI numbers using the official CMS Luhn checksum
- [`mysterycall_extract_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_zip5.md)
  : Extract a clean 5-digit ZIP code from a dirty string
- [`mysterycall_extract_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_physician_name.md)
  : Extract a formatted physician name from a raw string
- [`mysterycall_parse_certification_subspecialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_certification_subspecialty.md)
  : Map an ABOHNS certification_type string to a subspecialty label
- [`mysterycall_check_generalist_presence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_generalist_presence.md)
  : Flag locations where generalist physicians are absent
- [`npi_utils`](https://mufflyt.github.io/mysterycall/reference/npi_utils.md)
  : NPI validation utilities
- [`address_utils`](https://mufflyt.github.io/mysterycall/reference/address_utils.md)
  : Address cleaning utilities
- [`caller_management`](https://mufflyt.github.io/mysterycall/reference/caller_management.md)
  : Caller-management utilities for mystery-caller studies
- [`specialty_utils`](https://mufflyt.github.io/mysterycall/reference/specialty_utils.md)
  : Specialty parsing and physician name extraction utilities

## Address Normalization

USPS-standard address normalization: directionals, suffixes, units,
state codes, ZIP extraction, and full data-frame normalization.

- [`address_normalizer`](https://mufflyt.github.io/mysterycall/reference/address_normalizer.md)
  : USPS Address Normalization Utilities
- [`mysterycall_ascii_norm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ascii_norm.md)
  : Normalize ASCII Characters and Whitespace
- [`mysterycall_caps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caps.md)
  : Convert to Canonical Uppercase
- [`mysterycall_is_po_box()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_is_po_box.md)
  : Detect PO Box Addresses
- [`mysterycall_has_street_number()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_has_street_number.md)
  : Detect Addresses with Street Numbers
- [`mysterycall_normalize_state()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_state.md)
  : Normalize State Names to USPS Codes
- [`mysterycall_normalize_directionals()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_directionals.md)
  : Normalize Directional Prefixes and Suffixes
- [`mysterycall_normalize_suffix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_suffix.md)
  : Normalize Street Suffixes
- [`mysterycall_normalize_units()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_units.md)
  : Normalize Unit Designators
- [`mysterycall_normalize_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_zip5.md)
  : Extract 5-Digit ZIP Code
- [`mysterycall_strip_suite()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strip_suite.md)
  : Remove Unit Designators from Address
- [`mysterycall_normalize_address_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_address_df.md)
  : Normalize All Address Fields in a Data Frame

## Academic Classification

Classify physician practice settings as academic vs. non-academic using
tiered confidence scoring and institution name patterns.

- [`academic_indicators`](https://mufflyt.github.io/mysterycall/reference/academic_indicators.md)
  : Academic Practice Indicators for Institution Classification
- [`mysterycall_classify_academic_affiliation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_academic_affiliation.md)
  : Classify Academic vs. Non-Academic Practice Setting
- [`mysterycall_check_academic_name_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_academic_name_patterns.md)
  : Check if Organization Name Suggests Academic Affiliation
- [`mysterycall_get_academic_indicators_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_academic_indicators_summary.md)
  : Export Academic Indicator Summary

## Regions

Assign ACOG regions to physician records. Geocoding, isochrones, and
publication maps now live in the mysterymaps package.

- [`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md)
  : Map US states to medical society districts and Census regions

## Census and Demographics

- [`mysterycall_get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md)
  : Get Census data of all state block groups
- [`mysterycall_summarize_census()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_census.md)
  : Produce summary statistics from Census block group data
- [`mysterycall_plot_census_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_census_age.md)
  : Plot the distribution of female age groups
- [`mysterycall_get_acs_adults_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md)
  : Get ACS Adult Population (Ages 18-90, Both Sexes) by Census Tract
- [`mysterycall_get_acs_women_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_women_18_90.md)
  : Get ACS Female Population (Ages 18-90) by Census Tract
- [`mysterycall_get_payer_mix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_payer_mix.md)
  : Build a county payer mix from ACS health-insurance coverage tables
- [`mysterycall_get_county_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_county_provider_counts.md)
  : Count distinct providers per county
- [`mysterycall_summarize_county_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_county_enrollment.md)
  : Summarize county Medicare/Medicaid enrollment and derive access
  ratio
- [`mysterycall_add_medicaid_expansion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_medicaid_expansion.md)
  : Join ACA Medicaid-expansion status onto study data (optionally as of
  the call date)
- [`mysterycall_read_kff_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_kff_hhi.md)
  : Read the KFF per-MSA HHI dataset and crosswalk it to CBSA
- [`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md)
  : Join a market HHI covariate onto office data

## Data Quality and Validation

Validate phone numbers against NANP rules and state geography; parse,
validate, and reformat free-text physician name strings; safe join
wrappers with coverage enforcement and right-side uniqueness guards.

- [`phone_validation`](https://mufflyt.github.io/mysterycall/reference/phone_validation.md)
  : Validate North-American phone numbers
- [`mysterycall_validate_phone()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_phone.md)
  : Validate North-American (NANP) phone number strings
- [`physician_name_parsing`](https://mufflyt.github.io/mysterycall/reference/physician_name_parsing.md)
  : Parse and validate physician names
- [`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md)
  : Parse physician names into structured components
- [`mysterycall_validate_parsed_names()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_parsed_names.md)
  : Validate parsed physician names for quality issues
- [`mysterycall_format_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_physician_name.md)
  : Format parsed physician name components into a display string
- [`mysterycall_test_name_parser()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_name_parser.md)
  : Run the built-in name-parser accuracy suite
- [`join_safety`](https://mufflyt.github.io/mysterycall/reference/join_safety.md)
  : Safe join wrappers with coverage validation
- [`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md)
  : Safe left join with coverage validation
- [`mysterycall_safe_inner_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_inner_join.md)
  : Safe inner join with cardinality checking
- [`mysterycall_safe_semi_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_semi_join.md)
  : Safe semi join with keep-rate enforcement
- [`mysterycall_safe_anti_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_anti_join.md)
  : Safe anti join with over-exclusion guard
- [`mysterycall_assert_unique_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assert_unique_keys.md)
  : Assert that join key columns are unique

## Data Cleaning and Processing

Clean Phase 1/2 data, rename columns, recode variables, and impute
missing values.

- [`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
  : Clean Phase 1 Results Data
- [`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md)
  : Clean and process Phase 2 data
- [`mysterycall_rename_columns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_rename_columns.md)
  : Rename columns by substring match
- [`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md)
  : Split data into multiple parts and save each part as separate Excel
  files
- [`mysterycall_remove_constants()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_remove_constants.md)
  : Remove Constant Variables from a Data Frame
- [`mysterycall_remove_near_zero()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_remove_near_zero.md)
  : Remove Near-Zero Variance Variables from a Data Frame
- [`mysterycall_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_normality.md)
  : Check Normality and Summarize Data
- [`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md)
  : Create a Formula for Poisson Model
- [`mysterycall_recode_credentials()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_recode_credentials.md)
  : Recode raw physician credential strings to MD, DO, or Other
- [`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md)
  : Reorder a factor (or character vector) by descending frequency
- [`mysterycall_collapse_rare()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_collapse_rare.md)
  : Collapse rare factor/character levels into an "Other" category
- [`mysterycall_merge_with_prefix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_merge_with_prefix.md)
  : Merge two data frames with source-prefixed column names
- [`mysterycall_classify_ruca()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_ruca.md)
  : Classify RUCA codes into Urban / Suburban / Rural
- [`mysterycall_classify_medical_school()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_medical_school.md)
  : Classify medical school as US_MD, US_DO, CAN_MD, or IMG
- [`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md)
  : Classify physician practice setting from facility/organization name
- [`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md)
  : Three-tier specialty reconciliation with audit columns
- [`mysterycall_impute_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_impute_age.md)
  : Impute physician age from medical school graduation year
- [`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md)
  : Bin physician ages into decade categories
- [`mysterycall_stratified_sample()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_stratified_sample.md)
  : Draw a balanced stratified sample from a data frame
- [`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md)
  : Flag physicians called more than the allowed number of times
- [`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md)
  : Standardize demographic variables for Table 1
- [`mysterycall_assign_scenarios()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_scenarios.md)
  : Assign call scenarios to generalist providers
- [`data_utils`](https://mufflyt.github.io/mysterycall/reference/data_utils.md)
  : Data utilities for mystery-caller study management
- [`factor_utils`](https://mufflyt.github.io/mysterycall/reference/factor_utils.md)
  : Factor and categorical-variable utilities
- [`mysterycall_academic_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_academic_patterns.md)
  : Return the built-in academic keyword patterns
- [`mysterycall_government_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_government_patterns.md)
  : Return the built-in government/military keyword patterns
- [`mysterycall_age`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age.md)
  : Physician age imputation and categorization

## Business Days

Calculate business-day wait times excluding weekends and federal
holidays.

- [`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md)
  : Business-day utilities for mystery caller studies
- [`mysterycall_count_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_count_business_days.md)
  : Count business days between two dates (vectorized)
- [`mysterycall_us_federal_calendar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_us_federal_calendar.md)
  : Build a US federal holiday calendar

## Outcomes and Wait Times

Core outcome functions: acceptance rate, wait-time distribution, and
Poisson modeling.

- [`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md)
  : Compute appointment acceptance rates
- [`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md)
  : Summarize appointment wait times
- [`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
  : Fit a Poisson GLMER for mystery caller wait-time analysis
- [`mysterycall_hurdle_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hurdle_wait.md)
  : Two-part hurdle model for a mystery-caller wait time
- [`mysterycall_irr_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_plot.md)
  : IRR forest plot for a Poisson GLMER result
- [`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md)
  : Word-ready IRR table from a fitted Poisson model
- [`mysterycall_model_metrics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_metrics.md)
  : Compute MAE and RMSE from a fitted Poisson or linear model
- [`mysterycall_select_best_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_select_best_model.md)
  : Compare and rank competing fitted models
- [`mysterycall_screen_interactions()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_screen_interactions.md)
  : Screen candidate variables for interaction with a primary exposure
- [`mysterycall_outcomes`](https://mufflyt.github.io/mysterycall/reference/mysterycall_outcomes.md)
  : Primary outcome analysis for mystery caller studies
- [`print(`*`<mysterycall_poisson_model>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_poisson_model.md)
  : Print method for mysterycall_poisson_model objects

## Statistical Analysis

Disparities tables, multiple-comparison correction, bootstrap CIs,
marginal effects, and wave-over-wave comparisons.

- [`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md)
  : Compute Disparity Metrics Across Groups
- [`mysterycall_multiple_comparison_adjust()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multiple_comparison_adjust.md)
  : Adjust P-Values for Multiple Comparisons
- [`mysterycall_bootstrap_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_ci.md)
  : Bootstrap Confidence Intervals for a Summary Statistic
- [`mysterycall_marginal_effects()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_effects.md)
  : Compute average marginal effects for a Poisson GLM or GLMER
- [`mysterycall_compare_waves()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compare_waves.md)
  : Compare a study outcome across waves of a mystery caller study
- [`mysterycall_plot_emmeans()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans.md)
  : Plot and Save Estimated Marginal Means (EMMs)
- [`mysterycall_plot_emmeans_full()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans_full.md)
  : Full emmeans interaction plot with optional file save
- [`mysterycall_plot_emmeans_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans_interaction.md)
  : Visualize estimated marginal means for an interaction
- [`mysterycall_plot_effect()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_effect.md)
  : Plot marginal effects for a single model term
- [`mysterycall_plot_sjplot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_sjplot_interaction.md)
  : Interaction visualization via sjPlot
- [`print(`*`<mysterycall_disparities_table>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_disparities_table.md)
  : Print a mysterycall_disparities_table

## Sample Size and Power

Poisson power calculations and sample-size formulas for mystery-caller
studies.

- [`mysterycall_poisson_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_power.md)
  : Sample-size calculation for a Poisson mystery caller study
- [`mysterycall_cochran_n()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cochran_n.md)
  : Cochran finite-population sample size
- [`mysterycall_equation_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_equation_figure.md)
  : Poisson power curve: required sample size across a range of IRRs
- [`mysterycall_sample_size_text()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_size_text.md)
  : Generate a sample-size methods sentence
- [`mysterycall_power`](https://mufflyt.github.io/mysterycall/reference/mysterycall_power.md)
  : Power and sample-size tools for mystery caller studies

## Caller Quality Control

Audit caller performance: inter-rater reliability and per-caller
productivity metrics.

- [`mysterycall_caller_reliability()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caller_reliability.md)
  : Compute inter-rater reliability between mystery callers
- [`mysterycall_call_productivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_call_productivity.md)
  : Compute per-caller productivity metrics
- [`print(`*`<mysterycall_reliability>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_reliability.md)
  : Print method for mysterycall_reliability objects

## Visualization

Publication-ready plots for distributions, interactions, residuals, and
stacked bars.

- [`mysterycall_plot_disparities()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_disparities.md)
  :

  Plot disparity metrics from a `mysterycall_disparities_table`

- [`mysterycall_plot_stacked_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_stacked_bar.md)
  : Stacked bar chart of appointment acceptance by group

- [`mysterycall_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_interaction.md)
  : Create and plot interaction effects from a Poisson GLMM

- [`mysterycall_plot_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_density.md)
  : Create a Density Plot for Mystery Caller Studies with Optional
  Transformations

- [`mysterycall_plot_distribution()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_distribution.md)
  : Distribution plots for numeric outcome variables

- [`mysterycall_plot_residuals()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_residuals.md)
  : Residual diagnostic plots for a fitted model

- [`mysterycall_plot_line()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_line.md)
  : Create a Line Plot with Optional Transformations and Grouping

- [`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md)
  : Create a Scatter Plot for Mystery Caller Studies with Optional
  Transformations, Jitter, and Custom Labels

- [`mysterycall_plot_inclexcl()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_inclexcl.md)
  : CONSORT-style inclusion/exclusion flowchart for mystery-caller
  studies

- [`mysterycall_plot_source_venn()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_source_venn.md)
  : Three-circle Venn diagram for data-source overlap

- [`mysterycall_flowchart()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flowchart.md)
  : CONSORT-style inclusion/exclusion flowchart

- [`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md)
  : Save a ggplot2 figure with publication-quality defaults

- [`plot_effects`](https://mufflyt.github.io/mysterycall/reference/plot_effects.md)
  : Marginal effect plots for fitted models

## Tables and Reports

- [`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md)
  : Build a Table 1 for mystery caller studies
- [`mysterycall_table1_gtsummary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1_gtsummary.md)
  : Publication-ready Table 1 via gtsummary
- [`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md)
  : Calculate the Maximum Value(s) and Corresponding Level(s) of a
  Factor Variable
- [`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md)
  : Calculate the Minimum Value(s) and Corresponding Level(s) of a
  Factor Variable
- [`mysterycall_write_arsenal_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_arsenal_table.md)
  : Writes an Arsenal summary table to a Word document
- [`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md)
  : Most frequent level(s) of a categorical variable with percentage
- [`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md)
  : Calculate the Proportion of Each Level in a Categorical Variable
- [`mysterycall_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_overall.md)
  : Generate an overall summary table
- [`mysterycall_write_table_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table_pdf.md)
  : Write an Arsenal table to a PDF file
- [`mysterycall_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_quality_table.md)
  : Save Quality Check Table
- [`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md)
  : Format a Numeric Value as a Percentage
- [`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md)
  : Format an IRR table for manuscript display
- [`print(`*`<mysterycall_table1>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table1.md)
  : Print a mysterycall_table1 object

## Manuscript Writing

Auto-generate methods paragraphs, results sentences, and formatted
output tables.

- [`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md)
  : Generate a results paragraph for a mystery caller Poisson model
- [`mysterycall_methods_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_methods_paragraph.md)
  : Generate a boilerplate methods paragraph for a mystery-caller study
- [`mysterycall_summarize_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_demographics.md)
  : One-line demographic summary for a study cohort
- [`manuscript_helpers`](https://mufflyt.github.io/mysterycall/reference/manuscript_helpers.md)
  : Helpers for writing manuscript methods and results sections

## Quality and Validation

- [`mysterycall_check_data_completeness()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_data_completeness.md)
  : Assess completeness for required data columns
- [`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md)
  : Assess data quality
- [`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)
  : Run comprehensive preflight checks before workflow
- [`mysterycall_check_api_response()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_api_response.md)
  : Validate API response row count matches expectation
- [`mysterycall_check_no_data_loss()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_data_loss.md)
  : Validate no data loss between pipeline steps
- [`mysterycall_check_no_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_limits.md)
  : Validate no artificial data limits in workflow
- [`mysterycall_estimate_resources()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_estimate_resources.md)
  : Estimate workflow resources
- [`mysterycall_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scan_for_limits.md)
  : Scan code files for artificial limit patterns
- [`mysterycall_not_contacted_states()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_not_contacted_states.md)
  : Summarize States Where Physicians Were NOT Contacted
- [`mysterycall_physician_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physician_age.md)
  : Summarize physician age as median (IQR) text
- [`mysterycall_most_common_gender()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_most_common_gender.md)
  : Generate a Summary Sentence for the Most Common Gender, Specialty,
  Training, and Academic Affiliation
- [`mysterycall_verify_artifact()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_verify_artifact.md)
  : Verify the content-addressable identity of an audit trail JSON file
- [`preflight-checks`](https://mufflyt.github.io/mysterycall/reference/preflight-checks.md)
  : Preflight Checks for Mysterycall Workflows
- [`mysterycall_validate_google_api()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_google_api.md)
  : Validate Google Maps API key
- [`mysterycall_validate_here_api()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_here_api.md)
  : Validate routing API key

## Workflow

- [`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)
  : Run the end-to-end mystery caller workflow
- [`mysterycall_run_workflow_logged()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow_logged.md)
  : Run the mystery caller workflow with structured logging
- [`mysterycall_workflow_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_workflow_start.md)
  : Initialize workflow tracking
- [`mysterycall_workflow_end()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_workflow_end.md)
  : End workflow and print summary
- [`mysterycall_print_dashboard()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_print_dashboard.md)
  : Print a formatted summary dashboard
- [`mysterycall_tracker_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tracker_fail.md)
  : Mark a tracker step as failed
- [`mysterycall_tracker_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tracker_update.md)
  : Emit a manual progress heartbeat
- [`mysterycall_export_with_backup()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_with_backup.md)
  : Write tabular or graphical outputs with timestamped backups
- [`mysterycall_resolve_path()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_resolve_path.md)
  : Resolve project-relative paths from standard aliases
- [`mysterycall_cache_dir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cache_dir.md)
  : Determine the cache directory used for downloaded resources

## Logging

- [`mysterycall_log_info()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_info.md)
  : Log informational message
- [`mysterycall_log_error()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_error.md)
  : Log error message with context
- [`mysterycall_log_warning()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_warning.md)
  : Log warning message
- [`mysterycall_log_success()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_success.md)
  : Log success message
- [`mysterycall_log_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_progress.md)
  : Log progress for batch operations
- [`mysterycall_log_step()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_step.md)
  : Log a step start
- [`mysterycall_log_step_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_step_complete.md)
  : Complete current step with timing
- [`mysterycall_log_cache_hit()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_cache_hit.md)
  : Log cache hit
- [`mysterycall_log_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_save.md)
  : Log file save
- [`logging-utils`](https://mufflyt.github.io/mysterycall/reference/logging-utils.md)
  : Comprehensive Logging Utilities for mysterycall
- [`mysterycall_log_to_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_to_file.md)
  : Write to log file if configured

## Progress and Spinners

- [`mysterycall_progress_tracker()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_tracker.md)
  : Progress tracker for long-running workflows
- [`mysterycall_progress_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_start.md)
  : Mark a step as started
- [`mysterycall_progress_finish()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_finish.md)
  : Mark a step as completed
- [`mysterycall_progress_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_fail.md)
  : Fail progress bar
- [`mysterycall_progress_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_update.md)
  : Update progress bar
- [`mysterycall_progress_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_summary.md)
  : Return a tibble describing step-by-step progress
- [`mysterycall_progress_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_bar.md)
  : Create a beautiful progress bar
- [`mysterycall_progress_callback()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_callback.md)
  : Create a simple progress callback for batch operations
- [`mysterycall_progress_done()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_done.md)
  : Complete progress bar
- [`mysterycall_progress_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_map.md)
  : Create a progress bar for batch processing
- [`mysterycall_multi_step()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_step.md)
  : Start a step in multi-progress tracker
- [`mysterycall_multi_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_update.md)
  : Update current step in multi-progress tracker
- [`mysterycall_multi_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_progress.md)
  : Create a multi-step progress tracker
- [`mysterycall_multi_done()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_done.md)
  : Complete multi-step tracker
- [`mysterycall_multi_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_complete.md)
  : Complete current step in multi-progress tracker
- [`mysterycall_spinner_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_start.md)
  : Show a spinner for indeterminate operations
- [`mysterycall_spinner_stop()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_spinner_stop.md)
  : Stop a spinner
- [`progress-bars`](https://mufflyt.github.io/mysterycall/reference/progress-bars.md)
  : Beautiful Progress Bars for mysterycall

## Green Journal Publication Utilities

ggplot2 themes, colorblind-safe palettes, and figure-export helpers
conforming to Obstetrics & Gynecology (Green Journal) 2024 author
guidelines (TIFF/PDF/PNG/CSV export, Okabe-Ito palette, Albers CRS).

- [`mysterycall_theme_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal.md)
  [`mysterycall_theme_publication()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal.md)
  : Green Journal ggplot2 theme
- [`mysterycall_theme_green_journal_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_map.md)
  [`mysterycall_theme_publication_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_map.md)
  : Green Journal map theme
- [`mysterycall_theme_green_journal_faceted()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_faceted.md)
  [`mysterycall_theme_publication_faceted()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_faceted.md)
  : Green Journal faceted map theme
- [`mysterycall_palette_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_palette_green_journal.md)
  [`mysterycall_palette_publication()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_palette_green_journal.md)
  : Colorblind-safe publication palette (Okabe-Ito)
- [`mysterycall_scale_color_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scale_color_green_journal.md)
  : Green Journal discrete color scale
- [`mysterycall_scale_fill_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scale_fill_green_journal.md)
  : Green Journal discrete fill scale
- [`mysterycall_save_green_journal_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_green_journal_figure.md)
  [`mysterycall_save_publication_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_green_journal_figure.md)
  : Save a figure in Green Journal submission format
- [`mysterycall_crs_albers_conus()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_crs_albers_conus.md)
  : Albers Equal-Area CRS for the continental United States
- [`mysterycall_winsorize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_winsorize.md)
  : Winsorize extreme values
- [`mysterycall_truncate_for_viz()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_truncate_for_viz.md)
  : Truncate values to fixed bounds
- [`mysterycall_compose_map_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compose_map_density.md)
  : Composite map + density figure

## Utilities

- [`mysterycall_check_dependencies()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_dependencies.md)
  : Check for required R package dependencies

- [`mysterycall_use_quiet_logging()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_use_quiet_logging.md)
  : Toggle quiet logging for helper functions

- [`mysterycall_standard_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_labels.md)
  :

  Retrieve the standard label dictionary used in `mysterycall`

- [`mysterycall_standard_palette()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_palette.md)
  : Retrieve a standard color palette

- [`mysterycall_quality_tier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_quality_tier.md)
  : Convert numeric scores to qualitative tiers

- [`mysterycall_download_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_download_file.md)
  : Download a large file with resume support

- [`mysterycall_format_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_duration.md)
  : Format duration in human-readable form

- [`mysterycall_read_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_table.md)
  : Read a tabular data file (CSV or Parquet)

- [`mysterycall_write_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table.md)
  : Write a data frame to a tabular file (CSV or Parquet)

- [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md)
  : Internal helper for package-specific temporary directories

## Datasets

Built-in datasets included with the package.

- [`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md)
  : Medicaid Expansion Status by State

## Mixed Models and GLMMs

Fit LMMs, Poisson GLMMs, negative-binomial GLMMs, and logistic models.

- [`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md)
  : Fit a Linear Mixed Model (LMM) for wait-time analysis
- [`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md)
  : Fit a Negative Binomial GLMM for overdispersed wait-time analysis
- [`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md)
  : Fit a Logistic GLMER for mystery caller appointment-offered outcome
- [`mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_auto_model.md)
  : Automatically select and compare wait-time models
- [`mysterycall_simple_poisson()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_simple_poisson.md)
  : Simple Poisson Regression for Group Comparison of Count Outcomes
- [`mysterycall_univariate_lmm_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_lmm_screen.md)
  : Screen predictors one-at-a-time using a linear mixed model
- [`mysterycall_univariate_poisson_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_poisson_screen.md)
  : Screen predictors one-at-a-time using univariate Poisson GLMs
- [`mysterycall_interaction_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_screen.md)
  : Screen all pairwise factor interactions using linear mixed models
- [`mysterycall_screen_predictors()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_screen_predictors.md)
  : Screen candidate predictors for a GLMM outcome

## Model Interpretation

Interpret fitted models: ICC, overdispersion, IRR, power, and
predictions.

- [`mysterycall_icc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_icc.md)
  : Extract the intraclass correlation coefficient from a fitted model

- [`mysterycall_icc_report()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_icc_report.md)
  : Inter-caller reliability report for STROBE item 22

- [`mysterycall_icc_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_icc_sentence.md)
  : Generate a manuscript sentence for the ICC

- [`mysterycall_r2_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_r2_sentence.md)
  : Compute R-squared values and generate an interpretive sentence for
  mixed models

- [`mysterycall_random_effect_variance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_random_effect_variance.md)
  : Compute random-effect variance components and ICC for mixed models

- [`mysterycall_overdispersion_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_sentence.md)
  : Test for overdispersion and generate an interpretive sentence

- [`mysterycall_overdispersion_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_test.md)
  : Test overdispersion in a fitted count model

- [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md)
  : Convert IRRs to absolute wait-time differences in days

- [`mysterycall_power_calc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_power_calc.md)
  : Clustered binary power and sample-size calculator (GLMM / VIF
  approach)

- [`mysterycall_power_curve()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_power_curve.md)
  : Plot power vs. physicians across IRR scenarios (NB GLMM)

- [`mysterycall_nb_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_power.md)
  : Simulate power for a negative binomial mixed model

- [`mysterycall_predict_appointment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_predict_appointment.md)
  : Predict appointment probability for new patient profiles

- [`mysterycall_predicted_means()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_predicted_means.md)
  : Extract predicted mean wait times from a fitted mystery-caller model

- [`mysterycall_model_mae_rmse()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_mae_rmse.md)
  :

  Compute MAE, RMSE, Pearson R², and MAPE for a fitted model

- [`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md)
  : Publication-ready model comparison table

- [`mysterycall_multi_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_model_table.md)
  : Build a three-column regression table for manuscript submission

- [`mysterycall_acceptance_rate_calc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate_calc.md)
  : Rigorous Three-Part Acceptance Rate Calculator

## Acceptance Rates and Wait Times

Calculate and narrate appointment acceptance rates and wait-time
outcomes.

- [`mysterycall_insurance_acceptance_rates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_acceptance_rates.md)
  : Calculate Medicaid and BCBS Acceptance Rates (deprecated)
- [`mysterycall_insurance_wait_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_wait_sentence.md)
  : Build a Manuscript-Ready Insurance Wait-Time Sentence
- [`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)
  : Sensitivity analysis: physicians called under both insurance types
- [`mysterycall_sensitivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity.md)
  : Sensitivity analysis across data subsets
- [`mysterycall_sensitivity_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_table.md)
  : Side-by-side sensitivity table of exposure-term estimates across
  models
- [`mysterycall_calendar_sensitivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_calendar_sensitivity.md)
  : Calendar-days vs. business-days sensitivity analysis for wait-time
  models
- [`mysterycall_wait_time_by_group()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_by_group.md)
  : Summarise Wait Times by Group
- [`mysterycall_wait_time_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_sentence.md)
  : Build a Manuscript-Ready Wait-Time Sentence
- [`mysterycall_wait_time_crossover()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_crossover.md)
  : Compute the wait-time equalization (crossover) point between two
  insurance groups

## Descriptive Statistics

Summarize demographics, distributions, and scenarios in text and tables.

- [`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md)
  : Distil key abstract numbers from fitted model objects
- [`mysterycall_descriptive_stats()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_descriptive_stats.md)
  : Descriptive statistics for a numeric column
- [`mysterycall_distribution_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_distribution_summary.md)
  : Distribution summary for a categorical column
- [`mysterycall_demographics_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_demographics_sentence.md)
  : Build a Manuscript-Ready Demographics Sentence
- [`mysterycall_sample_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_demographics.md)
  : Summarise Sample Demographics for a Mystery-Caller Study
- [`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md)
  : Scenario call count summary and descriptive sentence

## Data Cleaning

Clean raw call data, recode insurance columns, and deduplicate records.

- [`mysterycall_clean_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data.md)
  : Clean raw mystery-caller data for publication-ready analysis
- [`mysterycall_clean_data_keep_identifiers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data_keep_identifiers.md)
  : Clean mystery-caller data while retaining all identifier columns
- [`mysterycall_clean_medicaid_col()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_medicaid_col.md)
  : Clean and binarise a Medicaid acceptance column
- [`mysterycall_dedup_by_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_dedup_by_insurance.md)
  : Deduplicate data by insurance and physician phone
- [`mysterycall_physicians_with_detail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physicians_with_detail.md)
  : Retrieve detailed records for a set of flagged physician IDs
- [`mysterycall_impute_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_impute_calls.md)
  : Multiple imputation by chained equations for missing call outcomes

## Quality Control and Flags

Flag outliers, exclusion discrepancies, and missing data patterns.

- [`mysterycall_flag_date_outliers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_date_outliers.md)
  : Flag call dates that look like fat-finger entry errors
- [`mysterycall_flag_excluded_with_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_excluded_with_appointments.md)
  : Flag Excluded Records That Still Have a Recorded Wait Time
- [`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md)
  : Flag Records with Exclusions That Also Have a Wait Time
- [`mysterycall_flag_included_na_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_included_na_appointments.md)
  : Flag "Included" Records with a Missing Wait Time
- [`mysterycall_flag_repeat_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md)
  : Flag Physicians Included More Than a Threshold Number of Times
- [`mysterycall_check_zero_inflation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_zero_inflation.md)
  : Test for zero-inflation in a fitted count model
- [`mysterycall_missing_data_analysis()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_missing_data_analysis.md)
  : Test whether missing appointment dates are MAR or MNAR
- [`mysterycall_caller_drift()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caller_drift.md)
  : Detect and visualise calendar and sequence drift in mystery-caller
  outcomes

## Visualization

Publication-ready figures: forest plots, histograms, survival curves,
flow diagrams.

- [`mysterycall_forest_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_forest_plot.md)
  : Publication-ready forest plot of IRRs or odds ratios
- [`mysterycall_log_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_histogram.md)
  : Log-scale faceted histogram of a numeric variable by group
- [`mysterycall_facet_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_facet_histogram.md)
  : Faceted histogram of a numeric variable by group
- [`mysterycall_kaplan_meier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_kaplan_meier.md)
  : Kaplan-Meier time-to-appointment analysis by insurance group
- [`mysterycall_flow_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_diagram.md)
  : Draw a participant flow diagram for a mystery-caller study
- [`mysterycall_acceptance_waffle()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_waffle.md)
  : Waffle chart of insurance acceptance rates
- [`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md)
  : Greene-journal-ready monochrome ggplot2 theme

## Reporting and Manuscript Tables

Generate methods paragraphs, results sentences, and supplemental tables.

- [`mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_materials_methods.md)
  : Generate a complete Materials & Methods section for a mystery-caller
  study
- [`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md)
  : Generate a results paragraph for a logistic mystery caller model
- [`mysterycall_results_report()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_report.md)
  : Generate a complete manuscript results report from a fitted model
- [`mysterycall_literature_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_literature_table.md)
  : Build a literature comparison table of prior mystery-caller study
  ORs
- [`mysterycall_interaction_sentences()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_sentences.md)
  [`print(`*`<mysterycall_interaction_sentences>`*`)`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_sentences.md)
  : Auto-generate manuscript sentences for a two-way interaction
- [`mysterycall_interaction_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_table.md)
  : Stratum-specific ORs and omnibus LRT for a fitted interaction term
- [`mysterycall_supplemental_tables()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_supplemental_tables.md)
  : Export a publication-ready supplemental Excel workbook
- [`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md)
  : Summarise call-level exclusions into a manuscript-ready paragraph
- [`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md)
  : Merge IRR results and absolute day differences into one publication
  table
- [`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md)
  : Write a styled manuscript results table to a .docx file
- [`mysterycall_table2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table2.md)
  : Build a two-panel manuscript Table 2
- [`mysterycall_irr_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_table.md)
  : Publication-Ready gt Table of Incidence Rate Ratios
- [`mysterycall_model_gt()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_gt.md)
  : Thin Wrapper: gt IRR Table from a Simple Poisson Result

## NPI Enrichment and REDCap

Enrich NPI records and parse REDCap data dictionaries.

- [`mysterycall_enrich_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_enrich_npi.md)
  : Integrated NPI enrichment pipeline
- [`mysterycall_parse_redcap_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_redcap_labels.md)
  : Parse REDCap field labels into choice-code / label tables

## Study Flow and STROBE

Prepare call lists, STROBE checklists, and session snapshots.

- [`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md)
  : STROBE reporting checklist for mystery-caller studies
- [`mysterycall_crisp_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_crisp_checklist.md)
  : Simulated-patient (CRiSP-style) reporting checklist
- [`mysterycall_model_equation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_equation.md)
  : Render a fitted model as a LaTeX equation
- [`mysterycall_strobe_flow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_flow.md)
  : Draw a STROBE-compliant flow diagram for mystery-caller
  (secret-shopper) studies
- [`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md)
  : Prepare raw REDCap mystery-caller data for statistical analysis
- [`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md)
  : Write a reproducibility snapshot at analysis end
- [`mysterycall_run_analysis()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_analysis.md)
  : Run the Full Mystery-Caller Analysis Pipeline

## Guideline Concordance

Score call transcripts against a clinical-guideline rubric and quantify
inter-rater agreement.

- [`mysterycall_concordance_rubric()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_rubric.md)
  : Define a Guideline-Concordance Rubric
- [`mysterycall_score_concordance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_score_concordance.md)
  : Score Captured Calls Against a Concordance Rubric
- [`mysterycall_concordance_kappa()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_kappa.md)
  : Per-Item Inter-Rater Agreement for a Concordance Rubric
- [`mysterycall_concordance_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_sentence.md)
  : Manuscript-Ready Concordance Sentence

## Small-Sample Categorical and Rank Tests

Chi-square / Fisher / Freeman-Halton, Cochran-Mantel-Haenszel,
prevalence CIs, and Kruskal-Wallis / Mann-Whitney comparisons for small
audit samples.

- [`mysterycall_test_categorical()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_categorical.md)
  : Association Test for a Contingency Table (auto chi-squared / Fisher)
- [`mysterycall_cmh_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cmh_test.md)
  : Cochran-Mantel-Haenszel Test for a Matched / Stratified Design
- [`mysterycall_prevalence_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prevalence_ci.md)
  : Category Prevalence with Wilson or Clopper-Pearson Intervals
- [`mysterycall_compare_ranks()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compare_ranks.md)
  : Rank-Based Comparison of a Numeric Outcome Across Groups

## Call Outcomes

Multi-category and multi-response call-outcome tabulation,
classification, gradients, and ordinal models.

- [`mysterycall_multiresponse_tabulate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multiresponse_tabulate.md)
  : Tabulate a Multi-Response ("Check-All-That-Apply") Call Outcome
- [`mysterycall_classify_call_outcome()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_call_outcome.md)
  : Map Raw Call Dispositions to a Standard Outcome Taxonomy
- [`mysterycall_outcome_gradient()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_outcome_gradient.md)
  : Ordered Multi-Category Outcome Summary (Access Gradient)
- [`mysterycall_ordinal_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ordinal_model.md)
  : Proportional-Odds Model for a Graded Ordinal Outcome

## Access Cascade and Call-Log Integrity

Summarize the access cascade across the call pathway, reconcile
offer/outcome discordance, run cross-field consistency rules, and bound
a rate under non-response.

- [`mysterycall_access_cascade()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_access_cascade.md)
  : Summarize an access cascade across the call pathway
- [`mysterycall_cascade_stage()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cascade_stage.md)
  : Define one stage of an access cascade
- [`mysterycall_reconcile_offer_outcome()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_offer_outcome.md)
  : Reconcile a binary "offered" flag against a granular outcome field
- [`mysterycall_check_consistency()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_consistency.md)
  : Apply a battery of consistency rules to a call log
- [`mysterycall_consistency_rule()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_consistency_rule.md)
  : Define one cross-field consistency rule
- [`mysterycall_default_consistency_rules()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_default_consistency_rules.md)
  : Default cross-field consistency rules for a call log
- [`mysterycall_outcome_bounds()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_outcome_bounds.md)
  : Worst-case / best-case bounds on a proportion under non-response

## Clustering and Single-Contact Curves

Build a random-intercept clustering key and plot the empirical
cumulative appointment-acquisition curve for single-contact designs.

- [`mysterycall_cluster_id()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cluster_id.md)
  : Build a random-intercept clustering key by coalescing columns
- [`mysterycall_cumulative_access_curve()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cumulative_access_curve.md)
  : Cumulative appointment-acquisition curve for single-contact designs

## Simulation Power and Model Robustness

Monte Carlo power for two-part and population-marginal designs, a type-I
calibration check, minimum-detectable-effect search, joint
likelihood-ratio tests, and leave-one-group-out refit sensitivity.

- [`mysterycall_twopart_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_twopart_power.md)
  : Monte Carlo power for a two-part (offer + conditional wait) design
- [`mysterycall_marginal_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_power.md)
  : Monte Carlo power for a population-marginal,
  post-stratification-weighted effect in a paired-call design
- [`mysterycall_type_i_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_type_i_check.md)
  : Type I error calibration check for a simulation-based test
- [`mysterycall_find_mde()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_find_mde.md)
  : Minimum detectable effect by binary search over a power function
- [`mysterycall_joint_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_joint_test.md)
  : Joint likelihood-ratio test for a multi-level predictor
- [`mysterycall_leave_one_out()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_leave_one_out.md)
  : Leave-one-group-out refit sensitivity
- [`mysterycall_provider_split_simulation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_provider_split_simulation.md)
  : Site/Provider Split Simulation (Cluster Cross-Validation)

## Matched-Pair Analyses

Within-practice paired comparisons for the matched-pair design (same
practice called under two scenarios).

- [`mysterycall_paired_acceptance_mcnemar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_acceptance_mcnemar.md)
  : Within-practice paired McNemar test for a binary acceptance outcome
- [`mysterycall_paired_wait_within_practice()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_wait_within_practice.md)
  : Within-practice paired wait-time comparison

## Matched-Control Design and Geocoding

Build a propensity-score-matched control cohort for a case-control
audit, geocode a city/state roster, and normalize organization names for
joins.

- [`mysterycall_build_matched_controls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_build_matched_controls.md)
  : Build a propensity-score-matched control cohort
- [`mysterycall_geocode_city_state()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode_city_state.md)
  : Look up latitude/longitude for city + state
- [`mysterycall_normalize_org_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_org_name.md)
  : Normalize an organization / practice name for matching

## Additional Models and Diagnostics

- [`mysterycall_compare_count_families()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compare_count_families.md)
  : Compare Count Mixed Model Families (Poisson, nbinom1, nbinom2)
- [`mysterycall_model_nonlinear()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_nonlinear.md)
  : Model Non-Linear Relationships with Splines or Polynomials
- [`mysterycall_model_zero_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_zero_wait.md)
  : Model Same-Day Appointments (Wait Time is Zero)
- [`mysterycall_bootstrap_predictor_stability()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_predictor_stability.md)
  : Bootstrap Predictor-Retention Stability Analysis
- [`mysterycall_temporal_validation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_temporal_validation.md)
  : Locked Temporal Validation for Count/Binary Models
- [`mysterycall_recalibration_assessment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_recalibration_assessment.md)
  : Recalibration Assessment for Fitted Models
- [`mysterycall_test_interaction_effect()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_interaction_effect.md)
  : Test for Interaction Effect in Wait-Time GLMM
- [`mysterycall_validate_residuals_dharma()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_residuals_dharma.md)
  : Run DHARMa Residual Diagnostics for GLMM Validation

## Additional Covariates and Geography

- [`mysterycall_region_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_region_labels.md)
  : Region Labels for a US State Choropleth
- [`mysterycall_get_acs_female_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_female_insurance.md)
  : Extract Female Insurance Shares from ACS Sex-by-Coverage-Type Tables
- [`mysterycall_get_cms_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_cms_enrollment.md)
  : Retrieve CMS Monthly County-Level Enrollment Reports
- [`mysterycall_get_hrsa_ahrf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_hrsa_ahrf.md)
  : Extract County-Level Metrics from HRSA Area Health Resources File
  (AHRF)
- [`mysterycall_medicaid_fee_index()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_medicaid_fee_index.md)
  : Retrieve State-Level Medicaid-to-Medicare Fee Index Ratios
- [`mysterycall_track_clinician_churn()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_track_clinician_churn.md)
  : Track Clinician Churn at a Specific Practice Location (NPPES
  History)
- [`mysterycall_calculate_hq_distance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_calculate_hq_distance.md)
  : Calculate Haversine Distance to Platform Headquarters
- [`mysterycall_calculate_spatial_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_calculate_spatial_density.md)
  : Calculate Spatial Density of Clinics (Local Concentration Index)
- [`ensure_hrr_shapefile()`](https://mufflyt.github.io/mysterycall/reference/ensure_hrr_shapefile.md)
  : Ensure the Dartmouth Atlas HRR boundary shapefile is available
  locally
- [`county_covariates`](https://mufflyt.github.io/mysterycall/reference/county_covariates.md)
  : County provider counts and Medicare/Medicaid enrollment covariates
- [`hhi`](https://mufflyt.github.io/mysterycall/reference/hhi.md) :
  Market concentration (HHI) covariates from KFF data

## Caller List Export and Direction Helpers

- [`mysterycall_export_gsheet_caller_list()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_gsheet_caller_list.md)
  : Export a caller list in Google Sheets import format
- [`mysterycall_get_direction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md)
  [`mysterycall_get_change_verb()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md)
  : Direction and change words wired to the sign of the data
- [`mystercall_no_longer_in_service()`](https://mufflyt.github.io/mysterycall/reference/mystercall_no_longer_in_service.md)
  [`mysterycall_no_longer_in_service()`](https://mufflyt.github.io/mysterycall/reference/mystercall_no_longer_in_service.md)
  : Dial phone numbers and flag lines that appear no longer in service

## Package Constants

Exported pattern and indicator vectors used by the academic and
practice-setting classifiers.

- [`ACADEMIC_HOSPITAL_PATTERNS`](https://mufflyt.github.io/mysterycall/reference/ACADEMIC_HOSPITAL_PATTERNS.md)
  : Academic Hospital Name Patterns
- [`ACGME_PROGRAM_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/ACGME_PROGRAM_INDICATORS.md)
  : ACGME Program Indicators
- [`COTH_TEACHING_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/COTH_TEACHING_INDICATORS.md)
  : COTH (Council of Teaching Hospitals) Indicators
- [`KNOWN_ACADEMIC_INSTITUTIONS`](https://mufflyt.github.io/mysterycall/reference/KNOWN_ACADEMIC_INSTITUTIONS.md)
  : Known Academic Medical Centers
- [`MEDICAL_SCHOOL_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICAL_SCHOOL_INDICATORS.md)
  : Medical School Affiliation Patterns
- [`MEDICARE_GME_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICARE_GME_INDICATORS.md)
  : Medicare GME Payment Indicators
- [`NCI_CANCER_CENTERS`](https://mufflyt.github.io/mysterycall/reference/NCI_CANCER_CENTERS.md)
  : NCI-Designated Cancer Center Patterns
- [`NIH_CTSA_HUBS`](https://mufflyt.github.io/mysterycall/reference/NIH_CTSA_HUBS.md)
  : NIH CTSA Hub Patterns
- [`build_missingness_mcar_table()`](https://mufflyt.github.io/mysterycall/reference/build_missingness_mcar_table.md)
  : Per-variable missingness table paired with Little's MCAR test

## S3 Methods

print(), tidy(), plot(), and coercion methods for mysterycall objects.

- [`print(`*`<mysterycall_provider_counts>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_provider_counts.md)
  : Print method for mysterycall_provider_counts
- [`plot(`*`<mysterycall_lmm>`*`)`](https://mufflyt.github.io/mysterycall/reference/plot.mysterycall_lmm.md)
  : Q-Q and residual diagnostic plots for a fitted LMM
- [`tidy(`*`<mysterycall_lmm>`*`)`](https://mufflyt.github.io/mysterycall/reference/tidy.mysterycall_lmm.md)
  : Tidy method for mysterycall_lmm objects
- [`tidy(`*`<mysterycall_logistic_model>`*`)`](https://mufflyt.github.io/mysterycall/reference/tidy.mysterycall_logistic_model.md)
  : Tidy method for mysterycall_logistic_model objects
- [`tidy(`*`<mysterycall_poisson_model>`*`)`](https://mufflyt.github.io/mysterycall/reference/tidy.mysterycall_poisson_model.md)
  : Tidy method for mysterycall_poisson_model objects
- [`print(`*`<mysterycall_abstract_numbers>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_abstract_numbers.md)
  : Print method for mysterycall_abstract_numbers objects
- [`print(`*`<mysterycall_acceptance_rate_calc>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_acceptance_rate_calc.md)
  : Print a mysterycall_acceptance_rate_calc Object
- [`print(`*`<mysterycall_auto_model>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_auto_model.md)
  : Print method for auto-selected mystery-caller models
- [`print(`*`<mysterycall_calendar_sensitivity>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_calendar_sensitivity.md)
  : Print method for mysterycall_calendar_sensitivity
- [`print(`*`<mysterycall_caller_drift>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_caller_drift.md)
  : Print method for mysterycall_caller_drift objects
- [`print(`*`<mysterycall_icc>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_icc.md)
  : Print method for mysterycall_icc
- [`print(`*`<mysterycall_icc_report>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_icc_report.md)
  : Print method for mysterycall_icc_report
- [`print(`*`<mysterycall_impute_calls>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_impute_calls.md)
  : Print method for mysterycall_impute_calls objects
- [`print(`*`<mysterycall_interaction_table>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_interaction_table.md)
  : Print method for mysterycall_interaction_table objects
- [`print(`*`<mysterycall_irr_days>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md)
  : Print method for mysterycall_irr_days
- [`print(`*`<mysterycall_kaplan_meier>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_kaplan_meier.md)
  : Print a mysterycall_kaplan_meier result
- [`print(`*`<mysterycall_literature_table>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_literature_table.md)
  : Print a mysterycall_literature_table object
- [`print(`*`<mysterycall_lmm>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_lmm.md)
  : Print method for mysterycall_lmm objects
- [`print(`*`<mysterycall_logistic_model>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_logistic_model.md)
  : Print method for mysterycall_logistic_model objects
- [`print(`*`<mysterycall_materials_methods>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_materials_methods.md)
  : Print method for mysterycall_materials_methods
- [`print(`*`<mysterycall_missing_data>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_missing_data.md)
  : Print method for mysterycall_missing_data
- [`print(`*`<mysterycall_model_comparison_table>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_comparison_table.md)
  : Print method for model comparison table
- [`print(`*`<mysterycall_model_mae_rmse>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_mae_rmse.md)
  : Print method for mysterycall_model_mae_rmse objects
- [`print(`*`<mysterycall_multi_model_table>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_multi_model_table.md)
  : Print a mysterycall_multi_model_table
- [`print(`*`<mysterycall_nb_model>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_nb_model.md)
  : Print method for mysterycall_nb_model objects
- [`print(`*`<mysterycall_nb_power>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_nb_power.md)
  : Print method for mysterycall_nb_power
- [`print(`*`<mysterycall_overdispersion_test>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_overdispersion_test.md)
  : Print method for mysterycall_overdispersion_test
- [`print(`*`<mysterycall_power_curve>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_power_curve.md)
  : Print method for mysterycall_power_curve
- [`print(`*`<mysterycall_predicted_means>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_predicted_means.md)
  : Print method for mysterycall_predicted_means
- [`print(`*`<mysterycall_prepared>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_prepared.md)
  : Print method for mysterycall_prepared objects
- [`print(`*`<mysterycall_results_report>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_results_report.md)
  : Print method for mysterycall_results_report
- [`print(`*`<mysterycall_sensitivity>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_sensitivity.md)
  : Print method for mysterycall_sensitivity
- [`print(`*`<mysterycall_snapshot>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_snapshot.md)
  : Print a mysterycall_snapshot object
- [`print(`*`<mysterycall_strobe_checklist>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_strobe_checklist.md)
  : Print method for mysterycall_strobe_checklist
- [`print(`*`<mysterycall_table2>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table2.md)
  : Print method for mysterycall_table2
- [`print(`*`<mysterycall_wait_time_crossover>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_wait_time_crossover.md)
  : Print a mysterycall_wait_time_crossover result

## Short Aliases

Unqualified alias names for frequently used functions.

- [`clean_data`](https://mufflyt.github.io/mysterycall/reference/clean_data.md)
  : Clean and standardize raw mystery-caller data for analysis
- [`combined_results_table`](https://mufflyt.github.io/mysterycall/reference/combined_results_table.md)
  : Combined IRR and absolute-days publication table
- [`export_results_docx`](https://mufflyt.github.io/mysterycall/reference/export_results_docx.md)
  : Export results table to a styled Word document
- [`flow_diagram`](https://mufflyt.github.io/mysterycall/reference/flow_diagram.md)
  : CONSORT/STROBE flow diagram for mystery-caller studies
- [`forest_plot`](https://mufflyt.github.io/mysterycall/reference/forest_plot.md)
  : Publication-ready forest plot for mystery-caller model results
- [`icc`](https://mufflyt.github.io/mysterycall/reference/icc.md) :
  Intraclass correlation coefficient for mystery-caller models
- [`impute_calls`](https://mufflyt.github.io/mysterycall/reference/impute_calls.md)
  : Multiple imputation for missing mystery-caller outcomes
- [`lmm`](https://mufflyt.github.io/mysterycall/reference/lmm.md) : Fit
  a Linear Mixed Model for approximately normal wait-time outcomes
- [`materials_methods`](https://mufflyt.github.io/mysterycall/reference/materials_methods.md)
  : Generate a programmatic Materials & Methods section
- [`missing_data_analysis`](https://mufflyt.github.io/mysterycall/reference/missing_data_analysis.md)
  : Missing data analysis for mystery-caller appointment outcomes
- [`model_mae_rmse`](https://mufflyt.github.io/mysterycall/reference/model_mae_rmse.md)
  : Evaluate prediction accuracy for a fitted mysterycall model
- [`power_curve`](https://mufflyt.github.io/mysterycall/reference/power_curve.md)
  : Power curve for negative binomial GLMM mystery-caller studies
- [`predicted_means`](https://mufflyt.github.io/mysterycall/reference/predicted_means.md)
  : Model-based predicted mean wait times per group
- [`prepare_calls`](https://mufflyt.github.io/mysterycall/reference/prepare_calls.md)
  : Prepare and filter raw REDCap mystery-caller data for analysis
- [`results_report`](https://mufflyt.github.io/mysterycall/reference/results_report.md)
  : One-call manuscript results report
- [`strobe_flow`](https://mufflyt.github.io/mysterycall/reference/strobe_flow.md)
  : STROBE flow diagram for mystery-caller studies

## Additional Functions

Further analysis, power, workflow, and utility functions.

- [`mysterycall_adjusted_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_adjusted_power.md)
  : Simulation power for a covariate-adjusted NB GLMM with a cluster ICC
- [`mysterycall_appointment_obtained()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_appointment_obtained.md)
  : Derive the appointment-obtained indicator and wait, with same-day =
  0
- [`mysterycall_assign_area_covariates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_area_covariates.md)
  : Assign area-level covariates (ADI, SVI, HHI) from physician
  coordinates
- [`mysterycall_categorize_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_categorize_wait.md)
  : Bin a wait-time-to-appointment into weekly categories and a
  threshold flag
- [`mysterycall_clean_zip()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_zip.md)
  : Clean and standardize ZIP codes to five digits
- [`mysterycall_exclusion_crosswalk()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_crosswalk.md)
  : Canonical exclusion-code / label-string crosswalk
- [`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md)
  : Flag near-duplicate cluster keys (likely mistyped grouping values)
- [`mysterycall_gee()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_gee.md)
  : Population-average GEE model for a clustered binary audit outcome
- [`mysterycall_geocode_address()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode_address.md)
  : Geocode full street addresses (US Census batch, with fallbacks)
- [`mysterycall_link_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_link_physicians.md)
  : Probabilistic record linkage of two physician lists without a shared
  key
- [`mysterycall_lm_interaction_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lm_interaction_power.md)
  : Analytic power for factorial linear-model terms via Cohen's
  f-squared
- [`mysterycall_lookup_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lookup_age.md)
  : Look up physician age by name and state
- [`mysterycall_nppes_gender()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nppes_gender.md)
  : Physician gender from the NPPES registry
- [`mysterycall_overdispersion_threshold()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_threshold.md)
  : Canonical overdispersion threshold for Poisson-vs-negative-binomial
  choice
- [`mysterycall_parse_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_duration.md)
  : Parse messy free-text call durations to a numeric unit
- [`mysterycall_plot_paired_slope()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_paired_slope.md)
  : Within-cluster paired slope plot across scenarios
- [`mysterycall_plot_raincloud()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_raincloud.md)
  : Raincloud plot of a numeric outcome by group
- [`mysterycall_reached_declined_reasons()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reached_declined_reasons.md)
  : Canonical "reached but declined" call-outcome labels
- [`mysterycall_read_latest()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_latest.md)
  : Read (or locate) the most recent file matching a pattern - loudly
- [`mysterycall_reconcile_inclusion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_inclusion.md)
  : Crosswalk between REDCap integer exclusion codes and label strings
- [`mysterycall_scenario_coverage()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_coverage.md)
  : Per-cluster scenario coverage for a matched multi-scenario audit
- [`mysterycall_ttest_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ttest_power.md)
  : Analytic power for a two-group continuous outcome under unequal
  allocation
- [`logging-utils`](https://mufflyt.github.io/mysterycall/reference/logging-utils.md)
  : Comprehensive Logging Utilities for mysterycall
- [`preflight-checks`](https://mufflyt.github.io/mysterycall/reference/preflight-checks.md)
  : Preflight Checks for Mysterycall Workflows
- [`progress-bars`](https://mufflyt.github.io/mysterycall/reference/progress-bars.md)
  : Beautiful Progress Bars for mysterycall

## S3 Methods

print() and as.data.frame() methods for mysterycall result objects.

- [`as.data.frame(`*`<mysterycall_access_cascade>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_access_cascade.md)
  :

  Coerce a `mysterycall_access_cascade` object to a data frame

- [`as.data.frame(`*`<mysterycall_concordance>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_concordance.md)
  :

  Coerce a `mysterycall_concordance` object to a data frame

- [`as.data.frame(`*`<mysterycall_consistency_report>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_consistency_report.md)
  :

  Coerce a `mysterycall_consistency_report` object to a data frame

- [`as.data.frame(`*`<mysterycall_cumulative_access_curve>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_cumulative_access_curve.md)
  :

  Coerce a `mysterycall_cumulative_access_curve` object to a data frame

- [`as.data.frame(`*`<mysterycall_hurdle_wait>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_hurdle_wait.md)
  :

  Coerce a `mysterycall_hurdle_wait` object to a data frame

- [`as.data.frame(`*`<mysterycall_joint_test>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_joint_test.md)
  :

  Coerce a `mysterycall_joint_test` object to a data frame

- [`as.data.frame(`*`<mysterycall_leave_one_out>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_leave_one_out.md)
  :

  Coerce a `mysterycall_leave_one_out` object to a data frame

- [`as.data.frame(`*`<mysterycall_marginal_power>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_marginal_power.md)
  :

  Coerce a `mysterycall_marginal_power` object to a data frame

- [`as.data.frame(`*`<mysterycall_matched_controls>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_matched_controls.md)
  :

  Coerce a `mysterycall_matched_controls` object to a data frame

- [`as.data.frame(`*`<mysterycall_multiresponse>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_multiresponse.md)
  :

  Coerce a `mysterycall_multiresponse` object to a data frame

- [`as.data.frame(`*`<mysterycall_offer_reconciliation>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_offer_reconciliation.md)
  :

  Coerce a `mysterycall_offer_reconciliation` object to a data frame

- [`as.data.frame(`*`<mysterycall_outcome_bounds>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_outcome_bounds.md)
  :

  Coerce a `mysterycall_outcome_bounds` object to a data frame

- [`as.data.frame(`*`<mysterycall_paired_mcnemar>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_paired_mcnemar.md)
  :

  Coerce a `mysterycall_paired_mcnemar` object to a data frame

- [`as.data.frame(`*`<mysterycall_paired_wait>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_paired_wait.md)
  :

  Coerce a `mysterycall_paired_wait` object to a data frame

- [`as.data.frame(`*`<mysterycall_rank_comparison>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_rank_comparison.md)
  :

  Coerce a `mysterycall_rank_comparison` object to a data frame

- [`as.data.frame(`*`<mysterycall_twopart_power>`*`)`](https://mufflyt.github.io/mysterycall/reference/as.data.frame.mysterycall_twopart_power.md)
  :

  Coerce a `mysterycall_twopart_power` object to a data frame

- [`print(`*`<mysterycall_access_cascade>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_access_cascade.md)
  :

  Print a `mysterycall_access_cascade` object

- [`print(`*`<mysterycall_categorical_test>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_categorical_test.md)
  :

  Print a `mysterycall_categorical_test` object

- [`print(`*`<mysterycall_cmh_test>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_cmh_test.md)
  :

  Print a `mysterycall_cmh_test` object

- [`print(`*`<mysterycall_concordance>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_concordance.md)
  :

  Print a `mysterycall_concordance` object

- [`print(`*`<mysterycall_consistency_report>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_consistency_report.md)
  :

  Print a `mysterycall_consistency_report` object

- [`print(`*`<mysterycall_crisp_checklist>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_crisp_checklist.md)
  :

  Print a `mysterycall_crisp_checklist` object

- [`print(`*`<mysterycall_cumulative_access_curve>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_cumulative_access_curve.md)
  :

  Print a `mysterycall_cumulative_access_curve` object

- [`print(`*`<mysterycall_exclusion_summary>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_exclusion_summary.md)
  :

  Print a `mysterycall_exclusion_summary` object

- [`print(`*`<mysterycall_hurdle_wait>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_hurdle_wait.md)
  :

  Print a `mysterycall_hurdle_wait` object

- [`print(`*`<mysterycall_joint_test>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_joint_test.md)
  :

  Print a `mysterycall_joint_test` object

- [`print(`*`<mysterycall_leave_one_out>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_leave_one_out.md)
  :

  Print a `mysterycall_leave_one_out` object

- [`print(`*`<mysterycall_marginal_power>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_marginal_power.md)
  :

  Print a `mysterycall_marginal_power` object

- [`print(`*`<mysterycall_matched_controls>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_matched_controls.md)
  :

  Print a `mysterycall_matched_controls` object

- [`print(`*`<mysterycall_multiresponse>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_multiresponse.md)
  :

  Print a `mysterycall_multiresponse` object

- [`print(`*`<mysterycall_offer_reconciliation>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_offer_reconciliation.md)
  :

  Print a `mysterycall_offer_reconciliation` object

- [`print(`*`<mysterycall_outcome_bounds>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_outcome_bounds.md)
  :

  Print a `mysterycall_outcome_bounds` object

- [`print(`*`<mysterycall_paired_mcnemar>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_paired_mcnemar.md)
  :

  Print a `mysterycall_paired_mcnemar` object

- [`print(`*`<mysterycall_paired_wait>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_paired_wait.md)
  :

  Print a `mysterycall_paired_wait` object

- [`print(`*`<mysterycall_rank_comparison>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_rank_comparison.md)
  :

  Print a `mysterycall_rank_comparison` object

- [`print(`*`<mysterycall_reconciliation>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_reconciliation.md)
  : Print method for mysterycall_reconciliation objects

- [`print(`*`<mysterycall_rubric>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_rubric.md)
  :

  Print a `mysterycall_rubric` object

- [`print(`*`<mysterycall_simple_poisson>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_simple_poisson.md)
  :

  Print a `mysterycall_simple_poisson` object

- [`print(`*`<mysterycall_twopart_power>`*`)`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_twopart_power.md)
  :

  Print a `mysterycall_twopart_power` object

## Deprecated

- [`arsenal_tables_write2word()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`calculate_intersection_overlap_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`clean_phase_1_results()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`clean_phase_2_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`create_and_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`create_density_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`create_individual_isochrone_plots()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`create_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`create_isochrones_for_dataframe()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`create_line_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`create_scatter_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`download_large_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`genderize_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`geocode_unique_addresses()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`hrr()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`hrr_generate_maps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`map_create_acog_districts_sf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`map_create_base()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`map_create_block_group_overlap()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`map_create_leaflet_base()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`map_create_physician_dot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`most_common_gender_training_academic()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`physician_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`plot_and_save_emmeans()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`plot_census_age_distribution()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`remove_constant_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`remove_near_zero_var()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`rename_columns_by_substring()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`retrieve_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`run_mystery_caller_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`run_mystery_caller_workflow_with_logging()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`save_quality_check_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`search_by_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`states_where_physicians_were_NOT_contacted()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`summarize_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`table_calculate_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`table_calculate_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`table_generate_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`table_write_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`validate_and_remove_invalid_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`search_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`test_and_process_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_log_cache_hit()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_log_error()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_log_info()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_log_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_log_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_log_step()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_log_step_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_log_success()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_log_warning()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_map_acog_districts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_map_base()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_map_block_group()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_map_leaflet()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_map_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_most_common_gender()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_multi_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_multi_done()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_multi_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_multi_step()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_multi_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_not_contacted_states()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_physician_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_plot_census_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_plot_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_plot_emmeans()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_plot_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_plot_line()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_print_dashboard()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_progress_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_progress_callback()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_progress_done()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_progress_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_progress_finish()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_progress_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_progress_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_progress_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_progress_tracker()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_progress_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_quality_tier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_remove_constants()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_remove_near_zero()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_rename_columns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_resolve_path()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_run_workflow_logged()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_spinner_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_spinner_stop()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_standard_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_standard_palette()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_summarize_census()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_use_quiet_logging()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_workflow_end()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_workflow_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_write_arsenal_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`tyler_write_table_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  : Deprecated functions in mysterycall
- [`mystercall_no_longer_in_service()`](https://mufflyt.github.io/mysterycall/reference/mystercall_no_longer_in_service.md)
  [`mysterycall_no_longer_in_service()`](https://mufflyt.github.io/mysterycall/reference/mystercall_no_longer_in_service.md)
  : Dial phone numbers and flag lines that appear no longer in service
