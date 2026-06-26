#' Build a Table 1 for mystery caller studies
#'
#' Produces a publication-ready summary table describing physician and study
#' characteristics, optionally stratified by a grouping variable (typically
#' `"insurance"`). Continuous variables are summarized with median \[IQR\]
#' and/or mean (SD); categorical variables with n (%). Statistical tests are
#' chosen automatically: Wilcoxon rank-sum or Kruskal-Wallis for continuous
#' variables, chi-square or Fisher's exact for categorical.
#'
#' @name mysterycall_table1
NULL

# -- ACOG district label lookup -----------------------------------------------
# Maps "District X" -> "District X (ST, ST, ...)" using two-letter abbreviations.
# Derived from .mc_acog_map in assign_region.R; hardcoded to avoid a runtime
# dependency on the acog_districts dataset being loaded.
# Source of truth: acog_districts dataset (acog_districts.R).
# District III = NJ, PA (DE is in IV); District XI = TX; no District X.
# Source of truth: acog_districts dataset (acog_districts.R).
# District III = NJ, PA (DE is in IV); District XI = TX; no District X.
# Abbreviations are sorted alphabetically within each district to match the dataset.
.ACOG_DISTRICT_ABBREVS <- c(
  "District I"    = "CT, MA, ME, NH, RI, VT",
  "District II"   = "NY",
  "District III"  = "NJ, PA",
  "District IV"   = "DC, DE, GA, MD, NC, PR, SC, VA, WV",
  "District V"    = "IN, KY, MI, OH",
  "District VI"   = "IA, IL, MN, ND, NE, SD, WI",
  "District VII"  = "AL, AR, KS, LA, MO, MS, OK, TN",
  "District VIII" = "AK, AZ, CO, HI, ID, MT, NM, NV, OR, UT, WA, WY",
  "District IX"   = "CA",
  "District XI"   = "TX",
  "District XII"  = "FL"
)

.t1_expand_acog_level <- function(level) {
  abbrevs <- .ACOG_DISTRICT_ABBREVS[level]
  ifelse(is.na(abbrevs), level, sprintf("%s (%s)", level, abbrevs))
}

# -- Internal formatters -------------------------------------------------------

#' Format n (%)
#'
#' @param k Count.
#' @param n Total.
#' @param digits Number of digits for percentage.
#'
#' @return Formatted character string.
#' @family table
#' @keywords internal
.t1_fmt_pct <- function(k, n, digits) {
  if (n == 0L) return("0 (--%)")
  sprintf(paste0("%d (%.", digits, "f%%)"), k, k / n * 100)
}

#' Format Median [IQR]
#'
#' @param x Numeric vector.
#' @param digits Number of digits.
#'
#' @return Formatted character string.
#' @family table
#' @keywords internal
.t1_fmt_median_iqr <- function(x, digits) {
  x <- x[!is.na(x)]
  if (!length(x)) return(NA_character_)
  qs <- stats::quantile(x, probs = c(0.25, 0.75), na.rm = FALSE)
  fmt <- paste0("%.", digits, "f")
  sprintf(paste0(fmt, " [", fmt, "-", fmt, "]"),
          stats::median(x), qs[[1L]], qs[[2L]])
}

#' Format Mean (SD)
#'
#' @param x Numeric vector.
#' @param digits Number of digits.
#'
#' @return Formatted character string.
#' @family table
#' @keywords internal
.t1_fmt_mean_sd <- function(x, digits) {
  x <- x[!is.na(x)]
  if (!length(x)) return(NA_character_)
  fmt <- paste0("%.", digits, "f")
  sprintf(paste0(fmt, " (", fmt, ")"), mean(x), stats::sd(x))
}

#' Format P-Value for Table 1
#'
#' @param p Numeric p-value.
#'
#' @return Formatted character string (e.g., "<0.001").
#' @family table
#' @keywords internal
.t1_fmt_pval <- function(p) {
  if (is.na(p)) return(NA_character_)
  if (p < 0.001) "<0.001" else sprintf("%.3f", p)
}

# -- Internal tests ------------------------------------------------------------

