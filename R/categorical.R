# Small-sample categorical statistics toolkit
# -----------------------------------------------------------------------------
# The audit-study literature analyses call outcomes with contingency-table
# tests, exact tests for sparse cells, matched/stratified (Cochran-Mantel-
# Haenszel) tests, effect sizes, and rank tests -- not the package's GLMM core,
# which is overkill when denominators fall to ~140. This module supplies a thin,
# dependency-free layer for exactly those designs.
#
#   mysterycall_test_categorical()  chi-squared / Fisher (auto), Cramer's V,
#                                   optional BH-adjusted post-hoc proportions
#   mysterycall_cmh_test()          Cochran-Mantel-Haenszel across a matching
#                                   stratum (paired/within-unit designs)
#   mysterycall_prevalence_ci()     per-category proportions with Wilson or
#                                   Clopper-Pearson intervals
#   mysterycall_compare_ranks()     Kruskal-Wallis / Mann-Whitney with an
#                                   effect size and per-group median (IQR)
# -----------------------------------------------------------------------------


# ---- internal helpers -------------------------------------------------------

# Clopper-Pearson (exact) binomial interval. Returns c(lower, upper).
.mc_clopper_pearson <- function(x, n, conf_level = 0.95) {
  if (is.na(n) || n == 0) return(c(NA_real_, NA_real_))
  a <- 1 - conf_level
  lower <- if (x == 0) 0 else stats::qbeta(a / 2, x, n - x + 1)
  upper <- if (x == n) 1 else stats::qbeta(1 - a / 2, x + 1, n - x)
  c(lower, upper)
}

# Rough Cohen-style label for Cramer's V (df-dependent; a guide, not a rule).
.mc_cramers_v_label <- function(v) {
  if (is.na(v)) return(NA_character_)
  if (v < 0.1) "negligible" else if (v < 0.3) "small" else
    if (v < 0.5) "medium" else "large"
}

