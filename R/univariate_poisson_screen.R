#' Screen predictors one-at-a-time using univariate Poisson GLMs
#'
#' @name mysterycall_univariate_poisson_screen
NULL

#' Screen predictors with univariate Poisson GLMs
#'
#' For each predictor (excluding `outcome_col` and any `exclude_cols`), fits a
#' simple Poisson GLM (no random effects) using [stats::glm()] with
#' `family = poisson(link = "log")`. Predictors with only one unique value are
#' skipped with a message.
#'
#' Direction of association is determined from the sign of the predictor
#' coefficient: positive estimates are labelled `"Higher"` and negative
#' estimates `"Lower"`.
#'
#' @param data A data frame.
#' @param outcome_col Character scalar. The count or binary outcome column.
#' @param exclude_cols Character vector. Columns to exclude from the predictor
#'   loop. Default is `outcome_col` alone; supply additional columns as needed.
#' @param alpha Numeric. Significance threshold for the `$significant` table.
#'   Default `0.2`.
#' @param output_dir Character scalar or `NULL`. Directory for CSV output.
#'   `NULL` uses [mysterycall_tempdir()]. Pass `NA` to skip writing.
#' @param filename Character scalar. CSV file name.
#'   Default `"univariate_poisson_screen.csv"`.
#'
#' @return A named list with four elements:
#' \describe{
#'   \item{`results`}{[tibble::tibble()] with columns `Variable`, `P_Value`,
#'     `Formatted_P_Value`, `Direction` for every predictor attempted.}
#'   \item{`significant`}{Subset of `results` where `P_Value < alpha`, sorted
#'     ascending by `P_Value`.}
#'   \item{`sentence`}{Character scalar summarising significant predictors.}
#'   \item{`alpha`}{The threshold used.}
#' }
#'
#' @family modeling helpers
#' @seealso [mysterycall_univariate_lmm_screen()],
#'   [mysterycall_interaction_screen()]
#' @importFrom stats glm poisson coef as.formula na.omit
#' @importFrom utils write.csv
#' @export
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   wait_days = rpois(60, 10),
#'   insurance = rep(c("BCBS", "Medicaid"), 30),
#'   gender    = rep(c("M", "F"), 30),
#'   stringsAsFactors = FALSE
#' )
#' res <- mysterycall_univariate_poisson_screen(
#'   df, outcome_col = "wait_days", output_dir = NA
#' )
mysterycall_univariate_poisson_screen <- function(
    data,
    outcome_col  = "business_days_until_appointment",
    exclude_cols = outcome_col,
    alpha        = 0.2,
    output_dir   = NULL,
    filename     = "univariate_poisson_screen.csv") {

  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  if (missing(outcome_col) || !is.character(outcome_col) ||
      length(outcome_col) != 1L)
    stop("`outcome_col` must be a single character string.", call. = FALSE)
  if (!outcome_col %in% names(data))
    stop(sprintf("Outcome column '%s' not found in data.", outcome_col),
         call. = FALSE)

  predictors <- setdiff(names(data), unique(exclude_cols))
  predictors <- predictors[nzchar(predictors)]

  rows <- lapply(predictors, function(var) {
    col_vals <- data[[var]]
    n_unique <- length(unique(stats::na.omit(col_vals)))
    if (n_unique < 2L) {
      message(sprintf(
        "Skipping '%s': only %d unique value(s).", var, n_unique
      ))
      return(NULL)
    }

    tryCatch({
      fml   <- stats::as.formula(sprintf("%s ~ %s", outcome_col, var))
      model <- stats::glm(fml, family = stats::poisson(link = "log"),
                          data = data)

      coef_tbl <- summary(model)$coefficients
      if (nrow(coef_tbl) < 2L) return(NULL)

      p_value    <- coef_tbl[2L, 4L]
      coef_value <- stats::coef(model)[2L]
      direction  <- if (coef_value > 0) "Higher" else "Lower"

      data.frame(
        Variable        = var,
        P_Value         = p_value,
        Formatted_P_Value = ifelse(p_value < 0.01, "<0.01",
                                   as.character(round(p_value, 2))),
        Direction       = direction,
        stringsAsFactors = FALSE
      )
    }, error = function(e) {
      message(sprintf("Skipping '%s': model failed (%s).", var,
                      conditionMessage(e)))
      NULL
    })
  })

  rows <- rows[!vapply(rows, is.null, logical(1L))]

  if (length(rows) == 0L) {
    results <- tibble::tibble(
      Variable          = character(),
      P_Value           = numeric(),
      Formatted_P_Value = character(),
      Direction         = character()
    )
  } else {
    results <- tibble::as_tibble(do.call(rbind, rows))
  }

  significant <- results[results$P_Value < alpha, , drop = FALSE]
  significant <- significant[order(significant$P_Value), , drop = FALSE]

  if (nrow(significant) == 0L) {
    sentence <- sprintf("No significant predictors found (p < %.2f).", alpha)
  } else {
    parts <- mapply(
      function(var, dir, pval) {
        sprintf("%s (%s, p=%s)", var, dir,
                ifelse(pval < 0.01, "<0.01", as.character(round(pval, 2))))
      },
      significant$Variable, significant$Direction, significant$P_Value,
      SIMPLIFY = TRUE
    )
    sentence <- sprintf(
      "Significant predictors (p < %.2f): %s.",
      alpha, paste(parts, collapse = ", ")
    )
  }

  # Output
  if (!identical(output_dir, NA) && !identical(output_dir, NA_character_)) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("univariate_poisson_screen",
                                        create = TRUE)
    }
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    out_path <- file.path(output_dir, filename)
    utils::write.csv(results, out_path, row.names = FALSE)
    message(sprintf("Results written to %s", out_path))
  }

  list(
    results     = results,
    significant = tibble::as_tibble(significant),
    sentence    = sentence,
    alpha       = alpha
  )
}