#' Calculate P-Value for Continuous Variables
#'
#' Uses Wilcoxon rank-sum or Kruskal-Wallis test.
#'
#' @param x Numeric vector.
#' @param g Grouping vector.
#'
#' @return Numeric p-value or NA.
#' @family table
#' @keywords internal
.t1_cont_pvalue <- function(x, g) {
  groups <- sort(unique(g[!is.na(g)]))
  if (length(groups) < 2L) return(NA_real_)
  if (length(groups) == 2L) {
    gd <- lapply(groups, function(lv) x[!is.na(g) & g == lv & !is.na(x)])
    if (any(!lengths(gd))) return(NA_real_)
    res <- tryCatch(
      suppressWarnings(stats::wilcox.test(gd[[1L]], gd[[2L]], exact = FALSE)),
      error = function(e) NULL
    )
  } else {
    df  <- data.frame(x = x[!is.na(g) & !is.na(x)], g = g[!is.na(g) & !is.na(x)])
    res <- tryCatch(stats::kruskal.test(x ~ g, data = df), error = function(e) NULL)
  }
  if (is.null(res)) NA_real_ else res$p.value
}

#' Calculate P-Value for Categorical Variables
#'
#' Uses Fisher's exact or chi-square test.
#'
#' @param x Vector.
#' @param g Grouping vector.
#' @param min_cell Minimum cell size for chi-square.
#'
#' @return Numeric p-value or NA.
#' @family table
#' @keywords internal
.t1_cat_pvalue <- function(x, g, min_cell = 5L) {
  ct <- table(x, g, useNA = "no")
  if (nrow(ct) < 2L || ncol(ct) < 2L) return(NA_real_)
  use_fisher <- ncol(ct) == 2L && any(ct < min_cell)
  res <- tryCatch(
    if (use_fisher) {
      stats::fisher.test(ct)
    } else {
      suppressWarnings(stats::chisq.test(ct, correct = FALSE))
    },
    error = function(e) NULL
  )
  if (is.null(res)) NA_real_ else res$p.value
}

# -- One-variable row builder --------------------------------------------------

#' Build Continuous Rows for Table 1
#'
#' @param x Numeric vector.
#' @param label Variable label.
#' @param group_vec Grouping vector.
#' @param groups Unique groups.
#' @param group_col_names Column names for groups.
#' @param include_overall Logical; include overall column.
#' @param cont_stats Stats to include (median_iqr, mean_sd).
#' @param digits Number of digits.
#' @param emit_pvalue Logical; include p-value.
#' @param min_cell Minimum cell size.
#'
#' @return A list of rows.
#' @family table
#' @keywords internal
.t1_rows_continuous <- function(x, label, group_vec, groups, group_col_names,
                                include_overall, cont_stats, digits,
                                emit_pvalue, min_cell) {
  pval <- if (emit_pvalue && !is.null(group_vec)) {
    .t1_cont_pvalue(x, group_vec)
  } else NA_real_

  stat_rows <- lapply(seq_along(cont_stats), function(si) {
    stat  <- cont_stats[[si]]
    label_row <- if (stat == "median_iqr") "Median [IQR]" else "Mean (SD)"
    fmt_fn    <- if (stat == "median_iqr") .t1_fmt_median_iqr else .t1_fmt_mean_sd

    row <- list(variable = label, level = label_row)

    if (include_overall)  row[["Overall"]]  <- fmt_fn(x, digits)

    if (!is.null(group_vec)) {
      for (i in seq_along(groups)) {
        xg <- x[!is.na(group_vec) & group_vec == groups[[i]]]
        row[[group_col_names[[i]]]] <- fmt_fn(xg, digits)
      }
    }

    row[["p_value"]] <- if (si == 1L) .t1_fmt_pval(pval) else NA_character_
    as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
  })

  do.call(rbind, stat_rows)
}
#' Build Categorical Rows for Table 1
#'
#' @param x Vector.
#' @param label Variable label.
#' @param group_vec Grouping vector.
#' @param groups Unique groups.
#' @param group_col_names Column names for groups.
#' @param include_overall Logical; include overall column.
#' @param digits Number of digits.
#' @param emit_pvalue Logical; include p-value.
#' @param min_cell Minimum cell size.
#'
#' @return A list of rows.
#' @family table
#' @keywords internal
.t1_rows_categorical <- function(x, label, group_vec, groups, group_col_names,
                                 include_overall, digits,
                                 emit_pvalue, min_cell) {
  x_chr <- as.character(x)
  lvls  <- if (is.factor(x)) levels(x) else sort(unique(x_chr[!is.na(x_chr)]))

  pval <- if (emit_pvalue && !is.null(group_vec)) {
    .t1_cat_pvalue(x_chr, group_vec, min_cell)
  } else NA_real_

  level_rows <- lapply(seq_along(lvls), function(li) {
    lv <- lvls[[li]]

    row <- list(variable = label, level = lv)

    if (include_overall) {
      n_nonmiss <- sum(!is.na(x_chr))
      k         <- sum(!is.na(x_chr) & x_chr == lv)
      row[["Overall"]] <- .t1_fmt_pct(k, n_nonmiss, digits)
    }

    if (!is.null(group_vec)) {
      for (i in seq_along(groups)) {
        mask   <- !is.na(group_vec) & group_vec == groups[[i]]
        xg     <- x_chr[mask]
        n_nm   <- sum(!is.na(xg))
        k_g    <- sum(!is.na(xg) & xg == lv)
        row[[group_col_names[[i]]]] <- .t1_fmt_pct(k_g, n_nm, digits)
      }
    }

    row[["p_value"]] <- if (li == 1L) .t1_fmt_pval(pval) else NA_character_
    as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
  })

  do.call(rbind, level_rows)
}