# Pairwise comparison of a binary outcome across group levels, BH-adjusted.
.mc_posthoc_proportions <- function(tab, p_adjust) {
  # orient so the binary dimension is the rows and groups are the columns
  if (nrow(tab) != 2L && ncol(tab) == 2L) tab <- t(tab)
  if (nrow(tab) != 2L) return(NULL)  # only defined for a binary outcome
  groups <- colnames(tab)
  if (is.null(groups)) groups <- as.character(seq_len(ncol(tab)))
  combos <- utils::combn(seq_len(ncol(tab)), 2L)
  rows <- lapply(seq_len(ncol(combos)), function(j) {
    i1 <- combos[1, j]; i2 <- combos[2, j]
    succ <- c(tab[1, i1], tab[1, i2])
    tot <- c(sum(tab[, i1]), sum(tab[, i2]))
    pt <- suppressWarnings(stats::prop.test(succ, tot))
    data.frame(
      group1 = groups[i1], group2 = groups[i2],
      prop1 = round(succ[1] / tot[1], 3), prop2 = round(succ[2] / tot[2], 3),
      p_value = pt$p.value, stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out$p_adj <- stats::p.adjust(out$p_value, method = p_adjust)
  out$p_value <- round(out$p_value, 4)
  out$p_adj <- round(out$p_adj, 4)
  tibble::as_tibble(out)
}


# ---- chi-squared / Fisher with effect size ---------------------------------

#' Association Test for a Contingency Table (auto chi-squared / Fisher)
#'
#' Cross-tabulates two categorical variables and tests their association,
#' automatically falling back from Pearson's chi-squared to an exact test when
#' expected cell counts are small -- the standard pattern in mystery-caller
#' audits (Lungfiel 2023, Sharma 2025, Hodson 2025). Reports Cramer's V as an
#' effect size and, optionally, Benjamini-Hochberg-adjusted post-hoc pairwise
#' proportion comparisons when the outcome is binary.
#'
#' @param data A data frame.
#' @param row_var,col_var Character scalars. Names of the two categorical
#'   columns to cross-tabulate.
#' @param method Character. `"auto"` (default) uses an exact test when any
#'   expected count is `< min_expected`, otherwise chi-squared; `"chisq"` and
#'   `"fisher"` force the choice. For tables larger than 2x2 the exact test is
#'   the Fisher-Freeman-Halton test (simulated if the exact computation is
#'   infeasible).
#' @param min_expected Numeric. Expected-count threshold that triggers the exact
#'   test under `"auto"`. Default `5`.
#' @param correct Logical. Apply Yates' continuity correction for 2x2
#'   chi-squared tests. Default `TRUE`.
#' @param posthoc Logical. If `TRUE` and the outcome is binary and the overall
#'   test is significant at `1 - conf_level`, compute pairwise proportion
#'   comparisons across the other variable's levels. Default `FALSE`.
#' @param p_adjust Character. Multiple-comparison method for post-hoc p-values,
#'   passed to [stats::p.adjust()]. Default `"BH"`.
#' @param conf_level Numeric. Confidence level (drives the post-hoc alpha).
#'   Default `0.95`.
#'
#' @return A `mysterycall_categorical_test` object: a list with `method`,
#'   `statistic`, `df`, `p_value`, `cramers_v`, `effect_size` (label),
#'   `n`, `min_expected`, `table`, and `posthoc` (a tibble or `NULL`).
#'
#' @family categorical
#' @importFrom tibble tibble as_tibble
#' @importFrom stats chisq.test fisher.test p.adjust prop.test
#' @importFrom utils combn
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_flag assert_number
#' @export
#'
#' @examples
#' df <- data.frame(
#'   offered = c(rep("yes", 30), rep("no", 10), rep("yes", 18), rep("no", 22)),
#'   payer   = c(rep("commercial", 40), rep("medicaid", 40))
#' )
#' res <- mysterycall_test_categorical(df, "offered", "payer", posthoc = TRUE)
#' res
mysterycall_test_categorical <- function(
    data, row_var, col_var,
    method       = c("auto", "chisq", "fisher"),
    min_expected = 5,
    correct      = TRUE,
    posthoc      = FALSE,
    p_adjust     = "BH",
    conf_level   = 0.95) {

  method <- match.arg(method)
  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_string(row_var)
  checkmate::assert_string(col_var)
  checkmate::assert_names(names(data), must.include = c(row_var, col_var))
  checkmate::assert_number(min_expected, lower = 0)
  checkmate::assert_flag(correct)
  checkmate::assert_flag(posthoc)
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)

  tab <- table(data[[row_var]], data[[col_var]])
  if (any(dim(tab) < 2L)) {
    stop("Both variables must have at least two observed levels.", call. = FALSE)
  }
  n <- sum(tab)
  is_2x2 <- all(dim(tab) == 2L)

  expected <- suppressWarnings(stats::chisq.test(tab, correct = FALSE)$expected)
  min_exp <- min(expected)

  use_exact <- switch(method,
    auto   = min_exp < min_expected,
    chisq  = FALSE,
    fisher = TRUE
  )

  # Cramer's V from the (uncorrected) chi-squared statistic, always
  chi2 <- suppressWarnings(stats::chisq.test(tab, correct = FALSE)$statistic)
  cramers_v <- sqrt(as.numeric(chi2) / (n * (min(dim(tab)) - 1L)))

  if (use_exact) {
    ft <- tryCatch(
      stats::fisher.test(tab),
      error = function(e) suppressWarnings(
        stats::fisher.test(tab, simulate.p.value = TRUE, B = 10000)
      )
    )
    simulated <- grepl("simulate", ft$method, ignore.case = TRUE)
    method_label <- if (is_2x2) {
      "Fisher's exact test"
    } else if (simulated) {
      "Fisher-Freeman-Halton exact test (simulated)"
    } else {
      "Fisher-Freeman-Halton exact test"
    }
    statistic <- NA_real_
    df <- NA_real_
    p_value <- ft$p.value
  } else {
    cs <- suppressWarnings(stats::chisq.test(tab, correct = correct && is_2x2))
    method_label <- if (correct && is_2x2) {
      "Pearson's chi-squared (Yates' correction)"
    } else {
      "Pearson's chi-squared"
    }
    statistic <- as.numeric(cs$statistic)
    df <- as.numeric(cs$parameter)
    p_value <- cs$p.value
  }

  ph <- NULL
  if (isTRUE(posthoc) && p_value < (1 - conf_level) && min(dim(tab)) == 2L) {
    ph <- .mc_posthoc_proportions(tab, p_adjust)
  }

  structure(
    list(
      method       = method_label,
      statistic    = statistic,
      df           = df,
      p_value      = p_value,
      cramers_v    = round(cramers_v, 3),
      effect_size  = .mc_cramers_v_label(cramers_v),
      n            = n,
      min_expected = round(min_exp, 2),
      table        = tab,
      posthoc      = ph,
      settings     = list(row_var = row_var, col_var = col_var,
                          conf_level = conf_level, p_adjust = p_adjust)
    ),
    class = "mysterycall_categorical_test"
  )
}


# ---- Cochran-Mantel-Haenszel ------------------------------------------------

#' Cochran-Mantel-Haenszel Test for a Matched / Stratified Design
#'
#' Tests the association between a categorical outcome and a group while
#' conditioning on a matching stratum -- the correct engine for within-unit
#' audit designs where the same clinic/pharmacy is called under several
#' personas (Wilkinson 2018). Wraps [stats::mantelhaen.test()]; for a binary
#' outcome and binary group it also returns the common odds ratio and its
#' confidence interval.
#'
#' @param data A data frame in long form (one row per call).
#' @param outcome_var,group_var,strata_var Character scalars. The outcome, the
#'   grouping (exposure) variable, and the matching stratum (e.g. the clinic id).
#' @param conf_level Numeric. Confidence level for the common odds ratio.
#'   Default `0.95`.
#' @param correct Logical. Continuity correction for the 2x2xK case. Default
#'   `TRUE`.
#'
#' @return A `mysterycall_cmh_test` object: a list with `method`, `statistic`,
#'   `df`, `p_value`, `estimate` (common OR or `NA`), `conf_int`, `n`,
#'   `n_strata`, and `table`.
#'
#' @family categorical
#' @importFrom stats mantelhaen.test
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_number assert_flag
#' @export
#'
#' @examples
#' set.seed(1)
#' clinic <- rep(paste0("c", 1:20), each = 2)
#' persona <- rep(c("adult", "teen"), times = 20)
#' offered <- rbinom(40, 1, ifelse(persona == "teen", 0.55, 0.8))
#' df <- data.frame(clinic, persona, offered = ifelse(offered == 1, "yes", "no"))
#' mysterycall_cmh_test(df, "offered", "persona", "clinic")
mysterycall_cmh_test <- function(
    data, outcome_var, group_var, strata_var,
    conf_level = 0.95, correct = TRUE) {

  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_string(outcome_var)
  checkmate::assert_string(group_var)
  checkmate::assert_string(strata_var)
  checkmate::assert_names(names(data),
                          must.include = c(outcome_var, group_var, strata_var))
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)
  checkmate::assert_flag(correct)

  tab <- table(data[[outcome_var]], data[[group_var]], data[[strata_var]])
  is_2x2xk <- all(dim(tab)[1:2] == 2L)
  if (dim(tab)[3] < 2L) {
    stop("`strata_var` must define at least two strata for a Cochran-Mantel-",
         "Haenszel test; with a single stratum use mysterycall_test_categorical() ",
         "on the two-way table.", call. = FALSE)
  }

  ht <- stats::mantelhaen.test(
    tab, correct = correct,
    conf.level = conf_level,
    exact = FALSE
  )

  estimate <- if (is_2x2xk && !is.null(ht$estimate)) unname(ht$estimate) else NA_real_
  conf_int <- if (is_2x2xk && !is.null(ht$conf.int)) as.numeric(ht$conf.int) else c(NA_real_, NA_real_)

  structure(
    list(
      method    = ht$method,
      statistic = as.numeric(ht$statistic),
      df        = as.numeric(ht$parameter),
      p_value   = ht$p.value,
      estimate  = estimate,
      conf_int  = conf_int,
      n         = sum(tab),
      n_strata  = dim(tab)[3],
      table     = tab,
      settings  = list(outcome_var = outcome_var, group_var = group_var,
                       strata_var = strata_var, conf_level = conf_level)
    ),
    class = "mysterycall_cmh_test"
  )
}


# ---- prevalence with exact / Wilson CIs -------------------------------------

#' Category Prevalence with Wilson or Clopper-Pearson Intervals
#'
#' Descriptive per-category proportions with interval estimates suited to small
#' audit samples -- the appropriate output for "% of calls in each category"
#' when the GLMM machinery is unwarranted. Optionally computes the intervals
#' within a grouping variable.
#'
#' @param data A data frame.
#' @param var Character scalar. The categorical column to summarise.
#' @param group_var Character scalar or `NULL`. Optional grouping column; when
#'   supplied, prevalences are computed within each group.
#' @param method Character. `"wilson"` (default), `"clopper-pearson"`, or
#'   `"wald"`.
#' @param conf_level Numeric. Interval confidence level. Default `0.95`.
#'
#' @return A [tibble::tibble()] with columns (optional `group`), `category`,
#'   `n`, `total`, `proportion`, `ci_lower`, `ci_upper`, `method`.
#'
#' @family categorical
#' @importFrom tibble tibble
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_number
#' @export
#'
#' @examples
#' df <- data.frame(
#'   staff = c(rep("pharmacist", 55), rep("technician", 30), rep("other", 15))
#' )
#' mysterycall_prevalence_ci(df, "staff")
mysterycall_prevalence_ci <- function(
    data, var, group_var = NULL,
    method = c("wilson", "clopper-pearson", "wald"),
    conf_level = 0.95) {

  method <- match.arg(method)
  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_string(var)
  need <- if (is.null(group_var)) var else c(var, group_var)
  checkmate::assert_names(names(data), must.include = need)
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)

  one_block <- function(x, grp_label) {
    x <- x[!is.na(x)]
    total <- length(x)
    counts <- table(x)
    cats <- names(counts)
    ci <- t(vapply(seq_along(cats), function(i) {
      cnt <- as.integer(counts[i])
      switch(method,
        "wilson"          = .mc_wilson_ci(cnt, total, conf_level),
        "clopper-pearson" = .mc_clopper_pearson(cnt, total, conf_level),
        "wald" = {
          p <- cnt / total
          z <- stats::qnorm(1 - (1 - conf_level) / 2)
          h <- z * sqrt(p * (1 - p) / total)
          c(max(0, p - h), min(1, p + h))
        }
      )
    }, numeric(2)))
    out <- tibble::tibble(
      category   = cats,
      n          = as.integer(counts),
      total      = total,
      proportion = round(as.integer(counts) / total, 3),
      ci_lower   = round(ci[, 1], 3),
      ci_upper   = round(ci[, 2], 3),
      method     = method
    )
    if (!is.null(grp_label)) out <- cbind(group = grp_label, out)
    out
  }

  if (is.null(group_var)) {
    return(tibble::as_tibble(one_block(data[[var]], NULL)))
  }
  parts <- lapply(
    split(data[[var]], as.character(data[[group_var]])),
    function(x) x
  )
  res <- do.call(rbind, Map(function(x, g) one_block(x, g), parts, names(parts)))
  tibble::as_tibble(res)
}


