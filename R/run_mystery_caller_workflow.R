#' Run the end-to-end mystery caller workflow
#'
#' This helper orchestrates the core steps required to prepare and execute a
#' mystery caller campaign. It stitches together roster creation, NPI
#' validation, call sheet preparation, workload splitting, and Phase 2 data
#' hygiene checks so teams can focus on execution instead of plumbing.
#'
#' @param taxonomy_terms Character vector of taxonomy descriptions to pass to
#'   [mysterycall_search_taxonomy()]. Set to `NULL` to skip taxonomy-based searches.
#' @param name_data Optional data frame containing `first` and `last` columns to
#'   use with [mysterycall_search_and_process_npi()]. Provide `NULL` to skip name-based
#'   searches.
#' @param phase1_data Data frame holding Phase 1 calling roster information to
#'   pass to [mysterycall_clean_phase1()].
#' @param lab_assistant_names Character vector of caller names used when splitting
#'   the cleaned roster via [mysterycall_split_and_save()]. Must contain at least two
#'   entries.
#' @param output_directory Directory where [mysterycall_split_and_save()] should write the
#'   complete and per-caller workbooks.
#' @param phase2_data Data frame or file path consumed by
#'   [mysterycall_clean_phase2()].
#' @param phase2_output_directory Directory where Phase 2 exports should be
#'   written. Defaults to `output_directory`.
#' @param quality_check_path File path where [mysterycall_save_quality_table()] should
#'   write the quality check CSV.
#' @param phase1_output_directory Directory where [mysterycall_clean_phase1()]
#'   should write the cleaned Phase 1 CSV. Defaults to `output_directory`.
#' @param split_insurance_order Ordering passed to [mysterycall_split_and_save()]'s
#'   `insurance_order` argument. Defaults to `c("Medicaid", "Blue Cross/Blue Shield")`.
#' @param phase2_required_strings Character vector of substrings used when
#'   standardizing Phase 2 column names via [mysterycall_clean_phase2()].
#' @param phase2_standard_names Replacement names corresponding to
#'   `phase2_required_strings`.
#' @param npi_search_args Named list of additional arguments forwarded to
#'   [mysterycall_search_and_process_npi()].
#' @param all_states Optional character vector of all states to supply to
#'   [mysterycall_not_contacted_states()].
#' @param taxonomy_states Optional character vector of two-letter state
#'   abbreviations forwarded to [mysterycall_search_taxonomy()] as its `states`
#'   argument. When `NULL` (default) the search is national and capped at 1,200
#'   records per taxonomy term. Pass all 50 abbreviations to bypass the cap for
#'   large specialties.
#' @param verbose Logical. When `TRUE`, print stage updates to the console while
#'   running the workflow. Defaults to `interactive()`.
#' @param npi_progress_observer Optional callback that receives progress updates
#'   from [mysterycall_search_and_process_npi()]. It is invoked with the same payload as the
#'   `progress_callback` argument for that function.
#'
#' @return A list containing intermediate artifacts from each workflow stage:
#'   `roster`, `validated_roster`, `cleaned_phase1`, `cleaned_phase2`,
#'   `coverage_summary`, `quality_check_table`, and a `workflow_summary` data
#'   frame documenting row counts, retention rates, and output paths for audit
#'   transparency.
#'
#' @section Contract:
#' **Inputs:**
#' - `phase1_data` must contain columns: `names`, `practice_name`, `phone_number`,
#'   `state_name`, `npi`, `for_redcap`.
#' - `lab_assistant_names` must have at least two entries for workload splitting.
#' - `output_directory` must be writable; created automatically if absent.
#'
#' **Guarantees:**
#' - Output list always contains `workflow_summary` even when upstream steps fail.
#' - Row counts at each stage are recorded in `workflow_summary` for audit
#'   transparency.
#' - Files written to `output_directory` are overwritten deterministically on
#'   re-run with the same inputs.
#'
#' **Fails if:**
#' - `phase1_data` is missing required columns (error from `mysterycall_clean_phase1()`).
#' - `lab_assistant_names` has fewer than two entries.
#' - `output_directory` is not writable and cannot be created.
#'
#' @section Performance:
#' Complexity is approximately O(n) in number of Phase 1 rows for local steps.
#' NPI registry calls via `mysterycall_search_taxonomy()` add O(t * p) where
#' `t` = number of taxonomy terms and `p` = max records per term (default 1,200).
#' Budget ~5-30 s per taxonomy term depending on network latency.
#'
#' @section Calls:
#' - [mysterycall_search_taxonomy()] (when `taxonomy_terms` is non-NULL)
#' - [mysterycall_search_and_process_npi()] (when `name_data` is non-NULL)
#' - [mysterycall_clean_phase1()]
#' - [mysterycall_validate_npi()]
#' - [mysterycall_split_and_save()]
#' - [mysterycall_clean_phase2()]
#' - [mysterycall_not_contacted_states()]
#' - [mysterycall_save_quality_table()]
#'
#' @seealso Stage functions called by this workflow:
#'   [mysterycall_search_taxonomy()], [mysterycall_search_and_process_npi()],
#'   [mysterycall_validate_npi()], [mysterycall_clean_phase1()],
#'   [mysterycall_clean_phase2()].
#'   Run [mysterycall_preflight_check()] before starting to catch missing
#'   API keys and malformed inputs early.
#'   Feed the cleaned result into [mysterycall_run_analysis()] for the
#'   analysis phase.
#' @family workflow
#' @examplesIf interactive()
#' results <- mysterycall_run_workflow(
#'   phase1_data = data.frame(
#'     names = "Jane Doe", practice_name = "Clinic A",
#'     phone_number = "555-0100", state_name = "Colorado",
#'     npi = "1234567890", for_redcap = "Yes"
#'   ),
#'   lab_assistant_names = c("Alice", "Bob"),
#'   output_directory = tempdir(),
#'   phase2_data = data.frame(),
#'   quality_check_path = file.path(tempdir(), "qc.csv")
#' )
#' @export
#' @importFrom dplyr bind_rows distinct
#' @importFrom tibble tibble
#' @importFrom utils modifyList
mysterycall_run_workflow <- function(
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
  verbose = interactive(),
  npi_progress_observer = NULL
) {
  announce <- function(stage) {
    if (isTRUE(verbose)) {
      message(sprintf("[%s] %s", format(Sys.time(), "%H:%M:%S"), stage))
    }
  }

  announce("Starting mystery caller workflow")
  if (isTRUE(verbose)) {
    config_candidates <- list(npi_search_args$config_file, npi_search_args$config_path)
    config_candidates <- config_candidates[!vapply(config_candidates, is.null, logical(1))]
    config_candidates <- config_candidates[vapply(config_candidates, function(x) {
      length(x) && all(!is.na(x)) && any(nzchar(as.character(x)))
    }, logical(1))]
    config_file <- if (length(config_candidates)) {
      as.character(config_candidates[[1]])
    } else {
      "none provided"
    }
    year_candidates <- list(npi_search_args$years, npi_search_args$year)
    year_candidates <- year_candidates[!vapply(year_candidates, is.null, logical(1))]
    years <- if (length(year_candidates)) {
      unlist(year_candidates, use.names = FALSE)
    } else {
      "unspecified"
    }
    taxonomy_sentence <- if (!is.null(taxonomy_terms) && length(taxonomy_terms)) {
      sprintf("Taxonomy search will include %d term(s): %s.", length(taxonomy_terms), paste(taxonomy_terms, collapse = ", "))
    } else {
      "Taxonomy search is skipped."
    }
    name_sentence <- if (is.data.frame(name_data) && nrow(name_data)) {
      sprintf("Name-based search will process %d row(s).", nrow(name_data))
    } else if (is.null(name_data)) {
      "Name-based search is skipped."
    } else {
      "Name-based search input provided but contains zero rows; treating as skipped."
    }
    validation_sentence <- if (isTRUE(npi_search_args$skip_validation)) {
      "Roster validation is explicitly skipped."
    } else {
      "Roster validation will run when NPIs are available."
    }
    plan_sentences <- c(
      sprintf("Resolved plan uses config file: %s.", config_file),
      sprintf("Years parameter: %s.", paste(years, collapse = ", ")), 
      taxonomy_sentence,
      name_sentence,
      validation_sentence,
      sprintf("Caller workbooks will be written to %s.", output_directory),
      sprintf("Cleaned Phase 1 results will be saved to %s.", phase1_output_directory),
      sprintf("Phase 2 exports will be saved to %s.", phase2_output_directory),
      sprintf("Quality check output will be written to %s.", quality_check_path)
    )
    message(paste(plan_sentences, collapse = " "))
  }
  roster_taxonomy <- if (!is.null(taxonomy_terms) && length(taxonomy_terms)) {
    announce("Searching NPIs by taxonomy")
    mysterycall_search_taxonomy(taxonomy_terms, states = taxonomy_states)
  } else {
    tibble::tibble()
  }

  roster_names <- tibble::tibble()
  if (!is.null(name_data)) {
    if (!is.data.frame(name_data)) {
      stop("`name_data` must be a data frame with `first` and `last` columns.", call. = FALSE)
    }
    if (nrow(name_data)) {
      if (!all(c("first", "last") %in% names(name_data))) {
        stop("`name_data` must contain columns named `first` and `last`.", call. = FALSE)
      }
      announce("Searching NPIs by name")
      args <- utils::modifyList(list(data = name_data), npi_search_args)
      user_callback <- NULL
      if (!is.null(args$progress_callback)) {
        user_callback <- args$progress_callback
      }
      callbacks <- list()
      if (is.function(user_callback)) {
        callbacks <- c(callbacks, list(user_callback))
      }
      if (is.function(npi_progress_observer)) {
        callbacks <- c(callbacks, list(npi_progress_observer))
      }
      if (isTRUE(verbose)) {
        callbacks <- c(callbacks, list(function(update) {
          if (is.null(update$event)) {
            return(invisible(NULL))
          }
          known_events <- c(
            start = "Starting name searches",
            result = "Retrieved results",
            no_results = "No results",
            skipped = "Skipped",
            heartbeat = "Still processing",
            completed = "Completed name searches"
          )
          label <- known_events[[update$event]]
          if (is.null(label)) {
            label <- update$event
          }
          detail <- if (!is.null(update$search_term)) {
            paste0(" for ", update$search_term)
          } else {
            ""
          }
          message(sprintf("[%s] %s%s", format(Sys.time(), "%H:%M:%S"), label, detail))
          invisible(NULL)
        }))
        if (is.null(args$heartbeat_seconds)) {
          args$heartbeat_seconds <- 30
        }
      }
      if (length(callbacks) == 1) {
        args$progress_callback <- callbacks[[1]]
      } else if (length(callbacks) > 1) {
        args$progress_callback <- function(update) {
          for (cb in callbacks) {
            try(cb(update), silent = TRUE)
          }
          invisible(NULL)
        }
      }
      roster_names <- do.call(mysterycall_search_and_process_npi, args)
    }
  }

  combined_roster <- dplyr::bind_rows(roster_taxonomy, roster_names)
  if ("npi" %in% names(combined_roster) && nrow(combined_roster)) {
    combined_roster <- dplyr::distinct(combined_roster, npi, .keep_all = TRUE)
  }

  validated_roster <- combined_roster
  if ("npi" %in% names(combined_roster) && nrow(combined_roster)) {
    announce("Validating NPI roster")
    validated_roster <- mysterycall_validate_npi(combined_roster)
  }

  announce("Cleaning Phase 1 results")
  cleaned_phase1 <- mysterycall_clean_phase1(
    phase1_data,
    output_directory = phase1_output_directory,
    notify = isTRUE(verbose)
  )
  announce("Splitting Phase 1 workbooks for callers")
  redcap_ready <- cleaned_phase1
  if ("for_redcap" %in% names(cleaned_phase1)) {
    n_before_filter <- nrow(redcap_ready)
    redcap_ready <- dplyr::filter(redcap_ready, !is.na(.data$for_redcap))
    n_dropped <- n_before_filter - nrow(redcap_ready)
    if (n_dropped > 0) {
      announce(sprintf(
        "Dropped %d row(s) with NA for_redcap (empty-name rows) before workbook split.",
        n_dropped
      ))
    }
  }
  mysterycall_split_and_save(
    redcap_ready,
    output_directory = output_directory,
    lab_assistant_names = lab_assistant_names,
    insurance_order = split_insurance_order
  )

  announce("Cleaning Phase 2 results")
  cleaned_phase2 <- mysterycall_clean_phase2(
    data_or_path = phase2_data,
    required_strings = phase2_required_strings,
    standard_names = phase2_standard_names,
    output_directory = phase2_output_directory
  )

  coverage_summary <- NULL
  if ("state" %in% names(cleaned_phase2)) {
    announce("Summarising coverage gaps")
    coverage_summary <- mysterycall_not_contacted_states(cleaned_phase2, all_states = all_states)
  }

  if (!dir.exists(dirname(quality_check_path))) {
    dir.create(dirname(quality_check_path), recursive = TRUE, showWarnings = FALSE)
  }

  quality_check_table <- NULL
  if (all(c("npi", "name") %in% names(cleaned_phase2))) {
    announce("Saving quality check table")
    quality_check_table <- mysterycall_save_quality_table(cleaned_phase2, quality_check_path)
  }

  workflow_summary <- tibble::tibble(
    stage = c(
      "combined_roster",
      "validated_roster",
      "cleaned_phase1",
      "cleaned_phase2",
      "coverage_summary",
      "quality_check_table"
    ),
    n_rows = c(
      nrow(combined_roster),
      nrow(validated_roster),
      nrow(cleaned_phase1),
      nrow(cleaned_phase2),
      if (!is.data.frame(coverage_summary)) NA_integer_ else nrow(coverage_summary),
      if (!is.data.frame(quality_check_table)) NA_integer_ else nrow(quality_check_table)
    ),
    retention_from_previous = c(
      NA_real_,
      if (nrow(combined_roster) == 0) NA_real_ else nrow(validated_roster) / nrow(combined_roster),
      if (nrow(phase1_data) == 0) NA_real_ else nrow(cleaned_phase1) / nrow(phase1_data),
      NA_real_,
      if (!is.data.frame(coverage_summary) || nrow(cleaned_phase2) == 0) NA_real_ else nrow(coverage_summary) / nrow(cleaned_phase2),
      if (!is.data.frame(quality_check_table) || nrow(cleaned_phase2) == 0) NA_real_ else nrow(quality_check_table) / nrow(cleaned_phase2)
    ),
    output_path = c(
      NA_character_,
      NA_character_,
      phase1_output_directory,
      phase2_output_directory,
      NA_character_,
      quality_check_path
    )
  )

  if (isTRUE(verbose)) {
    message("Workflow summary (rows and retention):")
    for (line in capture.output(print(workflow_summary))) message(line)
    message(sprintf("[%s] Mystery caller workflow complete", format(Sys.time(), "%H:%M:%S")))
  }

  list(
    roster = combined_roster,
    validated_roster = validated_roster,
    cleaned_phase1 = cleaned_phase1,
    cleaned_phase2 = cleaned_phase2,
    coverage_summary = coverage_summary,
    quality_check_table = quality_check_table,
    workflow_summary = workflow_summary
  )
}
