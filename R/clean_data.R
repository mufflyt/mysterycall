#' Clean and standardize raw mystery-caller data for analysis
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name clean_data
NULL

# ---- private helpers ---------------------------------------------------------

#' Apply a named character recode map to a vector
#'
#' Replaces elements of `x` whose value matches `names(map)` with the
#' corresponding element of `map`.  Non-matching values are left unchanged.
#'
#' @param x    Character (or factor) vector to recode.
#' @param map  Named character vector: `c("old_val" = "new_val", ...)`.
#' @return     Character vector the same length as `x`.
#' @keywords   internal
.mc_apply_recode <- function(x, map) {
  if (!length(map)) return(x)
  x_chr <- as.character(x)
  idx   <- match(x_chr, names(map))
  hit   <- !is.na(idx)
  x_chr[hit] <- map[idx[hit]]
  x_chr
}

#' Rename a single column in a data frame (base R, no side-effects)
#'
#' @param data   A data frame.
#' @param old    Current column name (character scalar).
#' @param new    Desired column name (character scalar).
#' @return       The data frame with the column renamed, or unchanged if `old`
#'   is `NULL`, `NA`, or not present.
#' @keywords     internal
.mc_rename_col <- function(data, old, new) {
  if (is.null(old) || is.na(old) || !nzchar(old)) return(data)
  pos <- match(old, names(data))
  if (!is.na(pos)) names(data)[pos] <- new
  data
}

#' Fill a column downward with the last non-NA value
#'
#' Uses `tidyr::fill()` when available, falls back to `zoo::na.locf()`, then
#' a pure-base-R forward-fill loop.
#'
#' @param data  A data frame.
#' @param col   Column name to fill.
#' @return      `data` with `col` forward-filled.
#' @keywords    internal
.mc_fill_col <- function(data, col) {
  if (!col %in% names(data)) return(data)

  if (requireNamespace("tidyr", quietly = TRUE)) {
    data <- tidyr::fill(data, dplyr::all_of(col), .direction = "down")
    return(data)
  }

  if (requireNamespace("zoo", quietly = TRUE)) {
    data[[col]] <- zoo::na.locf(data[[col]], na.rm = FALSE)
    return(data)
  }

  # Pure base R forward fill
  v <- data[[col]]
  for (i in seq_along(v)) {
    if (is.na(v[i]) && i > 1L) v[i] <- v[i - 1L]
  }
  data[[col]] <- v
  data
}

#' Order a column's factor levels by descending frequency
#'
#' Uses `forcats::fct_infreq()` when available; otherwise delegates to the
#' package's own `mysterycall_reorder_by_freq()`.
#'
#' @param data  A data frame.
#' @param col   Column name to reorder.
#' @return      `data` with `col` converted to a frequency-ordered factor.
#' @keywords    internal
.mc_infreq_col <- function(data, col) {
  if (!col %in% names(data)) return(data)
  if (requireNamespace("forcats", quietly = TRUE)) {
    data[[col]] <- forcats::fct_infreq(data[[col]])
  } else {
    data[[col]] <- mysterycall_reorder_by_freq(data[[col]])
  }
  data
}

# ---- shared core logic -------------------------------------------------------

