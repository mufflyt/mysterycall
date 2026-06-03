#' Run the mystery caller workflow with structured logging
#'
#' A thin wrapper around [mysterycall_run_workflow()] that initialises the
#' `mysterycall` logging infrastructure before the run and tears it down afterward.
#' All substantive workflow logic lives in the underlying function; any bug
#' fixed there is automatically inherited here.
#'
#' @inheritParams mysterycall_run_workflow
#' @param log_file Optional path to write a plain-text log file. When `NULL`
#'   (default), a timestamped file is created inside `output_directory`.
#' @param skip_preflight Logical. When `TRUE`, skip the preflight validation
#'   step. Defaults to `FALSE`.
#'
#' @return Invisibly, the named list returned by [mysterycall_run_workflow()].
#'   Key elements include `cleaned_phase1` and `cleaned_phase2` (data frames),
#'   `excluded_records` (data frame), and `workflow_summary` (stage-level
#'   counts). See [mysterycall_run_workflow()] for the complete structure.
#'
#' @examplesIf interactive()
#' results <- mysterycall_run_workflow_logged(
#'   phase1_data = phase1,
#'   phase2_data = phase2,
#'   lab_assistant_names = c("Alice", "Bob"),
#'   output_directory = "output/",
#'   quality_check_path = "output/qc.csv",
#'   log_file = "output/run.log"
#' )
#'
#' @family workflow
#' @export
mysterycall_run_workflow_logged <- function(
  taxonomy_terms = NULL,
  name_data = NULL,
  phase1_data,
  lab_assistant_names,
  output_directory,
  phase2_data,
  phase2_output_directory = output_directory,
  quality_check_path,
  phase1_output_directory = output_directory,
  split_insurance_order = c("Medicaid", "Blue Cross/Blue Shield"),
  phase2_required_strings = c(
    "physician_information", "able_to_contact_office", "are_we_including",
    "reason_for_exclusions", "appointment_date", "number_of_transfers",
    "call_time", "hold_time", "notes", "person_completing",
    "state", "npi", "name"
  ),
  phase2_standard_names = c(
    "physician_info", "contact_office", "included_in_study",
    "exclusion_reasons", "appt_date", "transfer_count",
    "call_duration", "hold_duration", "notes", "completed_by",
    "state", "npi", "name"
  ),
  npi_search_args = list(),
  all_states = NULL,
  taxonomy_states = NULL,
  npi_progress_observer = NULL,
  log_file = NULL,
  skip_preflight = FALSE
) {
  dir.create(output_directory, showWarnings = FALSE, recursive = TRUE)

  if (is.null(log_file)) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    log_file <- file.path(output_directory, sprintf("workflow_log_%s.txt", timestamp))
  }

  mysterycall_workflow_start(
    workflow_name = "Mystery Caller Workflow",
    total_steps = 6,
    log_file = log_file
  )

  result <- tryCatch(
    mysterycall_run_workflow(
      taxonomy_terms = taxonomy_terms,
      name_data = name_data,
      phase1_data = phase1_data,
      lab_assistant_names = lab_assistant_names,
      output_directory = output_directory,
      phase2_data = phase2_data,
      phase2_output_directory = phase2_output_directory,
      quality_check_path = quality_check_path,
      phase1_output_directory = phase1_output_directory,
      split_insurance_order = split_insurance_order,
      phase2_required_strings = phase2_required_strings,
      phase2_standard_names = phase2_standard_names,
      npi_search_args = npi_search_args,
      all_states = all_states,
      taxonomy_states = taxonomy_states,
      verbose = TRUE,
      npi_progress_observer = npi_progress_observer
    ),
    error = function(e) {
      mysterycall_log_error("Workflow failed", cause = e$message, fix = "Check input data and parameters")
      mysterycall_workflow_end()
      stop(e)
    }
  )

  mysterycall_workflow_end(
    final_n = if (!is.null(result$cleaned_phase2)) nrow(result$cleaned_phase2) else NA_integer_,
    input_n  = nrow(phase1_data)
  )

  invisible(result)
}


#' Print a formatted summary dashboard
#'
#' Prints a Unicode-box-drawing summary table showing row counts at each stage
#' of the mystery caller workflow.
#'
#' @param results Named list of workflow results as returned by
#'   [mysterycall_run_workflow()].
#'
#' @return Invisible NULL.
#' @family workflow
#' @keywords internal
#' @examplesIf interactive()
#' results <- mysterycall_run_workflow_logged(phase1_data = my_data)
#' mysterycall_print_dashboard(results)
mysterycall_print_dashboard <- function(results) {
  message("")
  message("\u256d", strrep("\u2500", 58), "\u256e")
  message("\u2502", "   Mystery Caller Workflow Summary", strrep(" ", 23), "\u2502")
  message("\u2570", strrep("\u2500", 58), "\u256f")
  message("")

  if (!is.null(results$workflow_summary)) {
    summary <- results$workflow_summary
    for (i in seq_len(nrow(summary))) {
      message(sprintf("  %-20s %s rows", summary$stage[i], format(summary$n_rows[i], big.mark = ",")))
    }
    message("")
  }

  message(strrep("\u2500", 60))
  message("")
}
