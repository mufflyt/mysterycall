#' Search NPI Database by Taxonomy
#'
#' This function searches the NPI Database for healthcare providers based on a
#' taxonomy description. The NPI API returns at most 1\,200 records per query.
#' To retrieve all providers for a large specialty, supply a character vector
#' of state abbreviations via the `states` argument; the function will loop over
#' each state and combine the results, effectively bypassing the 1\,200-record
#' cap.
#'
#' @param taxonomy_to_search A character vector containing the taxonomy
#'   description(s) to search for.
#' @param states Optional character vector of two-letter US state abbreviations
#'   (e.g. `c("CO", "CA", "NY")`). When supplied the search is repeated for
#'   each state so that all providers are captured even for large specialties
#'   that exceed the 1\,200-record per-query limit. Pass all 50 state
#'   abbreviations to perform a complete national search. Defaults to `NULL`
#'   (national search, capped at `limit` records).
#' @param city Optional city name passed to [npi::npi_search()].
#' @param limit Maximum records to request per API call. Capped at 1\,200 by
#'   the NPI API. Defaults to `1200L`.
#' @param write_snapshot Logical. If `TRUE`, the retrieved data is saved as an
#'   `.rds` file for later reference. Defaults to `TRUE`.
#' @param snapshot_dir Directory where snapshot files should be written when
#'   `write_snapshot` is `TRUE`. Defaults to a session-specific folder inside
#'   [tempdir()] when not supplied.
#' @param notify Logical. If `TRUE`, play a notification sound when processing
#'   completes (requires the optional `beepr` package). Defaults to `TRUE`.
#' @return A data frame of NPPES records matching the requested taxonomy. Key
#'   columns include `npi`, `first_name`, `last_name`, `taxonomies_desc`
#'   (broad NPPES specialty label), and `taxonomies_primary` (logical).
#'
#' @section Subspecialty source warning:
#'   `taxonomies_desc` reflects the NPPES taxonomy code the provider self-
#'   reported to the NPI registry. **Do not use this column to assign
#'   subspecialty.** NPPES taxonomy codes cannot reliably distinguish
#'   subspecialties (e.g. Neurotology vs. General Otolaryngology). Subspecialty
#'   must be derived from board certification data only, using
#'   [mysterycall_parse_certification_subspecialty()] on the ABOHNS
#'   `certification_type` field, then reconciled with
#'   [mysterycall_reconcile_specialty()].
#'
#' @examplesIf interactive()
#' # National search (limited to 1200 records per taxonomy):
#' go_data <- mysterycall_search_taxonomy("Gynecologic Oncology")
#'
#' # Full national search by looping over every state:
#' all_states <- c(
#'   "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
#'   "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
#'   "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
#'   "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
#'   "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"
#' )
#' fpmrs_data <- mysterycall_search_taxonomy(
#'   "Female Pelvic Medicine and Reconstructive Surgery",
#'   states = all_states
#' )
#'
#' @section Output columns:
#'   The function returns a curated subset of `npi::npi_flatten()` output.
#'
#'   **Retained** (after renaming):
#'   `npi`, `first_name`, `last_name`, `middle_name`, `credential`,
#'   `addresses_city`, `addresses_state`, `addresses_postal_code`,
#'   `addresses_telephone_number`, `addresses_country_name`,
#'   `taxonomies_desc`, `taxonomies_primary`, `search_term`.
#'   Any columns returned by `npi_flatten()` that are *not* on the explicit
#'   drop list are also retained.
#'
#'   **Always dropped** regardless of what the NPI API returns:
#'   \itemize{
#'     \item All `endpoints_*` fields (electronic health endpoint metadata)
#'     \item All `other_names_*` fields (former or alternate name records)
#'     \item All `identifiers_*` fields (legacy identifier records)
#'     \item Supplementary address fields: `addresses_address_2`,
#'           `addresses_fax_number`, `addresses_address_type`,
#'           `addresses_country_code`
#'     \item Basic metadata: `basic_last_updated`, `basic_status`,
#'           `basic_name_prefix`, `basic_name_suffix`,
#'           `basic_certification_date`
#'     \item Secondary taxonomy fields: `taxonomies_code`,
#'           `taxonomies_taxonomy_group`, `taxonomies_state`,
#'           `taxonomies_license`
#'     \item Internal working column: `credential_lower`
#'   }
#'
#'   To access dropped columns, call `npi::npi_search()` and
#'   `npi::npi_flatten()` directly before any filtering.
#'
#' @section Contract:
#' **Inputs:**
#' - `taxonomy_to_search` must be an exact NUCC taxonomy description string
#'   (see `mysterycall::taxonomy` dataset for valid values).
#' - NPI registry API must be reachable; the function retries up to 3 times with
#'   exponential back-off before returning an empty data frame.
#'
#' **Guarantees:**
#' - Returns a zero-row data frame (never `NULL`) when no records are found.
#' - Output rows are deduplicated on NPI.
#' - When `write_snapshot = TRUE`, an `.rds` file is written to `output_dir`
#'   for reproducible re-runs without re-querying the live API.
#'
#' **Fails if:**
#' - Network is unavailable after all retries (returns empty data frame, does
#'   not error).
#' - `states` contains an invalid two-letter abbreviation (silently skipped).
#'
#' @section Performance:
#' O(t * p / 200) HTTP requests where `t` = number of state batches and
#' `p` = max_records (default 1,200). Each page request targets < 200 rows.
#' Full national search across all 50 states for one taxonomy takes ~2-5 min
#' depending on registry load. Results are cached in-memory per session when
#' `use_cache = TRUE`.
#'
#' @section Called By:
#' - [mysterycall_run_workflow()]
#' - [mysterycall_search_and_process_npi()] (indirectly via taxonomy lookup)
#'
#' @importFrom npi npi_search npi_flatten
#' @importFrom dplyr bind_rows arrange filter select distinct mutate rename
#' @importFrom stringr str_remove_all str_to_lower str_detect str_extract str_trunc fixed
#' @importFrom readr write_rds
#' @importFrom tibble tibble
#' @family npi
#' @export
mysterycall_search_taxonomy <- function(taxonomy_to_search,
                               states = NULL,
                               city = NULL,
                               limit = 1200L,
                               write_snapshot = TRUE,
                               snapshot_dir = NULL,
                               notify = TRUE) {
  if (isTRUE(write_snapshot) && !requireNamespace("readr", quietly = TRUE)) {
    stop("Package 'readr' is required when write_snapshot = TRUE. Install it or pass write_snapshot = FALSE.", call. = FALSE)
  }
  if (missing(taxonomy_to_search) || is.null(taxonomy_to_search)) {
    return(tibble::tibble())
  }

  checkmate::assert_flag(write_snapshot, .var.name = "write_snapshot")
  checkmate::assert_flag(notify, .var.name = "notify")
  checkmate::assert_number(limit, lower = 1, upper = 1200, finite = TRUE, .var.name = "limit")

  taxonomy_to_search <- trimws(as.character(taxonomy_to_search))
  taxonomy_to_search <- taxonomy_to_search[!is.na(taxonomy_to_search) & nzchar(taxonomy_to_search)]
  if (!length(taxonomy_to_search)) {
    return(tibble::tibble())
  }

  # When states are provided loop over each state so we bypass the 1200-record
  # per-query cap. Results are deduplicated on NPI before returning.
  if (!is.null(states) && length(states)) {
    states <- toupper(trimws(as.character(states)))
    states <- unique(states[!is.na(states) & nzchar(states)])
    invalid_states <- states[nchar(states) != 2]
    if (length(invalid_states)) {
      warning(sprintf(
        "Skipping %d invalid state abbreviation(s) (must be 2 letters): %s",
        length(invalid_states),
        paste(invalid_states, collapse = ", ")
      ), call. = FALSE)
      states <- states[nchar(states) == 2]
    }

    known_codes <- c(
      "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
      "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
      "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
      "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
      "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY",
      "DC","GU","PR","VI","AS","MP"
    )
    unrecognized <- states[!states %in% known_codes]
    if (length(unrecognized)) {
      warning(sprintf(
        "%d unrecognized state code(s) will be queried but are not known US state/territory abbreviations and will likely return no results: %s",
        length(unrecognized),
        paste(unrecognized, collapse = ", ")
      ), call. = FALSE)
    }
    if (!length(states)) {
      message("No valid state abbreviations remain after filtering. Returning empty data frame.")
      return(tibble::tibble())
    }
    message(sprintf(
      "Searching %d taxonomy term(s) across %d state(s) to bypass the 1200-record cap...",
      length(taxonomy_to_search), length(states)
    ))

    all_results <- lapply(states, function(st) {
      .search_by_taxonomy_single(
        taxonomy_to_search = taxonomy_to_search,
        state = st,
        city = city,
        limit = limit
      )
    })

    npi_data <- dplyr::bind_rows(all_results)
    npi_data <- dplyr::distinct(npi_data, .data$npi, .keep_all = TRUE)

    if (isTRUE(write_snapshot)) {
      .save_taxonomy_snapshot(npi_data, snapshot_dir)
    }

    if (isTRUE(interactive()) && isTRUE(notify) && requireNamespace("beepr", quietly = TRUE)) {
      beepr::beep(2)
    }

    return(npi_data)
  }

  # Single (national) search path
  npi_data <- .search_by_taxonomy_single(
    taxonomy_to_search = taxonomy_to_search,
    state = NULL,
    city = city,
    limit = limit
  )

  if (isTRUE(write_snapshot)) {
    .save_taxonomy_snapshot(npi_data, snapshot_dir)
  }

  if (isTRUE(interactive()) && isTRUE(notify) && requireNamespace("beepr", quietly = TRUE)) {
    beepr::beep(2)
  }

  npi_data
}

