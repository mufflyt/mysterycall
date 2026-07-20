#' Define one cross-field consistency rule
#'
#' A rule pairs a predicate with the metadata needed to triage the rows it
#' flags. It is the unit consumed by [mysterycall_check_consistency()].
#'
#' @param flag Short machine tag for the rule (e.g. `"ANSWER_CONFLICT"`).
#' @param description Human-readable statement of the contradiction.
#' @param action What the study team should do about it.
#' @param predicate A `function(data)` returning a logical vector with one entry
#'   per row of `data`; `TRUE` marks a row that *violates* the rule. `NA` is
#'   treated as "not flagged". A predicate that references a column absent from
#'   the data should return `FALSE` for every row (see
#'   [mysterycall_default_consistency_rules()] for the pattern) so a rule set can
#'   be applied to logs that lack some fields.
#' @param priority One of `"CRITICAL"`, `"HIGH"`, `"MEDIUM"`, `"LOW"`
#'   (default `"MEDIUM"`); controls sort order in the report.
#'
#' @return A list with class `"mysterycall_consistency_rule"`.
#' @seealso [mysterycall_check_consistency()],
#'   [mysterycall_default_consistency_rules()]
#' @examples
#' mysterycall_consistency_rule(
#'   flag = "WAIT_NO_OFFER",
#'   description = "A wait time is recorded but no appointment was offered",
#'   action = "Clear wait_days or correct appointment_offered",
#'   predicate = function(d) !is.na(d$wait_days) & d$offered == FALSE,
#'   priority = "HIGH"
#' )
#' @export
mysterycall_consistency_rule <- function(flag, description, action, predicate,
                                         priority = "MEDIUM") {
  checkmate::assert_string(flag)
  checkmate::assert_string(description)
  checkmate::assert_string(action)
  checkmate::assert_function(predicate)
  priority <- match.arg(priority, c("CRITICAL", "HIGH", "MEDIUM", "LOW"))
  structure(
    list(flag = flag, description = description, action = action,
         predicate = predicate, priority = priority),
    class = "mysterycall_consistency_rule"
  )
}

