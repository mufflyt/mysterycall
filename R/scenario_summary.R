#' Scenario call count summary and descriptive sentence
#'
#' @name mysterycall_scenario_summary
NULL

#' Summarise call counts by scenario and build a manuscript sentence
#'
#' Counts the number of calls per scenario level, computes row percentages, and
#' builds a ready-to-paste sentence describing the distribution. Optionally
#' filters to successfully-contacted calls before generating the contact-level
#' scenario counts.
#'
#' @param data A data frame of mystery-caller records.
#' @param scenario_col Character scalar. Name of the column containing scenario
#'   labels. Default `"scenario"`.
#' @param scenario_levels Named character vector. Maps display labels (names) to
#'   column values (values), e.g.
#'   `c(hip = "HIP scenario", shoulder = "SHOULDER scenario", knee = "KNEE scenario")`.
#'   When `NULL` (default), all unique values found in `scenario_col` are used
#'   and a generic sentence is generated.
#' @param contact_col Character scalar or `NULL`. If provided, also compute
#'   scenario counts restricted to rows where `contact_col == contact_value`.
#'   Default `NULL`.
#' @param contact_value Character scalar. The value in `contact_col` that
#'   indicates a successful contact. Default `"Able to contact"`.
#' @param output_dir Character scalar or `NULL`. Directory for CSV output.
#'   `NULL` (default) writes to a session temp directory via
#'   [mysterycall_tempdir()]. Pass `NA` to skip writing entirely.
#' @param filename Character scalar. Output CSV file name.
#'   Default `"scenario_summary.csv"`.
#'
#' @return A named list with four elements:
#' \describe{
#'   \item{`counts`}{[tibble::tibble()] with columns `scenario`, `count`,
#'     `percent`, arranged descending by `count`.}
#'   \item{`total`}{Integer. Total number of rows in `data`.}
#'   \item{`sentence`}{Character scalar. Manuscript-ready descriptive sentence.
#'     When `scenario_levels` is `NULL` a generic format is used; when provided
#'     the sentence follows the sports-medicine orthopedics template from the
#'     source Rmd.}
#'   \item{`contact_counts`}{[tibble::tibble()] with the same columns as
#'     `counts` but restricted to rows where `contact_col == contact_value`.
#'     `NULL` when `contact_col` is not supplied.}
#' }
#'
#' @family descriptive helpers
#' @seealso [mysterycall_sensitivity_both_insurance()]
#' @importFrom dplyr count arrange desc
#' @importFrom tibble as_tibble
#' @importFrom utils write.csv
#' @export
#'
#' @examples
#' df <- data.frame(
#'   scenario = c(
#'     "HIP scenario", "HIP scenario", "SHOULDER scenario",
#'     "KNEE scenario", "HIP scenario"
#'   ),
#'   status = rep("Able to contact", 5L),
#'   stringsAsFactors = FALSE
#' )
#' res <- mysterycall_scenario_summary(
#'   df,
#'   scenario_levels = c(
#'     hip      = "HIP scenario",
#'     shoulder = "SHOULDER scenario",
#'     knee     = "KNEE scenario"
#'   ),
#'   output_dir = NA
#' )
#' cat(res$sentence)
mysterycall_scenario_summary <- function(
    data,
    scenario_col    = "scenario",
    scenario_levels = NULL,
    contact_col     = NULL,
    contact_value   = "Able to contact",
    output_dir      = NULL,
    filename        = "scenario_summary.csv"
) {

  # ---- input validation -------------------------------------------------------
  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  if (!is.character(scenario_col) || length(scenario_col) != 1L)
    stop("`scenario_col` must be a single character string.", call. = FALSE)
  if (!scenario_col %in% names(data))
    stop(sprintf("Column '%s' not found in data.", scenario_col), call. = FALSE)
  if (!is.null(contact_col)) {
    if (!is.character(contact_col) || length(contact_col) != 1L)
      stop("`contact_col` must be a single character string or NULL.", call. = FALSE)
    if (!contact_col %in% names(data))
      stop(sprintf("Column '%s' not found in data.", contact_col), call. = FALSE)
  }
  if (!is.null(scenario_levels)) {
    if (!is.character(scenario_levels) || is.null(names(scenario_levels)) ||
        any(!nzchar(names(scenario_levels))))
      stop("`scenario_levels` must be a named character vector.", call. = FALSE)
  }

  # ---- build full scenario counts --------------------------------------------
  counts_df <- dplyr::count(data, .data[[scenario_col]], name = "count")
  names(counts_df)[1L] <- "scenario"
  counts_df <- dplyr::arrange(counts_df, dplyr::desc(.data$count))
  total     <- sum(counts_df$count)

  counts_df$percent <- if (total > 0L) {
    round(counts_df$count / total * 100, 1)
  } else {
    rep(NA_real_, nrow(counts_df))
  }

  # ---- contact-filtered counts (optional) ------------------------------------
  contact_counts <- NULL
  if (!is.null(contact_col)) {
    contact_data <- data[
      !is.na(data[[contact_col]]) & data[[contact_col]] == contact_value,
      , drop = FALSE
    ]
    if (nrow(contact_data) > 0L) {
      cc_df <- dplyr::count(contact_data, .data[[scenario_col]], name = "count")
      names(cc_df)[1L] <- "scenario"
      cc_df <- dplyr::arrange(cc_df, dplyr::desc(.data$count))
      cc_total <- sum(cc_df$count)
      cc_df$percent <- if (cc_total > 0L) {
        round(cc_df$count / cc_total * 100, 1)
      } else {
        NA_real_
      }
      contact_counts <- tibble::as_tibble(cc_df)
    } else {
      # Return an empty tibble with correct columns
      contact_counts <- tibble::as_tibble(
        data.frame(
          scenario = character(0L),
          count    = integer(0L),
          percent  = numeric(0L),
          stringsAsFactors = FALSE
        )
      )
    }
  }

  # ---- build sentence --------------------------------------------------------
  sentence <- .build_scenario_sentence(
    scenario_levels = scenario_levels,
    counts_df       = counts_df,
    total           = total
  )

  # ---- optional CSV output ---------------------------------------------------
  if (!isTRUE(is.na(output_dir))) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("scenario_summary", create = TRUE)
    }
    if (!dir.exists(output_dir))
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    out_path <- file.path(output_dir, filename)
    utils::write.csv(counts_df, out_path, row.names = FALSE)
    message("Scenario summary written to: ", out_path)
  }

  list(
    counts        = tibble::as_tibble(counts_df),
    total         = total,
    sentence      = sentence,
    contact_counts = contact_counts
  )
}


