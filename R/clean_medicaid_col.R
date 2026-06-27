#' Clean and binarise a Medicaid acceptance column
#'
#' @name mysterycall_clean_medicaid_col
NULL

#' Clean and binarise a Medicaid acceptance column
#'
#' Recodes ambiguous or non-informative responses in a Medicaid acceptance
#' column to \code{NA}, then creates a binary 0/1 numeric column where the
#' specified \code{yes_value} maps to \code{1} and all other non-\code{NA}
#' values map to \code{0}.
#'
#' @param data A data frame containing the source column.
#' @param col Character scalar. Name of the column to clean. Default
#'   \code{"does_the_physician_accept_medicaid"}.
#' @param na_values Character vector. Values to recode as \code{NA}. Default:
#'   \code{c("NA as this was a Blue Cross/Blue Shield call.",
#'   "No answer, unable to determine if they accept Medicaid.")}.
#' @param yes_value Character scalar. The value in the cleaned column that
#'   should be mapped to \code{1}; all other non-\code{NA} values → \code{0}.
#'   Default \code{"Yes they accept Medicaid"}.
#' @param out_col_cleaned Character scalar or \code{NULL}. Name for the cleaned
#'   character column. Defaults to \code{paste0("cleaned_", col)}.
#' @param out_col_numeric Character scalar or \code{NULL}. Name for the binary
#'   numeric column. Defaults to \code{paste0(out_col_cleaned, "_numeric")}.
#'
#' @return The input data frame with two new columns appended:
#'   \describe{
#'     \item{\code{<out_col_cleaned>}}{Character. Original values with
#'       \code{na_values} replaced by \code{NA}.}
#'     \item{\code{<out_col_numeric>}}{Numeric (\code{0}/\code{1}/\code{NA}).
#'       \code{1} where cleaned column equals \code{yes_value}; \code{0}
#'       otherwise; \code{NA} where cleaned column is \code{NA}.}
#'   }
#'   Emits an informative message reporting recoding counts.
#'
#' @section Messages:
#' \code{"Recoded [n_na] values to NA in '[col]'. [n_yes] records coded 1,
#' [n_no] records coded 0."}
#'
#' @seealso [mysterycall_check_normality()] for downstream variable checks.
#' @family quality control
#' @export
#' @importFrom dplyr mutate
#'
#' @examples
#' df <- data.frame(
#'   does_the_physician_accept_medicaid = c(
#'     "Yes they accept Medicaid",
#'     "No",
#'     "NA as this was a Blue Cross/Blue Shield call.",
#'     "No answer, unable to determine if they accept Medicaid.",
#'     "Yes they accept Medicaid"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' result <- suppressMessages(mysterycall_clean_medicaid_col(df))
#' result[, c("cleaned_does_the_physician_accept_medicaid",
#'            "cleaned_does_the_physician_accept_medicaid_numeric")]
mysterycall_clean_medicaid_col <- function(
    data,
    col             = "does_the_physician_accept_medicaid",
    na_values       = c(
      "NA as this was a Blue Cross/Blue Shield call.",
      "No answer, unable to determine if they accept Medicaid."
    ),
    yes_value       = "Yes they accept Medicaid",
    out_col_cleaned = NULL,
    out_col_numeric = NULL
) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!col %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", col), call. = FALSE)
  }

  # Default output column names
  if (is.null(out_col_cleaned)) out_col_cleaned <- paste0("cleaned_", col)
  if (is.null(out_col_numeric)) out_col_numeric <- paste0(out_col_cleaned, "_numeric")

  # Guard against duplicate output column names
  if (out_col_cleaned == out_col_numeric) {
    stop(
      "`out_col_cleaned` and `out_col_numeric` must be different column names.",
      call. = FALSE
    )
  }

  # Warn if output columns already exist
  existing <- intersect(c(out_col_cleaned, out_col_numeric), names(data))
  if (length(existing) > 0L) {
    warning(
      sprintf(
        "Output column(s) already exist and will be overwritten: %s",
        paste(existing, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  raw <- data[[col]]

  # Recode na_values → NA
  cleaned <- ifelse(raw %in% na_values, NA_character_, as.character(raw))

  # Recode to 0/1/NA
  numeric_col <- ifelse(
    is.na(cleaned),
    NA_real_,
    ifelse(cleaned == yes_value, 1, 0)
  )

  # Counts for message
  n_na  <- sum(raw %in% na_values, na.rm = TRUE)
  n_yes <- sum(numeric_col == 1L, na.rm = TRUE)
  n_no  <- sum(numeric_col == 0L, na.rm = TRUE)

  message(sprintf(
    "Recoded %d values to NA in '%s'. %d records coded 1, %d records coded 0.",
    n_na, col, n_yes, n_no
  ))

  data[[out_col_cleaned]] <- cleaned
  data[[out_col_numeric]] <- numeric_col
  data
}
