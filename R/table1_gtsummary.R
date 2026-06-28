#' Publication-ready Table 1 via gtsummary
#'
#' @name mysterycall_table1_gtsummary
NULL

#' Generate a publication-ready Table 1 using gtsummary
#'
#' Wraps [gtsummary::tbl_summary()] with opinionated defaults suitable for
#' mystery-caller study demographics: no "Unknown" rows (use `missing =
#' "ifany"` to re-enable), bold row labels, an overall column and p-values
#' when stratified.
#'
#' @param data A data frame.
#' @param vars Non-empty character vector of column names to include as rows.
#'   All names must be present in `data`. If `strata_col` appears here it is
#'   silently removed with a warning.
#' @param strata_col Optional single character column name to stratify by
#'   (e.g. `"insurance"`). When provided, an Overall column and p-values are
#'   added automatically.
#' @param label_list Optional named list mapping column names to display
#'   labels, forwarded to [gtsummary::tbl_summary()].
#' @param missing One of `"no"` (default), `"ifany"`, or `"always"`. Controls
#'   missing-data reporting. Forwarded to [gtsummary::tbl_summary()].
#' @param percent One of `"column"` (default), `"row"`, or `"cell"`. Controls
#'   the denominator used for categorical-variable percentages.
#' @param overall_last Logical. When `strata_col` is provided, should the
#'   Overall column appear last (`TRUE`) or first (`FALSE`, default)?
#' @param ... Additional arguments forwarded to [gtsummary::tbl_summary()].
#'
#' @return A `gtsummary` `tbl_summary` object. Chain additional modifiers
#'   (e.g. [gtsummary::modify_caption()], [gtsummary::modify_spanning_header()])
#'   before converting with [gtsummary::as_gt()] or [gtsummary::as_flex_table()].
#'
#' @examplesIf interactive() && requireNamespace("gtsummary", quietly = TRUE)
#' df <- data.frame(
#'   gender    = sample(c("Male", "Female"), 100, replace = TRUE),
#'   setting   = sample(c("Academic", "Private"), 100, replace = TRUE),
#'   age_cat   = sample(c("30-39", "40-49", "50-59"), 100, replace = TRUE),
#'   insurance = sample(c("BCBS", "Medicaid"), 100, replace = TRUE)
#' )
#' tbl <- mysterycall_table1_gtsummary(
#'   df,
#'   vars       = c("gender", "setting", "age_cat"),
#'   strata_col = "insurance"
#' )
#' tbl
#'
#' @family table
#' @seealso [mysterycall_table1()], [mysterycall_disparities_table()]
#' @export
mysterycall_table1_gtsummary <- function(data,
                                          vars,
                                          strata_col   = NULL,
                                          label_list   = NULL,
                                          missing      = "no",
                                          percent      = c("column", "row", "cell"),
                                          overall_last = FALSE,
                                          ...) {
  if (!requireNamespace("gtsummary", quietly = TRUE)) {
    stop(
      "This function requires the gtsummary package.\n",
      "Install it with: install.packages(\"gtsummary\")",
      call. = FALSE
    )
  }
  # ---- validation ----------------------------------------------------------
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!is.character(vars) || length(vars) == 0L) {
    stop("`vars` must be a non-empty character vector of column names.", call. = FALSE)
  }
  missing_vars <- setdiff(vars, names(data))
  if (length(missing_vars) > 0L) {
    stop(
      "Variable(s) not found in `data`: ",
      paste(missing_vars, collapse = ", "),
      call. = FALSE
    )
  }
  if (!is.null(strata_col)) {
    if (!is.character(strata_col) || length(strata_col) != 1L || is.na(strata_col)) {
      stop("`strata_col` must be a single non-NA character string.", call. = FALSE)
    }
    if (!strata_col %in% names(data)) {
      stop(
        sprintf("`strata_col` '%s' not found in `data`.", strata_col),
        call. = FALSE
      )
    }
    if (strata_col %in% vars) {
      warning(
        sprintf("`strata_col` '%s' appears in `vars` and will be excluded from row listing.",
                strata_col),
        call. = FALSE
      )
      vars <- setdiff(vars, strata_col)
    }
  }
  percent <- match.arg(percent)
  missing <- match.arg(missing, c("no", "ifany", "always"))

  # ---- build table ---------------------------------------------------------
  tbl <- suppressWarnings(
    gtsummary::tbl_summary(
      data    = data[, c(vars, strata_col), drop = FALSE],
      by      = strata_col,
      label   = label_list,
      missing = missing,
      percent = percent,
      ...
    )
  )

  if (!is.null(strata_col)) {
    tbl <- gtsummary::add_overall(tbl, last = overall_last)
    tbl <- gtsummary::add_p(tbl)
  }

  gtsummary::bold_labels(tbl)
}
