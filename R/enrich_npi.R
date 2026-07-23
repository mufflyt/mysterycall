#' Integrated NPI enrichment pipeline
#'
#' @name mysterycall_enrich_npi
NULL

#' Enrich a roster of NPIs with clinician demographics and regional assignments
#'
#' Runs the standard mysterycall NPI enrichment pipeline in one call:
#' 1. Fetch clinician data via [mysterycall_get_clinician_data()]
#' 2. Infer gender from first name via [mysterycall_genderize()]
#' 3. Classify practice setting via [mysterycall_classify_practice_setting()]
#' 4. Assign ACOG district via [mysterycall_assign_region()]
#' 5. (Optional) Deduplicate on NPI, keeping the row with the most non-NA values
#'
#' @param data A data frame with at least an `npi` column (character or numeric).
#' @param first_name_col Name of the column containing the provider's first name,
#'   used for gender inference. Default `"first_name"`. Set to `NULL` to skip
#'   genderization.
#' @param state_col Name of the column containing US state (full name or
#'   two-letter abbreviation) for ACOG district assignment. Default `"state"`.
#'   Set to `NULL` to skip region assignment.
#' @param address_col Name of the column containing the practice address, used
#'   by [mysterycall_classify_practice_setting()]. Default `"address"`. Set to
#'   `NULL` to skip practice classification.
#' @param acog_out Name of the output column for the ACOG district.
#'   Default `"acog_district"`.
#' @param dedup Logical. When `TRUE` (default), deduplicate on `npi`, keeping
#'   the row with the greatest number of non-NA values.
#' @param quiet Logical. When `TRUE`, suppress step messages. Default `FALSE`.
#'
#' @return A data frame (tibble) with all original columns plus enrichment
#'   columns added by each pipeline step. Steps that are skipped (because
#'   `first_name_col`, `state_col`, or `address_col` is `NULL`, or because
#'   a required package is absent) leave the data unchanged.
#'
#' @seealso [mysterycall_get_clinician_data()], [mysterycall_genderize()],
#'   [mysterycall_classify_practice_setting()], [mysterycall_assign_region()]
#' @family npi
#' @export
#'
#' @examples
#' # Requires live NPPES API access and (optionally) a Genderize.io API key.
#' \dontrun{
#' roster <- data.frame(
#'   npi        = c("1234567893", "9876543210"),
#'   first_name = c("Jane", "John"),
#'   state      = c("CO", "NY"),
#'   stringsAsFactors = FALSE
#' )
#' enriched <- mysterycall_enrich_npi(roster)
#' }
mysterycall_enrich_npi <- function(
    data,
    first_name_col = "first_name",
    state_col      = "state",
    address_col    = "address",
    acog_out       = "acog_district",
    dedup          = TRUE,
    quiet          = FALSE
) {
  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  if (!"npi" %in% names(data))
    stop("`data` must contain an 'npi' column.", call. = FALSE)

  .msg <- function(...) if (!quiet) message(...)

  # Step 1: fetch clinician data
  .msg("Step 1/4: fetching clinician data via NPPES...")
  data <- tryCatch(
    mysterycall_get_clinician_data(data),
    error = function(e) {
      warning("mysterycall_get_clinician_data() failed: ", conditionMessage(e),
              "\nSkipping step 1.", call. = FALSE)
      data
    }
  )

  # Step 2: registry gender. Step 1 already attaches DAC/NPPES `gender` via
  # get_clinician_data(); here we fill any remaining gaps straight from the
  # NPPES `basic_sex` field. Genderize.io (first-name inference) is no longer
  # used: it burns a monthly quota and only guesses.
  needs_gender <- !"gender" %in% names(data) || any(is.na(data[["gender"]]))
  if ("npi" %in% names(data) && needs_gender &&
      requireNamespace("npi", quietly = TRUE)) {
    .msg("Step 2/4: filling gender from NPPES (basic_sex)...")
    data <- tryCatch(
      {
        if (!"gender" %in% names(data)) data[["gender"]] <- NA_character_
        miss  <- is.na(data[["gender"]])
        nppes <- mysterycall_nppes_gender(unique(data[["npi"]][miss]))
        hit   <- nppes$gender[match(data[["npi"]], nppes$npi)]
        fill  <- miss & !is.na(hit)
        data[["gender"]][fill] <- hit[fill]
        data
      },
      error = function(e) {
        warning("NPPES gender fill failed: ", conditionMessage(e),
                "\nSkipping step 2.", call. = FALSE)
        data
      }
    )
  } else {
    .msg("Step 2/4: gender already present or NPPES unavailable; skipping fill.")
  }

  # Step 3: classify practice setting — takes a character vector, returns a
  # vector of labels; add result as new column "practice_setting".
  if (!is.null(address_col) && address_col %in% names(data)) {
    .msg("Step 3/4: classifying practice setting...")
    data <- tryCatch(
      {
        data$practice_setting <- mysterycall_classify_practice_setting(
          data[[address_col]]
        )
        data
      },
      error = function(e) {
        warning("mysterycall_classify_practice_setting() failed: ", conditionMessage(e),
                "\nSkipping step 3.", call. = FALSE)
        data
      }
    )
  } else {
    .msg("Step 3/4: skipping practice classification (address_col not found or NULL).")
  }

  # Step 4: assign ACOG district
  if (!is.null(state_col) && state_col %in% names(data)) {
    .msg("Step 4/4: assigning ACOG district...")
    data[[acog_out]] <- mysterycall_assign_region(data[[state_col]], system = "acog")
  } else {
    .msg("Step 4/4: skipping ACOG assignment (state_col not found or NULL).")
  }

  # Dedup on NPI: keep row with most non-NA values per NPI
  if (dedup && anyDuplicated(data$npi)) {
    .msg("Deduplicating on NPI (", sum(duplicated(data$npi)), " duplicate(s) removed)...")
    data$..nonNA.. <- rowSums(!is.na(data))
    data <- data[order(data$npi, -data$..nonNA..), ]
    data <- data[!duplicated(data$npi), ]
    data$..nonNA.. <- NULL
  }

  data
}
