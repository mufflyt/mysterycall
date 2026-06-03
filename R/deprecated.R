#' Deprecated functions in mysterycall
#'
#' These names were used before `mysterycall` adopted a consistent `mysterycall_` prefix.
#' They emit deprecation warnings and forward all arguments to the current
#' equivalent.
#'
#' @name mysterycall-deprecated
#' @keywords internal
NULL

#' @rdname mysterycall-deprecated
arsenal_tables_write2word <- function(...) {
  .Deprecated("mysterycall_write_arsenal_table", package = "mysterycall",
              msg = paste0("arsenal_tables_write2word() is deprecated. Use mysterycall_write_arsenal_table() instead."))
  mysterycall_write_arsenal_table(...)
}

#' @rdname mysterycall-deprecated
calculate_intersection_overlap_and_save <- function(...) {
  .Deprecated("mysterycall_calculate_overlap", package = "mysterycall",
              msg = paste0("calculate_intersection_overlap_and_save() is deprecated. Use mysterycall_calculate_overlap() instead."))
  mysterycall_calculate_overlap(...)
}

#' @rdname mysterycall-deprecated
check_normality <- function(...) {
  .Deprecated("mysterycall_check_normality", package = "mysterycall",
              msg = paste0("check_normality() is deprecated. Use mysterycall_check_normality() instead."))
  mysterycall_check_normality(...)
}

#' @rdname mysterycall-deprecated
clean_phase_1_results <- function(...) {
  .Deprecated("mysterycall_clean_phase1", package = "mysterycall",
              msg = paste0("clean_phase_1_results() is deprecated. Use mysterycall_clean_phase1() instead."))
  mysterycall_clean_phase1(...)
}

#' @rdname mysterycall-deprecated
clean_phase_2_data <- function(...) {
  .Deprecated("mysterycall_clean_phase2", package = "mysterycall",
              msg = paste0("clean_phase_2_data() is deprecated. Use mysterycall_clean_phase2() instead."))
  mysterycall_clean_phase2(...)
}

#' @rdname mysterycall-deprecated
create_and_plot_interaction <- function(...) {
  .Deprecated("mysterycall_plot_interaction", package = "mysterycall",
              msg = paste0("create_and_plot_interaction() is deprecated. Use mysterycall_plot_interaction() instead."))
  mysterycall_plot_interaction(...)
}

#' @rdname mysterycall-deprecated
create_density_plot <- function(...) {
  .Deprecated("mysterycall_plot_density", package = "mysterycall",
              msg = paste0("create_density_plot() is deprecated. Use mysterycall_plot_density() instead."))
  mysterycall_plot_density(...)
}

#' @rdname mysterycall-deprecated
create_formula <- function(...) {
  .Deprecated("mysterycall_create_formula", package = "mysterycall",
              msg = paste0("create_formula() is deprecated. Use mysterycall_create_formula() instead."))
  mysterycall_create_formula(...)
}

#' @rdname mysterycall-deprecated
create_individual_isochrone_plots <- function(...) {
  .Deprecated("mysterycall_plot_isochrones", package = "mysterycall",
              msg = paste0("create_individual_isochrone_plots() is deprecated. Use mysterycall_plot_isochrones() instead."))
  mysterycall_plot_isochrones(...)
}

#' @rdname mysterycall-deprecated
create_isochrones <- function(...) {
  .Deprecated("mysterycall_create_isochrones", package = "mysterycall",
              msg = paste0("create_isochrones() is deprecated. Use mysterycall_create_isochrones() instead."))
  mysterycall_create_isochrones(...)
}

#' @rdname mysterycall-deprecated
create_isochrones_for_dataframe <- function(...) {
  .Deprecated("mysterycall_isochrones_for_df", package = "mysterycall",
              msg = paste0("create_isochrones_for_dataframe() is deprecated. Use mysterycall_isochrones_for_df() instead."))
  mysterycall_isochrones_for_df(...)
}

#' @rdname mysterycall-deprecated
create_line_plot <- function(...) {
  .Deprecated("mysterycall_plot_line", package = "mysterycall",
              msg = paste0("create_line_plot() is deprecated. Use mysterycall_plot_line() instead."))
  mysterycall_plot_line(...)
}

#' @rdname mysterycall-deprecated
create_scatter_plot <- function(...) {
  .Deprecated("mysterycall_plot_scatter", package = "mysterycall",
              msg = paste0("create_scatter_plot() is deprecated. Use mysterycall_plot_scatter() instead."))
  mysterycall_plot_scatter(...)
}

#' @rdname mysterycall-deprecated
download_large_file <- function(...) {
  .Deprecated("mysterycall_download_file", package = "mysterycall",
              msg = paste0("download_large_file() is deprecated. Use mysterycall_download_file() instead."))
  mysterycall_download_file(...)
}

#' @rdname mysterycall-deprecated
format_pct <- function(...) {
  .Deprecated("mysterycall_format_pct", package = "mysterycall",
              msg = paste0("format_pct() is deprecated. Use mysterycall_format_pct() instead."))
  mysterycall_format_pct(...)
}

#' @rdname mysterycall-deprecated
genderize_physicians <- function(...) {
  .Deprecated("mysterycall_genderize", package = "mysterycall",
              msg = paste0("genderize_physicians() is deprecated. Use mysterycall_genderize() instead."))
  mysterycall_genderize(...)
}

#' @rdname mysterycall-deprecated
geocode_unique_addresses <- function(...) {
  .Deprecated("mysterycall_geocode", package = "mysterycall",
              msg = paste0("geocode_unique_addresses() is deprecated. Use mysterycall_geocode() instead."))
  mysterycall_geocode(...)
}

#' @rdname mysterycall-deprecated
get_census_data <- function(...) {
  .Deprecated("mysterycall_get_census_data", package = "mysterycall",
              msg = paste0("get_census_data() is deprecated. Use mysterycall_get_census_data() instead."))
  mysterycall_get_census_data(...)
}

#' @rdname mysterycall-deprecated
hrr <- function(...) {
  .Deprecated("mysterycall_hrr", package = "mysterycall",
              msg = paste0("hrr() is deprecated. Use mysterycall_hrr() instead."))
  mysterycall_hrr(...)
}

