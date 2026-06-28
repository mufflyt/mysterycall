#' Sensitivity analysis across data subsets
#'
#' @name mysterycall_sensitivity
NULL

#' Run sensitivity analyses by re-fitting a model across data subsets
#'
#' Re-runs the same model specification across subsets of the data - e.g.
#' stratified by practice setting or geographic region, or excluding
#' zero-wait observations. Returns a combined table comparing IRRs across
#' subsets so the stability of the primary result can be assessed.
#'
#' @param data A data frame containing all model columns.
#' @param outcome Character scalar naming the count outcome column.
#' @param predictors Character vector of fixed-effect predictor column names.
#' @param random_intercept Character scalar naming the random-intercept
#'   grouping column.
#' @param subset_var Character scalar naming a column whose unique levels
#'   each define one subset. Pass `NULL` (default) to skip stratification.
#' @param exclude_zeros Logical. If `TRUE`, an additional subset excluding
#'   rows where `outcome == 0` is added. Default `FALSE`.
#' @param family One of `"auto"` (default), `"poisson"`, or `"nb"` (negative
#'   binomial). `"auto"` fits Poisson first and switches to NB if Pearson
#'   phi > `phi_threshold`.
#' @param ref_group Character scalar. Label for the reference group used in
#'   manuscript sentences. Passed to [mysterycall_irr_to_days()] when
#'   `baseline_mean` is supplied. Default `NULL`.
#' @param baseline_mean Numeric scalar. If supplied, an absolute days
#'   difference column is added: `days_diff = baseline_mean * (IRR - 1)`.
#' @param conf_level Numeric. Confidence level for Wald CIs. Default `0.95`.
#' @param phi_threshold Numeric. Pearson phi above which `"auto"` switches to
#'   NB. Default `2.0`.
#' @param ... Additional arguments forwarded to the model-fitting function.
#'
#' @return A list of class `mysterycall_sensitivity` with elements:
#' \describe{
#'   \item{`table`}{Data frame with columns `subset_name`, `term`, `IRR`,
#'     `ci_lower`, `ci_upper`, `p_value`, `model_type`, and (if
#'     `baseline_mean` supplied) `days_diff`.}
#'   \item{`models`}{Named list of fitted model objects, one per subset.}
#'   \item{`subsets_run`}{Character vector of subset names that were
#'     successfully analysed.}
#'   \item{`family`}{The `family` argument that was used.}
#' }
#'
#' @family outcomes
#' @seealso [mysterycall_auto_model()], [mysterycall_poisson_model()],
#'   [mysterycall_nb_model()]
#' @export
#'
#' @examplesIf requireNamespace("lme4", quietly = TRUE)
#' set.seed(42)
#' df <- data.frame(
#'   wait    = rpois(80, 18),
#'   ins     = rep(c("Medicaid", "BCBS"), 40),
#'   setting = rep(c("Academic", "Private", "Academic", "Private"), 20),
#'   phys    = rep(paste0("Dr", 1:20), each = 4),
#'   stringsAsFactors = FALSE
#' )
#' res <- mysterycall_sensitivity(
#'   df, "wait", "ins", "phys",
#'   subset_var = "setting",
#'   family     = "poisson"
#' )
#' print(res)
mysterycall_sensitivity <- function(data,
                                     outcome,
                                     predictors,
                                     random_intercept,
                                     subset_var    = NULL,
                                     exclude_zeros = FALSE,
                                     family        = c("auto", "poisson", "nb"),
                                     ref_group     = NULL,
                                     baseline_mean = NULL,
                                     conf_level    = 0.95,
                                     phi_threshold = 2.0,
                                     ...) {

  if (!is.data.frame(data))
    stop(sprintf("`data` must be a data frame, not %s.", class(data)[1L]), call. = FALSE)
  if (!is.character(outcome) || length(outcome) != 1L)
    stop("`outcome` must be a single character string naming a column in `data`.", call. = FALSE)
  if (!outcome %in% names(data))
    stop(sprintf(
      "`outcome` column '%s' not found in `data`.\nAvailable columns: %s",
      outcome, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  if (!is.character(predictors) || length(predictors) == 0L)
    stop("`predictors` must be a non-empty character vector of column names.", call. = FALSE)
  {
    bad_pred <- setdiff(predictors, names(data))
    if (length(bad_pred))
      stop(sprintf(
        "`predictors` column(s) not found in `data`: %s\nAvailable columns: %s",
        paste(bad_pred, collapse = ", "), paste(names(data), collapse = ", ")
      ), call. = FALSE)
  }
  if (!is.character(random_intercept) || length(random_intercept) != 1L)
    stop("`random_intercept` must be a single character string naming a column in `data`.", call. = FALSE)
  if (!random_intercept %in% names(data))
    stop(sprintf(
      "`random_intercept` column '%s' not found in `data`.\nAvailable columns: %s",
      random_intercept, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  if (!is.null(baseline_mean) &&
      (!is.numeric(baseline_mean) || length(baseline_mean) != 1L || baseline_mean <= 0))
    stop("`baseline_mean` must be a single positive number (e.g. the reference group mean wait time).", call. = FALSE)

  family <- match.arg(family)

  subsets <- list("Full sample" = data)

  if (isTRUE(exclude_zeros)) {
    nz <- data[!is.na(data[[outcome]]) & data[[outcome]] > 0, , drop = FALSE]
    if (nrow(nz) >= 10L) {
      subsets[["Exclude zeros"]] <- nz
    } else {
      warning("Subset 'Exclude zeros' has < 10 rows; skipped.", call. = FALSE)
    }
  }

  if (!is.null(subset_var)) {
    if (!is.character(subset_var) || length(subset_var) != 1L ||
        !subset_var %in% names(data)) {
      warning("`subset_var` not found in `data`; stratification skipped.", call. = FALSE)
    } else {
      levels_sv <- sort(unique(as.character(data[[subset_var]][!is.na(data[[subset_var]])])))
      for (lvl in levels_sv) {
        sub_df <- data[!is.na(data[[subset_var]]) & data[[subset_var]] == lvl, , drop = FALSE]
        if (nrow(sub_df) < 10L) {
          warning(sprintf("Subset '%s' has < 10 rows; skipped.", lvl), call. = FALSE)
          next
        }
        subsets[[lvl]] <- sub_df
      }
    }
  }

  results_list <- vector("list", length(subsets))
  model_list   <- vector("list", length(subsets))
  names(results_list) <- names(subsets)
  names(model_list)   <- names(subsets)
  subsets_run  <- character(0L)

  for (sname in names(subsets)) {
    sdata <- subsets[[sname]]

    fit <- tryCatch(
      withCallingHandlers({
      if (family == "poisson") {
        mysterycall_poisson_model(
          data             = sdata,
          outcome          = outcome,
          predictors       = predictors,
          random_intercept = random_intercept,
          conf_level       = conf_level,
          ...
        )
      } else if (family == "nb") {
        if (!requireNamespace("glmmTMB", quietly = TRUE))
          stop(
            "family = 'nb' requires the glmmTMB package.\n",
            "Install it with: install.packages(\"glmmTMB\")",
            call. = FALSE
          )
        mysterycall_nb_model(
          data             = sdata,
          outcome          = outcome,
          predictors       = predictors,
          random_intercept = random_intercept,
          conf_level       = conf_level,
          ...
        )
      } else {
        suppressMessages(suppressWarnings(
          mysterycall_auto_model(
            data             = sdata,
            outcome          = outcome,
            predictors       = predictors,
            random_intercept = random_intercept,
            conf_level       = conf_level,
            phi_threshold    = phi_threshold,
            ...
          )
        ))
      }
    }, warning = function(w) {
      if (grepl(
        "singular|convergence|Singular|Convergence|random.intercept variance|random-intercept variance",
        conditionMessage(w),
        ignore.case = TRUE
      )) {
        invokeRestart("muffleWarning")
      }
    }),
    error = function(e) {
      warning(sprintf("Model fit failed for subset '%s': %s", sname, conditionMessage(e)),
              call. = FALSE)
      NULL
    })

    if (is.null(fit)) {
      na_row <- data.frame(
        subset_name = sname,
        term        = NA_character_,
        IRR         = NA_real_,
        ci_lower    = NA_real_,
        ci_upper    = NA_real_,
        p_value     = NA_real_,
        model_type  = NA_character_,
        stringsAsFactors = FALSE
      )
      results_list[[sname]] <- na_row
      next
    }

    model_list[[sname]] <- fit
    subsets_run <- c(subsets_run, sname)

    model_type <- if (inherits(fit, "mysterycall_nb_model")) "negative_binomial" else "poisson"

    irr_tbl <- fit$irr_table

    if (length(predictors) == 1L) {
      irr_tbl <- irr_tbl[startsWith(as.character(irr_tbl$term), predictors[1L]), , drop = FALSE]
    } else {
      irr_tbl <- irr_tbl[irr_tbl$term != "(Intercept)", , drop = FALSE]
    }

    row_df <- data.frame(
      subset_name = sname,
      term        = as.character(irr_tbl$term),
      IRR         = as.numeric(irr_tbl$irr),
      ci_lower    = as.numeric(irr_tbl$ci_lower),
      ci_upper    = as.numeric(irr_tbl$ci_upper),
      p_value     = as.numeric(irr_tbl$p_value),
      model_type  = model_type,
      stringsAsFactors = FALSE
    )
    results_list[[sname]] <- row_df
  }

  combined <- do.call(rbind, results_list)
  rownames(combined) <- NULL

  if (!is.null(baseline_mean) && !is.null(combined)) {
    combined$days_diff <- baseline_mean * (combined$IRR - 1)
  }

  structure(
    list(
      table       = combined,
      models      = model_list[subsets_run],
      subsets_run = subsets_run,
      family      = family
    ),
    class = "mysterycall_sensitivity"
  )
}


#' Print method for mysterycall_sensitivity
#'
#' @param x A `mysterycall_sensitivity` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_sensitivity <- function(x, ...) {
  cat(sprintf(
    "Sensitivity analysis (%d subsets, family = %s)\n\n",
    length(x$subsets_run), x$family
  ))
  print(x$table, row.names = FALSE)
  invisible(x)
}