#' Produce a Table 1 summary
#'
#' @param data A data frame, typically the output of
#'   [mysterycall_clean_phase1()] merged with genderize results.
#' @param covariates Character vector of column names to include as rows.
#'   Numeric columns are treated as continuous; all others are categorical.
#' @param stratify_by Optional single column name used as the stratifying
#'   variable (e.g. `"insurance"`). When `NULL` (default) a single Overall
#'   column is produced with no hypothesis tests.
#' @param include_overall Logical. When `TRUE` (default) an Overall column
#'   is included even when `stratify_by` is set.
#' @param cont_stats Character vector controlling which statistics are shown
#'   for numeric variables. Valid choices are `"median_iqr"` (default, first)
#'   and `"mean_sd"`. Both can be supplied to show two rows per variable.
#' @param digits Number of decimal places for continuous statistics and
#'   percentages. Default `1`.
#' @param p_value Logical. When `TRUE` (default) and `stratify_by` is set,
#'   a `p_value` column is appended (Wilcoxon/Kruskal-Wallis for continuous,
#'   chi-square/Fisher's exact for categorical).
#' @param min_cell Minimum expected cell count below which Fisher's exact
#'   test is used instead of chi-square (2-group categorical only). Default `5`.
#' @param variable_labels Optional named character vector mapping column names
#'   to display labels, e.g. `c(wait_days = "Wait time (days)")`. Unlabelled
#'   columns use their column name.
#' @param output_path Character scalar or `NULL`. When a path ending in
#'   `.docx` is supplied (e.g. `"table1.docx"`), the table is exported to a
#'   Word document via the `flextable` and `officer` packages and the path is
#'   stored in `$docx_path`. Requires both packages to be installed.
#' @param acog_district_col Character scalar or `NULL`. Name of the column
#'   containing ACOG district assignments (e.g. `"acog_district"`). When set,
#'   two things happen automatically: (1) the variable label is expanded to
#'   "American College of Obstetricians and Gynecologists (ACOG) District", and
#'   (2) each district level is annotated with its two-letter state
#'   abbreviations, e.g. "District I (CT, ME, MA, NH, RI, VT)". A
#'   `variable_labels` entry for the same column takes precedence over the
#'   auto-generated label.
#'
#' @return A list of class `mysterycall_table1` with:
#' \describe{
#'   \item{`table`}{Tibble with columns `variable`, `level`, `Overall` (if
#'     `include_overall`), one column per stratum, and `p_value` (if
#'     `p_value = TRUE` and stratified). Each row is one statistic or one
#'     category level.}
#'   \item{`column_ns`}{Named integer vector of sample sizes per column.}
#'   \item{`stratify_by`}{The name of the stratifying column, or `NULL`.}
#'   \item{`n`}{Total rows in `data`.}
#'   \item{`docx_path`}{Character path to the written `.docx` file, or `NULL`
#'     when `output_path` is not supplied.}
#' }
#'
#' @importFrom stats wilcox.test kruskal.test chisq.test fisher.test sd median quantile
#' @importFrom tibble as_tibble
#' @family table
#' @seealso [mysterycall_table1_gtsummary()], [mysterycall_wait_time_summary()],
#'   [mysterycall_acceptance_rate()]
#' @export
#'
#' @examples
#' df <- data.frame(
#'   gender    = c("Male", "Female", "Female", "Male", "Male", "Female"),
#'   academic  = c("University", "Private Practice", "Private Practice",
#'                 "University", "Private Practice", "University"),
#'   wait_days = c(10, 25, 14, 30, 7, 21),
#'   insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS", "Medicaid", "BCBS")
#' )
#' result <- mysterycall_table1(
#'   df,
#'   covariates   = c("gender", "academic", "wait_days"),
#'   stratify_by  = "insurance"
#' )
#' result$table
mysterycall_table1 <- function(data,
                                covariates,
                                stratify_by      = NULL,
                                include_overall  = TRUE,
                                cont_stats       = c("median_iqr", "mean_sd"),
                                digits           = 1L,
                                p_value          = TRUE,
                                min_cell         = 5L,
                                variable_labels  = NULL,
                                output_path      = NULL,
                                acog_district_col = NULL) {

  # -- Validate ---------------------------------------------------------------
  validate_dataframe(data, name = "data", allow_zero_rows = FALSE)
  validate_required_columns(data, covariates, name = "data")

  if (!is.null(stratify_by)) {
    validate_required_columns(data, stratify_by, name = "data")
    if (!is.character(stratify_by) || length(stratify_by) != 1L) {
      stop("`stratify_by` must be a single column name.", call. = FALSE)
    }
  }

  cont_stats <- match.arg(cont_stats, c("median_iqr", "mean_sd"), several.ok = TRUE)

  if (!is.numeric(digits) || length(digits) != 1L || digits < 0) {
    stop("`digits` must be a non-negative number.", call. = FALSE)
  }
  digits <- as.integer(digits)

  if (!is.null(variable_labels)) {
    if (!is.character(variable_labels) || is.null(names(variable_labels))) {
      stop("`variable_labels` must be a named character vector.", call. = FALSE)
    }
  }

  emit_pvalue <- isTRUE(p_value) && !is.null(stratify_by)

  # -- Group setup ------------------------------------------------------------
  if (!is.null(stratify_by)) {
    group_vec      <- data[[stratify_by]]
    groups         <- sort(unique(group_vec[!is.na(group_vec)]))
    group_ns       <- vapply(groups,
                             function(g) sum(!is.na(group_vec) & group_vec == g),
                             integer(1L))
    group_col_names <- sprintf("%s (N=%d)", groups, group_ns)
  } else {
    group_vec <- NULL; groups <- character(0L); group_ns <- integer(0L)
    group_col_names <- character(0L)
  }

  n_overall <- nrow(data)

  # -- Build one block of rows per covariate ---------------------------------
  blocks <- lapply(covariates, function(cv) {
    x <- data[[cv]]

    # Determine display label: explicit variable_labels > acog auto-label > column name
    is_acog_col <- !is.null(acog_district_col) && identical(cv, acog_district_col)
    label <- if (!is.null(variable_labels) && cv %in% names(variable_labels)) {
      variable_labels[[cv]]
    } else if (is_acog_col) {
      "American College of Obstetricians and Gynecologists (ACOG) District"
    } else {
      cv
    }

    # Expand district level names to include state abbreviations
    if (is_acog_col && (is.character(x) || is.factor(x))) {
      was_factor <- is.factor(x)
      x_chr      <- as.character(x)
      expanded   <- .t1_expand_acog_level(x_chr)
      x <- if (was_factor) {
        orig_lvls <- levels(x)
        factor(expanded, levels = .t1_expand_acog_level(orig_lvls))
      } else {
        expanded
      }
    }

    if (is.numeric(x) && !is.logical(x)) {
      .t1_rows_continuous(
        x, label, group_vec, groups, group_col_names,
        include_overall, cont_stats, digits, emit_pvalue, min_cell
      )
    } else {
      .t1_rows_categorical(
        x, label, group_vec, groups, group_col_names,
        include_overall, digits, emit_pvalue, min_cell
      )
    }
  })

  tbl <- tibble::as_tibble(do.call(rbind, blocks))

  # Drop p_value column entirely when not requested
  if (!emit_pvalue && "p_value" %in% names(tbl)) {
    tbl[["p_value"]] <- NULL
  }

  # -- Column N metadata ------------------------------------------------------
  col_ns <- c(
    if (include_overall) c(Overall = n_overall) else integer(0L),
    if (!is.null(stratify_by)) setNames(group_ns, groups) else integer(0L)
  )

  docx_path <- NULL
  if (!is.null(output_path)) {
    if (!requireNamespace("flextable", quietly = TRUE) ||
        !requireNamespace("officer",   quietly = TRUE)) {
      warning(
        "Packages 'flextable' and 'officer' are required for Word export. ",
        "Install with: install.packages(c('flextable','officer'))",
        call. = FALSE
      )
    } else {
      ft  <- flextable::flextable(as.data.frame(tbl))
      ft  <- flextable::autofit(ft)
      ft  <- flextable::theme_booktabs(ft)
      doc <- officer::read_docx()
      doc <- flextable::body_add_flextable(doc, ft)
      print(doc, target = output_path)
      message("Table 1 written to: ", output_path)
      docx_path <- output_path
    }
  }

  structure(
    list(table       = tbl,
         column_ns   = col_ns,
         stratify_by = stratify_by,
         n           = n_overall,
         docx_path   = docx_path),
    class = "mysterycall_table1"
  )
}

