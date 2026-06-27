#' Auto-generate manuscript sentences for a two-way interaction
#'
#' @name mysterycall_interaction_sentences
NULL

#' Generate manuscript-ready sentences for a two-way emmeans interaction
#'
#' Takes a fitted model and two variable names, computes estimated marginal
#' means (EMMs) for the full cross of those variables via
#' [emmeans::emmeans()], and auto-generates one manuscript-ready sentence per
#' level of `var1`. Each sentence reports the mean (or rate) and 95% CI for
#' every level of `var2` within that `var1` stratum, plus the within-stratum
#' pairwise difference. All sentences are also collapsed into a single
#' paste-ready paragraph. When an interaction p-value can be extracted from
#' the model summary it is appended as a trailing sentence.
#'
#' @param model A fitted model object accepted by [emmeans::emmeans()].
#'   Typical classes include `glmerMod`, `lmerMod`, `glm`, and `lm`.
#' @param var1 Character scalar. First variable in the interaction (e.g.
#'   `"scenario"`). One sentence is produced per level of `var1`.
#' @param var2 Character scalar. Second variable in the interaction (e.g.
#'   `"insurance"`). Levels of `var2` are compared within each `var1`
#'   sentence.
#' @param type Character scalar. The `type` argument forwarded to
#'   [emmeans::emmeans()]. Default `"response"` back-transforms estimates to
#'   the original outcome scale (e.g. rate for Poisson, probability for
#'   logistic).
#' @param conf_level Numeric scalar in (0, 1). Confidence level for the
#'   intervals. Default `0.95`.
#' @param digits Integer scalar. Number of decimal places for means and CI
#'   bounds in the formatted sentences. Default `1L`.
#' @param ref_group2 Character scalar or `NULL`. When non-`NULL`, the named
#'   level of `var2` is placed first in each sentence and used as the
#'   reference when computing the within-stratum difference. When `NULL`
#'   (default) the first factor level determined by emmeans is used.
#' @param outcome_label Character scalar. Human-readable label for the
#'   outcome quantity written into each sentence. Default
#'   `"wait time (days)"`.
#'
#' @return A list of class `mysterycall_interaction_sentences` with elements:
#' \describe{
#'   \item{`sentences`}{Named character vector. One sentence per level of
#'     `var1`. Names equal the `var1` level labels.}
#'   \item{`emmeans_table`}{`data.frame`. The raw [emmeans::emmeans()]
#'     output converted via [as.data.frame()]. Column names vary by model
#'     family (e.g. `rate` vs `emmean`, `asymp.LCL` vs `lower.CL`).}
#'   \item{`paragraph`}{Character scalar. All sentences joined with a
#'     single space, ready to paste into a manuscript.}
#'   \item{`var1`}{Character scalar. The `var1` argument.}
#'   \item{`var2`}{Character scalar. The `var2` argument.}
#'   \item{`type`}{Character scalar. The emmeans `type` used.}
#' }
#'
#' @section Print method:
#' `print.mysterycall_interaction_sentences()` writes the `$paragraph`
#' element to the console via [cat()], so the text appears as plain prose
#' without surrounding quotes or list structure.
#'
#' @section emmeans column detection:
#' Column names in the emmeans data frame differ by model family. This
#' function detects the estimate and CI columns automatically:
#' \itemize{
#'   \item Estimate: `rate`, `emmean`, `response`, `prob` (first match).
#'   \item Lower CI: `asymp.LCL`, `lower.CL`, `lower.HPD`.
#'   \item Upper CI: `asymp.UCL`, `upper.CL`, `upper.HPD`.
#' }
#' An informative error is raised when none of the candidate names are
#' found.
#'
#' @section Interaction p-value:
#' The function silently attempts to extract the smallest p-value for any
#' `var1:var2` coefficient row from [summary()]. Coefficients are matched
#' when their row name contains both `var1` and `var2` and a colon. On
#' success, a trailing sentence reporting significance is appended to
#' `$paragraph`. Failure (e.g. for unsupported model classes or missing
#' interaction terms) is ignored silently.
#'
#' @importFrom stats as.formula
#' @family outcomes
#' @seealso [mysterycall_interaction_table()], [mysterycall_marginal_effects()]
#' @export
#'
#' @examples
#' \dontrun{
#' library(lme4)
#'
#' set.seed(42)
#' df <- data.frame(
#'   wait_days = rpois(120, lambda = 20),
#'   scenario  = rep(c("Urgent", "Routine"), each = 60),
#'   insurance = rep(c("Medicaid", "BCBS", "Medicare"), times = 40),
#'   physician = rep(paste0("Dr", 1:10), each = 12),
#'   stringsAsFactors = FALSE
#' )
#'
#' fit <- lme4::glmer(
#'   wait_days ~ scenario * insurance + (1 | physician),
#'   data   = df,
#'   family = poisson()
#' )
#'
#' result <- mysterycall_interaction_sentences(
#'   model         = fit,
#'   var1          = "scenario",
#'   var2          = "insurance",
#'   ref_group2    = "BCBS",
#'   outcome_label = "wait time (days)"
#' )
#'
#' print(result)          # prints paragraph to console
#' result$sentences       # named vector, one element per scenario level
#' result$emmeans_table   # raw emmeans data frame
#' }
mysterycall_interaction_sentences <- function(model,
                                              var1,
                                              var2,
                                              type          = "response",
                                              conf_level    = 0.95,
                                              digits        = 1L,
                                              ref_group2    = NULL,
                                              outcome_label = "wait time (days)") {

  # -- Guard: emmeans must be available ----------------------------------------
  if (!requireNamespace("emmeans", quietly = TRUE)) {
    stop(
      "Package 'emmeans' is required but not installed. ",
      "Install with: install.packages('emmeans')",
      call. = FALSE
    )
  }

  # -- Input validation ---------------------------------------------------------
  if (!is.character(var1) || length(var1) != 1L || !nzchar(var1)) {
    stop("`var1` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.character(var2) || length(var2) != 1L || !nzchar(var2)) {
    stop("`var2` must be a single non-empty character string.", call. = FALSE)
  }
  if (identical(var1, var2)) {
    stop("`var1` and `var2` must be different variable names.", call. = FALSE)
  }
  if (!is.character(type) || length(type) != 1L || !nzchar(type)) {
    stop("`type` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      is.na(conf_level) || conf_level <= 0 || conf_level >= 1) {
    stop("`conf_level` must be a single number strictly between 0 and 1.",
         call. = FALSE)
  }
  if (!is.numeric(digits) || length(digits) != 1L ||
      is.na(digits) || digits < 0L) {
    stop("`digits` must be a non-negative integer scalar.", call. = FALSE)
  }
  digits <- as.integer(digits)
  if (!is.null(ref_group2)) {
    if (!is.character(ref_group2) || length(ref_group2) != 1L ||
        !nzchar(ref_group2)) {
      stop(
        "`ref_group2` must be a single non-empty character string or NULL.",
        call. = FALSE
      )
    }
  }
  if (!is.character(outcome_label) || length(outcome_label) != 1L) {
    stop("`outcome_label` must be a single character string.", call. = FALSE)
  }

  # -- Build emmeans specs and compute -----------------------------------------
  specs  <- stats::as.formula(paste("~", var1, "*", var2))

  em_obj <- tryCatch(
    emmeans::emmeans(model, specs = specs, type = type, level = conf_level),
    error = function(e) {
      stop(
        "emmeans::emmeans() failed: ", e$message, "\n",
        "Verify that '", var1, "' and '", var2,
        "' both appear in the model formula.",
        call. = FALSE
      )
    }
  )

  em_df <- as.data.frame(em_obj)

  # -- Auto-detect estimate and CI column names ---------------------------------
  est_candidates <- c("rate", "emmean", "response", "prob")
  lcl_candidates <- c("asymp.LCL", "lower.CL", "lower.HPD")
  ucl_candidates <- c("asymp.UCL", "upper.CL", "upper.HPD")

  est_col <- intersect(est_candidates, names(em_df))
  lcl_col <- intersect(lcl_candidates, names(em_df))
  ucl_col <- intersect(ucl_candidates, names(em_df))

  if (length(est_col) == 0L) {
    stop(
      "Cannot identify estimate column in emmeans output. ",
      "Expected one of: ", paste(est_candidates, collapse = ", "), ". ",
      "Found: ", paste(names(em_df), collapse = ", "),
      call. = FALSE
    )
  }
  if (length(lcl_col) == 0L || length(ucl_col) == 0L) {
    stop(
      "Cannot identify CI columns in emmeans output. ",
      "Expected lower CI from: ", paste(lcl_candidates, collapse = ", "),
      " and upper CI from: ", paste(ucl_candidates, collapse = ", "), ". ",
      "Found: ", paste(names(em_df), collapse = ", "),
      call. = FALSE
    )
  }
  est_col <- est_col[[1L]]
  lcl_col <- lcl_col[[1L]]
  ucl_col <- ucl_col[[1L]]

  # -- Verify grouping columns exist in the emmeans output ---------------------
  if (!var1 %in% names(em_df)) {
    stop(
      "'", var1, "' not found in emmeans output. Available columns: ",
      paste(names(em_df), collapse = ", "),
      call. = FALSE
    )
  }
  if (!var2 %in% names(em_df)) {
    stop(
      "'", var2, "' not found in emmeans output. Available columns: ",
      paste(names(em_df), collapse = ", "),
      call. = FALSE
    )
  }

  # -- Determine ordered factor levels -----------------------------------------
  var1_levels <- as.character(unique(em_df[[var1]]))
  var2_levels <- as.character(unique(em_df[[var2]]))

  if (!is.null(ref_group2)) {
    if (!ref_group2 %in% var2_levels) {
      stop(
        "`ref_group2` value '", ref_group2, "' not found among levels of '",
        var2, "'. Available: ", paste(var2_levels, collapse = ", "),
        call. = FALSE
      )
    }
    var2_levels <- c(ref_group2, setdiff(var2_levels, ref_group2))
  }

  # -- Formatting helper -------------------------------------------------------
  .fmt <- function(x) formatC(x, digits = digits, format = "f")

  # -- Build one sentence per var1 level ----------------------------------------
  sentences <- vapply(var1_levels, function(v1) {

    # Subset rows belonging to this var1 level
    mask  <- as.character(em_df[[var1]]) == v1
    block <- em_df[mask, , drop = FALSE]

    # Reorder rows to match the requested var2 order
    idx   <- match(var2_levels, as.character(block[[var2]]))
    valid <- !is.na(idx)
    block <- block[idx[valid], , drop = FALSE]
    v2_ordered <- var2_levels[valid]

    # Build one fragment per var2 cell
    cell_parts <- vapply(seq_along(v2_ordered), function(i) {
      r   <- block[i, , drop = FALSE]
      est <- r[[est_col]]
      lcl <- r[[lcl_col]]
      ucl <- r[[ucl_col]]
      sprintf(
        "%s patients: mean %s %s (95%% CI %s–%s)",
        v2_ordered[i],
        .fmt(est),
        outcome_label,
        .fmt(lcl),
        .fmt(ucl)
      )
    }, character(1L))

    # Difference: last var2 level minus first (reference)
    est_ref  <- block[[est_col]][[1L]]
    est_comp <- block[[est_col]][[nrow(block)]]
    diff_val <- est_comp - est_ref

    diff_str <- sprintf(
      "Difference (%s vs %s): %s %s.",
      v2_ordered[nrow(block)],
      v2_ordered[1L],
      .fmt(diff_val),
      outcome_label
    )

    paste0(
      var1, " = ", v1, ": ",
      paste(cell_parts, collapse = "; "),
      ". ",
      diff_str
    )
  }, character(1L))

  names(sentences) <- var1_levels

  # -- Silently attempt to extract interaction LRT p-value ---------------------
  p_sentence <- tryCatch({

    sm <- summary(model)

    # Support glm/lm/glmerMod/lmerMod ($coefficients is a matrix) and
    # glmmTMB ($coefficients$cond is a matrix)
    coef_mat <- if (!is.null(sm[["coefficients"]]) &&
                    is.matrix(sm[["coefficients"]])) {
      sm[["coefficients"]]
    } else if (!is.null(sm[["coefficients"]][["cond"]]) &&
               is.matrix(sm[["coefficients"]][["cond"]])) {
      sm[["coefficients"]][["cond"]]
    } else {
      NULL
    }

    if (!is.null(coef_mat) && nrow(coef_mat) > 0L) {
      rn <- rownames(coef_mat)
      # Last column is p-value in both glm and lme4 summaries
      p_col_idx <- ncol(coef_mat)

      int_mask <- grepl(":", rn, fixed = TRUE) &
        grepl(var1, rn, fixed = TRUE)       &
        grepl(var2, rn, fixed = TRUE)

      if (any(int_mask)) {
        p_vals <- as.numeric(coef_mat[int_mask, p_col_idx])
        p_min  <- min(p_vals, na.rm = TRUE)
        if (is.finite(p_min)) {
          p_fmt    <- if (p_min < 0.001) "< 0.001" else
            formatC(p_min, digits = 3, format = "f")
          sig_word <- if (p_min < 0.05) "statistically significant" else
            "not statistically significant"
          sprintf(
            "The %s × %s interaction was %s (p %s).",
            var1, var2, sig_word, p_fmt
          )
        } else {
          NULL
        }
      } else {
        NULL
      }
    } else {
      NULL
    }
  }, error = function(e) NULL, warning = function(w) NULL)

  # -- Assemble paragraph ------------------------------------------------------
  para_parts <- as.character(sentences)
  if (!is.null(p_sentence)) para_parts <- c(para_parts, p_sentence)
  paragraph <- paste(para_parts, collapse = " ")

  # -- Return structured result ------------------------------------------------
  structure(
    list(
      sentences     = sentences,
      emmeans_table = em_df,
      paragraph     = paragraph,
      var1          = var1,
      var2          = var2,
      type          = type
    ),
    class = "mysterycall_interaction_sentences"
  )
}


#' @rdname mysterycall_interaction_sentences
#' @param x A `mysterycall_interaction_sentences` object.
#' @param ... Ignored; present for S3 method consistency.
#' @export
print.mysterycall_interaction_sentences <- function(x, ...) {
  cat(x$paragraph, "\n")
  invisible(x)
}
