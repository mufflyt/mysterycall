#' Run the Full Mystery-Caller Analysis Pipeline
#'
#' A high-level orchestrator that chains quality-control checks,
#' deduplication, Medicaid column cleaning, demographic summaries, scenario
#' counts, insurance acceptance rates, wait-time analyses, Poisson regression,
#' and a sensitivity analysis into a single reproducible call.  Each step is
#' wrapped in error handling so that a failure in one step does not abort the
#' rest of the pipeline.
#'
#' @param data A data frame of mystery-caller records.
#' @param outcome_col Character scalar. Name of the numeric wait-time column.
#'   Default \code{"business_days_until_appointment"}.
#' @param insurance_col Character scalar. Insurance type column.
#'   Default \code{"insurance"}.
#' @param id_col Character scalar. Physician identifier column.
#'   Default \code{"id_number"}.
#' @param phone_col Character scalar. Physician phone column.
#'   Default \code{"phone"}.
#' @param exclusion_col Character scalar. Exclusion-reason column.
#'   Default \code{"reason_for_exclusions"}.
#' @param scenario_col Character scalar. Scenario label column.
#'   Default \code{"scenario"}.
#' @param medicaid_col Character scalar. Medicaid acceptance column.
#'   Default \code{"does_the_physician_accept_medicaid"}.
#' @param medicaid_label Character scalar. Value in \code{insurance_col}
#'   identifying Medicaid calls.  Default \code{"Medicaid"}.
#' @param bcbs_label Character scalar. Value in \code{insurance_col}
#'   identifying Blue Cross/Blue Shield calls.
#'   Default \code{"Blue Cross/Blue Shield"}.
#' @param contact_value Character scalar. Value in \code{exclusion_col}
#'   indicating a successful contact.  Default \code{"Able to contact"}.
#' @param output_dir Character scalar or \code{NA}.  Directory for CSV outputs.
#'   \code{NA} (default) skips all file writing.  Pass \code{NULL} to write to
#'   session temp directories via \code{\link{mysterycall_tempdir}}.
#' @param steps Character vector.  Which analysis steps to run.  Any subset of
#'   \code{c("qc","dedup","clean_medicaid","demographics","scenarios",
#'   "acceptance_rates","wait_times","poisson","sensitivity")}.
#'   Default runs all nine steps.
#' @param verbose Logical.  If \code{TRUE} (default), emit progress messages
#'   from the orchestrator.  Sub-function messages are unaffected.
#'
#' @return Invisibly returns a named list with one slot per pipeline step plus
#'   three bookkeeping elements:
#' \describe{
#'   \item{\code{qc}}{List with elements \code{repeat_physicians} (tibble from
#'     \code{\link{mysterycall_flag_repeat_physicians}}) and
#'     \code{exclusion_discrepancy} (tibble from
#'     \code{\link{mysterycall_flag_exclusion_discrepancy}}).  \code{NULL}
#'     when the step is not in \code{steps}.}
#'   \item{\code{dedup}}{Deduplicated tibble from
#'     \code{\link{mysterycall_dedup_by_insurance}}, or \code{NULL}.  When
#'     non-\code{NULL} the working data is updated for all subsequent steps.}
#'   \item{\code{clean_medicaid}}{Data frame with two new cleaned columns from
#'     \code{\link{mysterycall_clean_medicaid_col}}, or \code{NULL}.  When
#'     non-\code{NULL} the working data is updated for all subsequent steps.}
#'   \item{\code{demographics}}{Named list from
#'     \code{\link{mysterycall_sample_demographics}} (includes
#'     \code{summary_sentence}), or \code{NULL}.}
#'   \item{\code{scenarios}}{Named list from
#'     \code{\link{mysterycall_scenario_summary}} (includes \code{sentence}),
#'     or \code{NULL}.}
#'   \item{\code{acceptance_rates}}{Named list from
#'     \code{\link{mysterycall_insurance_acceptance_rates}} (includes
#'     \code{paragraph}), or \code{NULL}.}
#'   \item{\code{wait_times}}{Named list from
#'     \code{\link{mysterycall_insurance_wait_sentence}}, or \code{NULL}.}
#'   \item{\code{poisson}}{Object of class \code{mysterycall_simple_poisson}
#'     from \code{\link{mysterycall_simple_poisson}} (includes
#'     \code{irr_table}), or \code{NULL}.}
#'   \item{\code{sensitivity}}{Named list from
#'     \code{\link{mysterycall_sensitivity_both_insurance}} (includes
#'     \code{n_both}), or \code{NULL}.}
#'   \item{\code{data_deduped}}{Data frame.  The working data after any
#'     deduplication and Medicaid-column cleaning steps have been applied.}
#'   \item{\code{steps_run}}{Character vector of step names that were
#'     requested via the \code{steps} argument.}
#'   \item{\code{steps_errored}}{Character vector of step names that
#'     encountered an error or had missing required columns.}
#' }
#'
#' @seealso [mysterycall_run_workflow()] builds and cleans the call log this
#'   analyzes; together they form the collection -> analysis pipeline.
#' @family workflow helpers
#' @importFrom checkmate assert_data_frame assert_flag assert_character
#' @export
#'
#' @examples
#' \dontrun{
#' set.seed(1)
#' n <- 20
#' phones <- paste0("555-", sprintf("%04d", seq_len(n)))
#' df <- data.frame(
#'   id_number  = rep(paste0("NPI", seq_len(n)), 2L),
#'   phone      = rep(phones, 2L),
#'   insurance  = c(rep("Medicaid", n), rep("Blue Cross/Blue Shield", n)),
#'   reason_for_exclusions = sample(
#'     c("Able to contact", "Not available"), 2L * n, replace = TRUE
#'   ),
#'   business_days_until_appointment = rpois(2L * n, 14L),
#'   scenario   = sample(c("HIP scenario", "SHOULDER scenario"), 2L * n,
#'                       replace = TRUE),
#'   does_the_physician_accept_medicaid = sample(
#'     c("Yes they accept Medicaid", "No"), 2L * n, replace = TRUE
#'   ),
#'   state = sample(c("Colorado", "Texas", "Florida"), 2L * n, replace = TRUE),
#'   stringsAsFactors = FALSE
#' )
#' result <- mysterycall_run_analysis(df, output_dir = NA)
#' cat(result$demographics$summary_sentence)
#' print(result$poisson$irr_table)
#' }
mysterycall_run_analysis <- function(
    data,
    outcome_col    = "business_days_until_appointment",
    insurance_col  = "insurance",
    id_col         = "id_number",
    phone_col      = "phone",
    exclusion_col  = "reason_for_exclusions",
    scenario_col   = "scenario",
    medicaid_col   = "does_the_physician_accept_medicaid",
    medicaid_label = "Medicaid",
    bcbs_label     = "Blue Cross/Blue Shield",
    contact_value  = "Able to contact",
    output_dir     = NA,
    steps          = c("qc", "dedup", "clean_medicaid", "demographics",
                       "scenarios", "acceptance_rates", "wait_times",
                       "poisson", "sensitivity"),
    verbose        = TRUE
) {

  # -- Upfront validation -------------------------------------------------------
  checkmate::assert_data_frame(data, min.rows = 0)
  checkmate::assert_flag(verbose)
  checkmate::assert_character(steps)

  # -- Internal helpers ---------------------------------------------------------
  .msg <- function(x) if (isTRUE(verbose)) message(x)

  steps_errored <- character(0)

  .try <- function(label, expr) {
    tryCatch(
      expr,
      error = function(e) {
        message(sprintf(
          "[mysterycall_run_analysis] Step '%s' failed: %s",
          label, conditionMessage(e)
        ))
        steps_errored <<- c(steps_errored, label)
        NULL
      }
    )
  }

  # -- Initialise results -------------------------------------------------------
  current_data   <- data
  all_step_names <- c("qc", "dedup", "clean_medicaid", "demographics",
                      "scenarios", "acceptance_rates", "wait_times",
                      "poisson", "sensitivity")
  results        <- vector("list", length(all_step_names))
  names(results) <- all_step_names

  # -- Reconcile the phase-2 column-name contract -------------------------------
  # mysterycall_run_workflow() renames incoming columns to short "standard"
  # names (e.g. reason_for_exclusions -> exclusion_reasons). run_analysis()
  # defaults to the documented long names, so piping the workflow's output in
  # with the defaults used to silently skip the exclusion-dependent steps. Where
  # a documented column is absent but its workflow alias is present, resolve to
  # the alias so the two functions chain cleanly. A column the caller set
  # explicitly still wins whenever that column is actually in the data.
  .resolve <- function(primary, aliases) {
    resolved <- .mc_resolve_col(current_data, primary, aliases)
    if (!identical(resolved, primary)) {
      .msg(sprintf(
        "[run_analysis] column '%s' not found; using workflow alias '%s'.",
        primary, resolved
      ))
    }
    resolved
  }
  exclusion_col <- .resolve(exclusion_col, "exclusion_reasons")

  # ---------------------------------------------------------------------------
  # Step: qc
  # ---------------------------------------------------------------------------
  if ("qc" %in% steps) {
    .msg("[qc] Running quality-control checks ...")

    repeat_physicians <- NULL
    if (id_col %in% names(current_data)) {
      name_col_qc <- .mc_resolve_col(
        current_data, "physician_information", "physician_info"
      )
      if (!name_col_qc %in% names(current_data)) name_col_qc <- NULL
      repeat_physicians <- .try("qc", {
        mysterycall_flag_repeat_physicians(
          data       = current_data,
          id_col     = id_col,
          name_col   = name_col_qc,
          output_dir = output_dir
        )
      })
    } else {
      .msg(sprintf("[qc] repeat_physicians skipped: column '%s' not found.", id_col))
    }

    excl_discrepancy <- NULL
    if (exclusion_col %in% names(current_data) &&
        outcome_col   %in% names(current_data)) {
      excl_discrepancy <- .try("qc", {
        mysterycall_flag_exclusion_discrepancy(
          data          = current_data,
          days_col      = outcome_col,
          exclusion_col = exclusion_col,
          contact_value = contact_value,
          output_dir    = output_dir
        )
      })
    } else {
      .msg(sprintf(
        "[qc] exclusion_discrepancy skipped: column '%s' or '%s' not found.",
        exclusion_col, outcome_col
      ))
    }

    results[["qc"]] <- list(
      repeat_physicians     = repeat_physicians,
      exclusion_discrepancy = excl_discrepancy
    )
  }

  # ---------------------------------------------------------------------------
  # Step: dedup
  # ---------------------------------------------------------------------------
  if ("dedup" %in% steps) {
    .msg("[dedup] Deduplicating by insurance x phone ...")

    if (phone_col %in% names(current_data) &&
        insurance_col %in% names(current_data)) {
      deduped <- .try("dedup", {
        mysterycall_dedup_by_insurance(
          data          = current_data,
          phone_col     = phone_col,
          insurance_col = insurance_col,
          name_col      = NULL,
          output_dir    = output_dir
        )
      })
      if (!is.null(deduped)) current_data <- deduped
      results[["dedup"]] <- deduped
    } else {
      .msg(sprintf(
        "[dedup] Skipped: column '%s' or '%s' not found.",
        phone_col, insurance_col
      ))
      steps_errored <- c(steps_errored, "dedup")
    }
  }

  # ---------------------------------------------------------------------------
  # Step: clean_medicaid
  # ---------------------------------------------------------------------------
  if ("clean_medicaid" %in% steps) {
    .msg("[clean_medicaid] Cleaning Medicaid acceptance column ...")

    if (medicaid_col %in% names(current_data)) {
      cleaned <- .try("clean_medicaid", {
        mysterycall_clean_medicaid_col(
          data = current_data,
          col  = medicaid_col
        )
      })
      if (!is.null(cleaned)) current_data <- cleaned
      results[["clean_medicaid"]] <- cleaned
    } else {
      .msg(sprintf(
        "[clean_medicaid] Skipped: column '%s' not found.",
        medicaid_col
      ))
      steps_errored <- c(steps_errored, "clean_medicaid")
    }
  }

  # ---------------------------------------------------------------------------
  # Step: demographics
  # ---------------------------------------------------------------------------
  if ("demographics" %in% steps) {
    .msg("[demographics] Summarising sample demographics ...")

    if (id_col %in% names(current_data) &&
        insurance_col %in% names(current_data)) {
      results[["demographics"]] <- .try("demographics", {
        mysterycall_sample_demographics(
          data          = current_data,
          id_col        = id_col,
          insurance_col = insurance_col,
          phone_col     = if (phone_col %in% names(current_data)) phone_col else NULL,
          output_dir    = output_dir
        )
      })
    } else {
      .msg(sprintf(
        "[demographics] Skipped: column '%s' or '%s' not found.",
        id_col, insurance_col
      ))
      steps_errored <- c(steps_errored, "demographics")
    }
  }

  # ---------------------------------------------------------------------------
  # Step: scenarios
  # ---------------------------------------------------------------------------
  if ("scenarios" %in% steps) {
    .msg("[scenarios] Summarising scenario distribution ...")

    if (scenario_col %in% names(current_data)) {
      results[["scenarios"]] <- .try("scenarios", {
        mysterycall_scenario_summary(
          data         = current_data,
          scenario_col = scenario_col,
          output_dir   = output_dir
        )
      })
    } else {
      .msg(sprintf(
        "[scenarios] Skipped: column '%s' not found.",
        scenario_col
      ))
      steps_errored <- c(steps_errored, "scenarios")
    }
  }

  # ---------------------------------------------------------------------------
  # Step: acceptance_rates
  # ---------------------------------------------------------------------------
  if ("acceptance_rates" %in% steps) {
    .msg("[acceptance_rates] Calculating insurance acceptance rates ...")

    required_ar <- c(insurance_col, exclusion_col, outcome_col, phone_col)
    if (all(required_ar %in% names(current_data))) {
      results[["acceptance_rates"]] <- .try("acceptance_rates", {
        # Internal worker (not the deprecated public wrapper) so the workflow
        # reuses the exact same computation without emitting a deprecation
        # warning on every run. See R/insurance_acceptance_rates.R.
        .mc_insurance_acceptance_rates(
          data           = current_data,
          insurance_col  = insurance_col,
          exclusion_col  = exclusion_col,
          days_col       = outcome_col,
          phone_col      = phone_col,
          contact_value  = contact_value,
          medicaid_label = medicaid_label,
          bcbs_label     = bcbs_label,
          output_dir     = output_dir
        )
      })
    } else {
      missing_ar <- setdiff(required_ar, names(current_data))
      .msg(sprintf(
        "[acceptance_rates] Skipped: column(s) not found: %s.",
        paste(missing_ar, collapse = ", ")
      ))
      steps_errored <- c(steps_errored, "acceptance_rates")
    }
  }

  # ---------------------------------------------------------------------------
  # Step: wait_times
  # ---------------------------------------------------------------------------
  if ("wait_times" %in% steps) {
    .msg("[wait_times] Computing wait-time analysis ...")

    if (outcome_col %in% names(current_data) &&
        insurance_col %in% names(current_data)) {
      results[["wait_times"]] <- .try("wait_times", {
        mysterycall_insurance_wait_sentence(
          data           = current_data,
          outcome_col    = outcome_col,
          insurance_col  = insurance_col,
          medicaid_label = medicaid_label,
          bcbs_label     = bcbs_label
        )
      })
    } else {
      .msg(sprintf(
        "[wait_times] Skipped: column '%s' or '%s' not found.",
        outcome_col, insurance_col
      ))
      steps_errored <- c(steps_errored, "wait_times")
    }
  }

  # ---------------------------------------------------------------------------
  # Step: poisson
  # ---------------------------------------------------------------------------
  if ("poisson" %in% steps) {
    .msg("[poisson] Fitting simple Poisson regression ...")

    if (outcome_col %in% names(current_data) &&
        insurance_col %in% names(current_data)) {
      results[["poisson"]] <- .try("poisson", {
        mysterycall_simple_poisson(
          data      = current_data,
          outcome   = outcome_col,
          group     = insurance_col,
          reference = bcbs_label
        )
      })
    } else {
      .msg(sprintf(
        "[poisson] Skipped: column '%s' or '%s' not found.",
        outcome_col, insurance_col
      ))
      steps_errored <- c(steps_errored, "poisson")
    }
  }

  # ---------------------------------------------------------------------------
  # Step: sensitivity
  # ---------------------------------------------------------------------------
  if ("sensitivity" %in% steps) {
    .msg("[sensitivity] Running sensitivity analysis ...")

    required_sens <- c(phone_col, insurance_col, outcome_col)
    if (all(required_sens %in% names(current_data))) {
      results[["sensitivity"]] <- .try("sensitivity", {
        mysterycall_sensitivity_both_insurance(
          data           = current_data,
          phone_col      = phone_col,
          insurance_col  = insurance_col,
          outcome_col    = outcome_col,
          medicaid_label = tolower(trimws(medicaid_label)),
          bcbs_label     = tolower(trimws(bcbs_label)),
          output_dir     = output_dir
        )
      })
    } else {
      missing_sens <- setdiff(required_sens, names(current_data))
      .msg(sprintf(
        "[sensitivity] Skipped: column(s) not found: %s.",
        paste(missing_sens, collapse = ", ")
      ))
      steps_errored <- c(steps_errored, "sensitivity")
    }
  }

  # -- Assemble and return ------------------------------------------------------
  results[["data_deduped"]]  <- current_data
  results[["steps_run"]]     <- steps
  results[["steps_errored"]] <- unique(steps_errored)

  invisible(results)
}
