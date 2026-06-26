#' Parse REDCap field labels into choice-code / label tables
#'
#' @name mysterycall_parse_redcap_labels
NULL

#' Convert REDCap radio/dropdown/checkbox label strings to a tidy data frame
#'
#' REDCap exports choice fields as pipe-delimited strings such as
#' `"1, Yes | 2, No | 3, Prefer not to answer"`. This function converts one
#' or more such strings — typically stored in the `select_choices_or_calculations`
#' column of a REDCap data dictionary — into a tidy data frame with one row per
#' choice, making it easy to recode raw numeric codes to human-readable labels
#' or to build factor variables.
#'
#' @param labels Character vector of REDCap label strings. Each element is one
#'   field's choices in the canonical REDCap format:
#'   `"<code>, <label> | <code>, <label> | ..."`. Unnamed elements are
#'   assigned sequential field names (`field_1`, `field_2`, …); supply a
#'   **named** vector to control the `field` column in the output.
#' @param sep_choice Character scalar. Separator between choices within a
#'   single label string. Default `" | "` (space-pipe-space). REDCap uses
#'   this consistently, but some exports omit the surrounding spaces — adjust
#'   as needed.
#' @param sep_code Character scalar. Separator between the numeric code and
#'   the human-readable label within a single choice. Default `", "`.
#' @param trim Logical. When `TRUE` (default), strip leading/trailing
#'   whitespace from codes and labels.
#'
#' @return A [tibble::tibble()] with columns:
#' \describe{
#'   \item{`field`}{Field name, taken from the names of `labels`; defaults to
#'     `"field_1"`, `"field_2"`, … when `labels` is unnamed.}
#'   \item{`code`}{Raw choice code (character), as exported by REDCap.}
#'   \item{`label`}{Human-readable choice label (character).}
#' }
#' Rows are ordered by field then by their original order within each field.
#'
#' @section Common usage:
#' ```r
#' dict <- read.csv("REDCapDataDictionary.csv", stringsAsFactors = FALSE)
#' choices <- setNames(dict$select_choices_or_calculations, dict$variable_name)
#' choices <- choices[nzchar(choices)]   # drop empty / calculated fields
#'
#' parsed <- mysterycall_parse_redcap_labels(choices)
#'
#' # Build a recode lookup for one field
#' lookup <- parsed[parsed$field == "insurance_type", ]
#' df$insurance_label <- lookup$label[match(df$insurance_type, lookup$code)]
#' ```
#'
#' @seealso [mysterycall_recode_credentials()] for specialty-credential recoding
#' @family utilities
#' @export
#'
#' @examples
#' raw <- c(
#'   scenario = "1, Straight couple | 2, Lesbian couple | 3, Single woman",
#'   accepted = "0, No | 1, Yes | 99, Unknown"
#' )
#' mysterycall_parse_redcap_labels(raw)
mysterycall_parse_redcap_labels <- function(
    labels,
    sep_choice = " | ",
    sep_code   = ", ",
    trim       = TRUE
) {
  if (!is.character(labels) || !length(labels))
    stop("`labels` must be a non-empty character vector.", call. = FALSE)
  if (!is.character(sep_choice) || length(sep_choice) != 1L || !nzchar(sep_choice))
    stop("`sep_choice` must be a single non-empty string.", call. = FALSE)
  if (!is.character(sep_code) || length(sep_code) != 1L || !nzchar(sep_code))
    stop("`sep_code` must be a single non-empty string.", call. = FALSE)

  # Supply default field names when labels is unnamed
  if (is.null(names(labels))) {
    names(labels) <- paste0("field_", seq_along(labels))
  } else {
    missing_names <- !nzchar(names(labels))
    if (any(missing_names))
      names(labels)[missing_names] <- paste0("field_", which(missing_names))
  }

  rows <- vector("list", length(labels))

  for (i in seq_along(labels)) {
    field_name <- names(labels)[[i]]
    raw        <- labels[[i]]

    if (is.na(raw) || !nzchar(raw)) {
      rows[[i]] <- data.frame(
        field = character(0),
        code  = character(0),
        label = character(0),
        stringsAsFactors = FALSE
      )
      next
    }

    choices <- strsplit(raw, split = sep_choice, fixed = TRUE)[[1L]]

    codes  <- character(length(choices))
    lbls   <- character(length(choices))

    for (j in seq_along(choices)) {
      # Split on the FIRST occurrence of sep_code only (label may contain commas)
      m <- regexpr(sep_code, choices[[j]], fixed = TRUE)
      if (m == -1L) {
        codes[[j]] <- choices[[j]]
        lbls[[j]]  <- NA_character_
      } else {
        codes[[j]] <- substr(choices[[j]], 1L, m - 1L)
        lbls[[j]]  <- substr(choices[[j]], m + nchar(sep_code), nchar(choices[[j]]))
      }
    }

    if (trim) {
      codes <- trimws(codes)
      lbls  <- trimws(lbls)
    }

    rows[[i]] <- data.frame(
      field = field_name,
      code  = codes,
      label = lbls,
      stringsAsFactors = FALSE
    )
  }

  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  tibble::as_tibble(result)
}
