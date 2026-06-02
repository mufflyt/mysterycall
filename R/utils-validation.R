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
  if (is.null(required) || !length(required)) {
    return(invisible(x))
  }

  missing_required <- setdiff(required, names(x))
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