#' Internal: perform all cleaning steps common to both exported functions
#'
#' Called by both `mysterycall_clean_data()` and
#' `mysterycall_clean_data_keep_identifiers()`.
#'
#' @inheritParams mysterycall_clean_data
#' @param keep_all Logical. When `TRUE`, the full column set (minus PII) is
#'   returned.  When `FALSE`, only the set of standardized columns defined by
#'   the `*_col` parameters is returned.
#' @return A cleaned data frame.
#' @keywords internal
.mc_clean_core <- function(
    data,
    id_col,
    age_col,
    age_breaks,
    age_labels,
    wait_col,
    insurance_col,
    gender_col,
    credential_col,
    academic_col,
    rurality_col,
    central_col,
    transfers_col,
    recode_credential,
    recode_academic,
    recode_rurality,
    recode_central,
    drop_pii,
    fill_cols,
    keep_all) {

  # ------------------------------------------------------------------
  # 1. Validate input
  # ------------------------------------------------------------------
  validate_dataframe(data, name = "data")
  n_in <- nrow(data)
  message(sprintf("mysterycall_clean_data: %d row(s), %d column(s) received.",
                  n_in, ncol(data)))

  # ------------------------------------------------------------------
  # 2. Deduplicate by id_col (keep first occurrence)
  # ------------------------------------------------------------------
  if (!is.null(id_col) && nzchar(id_col)) {
    if (id_col %in% names(data)) {
      dup_mask <- duplicated(data[[id_col]])
      n_dup    <- sum(dup_mask)
      if (n_dup > 0L) {
        message(sprintf("  Removing %d duplicate row(s) based on '%s'.", n_dup, id_col))
        data <- data[!dup_mask, , drop = FALSE]
      }
    } else {
      warning(sprintf(
        "id_col '%s' not found in data; skipping deduplication.", id_col),
        call. = FALSE)
    }
  }

  # ------------------------------------------------------------------
  # 3. Fill specified columns downward (while still using original names)
  # ------------------------------------------------------------------
  fill_present <- intersect(fill_cols, names(data))
  if (length(fill_present)) {
    for (fc in fill_present) {
      data <- .mc_fill_col(data, fc)
    }
    message(sprintf("  Forward-filled column(s): %s.", paste(fill_present, collapse = ", ")))
  }

  # ------------------------------------------------------------------
  # 4. Create age_category
  # ------------------------------------------------------------------
  age_cat_col <- NULL
  if (!is.null(age_col) && nzchar(age_col)) {
    if (age_col %in% names(data)) {
      if (length(age_labels) != length(age_breaks) - 1L) {
        stop(
          sprintf(
            "Length of age_labels (%d) must equal length(age_breaks) - 1 (%d).",
            length(age_labels), length(age_breaks) - 1L),
          call. = FALSE)
      }
      data[["age_category"]] <- cut(
        as.numeric(data[[age_col]]),
        breaks = age_breaks,
        labels = age_labels,
        right  = FALSE,
        include.lowest = TRUE
      )
      age_cat_col <- "age_category"
      message(sprintf("  Created 'age_category' from '%s'.", age_col))
    } else {
      message(sprintf("  age_col '%s' not found; skipping age category.", age_col))
    }
  }

  # ------------------------------------------------------------------
  # 5. Apply recode mappings (base R match pattern, original col names)
  # ------------------------------------------------------------------
  .recode_if_present <- function(df, col_param, recode_map, label) {
    if (is.null(col_param) || !nzchar(col_param)) return(df)
    if (!col_param %in% names(df)) {
      message(sprintf("  Column '%s' (%s) not found; skipping recode.", col_param, label))
      return(df)
    }
    if (!length(recode_map)) return(df)
    df[[col_param]] <- .mc_apply_recode(df[[col_param]], recode_map)
    message(sprintf("  Recoded '%s' (%s).", col_param, label))
    df
  }

  data <- .recode_if_present(data, credential_col, recode_credential, "credential")
  data <- .recode_if_present(data, academic_col,   recode_academic,   "academic")
  data <- .recode_if_present(data, rurality_col,   recode_rurality,   "rurality")
  data <- .recode_if_present(data, central_col,    recode_central,    "central scheduling")

  # ------------------------------------------------------------------
  # 6. Order factor levels by frequency
  # ------------------------------------------------------------------
  freq_cols <- Filter(Negate(is.null), list(
    insurance_col, gender_col, credential_col,
    academic_col, rurality_col, central_col, age_cat_col
  ))
  freq_cols <- unique(unlist(freq_cols))
  freq_present <- intersect(freq_cols, names(data))
  for (fc in freq_present) {
    data <- .mc_infreq_col(data, fc)
  }

  # ------------------------------------------------------------------
  # 7. Rename columns to human-readable labels
  # ------------------------------------------------------------------
  rename_pairs <- list(
    list(old = wait_col,       new = "Business days until appointment"),
    list(old = insurance_col,  new = "Insurance"),
    list(old = gender_col,     new = "Gender"),
    list(old = credential_col, new = "Physician credential"),
    list(old = academic_col,   new = "Academic affiliation"),
    list(old = rurality_col,   new = "Rurality"),
    list(old = central_col,    new = "Central scheduling"),
    list(old = age_cat_col,    new = "Age category")
  )

  for (pair in rename_pairs) {
    old <- pair$old
    new <- pair$new
    if (is.null(old) || !nzchar(old)) next
    if (old %in% names(data) && old != new) {
      # Guard against collision: if target name already exists (and differs from source), warn
      if (new %in% names(data) && new != old) {
        warning(sprintf(
          "Cannot rename '%s' to '%s': target column already exists. Skipping.",
          old, new), call. = FALSE)
        next
      }
      data <- .mc_rename_col(data, old, new)
      message(sprintf("  Renamed '%s' -> '%s'.", old, new))
    }
  }

  # ------------------------------------------------------------------
  # 8. Drop PII columns
  # ------------------------------------------------------------------
  if (drop_pii) {
    pii_names <- c("first", "last", "middle", "phone", "address",
                   "notes", "record_id", "npi", "zip")
    # Case-insensitive match against current column names
    drop_hits <- names(data)[tolower(names(data)) %in% pii_names]
    if (length(drop_hits)) {
      data <- data[, setdiff(names(data), drop_hits), drop = FALSE]
      message(sprintf("  Dropped PII column(s): %s.", paste(drop_hits, collapse = ", ")))
    }
  }

  # ------------------------------------------------------------------
  # 9. Return
  # ------------------------------------------------------------------
  message(sprintf("mysterycall_clean_data: returning %d row(s), %d column(s).",
                  nrow(data), ncol(data)))
  data
}

