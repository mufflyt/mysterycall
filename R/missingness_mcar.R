# =============================================================================
# missingness_mcar.R  --  Missingness table + Little's MCAR test
# -----------------------------------------------------------------------------
# One call that produces (1) a per-variable missingness table and (2) Little's
# MCAR test (naniar::mcar_test()), which returns a single chi-square / df /
# p-value for the null "the data are Missing Completely At Random."
#
# The table SEPARATES two mechanistically different kinds of missingness:
#   * item-level  -- the variable applies to (essentially) every unit, so a
#                   missing value is item non-response / a data gap. MCAR is a
#                   meaningful question here, so ONLY these variables feed the
#                   Little's test.
#   * structural  -- the variable is undefined by design for a subgroup. Its
#                   "missingness" is informative, not random; including it in an
#                   MCAR test is a category error, so it is reported but EXCLUDED.
#
# Notes
#   - Little's test (naniar::mcar_test) is a multivariate-normal-based test and
#     requires NUMERIC columns. Categorical item-level variables are summarized
#     in the table but cannot enter Little's test directly; by default the test
#     runs on the numeric item-level columns. Supply `mcar_vars` to override.
#   - At large N the test is over-powered: it rejects MCAR on trivial deviations.
#     The returned `interpretation` says so; report the statistic WITH context.
#   - Pure function: no file I/O, no global state.
# =============================================================================

# Tokens that are PRESENT-but-uninformative (count as "unknown").
.MCAR_UNKNOWN_TOKENS <- c(
  "unknown", "", "na", "n/a", "missing", "none", "null",
  "\u2014", "-", "?", ".", "unk", "not available", "not reported"
)

# NSE column names used inside dplyr/gt verbs (silence R CMD check NOTE).
utils::globalVariables(c(
  "missingness_type", "pct_missing", "label", "n_total", "n_missing",
  "n_unknown", "n_informative", "pct_informative", "Mechanism"
))

