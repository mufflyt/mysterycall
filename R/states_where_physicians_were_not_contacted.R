#' Summarize States Where Physicians Were NOT Contacted
#'
#' This function summarizes the demographic details by identifying the states where physicians
#' were not successfully contacted and those that were included. It also reports how many unique
#' physicians were successfully reached by filtering to rows with affirmative contact indicators
#' (e.g., "Yes" values in `contact_office` or `included_in_study`).
#'
#' @param filtered_data A data frame containing filtered data of contacted physicians.
#' @param all_states A character vector of all possible states including Washington, DC.
#' If not provided, a default set of states will be used.
#'
#' @return A length-1 character string summarising the states not contacted and
#'   the number of unique physicians successfully reached.
#' @details
#' If `contact_office` and/or `included_in_study` exist, they are interpreted as
#' contact indicators and used to restrict the denominator to successfully
#' contacted rows. Accepted affirmative values include logical `TRUE`, non-zero
#' numerics, and character values such as `"yes"`, `"y"`, `"true"`, and `"1"`.
#'
#' The physician count is derived from the first available identifier among
#' `npi`, `name`, `physician_info`, and `physician_information`.
#' @seealso [mysterycall_summarize_census()], [mysterycall_get_clinician_data()], [mysterycall_clean_phase1()]
#' @family data quality
#' @export
#'
#' @importFrom dplyr distinct
#' @importFrom stringr str_c
#'
#' @examples
#' # Example with provided all_states
#' filtered_data <- data.frame(state = c("California", "New York", "Texas"))
#' all_states <- c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
#'                  "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho",
#'                  "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana",
#'                  "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
#'                  "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada",
#'                  "New Hampshire", "New Jersey", "New Mexico", "New York",
#'                  "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon",
#'                  "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota",
#'                  "Tennessee", "Texas", "Utah", "Vermont", "Virginia",
#'                  "Washington", "West Virginia", "Wisconsin", "Wyoming",
#'                  "District of Columbia")
#' mysterycall_not_contacted_states(filtered_data, all_states)
#'
#' # Example with default all_states
#' filtered_data <- data.frame(state = c("California", "New York", "Texas", "Nevada"))
#' mysterycall_not_contacted_states(filtered_data)
#'
mysterycall_not_contacted_states <- function(filtered_data, all_states = NULL) {

  # Helper to coerce character responses such as "Yes"/"No" into logical
  as_positive_logical <- function(x) {
    if (is.logical(x)) {
      return(!is.na(x) & x)
    }
    if (is.numeric(x)) {
      return(!is.na(x) & x != 0)
    }
    normalized <- tolower(trimws(as.character(x)))
    !is.na(normalized) & normalized %in% c("yes", "y", "true", "1")
  }

  # Default list of all states including Washington, DC
  default_all_states <- c(
    "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia",
    "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland",
    "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey",
    "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina",
    "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming", "District of Columbia"
  )

  # Check if all_states is NULL and use default if necessary
  if (is.null(all_states)) {
    all_states <- default_all_states
  }

  # Limit the data to rows that represent completed contacts
  contacted_mask <- rep(TRUE, nrow(filtered_data))
  if ("contact_office" %in% names(filtered_data)) {
    contacted_mask <- contacted_mask & as_positive_logical(filtered_data$contact_office)
  }
  if ("included_in_study" %in% names(filtered_data)) {
    contacted_mask <- contacted_mask & as_positive_logical(filtered_data$included_in_study)
  }
  contacted_data <- filtered_data[contacted_mask, , drop = FALSE]

  # Identify the unique included states
  if ("state" %in% names(contacted_data)) {
    included_states <- dplyr::distinct(contacted_data, state)
  } else if ("state" %in% names(filtered_data)) {
    included_states <- dplyr::distinct(filtered_data[, "state", drop = FALSE])
  } else {
    included_states <- dplyr::distinct(data.frame(state = character()))
  }

  # Identify the excluded states by finding the difference between all states and the included states
  excluded_states <- setdiff(all_states, included_states$state)

  # Convert the excluded_states vector into a human-readable series
  excluded_states_series <- if (length(excluded_states) > 1) {
    paste(paste(excluded_states[-length(excluded_states)], collapse = ", "), "and", excluded_states[length(excluded_states)])
  } else if (length(excluded_states) == 1) {
    excluded_states
  } else {
    "No states"
  }

  # Count the number of included states
  num_included_states <- length(included_states$state)

  # Determine how many unique physicians were successfully contacted
  unique_physicians <- 0L
  identifier_columns <- intersect(
    c("npi", "name", "physician_info", "physician_information"),
    names(contacted_data)
  )
  if (length(identifier_columns) > 0) {
    id_values <- contacted_data[[identifier_columns[[1]]]]
    id_values <- as.character(id_values)
    id_values <- id_values[!is.na(id_values) & nzchar(id_values)]
    unique_physicians <- length(unique(id_values))
  } else if (nrow(contacted_data)) {
    unique_physicians <- nrow(dplyr::distinct(contacted_data))
  }

  exclusion_sentence <- if (length(excluded_states) == 0) {
    "No states were excluded."
  } else {
    paste0("The excluded states include ", excluded_states_series, ".")
  }

  output_string <- paste0(
    "A total of ", unique_physicians,
    " unique physicians were identified in the dataset and were successfully contacted",
    " (i.e., with a recorded wait time for an appointment) in ",
    num_included_states, " states including the District of Columbia. ",
    exclusion_sentence
  )

  if (isTRUE(interactive()) && requireNamespace("beepr", quietly = TRUE)) beepr::beep(2)
  return(output_string)
}



# Example usage:
# filtered_data <- data.frame(state = c("California", "New York", "Texas"))
# mysterycall_not_contacted_states(filtered_data)