# ---- internal sentence builder ----------------------------------------------
#' @noRd
.build_scenario_sentence <- function(scenario_levels, counts_df, total) {

  if (total == 0L) {
    return(sprintf(
      "There were 0 calls across 0 scenarios."
    ))
  }

  if (is.null(scenario_levels)) {
    # Generic template: "There were N calls across K scenarios: L1 (n=n1), ..."
    k <- nrow(counts_df)
    parts <- sprintf("%s (n=%d)", counts_df$scenario, counts_df$count)
    return(sprintf(
      "There were %d call%s across %d scenario%s: %s.",
      total, if (total == 1L) "" else "s",
      k, if (k == 1L) "" else "s",
      paste(parts, collapse = ", ")
    ))
  }

  # Named-levels template (sports-medicine style)
  display_names <- names(scenario_levels)
  col_values    <- unname(scenario_levels)

  level_counts <- vapply(col_values, function(val) {
    idx <- counts_df$scenario == val
    if (any(idx)) counts_df$count[idx][1L] else 0L
  }, integer(1L))

  n_levels <- length(display_names)
  items    <- sprintf("%d %s", level_counts, display_names)

  parts_str <- if (n_levels == 1L) {
    items
  } else if (n_levels == 2L) {
    paste(items, collapse = " and ")
  } else {
    paste0(
      paste(items[-n_levels], collapse = ", "),
      ", and ",
      items[n_levels]
    )
  }

  sprintf(
    "There were %d calls, with sports medicine orthopedists specializing in %s.",
    total, parts_str
  )
}
