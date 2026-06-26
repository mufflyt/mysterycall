#' Compute average marginal effects for a Poisson GLM or GLMER
#'
#' @name mysterycall_marginal_effects
NULL

#' Compute average marginal effects (AME) for a Poisson model
#'
#' Computes average marginal effects for each predictor in a fitted Poisson
#' GLM (`glm` with `family = poisson`) or Poisson GLMER (`glmerMod` from
#' lme4). Also accepts a `mysterycall_poisson_model` object, from which
#' the fitted model is extracted automatically.
#'
#' For continuous predictors, the AME is estimated by numerical
#' differentiation: predicted values are computed at the predictor bumped up
#' and down by `eps`, and the average finite-difference derivative is
#' returned. For factor (categorical) predictors, the AME for each non-reference
#' level is the average difference in predicted values between that level and
#' the reference level, holding all other predictors constant.
#'
#' Standard errors and confidence intervals are NOT computed by this function.
#' Use [mysterycall_bootstrap_ci()] for bootstrap-based confidence intervals.
#'
#' @param model A fitted `glm` (with `family = poisson`), a `glmerMod` object
#'   from lme4, a `mysterycall_poisson_model`, or a `mysterycall_nb_model`
#'   object. For wrapper objects the `$model` component is extracted
#'   automatically. For `mysterycall_nb_model` (glmmTMB), average marginal
#'   effects are computed via [marginaleffects::avg_slopes()] and the result is
#'   coerced into the standard `term` / `level` / `ame` / `variable_type`
#'   data frame returned by this function.
#' @param term Character vector of predictor names for which to compute
#'   marginal effects. Pass the variable name (e.g. `"cyl"`), not the
#'   dummy-encoded column name (e.g. `"factor(cyl)6"`). If `NULL` (default),
#'   effects are computed for all predictors in the model frame.
#' @param data Optional data frame to use instead of the stored model data.
#'   Columns must use the original (un-transformed) variable names. If `NULL`
#'   (default), the data used to fit the model is retrieved automatically.
#' @param type Character scalar, either `"response"` (default) or `"link"`.
#'   Passed to `stats::predict()`. For lme4 models, population-average
#'   predictions (`re.form = NA`) are always used.
#' @param eps Positive numeric scalar. Step size for numerical differentiation
#'   of continuous predictors. Default `1e-7`.
#'
#' @return A `data.frame` with one row per term-level combination and columns:
#' \describe{
#'   \item{`term`}{Character. The predictor name (as supplied in `term` or
#'     derived from the model frame). Continuous predictors yield one row;
#'     categorical predictors yield one row per non-reference level.}
#'   \item{`level`}{Character or `NA_character_`. `NA_character_` for
#'     continuous predictors; the factor level name for categorical predictors.
#'     The reference level is omitted from the output.}
#'   \item{`ame`}{Numeric. The average marginal effect. For continuous
#'     predictors, the mean finite-difference derivative across all
#'     observations. For categorical predictors, the mean difference in
#'     predicted values versus the reference level.}
#'   \item{`variable_type`}{Character. Either `"continuous"` or
#'     `"categorical"`.}
#' }
#' Row names are not set. No special class attributes are added.
#'
#' @section Standard errors:
#' This function returns only the AME point estimate. Standard errors and
#' confidence intervals require a bootstrap procedure; see
#' `mysterycall_bootstrap_ci()`.
#'
#' @section lme4 models:
#' For `glmerMod` objects, predictions use `re.form = NA` so that the
#' marginal effect is averaged over the population (not conditional on
#' estimated random effects). The lme4 package must be installed.
#'
#' @section Formulas with in-line transformations:
#' When a formula contains in-line calls such as `factor(cyl)`, pass the
#' underlying variable name (`"cyl"`) to `term`, not the transformed name.
#' The function resolves the original column automatically.
#'
#' @param ... Additional arguments forwarded to [marginaleffects::avg_slopes()]
#'   for negative-binomial model wrappers.
#' @importFrom stats model.frame model.matrix predict formula terms
#' @family outcomes
#' @seealso [mysterycall_poisson_model()], [mysterycall_model_metrics()],
#'   [marginaleffects::avg_slopes()] for direct use with glmmTMB NB models.
#' @export
#'
#' @examples
#' m <- glm(vs ~ wt + factor(cyl), data = mtcars, family = poisson())
#' mysterycall_marginal_effects(m)
#' mysterycall_marginal_effects(m, term = "wt")
#' mysterycall_marginal_effects(m, term = "cyl")
mysterycall_marginal_effects <- function(model,
                                         term  = NULL,
                                         data  = NULL,
                                         type  = c("response", "link"),
                                         eps   = 1e-7,
                                         ...) {

  type <- match.arg(type)

  # -- Unwrap package model objects --------------------------------------------
  if (inherits(model, "mysterycall_nb_model")) {
    if (!requireNamespace("marginaleffects", quietly = TRUE)) {
      stop(
        "Package 'marginaleffects' is required for NB models. ",
        "Install with: install.packages('marginaleffects')",
        call. = FALSE
      )
    }
    fit <- model$model
    me_args <- list(fit)
    if (!is.null(term)) me_args$variables <- term
    raw <- do.call(marginaleffects::avg_slopes, c(me_args, list(...)))
    raw_df <- as.data.frame(raw)

    # Detect variable type from the bare model frame
    mf_nb <- tryCatch(fit$frame, error = function(e) NULL)
    .vtype <- function(trm) {
      if (!is.null(mf_nb) && trm %in% names(mf_nb)) {
        cls <- class(mf_nb[[trm]])[1L]
        if (cls %in% c("factor", "character", "ordered")) return("categorical")
      }
      "continuous"
    }

    out <- data.frame(
      term          = if ("term" %in% names(raw_df)) raw_df$term else NA_character_,
      level         = if ("contrast" %in% names(raw_df)) raw_df$contrast else NA_character_,
      ame           = if ("estimate" %in% names(raw_df)) raw_df$estimate else NA_real_,
      variable_type = vapply(
        if ("term" %in% names(raw_df)) raw_df$term else character(nrow(raw_df)),
        .vtype, character(1L)
      ),
      stringsAsFactors = FALSE
    )
    rownames(out) <- NULL
    return(out)
  }
  if (inherits(model, "mysterycall_poisson_model")) {
    model <- model$model
  }

  # -- Validate model class ----------------------------------------------------
  is_glmer <- inherits(model, "glmerMod")
  is_glm   <- inherits(model, "glm")

  if (!is_glmer && !is_glm) {
    stop(
      paste0(
        "`model` must be a glm, glmerMod, or mysterycall_poisson_model object.",
        " Got class: ", paste(class(model), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  # -- Validate eps ------------------------------------------------------------
  if (!is.numeric(eps) || length(eps) != 1L || eps <= 0) {
    stop("`eps` must be a single positive number.", call. = FALSE)
  }

  # -- Validate term -----------------------------------------------------------
  if (!is.null(term) && !is.character(term)) {
    stop("`term` must be a character vector or NULL.", call. = FALSE)
  }

  # -- Load lme4 if needed -----------------------------------------------------
  if (is_glmer && !requireNamespace("lme4", quietly = TRUE)) {
    stop(
      "Package 'lme4' is required for glmerMod objects",
      call. = FALSE
    )
  }

  # -- Get the original data (with un-transformed column names) ----------------
  # stats::predict() evaluates the model formula against newdata, so newdata
  # must contain the original variable names (e.g. "cyl", not "factor(cyl)").
  if (!is.null(data)) {
    orig_data <- data
  } else if (is_glmer) {
    orig_data <- lme4::getData(model)
  } else {
    # glm stores the original call data in model$data (when data= was passed)
    # and model.frame() returns the processed version. Use model$data if
    # available, otherwise reconstruct from model.frame.
    orig_data <- tryCatch(model$data, error = function(e) NULL)
    if (is.null(orig_data)) {
      # Fallback: reconstruct a data frame with original variable names
      # from model.frame, dropping the response and renaming wrapped cols
      orig_data <- .me_mf_to_orig(model)
    }
  }

  # -- Identify all predictor variable names (original, un-wrapped) ------------
  # all.vars(formula(model)) gives: response + all predictors, original names
  form_vars   <- all.vars(stats::formula(model))
  response_nm <- form_vars[1L]
  all_pred_vars <- form_vars[-1L]  # original variable names, no wrappers

  # -- Resolve requested terms -------------------------------------------------
  if (is.null(term)) {
    requested <- all_pred_vars
  } else {
    bad <- setdiff(term, all_pred_vars)
    if (length(bad) > 0L) {
      stop(
        paste0(
          "Term(s) not found in model: ",
          paste(bad, collapse = ", "),
          ". Available: ",
          paste(all_pred_vars, collapse = ", ")
        ),
        call. = FALSE
      )
    }
    requested <- term
  }

  # -- Internal predict helper -------------------------------------------------
  .predict_me <- function(newdata) {
    if (is_glmer) {
      stats::predict(model, newdata = newdata, type = type, re.form = NA)
    } else {
      stats::predict(model, newdata = newdata, type = type)
    }
  }

  # -- Determine variable type for each predictor ------------------------------
  # Use model.frame to get processed types (factors are properly detected there)
  mf <- stats::model.frame(model)
  # mf may have wrapped names like "factor(cyl)"; map back to original names
  mf_names   <- names(mf)[-1L]   # drop response
  orig_names <- all_pred_vars     # from all.vars

  # For each original pred name, find the corresponding mf column and its class
  .get_mf_col_class <- function(orig_name) {
    # Direct match
    if (orig_name %in% mf_names) {
      return(class(mf[[orig_name]])[1L])
    }
    # Wrapped match: look for mf columns whose all.vars == orig_name
    for (nm in mf_names) {
      inner <- tryCatch(all.vars(parse(text = nm)[[1L]]), error = function(e) character(0L))
      if (length(inner) == 1L && inner == orig_name) {
        return(class(mf[[nm]])[1L])
      }
    }
    # Fall back to the column class in orig_data
    class(orig_data[[orig_name]])[1L]
  }

  # -- Build results -----------------------------------------------------------
  results <- vector("list", length(requested))

  for (i in seq_along(requested)) {
    trm     <- requested[[i]]
    col_cls <- .get_mf_col_class(trm)
    is_cat  <- col_cls %in% c("factor", "character", "ordered")

    if (is_cat) {
      # -- Categorical predictor -----------------------------------------------
      # Get levels from the model.frame version of the column, which has
      # already been through factor() even if the original column is numeric
      # (e.g. mtcars$cyl is numeric but formula uses factor(cyl)).
      mf_col_nm <- .me_find_mf_col(trm, mf_names)
      mf_col    <- mf[[mf_col_nm]]
      if (is.character(mf_col)) mf_col <- factor(mf_col)
      lvls    <- levels(mf_col)
      ref_lvl <- lvls[1L]

      # For newdata we use original data but set the column to the factor value.
      # When the original column is numeric (e.g. cyl) and the formula wraps it
      # in factor(), we set it to the numeric equivalent of the level so that
      # factor(cyl) inside predict() evaluates correctly.
      orig_col <- orig_data[[trm]]
      is_num_wrapped <- is.numeric(orig_col) && !is.factor(orig_col)

      .make_newdata_cat <- function(nd, lvl_val) {
        if (is_num_wrapped) {
          nd[[trm]] <- as.numeric(lvl_val)
        } else {
          nd[[trm]] <- factor(lvl_val, levels = lvls)
        }
        nd
      }

      newdata_ref <- .make_newdata_cat(orig_data, ref_lvl)
      pred_ref    <- .predict_me(newdata_ref)

      non_ref    <- lvls[-1L]
      level_rows <- vector("list", length(non_ref))
      for (j in seq_along(non_ref)) {
        newdata_k       <- .make_newdata_cat(orig_data, non_ref[j])
        pred_k          <- .predict_me(newdata_k)
        ame_k           <- mean(pred_k - pred_ref, na.rm = TRUE)
        level_rows[[j]] <- data.frame(
          term          = trm,
          level         = non_ref[j],
          ame           = ame_k,
          variable_type = "categorical",
          stringsAsFactors = FALSE
        )
      }
      results[[i]] <- do.call(rbind, level_rows)

    } else {
      # -- Continuous predictor ------------------------------------------------
      col_vals      <- as.numeric(orig_data[[trm]])
      newdata_hi    <- orig_data
      newdata_lo    <- orig_data
      newdata_hi[[trm]] <- col_vals + eps
      newdata_lo[[trm]] <- col_vals - eps

      pred_hi  <- .predict_me(newdata_hi)
      pred_lo  <- .predict_me(newdata_lo)
      ame_val  <- mean((pred_hi - pred_lo) / (2 * eps), na.rm = TRUE)

      results[[i]] <- data.frame(
        term          = trm,
        level         = NA_character_,
        ame           = ame_val,
        variable_type = "continuous",
        stringsAsFactors = FALSE
      )
    }
  }

  out <- do.call(rbind, results)
  rownames(out) <- NULL
  out
}


# -- Internal helpers ----------------------------------------------------------

#' Reconstruct Original Data from Model Frame
#'
#' Fallback when `model$data` is not available. Renames columns by extracting
#' variable names from wrapped expressions (e.g., `"factor(cyl)"` becomes
#' `"cyl"`).
#'
#' @param model A fitted model object.
#'
#' @return A data frame with original variable names.
#' @family outcomes
#' @keywords internal
.me_mf_to_orig <- function(model) {
  mf  <- stats::model.frame(model)
  nms <- names(mf)
  new_nms <- vapply(nms, function(nm) {
    has_paren <- grepl("(", nm, fixed = TRUE)
    if (!has_paren) return(nm)
    inner <- tryCatch(
      all.vars(parse(text = nm)[[1L]]),
      error = function(e) nm
    )
    if (length(inner) == 1L) inner else nm
  }, character(1L))
  names(mf) <- new_nms
  mf
}


#' Find Model Frame Column Name
#'
#' Maps a plain variable name to the possibly-wrapped column name in the
#' model frame (e.g., `"cyl"` -> `"factor(cyl)"`).
#'
#' @param term Plain variable name.
#' @param mf_names Names of the model frame.
#'
#' @return Character scalar.
#' @family outcomes
#' @keywords internal
.me_find_mf_col <- function(term, mf_names) {
  # Direct match first
  if (term %in% mf_names) return(term)
  # Try to match via all.vars of each column name
  for (nm in mf_names) {
    inner <- tryCatch(
      all.vars(parse(text = nm)[[1L]]),
      error = function(e) character(0L)
    )
    if (length(inner) == 1L && inner == term) return(nm)
  }
  # If still not found, return the term itself and let the caller handle it
  term
}