#' Apply a battery of consistency rules to a call log
#'
#' Runs a list of cross-field rules over a call log and returns a single,
#' priority-sorted worklist of every row that violates a rule — the general
#' form of the one-off `mysterycall_flag_*` checks. Each flagged row appears
#' once per rule it trips, tagged with the rule's flag, priority, description,
#' and recommended action, so the output can drive a data-cleaning pass or a
#' correction report.
#'
#' @param data A data frame (one row per call).
#' @param rules A list of [mysterycall_consistency_rule()] objects. Defaults to
#'   [mysterycall_default_consistency_rules()].
#' @param id_col Optional identifier column carried into the report so flagged
#'   rows can be traced back to the source record.
#' @param keep_cols Optional character vector of extra columns to include in the
#'   report for context.
#' @param output_dir,filename Optional. If both are non-`NA`, the worklist is
#'   written to `file.path(output_dir, filename)` as CSV.
#'
#' @return An object of class `"mysterycall_consistency_report"`: a list with
#'   `report` (a tibble of `row`, optional id/keep columns, `flag`, `priority`,
#'   `description`, `action`, sorted by priority then row), `summary` (per-flag
#'   counts), and `n_rules`. [as.data.frame()] returns the report.
#'
#' @examples
#' d <- data.frame(
#'   record_id           = 1:3,
#'   office_answered     = c(FALSE, TRUE, TRUE),
#'   appointment_date    = c("2026-02-01", NA, "2026-03-01"),
#'   taking_new_patients = c("Yes", "Yes", "Yes"),
#'   complete            = c("Complete", "Complete", "Complete"),
#'   call_date           = c("2026-01-01", "2026-01-02", NA),
#'   caller              = c("AB", NA, "CD")
#' )
#' mysterycall_check_consistency(d, id_col = "record_id")
#' @export
mysterycall_check_consistency <- function(
    data, rules = mysterycall_default_consistency_rules(),
    id_col = NULL, keep_cols = NULL, output_dir = NA, filename = NA) {

  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_list(rules, min.len = 1L)
  if (!is.null(id_col)) checkmate::assert_choice(id_col, names(data))
  if (!is.null(keep_cols)) checkmate::assert_subset(keep_cols, names(data))

  prio_levels <- c("CRITICAL", "HIGH", "MEDIUM", "LOW")
  pieces <- list()
  for (rule in rules) {
    if (!inherits(rule, "mysterycall_consistency_rule")) {
      stop("Every element of `rules` must be a mysterycall_consistency_rule().",
           call. = FALSE)
    }
    hit <- rule$predicate(data)
    if (!is.logical(hit) || length(hit) != nrow(data)) {
      stop(sprintf(paste0("Rule '%s' predicate must return a logical vector of ",
                          "length nrow(data)."), rule$flag), call. = FALSE)
    }
    hit[is.na(hit)] <- FALSE
    idx <- which(hit)
    if (!length(idx)) next
    piece <- tibble::tibble(
      row = idx,
      flag = rule$flag,
      priority = rule$priority,
      description = rule$description,
      action = rule$action
    )
    pieces[[length(pieces) + 1L]] <- piece
  }

  if (length(pieces)) {
    report <- do.call(rbind, pieces)
    if (!is.null(keep_cols)) {
      ctx <- data[report$row, keep_cols, drop = FALSE]
      rownames(ctx) <- NULL
      report <- tibble::as_tibble(cbind(report["row"], ctx,
                                        report[setdiff(names(report), "row")]))
    }
    if (!is.null(id_col)) {
      report <- tibble::add_column(report, id = data[[id_col]][report$row],
                                   .after = "row")
      names(report)[names(report) == "id"] <- id_col
    }
    ord <- order(match(report$priority, prio_levels), report$row)
    report <- report[ord, , drop = FALSE]
    report$priority <- factor(report$priority, levels = prio_levels)
  } else {
    report <- tibble::tibble(
      row = integer(0), flag = character(0),
      priority = factor(character(0), levels = prio_levels),
      description = character(0), action = character(0))
  }

  summary <- as.data.frame(table(priority = report$priority, flag = report$flag),
                           stringsAsFactors = FALSE)
  summary <- tibble::as_tibble(summary[summary$Freq > 0, , drop = FALSE])
  names(summary)[names(summary) == "Freq"] <- "n"
  if (nrow(summary)) {
    summary <- summary[order(match(summary$priority, prio_levels)), ]
  }

  if (!is.na(output_dir) && !is.na(filename)) {
    if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
    utils::write.csv(report, file.path(output_dir, filename), row.names = FALSE)
  }

  structure(
    list(report = report, summary = summary, n_rules = length(rules)),
    class = "mysterycall_consistency_report"
  )
}

