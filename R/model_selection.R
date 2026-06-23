#' Compare and rank competing fitted models
#'
#' @name mysterycall_select_best_model
NULL

#' Rank a list of fitted models by AIC, BIC, or likelihood-ratio test
#'
#' Accepts a named list of fitted model objects (e.g. output from repeated
#' calls to [mysterycall_poisson_model()] with different predictor sets) and
#' returns a ranked summary table.
#'
#' @param models Named list of fitted model objects. Any object with an `AIC()`
#'   or `BIC()` method is accepted (glm, glmerMod, lm, lmerMod, ...).
#' @param criterion One of:
#'   \describe{
#'     \item{`"aic"`}{Rank by Akaike Information Criterion (default).}
#'     \item{`"bic"`}{Rank by Bayesian Information Criterion.}
#'     \item{`"lrt"`}{Sequential likelihood-ratio tests between consecutive
#'       models. Requires `lme4` for mixed models.}
#'   }
#'
#' @return For `"aic"` and `"bic"`: a data frame with columns `model`,
#'   `AIC`/`BIC`, `delta_AIC`/`delta_BIC`, `winner`.
#'   For `"lrt"`: a data frame with columns `comparison`, `Chisq`, `df`,
#'   `p_value`.
#'
#' @seealso [mysterycall_poisson_model()] and [mysterycall_nb_model()] to fit
#'   the models being compared; [mysterycall_create_formula()] to build
#'   predictor sets; [mysterycall_bootstrap_ci()] for post-selection inference.
#' @family outcomes
#' @keywords internal
#'
#' @examples
#' m1 <- glm(mpg ~ wt, data = mtcars, family = gaussian())
#' m2 <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian())
#' mysterycall_select_best_model(list(base = m1, full = m2))
mysterycall_select_best_model <- function(models,
                                           criterion = c("aic", "bic", "lrt")) {
  criterion <- match.arg(criterion)
  if (!is.list(models) || is.null(names(models)) || any(nchar(names(models)) == 0L)) {
    stop("`models` must be a named list of fitted model objects.", call. = FALSE)
  }

  # Unwrap mysterycall wrapper objects to their inner fitted model
  .unwrap <- function(m) {
    if (inherits(m, c("mysterycall_poisson_model", "mysterycall_nb_model"))) m$model else m
  }

  if (criterion %in% c("aic", "bic")) {
    scores <- vapply(models, function(m) {
      if (inherits(m, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
        if (criterion == "aic") m$aic else m$bic
      } else {
        ic_fn <- if (criterion == "aic") stats::AIC else stats::BIC
        tryCatch(ic_fn(m), error = function(e) NA_real_)
      }
    }, numeric(1L))

    best  <- which.min(scores)
    delta <- scores - scores[[best]]
    out   <- data.frame(
      model  = names(models),
      score  = scores,
      delta  = delta,
      winner = seq_along(models) == best,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
    IC <- toupper(criterion)
    names(out)[2L:3L] <- c(IC, paste0("delta_", IC))
    out[order(out[[IC]], na.last = TRUE), ]

  } else {
    n <- length(models)
    if (n < 2L) stop("At least 2 models are required for LRT.", call. = FALSE)
    results <- lapply(seq_len(n - 1L), function(i) {
      tryCatch({
        lrt <- as.data.frame(
          stats::anova(.unwrap(models[[i]]), .unwrap(models[[i + 1L]]), test = "Chisq")
        )
        if (nrow(lrt) < 2L) return(NULL)
        # Column names differ by model class: "Chisq"/"Deviance", "Df"/"Chi Df"
        chisq_col <- grep("^(Chisq|Deviance|LRT)$", names(lrt), value = TRUE, ignore.case = TRUE)
        df_col    <- grep("^(Df|Chi Df)$",          names(lrt), value = TRUE, ignore.case = TRUE)
        p_col     <- grep("Pr\\(",                   names(lrt), value = TRUE)
        if (length(chisq_col) == 0L || length(p_col) == 0L) return(NULL)
        data.frame(
          comparison = paste0(names(models)[[i]], " vs ", names(models)[[i + 1L]]),
          Chisq      = lrt[[chisq_col[[1L]]]][[2L]],
          df         = if (length(df_col) > 0L) lrt[[df_col[[1L]]]][[2L]] else NA_integer_,
          p_value    = lrt[[p_col[[1L]]]][[2L]],
          stringsAsFactors = FALSE
        )
      }, error = function(e) NULL)
    })
    out <- do.call(rbind, Filter(Negate(is.null), results))
    if (is.null(out)) return(data.frame())
    out
  }
}
