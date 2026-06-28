#' Evaluate prediction accuracy for a fitted mysterycall model
#'
#' @name model_mae_rmse
NULL

#' Compute MAE, RMSE, Pearson R\ifelse{html}{\out{<sup>2</sup>}}{\eqn{^2}}, and MAPE for a fitted model
#'
#' Evaluates prediction accuracy for any fitted [`mysterycall_lmm`],
#' [`mysterycall_poisson_model`], or [`mysterycall_nb_model`] object by
#' comparing actual outcome values against in-sample or out-of-sample
#' predictions. Optionally back-transforms predictions from a log scale and
#' produces an actual-vs-predicted scatter plot with a 45-degree reference line.
#'
#' **When to use:**
#' After fitting a model with [mysterycall_lmm()], [mysterycall_poisson_model()],
#' or [mysterycall_nb_model()], call this function to quantify how closely the
#' fitted values track the observed outcomes. Useful for model comparison and
#' for reporting prediction accuracy in the methods section.
#'
#' **Back-transformation for log-transformed LMM:**
#' When the LMM was fitted on a `log1p()`-transformed outcome
#' (`fit$log_transformed = TRUE`), `back_transform` is automatically set to
#' `TRUE`. Predictions from `predict()` are on the log scale; `exp()` is
#' applied before computing errors, so MAE and RMSE are reported in the units
#' of the original outcome (days). Actual values stored in the model frame are
#' also on the log scale and receive the same `exp()` back-transform for a
#' consistent comparison.
#'
#' @param fit A `mysterycall_lmm`, `mysterycall_poisson_model`, or
#'   `mysterycall_nb_model` object returned by [mysterycall_lmm()],
#'   [mysterycall_poisson_model()], or [mysterycall_nb_model()], respectively.
#' @param newdata A `data.frame` or `NULL`. If `NULL` (default), in-sample
#'   predictions are computed using the training data stored in the model
#'   object. If a data frame is supplied, out-of-sample predictions are
#'   generated via `predict(fit$model, newdata = newdata, ...)`.
#' @param actual_col Character scalar or `NULL`. Name of the outcome column.
#'   If `NULL` (default), the column name is extracted automatically from the
#'   left-hand side of `fit$formula`. For a log-transformed LMM with
#'   `newdata` supplied, the column must be the *transformed* outcome column
#'   (e.g., `"log1p_wait_days"`) unless you pass `actual_col` explicitly.
#' @param back_transform Logical scalar or `NULL`. When `TRUE`, predictions and
#'   actual values are back-transformed via `exp()` before computing errors,
#'   which places MAE and RMSE on the original (untransformed) scale. When
#'   `NULL` (default), auto-detected: `TRUE` if `fit$log_transformed` is
#'   `TRUE` (LMM with log scale), `FALSE` otherwise. Setting this explicitly
#'   overrides the auto-detection.
#' @param conf_level Numeric. Reserved for future prediction-interval coverage
#'   calculations. Default `0.95`. Must be in `(0, 1)`.
#' @param plot Logical. If `TRUE` (default) and \pkg{ggplot2} is available,
#'   an actual-vs-predicted scatter plot is created, printed to the active
#'   graphics device, and stored in `$plot`. If `ggplot2` is not installed a
#'   message is emitted and `$plot` is `NULL`.
#' @param plot_title Character scalar or `NULL`. Title for the plot. When
#'   `NULL` (default), a title is auto-generated from the model class.
#'
#' @return A list of class `mysterycall_model_mae_rmse` with elements:
#' \describe{
#'   \item{`mae`}{`numeric`. Mean absolute error on the (back-transformed)
#'     scale.}
#'   \item{`rmse`}{`numeric`. Root mean squared error on the (back-transformed)
#'     scale.}
#'   \item{`r2_pearson`}{`numeric`. Pearson \eqn{R^2} = squared correlation
#'     between actual and predicted values.}
#'   \item{`mape`}{`numeric`. Mean absolute percentage error (percent). Rows
#'     where `actual == 0` are excluded. `NA` when all actual values are zero.}
#'   \item{`n`}{`integer`. Number of observations used (after removing `NA`
#'     pairs).}
#'   \item{`predictions`}{`data.frame`. One row per observation with columns
#'     `actual`, `predicted`, and `residual` (= actual - predicted), all on
#'     the (back-transformed) scale.}
#'   \item{`plot`}{`ggplot` or `NULL`. The actual-vs-predicted scatter plot, or
#'     `NULL` when `plot = FALSE` or \pkg{ggplot2} is unavailable.}
#'   \item{`sentence`}{`character`. Ready-to-paste summary sentence, e.g.:
#'     `"Model MAE = 3.2 days, RMSE = 4.5 days, R2 = 0.81, MAPE = 12.3% (N=80)."`}
#' }
#'
#' @section Metrics:
#' \describe{
#'   \item{MAE}{`mean(|actual - predicted|)`. Scale-dependent; same units as
#'     the outcome.}
#'   \item{RMSE}{`sqrt(mean((actual - predicted)^2))`. More sensitive to large
#'     errors than MAE.}
#'   \item{R2 (Pearson)}{`cor(actual, predicted)^2`. Measures linear agreement;
#'     does **not** equal the model's marginal R^2.}
#'   \item{MAPE}{`mean(|actual - predicted| / |actual|) * 100`. Unit-free
#'     percentage; undefined when actual = 0.}
#' }
#'
#' @section Out-of-sample use:
#' Pass `newdata` for external validation. The grouping variable (random
#' intercept) should be present in `newdata` so that `lme4` / \pkg{glmmTMB}
#' can condition on estimated BLUPs; pass it as `re.form = NA` (via
#' `predict()` directly) for pure population-level predictions.
#'
#' @importFrom stats predict cor model.frame
#' @family outcomes
#' @seealso [mysterycall_lmm()], [mysterycall_poisson_model()],
#'   [mysterycall_nb_model()]
#' @export
#'
#' @examples
#' \donttest{
#' # Demonstrate the print method on a pre-built result object
#' # (no lme4 required).
#' fake_result <- structure(
#'   list(
#'     mae        = 3.2,
#'     rmse       = 4.5,
#'     r2_pearson = 0.81,
#'     mape       = 12.3,
#'     n          = 80L,
#'     predictions = data.frame(
#'       actual    = c(20.0, 25.0, 18.0),
#'       predicted = c(18.3, 27.1, 19.5),
#'       residual  = c( 1.7, -2.1, -1.5),
#'       stringsAsFactors = FALSE
#'     ),
#'     plot     = NULL,
#'     sentence = paste0(
#'       "Model MAE = 3.2 days, RMSE = 4.5 days, ",
#'       "R2 = 0.81, MAPE = 12.3% (N=80)."
#'     )
#'   ),
#'   class = "mysterycall_model_mae_rmse"
#' )
#' print(fake_result)
#' }
mysterycall_model_mae_rmse <- function(fit,
                                       newdata        = NULL,
                                       actual_col     = NULL,
                                       back_transform = NULL,
                                       conf_level     = 0.95,
                                       plot           = TRUE,
                                       plot_title     = NULL) {

  # -- Validate fit class ----------------------------------------------------------
  valid_classes <- c(
    "mysterycall_lmm",
    "mysterycall_poisson_model",
    "mysterycall_nb_model"
  )
  model_class <- class(fit)[[1L]]
  if (!model_class %in% valid_classes) {
    stop(
      sprintf(
        "`fit` must be one of: %s. Got class: '%s'.",
        paste(valid_classes, collapse = ", "),
        model_class
      ),
      call. = FALSE
    )
  }

  # -- Validate conf_level ---------------------------------------------------------
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1) {
    stop("`conf_level` must be a single number in (0, 1).", call. = FALSE)
  }

  # -- Auto-detect back_transform --------------------------------------------------
  if (is.null(back_transform)) {
    back_transform <- isTRUE(fit$log_transformed)
  }
  if (!is.logical(back_transform) || length(back_transform) != 1L ||
      is.na(back_transform)) {
    stop("`back_transform` must be a single non-NA logical (TRUE or FALSE).",
         call. = FALSE)
  }

  # -- Validate plot_title ---------------------------------------------------------
  if (!is.null(plot_title) &&
      (!is.character(plot_title) || length(plot_title) != 1L)) {
    stop("`plot_title` must be a single character string or NULL.", call. = FALSE)
  }

  # -- Auto-extract actual_col from formula LHS ------------------------------------
  if (is.null(actual_col)) {
    actual_col <- tryCatch(
      as.character(fit$formula[[2L]]),
      error = function(e) {
        stop(
          "Cannot extract outcome column name from fit$formula. ",
          "Supply `actual_col` explicitly.",
          call. = FALSE
        )
      }
    )
  }
  if (!is.character(actual_col) || length(actual_col) != 1L) {
    stop("`actual_col` must be a single character string.", call. = FALSE)
  }

  # -- Determine in-sample vs out-of-sample ----------------------------------------
  in_sample <- is.null(newdata)

  if (!in_sample) {
    if (!is.data.frame(newdata)) {
      stop("`newdata` must be a data.frame or NULL.", call. = FALSE)
    }
    if (!actual_col %in% names(newdata)) {
      stop(
        sprintf(
          "`actual_col` '%s' not found in `newdata`. ",
          actual_col
        ),
        "Check the column name or supply `actual_col` explicitly.",
        call. = FALSE
      )
    }
  }

  # -- Retrieve model frame for in-sample case ------------------------------------
  if (in_sample) {
    data_used <- tryCatch(
      stats::model.frame(fit$model),
      error = function(e) {
        # Fallback 1: S4 @frame slot (lme4 lmerMod / glmerMod)
        tryCatch(
          fit$model@frame,
          error = function(e2) {
            # Fallback 2: S3 $frame slot (glmmTMB)
            tryCatch(
              fit$model$frame,
              error = function(e3) {
                stop(
                  "Cannot extract the model data frame from fit$model. ",
                  "Provide `newdata` explicitly.",
                  call. = FALSE
                )
              }
            )
          }
        )
      }
    )

    if (!actual_col %in% names(data_used)) {
      stop(
        sprintf(
          "Outcome column '%s' not found in the model frame. ",
          actual_col
        ),
        "This can happen when `actual_col` does not match the formula LHS. ",
        "Provide `actual_col` or `newdata` explicitly.",
        call. = FALSE
      )
    }
    actual_raw <- data_used[[actual_col]]
  } else {
    actual_raw <- newdata[[actual_col]]
  }

  if (!is.numeric(actual_raw)) {
    stop(
      sprintf("Outcome column '%s' must be numeric.", actual_col),
      call. = FALSE
    )
  }

  # -- Generate predictions --------------------------------------------------------
  predicted_raw <- tryCatch({
    if (in_sample) {
      if (model_class == "mysterycall_lmm") {
        # lmerMod: predict() returns values on the modelled (possibly log) scale.
        # type = "response" is valid for merMod but redundant for Gaussian;
        # re.form = NULL conditions on all estimated random effects (BLUP).
        stats::predict(fit$model, re.form = NULL, type = "response")
      } else {
        # glmerMod (Poisson) and glmmTMB (NB): type = "response" ensures
        # predictions are on the count scale rather than the log-link scale.
        stats::predict(fit$model, type = "response", re.form = NULL)
      }
    } else {
      if (model_class == "mysterycall_lmm") {
        stats::predict(fit$model, newdata = newdata,
                       re.form = NULL, type = "response")
      } else {
        stats::predict(fit$model, newdata = newdata,
                       type = "response", re.form = NULL)
      }
    }
  }, error = function(e) {
    stop(
      sprintf(
        "predict() failed for a '%s' object: %s",
        model_class, e$message
      ),
      call. = FALSE
    )
  })

  predicted_raw <- as.numeric(predicted_raw)

  if (length(predicted_raw) != length(actual_raw)) {
    stop(
      sprintf(
        "Length mismatch: %d actual values vs %d predictions.",
        length(actual_raw), length(predicted_raw)
      ),
      call. = FALSE
    )
  }

  # -- Back-transform via exp() ---------------------------------------------------
  # When back_transform = TRUE (auto-set for LMM with log_transformed = TRUE),
  # both the log-scale predictions from predict() and the log-scale actual values
  # stored in the model frame are exponentiated so that MAE / RMSE are reported
  # in the units of the original outcome (days).
  if (back_transform) {
    actual    <- exp(actual_raw)
    predicted <- exp(predicted_raw)
  } else {
    actual    <- actual_raw
    predicted <- predicted_raw
  }

  # -- Drop NA pairs ---------------------------------------------------------------
  complete_mask <- !is.na(actual) & !is.na(predicted)
  n_na <- sum(!complete_mask)
  if (!any(complete_mask)) {
    stop("No complete actual/predicted pairs remain after removing NAs.", call. = FALSE)
  }
  if (n_na > 0L) {
    warning(
      sprintf("%d observation(s) with NA actual or predicted values were excluded.", n_na),
      call. = FALSE
    )
  }
  actual    <- actual[complete_mask]
  predicted <- predicted[complete_mask]
  n_obs     <- length(actual)

  # -- Metrics --------------------------------------------------------------------
  residuals_vec <- actual - predicted

  mae        <- mean(abs(residuals_vec))
  rmse       <- sqrt(mean(residuals_vec^2))
  r2_pearson <- stats::cor(actual, predicted)^2

  nonzero    <- actual != 0
  mape <- if (any(nonzero)) {
    mean(abs(residuals_vec[nonzero] / actual[nonzero])) * 100
  } else {
    NA_real_
  }
  if (!all(nonzero)) {
    warning(
      sprintf(
        "%d zero value(s) in actual excluded from MAPE (division by zero).",
        sum(!nonzero)
      ),
      call. = FALSE
    )
  }

  # -- Predictions data.frame -----------------------------------------------------
  pred_df <- data.frame(
    actual    = actual,
    predicted = predicted,
    residual  = residuals_vec,
    stringsAsFactors = FALSE
  )

  # -- Summary sentence ------------------------------------------------------------
  mape_clause <- if (!is.na(mape)) sprintf(", MAPE = %.1f%%", mape) else ""
  sentence <- sprintf(
    "Model MAE = %.1f days, RMSE = %.1f days, R2 = %.2f%s (N=%d).",
    mae, rmse, r2_pearson, mape_clause, n_obs
  )

  # -- Auto plot title ------------------------------------------------------------
  if (is.null(plot_title)) {
    model_label <- switch(
      model_class,
      mysterycall_lmm           = "LMM",
      mysterycall_poisson_model = "Poisson GLMM",
      mysterycall_nb_model      = "Negative Binomial GLMM",
      "Model"
    )
    bt_suffix <- if (back_transform) " (back-transformed via exp())" else ""
    plot_title <- sprintf("Actual vs. Predicted: %s%s", model_label, bt_suffix)
  }

  # -- Build ggplot ---------------------------------------------------------------
  gg <- NULL
  if (isTRUE(plot)) {
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
      message(
        "Package 'ggplot2' not available; plot skipped. ",
        "Install with: install.packages('ggplot2')"
      )
    } else {
      # Place annotation in the upper-left corner (low predicted, high actual)
      x_rng   <- range(predicted, na.rm = TRUE)
      y_rng   <- range(actual,    na.rm = TRUE)
      ann_x   <- x_rng[[1L]] + 0.03 * diff(x_rng)
      ann_y   <- y_rng[[2L]] - 0.03 * diff(y_rng)
      ann_lab <- sprintf(
        "MAE  = %.2f\nRMSE = %.2f\nR\u00b2   = %.3f",
        mae, rmse, r2_pearson
      )

      gg <- ggplot2::ggplot(
          pred_df,
          ggplot2::aes(x = .data$predicted, y = .data$actual)
        ) +
        ggplot2::geom_point(alpha = 0.65, size = 2) +
        ggplot2::geom_abline(
          slope     = 1,
          intercept = 0,
          linetype  = "dashed",
          color     = "red",
          linewidth = 0.9
        ) +
        ggplot2::annotate(
          geom  = "text",
          x     = ann_x,
          y     = ann_y,
          label = ann_lab,
          hjust = 0,
          vjust = 1,
          size  = 3.5,
          family = "mono"
        ) +
        ggplot2::labs(
          title    = plot_title,
          subtitle = sprintf(
            "N = %d%s",
            n_obs,
            if (back_transform) "; predictions back-transformed via exp()" else ""
          ),
          x = "Predicted",
          y = "Actual"
        ) +
        ggplot2::theme_bw()

      print(gg)
    }
  }

  # -- Return result --------------------------------------------------------------
  structure(
    list(
      mae        = mae,
      rmse       = rmse,
      r2_pearson = r2_pearson,
      mape       = mape,
      n          = n_obs,
      predictions = pred_df,
      plot       = gg,
      sentence   = sentence
    ),
    class = "mysterycall_model_mae_rmse"
  )
}