#' Print a mysterycall_table1 object
#'
#' Prints a formatted Table 1 with column sample sizes in the header and the
#' underlying tibble displayed via [print.tbl_df()].
#'
#' @param x A `mysterycall_table1` object returned by [mysterycall_table1()].
#' @param ... Additional arguments passed to [print.tbl_df()].
#' @return Invisibly returns `x`.
#' @seealso [mysterycall_table1()] which produces this object;
#'   [mysterycall_table1_gtsummary()] for a publication-ready `gtsummary` alternative.
#' @family table
#' @export
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   age = c(25, 30, 35, 40),
#'   sex = c("M", "F", "F", "M")
#' )
#' t1 <- mysterycall_table1(df, vars = c("age", "sex"))
#' print(t1)
#' }
print.mysterycall_table1 <- function(x, ...) {
  ns_str <- paste(sprintf("%s N=%d", names(x$column_ns), x$column_ns),
                  collapse = ", ")
  cat(sprintf("Table 1 (%s)\n", ns_str))
  if (!is.null(x$stratify_by)) {
    cat(sprintf("Stratified by: %s\n", x$stratify_by))
  }
  cat("\n")
  print(x$table, n = Inf, ...)
  invisible(x)
}

#' Convert a mysterycall_table1 to a flextable (internal)
#'
#' @param x A `mysterycall_table1` object.
#' @param ... Passed to [flextable::flextable()].
#' @return A `flextable` object.
#' @keywords internal
#' Coerce a mysterycall_table1 to a plain data frame
#'
#' @param x A `mysterycall_table1` object.
#' @param ... Ignored.
#' @return A data frame.
#' @export
as.data.frame.mysterycall_table1 <- function(x, ...) {
  as.data.frame(x$table, stringsAsFactors = FALSE)
}

#' Convert a mysterycall_table1 to a flextable (internal)
#'
#' @param x A `mysterycall_table1` object.
#' @param ... Passed to [flextable::flextable()].
#' @return A `flextable` object.
#' @keywords internal
as_flex_table.mysterycall_table1 <- function(x, ...) {
  if (!requireNamespace("flextable", quietly = TRUE))
    stop("Install 'flextable' for Word export: install.packages('flextable')",
         call. = FALSE)
  tbl_df <- as.data.frame(x$table)
  ft <- flextable::flextable(tbl_df, ...)
  ft <- flextable::autofit(ft)
  ft <- flextable::theme_booktabs(ft)
  ft
}
