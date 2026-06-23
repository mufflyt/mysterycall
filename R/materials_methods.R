#' Generate a programmatic Materials & Methods section
#'
#' @name materials_methods
NULL

#' Generate a complete Materials & Methods section for a mystery-caller study
#'
#' Produces reviewer-ready prose addressing seven standard reviewer concerns
#' for audit-by-secret-shopper designs: caller standardization, call spacing,
#' appointment definition, physician selection, missing data, business vs.
#' calendar days, and IRB ethics. Numbers are drawn directly from `data` when
#' supplied so the text stays current as data collection continues.
#'
#' Caller names in `caller_col` are standardized to title case
#' (`tools::toTitleCase`) before any output is produced.
#' Inter-caller reliability is computed via [mysterycall_caller_reliability()]
#' when both `caller_col` and `outcome_col` are provided.
#'
#' @param data Optional data frame. When supplied, study statistics (N calls,
#'   % complete, N physicians, caller names) are derived from the data.
#' @param outcome_col Character scalar or `NULL`. Column containing the primary
#'   outcome (e.g. appointment wait days). Used to compute % complete and to
#'   run [mysterycall_caller_reliability()].
#' @param caller_col Character scalar or `NULL`. Column identifying which caller
#'   placed each call. Caller names are standardized to title case.
#' @param group_col Character scalar or `NULL`. Grouping variable (e.g.
#'   `"insurance"`). Reserved for future use.
#' @param physician_col Character scalar or `NULL`. Column identifying unique
#'   physicians. Used to count N physicians.
#' @param accepted_col Character scalar. Column for appointment-acceptance
#'   indicator. Default `"contact_office"`.
#' @param scenario_col Character scalar or `NULL`. Column for clinical scenario.
#' @param callers Character vector or `NULL`. Fallback caller names when
#'   `caller_col` is `NULL` or when supplementing data-derived names.
#' @param specialty Character scalar. Specialty label for physician-selection
#'   paragraph.
#' @param n_scenarios Integer. Number of clinical scenarios tested. Default `3L`.
#' @param scenario_names Character vector. Names of the clinical scenarios.
#' @param insurance_types Character vector. Insurance types tested.
#' @param ref_insurance Character scalar. Reference insurance type.
#' @param source_directory Character scalar. Physician directory URL/name.
#'   Default `"voicesforpfd.org"`.
#' @param sampling_method Character scalar. How physicians were sampled.
#'   Default `"random"`.
#' @param irb_institution Character scalar. Name of the approving IRB.
#' @param irb_number Character scalar. IRB protocol number. Default prompts for
#'   manual completion.
#' @param call_hours Character scalar. Hours during which calls were placed.
#' @param min_interval_hours Integer. Minimum hours between calls to the same
#'   office. Default `24L`.
#' @param caller_assignment Character scalar. How callers were assigned.
#' @param appointment_definition Character scalar. What constitutes an
#'   appointment for this study.
#' @param appointments_accepted Logical. Whether appointments were accepted.
#'   Default `FALSE`.
#' @param business_days_primary Logical. Whether business days are the primary
#'   outcome unit. Default `FALSE` (calendar days).
#' @param business_days_sensitivity Logical. Whether a business-days sensitivity
#'   analysis was run. Default `TRUE`.
#' @param data_platform Character scalar. Data capture platform used.
#' @param script_appendix Character scalar. Appendix label for the call script.
#' @param r_version Character scalar or `NULL`. R version string. Defaults to
#'   the running R version.
#' @param ... Reserved for future arguments.
#'
#' @return A list of class `mysterycall_materials_methods` with elements:
#' \describe{
#'   \item{`sections`}{Named list of seven character scalars, one per reviewer
#'     concern: `caller_standardization`, `call_spacing`,
#'     `appointment_definition`, `physician_selection`, `missing_data`,
#'     `business_days`, `irb`.}
#'   \item{`full_text`}{Character scalar. All seven paragraphs joined with
#'     `"\n\n"`.}
#'   \item{`stats`}{Named list of computed study statistics.}
#'   \item{`reliability`}{The `mysterycall_reliability` object from
#'     [mysterycall_caller_reliability()], or `NULL`.}
#'   \item{`callers_standardized`}{Character vector. Title-case caller names
#'     used in the text.}
#'   \item{`items_needing_input`}{Character vector. Placeholders that require
#'     manual completion before submission.}
#' }
#'
#' @family manuscript
#' @seealso [mysterycall_caller_reliability()], [mysterycall_business_days()],
#'   [mysterycall_missing_data_analysis()]
#' @export
#'
#' @examples
#' m <- mysterycall_materials_methods(
#'   callers    = c("Lizeth", "Merilyn", "Jessica"),
#'   irb_number = "COMIRB-2024-001"
#' )
#' print(m)
mysterycall_materials_methods <- function(
    data                      = NULL,
    outcome_col               = NULL,
    caller_col                = NULL,
    group_col                 = NULL,
    physician_col             = NULL,
    accepted_col              = "contact_office",
    scenario_col              = NULL,
    callers                   = NULL,
    specialty                 = "Female Pelvic Medicine and Reconstructive Surgery (FPMRS)",
    n_scenarios               = 3L,
    scenario_names            = c("pelvic organ prolapse", "stress urinary incontinence",
                                  "bladder pain/interstitial cystitis"),
    insurance_types           = c("Blue Cross Blue Shield (BCBS)", "Medicaid"),
    ref_insurance             = "BCBS",
    source_directory          = "voicesforpfd.org",
    sampling_method           = "random",
    irb_institution           = "Colorado Multiple Institutional Review Board (COMIRB)",
    irb_number                = "[COMIRB NUMBER REQUIRED]",
    call_hours                = "Monday through Friday, 9:00 am – 4:00 pm local time",
    min_interval_hours        = 24L,
    caller_assignment         = "rotated systematically across physicians and conditions",
    appointment_definition    = "first available appointment offered",
    appointments_accepted     = FALSE,
    business_days_primary     = FALSE,
    business_days_sensitivity = TRUE,
    data_platform             = "REDCap",
    script_appendix           = "Appendix A",
    r_version                 = NULL,
    ...
) {

  # ---- Step 1: standardize caller names -----------------------------------------
  if (!is.null(data) && !is.null(caller_col)) {
    if (!caller_col %in% names(data)) {
      warning("`caller_col` '", caller_col, "' not found in `data`; ignoring.",
              call. = FALSE)
      caller_col <- NULL
    } else {
      data[[caller_col]] <- tools::toTitleCase(tolower(trimws(data[[caller_col]])))
    }
  }

  caller_names_from_data <- if (!is.null(data) && !is.null(caller_col)) {
    sort(unique(na.omit(data[[caller_col]])))
  } else {
    character(0)
  }

  caller_names_supplied <- if (!is.null(callers)) {
    tools::toTitleCase(tolower(trimws(callers)))
  } else {
    character(0)
  }

  caller_names_used <- sort(unique(c(caller_names_from_data, caller_names_supplied)))

  # ---- Step 2: compute study statistics -----------------------------------------
  n_total_calls <- if (!is.null(data)) nrow(data) else NA_integer_

  n_complete <- if (!is.null(data) && !is.null(outcome_col)) {
    if (!outcome_col %in% names(data)) {
      warning("`outcome_col` '", outcome_col, "' not found in `data`; ignoring.",
              call. = FALSE)
      NA_integer_
    } else {
      sum(!is.na(data[[outcome_col]]))
    }
  } else {
    NA_integer_
  }

  pct_complete <- if (!is.na(n_complete) && !is.na(n_total_calls) && n_total_calls > 0L) {
    round(n_complete / n_total_calls * 100, 1)
  } else {
    NA_real_
  }

  n_physicians <- if (!is.null(data) && !is.null(physician_col)) {
    if (!physician_col %in% names(data)) {
      warning("`physician_col` '", physician_col, "' not found in `data`; ignoring.",
              call. = FALSE)
      NA_integer_
    } else {
      length(unique(na.omit(data[[physician_col]])))
    }
  } else {
    NA_integer_
  }

  n_callers <- if (length(caller_names_used) > 0L) {
    length(caller_names_used)
  } else if (!is.null(data) && !is.null(caller_col)) {
    length(unique(na.omit(data[[caller_col]])))
  } else {
    NA_integer_
  }

  # ---- Step 3: inter-caller reliability ------------------------------------------
  reliability <- NULL
  if (!is.null(data) && !is.null(caller_col) && !is.null(outcome_col) &&
      caller_col %in% names(data) && outcome_col %in% names(data)) {
    reliability <- tryCatch(
      mysterycall_caller_reliability(data, caller_col, outcome_col),
      error = function(e) {
        warning("mysterycall_caller_reliability() failed: ", conditionMessage(e),
                call. = FALSE)
        NULL
      }
    )
  }

  # ---- Step 4: R version ---------------------------------------------------------
  r_ver <- if (!is.null(r_version)) {
    as.character(r_version)
  } else {
    paste(R.version$major, R.version$minor, sep = ".")
  }

  # ---- Step 5: build section text ------------------------------------------------

  # Helper: format caller list as "A, B, and C"
  .format_names <- function(nms) {
    n <- length(nms)
    if (n == 0L) return("[CALLER NAMES REQUIRED]")
    if (n == 1L) return(nms)
    if (n == 2L) return(paste(nms, collapse = " and "))
    paste0(paste(nms[-n], collapse = ", "), ", and ", nms[n])
  }

  caller_list_str <- .format_names(caller_names_used)
  n_callers_word  <- switch(as.character(n_callers),
    "1" = "One", "2" = "Two", "3" = "Three", "4" = "Four",
    "5" = "Five", "6" = "Six", if (is.na(n_callers)) "[N]" else as.character(n_callers)
  )

  # -- Section 1: Caller Standardization --
  if (!is.null(reliability)) {
    stat_val  <- reliability$statistic
    type_str  <- switch(reliability$type,
      kappa             = "Cohen’s κ",
      icc               = "an intraclass correlation coefficient (ICC)",
      percent_agreement = "percent agreement",
      reliability$type
    )
    stat_str <- if (reliability$type == "percent_agreement") {
      sprintf("%.1f%%", stat_val)
    } else {
      sprintf("%.3f", stat_val)
    }
    lo_str   <- sprintf("%.3f", reliability$lower_ci)
    hi_str   <- sprintf("%.3f", reliability$upper_ci)
    interp_str <- if (!is.na(reliability$interpretation)) {
      paste0("; interpreted as ", reliability$interpretation, " agreement")
    } else {
      ""
    }
    reliability_sentence <- sprintf(
      "Inter-caller reliability was assessed using %s across %d matched call pairs (%s = %s, 95%% CI %s–%s%s).",
      type_str, reliability$n_pairs,
      if (reliability$type == "kappa") "κ" else if (reliability$type == "icc") "ICC" else "%",
      stat_str, lo_str, hi_str, interp_str
    )
  } else {
    reliability_sentence <- "[Inter-caller reliability results pending — run mysterycall_caller_reliability()]"
  }

  section1 <- sprintf(
    paste(
      "%s female research team members (%s) were trained as standardized callers",
      "prior to data collection. All callers used an identical verbatim call script",
      "(see %s); no improvisation was permitted. Callers identified themselves as",
      "prospective new patients, provided the scripted clinical complaint, stated their",
      "insurance type when asked, and requested the %s. Calls were placed during",
      "standard business hours (%s). %s"
    ),
    n_callers_word, caller_list_str, script_appendix,
    appointment_definition, call_hours, reliability_sentence
  )

  # -- Section 2: Call Spacing --
  section2 <- sprintf(
    paste(
      "To minimize scheduler recognition across repeated calls to the same practice,",
      "a minimum interval of %d hours elapsed between any two calls to the same",
      "physician’s office. Caller assignment was %s to prevent",
      "caller-by-condition confounding."
    ),
    as.integer(min_interval_hours), caller_assignment
  )

  # -- Section 3: Appointment Definition --
  outcome_unit <- if (business_days_primary) "business days" else "calendar days"
  section3 <- sprintf(
    paste(
      "The primary outcome was the number of %s from the date of the call to the",
      "date of the first available appointment offered. Callers recorded the",
      "appointment date offered but did not confirm or accept any appointment.",
      "Calls in which no appointment was offered were recorded as unsuccessful",
      "and excluded from wait-time analyses."
    ),
    outcome_unit
  )

  # -- Section 4: Physician Selection --
  n_phys_str <- if (!is.na(n_physicians)) {
    sprintf("A total of %d physicians were included", n_physicians)
  } else {
    "[N physicians — confirm from data]"
  }

  section4 <- sprintf(
    paste(
      "Eligible physicians were board-certified %s specialists identified through",
      "a %s sample of the patient-facing physician directory (%s). %s.",
      "Physicians were not contacted in advance and were unaware of their inclusion",
      "in the study."
    ),
    specialty, sampling_method, source_directory, n_phys_str
  )

  # -- Section 5: Missing Data --
  if (!is.na(n_complete) && !is.na(n_total_calls)) {
    pct_str       <- if (!is.na(pct_complete)) sprintf("%.1f%%", pct_complete) else "[%]"
    missing_stats <- sprintf(
      "%d of %d calls (%s) had a complete appointment date.",
      n_complete, n_total_calls, pct_str
    )
  } else {
    missing_stats <- "[N complete] of [N total] calls ([%]) had a complete appointment date."
  }

  section5 <- paste(
    missing_stats,
    "To evaluate whether calls with missing appointment dates differed systematically",
    "from those with complete data, physician and call characteristics were compared",
    "between groups (see Supplemental Table [X] for the missing data analysis)."
  )

  # -- Section 6: Business Days --
  primary_unit <- if (business_days_primary) "business days" else "calendar days"
  alt_unit     <- if (business_days_primary) "calendar days" else "business days"
  sensitivity_sentence <- if (business_days_sensitivity) {
    sprintf(
      "A sensitivity analysis using %s (excluding weekends and U.S. federal holidays) is reported in Supplemental Table [X].",
      alt_unit
    )
  } else {
    ""
  }

  section6 <- paste(
    sprintf(
      "Although %s are the preferred scheduling metric, %s were used as the primary unit because federal holiday calendars vary by state and institution.",
      alt_unit, primary_unit
    ),
    sensitivity_sentence
  )

  # -- Section 7: IRB --
  section7 <- sprintf(
    paste(
      "The study was approved by the %s (Protocol No. %s). Given that office staff",
      "were unaware they were being observed, the board granted a waiver of informed",
      "consent, classifying the study as minimal risk. No protected health information",
      "was collected, and no actual appointments were scheduled. The verbatim call",
      "script is reproduced in %s."
    ),
    irb_institution, irb_number, script_appendix
  )

  # ---- Step 6: full text ---------------------------------------------------------
  sections <- list(
    caller_standardization = section1,
    call_spacing           = section2,
    appointment_definition = section3,
    physician_selection    = section4,
    missing_data           = section5,
    business_days          = section6,
    irb                    = section7
  )
  full_text <- paste(unlist(sections), collapse = "\n\n")

  # ---- Step 7: items needing manual input ----------------------------------------
  items_manual <- character(0)
  if (grepl("\\[COMIRB NUMBER REQUIRED\\]", irb_number)) {
    items_manual <- c(items_manual, "IRB protocol number")
  }
  if (is.null(reliability)) {
    items_manual <- c(items_manual, "Inter-caller reliability results (provide caller_col and outcome_col)")
  }
  if (is.na(n_physicians)) {
    items_manual <- c(items_manual, "N physicians (provide physician_col)")
  }
  if (is.na(n_total_calls)) {
    items_manual <- c(items_manual, "N total calls (provide data)")
  }
  if (is.na(n_complete)) {
    items_manual <- c(items_manual, "N complete calls (provide outcome_col)")
  }
  if (length(caller_names_used) == 0L) {
    items_manual <- c(items_manual, "Caller names (provide callers= or caller_col)")
  }
  if (grepl("\\[N\\]", section1)) {
    items_manual <- c(items_manual, "Number of callers")
  }
  if (grepl("Supplemental Table \\[X\\]", section5)) {
    items_manual <- c(items_manual, "Supplemental table number for missing data analysis")
  }
  if (business_days_sensitivity && grepl("Supplemental Table \\[X\\]", section6)) {
    items_manual <- c(items_manual, "Supplemental table number for business-days sensitivity analysis")
  }

  structure(
    list(
      sections           = sections,
      full_text          = full_text,
      stats              = list(
        n_total_calls = n_total_calls,
        n_complete    = n_complete,
        pct_complete  = pct_complete,
        n_physicians  = n_physicians,
        n_callers     = n_callers,
        r_version     = r_ver
      ),
      reliability        = reliability,
      callers_standardized = caller_names_used,
      items_needing_input  = items_manual
    ),
    class = "mysterycall_materials_methods"
  )
}


#' Print method for mysterycall_materials_methods
#'
#' @param x A `mysterycall_materials_methods` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family manuscript
#' @export
print.mysterycall_materials_methods <- function(x, ...) {
  cat("=== Materials & Methods Section ===\n\n")
  for (nm in names(x$sections)) {
    cat(sprintf("-- %s --\n", gsub("_", " ", nm)))
    cat(strwrap(x$sections[[nm]], width = 80L), sep = "\n")
    cat("\n\n")
  }
  if (length(x$items_needing_input)) {
    cat("Items requiring manual input:\n")
    for (item in x$items_needing_input) {
      cat(sprintf("  [ ] %s\n", item))
    }
  }
  invisible(x)
}