#' @rdname mysterycall-deprecated
hrr_generate_maps <- function(...) {
  .Deprecated("mysterycall_hrr_maps", package = "mysterycall",
              msg = paste0("hrr_generate_maps() is deprecated. Use mysterycall_hrr_maps() instead."))
  mysterycall_hrr_maps(...)
}

#' @rdname mysterycall-deprecated
map_create_acog_districts_sf <- function(...) {
  .Deprecated("mysterycall_map_acog_districts", package = "mysterycall",
              msg = paste0("map_create_acog_districts_sf() is deprecated. Use mysterycall_map_acog_districts() instead."))
  mysterycall_map_acog_districts(...)
}

#' @rdname mysterycall-deprecated
map_create_base <- function(...) {
  .Deprecated("mysterycall_map_base", package = "mysterycall",
              msg = paste0("map_create_base() is deprecated. Use mysterycall_map_base() instead."))
  mysterycall_map_base(...)
}

#' @rdname mysterycall-deprecated
map_create_block_group_overlap <- function(...) {
  .Deprecated("mysterycall_map_block_group", package = "mysterycall",
              msg = paste0("map_create_block_group_overlap() is deprecated. Use mysterycall_map_block_group() instead."))
  mysterycall_map_block_group(...)
}

#' @rdname mysterycall-deprecated
map_create_leaflet_base <- function(...) {
  .Deprecated("mysterycall_map_leaflet", package = "mysterycall",
              msg = paste0("map_create_leaflet_base() is deprecated. Use mysterycall_map_leaflet() instead."))
  mysterycall_map_leaflet(...)
}

#' @rdname mysterycall-deprecated
map_create_physician_dot <- function(...) {
  .Deprecated("mysterycall_map_physicians", package = "mysterycall",
              msg = paste0("map_create_physician_dot() is deprecated. Use mysterycall_map_physicians() instead."))
  mysterycall_map_physicians(...)
}

#' @rdname mysterycall-deprecated
max_table <- function(...) {
  .Deprecated("mysterycall_max_table", package = "mysterycall",
              msg = paste0("max_table() is deprecated. Use mysterycall_max_table() instead."))
  mysterycall_max_table(...)
}

#' @rdname mysterycall-deprecated
min_table <- function(...) {
  .Deprecated("mysterycall_min_table", package = "mysterycall",
              msg = paste0("min_table() is deprecated. Use mysterycall_min_table() instead."))
  mysterycall_min_table(...)
}

#' @rdname mysterycall-deprecated
most_common_gender_training_academic <- function(...) {
  .Deprecated("mysterycall_most_common_gender", package = "mysterycall",
              msg = paste0("most_common_gender_training_academic() is deprecated. Use mysterycall_most_common_gender() instead."))
  mysterycall_most_common_gender(...)
}

#' @rdname mysterycall-deprecated
physician_age <- function(...) {
  .Deprecated("mysterycall_physician_age", package = "mysterycall",
              msg = paste0("physician_age() is deprecated. Use mysterycall_physician_age() instead."))
  mysterycall_physician_age(...)
}

#' @rdname mysterycall-deprecated
plot_and_save_emmeans <- function(...) {
  .Deprecated("mysterycall_plot_emmeans", package = "mysterycall",
              msg = paste0("plot_and_save_emmeans() is deprecated. Use mysterycall_plot_emmeans() instead."))
  mysterycall_plot_emmeans(...)
}

#' @rdname mysterycall-deprecated
plot_census_age_distribution <- function(...) {
  .Deprecated("mysterycall_plot_census_age", package = "mysterycall",
              msg = paste0("plot_census_age_distribution() is deprecated. Use mysterycall_plot_census_age() instead."))
  mysterycall_plot_census_age(...)
}

#' @rdname mysterycall-deprecated
remove_constant_vars <- function(...) {
  .Deprecated("mysterycall_remove_constants", package = "mysterycall",
              msg = paste0("remove_constant_vars() is deprecated. Use mysterycall_remove_constants() instead."))
  mysterycall_remove_constants(...)
}

#' @rdname mysterycall-deprecated
remove_near_zero_var <- function(...) {
  .Deprecated("mysterycall_remove_near_zero", package = "mysterycall",
              msg = paste0("remove_near_zero_var() is deprecated. Use mysterycall_remove_near_zero() instead."))
  mysterycall_remove_near_zero(...)
}

#' @rdname mysterycall-deprecated
rename_columns_by_substring <- function(...) {
  .Deprecated("mysterycall_rename_columns", package = "mysterycall",
              msg = paste0("rename_columns_by_substring() is deprecated. Use mysterycall_rename_columns() instead."))
  mysterycall_rename_columns(...)
}

#' @rdname mysterycall-deprecated
retrieve_clinician_data <- function(...) {
  .Deprecated("mysterycall_get_clinician_data", package = "mysterycall",
              msg = paste0("retrieve_clinician_data() is deprecated. Use mysterycall_get_clinician_data() instead."))
  mysterycall_get_clinician_data(...)
}

#' @rdname mysterycall-deprecated
run_mystery_caller_workflow <- function(...) {
  .Deprecated("mysterycall_run_workflow", package = "mysterycall",
              msg = paste0("run_mystery_caller_workflow() is deprecated. Use mysterycall_run_workflow() instead."))
  mysterycall_run_workflow(...)
}

#' @rdname mysterycall-deprecated
run_mystery_caller_workflow_with_logging <- function(...) {
  .Deprecated("mysterycall_run_workflow_logged", package = "mysterycall",
              msg = paste0("run_mystery_caller_workflow_with_logging() is deprecated. Use mysterycall_run_workflow_logged() instead."))
  mysterycall_run_workflow_logged(...)
}

#' @rdname mysterycall-deprecated
save_quality_check_table <- function(...) {
  .Deprecated("mysterycall_save_quality_table", package = "mysterycall",
              msg = paste0("save_quality_check_table() is deprecated. Use mysterycall_save_quality_table() instead."))
  mysterycall_save_quality_table(...)
}

