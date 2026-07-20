#' Reconcile a binary "offered" flag against a granular outcome field
#'
#' Call logs often record the same appointment fact twice: a coarse binary
#' "appointment offered" flag and a richer categorical disposition (e.g.
#' `"With sampled physician"`, `"No appointment offered"`). These drift apart
#' during data entry. This function finds — and optionally fixes — the two kinds
#' of contradiction:
#'
#' * **flag understates** the outcome: the disposition names an appointment that
#'   was offered, but the flag says it was not. The flag is set to "offered".
#' * **flag overstates** the outcome: the flag says an appointment was offered,
#'   but the disposition says none was. The flag is set to "not offered" and any
#'   `dependent_cols` (wait time, appointment date) are cleared so the
#'   "a wait exists only when an appointment was offered" invariant holds.
#'
#' The granular `outcome_col` is treated as authoritative. Rows whose outcome is
#' in neither `offered_values` nor `not_offered_values` are left untouched.
#'
#' @param data A data frame with one row per call.
#' @param flag_col Name of the binary offered flag column.
#' @param outcome_col Name of the granular disposition column.
#' @param offered_values Values of `outcome_col` that imply an appointment
#'   **was** offered.
#' @param not_offered_values Values of `outcome_col` that imply **no**
#'   appointment was offered.
#' @param dependent_cols Character vector of columns to blank out when a row is
#'   flipped to "not offered" (e.g. `c("wait_days_business", "appointment_date")`).
#'   Default none.
#' @param action `"flag"` (default) to detect and report discordance without
#'   changing `data`, or `"fix"` to apply the corrections.
#' @param true_value,false_value The value(s) that represent offered / not
#'   offered in `flag_col`. Matching uses `%in%`, so pass every spelling present
#'   (defaults cover logical and character `TRUE`/`FALSE`). When `action = "fix"`
#'   the first element of each is written back, coerced to the column's type.
#' @param clear_value Value written into `dependent_cols` on a not-offered flip.
#'   Defaults to `NA`; use `""` for character columns you export with `na = ""`.
#' @param id_col Optional identifier column included in the discordance report.
#'
#' @return An object of class `"mysterycall_offer_reconciliation"`: a list with
#'   `data` (unchanged when `action = "flag"`, corrected when `"fix"`),
#'   `discordant` (a tibble: `row`, optional id, `flag`, `outcome`, `direction`,
#'   `suggested`), and `n_understated` / `n_overstated` counts.
#'   [as.data.frame()] returns the discordance report.
#'
#' @examples
#' d <- data.frame(
#'   record_id           = 1:4,
#'   appointment_offered = c(FALSE, TRUE, TRUE, FALSE),
#'   appointment_outcome = c("With sampled physician", "No appointment offered",
#'                           "With sampled physician", "No appointment offered"),
#'   wait_days_business  = c(10, 5, 8, NA)
#' )
#' res <- mysterycall_reconcile_offer_outcome(
#'   d, "appointment_offered", "appointment_outcome",
#'   offered_values     = "With sampled physician",
#'   not_offered_values = "No appointment offered",
#'   dependent_cols     = "wait_days_business",
#'   action = "fix", id_col = "record_id"
#' )
#' as.data.frame(res)
#' @export
mysterycall_reconcile_offer_outcome <- function(
    data, flag_col, outcome_col, offered_values, not_offered_values,
    dependent_cols = character(0), action = c("flag", "fix"),
    true_value = c(TRUE, "TRUE"), false_value = c(FALSE, "FALSE"),
    clear_value = NA, id_col = NULL) {

  action <- match.arg(action)
  checkmate::assert_data_frame(data)
  checkmate::assert_choice(flag_col, names(data))
  checkmate::assert_choice(outcome_col, names(data))
  checkmate::assert_character(dependent_cols)
  if (length(dependent_cols)) {
    checkmate::assert_subset(dependent_cols, names(data))
  }
  if (!is.null(id_col)) checkmate::assert_choice(id_col, names(data))
  if (length(intersect(offered_values, not_offered_values))) {
    stop("`offered_values` and `not_offered_values` overlap: ",
         paste(intersect(offered_values, not_offered_values), collapse = ", "),
         call. = FALSE)
  }

  flag <- data[[flag_col]]
  outcome <- data[[outcome_col]]
  is_offered_flag <- flag %in% true_value

  understated <- (outcome %in% offered_values) & !is_offered_flag
  overstated  <- (outcome %in% not_offered_values) & is_offered_flag
  understated[is.na(understated)] <- FALSE
  overstated[is.na(overstated)] <- FALSE

  rows <- which(understated | overstated)
  report <- tibble::tibble(
    row = rows,
    flag = flag[rows],
    outcome = outcome[rows],
    direction = ifelse(understated[rows], "flag_understates", "flag_overstates"),
    suggested = ifelse(understated[rows], "offered", "not_offered")
  )
  if (!is.null(id_col)) {
    report <- tibble::add_column(report, id = data[[id_col]][rows],
                                 .after = "row")
    names(report)[names(report) == "id"] <- id_col
  }

  out <- data
  if (action == "fix") {
    out[[flag_col]][understated] <- .mc_coerce_like(true_value[[1]], flag)
    out[[flag_col]][overstated]  <- .mc_coerce_like(false_value[[1]], flag)
    for (dc in dependent_cols) {
      out[[dc]][overstated] <- .mc_coerce_like(clear_value, data[[dc]])
    }
  }

  structure(
    list(data = out, discordant = report,
         n_understated = sum(understated), n_overstated = sum(overstated),
         action = action),
    class = "mysterycall_offer_reconciliation"
  )
}

# Coerce a replacement value to the storage type of the target column, so
# writing FALSE into a character column stores "FALSE", not a coerced NA.
.mc_coerce_like <- function(value, target) {
  if (is.na(value)) return(methods::as(NA, class(target)[1]))
  if (is.character(target)) return(as.character(value))
  if (is.logical(target))   return(as.logical(value))
  if (is.numeric(target))   return(as.numeric(value))
  value
}

#' Print a `mysterycall_offer_reconciliation` object
#'
#' @param x A `mysterycall_offer_reconciliation` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return `x`, invisibly.
#' @export
print.mysterycall_offer_reconciliation <- function(x, ...) {
  cat(sprintf("<mysterycall offer/outcome reconciliation [%s]>\n", x$action))
  cat(sprintf("  flag understates outcome (-> offered):     %d\n",
              x$n_understated))
  cat(sprintf("  flag overstates outcome (-> not offered):  %d\n",
              x$n_overstated))
  if (nrow(x$discordant)) {
    cat("\nDiscordant rows:\n")
    print(x$discordant, ...)
  } else {
    cat("\nNo discordance found.\n")
  }
  if (x$action == "flag" && nrow(x$discordant)) {
    cat("\nRe-run with action = \"fix\" to apply the suggested corrections.\n")
  }
  invisible(x)
}

#' Coerce a `mysterycall_offer_reconciliation` object to a data frame
#'
#' @param x A `mysterycall_offer_reconciliation` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return A `data.frame` representation of `x`.
#' @export
as.data.frame.mysterycall_offer_reconciliation <- function(x, ...) {
  as.data.frame(x$discordant, ...)
}
