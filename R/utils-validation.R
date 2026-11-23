#' Validate a Data Frame
#'
#' @param x Object to validate.
#' @param name Character scalar naming the object for error messages.
#' @param allow_null Logical flag. When `TRUE`, `NULL` is accepted without error.
#' @param allow_zero_rows Logical flag. When `FALSE`, an error is thrown if `nrow(x) == 0`.
#'
#' @return The validated object (invisibly).
#' @family validation
#' @keywords internal
validate_dataframe <- function(x, name = "data", allow_null = FALSE, allow_zero_rows = TRUE) {
  checkmate::assert_string(name, min.chars = 1, .var.name = "name")
  checkmate::assert_flag(allow_null, .var.name = "allow_null")
  checkmate::assert_flag(allow_zero_rows, .var.name = "allow_zero_rows")
  if (is.null(x)) {
    if (allow_null) {
      return(invisible(x))
    }
    stop(sprintf("`%s` must be a data frame; received NULL.", name), call. = FALSE)
  }

  if (!inherits(x, "data.frame")) {
    stop(sprintf("`%s` must be a data frame; received an object of class %s.", name, paste(class(x), collapse = ", ")), call. = FALSE)
  }

  if (!allow_zero_rows && !nrow(x)) {
    stop(sprintf("`%s` must contain at least one row.", name), call. = FALSE)
  }

  invisible(x)
}


#' Validate a Scalar Positive Numeric Value
#'
#' @param x Numeric scalar to validate.
#' @param name Character scalar naming the object for error messages.
#' @param allow_null Logical flag. When `TRUE`, `NULL` is accepted without error.
#'
#' @return The validated object (invisibly).
#' @family validation
#' @keywords internal
validate_scalar_positive_numeric <- function(x, name, allow_null = TRUE) {
  checkmate::assert_string(name, min.chars = 1, .var.name = "name")
  checkmate::assert_flag(allow_null, .var.name = "allow_null")
  if (is.null(x)) {
    if (allow_null) {
      return(invisible(x))
    }
    stop(sprintf("`%s` must not be NULL.", name), call. = FALSE)
  }

  checkmate::assert_number(
    x,
    lower = 0,
    finite = TRUE,
    na.ok = FALSE,
    .var.name = name
  )

  invisible(x)
}