#' Default cross-field consistency rules for a call log
#'
#' A starter set of study-agnostic rules covering contradictions common to
#' mystery-caller call logs: an appointment date recorded when the office was
#' never reached, a practice marked as taking new patients yet with no
#' appointment recorded, a record marked complete but missing its call date, a
#' missing caller assignment, and a wait time recorded when no appointment was
#' offered (the "a wait exists only when offered" invariant, the companion
#' detector to [mysterycall_reconcile_offer_outcome()]). Column names are
#' supplied via `cols` so the rules travel across studies; any rule whose
#' columns are absent from the data silently no-ops.
#'
#' @param cols Named list mapping roles to column names. Recognized roles:
#'   `answered`, `appointment_date`, `taking_new`, `complete`, `call_date`,
#'   `caller`, `offered`, `wait`. Override any you use; unmatched roles keep
#'   their defaults.
#' @param values Named list of the values that trigger each rule: `answered_no`
#'   (default `FALSE`), `taking_new_yes` (default `"Yes"`), `complete_yes`
#'   (default `"Complete"`), `offered_no` (default `c(FALSE, "FALSE")`).
#'
#' @return A list of [mysterycall_consistency_rule()] objects.
#' @seealso [mysterycall_check_consistency()]
#' @examples
#' rules <- mysterycall_default_consistency_rules()
#' length(rules)
#' @export
mysterycall_default_consistency_rules <- function(cols = list(), values = list()) {
  cc <- utils::modifyList(list(
    answered = "office_answered", appointment_date = "appointment_date",
    taking_new = "taking_new_patients", complete = "complete",
    call_date = "call_date", caller = "caller",
    offered = "appointment_offered", wait = "wait_days_business"), cols)
  vv <- utils::modifyList(list(
    answered_no = FALSE, taking_new_yes = "Yes", complete_yes = "Complete",
    offered_no = c(FALSE, "FALSE")), values)

  # helper: guard so a rule referencing an absent column flags nothing
  has <- function(d, ...) all(c(...) %in% names(d))
  # a wait is "recorded" when it is neither NA nor an empty string
  recorded <- function(x) !is.na(x) & (!is.character(x) | nzchar(trimws(x)))

  list(
    mysterycall_consistency_rule(
      flag = "ANSWER_CONFLICT", priority = "HIGH",
      description = "Office not answered but an appointment date was recorded",
      action = "Clarify: should the office-answered flag be Yes?",
      predicate = function(d) {
        if (!has(d, cc$answered, cc$appointment_date)) return(rep(FALSE, nrow(d)))
        (d[[cc$answered]] %in% vv$answered_no) & !is.na(d[[cc$appointment_date]])
      }),
    mysterycall_consistency_rule(
      flag = "MISSING_APPT_DATE", priority = "HIGH",
      description = "Practice taking new patients but no appointment date recorded",
      action = "Back-fill the appointment date, or correct the new-patient status.",
      predicate = function(d) {
        if (!has(d, cc$taking_new, cc$appointment_date)) return(rep(FALSE, nrow(d)))
        (d[[cc$taking_new]] %in% vv$taking_new_yes) & is.na(d[[cc$appointment_date]])
      }),
    mysterycall_consistency_rule(
      flag = "MISSING_CALL_DATE", priority = "HIGH",
      description = "Record marked complete but the call date is blank",
      action = "Caller must back-fill the date of the phone call.",
      predicate = function(d) {
        if (!has(d, cc$complete, cc$call_date)) return(rep(FALSE, nrow(d)))
        (d[[cc$complete]] %in% vv$complete_yes) & is.na(d[[cc$call_date]])
      }),
    mysterycall_consistency_rule(
      flag = "NO_CALLER_ASSIGNED", priority = "MEDIUM",
      description = "No caller assigned to this record",
      action = "Assign a caller to the record.",
      predicate = function(d) {
        if (!has(d, cc$caller)) return(rep(FALSE, nrow(d)))
        cal <- d[[cc$caller]]
        is.na(cal) | tolower(trimws(as.character(cal))) %in% c("", "na")
      }),
    mysterycall_consistency_rule(
      flag = "WAIT_NO_OFFER", priority = "HIGH",
      description = "A wait time is recorded but no appointment was offered",
      action = paste("Clear the wait time, or correct the appointment-offered",
                     "flag / outcome (see mysterycall_reconcile_offer_outcome())."),
      predicate = function(d) {
        if (!has(d, cc$offered, cc$wait)) return(rep(FALSE, nrow(d)))
        recorded(d[[cc$wait]]) & (d[[cc$offered]] %in% vv$offered_no)
      })
  )
}

#' Print a `mysterycall_consistency_report` object
#'
#' @param x A `mysterycall_consistency_report` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return `x`, invisibly.
#' @export
print.mysterycall_consistency_report <- function(x, ...) {
  cat(sprintf("<mysterycall consistency report: %d rows flagged by %d of %d rules>\n",
              nrow(x$report), nrow(x$summary), x$n_rules))
  if (nrow(x$summary)) {
    cat("\nBy priority / flag:\n")
    print(x$summary, ...)
    cat("\n")
    print(x$report, ...)
  } else {
    cat("No consistency violations found.\n")
  }
  invisible(x)
}

#' Coerce a `mysterycall_consistency_report` object to a data frame
#'
#' @param x A `mysterycall_consistency_report` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return A `data.frame` representation of `x`.
#' @export
as.data.frame.mysterycall_consistency_report <- function(x, ...) {
  as.data.frame(x$report, ...)
}