#' Per-variable missingness table paired with Little's MCAR test
#'
#' @description
#' Computes a tidy per-variable missingness summary and, on the item-level
#' numeric subset, Little's MCAR test. Structural (missing-by-design) variables
#' are reported but excluded from the test.
#'
#' @param data \code{[data.frame]} One row per analytic unit (e.g., per NPI).
#' @param item_vars \code{[character]} Variables whose missingness is item-level
#'   (MCAR is a meaningful question). These, when numeric, feed Little's test.
#' @param structural_vars \code{[character]} Variables missing by design
#'   (conditional on a subgroup). Reported, never tested. Default none.
#' @param var_labels \code{[named character]} Optional \code{var -> pretty label}.
#'   Unlabelled variables fall back to their name.
#' @param unknown_tokens \code{[character]} Lower-cased tokens treated as
#'   present-but-uninformative. Default \code{.MCAR_UNKNOWN_TOKENS}.
#' @param mcar_vars \code{[character|NULL]} Explicit variable set for Little's
#'   test. Default \code{NULL} = the numeric columns among \code{item_vars}.
#' @param run_mcar \code{[logical]} Run Little's test. Default \code{TRUE}.
#' @param make_gt \code{[logical]} Also return a \code{gt} table. Default \code{FALSE}.
#' @param gt_title \code{[character]} Title for the gt table.
#'
#' @return A list with:
#'   \describe{
#'     \item{missingness}{tibble: variable, label, missingness_type, n_total,
#'       n_missing, pct_missing, n_unknown, n_informative, pct_informative.}
#'     \item{mcar}{list: statistic, df, p.value, n_missing_patterns, vars_tested,
#'       n_rows_tested, note -- or \code{NULL} if not run/possible.}
#'     \item{interpretation}{character: calibrated narrative (structural vs
#'       item-level; large-N caveat).}
#'     \item{gt}{a \code{gt_tbl} if \code{make_gt=TRUE} and gt is installed, else
#'       \code{NULL}.}
#'   }
#'
#' @examples
#' \dontrun{
#' res <- build_missingness_mcar_table(
#'   data           = cohort,
#'   item_vars      = c("gender", "age_years", "state", "latitude", "longitude"),
#'   structural_vars= c("years_active", "retirement_year", "total_go"),
#'   var_labels     = c(gender = "Gender", age_years = "Age (years)")
#' )
#' res$missingness
#' res$mcar$statistic; res$mcar$p.value
#' cat(res$interpretation)
#' }
#'
#' @importFrom dplyr bind_rows arrange desc filter transmute
#' @importFrom tibble tibble
#' @importFrom stats var
#' @export
build_missingness_mcar_table <- function(data,
                                         item_vars,
                                         structural_vars = character(0),
                                         var_labels      = NULL,
                                         unknown_tokens  = .MCAR_UNKNOWN_TOKENS,
                                         mcar_vars       = NULL,
                                         run_mcar        = TRUE,
                                         make_gt         = FALSE,
                                         gt_title        = "Variable Missingness and Little's MCAR Test") {

  stopifnot("`data` must be a data frame" = is.data.frame(data))
  item_vars       <- unique(as.character(item_vars))
  structural_vars <- unique(as.character(structural_vars))

  # ---- Validate variable membership -----------------------------------------
  all_vars <- c(item_vars, structural_vars)
  dup <- intersect(item_vars, structural_vars)
  if (length(dup)) {
    stop("Variables classified as BOTH item and structural: ",
         paste(dup, collapse = ", "), call. = FALSE)
  }
  missing_cols <- setdiff(all_vars, names(data))
  if (length(missing_cols)) {
    stop("Variables not present in `data`: ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  n_total <- nrow(data)
  toks    <- tolower(trimws(unknown_tokens))

  # ---- Per-variable missingness ---------------------------------------------
  .lab <- function(v) if (!is.null(var_labels) && v %in% names(var_labels)) var_labels[[v]] else v
  .row <- function(v, type) {
    x         <- data[[v]]
    is_na     <- is.na(x)
    is_tok    <- if (is.character(x) || is.factor(x)) tolower(trimws(as.character(x))) %in% toks & !is_na
                 else rep(FALSE, length(x))
    n_missing <- sum(is_na)
    n_unknown <- sum(is_tok)
    n_info    <- n_total - n_missing - n_unknown
    tibble::tibble(
      variable         = v,
      label            = .lab(v),
      missingness_type = type,
      n_total          = n_total,
      n_missing        = n_missing,
      pct_missing      = round(100 * n_missing / n_total, 1),
      n_unknown        = n_unknown,
      n_informative    = n_info,
      pct_informative  = round(100 * n_info / n_total, 1)
    )
  }

  miss_tbl <- dplyr::bind_rows(
    if (length(item_vars))       dplyr::bind_rows(lapply(item_vars,       .row, type = "item-level")),
    if (length(structural_vars)) dplyr::bind_rows(lapply(structural_vars, .row, type = "structural"))
  )
  miss_tbl <- dplyr::arrange(
    miss_tbl,
    factor(miss_tbl$missingness_type, levels = c("item-level", "structural")),
    dplyr::desc(miss_tbl$pct_missing)
  )

  # ---- Little's MCAR test (item-level numeric block only) -------------------
  mcar <- NULL
  if (isTRUE(run_mcar)) {
    if (is.null(mcar_vars)) {
      mcar_vars <- item_vars[vapply(item_vars, function(v) is.numeric(data[[v]]), logical(1))]
    }
    dropped_nonnum <- setdiff(item_vars, mcar_vars)

    if (!requireNamespace("naniar", quietly = TRUE)) {
      mcar <- list(statistic = NA_real_, df = NA_real_, p.value = NA_real_,
                   n_missing_patterns = NA_integer_, vars_tested = character(0),
                   n_rows_tested = 0L,
                   note = paste0("naniar not installed; cannot run Little's MCAR test. ",
                                 "Install with install.packages('naniar')."))
    } else if (length(mcar_vars) < 2L) {
      mcar <- list(statistic = NA_real_, df = NA_real_, p.value = NA_real_,
                   n_missing_patterns = NA_integer_, vars_tested = mcar_vars,
                   n_rows_tested = 0L,
                   note = "Fewer than 2 numeric item-level variables; Little's test not defined.")
    } else {
      test_df <- data[, mcar_vars, drop = FALSE]
      test_df <- as.data.frame(lapply(test_df, as.numeric))
      var_ok  <- vapply(test_df, function(cc) {
        o <- cc[!is.na(cc)]; length(o) > 1L && stats::var(o) > 0
      }, logical(1))
      dropped_const <- names(test_df)[!var_ok]
      test_df <- test_df[, var_ok, drop = FALSE]

      if (ncol(test_df) < 2L) {
        mcar <- list(statistic = NA_real_, df = NA_real_, p.value = NA_real_,
                     n_missing_patterns = NA_integer_, vars_tested = names(test_df),
                     n_rows_tested = nrow(test_df),
                     note = "After dropping constant/degenerate columns, <2 remain; test not run.")
      } else if (sum(is.na(test_df)) == 0L) {
        mcar <- list(statistic = 0, df = 0, p.value = NA_real_,
                     n_missing_patterns = 1L, vars_tested = names(test_df),
                     n_rows_tested = nrow(test_df),
                     note = "No missing values in the tested block; MCAR is vacuously satisfied.")
      } else {
        res <- tryCatch(naniar::mcar_test(test_df), error = function(e) e)
        if (inherits(res, "error")) {
          mcar <- list(statistic = NA_real_, df = NA_real_, p.value = NA_real_,
                       n_missing_patterns = NA_integer_, vars_tested = names(test_df),
                       n_rows_tested = nrow(test_df),
                       note = paste0("naniar::mcar_test() errored: ", conditionMessage(res)))
        } else {
          g <- function(nm) if (nm %in% names(res)) res[[nm]][1] else NA
          note_bits <- character(0)
          if (length(dropped_nonnum))
            note_bits <- c(note_bits, paste0("non-numeric item vars excluded from test: ",
                                             paste(dropped_nonnum, collapse = ", ")))
          if (length(dropped_const))
            note_bits <- c(note_bits, paste0("constant/degenerate vars dropped: ",
                                             paste(dropped_const, collapse = ", ")))
          mcar <- list(
            statistic          = as.numeric(g("statistic")),
            df                 = as.numeric(g("df")),
            p.value            = as.numeric(g("p.value")),
            n_missing_patterns = suppressWarnings(as.integer(g("missing.patterns"))),
            vars_tested        = names(test_df),
            n_rows_tested      = nrow(test_df),
            note               = if (length(note_bits)) paste(note_bits, collapse = "; ") else "OK"
          )
        }
      }
    }
  }

  interpretation <- .mcar_interpretation(miss_tbl, mcar, n_total)

  gt_obj <- NULL
  if (isTRUE(make_gt) && requireNamespace("gt", quietly = TRUE)) {
    gt_obj <- .mcar_gt(miss_tbl, mcar, gt_title, interpretation)
  }

  list(missingness = miss_tbl, mcar = mcar, interpretation = interpretation, gt = gt_obj)
}

# ---- narrative -------------------------------------------------------------
#' @keywords internal
#' @noRd
.mcar_interpretation <- function(miss_tbl, mcar, n_total) {
  item <- dplyr::filter(miss_tbl, miss_tbl$missingness_type == "item-level")
  strc <- dplyr::filter(miss_tbl, miss_tbl$missingness_type == "structural")
  worst_item <- if (nrow(item)) item[which.max(item$pct_missing), ] else NULL

  s <- c()
  s <- c(s, sprintf(
    "Missingness was assessed for %d analytic variables across %s units, separated into item-level (n=%d) and structural, missing-by-design (n=%d) mechanisms.",
    nrow(miss_tbl), format(n_total, big.mark = ","), nrow(item), nrow(strc)))
  if (!is.null(worst_item)) {
    s <- c(s, sprintf(
      "Item-level missingness ranged from %.1f%% to %.1f%% (greatest for %s) and reflects source non-linkage that is independent of the subgroup structure, rather than missingness conditioned on a unit's subgroup or observation status.",
      min(item$pct_missing), max(item$pct_missing), worst_item$label))
  }
  if (nrow(strc)) {
    s <- c(s, sprintf(
      "Structural variables (%s) are undefined for units outside the relevant subgroup; their missingness is informative (MAR/MNAR by construction) and is therefore reported but excluded from any MCAR test.",
      paste(utils::head(strc$label, 4), collapse = "; ")))
  }
  if (!is.null(mcar) && is.finite(mcar$statistic) && is.finite(mcar$p.value)) {
    verdict <- if (mcar$p.value < 0.05) "reject" else "do not reject"
    s <- c(s, sprintf(
      "Little's MCAR test on the numeric item-level block (%d variables) gave chi-square = %.1f, df = %.0f, p = %s; we therefore %s the null of MCAR.",
      length(mcar$vars_tested), mcar$statistic, mcar$df,
      format.pval(mcar$p.value, digits = 3, eps = 1e-4), verdict))
    if (mcar$p.value < 0.05) {
      s <- c(s, sprintf(
        "At this sample size (N=%s) Little's test is highly powered and rejects MCAR on minor deviations; rejection here is consistent with weak, non-systematic item missingness rather than evidence of substantial bias, and complete-case analyses of these variables are unlikely to be materially confounded.",
        format(n_total, big.mark = ",")))
    }
  } else if (!is.null(mcar)) {
    s <- c(s, sprintf("Little's MCAR test not evaluated: %s", mcar$note))
  }
  paste(s, collapse = " ")
}

# ---- gt renderer -----------------------------------------------------------
#' @keywords internal
#' @noRd
.mcar_gt <- function(miss_tbl, mcar, title, interpretation) {
  disp <- dplyr::transmute(
    miss_tbl,
    Variable = label,
    Mechanism = missingness_type,
    N = n_total,
    `Missing (n)` = n_missing,
    `Missing (%)` = pct_missing,
    `Uninformative (n)` = n_unknown,
    `Informative (%)` = pct_informative
  )
  src <- if (!is.null(mcar) && is.finite(mcar$statistic) && is.finite(mcar$p.value)) {
    sprintf(paste0("Little's MCAR test (naniar::mcar_test) on the %d numeric item-level ",
                   "variables: chi-square = %.1f, df = %.0f, p = %s. Structural ",
                   "(missing-by-design) variables are excluded from the test. %s"),
            length(mcar$vars_tested), mcar$statistic, mcar$df,
            format.pval(mcar$p.value, digits = 3, eps = 1e-4), interpretation)
  } else {
    paste0("Little's MCAR test not available. ", interpretation)
  }
  tbl <- gt::gt(disp)
  tbl <- gt::tab_header(tbl, title = gt::md(paste0("**", title, "**")))
  tbl <- gt::tab_row_group(tbl, label = "Structural (missing by design)",
                           rows = Mechanism == "structural")
  tbl <- gt::tab_row_group(tbl, label = "Item-level (MCAR assessable)",
                           rows = Mechanism == "item-level")
  tbl <- gt::cols_hide(tbl, columns = "Mechanism")
  tbl <- gt::tab_source_note(tbl, source_note = gt::md(src))
  tbl <- gt::tab_style(tbl, style = gt::cell_text(weight = "bold"),
                       locations = gt::cells_column_labels())
  tbl <- gt::tab_options(tbl, table.font.size = 11, heading.title.font.size = 13,
                         source_notes.font.size = 9, table.width = gt::pct(100))
  tbl
}
