#' Screen predictors one-at-a-time using a linear mixed model
#'
#' @name mysterycall_univariate_lmm_screen
NULL

#' Screen predictors with univariate linear mixed models
#'
#' For each predictor (excluding `outcome_col`, `random_effect`, and any
#' `exclude_cols`), fits a linear mixed model using [lmerTest::lmer()] with
#' `REML = FALSE`, then extracts the fixed-effect estimate, standard error, and
#' p-value from the second row of the coefficient table (the predictor row).
#' Predictors with only one unique non-NA value are skipped with a message.
#'
#' Because the underlying model is linear (not Poisson), each predictor's
#' fixed-effect coefficient is an additive mean difference in the outcome's own
#' units, returned as `Estimate` with a 95 % Wald confidence interval on the
#' same additive scale. (Earlier versions exponentiated this coefficient and
#' mislabelled it "IRR", which is meaningless for a linear-scale day
#' difference.) Fit [mysterycall_univariate_poisson_screen()] instead if a true
#' rate ratio is wanted.
#'
#' @param data A data frame. Rows where `outcome_col` is `NA` are dropped.
#' @param outcome_col Character scalar. The numeric outcome column.
#'   Default `"business_days_until_appointment"`.
#' @param random_effect Character scalar. Column used as the random intercept
#'   `(1 | random_effect)`. Default `"last"`.
#' @param exclude_cols Character vector. Columns to exclude from the predictor
#'   loop. Default includes `outcome_col`, `random_effect`, and common
#'   identifier / free-text columns.
#' @param alpha Numeric. Significance threshold for the `$significant` table.
#'   Default `0.2`.
#' @param p_adjust_method Character scalar passed to [stats::p.adjust()] after
#'   all raw p-values are collected. `"none"` (default) skips adjustment and
#'   preserves existing behaviour. Common choices: `"BH"`, `"bonferroni"`,
#'   `"holm"`. When not `"none"`, a `P_Value_Adjusted` column is added to
#'   `$results` and significance is evaluated against the adjusted values.
#' @param output_dir Character scalar or `NULL`. Directory for CSV output.
#'   `NULL` uses [mysterycall_tempdir()]. Pass `NA` to skip writing.
#' @param filename Character scalar. CSV file name.
#'   Default `"univariate_lmm_screen.csv"`.
#'
#' @return A named list with four elements:
#' \describe{
#'   \item{`results`}{[tibble::tibble()] with columns `Predictor`, `P_Value`,
#'     `P_Formatted`, `Estimate` (additive mean difference in outcome units),
#'     `CI_Lower`, `CI_Upper` for every predictor attempted.}
#'   \item{`significant`}{Subset of `results` where `P_Value < alpha`, sorted
#'     ascending by `P_Value`.}
#'   \item{`sentence`}{Character scalar summarising significant predictors.}
#'   \item{`alpha`}{The threshold used.}
#' }
#'
#' @family modeling helpers
#' @seealso [mysterycall_univariate_poisson_screen()],
#'   [mysterycall_interaction_screen()]
#' @importFrom stats as.formula p.adjust
#' @importFrom utils write.csv
#' @export
#'
#' @examplesIf requireNamespace("lmerTest", quietly = TRUE)
#' set.seed(1)
#' df <- data.frame(
#'   business_days_until_appointment = rpois(60, 10),
#'   insurance = rep(c("BCBS", "Medicaid"), 30),
#'   gender    = rep(c("M", "F"), 30),
#'   last      = rep(paste0("Dr", 1:10), each = 6),
#'   stringsAsFactors = FALSE
#' )
#' res <- mysterycall_univariate_lmm_screen(df, output_dir = NA)
mysterycall_univariate_lmm_screen <- function(
    data,
    outcome_col      = "business_days_until_appointment",
    random_effect    = "last",
    exclude_cols     = c(outcome_col, random_effect,
                         "record_id", "middle", "first",
                         "phone", "zip", "notes", "address"),
    alpha            = 0.2,
    p_adjust_method  = "none",
    output_dir       = NULL,
    filename         = "univariate_lmm_screen.csv") {

  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  if (!outcome_col %in% names(data))
    stop(sprintf(
      "outcome_col '%s' not found in `data`.\nAvailable columns: %s",
      outcome_col, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  if (!random_effect %in% names(data))
    stop(sprintf(
      "random_effect '%s' not found in `data`.\nAvailable columns: %s",
      random_effect, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  if (!requireNamespace("lmerTest", quietly = TRUE))
    stop(
      "This function requires the lmerTest package.\n",
      "Install it with: install.packages(\"lmerTest\")",
      call. = FALSE
    )

  # Drop NAs in outcome
  df_filtered <- data[!is.na(data[[outcome_col]]), , drop = FALSE]

  # Build predictor list
  predictors <- setdiff(names(df_filtered), unique(exclude_cols))
  predictors <- predictors[nzchar(predictors)]

  random_term <- sprintf("(1 | %s)", random_effect)

  rows <- lapply(predictors, function(predictor) {
    col_vals <- df_filtered[[predictor]]
    n_unique <- length(unique(stats::na.omit(col_vals)))
    if (n_unique < 2L) {
      message(sprintf(
        "Skipping '%s': only %d unique value(s).", predictor, n_unique
      ))
      return(NULL)
    }

    tryCatch({
      fml <- stats::as.formula(
        sprintf("%s ~ %s + %s", outcome_col, predictor, random_term)
      )
      withCallingHandlers(
        { model <- lmerTest::lmer(fml, data = df_filtered, REML = FALSE) },
        warning = function(w) {
          if (grepl("singular", conditionMessage(w), ignore.case = TRUE))
            invokeRestart("muffleWarning")
        }
      )
      coef_tbl <- summary(model)$coefficients

      if (nrow(coef_tbl) < 2L) return(NULL)

      coef_value <- coef_tbl[2L, "Estimate"]
      std_error  <- coef_tbl[2L, "Std. Error"]
      p_value    <- coef_tbl[2L, "Pr(>|t|)"]

      # The model is a LINEAR mixed model on the raw outcome, so the coefficient
      # is an additive mean difference (in outcome units), NOT a log rate ratio.
      # Report it and its Wald CI on the additive scale; exp()-ing it (the old
      # behaviour) produced a meaningless "IRR" such as exp(7 days) ~ 1096.
      ci_lower <- coef_value - 1.96 * std_error
      ci_upper <- coef_value + 1.96 * std_error

      data.frame(
        Predictor   = predictor,
        P_Value     = p_value,
        P_Formatted = ifelse(p_value < 0.01, "<0.01",
                             as.character(round(p_value, 2))),
        Estimate    = coef_value,
        CI_Lower    = ci_lower,
        CI_Upper    = ci_upper,
        stringsAsFactors = FALSE
      )
    }, error = function(e) {
      message(sprintf("Skipping '%s': model failed (%s).", predictor,
                      conditionMessage(e)))
      NULL
    })
  })

  rows <- rows[!vapply(rows, is.null, logical(1L))]

  if (length(rows) == 0L) {
    results <- tibble::tibble(
      Predictor   = character(),
      P_Value     = numeric(),
      P_Formatted = character(),
      Estimate    = numeric(),
      CI_Lower    = numeric(),
      CI_Upper    = numeric()
    )
  } else {
    results <- tibble::as_tibble(do.call(rbind, rows))
  }

  if (!identical(p_adjust_method, "none")) {
    results$P_Value_Adjusted <- stats::p.adjust(results$P_Value,
                                                 method = p_adjust_method)
    results$P_Adjusted_Formatted <- ifelse(results$P_Value_Adjusted < 0.01,
      "<0.01", as.character(round(results$P_Value_Adjusted, 3)))
    sig_col <- "P_Value_Adjusted"
  } else {
    sig_col <- "P_Value"
  }
  significant <- results[results[[sig_col]] < alpha, , drop = FALSE]
  significant <- significant[order(significant[[sig_col]]), , drop = FALSE]

  if (nrow(significant) == 0L) {
    sentence <- sprintf("No significant predictors found (p < %.2f).", alpha)
  } else {
    correction_note <- if (!identical(p_adjust_method, "none"))
      sprintf(", %s-adjusted", p_adjust_method) else ""
    parts <- mapply(
      function(pred, pval) {
        sprintf("%s (p=%s)", pred,
                ifelse(pval < 0.01, "<0.01", as.character(round(pval, 2))))
      },
      significant$Predictor, significant[[sig_col]],
      SIMPLIFY = TRUE
    )
    sentence <- sprintf(
      "The following predictors were significant (p < %.2f%s): %s.",
      alpha, correction_note, paste(parts, collapse = ", ")
    )
  }

  # Output
  if (!identical(output_dir, NA) && !identical(output_dir, NA_character_)) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("univariate_lmm_screen", create = TRUE)
    }
    out_path <- file.path(output_dir, filename)
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
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