# ---- exported functions ------------------------------------------------------

#' Clean raw mystery-caller data for publication-ready analysis
#'
#' Transforms a raw REDCap / Phase-2 export into a tidy, human-readable data
#' frame suitable for `gtsummary::tbl_summary()`, regression models, and
#' manuscript tables.  Steps include deduplication, age categorisation, value
#' recoding, factor-level ordering by frequency, column renaming to title-case
#' labels, and optional PII removal.
#'
#' @param data            A data frame of raw mystery-caller records (e.g. a
#'   REDCap export).  Must be a `data.frame` or subclass thereof.
#' @param id_col          Character scalar.  Column used to identify unique
#'   physicians for deduplication (first occurrence kept).  Set to `NULL` to
#'   skip deduplication. Default `"phone"`.
#' @param age_col         Character scalar or `NULL`.  Name of the numeric age
#'   column. When `NULL`, age processing is skipped entirely.  Default
#'   `"age"`.
#' @param age_breaks      Numeric vector of cut points passed to [base::cut()].
#'   Default `c(-Inf, 50, 60, 70, Inf)`.
#' @param age_labels      Character vector of category labels, length
#'   `length(age_breaks) - 1`. Default `c("<50 yrs", "50-59 yrs", "60-69 yrs",
#'   ">=70 yrs")`.
#' @param wait_col        Character scalar or `NULL`.  Wait-time column (business
#'   days). Renamed to `"Business days until appointment"` in output. Default
#'   `"business_days_until_appointment"`.
#' @param insurance_col   Character scalar or `NULL`. Default `"insurance"`.
#'   Renamed to `"Insurance"` in output.
#' @param gender_col      Character scalar or `NULL`. Default `"gender"`.
#'   Renamed to `"Gender"` in output.
#' @param credential_col  Character scalar or `NULL`. Column holding raw NPPES
#'   credential strings (`"MD"`, `"DO"`, etc.).  Default
#'   `"Provider.Credential.Text"`. Renamed to `"Physician credential"` in
#'   output.
#' @param academic_col    Character scalar or `NULL`. Default
#'   `"academic_affiliation"`. Renamed to `"Academic affiliation"` in output.
#' @param rurality_col    Character scalar or `NULL`. CBSA type column. Default
#'   `"cbsatype10"`. Renamed to `"Rurality"` in output.
#' @param central_col     Character scalar or `NULL`. Central-scheduling
#'   indicator column. Default `"central_number_e_g_appointment_center"`.
#'   Renamed to `"Central scheduling"` in output.
#' @param transfers_col   Character scalar or `NULL`. Number-of-transfers
#'   column.  No recode is applied; the column is kept as-is. Default `NULL`
#'   (skip).
#' @param recode_credential Named character vector mapping raw credential values
#'   to display labels. Default `c("MD" = "Allopathic training", "DO" =
#'   "Osteopathic training")`.
#' @param recode_academic Named character vector mapping raw academic-affiliation
#'   values. Default `c("University" = "Academic Practice")`.
#' @param recode_rurality Named character vector mapping raw CBSA-type values.
#'   Default `c("Metro" = "Metropolitan area", "Micro" = "Rural area")`.
#' @param recode_central  Named character vector mapping raw central-scheduling
#'   values. Default `c("Yes" = "Yes, central scheduling")`.
#' @param drop_pii        Logical.  When `TRUE` (default), columns named
#'   `first`, `last`, `middle`, `phone`, `address`, `notes`, `record_id`,
#'   `npi`, and `zip` (case-insensitive) are removed from the output.
#' @param fill_cols       Character vector of column names to forward-fill
#'   (last-observation-carried-forward) before any recoding or renaming. Uses
#'   `tidyr::fill()` when the package is installed, then `zoo::na.locf()`, then
#'   a pure-base-R loop. Columns absent from `data` are silently ignored.
#'   Default `c("academic_affiliation", "cbsatype10")`.
#'
#' @return A cleaned `data.frame` with:
#' \itemize{
#'   \item Deduplicated rows (one row per physician).
#'   \item An `"Age category"` column (ordered factor) when `age_col` is
#'         present.
#'   \item Recoded and frequency-ordered factor columns.
#'   \item Human-readable, title-case column names for all recognised fields.
#'   \item PII columns removed when `drop_pii = TRUE`.
#' }
#'
#' @section Recode convention:
#'   Each `recode_*` argument is a named character vector where **names** are
#'   the raw (input) values and **values** are the desired display labels.
#'   Non-matching values are left unchanged.  Pass an empty vector (`character(0)`)
#'   to suppress recoding for a particular column.
#'
#' @section Optional dependencies:
#'   `tidyr` (in `Suggests`) is used for forward-filling; `zoo` and `forcats`
#'   are used opportunistically when installed.  All three are optional: the
#'   function degrades gracefully to built-in fallbacks when they are absent.
#'
#' @family data utilities
#' @seealso [mysterycall_clean_data_keep_identifiers()] for a variant that
#'   retains PII columns; [mysterycall_reorder_by_freq()] for the base-R
#'   frequency-ordering used as a `forcats` fallback.
#' @export
#'
#' @examples
#' # Minimal example with base R only ------------------------------------------
#' set.seed(42)
#' raw <- data.frame(
#'   phone         = c("303-111-2222", "303-111-2222", "720-555-9999"),
#'   age           = c(55, 55, 72),
#'   insurance     = c("Medicaid", "Medicaid", "Medicare"),
#'   gender        = c("Female", "Female", "Male"),
#'   Provider.Credential.Text = c("MD", "MD", "DO"),
#'   academic_affiliation     = c("University", NA, "Community"),
#'   cbsatype10               = c("Metro", "Metro", "Micro"),
#'   business_days_until_appointment = c(7L, 7L, 14L),
#'   central_number_e_g_appointment_center = c("Yes", "Yes", "No"),
#'   first  = c("Jane", "Jane", "Bob"),
#'   last   = c("Doe",  "Doe",  "Smith"),
#'   record_id = 1:3,
#'   stringsAsFactors = FALSE
#' )
#'
#' cleaned <- mysterycall_clean_data(raw)
#' print(names(cleaned))
#' print(cleaned[["Age category"]])
#'
#' # Custom age breaks ---------------------------------------------------------
#' cleaned2 <- mysterycall_clean_data(
#'   raw,
#'   age_breaks = c(-Inf, 45, 65, Inf),
#'   age_labels = c("<45 yrs", "45-64 yrs", ">=65 yrs")
#' )
#' print(cleaned2[["Age category"]])
#'
#' # Skip age processing entirely ----------------------------------------------
#' cleaned3 <- mysterycall_clean_data(raw, age_col = NULL)
#' stopifnot(!"Age category" %in% names(cleaned3))
mysterycall_clean_data <- function(
    data,
    id_col          = "phone",
    age_col         = "age",
    age_breaks      = c(-Inf, 50, 60, 70, Inf),
    age_labels      = c("<50 yrs", "50-59 yrs", "60-69 yrs", ">=70 yrs"),
    wait_col        = "business_days_until_appointment",
    insurance_col   = "insurance",
    gender_col      = "gender",
    credential_col  = "Provider.Credential.Text",
    academic_col    = "academic_affiliation",
    rurality_col    = "cbsatype10",
    central_col     = "central_number_e_g_appointment_center",
    transfers_col   = NULL,
    recode_credential = c("MD" = "Allopathic training",
                          "DO" = "Osteopathic training"),
    recode_academic   = c("University" = "Academic Practice"),
    recode_rurality   = c("Metro" = "Metropolitan area",
                          "Micro" = "Rural area"),
    recode_central    = c("Yes" = "Yes, central scheduling"),
    drop_pii          = TRUE,
    fill_cols         = c("academic_affiliation", "cbsatype10")) {

  .mc_clean_core(
    data              = data,
    id_col            = id_col,
    age_col           = age_col,
    age_breaks        = age_breaks,
    age_labels        = age_labels,
    wait_col          = wait_col,
    insurance_col     = insurance_col,
    gender_col        = gender_col,
    credential_col    = credential_col,
    academic_col      = academic_col,
    rurality_col      = rurality_col,
    central_col       = central_col,
    transfers_col     = transfers_col,
    recode_credential = recode_credential,
    recode_academic   = recode_academic,
    recode_rurality   = recode_rurality,
    recode_central    = recode_central,
    drop_pii          = drop_pii,
    fill_cols         = fill_cols,
    keep_all          = TRUE
  )
}


