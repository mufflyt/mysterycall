#' Screen all pairwise factor interactions using linear mixed models
#'
#' @name mysterycall_interaction_screen
NULL

#' Screen all pairwise factor interactions with LMMs
#'
#' For every pair of factor columns in `data` (excluding `outcome_col` and
#' `random_effect`), fits a linear mixed model with an interaction term using
#' [lmerTest::lmer()]. Pairs that yield at least one significant non-intercept
#' coefficient (p <= `alpha`) are collected. AIC is computed for every model
#' that converges, allowing the best-fitting interaction to be identified.
#'
#' When the number of possible pairs exceeds `max_pairs`, a random sample of
#' `max_pairs` pairs is drawn with `set.seed(42)`.
#'
#' @param data A data frame. Rows where `outcome_col` is `NA` are dropped.
#' @param outcome_col Character scalar. Numeric outcome column.
#'   Default `"business_days_until_appointment"`.
#' @param random_effect Character scalar. Column for the random intercept.
#'   Default `"last"`.
#' @param alpha Numeric. P-value threshold for a pair to be considered
#'   significant. Default `0.05`.
#' @param max_pairs Integer. Maximum pairs to test. When the pool exceeds this,
#'   `max_pairs` pairs are sampled randomly with `set.seed(42)`.
#'   Default `50L`.
#' @param output_dir Character scalar or `NULL`. Directory for CSV output.
#'   `NULL` uses [mysterycall_tempdir()]. Pass `NA` to skip writing.
#' @param filename Character scalar. CSV file name.
#'   Default `"interaction_screen.csv"`.
#'
#' @return A named list:
#' \describe{
#'   \item{`interaction_results`}{[tibble::tibble()] with columns
#'     `Interaction` and `P_Value` for significant interactions.}
#'   \item{`aic_results`}{[tibble::tibble()] with columns `Interaction` and
#'     `AIC` for every converged model.}
#'   \item{`best_interaction`}{Single-row tibble (lowest AIC), or `NULL` if no
#'     models converged.}
#'   \item{`n_pairs_tested`}{Integer. Number of pairs actually tested.}
#'   \item{`sentence`}{Character scalar summarising the result.}
#' }
#'
#' @family modeling helpers
#' @seealso [mysterycall_univariate_lmm_screen()],
#'   [mysterycall_univariate_poisson_screen()]
#' @importFrom stats as.formula AIC
#' @importFrom utils write.csv
#' @export
#'
#' @examplesIf requireNamespace("lmerTest", quietly = TRUE)
#' set.seed(1)
#' df <- data.frame(
#'   business_days_until_appointment = rpois(60, 10),
#'   insurance = factor(rep(c("BCBS", "Medicaid"), 30)),
#'   gender    = factor(rep(c("M", "F"), 30)),
#'   last      = rep(paste0("Dr", 1:10), each = 6),
#'   stringsAsFactors = FALSE
#' )
#' res <- mysterycall_interaction_screen(df, output_dir = NA)
mysterycall_interaction_screen <- function(
    data,
    outcome_col   = "business_days_until_appointment",
    random_effect = "last",
    alpha         = 0.05,
    max_pairs     = 50L,
    output_dir    = NULL,
    filename      = "interaction_screen.csv") {

  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  if (!outcome_col %in% names(data))
    stop(sprintf("Outcome column '%s' not found in data.", outcome_col),
         call. = FALSE)
  if (!random_effect %in% names(data))
    stop(sprintf("Random effect column '%s' not found in data.", random_effect),
         call. = FALSE)
  if (!requireNamespace("lmerTest", quietly = TRUE))
    stop("Package 'lmerTest' is required. Install with: install.packages('lmerTest')",
         call. = FALSE)

  df_filtered <- data[!is.na(data[[outcome_col]]), , drop = FALSE]

  # Identify factor predictors
  candidate_cols <- setdiff(names(df_filtered),
                            c(outcome_col, random_effect))
  factor_cols <- candidate_cols[vapply(df_filtered[candidate_cols],
                                       is.factor, logical(1L))]

  if (length(factor_cols) < 2L) {
    message("fewer than 2 factor columns found — no pairs to test.")
    return(list(
      interaction_results = tibble::tibble(Interaction = character(),
                                           P_Value     = numeric()),
      aic_results         = tibble::tibble(Interaction = character(),
                                           AIC         = numeric()),
      best_interaction    = NULL,
      n_pairs_tested      = 0L,
      sentence            = "No significant interactions were found."
    ))
  }

  # Generate all pairs
  pairs <- utils::combn(factor_cols, 2L, simplify = FALSE)

  # Cap at max_pairs
  if (length(pairs) > max_pairs) {
    set.seed(42L)
    pairs <- pairs[sample(length(pairs), max_pairs)]
  }

  n_pairs_tested <- length(pairs)
  random_term    <- sprintf("(1 | %s)", random_effect)

  interaction_rows <- list()
  aic_rows         <- list()

  for (pair in pairs) {
    var1 <- pair[1L]
    var2 <- pair[2L]
    interaction_label <- sprintf("%s * %s", var1, var2)

    tryCatch({
      fml <- stats::as.formula(sprintf(
        "%s ~ %s * %s + %s", outcome_col, var1, var2, random_term
      ))
      model <- lmerTest::lmer(fml, data = df_filtered, REML = FALSE)
      coef_tbl <- summary(model)$coefficients

      # Exclude intercept; look at all other rows
      non_intercept <- coef_tbl[rownames(coef_tbl) != "(Intercept)", ,
                                 drop = FALSE]
      if (nrow(non_intercept) > 0L) {
        p_col_name <- "Pr(>|t|)"
        if (p_col_name %in% colnames(non_intercept)) {
          p_vals <- non_intercept[, p_col_name]
          sig_rows <- non_intercept[!is.na(p_vals) & p_vals <= alpha, ,
                                    drop = FALSE]
          if (nrow(sig_rows) > 0L) {
            # Record minimum p per pair
            interaction_rows[[length(interaction_rows) + 1L]] <- data.frame(
              Interaction = interaction_label,
              P_Value     = min(p_vals, na.rm = TRUE),
              stringsAsFactors = FALSE
            )
          }
        }
      }

      # AIC for every converged model
      model_aic <- tryCatch(stats::AIC(model), error = function(e) NA_real_)
      aic_rows[[length(aic_rows) + 1L]] <- data.frame(
        Interaction = interaction_label,
        AIC         = model_aic,
        stringsAsFactors = FALSE
      )
    }, error = function(e) {
      message(sprintf("Model failed for %s: %s",
                      interaction_label, conditionMessage(e)))
    })
  }

  # Assemble output tables
  if (length(interaction_rows) > 0L) {
    interaction_results <- tibble::as_tibble(
      do.call(rbind, interaction_rows)
    )
  } else {
    interaction_results <- tibble::tibble(
      Interaction = character(),
      P_Value     = numeric()
    )
  }

  if (length(aic_rows) > 0L) {
    aic_results <- tibble::as_tibble(do.call(rbind, aic_rows))
    aic_results <- aic_results[order(aic_results$AIC, na.last = TRUE), ,
                                drop = FALSE]
  } else {
    aic_results <- tibble::tibble(
      Interaction = character(),
      AIC         = numeric()
    )
  }

  if (nrow(aic_results) > 0L && !all(is.na(aic_results$AIC))) {
    best_interaction <- aic_results[which.min(aic_results$AIC), , drop = FALSE]
    sentence <- sprintf(
      "The interaction with the lowest AIC was %s (AIC=%.2f).",
      best_interaction$Interaction[1L],
      best_interaction$AIC[1L]
    )
  } else {
    best_interaction <- NULL
    sentence <- "No significant interactions were found."
  }

  # Output
  if (!identical(output_dir, NA) && !identical(output_dir, NA_character_)) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("interaction_screen", create = TRUE)
    }
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    out_path <- file.path(output_dir, filename)
    utils::write.csv(interaction_results, out_path, row.names = FALSE)
    message(sprintf("Interaction results written to %s", out_path))
  }

  list(
    interaction_results = interaction_results,
    aic_results         = aic_results,
    best_interaction    = if (is.null(best_interaction)) NULL
                          else tibble::as_tibble(best_interaction),
    n_pairs_tested      = n_pairs_tested,
    sentence            = sentence
  )
}
