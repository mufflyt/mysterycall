#' County provider counts and Medicare/Medicaid enrollment covariates
#'
#' @description
#' Two covariate builders that summarise physician supply and public-payer
#' enrollment at the county (5-digit FIPS) level, for merging onto
#' mystery-caller office data as environment covariates alongside the ACS payer
#' mix from [mysterycall_get_payer_mix()].
#'
#' * [mysterycall_get_county_provider_counts()] collapses a provider roster
#'   (one row per NPI, or per NPI-location) to a distinct-provider count per
#'   county, optionally scaled to a per-capita density.
#' * [mysterycall_summarize_county_enrollment()] aggregates CMS Medicare and
#'   Medicaid enrollment to the county level and derives the Medicaid-to-Medicare
#'   ratio and an access category. Its input can be assembled from
#'   [mysterycall_get_cms_enrollment()] (single-county CMS reader).
#'
#' Both operate on data frames you supply (an NPPES/roster extract, a CMS
#' enrollment file), so they carry no large bundled data and stay reproducible.
#'
#' @name county_covariates
NULL

# Normalise a county identifier to a zero-padded 5-character FIPS string.
.normalize_county_fips <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  x[x %in% c("", "NA")] <- NA_character_
  # Keep only rows that look numeric; pad 4-digit codes that lost a leading 0.
  padded <- ifelse(is.na(x), NA_character_, stringr::str_pad(x, 5, pad = "0"))
  padded
}