#' @rdname mysterycall-deprecated
search_and_process_npi <- function(...) {
  .Deprecated("mysterycall_search_and_process_npi", package = "mysterycall",
              msg = paste0("search_and_process_npi() is deprecated. Use mysterycall_search_and_process_npi() instead."))
  mysterycall_search_and_process_npi(...)
}

#' @rdname mysterycall-deprecated
search_by_taxonomy <- function(...) {
  .Deprecated("mysterycall_search_taxonomy", package = "mysterycall",
              msg = paste0("search_by_taxonomy() is deprecated. Use mysterycall_search_taxonomy() instead."))
  mysterycall_search_taxonomy(...)
}

#' @rdname mysterycall-deprecated
split_and_save <- function(...) {
  .Deprecated("mysterycall_split_and_save", package = "mysterycall",
              msg = paste0("split_and_save() is deprecated. Use mysterycall_split_and_save() instead."))
  mysterycall_split_and_save(...)
}

#' @rdname mysterycall-deprecated
states_where_physicians_were_NOT_contacted <- function(...) {
  .Deprecated("mysterycall_not_contacted_states", package = "mysterycall",
              msg = paste0("states_where_physicians_were_NOT_contacted() is deprecated. Use mysterycall_not_contacted_states() instead."))
  mysterycall_not_contacted_states(...)
}

#' @rdname mysterycall-deprecated
summarize_census_data <- function(...) {
  .Deprecated("mysterycall_summarize_census", package = "mysterycall",
              msg = paste0("summarize_census_data() is deprecated. Use mysterycall_summarize_census() instead."))
  mysterycall_summarize_census(...)
}

#' @rdname mysterycall-deprecated
table_calculate_percentages <- function(...) {
  .Deprecated("mysterycall_table_percentages", package = "mysterycall",
              msg = paste0("table_calculate_percentages() is deprecated. Use mysterycall_table_percentages() instead."))
  mysterycall_table_percentages(...)
}

#' @rdname mysterycall-deprecated
table_calculate_proportion <- function(...) {
  .Deprecated("mysterycall_table_proportion", package = "mysterycall",
              msg = paste0("table_calculate_proportion() is deprecated. Use mysterycall_table_proportion() instead."))
  mysterycall_table_proportion(...)
}

#' @rdname mysterycall-deprecated
table_generate_overall <- function(...) {
  .Deprecated("mysterycall_table_overall", package = "mysterycall",
              msg = paste0("table_generate_overall() is deprecated. Use mysterycall_table_overall() instead."))
  mysterycall_table_overall(...)
}

#' @rdname mysterycall-deprecated
table_write_pdf <- function(...) {
  .Deprecated("mysterycall_write_table_pdf", package = "mysterycall",
              msg = paste0("table_write_pdf() is deprecated. Use mysterycall_write_table_pdf() instead."))
  mysterycall_write_table_pdf(...)
}

#' @rdname mysterycall-deprecated
validate_and_remove_invalid_npi <- function(...) {
  .Deprecated("mysterycall_validate_npi", package = "mysterycall",
              msg = paste0("validate_and_remove_invalid_npi() is deprecated. Use mysterycall_validate_npi() instead."))
  mysterycall_validate_npi(...)
}