# ---- non-parametric group comparison ----------------------------------------

#' Rank-Based Comparison of a Numeric Outcome Across Groups
#'
#' Kruskal-Wallis (three or more groups) or Mann-Whitney / Wilcoxon rank-sum
#' (two groups) test for a skewed numeric outcome -- e.g. wait times or quoted
#' prices (Campbell 2013, Lungfiel 2023) -- with an effect size and per-group
#' medians (IQR).
#'
#' @param data A data frame.
#' @param outcome_var Character scalar. Numeric outcome column.
#' @param group_var Character scalar. Grouping column (two or more levels).
#'
#' @return A `mysterycall_rank_comparison` object: a list with `method`,
#'   `statistic`, `df`, `p_value`, `effect_size`, `effect_type`,
#'   `group_summary` (a tibble of `n`, `median`, `q1`, `q3`), and `n`.
#'
#' @family categorical
#' @importFrom tibble tibble
#' @importFrom stats kruskal.test wilcox.test median quantile qnorm
#' @importFrom checkmate assert_data_frame assert_string assert_names
#' @export
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   price = c(rexp(20, 1 / 20), rexp(20, 1 / 35)),
#'   payer = rep(c("A", "B"), each = 20)
#' )
#' mysterycall_compare_ranks(df, "price", "payer")
mysterycall_compare_ranks <- function(data, outcome_var, group_var) {
  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_string(outcome_var)
  checkmate::assert_string(group_var)
  checkmate::assert_names(names(data), must.include = c(outcome_var, group_var))

  df <- data[!is.na(data[[outcome_var]]) & !is.na(data[[group_var]]), , drop = FALSE]
  y <- as.numeric(df[[outcome_var]])
  g <- as.factor(df[[group_var]])
  k <- nlevels(g)
  if (k < 2L) stop("`group_var` must have at least two non-missing levels.", call. = FALSE)
  n <- length(y)

  if (k == 2L) {
    wt <- suppressWarnings(stats::wilcox.test(y ~ g, exact = FALSE))
    method <- "Mann-Whitney U (Wilcoxon rank-sum)"
    statistic <- as.numeric(wt$statistic)
    df_out <- NA_real_
    p_value <- wt$p.value
    # rank-biserial-style effect size r = |Z| / sqrt(N)
    z <- stats::qnorm(wt$p.value / 2, lower.tail = FALSE)
    effect_size <- round(abs(z) / sqrt(n), 3)
    effect_type <- "r (Z/sqrt(N))"
  } else {
    kt <- stats::kruskal.test(y ~ g)
    method <- "Kruskal-Wallis"
    statistic <- as.numeric(kt$statistic)
    df_out <- as.numeric(kt$parameter)
    p_value <- kt$p.value
    # epsilon-squared effect size
    effect_size <- round(as.numeric(kt$statistic) / ((n^2 - 1) / (n + 1)), 3)
    effect_type <- "epsilon-squared"
  }

  gs <- do.call(rbind, lapply(split(y, g), function(v) {
    data.frame(
      n      = length(v),
      median = round(stats::median(v), 2),
      q1     = round(stats::quantile(v, 0.25, names = FALSE), 2),
      q3     = round(stats::quantile(v, 0.75, names = FALSE), 2),
      stringsAsFactors = FALSE
    )
  }))
  group_summary <- tibble::tibble(
    group = rownames(gs), n = gs$n, median = gs$median, q1 = gs$q1, q3 = gs$q3
  )

  structure(
    list(
      method = method, statistic = statistic, df = df_out, p_value = p_value,
      effect_size = effect_size, effect_type = effect_type,
      group_summary = group_summary, n = n,
      settings = list(outcome_var = outcome_var, group_var = group_var)
    ),
    class = "mysterycall_rank_comparison"
  )
}