#' Count distinct providers per county
#'
#' Aggregates a provider roster to the number of distinct providers (NPIs) in
#' each county, with an optional per-capita density. County-level physician
#' supply is a standard confounder for insurance-based access disparities: a
#' Medicaid patient's odds of getting an appointment depend partly on how many
#' clinicians practise locally.
#'
#' @param providers A data frame with one row per provider (or per
#'   provider-location); duplicate NPIs within a county are counted once.
#' @param npi_col Character. Column holding the NPI (or any provider id used for
#'   the distinct count). Default `"npi"`.
#' @param county_col Character. Column holding the county FIPS code (values are
#'   zero-padded to 5 characters). Default `"fips_county"`.
#' @param taxonomy_col Character or `NULL`. Optional taxonomy/specialty column;
#'   when supplied, an additional per-county-per-specialty count is returned in
#'   `by_specialty`. Default `NULL`.
#' @param population A data frame of county populations for density, or `NULL`
#'   to skip density. Default `NULL`.
#' @param pop_county_col,pop_col Character. Columns in `population` holding the
#'   county FIPS and the population count. Defaults `"fips_county"` / `"population"`.
#' @param per Numeric. Density scaling (providers per `per` residents).
#'   Default `100000`.
#' @param denominator_label Character or `NULL`. When supplied (e.g. `"women"`),
#'   it is appended to the density column name so it self-documents the
#'   denominator you passed via `pop_col` -- for example
#'   `providers_per_100k_women` when `population` holds a female count. `NULL`
#'   (default) keeps the generic `providers_per_100k`. This changes only the
#'   column name, not the arithmetic.
#'
#' @return A list of class `mysterycall_provider_counts` with elements:
#' \describe{
#'   \item{`by_county`}{Tibble: `fips_county`, `n_providers`, and (when
#'     `population` supplied) `population` and the density column
#'     (`providers_per_100k`, or `providers_per_100k_<denominator_label>` when
#'     `denominator_label` is set), scaled by `per`.}
#'   \item{`by_specialty`}{Tibble of `fips_county`, taxonomy, `n_providers`,
#'     or `NULL` when `taxonomy_col` is `NULL`.}
#'   \item{`n_counties`}{Integer count of counties represented.}
#' }
#'   Rows with a missing county FIPS emit a warning and are dropped.
#'
#' @family census
#' @export
#' @examples
#' roster <- data.frame(
#'   npi         = sprintf("1%09d", 1:6),
#'   fips_county = c("08031", "08031", "8031", "48201", "48201", NA),
#'   taxonomy    = c("OBGYN", "OBGYN", "FM", "OBGYN", "OBGYN", "FM"),
#'   stringsAsFactors = FALSE
#' )
#' pop <- data.frame(fips_county = c("08031", "48201"),
#'                   population   = c(715522, 4731145))
#' mysterycall_get_county_provider_counts(roster, population = pop)
#'
#' # Female denominator -> self-documenting column `providers_per_100k_women`
#' women <- data.frame(fips_county = c("08031", "48201"),
#'                     population   = c(361000, 2350000))
#' mysterycall_get_county_provider_counts(roster, population = women,
#'                                        denominator_label = "women")
mysterycall_get_county_provider_counts <- function(providers,
                                                   npi_col      = "npi",
                                                   county_col   = "fips_county",
                                                   taxonomy_col = NULL,
                                                   population    = NULL,
                                                   pop_county_col = "fips_county",
                                                   pop_col        = "population",
                                                   per            = 100000,
                                                   denominator_label = NULL) {
  if (!is.data.frame(providers)) {
    stop(sprintf("`providers` must be a data frame, not %s.", class(providers)[1L]),
         call. = FALSE)
  }
  for (col in c(npi_col, county_col)) {
    if (!col %in% names(providers)) {
      stop(sprintf("Column '%s' not found in `providers`.\nAvailable: %s",
                   col, paste(names(providers), collapse = ", ")), call. = FALSE)
    }
  }
  if (!is.null(taxonomy_col) && !taxonomy_col %in% names(providers)) {
    stop(sprintf("`taxonomy_col` '%s' not found in `providers`.", taxonomy_col),
         call. = FALSE)
  }
  if (!is.numeric(per) || length(per) != 1L || per <= 0) {
    stop("`per` must be a single positive number.", call. = FALSE)
  }
  if (!is.null(denominator_label) &&
      (!is.character(denominator_label) || length(denominator_label) != 1L ||
       !nzchar(denominator_label))) {
    stop("`denominator_label` must be a single non-empty string or NULL.", call. = FALSE)
  }

  df <- tibble::as_tibble(providers)
  df$.fips <- .normalize_county_fips(df[[county_col]])

  n_missing <- sum(is.na(df$.fips))
  if (n_missing) {
    warning(sprintf("%d provider row(s) had a missing/blank county FIPS and were dropped.",
                    n_missing), call. = FALSE)
    df <- df[!is.na(df$.fips), , drop = FALSE]
  }

  by_county <- dplyr::summarise(
    dplyr::group_by(df, .data$.fips),
    n_providers = dplyr::n_distinct(.data[[npi_col]]),
    .groups = "drop"
  )
  by_county <- dplyr::rename(by_county, fips_county = ".fips")

  if (!is.null(population)) {
    if (!is.data.frame(population)) {
      stop("`population` must be a data frame or NULL.", call. = FALSE)
    }
    for (col in c(pop_county_col, pop_col)) {
      if (!col %in% names(population)) {
        stop(sprintf("Column '%s' not found in `population`.", col), call. = FALSE)
      }
    }
    pop <- tibble::tibble(
      fips_county = .normalize_county_fips(population[[pop_county_col]]),
      population  = suppressWarnings(as.numeric(population[[pop_col]]))
    )
    pop <- pop[!is.na(pop$fips_county), , drop = FALSE]
    by_county <- dplyr::left_join(by_county, pop, by = "fips_county")
    density <- ifelse(
      !is.na(by_county$population) & by_county$population > 0,
      by_county$n_providers / by_county$population * per,
      NA_real_
    )
    # Base name tracks `per` (100000 -> "per_100k"); label self-documents the
    # denominator supplied via `pop_col` (e.g. "_women").
    base <- if (per == 100000) "providers_per_100k" else sprintf("providers_per_%g", per)
    dens_col <- if (is.null(denominator_label)) {
      base
    } else {
      suffix <- tolower(gsub("[^A-Za-z0-9]+", "_", denominator_label))
      suffix <- gsub("^_|_$", "", suffix)
      paste0(base, "_", suffix)
    }
    by_county[[dens_col]] <- density
  }

  by_specialty <- NULL
  if (!is.null(taxonomy_col)) {
    by_specialty <- dplyr::summarise(
      dplyr::group_by(df, .data$.fips, .data[[taxonomy_col]]),
      n_providers = dplyr::n_distinct(.data[[npi_col]]),
      .groups = "drop"
    )
    by_specialty <- dplyr::rename(by_specialty, fips_county = ".fips")
  }

  structure(
    list(
      by_county    = by_county,
      by_specialty = by_specialty,
      n_counties   = nrow(by_county)
    ),
    class = "mysterycall_provider_counts"
  )
}

