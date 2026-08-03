#' Build a county payer mix from ACS health-insurance coverage tables
#'
#' Constructs a fuller insurance "payer mix" than the insured-vs-uninsured split
#' used in most access studies. Combines the ACS Subject table **S2701**
#' ("Selected Characteristics of Health Insurance Coverage", used here for the
#' headline insured / uninsured rates and the population denominator) with the
#' detailed coverage-type tables to add **Private**, **Public**, **Medicaid**,
#' and **Medicare** shares:
#'
#' \describe{
#'   \item{Private}{Table **B27002** — "With private health insurance".}
#'   \item{Public}{Table **B27003** — "With public coverage".}
#'   \item{Medicare}{Table **C27006** — "With Medicare coverage".}
#'   \item{Medicaid}{Table **C27007** — "With Medicaid/means-tested public
#'     coverage".}
#'   \item{Uninsured}{Table **B27001** — "No health insurance coverage", plus the
#'     S2701 percent-uninsured estimate.}
#' }
#'
#' Because a person may hold more than one coverage type (e.g. dual
#' Medicare + Medicaid), the type shares are computed as a percentage of the
#' total civilian noninstitutionalized population and do **not** sum to 100.
#' Coverage-type counts are obtained by summing every sex-by-age leaf whose
#' label carries the relevant "With ..." phrase, so the function self-corrects
#' across ACS vintages rather than depending on hard-coded cell numbers.
#'
#' Margins of error are propagated with the Census Bureau sum-of-squares rule,
#' \eqn{MOE_{sum} = \sqrt{\sum MOE_i^2}} (ACS Handbook Appendix 3); all MOEs are
#' at the 90% confidence level.
#'
#' @param year Integer. ACS 5-year survey end-year (2012-2023). Required — no
#'   default, to keep results reproducible.
#' @param states Character vector of two-letter state abbreviations, or `NULL`
#'   for all states (slow). Default `NULL`.
#' @param geography Character scalar passed to [tidycensus::get_acs()].
#'   Default `"county"`. Other useful values: `"tract"`, `"state"`, `"zcta"`.
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#'
#' @return A tibble with one row per geography and columns:
#' \describe{
#'   \item{`GEOID`, `NAME`}{Geography identifier and label.}
#'   \item{`total_pop`, `total_pop_moe`}{Civilian noninstitutionalized
#'     population (S2701 denominator) and its MOE.}
#'   \item{`n_private`, `n_public`, `n_medicare`, `n_medicaid`,
#'     `n_uninsured`}{Population counts with each coverage type.}
#'   \item{`*_moe`}{Propagated 90% MOE for each count.}
#'   \item{`pct_private`, `pct_public`, `pct_medicare`, `pct_medicaid`,
#'     `pct_uninsured`}{Share of `total_pop` (0-100) with each coverage type.}
#'   \item{`pct_insured_s2701`, `pct_uninsured_s2701`}{Headline insured /
#'     uninsured percentages taken directly from S2701.}
#'   \item{`year`}{The ACS end-year supplied.}
#' }
#'
#' @note Requires a Census API key in the `CENSUS_API_KEY` environment variable
#'   (see [tidycensus::census_api_key()]). Shares are `NA` where `total_pop`
#'   is zero.
#'
#' @seealso [mysterycall_get_acs_female_insurance()] for the female-only,
#'   single-county tract version built from the same sex-by-coverage-type
#'   tables; this builder generalises it (all persons, multi-state, any
#'   geography, with MOEs);
#'   [mysterycall_get_acs_adults_18_90()] and [mysterycall_summarize_census()]
#'   for other ACS covariate builders;
#'   [mysterycall_get_county_provider_counts()] and
#'   [mysterycall_summarize_county_enrollment()] for the provider-supply and
#'   Medicare/Medicaid-enrollment covariates that pair with payer mix.
#' @family census
#' @export
#'
#' @examplesIf interactive()
#' co <- mysterycall_get_payer_mix(year = 2022, states = "CO")
#' head(co[, c("NAME", "pct_private", "pct_medicaid", "pct_medicare",
#'             "pct_uninsured")])
mysterycall_get_payer_mix <- function(year = NULL,
                                      states = NULL,
                                      geography = "county",
                                      verbose = TRUE) {
  if (!requireNamespace("tidycensus", quietly = TRUE)) {
    stop("Package 'tidycensus' is required for mysterycall_get_payer_mix().",
         call. = FALSE)
  }
  if (is.null(year)) {
    stop("`year` is required (e.g. year = 2022L). No default is provided to ",
         "keep results reproducible.", call. = FALSE)
  }
  if (!is.numeric(year) || length(year) != 1L || year < 2012 || year > 2023) {
    stop(sprintf("Invalid `year`: %s. ACS 5-year coverage tables are available for 2012-2023.",
                 deparse(year)), call. = FALSE)
  }
  if (!is.character(geography) || length(geography) != 1L) {
    stop("`geography` must be a single character string.", call. = FALSE)
  }
  .mc_check_acs_vintage(year, geography, "mysterycall_get_payer_mix()")

  if (verbose) {
    message("")
    message("=========================================================")
    message("ACS PAYER MIX (health-insurance coverage) DOWNLOAD")
    message("=========================================================")
    message(sprintf("Year:       ACS %d (5-year estimates)", year))
    message(sprintf("Geography:  %s", geography))
    message(sprintf("States:     %s",
                    if (is.null(states)) "All US" else paste(states, collapse = ", ")))
    message("Tables:     S2701 (status) + B27002/B27003/C27006/C27007/B27001 (type)")
    message("")
  }

  # ---- resolve coverage-type leaves by label (vintage-robust) --------------
  vars <- tryCatch(
    tidycensus::load_variables(year = year, dataset = "acs5", cache = TRUE),
    error = function(e) stop(sprintf(
      "Census API error loading the variable dictionary:\n%s\n\nCheck CENSUS_API_KEY and that ACS 5-year %d is published.",
      e$message, year), call. = FALSE)
  )

  leaf_ids <- function(table, phrase) {
    hit <- vars[grepl(paste0("^", table, "_"), vars$name) &
                  grepl(phrase, vars$label, fixed = TRUE), , drop = FALSE]
    if (!nrow(hit)) {
      stop(sprintf("No ACS %d variables in table %s match label '%s'. ",
                   year, table, phrase),
           "The table may not exist for this vintage.", call. = FALSE)
    }
    hit$name
  }

  groups <- list(
    private  = leaf_ids("B27002", "With private health insurance"),
    public   = leaf_ids("B27003", "With public coverage"),
    medicare = leaf_ids("C27006", "With Medicare coverage"),
    medicaid = leaf_ids("C27007", "With Medicaid/means-tested public coverage"),
    uninsured = leaf_ids("B27001", "No health insurance coverage")
  )

  # Single wide pull: all coverage-type leaves + S2701 headline cells.
  s2701_ids <- c(total = "S2701_C01_001",
                 pct_insured = "S2701_C03_001",
                 pct_uninsured = "S2701_C05_001")
  all_ids <- unique(c(unlist(groups, use.names = FALSE), unname(s2701_ids)))

  if (verbose) {
    message(sprintf("Fetching %d ACS variables in one call...", length(all_ids)))
  }

  acs <- tryCatch(
    tidycensus::get_acs(
      geography   = geography,
      variables   = all_ids,
      year        = year,
      survey      = "acs5",
      output      = "wide",
      cache_table = TRUE,
      state       = states
    ),
    error = function(e) stop(sprintf(
      "Census API error:\n%s\n\nCheck CENSUS_API_KEY and internet connection.",
      e$message), call. = FALSE)
  )

  # ---- sum leaves per group, propagate MOE --------------------------------
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

  total_pop     <- acs[["S2701_C01_001E"]]
  total_pop_moe <- acs[["S2701_C01_001M"]]

  pct <- function(n) ifelse(total_pop > 0, round(n / total_pop * 100, 1), NA_real_)

  out <- tibble::tibble(
    GEOID = acs$GEOID,
    NAME  = acs$NAME,
    total_pop     = total_pop,
    total_pop_moe = total_pop_moe,
    n_private   = priv$est, n_private_moe   = priv$moe,
    n_public    = publ$est, n_public_moe    = publ$moe,
    n_medicare  = mcar$est, n_medicare_moe  = mcar$moe,
    n_medicaid  = mcad$est, n_medicaid_moe  = mcad$moe,
    n_uninsured = unin$est, n_uninsured_moe = unin$moe,
    pct_private   = pct(priv$est),
    pct_public    = pct(publ$est),
    pct_medicare  = pct(mcar$est),
    pct_medicaid  = pct(mcad$est),
    pct_uninsured = pct(unin$est),
    pct_insured_s2701   = acs[["S2701_C03_001E"]],
    pct_uninsured_s2701 = acs[["S2701_C05_001E"]],
    year = as.integer(year)
  )

  if (verbose) {
    message(sprintf("Done. %s geographies; median Medicaid share %.1f%%, median uninsured %.1f%%.",
                    format(nrow(out), big.mark = ","),
                    stats::median(out$pct_medicaid, na.rm = TRUE),
                    stats::median(out$pct_uninsured, na.rm = TRUE)))
    message("")
  }

  out
}

#' Deprecated alias for mysterycall_get_payer_mix
#' @param ... Arguments passed to [mysterycall_get_payer_mix()].
#' @return See [mysterycall_get_payer_mix()].
#' @keywords internal
#' @name get_payer_mix
get_payer_mix <- function(...) {
  .Deprecated("mysterycall_get_payer_mix")
  mysterycall_get_payer_mix(...)
}