#' Print method for mysterycall_model_mae_rmse objects
#'
#' Prints the one-sentence accuracy summary followed by a five-number summary
#' of the predictions data frame (actual, predicted, and residuals).
#'
#' @param x A `mysterycall_model_mae_rmse` object returned by
#'   [mysterycall_model_mae_rmse()].
#' @param digits Integer. Decimal places for the predictions summary.
#'   Default `3`.
#' @param ... Ignored; present for S3 consistency.
#'
#' @return `invisible(x)`.
#' @family outcomes
#' @export
#'
#' @examples
#' \donttest{
#' fake_result <- structure(
#'   list(
#'     mae        = 3.2,
#'     rmse       = 4.5,
#'     r2_pearson = 0.81,
#'     mape       = 12.3,
#'     n          = 80L,
#'     predictions = data.frame(
#'       actual    = c(20.0, 25.0, 18.0),
#'       predicted = c(18.3, 27.1, 19.5),
#'       residual  = c( 1.7, -2.1, -1.5),
#'       stringsAsFactors = FALSE
#'     ),
#'     plot     = NULL,
#'     sentence = paste0(
#'       "Model MAE = 3.2 days, RMSE = 4.5 days, ",
#'       "R2 = 0.81, MAPE = 12.3% (N=80)."
#'     )
#'   ),
#'   class = "mysterycall_model_mae_rmse"
#' )
#' print(fake_result)
#' }
print.mysterycall_model_mae_rmse <- function(x, digits = 3, ...) {
  cat(x$sentence, "\n\n")
  cat(sprintf("N = %d observations\n", x$n))
  if (!is.na(x$mape)) {
    cat(sprintf("MAPE = %.1f%%\n", x$mape))
  } else {
    cat("MAPE = NA (one or more actual values are zero)\n")
  }
  cat("\nPredictions (actual, predicted, residual):\n")
  print(summary(round(x$predictions, digits)), ...)
  invisible(x)
}