#' @rdname mysterycall-deprecated
#' @param input_data A data frame or CSV path containing `first` and `last` columns.
search_npi <- function(input_data, ...) {
  .Deprecated("mysterycall_search_and_process_npi", package = "mysterycall",
              msg = "search_npi() is deprecated. Use mysterycall_search_and_process_npi().")
  data <- if (is.data.frame(input_data)) {
    input_data
  } else if (is.character(input_data) && length(input_data) == 1) {
    utils::read.csv(input_data, stringsAsFactors = FALSE)
  } else {
    stop("`input_data` must be a data frame or a file path to a CSV.", call. = FALSE)
  }
  required_cols <- c("first", "last")
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols)) {
    stop("Input data must contain columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  mysterycall_search_and_process_npi(data = data, ...)
}

#' @rdname mysterycall-deprecated
test_and_process_isochrones <- function(input_file, ...) {
  .Deprecated("mysterycall_isochrones_for_df", package = "mysterycall",
              msg = "test_and_process_isochrones() is deprecated. Use mysterycall_isochrones_for_df().")
  stop("test_and_process_isochrones() is deprecated and has been removed. Use mysterycall_isochrones_for_df().", call. = FALSE)
}

#' @rdname mysterycall-deprecated
#' @param chunk_size Deprecated.
process_and_save_isochrones <- function(input_file, chunk_size = 25, ...) {
  .Deprecated("mysterycall_isochrones_for_df", package = "mysterycall",
              msg = "process_and_save_isochrones() is deprecated. Use mysterycall_isochrones_for_df().")
  stop("process_and_save_isochrones() is deprecated and has been removed. Use mysterycall_isochrones_for_df().", call. = FALSE)
}

#' @rdname mysterycall-deprecated
progress_tracker <- function(...) {
  .Deprecated("mysterycall_progress_tracker", package = "mysterycall",
              msg = "progress_tracker() is deprecated. Use mysterycall_progress_tracker() instead.")
  mysterycall_progress_tracker(...)
}

#' @rdname mysterycall-deprecated
progress_tracker_start <- function(...) {
  .Deprecated("mysterycall_progress_start", package = "mysterycall",
              msg = "progress_tracker_start() is deprecated. Use mysterycall_progress_start() instead.")
  mysterycall_progress_start(...)
}

#' @rdname mysterycall-deprecated
progress_tracker_finish <- function(...) {
  .Deprecated("mysterycall_progress_finish", package = "mysterycall",
              msg = "progress_tracker_finish() is deprecated. Use mysterycall_progress_finish() instead.")
  mysterycall_progress_finish(...)
}

#' @rdname mysterycall-deprecated
progress_tracker_fail <- function(...) {
  .Deprecated("mysterycall_tracker_fail", package = "mysterycall",
              msg = "progress_tracker_fail() is deprecated. Use mysterycall_tracker_fail() instead.")
  mysterycall_tracker_fail(...)
}

#' @rdname mysterycall-deprecated
progress_tracker_update <- function(...) {
  .Deprecated("mysterycall_tracker_update", package = "mysterycall",
              msg = "progress_tracker_update() is deprecated. Use mysterycall_tracker_update() instead.")
  mysterycall_tracker_update(...)
}

#' @rdname mysterycall-deprecated
progress_tracker_summary <- function(...) {
  .Deprecated("mysterycall_progress_summary", package = "mysterycall",
              msg = "progress_tracker_summary() is deprecated. Use mysterycall_progress_summary() instead.")
  mysterycall_progress_summary(...)
}

# -- tyler_ -> mysterycall_ shims (package renamed from tyler to mysterycall) ---

#' Deprecated tyler_ prefix functions
#'
#' @description
#' These functions existed when the package was named `tyler`. They have been
#' renamed with the `mysterycall_` prefix. All `tyler_*` wrappers call their
#' `mysterycall_*` counterpart and emit a deprecation warning.
#'
#' @name tyler-deprecated
#' @keywords internal
NULL

#' @rdname tyler-deprecated
tyler_assess_data_quality <- function(...) {
  .Deprecated("mysterycall_assess_data_quality", package = "mysterycall",
              msg = paste0("tyler_assess_data_quality() is deprecated. Use mysterycall_assess_data_quality() instead."))
  mysterycall_assess_data_quality(...)
}

#' @rdname tyler-deprecated
tyler_calculate_overlap <- function(...) {
  .Deprecated("mysterycall_calculate_overlap", package = "mysterycall",
              msg = paste0("tyler_calculate_overlap() is deprecated. Use mysterycall_calculate_overlap() instead."))
  mysterycall_calculate_overlap(...)
}

#' @rdname tyler-deprecated
tyler_check_api_response <- function(...) {
  .Deprecated("mysterycall_check_api_response", package = "mysterycall",
              msg = paste0("tyler_check_api_response() is deprecated. Use mysterycall_check_api_response() instead."))
  mysterycall_check_api_response(...)
}

#' @rdname tyler-deprecated
tyler_check_data_completeness <- function(...) {
  .Deprecated("mysterycall_check_data_completeness", package = "mysterycall",
              msg = paste0("tyler_check_data_completeness() is deprecated. Use mysterycall_check_data_completeness() instead."))
  mysterycall_check_data_completeness(...)
}

#' @rdname tyler-deprecated
tyler_check_dependencies <- function(...) {
  .Deprecated("mysterycall_check_dependencies", package = "mysterycall",
              msg = paste0("tyler_check_dependencies() is deprecated. Use mysterycall_check_dependencies() instead."))
  mysterycall_check_dependencies(...)
}

#' @rdname tyler-deprecated
tyler_check_no_data_loss <- function(...) {
  .Deprecated("mysterycall_check_no_data_loss", package = "mysterycall",
              msg = paste0("tyler_check_no_data_loss() is deprecated. Use mysterycall_check_no_data_loss() instead."))
  mysterycall_check_no_data_loss(...)
}

#' @rdname tyler-deprecated
tyler_check_no_limits <- function(...) {
  .Deprecated("mysterycall_check_no_limits", package = "mysterycall",
              msg = paste0("tyler_check_no_limits() is deprecated. Use mysterycall_check_no_limits() instead."))
  mysterycall_check_no_limits(...)
}

#' @rdname tyler-deprecated
tyler_check_normality <- function(...) {
  .Deprecated("mysterycall_check_normality", package = "mysterycall",
              msg = paste0("tyler_check_normality() is deprecated. Use mysterycall_check_normality() instead."))
  mysterycall_check_normality(...)
}

#' @rdname tyler-deprecated
tyler_clean_phase1 <- function(...) {
  .Deprecated("mysterycall_clean_phase1", package = "mysterycall",
              msg = paste0("tyler_clean_phase1() is deprecated. Use mysterycall_clean_phase1() instead."))
  mysterycall_clean_phase1(...)
}

#' @rdname tyler-deprecated
tyler_clean_phase2 <- function(...) {
  .Deprecated("mysterycall_clean_phase2", package = "mysterycall",
              msg = paste0("tyler_clean_phase2() is deprecated. Use mysterycall_clean_phase2() instead."))
  mysterycall_clean_phase2(...)
}

#' @rdname tyler-deprecated
tyler_clear_isochrone_cache <- function(...) {
  .Deprecated("mysterycall_clear_isochrone_cache", package = "mysterycall",
              msg = paste0("tyler_clear_isochrone_cache() is deprecated. Use mysterycall_clear_isochrone_cache() instead."))
  mysterycall_clear_isochrone_cache(...)
}

#' @rdname tyler-deprecated
tyler_create_formula <- function(...) {
  .Deprecated("mysterycall_create_formula", package = "mysterycall",
              msg = paste0("tyler_create_formula() is deprecated. Use mysterycall_create_formula() instead."))
  mysterycall_create_formula(...)
}

#' @rdname tyler-deprecated
tyler_create_isochrones <- function(...) {
  .Deprecated("mysterycall_create_isochrones", package = "mysterycall",
              msg = paste0("tyler_create_isochrones() is deprecated. Use mysterycall_create_isochrones() instead."))
  mysterycall_create_isochrones(...)
}

#' @rdname tyler-deprecated
tyler_download_file <- function(...) {
  .Deprecated("mysterycall_download_file", package = "mysterycall",
              msg = paste0("tyler_download_file() is deprecated. Use mysterycall_download_file() instead."))
  mysterycall_download_file(...)
}

#' @rdname tyler-deprecated
tyler_estimate_resources <- function(...) {
  .Deprecated("mysterycall_estimate_resources", package = "mysterycall",
              msg = paste0("tyler_estimate_resources() is deprecated. Use mysterycall_estimate_resources() instead."))
  mysterycall_estimate_resources(...)
}

#' @rdname tyler-deprecated
tyler_export_with_backup <- function(...) {
  .Deprecated("mysterycall_export_with_backup", package = "mysterycall",
              msg = paste0("tyler_export_with_backup() is deprecated. Use mysterycall_export_with_backup() instead."))
  mysterycall_export_with_backup(...)
}

#' @rdname tyler-deprecated
tyler_format_duration <- function(...) {
  .Deprecated("mysterycall_format_duration", package = "mysterycall",
              msg = paste0("tyler_format_duration() is deprecated. Use mysterycall_format_duration() instead."))
  mysterycall_format_duration(...)
}

#' @rdname tyler-deprecated
tyler_format_pct <- function(...) {
  .Deprecated("mysterycall_format_pct", package = "mysterycall",
              msg = paste0("tyler_format_pct() is deprecated. Use mysterycall_format_pct() instead."))
  mysterycall_format_pct(...)
}

#' @rdname tyler-deprecated
tyler_genderize <- function(...) {
  .Deprecated("mysterycall_genderize", package = "mysterycall",
              msg = paste0("tyler_genderize() is deprecated. Use mysterycall_genderize() instead."))
  mysterycall_genderize(...)
}

#' @rdname tyler-deprecated
tyler_geocode <- function(...) {
  .Deprecated("mysterycall_geocode", package = "mysterycall",
              msg = paste0("tyler_geocode() is deprecated. Use mysterycall_geocode() instead."))
  mysterycall_geocode(...)
}

#' @rdname tyler-deprecated
tyler_get_census_data <- function(...) {
  .Deprecated("mysterycall_get_census_data", package = "mysterycall",
              msg = paste0("tyler_get_census_data() is deprecated. Use mysterycall_get_census_data() instead."))
  mysterycall_get_census_data(...)
}

#' @rdname tyler-deprecated
tyler_get_clinician_data <- function(...) {
  .Deprecated("mysterycall_get_clinician_data", package = "mysterycall",
              msg = paste0("tyler_get_clinician_data() is deprecated. Use mysterycall_get_clinician_data() instead."))
  mysterycall_get_clinician_data(...)
}

#' @rdname tyler-deprecated
tyler_hrr <- function(...) {
  .Deprecated("mysterycall_hrr", package = "mysterycall",
              msg = paste0("tyler_hrr() is deprecated. Use mysterycall_hrr() instead."))
  mysterycall_hrr(...)
}

#' @rdname tyler-deprecated
tyler_hrr_maps <- function(...) {
  .Deprecated("mysterycall_hrr_maps", package = "mysterycall",
              msg = paste0("tyler_hrr_maps() is deprecated. Use mysterycall_hrr_maps() instead."))
  mysterycall_hrr_maps(...)
}

#' @rdname tyler-deprecated
tyler_isochrones_for_df <- function(...) {
  .Deprecated("mysterycall_isochrones_for_df", package = "mysterycall",
              msg = paste0("tyler_isochrones_for_df() is deprecated. Use mysterycall_isochrones_for_df() instead."))
  mysterycall_isochrones_for_df(...)
}

#' @rdname tyler-deprecated
tyler_log_cache_hit <- function(...) {
  .Deprecated("mysterycall_log_cache_hit", package = "mysterycall",
              msg = paste0("tyler_log_cache_hit() is deprecated. Use mysterycall_log_cache_hit() instead."))
  mysterycall_log_cache_hit(...)
}

#' @rdname tyler-deprecated
tyler_log_error <- function(...) {
  .Deprecated("mysterycall_log_error", package = "mysterycall",
              msg = paste0("tyler_log_error() is deprecated. Use mysterycall_log_error() instead."))
  mysterycall_log_error(...)
}

#' @rdname tyler-deprecated
tyler_log_info <- function(...) {
  .Deprecated("mysterycall_log_info", package = "mysterycall",
              msg = paste0("tyler_log_info() is deprecated. Use mysterycall_log_info() instead."))
  mysterycall_log_info(...)
}

#' @rdname tyler-deprecated
tyler_log_progress <- function(...) {
  .Deprecated("mysterycall_log_progress", package = "mysterycall",
              msg = paste0("tyler_log_progress() is deprecated. Use mysterycall_log_progress() instead."))
  mysterycall_log_progress(...)
}

#' @rdname tyler-deprecated
tyler_log_save <- function(...) {
  .Deprecated("mysterycall_log_save", package = "mysterycall",
              msg = paste0("tyler_log_save() is deprecated. Use mysterycall_log_save() instead."))
  mysterycall_log_save(...)
}

#' @rdname tyler-deprecated
tyler_log_step <- function(...) {
  .Deprecated("mysterycall_log_step", package = "mysterycall",
              msg = paste0("tyler_log_step() is deprecated. Use mysterycall_log_step() instead."))
  mysterycall_log_step(...)
}

#' @rdname tyler-deprecated
tyler_log_step_complete <- function(...) {
  .Deprecated("mysterycall_log_step_complete", package = "mysterycall",
              msg = paste0("tyler_log_step_complete() is deprecated. Use mysterycall_log_step_complete() instead."))
  mysterycall_log_step_complete(...)
}

#' @rdname tyler-deprecated
tyler_log_success <- function(...) {
  .Deprecated("mysterycall_log_success", package = "mysterycall",
              msg = paste0("tyler_log_success() is deprecated. Use mysterycall_log_success() instead."))
  mysterycall_log_success(...)
}

#' @rdname tyler-deprecated
tyler_log_warning <- function(...) {
  .Deprecated("mysterycall_log_warning", package = "mysterycall",
              msg = paste0("tyler_log_warning() is deprecated. Use mysterycall_log_warning() instead."))
  mysterycall_log_warning(...)
}

#' @rdname tyler-deprecated
tyler_map_acog_districts <- function(...) {
  .Deprecated("mysterycall_map_acog_districts", package = "mysterycall",
              msg = paste0("tyler_map_acog_districts() is deprecated. Use mysterycall_map_acog_districts() instead."))
  mysterycall_map_acog_districts(...)
}

#' @rdname tyler-deprecated
tyler_map_base <- function(...) {
  .Deprecated("mysterycall_map_base", package = "mysterycall",
              msg = paste0("tyler_map_base() is deprecated. Use mysterycall_map_base() instead."))
  mysterycall_map_base(...)
}

#' @rdname tyler-deprecated
tyler_map_block_group <- function(...) {
  .Deprecated("mysterycall_map_block_group", package = "mysterycall",
              msg = paste0("tyler_map_block_group() is deprecated. Use mysterycall_map_block_group() instead."))
  mysterycall_map_block_group(...)
}

#' @rdname tyler-deprecated
tyler_map_leaflet <- function(...) {
  .Deprecated("mysterycall_map_leaflet", package = "mysterycall",
              msg = paste0("tyler_map_leaflet() is deprecated. Use mysterycall_map_leaflet() instead."))
  mysterycall_map_leaflet(...)
}

#' @rdname tyler-deprecated
tyler_map_physicians <- function(...) {
  .Deprecated("mysterycall_map_physicians", package = "mysterycall",
              msg = paste0("tyler_map_physicians() is deprecated. Use mysterycall_map_physicians() instead."))
  mysterycall_map_physicians(...)
}

#' @rdname tyler-deprecated
tyler_max_table <- function(...) {
  .Deprecated("mysterycall_max_table", package = "mysterycall",
              msg = paste0("tyler_max_table() is deprecated. Use mysterycall_max_table() instead."))
  mysterycall_max_table(...)
}

#' @rdname tyler-deprecated
tyler_min_table <- function(...) {
  .Deprecated("mysterycall_min_table", package = "mysterycall",
              msg = paste0("tyler_min_table() is deprecated. Use mysterycall_min_table() instead."))
  mysterycall_min_table(...)
}

#' @rdname tyler-deprecated
tyler_most_common_gender <- function(...) {
  .Deprecated("mysterycall_most_common_gender", package = "mysterycall",
              msg = paste0("tyler_most_common_gender() is deprecated. Use mysterycall_most_common_gender() instead."))
  mysterycall_most_common_gender(...)
}

#' @rdname tyler-deprecated
tyler_multi_complete <- function(...) {
  .Deprecated("mysterycall_multi_complete", package = "mysterycall",
              msg = paste0("tyler_multi_complete() is deprecated. Use mysterycall_multi_complete() instead."))
  mysterycall_multi_complete(...)
}

#' @rdname tyler-deprecated
tyler_multi_done <- function(...) {
  .Deprecated("mysterycall_multi_done", package = "mysterycall",
              msg = paste0("tyler_multi_done() is deprecated. Use mysterycall_multi_done() instead."))
  mysterycall_multi_done(...)
}

#' @rdname tyler-deprecated
tyler_multi_progress <- function(...) {
  .Deprecated("mysterycall_multi_progress", package = "mysterycall",
              msg = paste0("tyler_multi_progress() is deprecated. Use mysterycall_multi_progress() instead."))
  mysterycall_multi_progress(...)
}

#' @rdname tyler-deprecated
tyler_multi_step <- function(...) {
  .Deprecated("mysterycall_multi_step", package = "mysterycall",
              msg = paste0("tyler_multi_step() is deprecated. Use mysterycall_multi_step() instead."))
  mysterycall_multi_step(...)
}

#' @rdname tyler-deprecated
tyler_multi_update <- function(...) {
  .Deprecated("mysterycall_multi_update", package = "mysterycall",
              msg = paste0("tyler_multi_update() is deprecated. Use mysterycall_multi_update() instead."))
  mysterycall_multi_update(...)
}

#' @rdname tyler-deprecated
tyler_not_contacted_states <- function(...) {
  .Deprecated("mysterycall_not_contacted_states", package = "mysterycall",
              msg = paste0("tyler_not_contacted_states() is deprecated. Use mysterycall_not_contacted_states() instead."))
  mysterycall_not_contacted_states(...)
}

#' @rdname tyler-deprecated
tyler_physician_age <- function(...) {
  .Deprecated("mysterycall_physician_age", package = "mysterycall",
              msg = paste0("tyler_physician_age() is deprecated. Use mysterycall_physician_age() instead."))
  mysterycall_physician_age(...)
}

#' @rdname tyler-deprecated
tyler_plot_census_age <- function(...) {
  .Deprecated("mysterycall_plot_census_age", package = "mysterycall",
              msg = paste0("tyler_plot_census_age() is deprecated. Use mysterycall_plot_census_age() instead."))
  mysterycall_plot_census_age(...)
}

#' @rdname tyler-deprecated
tyler_plot_density <- function(...) {
  .Deprecated("mysterycall_plot_density", package = "mysterycall",
              msg = paste0("tyler_plot_density() is deprecated. Use mysterycall_plot_density() instead."))
  mysterycall_plot_density(...)
}

#' @rdname tyler-deprecated
tyler_plot_emmeans <- function(...) {
  .Deprecated("mysterycall_plot_emmeans", package = "mysterycall",
              msg = paste0("tyler_plot_emmeans() is deprecated. Use mysterycall_plot_emmeans() instead."))
  mysterycall_plot_emmeans(...)
}

#' @rdname tyler-deprecated
tyler_plot_interaction <- function(...) {
  .Deprecated("mysterycall_plot_interaction", package = "mysterycall",
              msg = paste0("tyler_plot_interaction() is deprecated. Use mysterycall_plot_interaction() instead."))
  mysterycall_plot_interaction(...)
}

#' @rdname tyler-deprecated
tyler_plot_isochrones <- function(...) {
  .Deprecated("mysterycall_plot_isochrones", package = "mysterycall",
              msg = paste0("tyler_plot_isochrones() is deprecated. Use mysterycall_plot_isochrones() instead."))
  mysterycall_plot_isochrones(...)
}

#' @rdname tyler-deprecated
tyler_plot_line <- function(...) {
  .Deprecated("mysterycall_plot_line", package = "mysterycall",
              msg = paste0("tyler_plot_line() is deprecated. Use mysterycall_plot_line() instead."))
  mysterycall_plot_line(...)
}

#' @rdname tyler-deprecated
tyler_plot_scatter <- function(...) {
  .Deprecated("mysterycall_plot_scatter", package = "mysterycall",
              msg = paste0("tyler_plot_scatter() is deprecated. Use mysterycall_plot_scatter() instead."))
  mysterycall_plot_scatter(...)
}

#' @rdname tyler-deprecated
tyler_preflight_check <- function(...) {
  .Deprecated("mysterycall_preflight_check", package = "mysterycall",
              msg = paste0("tyler_preflight_check() is deprecated. Use mysterycall_preflight_check() instead."))
  mysterycall_preflight_check(...)
}

#' @rdname tyler-deprecated
tyler_print_dashboard <- function(...) {
  .Deprecated("mysterycall_print_dashboard", package = "mysterycall",
              msg = paste0("tyler_print_dashboard() is deprecated. Use mysterycall_print_dashboard() instead."))
  mysterycall_print_dashboard(...)
}

#' @rdname tyler-deprecated
tyler_progress_bar <- function(...) {
  .Deprecated("mysterycall_progress_bar", package = "mysterycall",
              msg = paste0("tyler_progress_bar() is deprecated. Use mysterycall_progress_bar() instead."))
  mysterycall_progress_bar(...)
}

#' @rdname tyler-deprecated
tyler_progress_callback <- function(...) {
  .Deprecated("mysterycall_progress_callback", package = "mysterycall",
              msg = paste0("tyler_progress_callback() is deprecated. Use mysterycall_progress_callback() instead."))
  mysterycall_progress_callback(...)
}

#' @rdname tyler-deprecated
tyler_progress_done <- function(...) {
  .Deprecated("mysterycall_progress_done", package = "mysterycall",
              msg = paste0("tyler_progress_done() is deprecated. Use mysterycall_progress_done() instead."))
  mysterycall_progress_done(...)
}

#' @rdname tyler-deprecated
tyler_progress_fail <- function(...) {
  .Deprecated("mysterycall_progress_fail", package = "mysterycall",
              msg = paste0("tyler_progress_fail() is deprecated. Use mysterycall_progress_fail() instead."))
  mysterycall_progress_fail(...)
}

#' @rdname tyler-deprecated
tyler_progress_finish <- function(...) {
  .Deprecated("mysterycall_progress_finish", package = "mysterycall",
              msg = paste0("tyler_progress_finish() is deprecated. Use mysterycall_progress_finish() instead."))
  mysterycall_progress_finish(...)
}

#' @rdname tyler-deprecated
tyler_progress_map <- function(...) {
  .Deprecated("mysterycall_progress_map", package = "mysterycall",
              msg = paste0("tyler_progress_map() is deprecated. Use mysterycall_progress_map() instead."))
  mysterycall_progress_map(...)
}

#' @rdname tyler-deprecated
tyler_progress_start <- function(...) {
  .Deprecated("mysterycall_progress_start", package = "mysterycall",
              msg = paste0("tyler_progress_start() is deprecated. Use mysterycall_progress_start() instead."))
  mysterycall_progress_start(...)
}

#' @rdname tyler-deprecated
tyler_progress_summary <- function(...) {
  .Deprecated("mysterycall_progress_summary", package = "mysterycall",
              msg = paste0("tyler_progress_summary() is deprecated. Use mysterycall_progress_summary() instead."))
  mysterycall_progress_summary(...)
}

#' @rdname tyler-deprecated
tyler_progress_tracker <- function(...) {
  .Deprecated("mysterycall_progress_tracker", package = "mysterycall",
              msg = paste0("tyler_progress_tracker() is deprecated. Use mysterycall_progress_tracker() instead."))
  mysterycall_progress_tracker(...)
}

#' @rdname tyler-deprecated
tyler_progress_update <- function(...) {
  .Deprecated("mysterycall_progress_update", package = "mysterycall",
              msg = paste0("tyler_progress_update() is deprecated. Use mysterycall_progress_update() instead."))
  mysterycall_progress_update(...)
}

#' @rdname tyler-deprecated
tyler_quality_tier <- function(...) {
  .Deprecated("mysterycall_quality_tier", package = "mysterycall",
              msg = paste0("tyler_quality_tier() is deprecated. Use mysterycall_quality_tier() instead."))
  mysterycall_quality_tier(...)
}

#' @rdname tyler-deprecated
tyler_remove_constants <- function(...) {
  .Deprecated("mysterycall_remove_constants", package = "mysterycall",
              msg = paste0("tyler_remove_constants() is deprecated. Use mysterycall_remove_constants() instead."))
  mysterycall_remove_constants(...)
}

#' @rdname tyler-deprecated
tyler_remove_near_zero <- function(...) {
  .Deprecated("mysterycall_remove_near_zero", package = "mysterycall",
              msg = paste0("tyler_remove_near_zero() is deprecated. Use mysterycall_remove_near_zero() instead."))
  mysterycall_remove_near_zero(...)
}

#' @rdname tyler-deprecated
tyler_rename_columns <- function(...) {
  .Deprecated("mysterycall_rename_columns", package = "mysterycall",
              msg = paste0("tyler_rename_columns() is deprecated. Use mysterycall_rename_columns() instead."))
  mysterycall_rename_columns(...)
}

#' @rdname tyler-deprecated
tyler_resolve_path <- function(...) {
  .Deprecated("mysterycall_resolve_path", package = "mysterycall",
              msg = paste0("tyler_resolve_path() is deprecated. Use mysterycall_resolve_path() instead."))
  mysterycall_resolve_path(...)
}

#' @rdname tyler-deprecated
tyler_run_workflow <- function(...) {
  .Deprecated("mysterycall_run_workflow", package = "mysterycall",
              msg = paste0("tyler_run_workflow() is deprecated. Use mysterycall_run_workflow() instead."))
  mysterycall_run_workflow(...)
}

#' @rdname tyler-deprecated
tyler_run_workflow_logged <- function(...) {
  .Deprecated("mysterycall_run_workflow_logged", package = "mysterycall",
              msg = paste0("tyler_run_workflow_logged() is deprecated. Use mysterycall_run_workflow_logged() instead."))
  mysterycall_run_workflow_logged(...)
}

#' @rdname tyler-deprecated
tyler_save_quality_table <- function(...) {
  .Deprecated("mysterycall_save_quality_table", package = "mysterycall",
              msg = paste0("tyler_save_quality_table() is deprecated. Use mysterycall_save_quality_table() instead."))
  mysterycall_save_quality_table(...)
}

#' @rdname tyler-deprecated
tyler_scan_for_limits <- function(...) {
  .Deprecated("mysterycall_scan_for_limits", package = "mysterycall",
              msg = paste0("tyler_scan_for_limits() is deprecated. Use mysterycall_scan_for_limits() instead."))
  mysterycall_scan_for_limits(...)
}

#' @rdname tyler-deprecated
tyler_search_and_process_npi <- function(...) {
  .Deprecated("mysterycall_search_and_process_npi", package = "mysterycall",
              msg = paste0("tyler_search_and_process_npi() is deprecated. Use mysterycall_search_and_process_npi() instead."))
  mysterycall_search_and_process_npi(...)
}

#' @rdname tyler-deprecated
tyler_search_taxonomy <- function(...) {
  .Deprecated("mysterycall_search_taxonomy", package = "mysterycall",
              msg = paste0("tyler_search_taxonomy() is deprecated. Use mysterycall_search_taxonomy() instead."))
  mysterycall_search_taxonomy(...)
}

#' @rdname tyler-deprecated
tyler_spinner_start <- function(...) {
  .Deprecated("mysterycall_spinner_start", package = "mysterycall",
              msg = paste0("tyler_spinner_start() is deprecated. Use mysterycall_spinner_start() instead."))
  mysterycall_spinner_start(...)
}

#' @rdname tyler-deprecated
tyler_spinner_stop <- function(...) {
  .Deprecated("mysterycall_spinner_stop", package = "mysterycall",
              msg = paste0("tyler_spinner_stop() is deprecated. Use mysterycall_spinner_stop() instead."))
  mysterycall_spinner_stop(...)
}

#' @rdname tyler-deprecated
tyler_split_and_save <- function(...) {
  .Deprecated("mysterycall_split_and_save", package = "mysterycall",
              msg = paste0("tyler_split_and_save() is deprecated. Use mysterycall_split_and_save() instead."))
  mysterycall_split_and_save(...)
}

#' @rdname tyler-deprecated
tyler_standard_labels <- function(...) {
  .Deprecated("mysterycall_standard_labels", package = "mysterycall",
              msg = paste0("tyler_standard_labels() is deprecated. Use mysterycall_standard_labels() instead."))
  mysterycall_standard_labels(...)
}

#' @rdname tyler-deprecated
tyler_standard_palette <- function(...) {
  .Deprecated("mysterycall_standard_palette", package = "mysterycall",
              msg = paste0("tyler_standard_palette() is deprecated. Use mysterycall_standard_palette() instead."))
  mysterycall_standard_palette(...)
}

#' @rdname tyler-deprecated
tyler_summarize_census <- function(...) {
  .Deprecated("mysterycall_summarize_census", package = "mysterycall",
              msg = paste0("tyler_summarize_census() is deprecated. Use mysterycall_summarize_census() instead."))
  mysterycall_summarize_census(...)
}

#' @rdname tyler-deprecated
tyler_table_overall <- function(...) {
  .Deprecated("mysterycall_table_overall", package = "mysterycall",
              msg = paste0("tyler_table_overall() is deprecated. Use mysterycall_table_overall() instead."))
  mysterycall_table_overall(...)
}

#' @rdname tyler-deprecated
tyler_table_percentages <- function(...) {
  .Deprecated("mysterycall_table_percentages", package = "mysterycall",
              msg = paste0("tyler_table_percentages() is deprecated. Use mysterycall_table_percentages() instead."))
  mysterycall_table_percentages(...)
}

#' @rdname tyler-deprecated
tyler_table_proportion <- function(...) {
  .Deprecated("mysterycall_table_proportion", package = "mysterycall",
              msg = paste0("tyler_table_proportion() is deprecated. Use mysterycall_table_proportion() instead."))
  mysterycall_table_proportion(...)
}

#' @rdname tyler-deprecated
tyler_use_quiet_logging <- function(...) {
  .Deprecated("mysterycall_use_quiet_logging", package = "mysterycall",
              msg = paste0("tyler_use_quiet_logging() is deprecated. Use mysterycall_use_quiet_logging() instead."))
  mysterycall_use_quiet_logging(...)
}

#' @rdname tyler-deprecated
tyler_validate_npi <- function(...) {
  .Deprecated("mysterycall_validate_npi", package = "mysterycall",
              msg = paste0("tyler_validate_npi() is deprecated. Use mysterycall_validate_npi() instead."))
  mysterycall_validate_npi(...)
}

#' @rdname tyler-deprecated
tyler_workflow_end <- function(...) {
  .Deprecated("mysterycall_workflow_end", package = "mysterycall",
              msg = paste0("tyler_workflow_end() is deprecated. Use mysterycall_workflow_end() instead."))
  mysterycall_workflow_end(...)
}

#' @rdname tyler-deprecated
tyler_workflow_start <- function(...) {
  .Deprecated("mysterycall_workflow_start", package = "mysterycall",
              msg = paste0("tyler_workflow_start() is deprecated. Use mysterycall_workflow_start() instead."))
  mysterycall_workflow_start(...)
}

#' @rdname tyler-deprecated
tyler_write_arsenal_table <- function(...) {
  .Deprecated("mysterycall_write_arsenal_table", package = "mysterycall",
              msg = paste0("tyler_write_arsenal_table() is deprecated. Use mysterycall_write_arsenal_table() instead."))
  mysterycall_write_arsenal_table(...)
}

#' @rdname tyler-deprecated
tyler_write_table_pdf <- function(...) {
  .Deprecated("mysterycall_write_table_pdf", package = "mysterycall",
              msg = paste0("tyler_write_table_pdf() is deprecated. Use mysterycall_write_table_pdf() instead."))
  mysterycall_write_table_pdf(...)
}
