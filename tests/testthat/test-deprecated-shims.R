# Smoke tests for deprecated function shims. Each shim emits a deprecation
# warning via .Deprecated() and forwards to its replacement. We only assert
# the warning fires; the forwarded call may error from missing args, which we
# catch — covr still records both lines as executed.

deprecated_fns <- c(
  "arsenal_tables_write2word",
  "calculate_intersection_overlap_and_save",
  "check_normality",
  "clean_phase_1_results",
  "clean_phase_2_data",
  "create_and_plot_interaction",
  "create_density_plot",
  "create_formula",
  "create_individual_isochrone_plots",
  "create_isochrones",
  "create_isochrones_for_dataframe",
  "create_line_plot",
  "create_scatter_plot",
  "download_large_file",
  "format_pct",
  "genderize_physicians",
  "geocode_unique_addresses",
  "get_census_data",
  "hrr",
  "hrr_generate_maps",
  "map_create_acog_districts_sf",
  "map_create_base",
  "map_create_block_group_overlap",
  "map_create_leaflet_base",
  "map_create_physician_dot",
  "max_table",
  "min_table",
  "most_common_gender_training_academic",
  "physician_age",
  "plot_and_save_emmeans",
  "plot_census_age_distribution",
  "remove_constant_vars",
  "remove_near_zero_var",
  "rename_columns_by_substring",
  "retrieve_clinician_data",
  "run_mystery_caller_workflow",
  "run_mystery_caller_workflow_with_logging",
  "save_quality_check_table",
  "search_and_process_npi",
  "search_by_taxonomy",
  "split_and_save",
  "states_where_physicians_were_NOT_contacted",
  "summarize_census_data",
  "table_calculate_percentages",
  "table_calculate_proportion",
  "table_generate_overall",
  "table_write_pdf",
  "validate_and_remove_invalid_npi",
  "search_npi",
  "test_and_process_isochrones",
  "process_and_save_isochrones",
  "progress_tracker",
  "progress_tracker_start",
  "progress_tracker_finish",
  "progress_tracker_fail",
  "progress_tracker_update",
  "progress_tracker_summary",
  "tyler_assess_data_quality",
  "tyler_calculate_overlap",
  "tyler_check_api_response",
  "tyler_check_data_completeness",
  "tyler_check_dependencies",
  "tyler_check_no_data_loss",
  "tyler_check_no_limits",
  "tyler_check_normality",
  "tyler_clean_phase1",
  "tyler_clean_phase2",
  "tyler_clear_isochrone_cache",
  "tyler_create_formula",
  "tyler_create_isochrones",
  "tyler_download_file",
  "tyler_estimate_resources",
  "tyler_export_with_backup",
  "tyler_format_duration",
  "tyler_format_pct",
  "tyler_genderize",
  "tyler_geocode",
  "tyler_get_census_data",
  "tyler_get_clinician_data",
  "tyler_hrr",
  "tyler_hrr_maps",
  "tyler_isochrones_for_df",
  "tyler_log_cache_hit",
  "tyler_log_error",
  "tyler_log_info",
  "tyler_log_progress",
  "tyler_log_save",
  "tyler_log_step",
  "tyler_log_step_complete",
  "tyler_log_success",
  "tyler_log_warning",
  "tyler_map_acog_districts",
  "tyler_map_base",
  "tyler_map_block_group",
  "tyler_map_leaflet",
  "tyler_map_physicians",
  "tyler_max_table",
  "tyler_min_table",
  "tyler_most_common_gender",
  "tyler_multi_complete",
  "tyler_multi_done",
  "tyler_multi_progress",
  "tyler_multi_step",
  "tyler_multi_update",
  "tyler_not_contacted_states",
  "tyler_physician_age",
  "tyler_plot_census_age",
  "tyler_plot_density",
  "tyler_plot_emmeans",
  "tyler_plot_interaction",
  "tyler_plot_isochrones",
  "tyler_plot_line",
  "tyler_plot_scatter",
  "tyler_preflight_check",
  "tyler_print_dashboard",
  "tyler_progress_bar",
  "tyler_progress_callback",
  "tyler_progress_done",
  "tyler_progress_fail",
  "tyler_progress_finish",
  "tyler_progress_map",
  "tyler_progress_start",
  "tyler_progress_summary",
  "tyler_progress_tracker",
  "tyler_progress_update",
  "tyler_quality_tier",
  "tyler_remove_constants",
  "tyler_remove_near_zero",
  "tyler_rename_columns",
  "tyler_resolve_path",
  "tyler_run_workflow",
  "tyler_run_workflow_logged",
  "tyler_save_quality_table",
  "tyler_scan_for_limits",
  "tyler_search_and_process_npi",
  "tyler_search_taxonomy",
  "tyler_spinner_start",
  "tyler_spinner_stop",
  "tyler_split_and_save",
  "tyler_standard_labels",
  "tyler_standard_palette",
  "tyler_summarize_census",
  "tyler_table_overall",
  "tyler_table_percentages",
  "tyler_table_proportion",
  "tyler_use_quiet_logging",
  "tyler_validate_npi",
  "tyler_workflow_end",
  "tyler_workflow_start",
  "tyler_write_arsenal_table",
  "tyler_write_table_pdf"
)

fire_shim <- function(name) {
  fn <- tryCatch(getFromNamespace(name, "mysterycall"), error = function(e) NULL)
  if (is.null(fn)) return(invisible(NULL))
  # Trap downstream errors from forwarded calls so we only assert the deprecation warning.
  suppressMessages(
    tryCatch(
      withCallingHandlers(
        fn(),
        warning = function(w) {
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) NULL
    )
  )
}

# A deprecated shim either (a) emits a .Deprecated() warning and forwards, or
# (b) stops outright when the functionality has moved to the mysterymaps
# package (these wrappers were converted from warn-and-delegate to stop()).
# Accept either signal.
test_that("all deprecated shims warn or stop with a migration message", {
  for (name in deprecated_fns) {
    fn <- tryCatch(getFromNamespace(name, "mysterycall"), error = function(e) NULL)
    if (is.null(fn)) next

    warned <- FALSE
    stop_msg <- NULL
    withCallingHandlers(
      tryCatch(
        suppressMessages(fn()),
        error = function(e) stop_msg <<- conditionMessage(e)
      ),
      warning = function(w) {
        if (grepl("deprecated|moved", conditionMessage(w), ignore.case = TRUE)) {
          warned <<- TRUE
        }
        invokeRestart("muffleWarning")
      }
    )

    stopped_migration <- !is.null(stop_msg) &&
      grepl("deprecated|moved to the mysterymaps package",
            stop_msg, ignore.case = TRUE)

    expect_true(warned || stopped_migration, info = name)
  }
})
