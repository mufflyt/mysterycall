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
  Data of FIPS codes
- [`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md)
  : Physician Location and Specialty Data
- [`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)
  : Taxonomy Codes for Obstetricians and Gynecologists

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
- [`KNOWN_ACADEMIC_INSTITUTIONS`](https://mufflyt.github.io/mysterycall/reference/KNOWN_ACADEMIC_INSTITUTIONS.md)
  : Known Academic Medical Centers
- [`ACADEMIC_HOSPITAL_PATTERNS`](https://mufflyt.github.io/mysterycall/reference/ACADEMIC_HOSPITAL_PATTERNS.md)
  : Academic Hospital Name Patterns
- [`ACGME_PROGRAM_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/ACGME_PROGRAM_INDICATORS.md)
  : ACGME Program Indicators
- [`COTH_TEACHING_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/COTH_TEACHING_INDICATORS.md)
  : COTH (Council of Teaching Hospitals) Indicators
- [`MEDICAL_SCHOOL_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICAL_SCHOOL_INDICATORS.md)
  : Medical School Affiliation Patterns
- [`NIH_CTSA_HUBS`](https://mufflyt.github.io/mysterycall/reference/NIH_CTSA_HUBS.md)
  : NIH CTSA Hub Patterns
- [`NCI_CANCER_CENTERS`](https://mufflyt.github.io/mysterycall/reference/NCI_CANCER_CENTERS.md)
  : NCI-Designated Cancer Center Patterns
- [`MEDICARE_GME_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICARE_GME_INDICATORS.md)
  : Medicare GME Payment Indicators

## Geocoding and Mapping

Geocode addresses, build isochrones, and produce publication maps.

- [`mysterycall_geocode()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode.md)
  : Geocode unique addresses from a file

- [`mysterycall_create_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_isochrones.md)
  : Calculate drive-time isochrones for a location

- [`mysterycall_isochrones_for_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_isochrones_for_df.md)
  : Get isochrones for each point in a dataframe

- [`mysterycall_plot_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_isochrones.md)
  : Create Individual Isochrone Maps and Shapefiles

- [`mysterycall_clear_isochrone_cache()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clear_isochrone_cache.md)
  : Clear the isochrone memoization cache

- [`mysterycall_map_base()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_base.md)
  : Create a Configurable Leaflet Base Map

- [`mysterycall_map_leaflet()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_leaflet.md)
  : Create a Leaflet Base Map

- [`mysterycall_map_acog_districts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_acog_districts.md)
  :

  Create `sf` Polygons for ACOG Districts

- [`mysterycall_map_block_group()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_block_group.md)
  : Function to create and export a map showing block group overlap with
  isochrones

- [`mysterycall_map_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_physicians.md)
  : Create and Save a Leaflet Dot Map of Physicians

- [`mysterycall_calculate_overlap()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_calculate_overlap.md)
  : Calculate intersection overlap and save results to shapefiles.

- [`mysterycall_hrr()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hrr.md)
  : Get Hospital Referral Region Shapefile

- [`mysterycall_hrr_maps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hrr_maps.md)
  : Generate honeycomb hex maps for Hospital Referral Regions

- [`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md)
  : Map US states to medical society districts and Census regions

- [`ensure_hrr_shapefile()`](https://mufflyt.github.io/mysterycall/reference/ensure_hrr_shapefile.md)
  : Ensure the Dartmouth Atlas HRR boundary shapefile is available
  locally

## Acceptance Rate Maps

Choropleth maps of appointment acceptance rates by state.

- [`mysterycall_map_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_acceptance_rate.md)
  : Choropleth map of appointment acceptance rates by US state

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
  [`process_and_save_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`progress_tracker()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`progress_tracker_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`progress_tracker_finish()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`progress_tracker_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`progress_tracker_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  [`progress_tracker_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  : Deprecated functions in mysterycall
