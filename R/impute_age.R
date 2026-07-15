#' Physician age imputation and categorization
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name mysterycall_age
NULL


#' Impute physician age from medical school graduation year
#'
#' Estimates a physician's current age as:
#' \deqn{\text{age} = (\text{ref\_year} - \text{grad\_year}) + \text{age\_offset}}
#' where `age_offset` (default 27) is the median age at US medical school
#' graduation. This method has been validated against Doximity birth-year data
#' for 32,998 OB/GYN physicians (r = 0.962, MAE = 2.1 years) and 348 ENT
#' physicians (r = 0.957, MAE = 1.7 years); see the technical appendix.
#'
#' Implausible results (age < 0 after computing, or age < `min_age`) are set
#' to `NA` with a warning.
#'
#' @param grad_year Integer or numeric vector of medical school graduation
#'   years (4-digit, e.g. `1995`). `NA` values produce `NA` output.
#' @param ref_year Integer scalar. Reference year for the calculation.
#'   Defaults to the current calendar year (`as.integer(format(Sys.Date(), "%Y"))`).
#' @param age_offset Integer scalar. Assumed age at graduation. Default `27L`
#'   (validated median for US physicians).
#' @param min_age Numeric. Minimum plausible physician age. Values below this
#'   threshold are replaced with `NA`. Default `25`.
#' @param max_age Numeric. Maximum plausible physician age. Values above this
#'   threshold are replaced with `NA`. Default `90`.
#'
#' @return Integer vector the same length as `grad_year`. `NA` is returned
#'   for elements where `grad_year` is `NA`, where the computed age is below
#'   `min_age`, or where it exceeds `max_age` (with a [base::warning()] in
#'   each case).
#'
#' @references
#' Muffly T, et al. Validation of Physician Age Imputation Method
#' (Graduation Year + 27). Technical Appendix, 2026.
#'
#' @family provider characteristics
#' @seealso [mysterycall_age_category()]
#' @export
#'
#' @examples
#' # Physician who graduated in 1995; current year 2026 -> age ~ 58
#' mysterycall_impute_age(1995)
#'
#' # Vectorized
#' mysterycall_impute_age(c(1980, 1995, 2010, NA))
mysterycall_impute_age <- function(grad_year,
                                    ref_year   = as.integer(format(Sys.Date(), "%Y")),
                                    age_offset = 27L,
                                    min_age    = 25,
                                    max_age    = 90) {

  if (!is.numeric(grad_year)) {
    stop("`grad_year` must be a numeric vector.", call. = FALSE)
  }
  if (!is.numeric(ref_year) || length(ref_year) != 1L || is.na(ref_year) || ref_year < 1900L) {
    stop("`ref_year` must be a single year >= 1900.", call. = FALSE)
  }
  if (!is.numeric(age_offset) || length(age_offset) != 1L || is.na(age_offset) || age_offset < 0L) {
    stop("`age_offset` must be a single non-negative number.", call. = FALSE)
  }

  future_grad <- !is.na(grad_year) & grad_year > ref_year
  if (any(future_grad)) {
    message(sprintf(
      "%d graduation year(s) exceed ref_year (%d) and will produce NA ages.",
      sum(future_grad), ref_year
    ))
  }

  age <- as.integer(ref_year - grad_year + age_offset)
  # Graduation years after the reference year describe physicians who have not
  # graduated; force NA rather than relying on the min_age filter to catch them
  # (a 1-2 year-future grad year otherwise yields a plausible-looking age).
  age[future_grad] <- NA_integer_

  implausible <- !is.na(age) & (age < min_age | age > max_age)
  n_impl <- sum(implausible)
  if (n_impl > 0L) {
    warning(sprintf(
      "%d imputed age(s) outside [%g, %g] set to NA. Check graduation years.",
      n_impl, min_age, max_age
    ), call. = FALSE)
    age[implausible] <- NA_integer_
  }

  age
}


#' Bin physician ages into decade categories
#'
#' Returns a character label for each age, using decade brackets suitable for
#' Table 1 demographic summaries. The break points match the standard used in
#' mystery caller studies: Under 30, 30-39, 40-49, 50-59, 60-69, 70+.
#'
#' @param age Numeric vector of physician ages. `NA` values return `na_label`.
#' @param breaks Numeric vector of break points defining the category
#'   boundaries. Default `c(30, 40, 50, 60, 70)` produces six bins:
#'   `"<30"`, `"30-39"`, `"40-49"`, `"50-59"`, `"60-69"`, `"70+"`.
#' @param labels Character vector of length `length(breaks) + 1` giving the
#'   label for each bin. When `NULL` (default) labels are auto-generated from
#'   the break points.
#' @param na_label Character scalar used for `NA` inputs. Default `"Unknown"`.
#' @param as_factor Logical. When `TRUE` returns an ordered factor with levels
#'   in the order defined by `labels`. Default `FALSE`.
#'
#' @return Character vector (or ordered factor) the same length as `age`.
#'
#' @family provider characteristics
#' @seealso [mysterycall_impute_age()]
#' @export
#'
#' @examples
#' ages <- c(28, 35, 47, 55, 63, 72, NA)
#' mysterycall_age_category(ages)
#' # [1] "<30"     "30-39"   "40-49"   "50-59"   "60-69"   "70+"     "Unknown"
mysterycall_age_category <- function(age,
                                      breaks    = c(30, 40, 50, 60, 70),
                                      labels    = NULL,
                                      na_label  = "Unknown",
                                      as_factor = FALSE) {

  if (!is.numeric(age)) {
    stop("`age` must be a numeric vector.", call. = FALSE)
  }
  if (!is.numeric(breaks) || length(breaks) < 1L || anyNA(breaks) || is.unsorted(breaks)) {
    stop("`breaks` must be an increasing numeric vector with at least one value.", call. = FALSE)
  }
  if (!is.character(na_label) || length(na_label) != 1L) {
    stop("`na_label` must be a single character string.", call. = FALSE)
  }

  n_bins <- length(breaks) + 1L

  if (is.null(labels)) {
    lbl <- character(n_bins)
    lbl[[1L]]     <- sprintf("<%g", breaks[[1L]])
    lbl[[n_bins]] <- sprintf("%g+", breaks[[length(breaks)]])
    if (n_bins > 2L) {
      for (i in seq(2L, n_bins - 1L)) {
        lbl[[i]] <- sprintf("%g-%g", breaks[[i - 1L]], breaks[[i]] - 1L)
      }
    }
  } else {
    if (!is.character(labels) || length(labels) != n_bins) {
      stop(sprintf("`labels` must be a character vector of length %d.", n_bins), call. = FALSE)
    }
    lbl <- labels
  }

  result <- ifelse(
    is.na(age), na_label,
    {
      idx <- findInterval(age, breaks) + 1L   # 1-based bin index
      lbl[pmin(idx, n_bins)]
    }
  )

  if (as_factor) {
    all_levels <- c(lbl, na_label)
    result <- factor(result, levels = unique(all_levels), ordered = TRUE)
  }

  result
}