# ---- shared p-value formatting + S3 methods ---------------------------------

.mc_fmt_p <- function(p) {
  if (is.na(p)) return("NA")
  if (p < 0.001) "p < 0.001" else sprintf("p = %.3f", p)
}

#' Print a `mysterycall_categorical_test` object
#'
#' @param x A `mysterycall_categorical_test` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return `x`, invisibly.
#' @export
print.mysterycall_categorical_test <- function(x, ...) {
  cat(sprintf("<mysterycall_categorical_test> %s x %s\n",
              x$settings$row_var, x$settings$col_var))
  cat("  ", x$method, "\n", sep = "")
  if (!is.na(x$statistic)) {
    cat(sprintf("  statistic = %.3f, df = %g, %s\n",
                x$statistic, x$df, .mc_fmt_p(x$p_value)))
  } else {
    cat(sprintf("  %s (min expected count = %.2f)\n",
                .mc_fmt_p(x$p_value), x$min_expected))
  }
  cat(sprintf("  Cramer's V = %.3f (%s); n = %d\n",
              x$cramers_v, x$effect_size, x$n))
  if (!is.null(x$posthoc)) {
    cat("  post-hoc pairwise proportions (", x$settings$p_adjust, "-adjusted):\n", sep = "")
    print(as.data.frame(x$posthoc), row.names = FALSE)
  }
  invisible(x)
}

