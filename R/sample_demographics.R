# Built-in reference list of all 50 US states + DC
.us_states_dc <- c(
  "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
  "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho",
  "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine",
  "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi",
  "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey",
  "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio",
  "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina",
  "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia",
  "Washington", "West Virginia", "Wisconsin", "Wyoming", "District of Columbia"
)


#' Summarise Sample Demographics for a Mystery-Caller Study
#'
#' Computes sample-level descriptive counts (total calls, unique physicians by
#' insurance, geographic coverage) and returns a manuscript-ready
#' `$summary_sentence` describing the sample.
#'
#' @param data A data frame of mystery-caller records (all records; no
#'   pre-filtering required).
#' @param id_col Character scalar. Physician identifier column for distinct
#'   counts. Default `"id_number"`.
#' @param state_col Character scalar. State column. Default `"state"`.
#' @param insurance_col Character scalar. Insurance column. Default
#'   `"insurance"`.
#' @param all_states Character vector of all expected state names. Default
#'   `NULL` uses the built-in 51-name vector (50 states + DC).
#' @param phone_col Character scalar or `NULL`. Column used for distinct
#'   physician counts within each insurance group. When `NULL`, falls back to
#'   `id_col`. Default `"phone"`.
#' @param output_dir Character scalar or `NULL`. Directory for CSV output.
#'   `NULL` writes to a session temp directory. Pass `NA` to skip writing.
#' @param filename Character scalar. Output CSV file name.
#'
#' @return A named list:
#' \describe{
#'   \item{`unique_physicians_count`}{Total rows in `data`.}
#'   \item{`total_calls`}{Same as `unique_physicians_count`.}
#'   \item{`count_by_insurance`}{Named integer vector: unique
#'     physician/phone count per insurance type.}
#'   \item{`included_states`}{Character vector of states present in `data`.}
#'   \item{`excluded_states`}{Character vector of states absent from `data`.}
#'   \item{`num_included_states`}{Integer count of covered states.}
#'   \item{`excluded_states_series`}{Human-readable series string for
#'     manuscript use (e.g., `"Alaska, Hawaii and Wyoming"`).}
#'   \item{`summary_sentence`}{Manuscript-ready character scalar.}
#' }
#'
#' @family outcomes
#' @seealso [mysterycall_insurance_acceptance_rates()] for acceptance rate
#'   calculations that extend this summary.
#' @importFrom dplyr group_by distinct summarise n
#' @importFrom utils write.csv
#' @importFrom checkmate assert_data_frame assert_string assert_names
#' @export
#'
#' @examples
#' df <- data.frame(
#'   id_number = paste0("P", 1:6),
#'   phone     = paste0("555-000", 1:6),
#'   state     = c("Colorado", "Texas", "Colorado", "Florida", "Texas", "Georgia"),
#'   insurance = c("Medicaid", "Medicaid", "Blue Cross/Blue Shield",
#'                 "Blue Cross/Blue Shield", "Medicaid", "Blue Cross/Blue Shield"),
#'   stringsAsFactors = FALSE
#' )
#' demo <- mysterycall_sample_demographics(df, output_dir = NA)
#' cat(demo$summary_sentence)
mysterycall_sample_demographics <- function(
    data,
    id_col        = "id_number",
    state_col     = "state",
    insurance_col = "insurance",
    all_states    = NULL,
    phone_col     = "phone",
    output_dir    = NULL,
    filename      = "sample_demographics.csv") {

  checkmate::assert_data_frame(data, min.rows = 0)
  checkmate::assert_string(id_col)
  checkmate::assert_string(state_col)
  checkmate::assert_string(insurance_col)
  checkmate::assert_names(names(data), must.include = c(id_col, state_col, insurance_col))

  if (is.null(all_states)) all_states <- .us_states_dc

  # Determine the column to use for distinct physician counting
  distinct_col <- if (!is.null(phone_col) && phone_col %in% names(data)) {
    phone_col
  } else {
    id_col
  }

  # 1. Total counts
  unique_physicians_count <- nrow(data)
  total_calls             <- nrow(data)

  # 2. Count unique physicians by insurance
  ins_counts <- data |>
    dplyr::group_by(.data[[insurance_col]]) |>
    dplyr::distinct(.data[[distinct_col]]) |>
    dplyr::summarise(count = dplyr::n(), .groups = "drop")

  count_by_insurance <- stats::setNames(
    as.integer(ins_counts$count),
    ins_counts[[insurance_col]]
  )

  # 3. State coverage
  included_states    <- unique(stats::na.omit(data[[state_col]]))
  excluded_states    <- setdiff(all_states, included_states)
  num_included_states <- length(all_states) - length(excluded_states)

  # 4. Excluded states series (no Oxford comma, last item joined with "and")
  excluded_states_series <- if (length(excluded_states) == 0L) {
    "No states were excluded."
  } else if (length(excluded_states) == 1L) {
    excluded_states
  } else {
    paste(
      paste(excluded_states[-length(excluded_states)], collapse = ", "),
      "and",
      excluded_states[length(excluded_states)]
    )
  }

  # 5. Summary sentence
  # Only mention the District of Columbia when it is actually among the
  # included states; otherwise the clause contradicts the excluded list.
  dc_clause <- if ("District of Columbia" %in% included_states) {
    ", including the District of Columbia"
  } else {
    ""
  }
  summary_sentence <- sprintf(
    paste0(
      "Our sample included %d calls to physician offices from %d states%s, ",
      "excluding %s."
    ),
    unique_physicians_count,
    num_included_states,
    dc_clause,
    excluded_states_series
  )

  message(summary_sentence)

  # 6. Write CSV (wide count_by_insurance)
  if (!isTRUE(is.na(output_dir))) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("demographics", create = TRUE)
    }
    if (!dir.exists(output_dir))
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

    out_df   <- as.data.frame(t(count_by_insurance), stringsAsFactors = FALSE)
    out_path <- file.path(output_dir, filename)
    utils::write.csv(out_df, out_path, row.names = FALSE)
    message(sprintf("Demographics written to: %s", out_path))
  }

  list(
    unique_physicians_count  = unique_physicians_count,
    total_calls              = total_calls,
    count_by_insurance       = count_by_insurance,
    included_states          = included_states,
    excluded_states          = excluded_states,
    num_included_states      = num_included_states,
    excluded_states_series   = excluded_states_series,
    summary_sentence         = summary_sentence
  )
}
