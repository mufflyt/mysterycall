#' Publication-ready model comparison table
#'
#' @name mysterycall_model_comparison_table
NULL

#' Compare fitted models: AIC, BIC, overdispersion, and theta
#'
#' Takes a named list of fitted `mysterycall_poisson_model` and/or
#' `mysterycall_nb_model` objects and produces a formatted comparison table
#' suitable for inclusion in a manuscript. Columns include AIC, BIC, their
#' deltas, Pearson overdispersion (phi), and the NB dispersion parameter
#' (theta). The winning model is marked with `"*"`.
#'
#' @param models A named list (length >= 2) of model objects. Each element
#'   must be a `mysterycall_poisson_model` or `mysterycall_nb_model`.
#' @param criterion Character vector. The first element (`"aic"` or `"bic"`)
#'   determines which criterion selects the winner. Default `c("aic", "bic")`.
#' @param digits Integer. Decimal places for AIC, BIC, and phi columns.
#'   Default `1L`.
#'
#' @return A data frame with columns `Model`, `Family`, `N`, `Params`,
#'   `AIC`, `BIC`, `ΔAIC`, `ΔBIC`, `Phi (Pearson)`, `Theta`, `Winner`.
#'   `Winner` is `"*"` for the best model under `criterion[1]` and `""`
#'   otherwise. The data frame carries an attribute `"winner"` with the
#'   winning model name.
#'
#' @family manuscript
#' @seealso [mysterycall_select_best_model()] for a simpler AIC/BIC/LRT
#'   comparison; [mysterycall_auto_model()] for automatic model selection.
#' @export
#'
#' @examplesIf interactive()
#' tbl <- mysterycall_model_comparison_table(
#'   list(
#'     "Base model"  = poisson_fit,
#'     "+ Setting"   = poisson_fit2,
#'     "NB full"     = nb_fit
#'   )
#' )
#' print(tbl)
mysterycall_model_comparison_table <- function(models,
                                                criterion = c("aic", "bic"),
                                                digits    = 1L) {

  if (!is.list(models) || is.null(names(models)) || length(models) < 2L)
    stop("`models` must be a named list with at least 2 elements.", call. = FALSE)

  valid_classes <- c("mysterycall_poisson_model", "mysterycall_nb_model")
  bad <- vapply(models, function(m) !inherits(m, valid_classes), logical(1L))
  if (any(bad))
    stop("All elements of `models` must be `mysterycall_poisson_model` or ",
         "`mysterycall_nb_model`. Bad elements: ",
         paste(names(models)[bad], collapse = ", "), ".", call. = FALSE)

  criterion <- match.arg(criterion)
  digits    <- as.integer(digits)

  rows <- lapply(names(models), function(nm) {
    m <- models[[nm]]

    family_str <- if (inherits(m, "mysterycall_nb_model")) "Negative Binomial" else "Poisson"

    n_obs <- tryCatch({
      if (!is.null(m$n_obs)) {
        as.integer(m$n_obs)
      } else if (!is.null(m$model)) {
        fit <- m$model
        as.integer(tryCatch(nrow(fit@frame),
          error = function(e) tryCatch(fit$modelInfo$nobs,
            error = function(e2) NA_integer_)))
      } else {
        NA_integer_
      }
    }, error = function(e) NA_integer_)

    n_params <- tryCatch(nrow(m$irr_table), error = function(e) NA_integer_)

    aic_val <- tryCatch({
      if (!is.null(m$aic)) as.numeric(m$aic)
      else AIC(m$model)
    }, error = function(e) NA_real_)

    bic_val <- tryCatch({
      if (!is.null(m$bic)) as.numeric(m$bic)
      else BIC(m$model)
    }, error = function(e) NA_real_)

    phi_val   <- tryCatch(as.numeric(m$overdispersion), error = function(e) NA_real_)
    theta_val <- tryCatch(as.numeric(m$theta),          error = function(e) NA_real_)

    data.frame(
      Model       = nm,
      Family      = family_str,
      N           = n_obs,
      Params      = n_params,
      AIC         = aic_val,
      BIC         = bic_val,
      Phi_Pearson = phi_val,
      Theta       = theta_val,
      stringsAsFactors = FALSE
    )
  })

  tbl <- do.call(rbind, rows)
  rownames(tbl) <- NULL

  tbl[["ΔAIC"]] <- tbl$AIC - min(tbl$AIC, na.rm = TRUE)
  tbl[["ΔBIC"]] <- tbl$BIC - min(tbl$BIC, na.rm = TRUE)

  score_col <- if (criterion == "bic") "BIC" else "AIC"
  best_idx  <- which.min(tbl[[score_col]])
  winner_nm <- tbl$Model[best_idx]
  tbl$Winner <- ifelse(seq_len(nrow(tbl)) == best_idx, "*", "")

  fmt <- paste0("%.", digits, "f")
  tbl$AIC         <- sprintf(fmt, tbl$AIC)
  tbl$BIC         <- sprintf(fmt, tbl$BIC)
  tbl[["ΔAIC"]]   <- sprintf(fmt, tbl[["ΔAIC"]])
  tbl[["ΔBIC"]]   <- sprintf(fmt, tbl[["ΔBIC"]])
  tbl$Phi_Pearson <- ifelse(is.na(tbl$Phi_Pearson), NA_character_, sprintf(fmt, tbl$Phi_Pearson))
  tbl$Theta       <- ifelse(is.na(tbl$Theta),       NA_character_, sprintf(fmt, tbl$Theta))

  names(tbl)[names(tbl) == "Phi_Pearson"] <- "Phi (Pearson)"

  attr(tbl, "winner") <- winner_nm
  tbl
}


#' Print method for model comparison table
#'
#' @param x Data frame returned by [mysterycall_model_comparison_table()].
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family manuscript
#' @export
print.mysterycall_model_comparison_table <- function(x, ...) {
  cat(sprintf("Model comparison (winner: %s)\n\n", attr(x, "winner")))
  print(format(x), row.names = FALSE)
  invisible(x)
}