# Internal workhorse for a single state (or national) query.
.search_by_taxonomy_single <- function(taxonomy_to_search, state = NULL,
                                       city = NULL, limit = 1200L) {
  extract_status <- function(msg) {
    status <- stringr::str_extract(msg, "\\b[0-9]{3}\\b")
    if (!is.na(status)) return(paste("after", status))
    paste("due to", stringr::str_trunc(msg, 120))
  }

  max_attempts <- 3L
  base_delay <- 1
  result_list <- vector("list", length(taxonomy_to_search))
  total_taxonomies <- length(taxonomy_to_search)

  for (index in seq_along(taxonomy_to_search)) {
    taxonomy <- taxonomy_to_search[index]

    if (!is.null(state)) {
      message(sprintf("Searching taxonomy '%s' in state '%s' (%d of %d)...",
                      taxonomy, state, index, total_taxonomies))
    } else {
      message(sprintf("Searching taxonomy '%s' (%d of %d)...", taxonomy, index, total_taxonomies))
    }

    attempt <- 1L
    repeat {
      result <- tryCatch({
        search_args <- list(
          taxonomy_description = taxonomy,
          country_code = "US",
          enumeration_type = "ind",
          limit = as.integer(limit)
        )
        if (!is.null(state)) search_args$state <- state
        if (!is.null(city))  search_args$city  <- city

        search_result <- do.call(npi::npi_search, search_args)

        data_taxonomy <- NULL
        if (!is.null(search_result)) {
          data_taxonomy <- npi::npi_flatten(search_result)
        }

        if (!is.null(data_taxonomy) && nrow(data_taxonomy)) {
          required_cols <- c(
            "npi",
            "addresses_country_name",
            "taxonomies_desc",
            "basic_first_name",
            "basic_last_name"
          )
          missing_required <- setdiff(required_cols, names(data_taxonomy))
          if (length(missing_required) > 0) {
            stop(sprintf(
              "NPI API response missing required columns: %s. Available columns: %s",
              paste(missing_required, collapse = ", "),
              paste(names(data_taxonomy), collapse = ", ")
            ))
          }
          if (!"basic_middle_name" %in% names(data_taxonomy)) {
            data_taxonomy$basic_middle_name <- NA_character_
          }
          if (!"basic_credential" %in% names(data_taxonomy)) {
            data_taxonomy$basic_credential <- NA_character_
          }

          data_taxonomy <- dplyr::distinct(data_taxonomy, .data$npi, .keep_all = TRUE)
          data_taxonomy <- dplyr::mutate(
            data_taxonomy,
            credential = stringr::str_remove_all(.data$basic_credential, "[[\\p{P}][\\p{S}]]"),
            credential_lower = stringr::str_to_lower(.data$credential)
          )
          n_before_cred <- nrow(data_taxonomy)
          data_taxonomy <- dplyr::filter(
            data_taxonomy,
            is.na(.data$credential_lower) | stringr::str_detect(.data$credential_lower, "\\bmd\\b|\\bdo\\b")
          )
          n_dropped_cred <- n_before_cred - nrow(data_taxonomy)
          if (n_dropped_cred > 0) {
            message(sprintf(
              "Dropped %d record(s) whose credential did not contain MD or DO (punctuation is stripped before matching).",
              n_dropped_cred
            ))
          }

          country_vals <- unique(data_taxonomy$addresses_country_name)
          n_before_country <- nrow(data_taxonomy)
          data_taxonomy <- dplyr::filter(
            data_taxonomy,
            grepl("^united states( of america)?$|^usa?$", .data$addresses_country_name, ignore.case = TRUE)
          )
          if (!nrow(data_taxonomy) && n_before_country > 0) {
            warning(sprintf(
              "All %d record(s) were removed by the US country name filter. Observed country values: %s. The NPI registry may have changed its country name format.",
              n_before_country,
              paste(head(country_vals, 5L), collapse = ", ")
            ), call. = FALSE)
          }
          data_taxonomy <- dplyr::filter(
            data_taxonomy,
            stringr::str_detect(
              string = .data$taxonomies_desc,
              pattern = stringr::fixed(taxonomy, ignore_case = TRUE)
            )
          )

          data_taxonomy <- dplyr::rename(
            data_taxonomy,
            "first_name" = "basic_first_name",
            "last_name" = "basic_last_name",
            "middle_name" = "basic_middle_name"
          )
          data_taxonomy <- dplyr::mutate(data_taxonomy, search_term = taxonomy)
          data_taxonomy <- dplyr::arrange(data_taxonomy, .data$last_name, .data$first_name)
          data_taxonomy <- dplyr::distinct(data_taxonomy, .data$npi, .keep_all = TRUE)

          # Drop noisy endpoint/identifier columns that inflate the result
          drop_cols <- intersect(names(data_taxonomy), c(
            "credential_lower",
            "basic_last_updated", "basic_status", "basic_name_prefix", "basic_name_suffix",
            "basic_certification_date", "other_names_type", "other_names_code",
            "other_names_credential", "other_names_first_name", "other_names_last_name",
            "other_names_prefix", "other_names_suffix", "other_names_middle_name",
            "identifiers_code", "identifiers_desc", "identifiers_identifier",
            "identifiers_state", "identifiers_issuer", "taxonomies_code",
            "taxonomies_taxonomy_group", "taxonomies_state", "taxonomies_license",
            "addresses_country_code", "addresses_address_purpose", "addresses_address_type",
            "addresses_address_2", "addresses_fax_number", "endpoints_endpointType",
            "endpoints_endpointTypeDescription", "endpoints_endpoint",
            "endpoints_affiliation", "endpoints_useDescription",
            "endpoints_contentTypeDescription", "endpoints_country_code",
            "endpoints_country_name", "endpoints_address_type", "endpoints_address_1",
            "endpoints_city", "endpoints_state", "endpoints_postal_code",
            "endpoints_use", "endpoints_endpointDescription", "endpoints_affiliationName",
            "endpoints_contentType", "endpoints_contentOtherDescription",
            "endpoints_address_2", "endpoints_useOtherDescription"
          ))
          if (length(drop_cols)) {
            data_taxonomy <- dplyr::select(data_taxonomy, -dplyr::all_of(drop_cols))
          }
        }

        data_taxonomy
      }, error = function(e) {
        list(error = e)
      })

      if (!inherits(result, "data.frame") && is.list(result) && !is.null(result$error)) {
        err <- result$error
        if (attempt >= max_attempts) {
          message(sprintf(
            "Attempt %d/%d for taxonomy '%s' failed %s. Giving up.",
            attempt, max_attempts, taxonomy, extract_status(err$message)
          ))
          break
        }
        delay <- base_delay * 2^(attempt - 1)
        message(sprintf(
          "Attempt %d/%d for taxonomy '%s' failed %s. Retrying in %.1f seconds...",
          attempt, max_attempts, taxonomy, extract_status(err$message), delay
        ))
        Sys.sleep(delay)
        attempt <- attempt + 1L
        next
      }

      if (!is.null(result) && nrow(result)) {
        result_list[[index]] <- result
        message(sprintf("Retrieved %d record(s) for taxonomy '%s'.", nrow(result), taxonomy))
      } else {
        message(sprintf("No records returned for taxonomy '%s'.", taxonomy))
      }
      break
    }
  }

  dplyr::bind_rows(result_list)
}

.save_taxonomy_snapshot <- function(npi_data, snapshot_dir) {
  if (is.null(snapshot_dir)) {
    snapshot_dir <- mysterycall_tempdir("mysterycall_search_taxonomy", create = TRUE)
  } else if (!dir.exists(snapshot_dir)) {
    dir.create(snapshot_dir, showWarnings = FALSE, recursive = TRUE)
  }
  tryCatch({
    filename <- file.path(
      snapshot_dir,
      paste0("search_taxonomy_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".rds")
    )
    saveRDS(npi_data, filename)
  }, error = function(e) {
    message("Error saving data to file:\n", e$message)
  })
  invisible(NULL)
}
