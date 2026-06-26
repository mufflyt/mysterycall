#' Screen candidate variables for interaction with a primary exposure
#'
#' @name mysterycall_screen_interactions
NULL

#' Fit one model per candidate interaction and return a ranked p-value table
#'
#' For each variable in `candidates`, fits a Poisson model with a
#' `exposure * candidate` interaction term and extracts the p-value(s) for the
#' interaction. Results are returned sorted by smallest p-value, making it easy
#' to identify the strongest potential effect modifiers.
#'
#' @param data A data frame.
#' @param outcome Character scalar. Name of the count-outcome column.
#' @param exposure Character scalar. Name of the primary exposure column.
#' @param candidates Character vector. Names of candidate effect-modifier
#'   columns to screen.
#' @param random_intercept Optional character scalar. When supplied, a
#'   `(1 | random_intercept)` term is added and `lme4::glmer()` is used;
#'   otherwise `stats::glm()` is used.
#' @param family Character scalar. Count-model family to use: `"poisson"`
#'   (default) or `"negative_binomial"`. Negative-binomial screening requires
#'   the `glmmTMB` package.
#'
#' @return A data frame with one row per candidate and columns:
#'   `candidate`, `n_terms` (number of interaction coefficients),
#'   `min_p_value`, `significant` (logical, `min_p_value < 0.05`).
#'   Models that fail to converge return `NA` for numeric columns.
#'
#' @seealso [mysterycall_poisson_model()] to fit the primary model;
#'   [mysterycall_select_best_model()] to rank models by AIC/BIC/LRT;
#'   [mysterycall_multiple_comparison_adjust()] for correcting resulting p-values.
#' @family outcomes
#' @export
#'
#' @examplesIf interactive()
#' mysterycall_screen_interactions(
#'   data             = df,
#'   outcome          = "wait_days",
#'   exposure         = "insurance",
#'   candidates       = c("gender", "practice_setting", "region"),
#'   random_intercept = "physician"
#' )
mysterycall_screen_interactions <- function(data,
                                             outcome,
                                             exposure,
                                             candidates,
                                             random_intercept = NULL,
                                             family = c("poisson", "negative_binomial")) {
  family <- match.arg(family)
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  missing_cols <- setdiff(c(outcome, exposure, candidates), names(data))
  if (length(missing_cols) > 0L) {
    stop("Columns not found in data: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  if (identical(family, "negative_binomial") && !requireNamespace("glmmTMB", quietly = TRUE)) {
    stop("glmmTMB is required when `family = \"negative_binomial\"`", call. = FALSE)
  }
  if (!is.null(random_intercept)) {
    if (!requireNamespace("lme4", quietly = TRUE)) {
      stop("lme4 is required when `random_intercept` is supplied",
           call. = FALSE)
    }
    if (!random_intercept %in% names(data)) {
      stop("`random_intercept` column not found in data.", call. = FALSE)
    }
  }

  results <- lapply(candidates, function(cand) {
    tryCatch({
      if (identical(family, "negative_binomial")) {
        if (!is.null(random_intercept)) {
          fml <- stats::as.formula(
            sprintf("%s ~ %s * %s + (1|%s)", outcome, exposure, cand, random_intercept)
          )
        } else {
          fml <- stats::as.formula(sprintf("%s ~ %s * %s", outcome, exposure, cand))
        }
        fit <- glmmTMB::glmmTMB(fml, data = data, family = glmmTMB::nbinom2(link = "log"))
        coef_mat <- as.data.frame(summary(fit)$coefficients$cond)
      } else if (!is.null(random_intercept)) {
        fml <- stats::as.formula(
          sprintf("%s ~ %s * %s + (1|%s)", outcome, exposure, cand, random_intercept)
        )
        fit <- lme4::glmer(fml, data = data, family = stats::poisson(), nAGQ = 0L)
        coef_mat <- as.data.frame(summary(fit)$coefficients)
      } else {
        fml <- stats::as.formula(sprintf("%s ~ %s * %s", outcome, exposure, cand))
        fit <- stats::glm(fml, data = data, family = stats::poisson())
        coef_mat <- as.data.frame(summary(fit)$coefficients)
      }

      p_col <- ncol(coef_mat)
      int_rows <- .mysterycall_interaction_coef_rows(fit, coef_mat, exposure, cand)

      if (nrow(int_rows) == 0L) {
        return(data.frame(
          candidate   = cand,
          n_terms     = 0L,
          min_p_value = NA_real_,
          significant = NA,
          stringsAsFactors = FALSE
        ))
      }

      p_min <- min(int_rows[[p_col]], na.rm = TRUE)
      data.frame(
        candidate   = cand,
        n_terms     = nrow(int_rows),
        min_p_value = p_min,
        significant = p_min < 0.05,
        stringsAsFactors = FALSE
      )
    }, error = function(e) {
      data.frame(
        candidate   = cand,
        n_terms     = NA_integer_,
        min_p_value = NA_real_,
        significant = NA,
        stringsAsFactors = FALSE
      )
    })
  })

  out <- do.call(rbind, results)
  out[order(out$min_p_value, na.last = TRUE), ]
}

.mysterycall_interaction_coef_rows <- function(fit, coef_mat, exposure, candidate) {
  term_labels <- tryCatch(attr(stats::terms(fit), "term.labels"),
                          error = function(e) character(0))
  interaction_terms <- c(
    paste(exposure, candidate, sep = ":"),
    paste(candidate, exposure, sep = ":")
  )
  interaction_idx <- which(term_labels %in% interaction_terms)

  if (length(interaction_idx) > 0L) {
    mm <- tryCatch(
      {
        if (inherits(fit, "glmmTMB")) {
          stats::model.matrix(fit, component = "cond")
        } else {
          stats::model.matrix(fit)
        }
      },
      error = function(e) NULL
    )
    assign <- attr(mm, "assign")
    if (!is.null(mm) && !is.null(assign)) {
      coef_names <- colnames(mm)[assign %in% interaction_idx]
      matched <- intersect(coef_names, rownames(coef_mat))
      if (length(matched) > 0L) {
        return(coef_mat[matched, , drop = FALSE])
      }
    }
  }

  coef_mat[grepl(":", rownames(coef_mat)) & grepl(exposure, rownames(coef_mat), fixed = TRUE) &
             grepl(candidate, rownames(coef_mat), fixed = TRUE), , drop = FALSE]
}
