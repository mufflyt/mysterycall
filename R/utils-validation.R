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