#' Summarize county Medicare/Medicaid enrollment and derive access ratio
#'
#' Collapses a CMS enrollment extract to one row per county with total Medicare
#' and Medicaid enrollment, then derives the **Medicaid-to-Medicare ratio** and
#' an ordered access category. The ratio is a compact marker of how welcoming a
#' local market is to Medicaid patients relative to Medicare: low ratios flag
#' counties where Medicaid beneficiaries are comparatively under-served. The
#' category thresholds match the `isochrones` study's convention.
#'
#' This is the multi-county aggregator/covariate builder; to pull the raw
#' single-county CMS monthly counts it consumes, see
#' [mysterycall_get_cms_enrollment()]. Enrollment counts are CMS **beneficiary**
#' enrollment (people), distinct from ACS coverage estimates
#' ([mysterycall_get_payer_mix()]) and from provider counts
#' ([mysterycall_get_county_provider_counts()]).
#'
#' @param data A data frame with county FIPS and enrollment columns (one or more
#'   rows per county; rows are summed within county).
#' @param county_col Character. County FIPS column. Default `"fips_county"`.
#' @param medicare_col Character. Medicare enrollment column. Default
#'   `"medicare_enrollment"`.
#' @param medicaid_col Character. Medicaid enrollment column. Default
#'   `"medicaid_enrollment"`.
#' @param dual_col Character or `NULL`. Optional dual-eligible enrollment column,
#'   summed and returned when supplied. Default `NULL`.
#'
#' @return A tibble with one row per county:
#' \describe{
#'   \item{`fips_county`}{Zero-padded 5-digit county FIPS.}
#'   \item{`medicare_enrollment`, `medicaid_enrollment`}{Summed enrollment.}
#'   \item{`dual_enrollment`}{Summed dual-eligible enrollment (only when
#'     `dual_col` supplied).}
#'   \item{`medicaid_to_medicare_ratio`}{`medicaid / medicare` (`NA` when
#'     Medicare enrollment is zero).}
#'   \item{`medicaid_access_category`}{Ordered factor: `"Low (<0.50)"`,
#'     `"Medium (0.50-0.74)"`, `"High (0.75-0.99)"`, `"Very High (>=1.00)"`.}
#' }
#'   Rows with a missing county FIPS emit a warning and are dropped.
#'
#' @family census
#' @export
#' @examples
#' cms <- data.frame(
#'   fips_county         = c("08031", "48201", "48201"),
#'   medicare_enrollment = c(90000, 400000, 10000),
#'   medicaid_enrollment = c(70000, 600000, 20000),
#'   stringsAsFactors    = FALSE
#' )
#' mysterycall_summarize_county_enrollment(cms)
mysterycall_summarize_county_enrollment <- function(data,
                                              county_col   = "fips_county",
                                              medicare_col = "medicare_enrollment",
                                              medicaid_col = "medicaid_enrollment",
                                              dual_col     = NULL) {
  if (!is.data.frame(data)) {
    stop(sprintf("`data` must be a data frame, not %s.", class(data)[1L]),
         call. = FALSE)
  }
  need <- c(county_col, medicare_col, medicaid_col, dual_col)
  for (col in need) {
    if (!col %in% names(data)) {
      stop(sprintf("Column '%s' not found in `data`.\nAvailable: %s",
                   col, paste(names(data), collapse = ", ")), call. = FALSE)
    }
  }

  fips <- .normalize_county_fips(data[[county_col]])
  n_missing <- sum(is.na(fips))
  if (n_missing) {
    warning(sprintf("%d row(s) had a missing/blank county FIPS and were dropped.",
                    n_missing), call. = FALSE)
  }

  df <- tibble::tibble(
    fips_county = fips,
    .medicare   = suppressWarnings(as.numeric(data[[medicare_col]])),
    .medicaid   = suppressWarnings(as.numeric(data[[medicaid_col]]))
  )
  if (!is.null(dual_col)) {
    df$.dual <- suppressWarnings(as.numeric(data[[dual_col]]))
  }
  df <- df[!is.na(df$fips_county), , drop = FALSE]

  agg <- dplyr::summarise(
    dplyr::group_by(df, .data$fips_county),
    medicare_enrollment = sum(.data$.medicare, na.rm = TRUE),
    medicaid_enrollment = sum(.data$.medicaid, na.rm = TRUE),
    dual_enrollment     = if (!is.null(dual_col)) sum(.data$.dual, na.rm = TRUE) else NA_real_,
    .groups = "drop"
  )
  if (is.null(dual_col)) {
    agg$dual_enrollment <- NULL
  }

  agg$medicaid_to_medicare_ratio <- ifelse(
    agg$medicare_enrollment > 0,
    agg$medicaid_enrollment / agg$medicare_enrollment,
    NA_real_
  )
  agg$medicaid_access_category <- .medicaid_access_category(agg$medicaid_to_medicare_ratio)

  agg
}

# Ordered access category from a Medicaid:Medicare ratio (isochrones thresholds).
.medicaid_access_category <- function(ratio) {
  lvls <- c("Low (<0.50)", "Medium (0.50-0.74)", "High (0.75-0.99)", "Very High (>=1.00)")
  cat_chr <- ifelse(
    is.na(ratio), NA_character_,
    ifelse(ratio < 0.50, lvls[1],
           ifelse(ratio < 0.75, lvls[2],
                  ifelse(ratio < 1.00, lvls[3], lvls[4])))
  )
  factor(cat_chr, levels = lvls, ordered = TRUE)
}

#' Print method for mysterycall_provider_counts
#' @param x A `mysterycall_provider_counts` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family census
#' @export
print.mysterycall_provider_counts <- function(x, ...) {
  cat("=== County Provider Counts ===\n")
  cat(sprintf("Counties: %d | Total distinct providers: %s\n",
              x$n_counties, format(sum(x$by_county$n_providers), big.mark = ",")))
  dens_col <- grep("^providers_per_", names(x$by_county), value = TRUE)
  if (length(dens_col)) {
    cat(sprintf("Median density: %.1f (%s)\n",
                stats::median(x$by_county[[dens_col[1]]], na.rm = TRUE),
                dens_col[1]))
  }
  if (!is.null(x$by_specialty)) {
    cat(sprintf("Specialty breakdown available (%d county-specialty rows).\n",
                nrow(x$by_specialty)))
  }
  print(utils::head(x$by_county, 10), row.names = FALSE)
  invisible(x)
}