#' Clean mystery-caller data while retaining all identifier columns
#'
#' A convenience wrapper around [mysterycall_clean_data()] that sets
#' `drop_pii = FALSE` by default and preserves every column in the input
#' (including `phone`, `npi`, `first`, `last`, etc.).  Useful during QC
#' when you need to trace a cleaned record back to its source.
#'
#' All parameters are identical to [mysterycall_clean_data()]; only the
#' default for `drop_pii` differs.
#'
#' @inheritParams mysterycall_clean_data
#' @param drop_pii Logical. Default `FALSE` (keep identifier columns). Set to
#'   `TRUE` to mimic the behaviour of [mysterycall_clean_data()].
#'
#' @return A cleaned `data.frame` identical in structure to the output of
#'   [mysterycall_clean_data()], but with PII/identifier columns retained.
#'   The physician-identifier column (`id_col`) is always present in the
#'   output regardless of other settings.
#'
#' @family data utilities
#' @seealso [mysterycall_clean_data()] for the PII-dropping variant.
#' @export
#'
#' @examples
#' raw <- data.frame(
#'   phone    = c("303-111-2222", "303-111-2222", "720-555-9999"),
#'   age      = c(55, 55, 72),
#'   insurance = c("Medicaid", "Medicaid", "Medicare"),
#'   gender   = c("Female", "Female", "Male"),
#'   Provider.Credential.Text = c("MD", "MD", "DO"),
#'   academic_affiliation     = c("University", NA, "Community"),
#'   cbsatype10               = c("Metro", "Metro", "Micro"),
#'   business_days_until_appointment = c(7L, 7L, 14L),
#'   central_number_e_g_appointment_center = c("Yes", "Yes", "No"),
#'   first  = c("Jane", "Jane", "Bob"),
#'   last   = c("Doe",  "Doe",  "Smith"),
#'   npi    = c("1234567890", "1234567890", "0987654321"),
#'   record_id = 1:3,
#'   stringsAsFactors = FALSE
#' )
#'
#' # Identifiers are retained (phone, npi, first, last, record_id all present)
#' kcleaned <- mysterycall_clean_data_keep_identifiers(raw)
#' stopifnot(all(c("phone", "npi", "first", "last") %in% names(kcleaned)))
#'
#' # Deduplication still happens - only 2 unique physicians
#' stopifnot(nrow(kcleaned) == 2L)
mysterycall_clean_data_keep_identifiers <- function(
    data,
    id_col          = "phone",
    age_col         = "age",
    age_breaks      = c(-Inf, 50, 60, 70, Inf),
    age_labels      = c("<50 yrs", "50-59 yrs", "60-69 yrs", ">=70 yrs"),
    wait_col        = "business_days_until_appointment",
    insurance_col   = "insurance",
    gender_col      = "gender",
    credential_col  = "Provider.Credential.Text",
    academic_col    = "academic_affiliation",
    rurality_col    = "cbsatype10",
    central_col     = "central_number_e_g_appointment_center",
    transfers_col   = NULL,
    recode_credential = c("MD" = "Allopathic training",
                          "DO" = "Osteopathic training"),
    recode_academic   = c("University" = "Academic Practice"),
    recode_rurality   = c("Metro" = "Metropolitan area",
                          "Micro" = "Rural area"),
    recode_central    = c("Yes" = "Yes, central scheduling"),
    drop_pii          = FALSE,
    fill_cols         = c("academic_affiliation", "cbsatype10")) {

  result <- .mc_clean_core(
    data              = data,
    id_col            = id_col,
    age_col           = age_col,
    age_breaks        = age_breaks,
    age_labels        = age_labels,
    wait_col          = wait_col,
    insurance_col     = insurance_col,
    gender_col        = gender_col,
    credential_col    = credential_col,
    academic_col      = academic_col,
    rurality_col      = rurality_col,
    central_col       = central_col,
    transfers_col     = transfers_col,
    recode_credential = recode_credential,
    recode_academic   = recode_academic,
    recode_rurality   = recode_rurality,
    recode_central    = recode_central,
    drop_pii          = drop_pii,
    fill_cols         = fill_cols,
    keep_all          = TRUE
  )

  # Guarantee id_col survives even when it was already present
  # (no-op if it was preserved, which it always is when drop_pii=FALSE and
  # id_col is not in the PII list, or when drop_pii=TRUE but id_col was not
  # in the PII list).
  if (!is.null(id_col) && nzchar(id_col) && !id_col %in% names(result)) {
    # id_col was removed (unlikely with drop_pii=FALSE, but defensive): restore
    # it from the pre-clean data if possible.
    if (id_col %in% names(data)) {
      dedup_idx <- which(!duplicated(data[[id_col]]))
      result[[id_col]] <- data[[id_col]][dedup_idx]
      message(sprintf("  Restored id_col '%s' to output.", id_col))
    }
  }

  result
}
