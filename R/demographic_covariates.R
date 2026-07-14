#' Track Clinician Churn at a Specific Practice Location (NPPES History)
#'
#' Since Tax Identifiers (TINs) are private, this function tracks office locations
#' longitudinally using physical practice address matches and organization NPI associations
#' within a historical NPPES DuckDB database.
#'
#' @param db_path Path to the DuckDB database (e.g. "/Volumes/MufflySamsung 1/nppes_historical.duckdb").
#' @param street_address Character. Practice Location Address Line 1.
#' @param zip_code Character. Five-digit ZIP code.
#' @param table_name Character. Name of the historical NPPES table to query in
#'   the DuckDB database. Default `"temporal_obgyn_only_all_years"`.
#' @return A data frame containing annual staffing levels, entries, exits, and churn rates.
#' @export
mysterycall_track_clinician_churn <- function(db_path, street_address, zip_code, table_name = "temporal_obgyn_only_all_years") {
  if (!file.exists(db_path)) {
    stop("DuckDB database not found at the specified path.")
  }
  
  con <- DBI::dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  
  addr_clean <- toupper(trimws(street_address))
  zip_clean <- substr(trimws(zip_code), 1, 5)
  
  if (table_name == "temporal_obgyn_only_all_years") {
    query <- sprintf("
      SELECT year, npi, first_name as provider_first_name, last_name as provider_last_name
      FROM temporal_obgyn_only_all_years
      WHERE UPPER(TRIM(practice_address_street)) = '%s'
        AND SUBSTR(practice_address_zip, 1, 5) = '%s'
      ORDER BY year, npi
    ", addr_clean, zip_clean)
  } else {
    query <- sprintf("
      SELECT year, npi, provider_first_name, provider_last_name
      FROM nppes_history
      WHERE UPPER(TRIM(practice_address_line1)) = '%s'
        AND SUBSTR(practice_postal_code, 1, 5) = '%s'
        AND entity_type_code = 1
      ORDER BY year, npi
    ", addr_clean, zip_clean)
  }
  
  df <- DBI::dbGetQuery(con, query)
  if (nrow(df) == 0) {
    message("No clinicians found matching the specified address and ZIP.")
    return(NULL)
  }
  
  years <- sort(unique(df$year))
  churn_results <- data.frame()
  
  for (i in seq_along(years)) {
    yr <- years[i]
    current_npis <- df$npi[df$year == yr]
    
    if (i == 1) {
      churn_results <- rbind(churn_results, data.frame(
        Year = yr,
        Staff_Count = length(current_npis),
        Joined = 0,
        Left = 0,
        Churn_Rate = 0.0
      ))
    } else {
      prev_yr <- years[i - 1]
      prev_npis <- df$npi[df$year == prev_yr]
      
      joined <- sum(!current_npis %in% prev_npis)
      left <- sum(!prev_npis %in% current_npis)
      
      baseline_staff <- length(prev_npis)
      churn_rate <- if (baseline_staff > 0) (joined + left) / baseline_staff else 0.0
      
      churn_results <- rbind(churn_results, data.frame(
        Year = yr,
        Staff_Count = length(current_npis),
        Joined = joined,
        Left = left,
        Churn_Rate = round(churn_rate, 3)
      ))
    }
  }
  
  return(churn_results)
}


#' Extract Female Insurance Shares from ACS Sex-by-Coverage-Type Tables
#'
#' Computes tract-level female health-insurance shares from the ACS 5-year
#' detailed coverage tables that are genuinely split by sex: private
#' (**B27002**), public (**B27003**), Medicare (**C27006**), Medicaid
#' (**C27007**), and insured/uninsured (**B27001**). Each share is the female
#' population with that coverage divided by the female civilian
#' noninstitutionalized population (the B27001 female universe, `B27001_030`).
#'
#' Coverage-type leaves are selected by matching the "With ..." label text
#' inside the *Female* branch of each table, so the function self-corrects
#' across ACS vintages instead of depending on hard-coded cell numbers. This
#' replaces an earlier implementation that mislabelled ACS Subject table
#' **S2701** cells: S2701 has no coverage-type breakdown and its `_010` row is
#' the "75 years and older" age band for both sexes, so the old
#' private/public/Medicaid/Medicare columns did not measure what their names
#' claimed.
#'
#' Because a person may hold more than one coverage type (e.g. dual
#' Medicare + Medicaid), the Private/Public/Medicaid/Medicare shares **overlap**
#' and do not sum to 100; only insured + uninsured partition the population.
#' Margins of error are propagated with the Census sum-of-squares rule,
#' \eqn{MOE_{sum} = \sqrt{\sum MOE_i^2}} (90\% confidence level).
#'
#' @param api_key Character. US Census API key (passed to
#'   [tidycensus::get_acs()]).
#' @param state_fips Character. Two-digit State FIPS code.
#' @param county_fips Character. Three-digit County FIPS code.
#' @param year Integer. ACS 5-year survey end-year. Default `2022`.
#' @return A data frame with one row per Census tract: geography identifiers,
#'   the female population denominator (`Total_Females`), the female counts with
#'   each coverage type (`N_Female_*`) with propagated MOEs (`*_moe`), and the
#'   corresponding shares of the female population (`Pct_Female_*`, 0-100).
#' @seealso [mysterycall_get_payer_mix()] for the all-persons, multi-geography
#'   generalisation of this builder.
#' @family census
#' @export
mysterycall_get_acs_female_insurance <- function(api_key, state_fips,
                                                 county_fips, year = 2022) {
  if (!requireNamespace("tidycensus", quietly = TRUE)) {
    stop("Package 'tidycensus' is required for ",
         "mysterycall_get_acs_female_insurance().", call. = FALSE)
  }
  if (!is.numeric(year) || length(year) != 1L || year < 2012 || year > 2023) {
    stop(sprintf("Invalid `year`: %s. ACS 5-year coverage tables are available for 2012-2023.",
                 deparse(year)), call. = FALSE)
  }

  # ---- resolve Female-branch coverage leaves by label (vintage-robust) ------
  vars <- tryCatch(
    tidycensus::load_variables(year = year, dataset = "acs5", cache = TRUE),
    error = function(e) stop(sprintf(
      "Census API error loading the variable dictionary:\n%s", e$message),
      call. = FALSE)
  )

  female_leaf <- function(table, phrase) {
    hit <- vars[grepl(paste0("^", table, "_"), vars$name) &
                  grepl("Female", vars$label) &
                  grepl(phrase, vars$label, fixed = TRUE), , drop = FALSE]
    if (!nrow(hit)) {
      stop(sprintf("No ACS %d Female variables in table %s match label '%s'.",
                   year, table, phrase), call. = FALSE)
    }
    hit$name
  }

  groups <- list(
    private   = female_leaf("B27002", "With private health insurance"),
    public    = female_leaf("B27003", "With public coverage"),
    medicare  = female_leaf("C27006", "With Medicare coverage"),
    medicaid  = female_leaf("C27007", "With Medicaid/means-tested public coverage"),
    uninsured = female_leaf("B27001", "No health insurance coverage")
  )

  # Female civilian noninstitutionalized population total = "...Total:!!Female:".
  female_total_id <- vars$name[grepl("^B27001_", vars$name) &
                                 grepl("Female:\\s*$", vars$label) &
                                 !grepl("years", vars$label)]
  if (length(female_total_id) != 1L) {
    stop("Could not uniquely identify the B27001 female population total.",
         call. = FALSE)
  }

  all_ids <- unique(c(unlist(groups, use.names = FALSE), female_total_id))

  acs <- tryCatch(
    tidycensus::get_acs(
      geography = "tract",
      variables = all_ids,
      year      = year,
      survey    = "acs5",
      state     = state_fips,
      county    = county_fips,
      output    = "wide",
      key       = api_key
    ),
    error = function(e) stop(sprintf(
      "Census API error:\n%s\n\nCheck the API key, state/county FIPS, and connection.",
      e$message), call. = FALSE)
  )

  # ---- sum leaves per group, propagate MOE ---------------------------------
  sum_group <- function(ids) {
    est_cols <- intersect(paste0(ids, "E"), names(acs))
    moe_cols <- intersect(paste0(ids, "M"), names(acs))
    est <- rowSums(as.data.frame(acs[, est_cols, drop = FALSE]), na.rm = TRUE)
    moe <- sqrt(rowSums(as.data.frame(acs[, moe_cols, drop = FALSE])^2, na.rm = TRUE))
    list(est = est, moe = moe)
  }

  priv <- sum_group(groups$private)
  publ <- sum_group(groups$public)
  mcar <- sum_group(groups$medicare)
  mcad <- sum_group(groups$medicaid)
  unin <- sum_group(groups$uninsured)

  total_f <- acs[[paste0(female_total_id, "E")]]
  pct <- function(n) ifelse(total_f > 0, round(n / total_f * 100, 1), NA_real_)

  data.frame(
    Census_Tract         = acs$NAME,
    GEOID                = acs$GEOID,
    State_FIPS           = substr(acs$GEOID, 1, 2),
    County_FIPS          = substr(acs$GEOID, 3, 5),
    Tract_FIPS           = substr(acs$GEOID, 6, 11),
    Total_Females        = total_f,
    N_Female_Private     = priv$est, N_Female_Private_moe   = priv$moe,
    N_Female_Public      = publ$est, N_Female_Public_moe    = publ$moe,
    N_Female_Medicare    = mcar$est, N_Female_Medicare_moe  = mcar$moe,
    N_Female_Medicaid    = mcad$est, N_Female_Medicaid_moe  = mcad$moe,
    N_Female_Uninsured   = unin$est, N_Female_Uninsured_moe = unin$moe,
    Pct_Female_Private   = pct(priv$est),
    Pct_Female_Public    = pct(publ$est),
    Pct_Female_Medicare  = pct(mcar$est),
    Pct_Female_Medicaid  = pct(mcad$est),
    Pct_Female_Uninsured = pct(unin$est),
    year                 = as.integer(year),
    stringsAsFactors     = FALSE
  )
}


#' Extract County-Level Metrics from HRSA Area Health Resources File (AHRF)
#'
#' @param ahrf_db_path Path to the local AHRF DuckDB or CSV database.
#' @param county_fips Character. Five-digit State-County FIPS code.
#' @return A data frame containing total population, OB-GYN supply, and public coverage metrics.
#' @export
mysterycall_get_hrsa_ahrf <- function(ahrf_db_path, county_fips) {
  if (!file.exists(ahrf_db_path)) {
    stop("AHRF database file not found.")
  }
  
  con <- DBI::dbConnect(duckdb::duckdb(), ahrf_db_path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  
  query <- sprintf("
    SELECT fips, county_name, state_abbrev,
           pop_total, 
           obgyn_count, 
           medicaid_enrolled
    FROM ahrf_county_data
    WHERE fips = '%s'
  ", county_fips)
  
  res <- DBI::dbGetQuery(con, query)
  return(res)
}


#' Retrieve CMS Monthly County-Level Enrollment Reports
#'
#' @param cms_csv_path Path to the downloaded CMS monthly enrollment CSV.
#' @param county_fips Character. Five-digit State-County FIPS code.
#' @return A data frame with monthly Medicare and Medicaid/CHIP enrollment counts.
#' @export
mysterycall_get_cms_enrollment <- function(cms_csv_path, county_fips) {
  if (!file.exists(cms_csv_path)) {
    stop("CMS monthly enrollment file not found.")
  }
  
  df <- utils::read.csv(cms_csv_path, stringsAsFactors = FALSE, check.names = FALSE)
  
  res <- df %>%
    dplyr::filter(FIPS == county_fips) %>%
    dplyr::select(FIPS, County, State, `Medicare Enrollment`, `Medicaid/CHIP Enrollment`, Report_Month)
  
  return(res)
}