#' Validate Required Columns in a Data Frame
#'
#' @param x Data frame to check.
#' @param required Character vector of required column names.
#' @param name Character scalar naming the data frame for error messages.
#'
#' @return The validated data frame (invisibly).
#' @family validation
#' @keywords internal
validate_required_columns <- function(x, required, name = "data") {
  checkmate::assert_data_frame(x, .var.name = "x")
  checkmate::assert_character(required, null.ok = TRUE, any.missing = FALSE, .var.name = "required")
  checkmate::assert_string(name, min.chars = 1, .var.name = "name")
  # Decompose any formula-like terms (e.g., containing :, *, +, |) into individual variable names
  decomposed_required <- unique(unlist(lapply(required, function(term) {
    if (grepl("[:\\*\\+\\|\\(\\)]", term)) {
      tryCatch(all.vars(stats::as.formula(paste("~", term))), error = function(e) term)
    } else {
      term
    }
  })))

  missing_required <- setdiff(decomposed_required, names(x))
  if (length(missing_required)) {
    available_cols <- names(x)

    suggestion_lines <- vapply(missing_required, function(col) {
      if (!length(available_cols)) {
        return(sprintf("  - `%s` (no columns are available)", col))
      }

      distances <- utils::adist(col, available_cols)
      closest_idx <- which.min(distances)
      closest_col <- available_cols[[closest_idx]]
      closest_distance <- distances[[closest_idx]]

      if (closest_distance <= 2) {
        sprintf("  - `%s` (did you mean `%s`?)", col, closest_col)
      } else {
        sprintf("  - `%s`", col)
      }
    }, character(1))

    available_preview <- if (length(available_cols)) {
      paste(utils::head(available_cols, 15), collapse = ", ")
    } else {
      "<none>"
    }

    suffix <- if (length(available_cols) > 15) {
      sprintf(" ... and %d more", length(available_cols) - 15)
    } else {
      ""
    }

    stop(
      sprintf(
        paste0(
          "Required columns are missing from `%s` (%d missing):
",
          "%s
",
          "Available columns (%d): %s%s"
        ),
        name,
        length(missing_required),
        paste(suggestion_lines, collapse = "
"),
        length(available_cols),
        available_preview,
        suffix
      ),
      call. = FALSE
    )
  }

  invisible(x)
}


#' Check One Coordinate Axis
#'
#' @param x Numeric vector of decimal degrees.
#' @param name Character scalar naming the argument for error messages.
#' @param limit Numeric scalar. Maximum permitted absolute value (90 for
#'   latitude, 180 for longitude).
#'
#' @return `invisible(TRUE)`. Called for the error side effect.
#' @family validation
#' @keywords internal
.mc_check_coord_axis <- function(x, name, limit) {
  if (!is.numeric(x)) {
    stop(sprintf(
      "`%s` must be a numeric vector of decimal degrees; received %s.",
      name, paste(class(x), collapse = "/")
    ), call. = FALSE)
  }

  n_nan <- sum(is.nan(x))
  if (n_nan) {
    stop(sprintf(
      paste0("`%s` contains %d NaN value(s); NaN is not a coordinate. ",
             "Use NA for a missing position."),
      name, n_nan
    ), call. = FALSE)
  }

  infinite <- !is.na(x) & !is.finite(x)
  if (any(infinite)) {
    stop(sprintf(
      "`%s` contains %d infinite value(s) at position(s) %s.",
      name, sum(infinite),
      paste(utils::head(which(infinite), 3L), collapse = ", ")
    ), call. = FALSE)
  }

  out <- !is.na(x) & abs(x) > limit
  if (any(out)) {
    idx <- utils::head(which(out), 3L)
    stop(sprintf(
      paste0("`%s` must lie within [%g, %g] decimal degrees; %d value(s) ",
             "are outside it, including %s at position(s) %s. Check that ",
             "latitude and longitude have not been swapped."),
      name, -limit, limit, sum(out),
      paste(signif(x[idx], 7L), collapse = ", "),
      paste(idx, collapse = ", ")
    ), call. = FALSE)
  }

  invisible(TRUE)
}


#' Validate Geographic Coordinates
#'
#' Checks that latitude and longitude are numeric, equal in length, free of
#' `NaN` and infinite values, and inside the geographic domain (latitude
#' `[-90, 90]`, longitude `[-180, 180]`).
#'
#' Out-of-domain values are a hard error rather than a warning because they
#' do not fail loudly downstream: a latitude of 500 still yields a finite
#' haversine distance, so an unchecked coordinate produces a plausible-looking
#' but wrong result. Values inside the domain are *not* thereby valid provider
#' locations -- plausibility of the location itself (right country, right
#' state) is a separate check this function does not make, and no coordinate
#' pair is ever silently reordered.
#'
#' Missing (`NA`) values are permitted by default and must be handled
#' explicitly by the caller.
#'
#' @param lat Numeric vector of latitudes in decimal degrees (WGS84).
#' @param lon Numeric vector of longitudes in decimal degrees (WGS84).
#' @param lat_name Character scalar naming the latitude argument in errors.
#' @param lon_name Character scalar naming the longitude argument in errors.
#' @param allow_missing Logical flag. When `FALSE`, `NA` values are rejected.
#'
#' @return `invisible(TRUE)`. Called for the error side effect.
#' @family validation
#' @keywords internal
validate_coordinates <- function(lat,
                                 lon,
                                 lat_name = "lats",
                                 lon_name = "lons",
                                 allow_missing = TRUE) {
  checkmate::assert_string(lat_name, min.chars = 1, .var.name = "lat_name")
  checkmate::assert_string(lon_name, min.chars = 1, .var.name = "lon_name")
  checkmate::assert_flag(allow_missing, .var.name = "allow_missing")

  .mc_check_coord_axis(lat, lat_name, 90)
  .mc_check_coord_axis(lon, lon_name, 180)

  if (length(lat) != length(lon)) {
    stop(sprintf(
      "`%s` and `%s` must be the same length; received %d and %d.",
      lat_name, lon_name, length(lat), length(lon)
    ), call. = FALSE)
  }

  if (!allow_missing) {
    n_na <- sum(is.na(lat) | is.na(lon))
    if (n_na) {
      stop(sprintf(
        paste0("`%s`/`%s` must not contain missing coordinates; ",
               "%d of %d pair(s) are incomplete."),
        lat_name, lon_name, n_na, length(lat)
      ), call. = FALSE)
    }
  }

  invisible(TRUE)
}


#' Validate an Exposure Column Used as a Log Offset
#'
#' A log offset requires a strictly positive, finite exposure: `log(0)` is
#' `-Inf` and `log(x)` for `x < 0` is `NaN`. Either value makes the model
#' frame unusable, and the fitting engine drops the affected rows silently,
#' so the model is estimated on a smaller cohort than the caller is told
#' about. This check refuses the input instead.
#'
#' The offending values are never replaced with a small positive constant;
#' choosing such a constant is a study-specific decision that belongs to the
#' analyst, not to this function.
#'
#' `NA` exposures are permitted: they are a declared exclusion that the
#' caller's complete-case filter removes and reports. The positivity check is
#' therefore applied to the complete-case cohort, so that a row excluded for
#' an unrelated reason cannot abort an otherwise valid analysis. The `NaN`
#' check is separate and runs on the supplied column, because
#' `complete.cases()` cannot tell `NaN` from `NA`.
#'
#' @param x Numeric vector of exposures.
#' @param name Character scalar naming the column for error messages.
#' @param check_positive Logical flag. When `FALSE`, only the `NaN` check
#'   runs, for use on the supplied column before complete-case filtering.
#' @param row_ids Optional integer vector mapping positions in `x` back to
#'   rows of the caller's data frame, so that a reported row number refers
#'   to the record the analyst can actually look up. Supply this whenever
#'   `x` is a filtered cohort rather than the original column.
#'
#' @return `invisible(TRUE)`. Called for the error side effect.
#' @family validation
#' @keywords internal
validate_log_offset <- function(x, name, check_positive = TRUE,
                                row_ids = NULL) {
  checkmate::assert_string(name, min.chars = 1, .var.name = "name")
  checkmate::assert_flag(check_positive, .var.name = "check_positive")
  if (!is.null(row_ids) && length(row_ids) != length(x)) {
    stop("`row_ids` must be the same length as `x`.", call. = FALSE)
  }

  if (!is.numeric(x)) {
    stop(sprintf(
      "`%s` (offset_col) must be numeric; received %s.",
      name, paste(class(x), collapse = "/")
    ), call. = FALSE)
  }

  # NaN is reported separately from NA: an NA exposure is a known-missing
  # row that the complete-case filter removes and counts, whereas NaN is the
  # residue of an invalid computation and must not be quietly dropped.
  n_nan <- sum(is.nan(x))
  if (n_nan) {
    stop(sprintf(
      paste0("`%s` (offset_col) contains %d NaN value(s). NaN is not a ",
             "missing exposure; correct the computation that produced it, ",
             "or set those rows to NA to exclude them explicitly."),
      name, n_nan
    ), call. = FALSE)
  }

  if (!check_positive) {
    return(invisible(TRUE))
  }

  bad <- !is.na(x) & (!is.finite(x) | x <= 0)
  if (any(bad)) {
    pos <- which(bad)
    idx <- utils::head(pos, 3L)
    reported <- if (is.null(row_ids)) idx else row_ids[idx]
    stop(sprintf(
      paste0("`%s` (offset_col) must be strictly positive and finite to be ",
             "used as log(%s); %d of %d value(s) are not, including %s at ",
             "row(s) %s. Zero or negative exposure is not replaced with a ",
             "small constant: drop or correct those rows explicitly."),
      name, name, sum(bad), length(x),
      paste(signif(x[idx], 7L), collapse = ", "),
      paste(reported, collapse = ", ")
    ), call. = FALSE)
  }

  invisible(TRUE)
}


#' Assert That a Fitted Model Used the Expected Number of Rows
#'
#' Model fitting engines apply their own `na.action` to the model frame, so a
#' value that only becomes unusable inside the formula -- `log()` of a
#' non-positive offset, for instance -- is dropped by the engine without
#' passing through the caller's complete-case filter. The returned object then
#' reports a cohort size that the model never used, which silently changes the
#' denominator of every downstream result.
#'
#' @param model A fitted model object supporting [stats::nobs()].
#' @param n_expected Integer scalar. Rows supplied to the fitting call.
#' @param fn_name Character scalar naming the calling function in the error.
#'
#' @return `invisible(n_used)`, the row count the model reports using.
#' @family validation
#' @keywords internal
assert_model_cohort <- function(model, n_expected, fn_name) {
  checkmate::assert_string(fn_name, min.chars = 1, .var.name = "fn_name")

  # Row count, not nobs(): the two differ by engine. stats::nobs.glm() counts
  # observations with non-zero prior weights and glmmTMB counts non-missing
  # responses, so a legitimately zero-weighted row would look like a dropped
  # one. The model frame is the cohort the engine actually assembled.
  n_used <- tryCatch(
    as.integer(nrow(stats::model.frame(model))),
    error = function(e) tryCatch(
      as.integer(stats::nobs(model)),
      error = function(e2) NA_integer_
    )
  )

  if (is.na(n_used)) {
    stop(sprintf(
      paste0("%s(): could not determine how many rows the fitted model ",
             "used, so the reported cohort cannot be verified. Neither ",
             "stats::model.frame() nor stats::nobs() worked on an object of ",
             "class %s."),
      fn_name, paste(class(model), collapse = "/")
    ), call. = FALSE)
  }

  if (n_used == as.integer(n_expected)) {
    return(invisible(n_used))
  }

  stop(sprintf(
    paste0("%s(): the fitted model used %d row(s) but %d complete case(s) ",
           "were supplied. The fitting engine dropped %d row(s) on its own, ",
           "so the reported cohort would not match the model. Check the ",
           "outcome, predictors and any offset for values that become ",
           "undefined inside the model formula."),
    fn_name, n_used, as.integer(n_expected),
    as.integer(n_expected) - n_used
  ), call. = FALSE)
}


#' Summarise Captured Model-Fitting Warnings
#'
#' A single data problem can make a fitting engine emit one warning per
#' observation; a non-integer Poisson outcome produces one `"non-integer x ="`
#' warning per row. Storing every one of them on the result object makes the
#' diagnostic unreadable and the object large, so keep the distinct warnings
#' and count the rest.
#'
#' Convergence-related warnings are **never** discarded by the cap. A single
#' data problem can emit hundreds of per-observation warnings, and if the cap
#' were applied in arrival order the one warning that matters -- glmmTMB's
#' "extreme or very small eigenvalues detected", which is the only signal for
#' a numerically singular covariance when the optimizer code is 0 and the
#' Hessian is nominally positive-definite -- could be dropped, leaving the
#' object claiming the fit converged.
#'
#' @param x Character vector of captured warning messages.
#' @param max_shown Integer scalar. Distinct non-convergence messages to
#'   retain. Convergence-related messages are retained regardless.
#'
#' @return Character vector: every distinct convergence-related message,
#'   then up to `max_shown` other distinct messages, then a count of any
#'   remainder.
#' @family validation
#' @keywords internal
summarise_fit_warnings <- function(x, max_shown = 10L) {
  if (!length(x)) {
    return(character(0L))
  }
  checkmate::assert_character(x, .var.name = "x")
  checkmate::assert_int(max_shown, lower = 1L, .var.name = "max_shown")

  distinct <- unique(x)
  is_conv  <- grepl(.mc_conv_warning_pattern(), distinct, ignore.case = TRUE)
  conv     <- distinct[is_conv]
  other    <- distinct[!is_conv]

  if (length(other) <= max_shown) {
    return(c(conv, other))
  }

  c(
    conv,
    other[seq_len(max_shown)],
    # Deliberately keyword-free: this sentinel is itself part of the
    # returned vector, and any convergence keyword in it would make the
    # caller classify a clean fit as non-convergent.
    sprintf(
      "... and %d more distinct warning(s) of other kinds.",
      length(other) - max_shown
    )
  )
}


#' Pattern Matching Convergence-Related Diagnostic Text
#'
#' Used to tell an optimizer or numerical problem apart from a warning about
#' something else, such as a non-integer outcome. Singularity is deliberately
#' **not** in this pattern: a boundary-singular random-effect variance is a
#' property of the data, reported separately in `$convergence$singular`, and
#' a singular fit whose optimizer returned code 0 has converged.
#'
#' @return Character scalar regular expression.
#' @family validation
#' @keywords internal
.mc_conv_warning_pattern <- function() {
  paste0(
    "converge|convergence|hessian|gradient|eigenvalue|",
    "failed to|not positive|pdHess"
  )
}


#' Warn When a Count Outcome Is Not Integer-Valued
#'
#' Poisson and negative binomial likelihoods are defined on non-negative
#' integers. A non-integer outcome still fits -- the quasi-likelihood is
#' well defined -- but it is almost always a unit error (hours recorded as
#' days, a mean carried forward from an aggregate), and left unchecked it
#' surfaces only as a flood of per-observation engine warnings that look
#' like a convergence failure.
#'
#' Whether a fractional outcome is an error depends on what the outcome
#' means, which only the analyst knows. A *count of days until an
#' appointment* is integer-valued by construction, so a fractional value is a
#' data error. *Elapsed time measured in days* can legitimately carry
#' decimals, but then a count distribution is the wrong model for it and a
#' continuous-time model should be considered instead. The default is
#' therefore a warning, with `strict = TRUE` available to refuse the fit.
#'
#' Offending values are never rounded or truncated.
#'
#' @param x Numeric vector. The outcome values.
#' @param name Character scalar naming the outcome column.
#' @param strict Logical flag. When `TRUE`, a fractional value is an error
#'   rather than a warning.
#' @param tol Numeric scalar. Tolerance for the integer comparison.
#'
#' @return `invisible(TRUE)`. Called for the warning or error side effect.
#' @family validation
#' @keywords internal
warn_non_integer_counts <- function(x, name, strict = FALSE, tol = 1e-8) {
  checkmate::assert_flag(strict, .var.name = "strict")
  if (!is.numeric(x)) {
    return(invisible(TRUE))
  }

  non_int <- !is.na(x) & is.finite(x) & abs(x - round(x)) > tol
  if (any(non_int)) {
    idx <- utils::head(which(non_int), 3L)
    detail <- sprintf(
      "%d of %d value(s) have a fractional part, including %s at row(s) %s",
      sum(non_int), length(x),
      paste(signif(x[idx], 7L), collapse = ", "),
      paste(idx, collapse = ", ")
    )

    if (strict) {
      stop(sprintf(
        paste0("`%s` is not integer-valued and `strict_counts = TRUE`: %s. ",
               "A count model requires whole counts. Values are never ",
               "rounded: correct `%s`, or model it as continuous time ",
               "instead of a count."),
        name, detail, name
      ), call. = FALSE)
    }

    warning(sprintf(
      paste0("`%s` is not integer-valued: %s. Count models expect whole ",
             "counts; the fit will proceed on the quasi-likelihood but ",
             "check the units of `%s`. Values are not rounded. Pass ",
             "`strict_counts = TRUE` to refuse fractional counts."),
      name, detail, name
    ), call. = FALSE)
  }

  invisible(TRUE)
}


#' Reject Non-Finite Values in a Count Outcome
#'
#' `NA` is a declared missing outcome: the fitters remove those rows through
#' the complete-case filter and report the count. `NaN`, `Inf` and `-Inf` are
#' not declared missingness -- they are the residue of an invalid computation,
#' and `is.na(NaN)` being `TRUE` means a `NaN` outcome would otherwise be
#' swept into the missing-data count and silently excluded.
#'
#' @param x Numeric vector. The outcome values.
#' @param name Character scalar naming the outcome column.
#'
#' @return `invisible(TRUE)`. Called for the error side effect.
#' @family validation
#' @keywords internal
validate_outcome_finite <- function(x, name) {
  checkmate::assert_string(name, min.chars = 1, .var.name = "name")
  if (!is.numeric(x)) {
    return(invisible(TRUE))
  }

  n_nan <- sum(is.nan(x))
  if (n_nan) {
    stop(sprintf(
      paste0("`%s` contains %d NaN value(s). NaN is not a missing outcome: ",
             "correct the computation that produced it, or set those rows ",
             "to NA so the exclusion is reported."),
      name, n_nan
    ), call. = FALSE)
  }

  infinite <- !is.na(x) & !is.finite(x)
  if (any(infinite)) {
    idx <- utils::head(which(infinite), 3L)
    stop(sprintf(
      paste0("`%s` contains %d infinite value(s) at row(s) %s. A count ",
             "outcome must be finite."),
      name, sum(infinite), paste(idx, collapse = ", ")
    ), call. = FALSE)
  }

  invisible(TRUE)
}