#' Print a `mysterycall_cmh_test` object
#'
#' @param x A `mysterycall_cmh_test` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return `x`, invisibly.
#' @export
print.mysterycall_cmh_test <- function(x, ...) {
  cat(sprintf("<mysterycall_cmh_test> %d strata, n = %d\n", x$n_strata, x$n))
  cat("  ", x$method, "\n", sep = "")
  cat(sprintf("  statistic = %.3f, df = %g, %s\n",
              x$statistic, x$df, .mc_fmt_p(x$p_value)))
  if (!is.na(x$estimate)) {
    cat(sprintf("  common OR = %.3f (95%% CI %.3f-%.3f)\n",
                x$estimate, x$conf_int[1], x$conf_int[2]))
  }
  invisible(x)
}

#' Print a `mysterycall_rank_comparison` object
#'
#' @param x A `mysterycall_rank_comparison` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return `x`, invisibly.
#' @export
print.mysterycall_rank_comparison <- function(x, ...) {
  cat(sprintf("<mysterycall_rank_comparison> %s by %s\n",
              x$settings$outcome_var, x$settings$group_var))
  cat("  ", x$method, "\n", sep = "")
  df_txt <- if (is.na(x$df)) "" else sprintf(", df = %g", x$df)
  cat(sprintf("  statistic = %.3f%s, %s\n", x$statistic, df_txt, .mc_fmt_p(x$p_value)))
  cat(sprintf("  effect size %s = %.3f; n = %d\n",
              x$effect_type, x$effect_size, x$n))
  print(as.data.frame(x$group_summary), row.names = FALSE)
  invisible(x)
}

#' Coerce a `mysterycall_rank_comparison` object to a data frame
#'
#' @param x A `mysterycall_rank_comparison` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return A `data.frame` representation of `x`.
#' @export
as.data.frame.mysterycall_rank_comparison <- function(x, ...) {
  as.data.frame(x$group_summary, ...)
}
