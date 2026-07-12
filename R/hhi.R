#' Market concentration (HHI) covariates from KFF data
#'
#' @description
#' Adds a hospital/insurer **market-concentration** covariate to mystery-caller
#' office data, using the Kaiser Family Foundation (KFF) published per-MSA
#' Herfindahl-Hirschman Index (HHI). Market consolidation is a plausible
#' confounder of insurance-based access: in a highly concentrated market a
#' dominant system has more latitude to steer scheduling by payer.
#'
#' The HHI ranges 0-10000 (sum of squared percent market shares). The
#' Department of Justice / Federal Trade Commission Horizontal Merger Guidelines
#' classify markets as un-concentrated (< 1000), moderately concentrated
#' (1000-1800), and highly concentrated (> 1800); those cut-points define
#' `hhi_cat`. Modelling typically uses `hhi_k = hhi / 1000` so a one-unit
#' coefficient is "per 1000 HHI points," matching the `consolidation` study
#' (`R/10_kff_exposure_sensitivity.R`).
#'
#' @name hhi
NULL

# Market-name key: "first-principal-city|STATE", stable across CBSA name
# vintages. Ported from consolidation R/10 key_of().
.hhi_market_key <- function(nm) {
  nm <- stringr::str_squish(nm)
  city <- stringr::str_trim(
    stringr::str_split_fixed(stringr::str_split_fixed(nm, ",", 2)[, 1], "-", 2)[, 1])
  st <- stringr::str_trim(
    stringr::str_split_fixed(
      stringr::str_trim(stringr::str_split_fixed(nm, ",", 2)[, 2]), "-", 2)[, 1])
  paste0(tolower(city), "|", toupper(st))
}

#' Read the KFF per-MSA HHI dataset and crosswalk it to CBSA
#'
#' Loads KFF's published metropolitan-area HHI table and attaches a Core-Based
#' Statistical Area (CBSA) GEOID so the values can be joined onto office data by
#' market. MSA names are matched to CBSAs on a `first-city|STATE` key that is
#' robust to CBSA-name vintage differences.
#'
#' @param path Path to the KFF HHI spreadsheet (`.xlsx`).
#' @param sheet Worksheet name or index. Default `"appendix"`.
#' @param msa_col Character. Column holding the MSA name. Default `"MSA"`.
#' @param hhi_col Character. Column holding the HHI value. Default
#'   `"HHI in 2024"`.
#' @param crosswalk Optional data frame with columns `cbsa` (GEOID) and either
#'   `msa` (name, matched on the city|state key) or a pre-built `key`. Supply
#'   this to avoid the `tigris` dependency. When `NULL` (default), CBSA GEOIDs
#'   are pulled from [tigris::core_based_statistical_areas()] (year `year`).
#' @param year Integer CBSA vintage used when `crosswalk` is `NULL`. Default
#'   `2021`.
#'
#' @return A tibble with columns `cbsa` (GEOID), `msa` (KFF name), and `hhi`
#'   (numeric HHI). One row per matched CBSA.
#'
#' @seealso [mysterycall_add_hhi()] to join the result onto office data.
#' @family census
#' @export
#' @examplesIf interactive()
#' kff <- mysterycall_read_kff_hhi("KFF HHI Dataset.xlsx")
#' head(kff)
mysterycall_read_kff_hhi <- function(path,
                                     sheet     = "appendix",
                                     msa_col   = "MSA",
                                     hhi_col   = "HHI in 2024",
                                     crosswalk = NULL,
                                     year      = 2021) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Package 'readxl' is required to read the KFF spreadsheet.", call. = FALSE)
  }
  if (!file.exists(path)) {
    stop(sprintf("KFF HHI file not found: %s", path), call. = FALSE)
  }

  raw <- readxl::read_excel(path, sheet = sheet)
  for (col in c(msa_col, hhi_col)) {
    if (!col %in% names(raw)) {
      stop(sprintf("Column '%s' not found in KFF sheet '%s'.\nAvailable: %s",
                   col, sheet, paste(names(raw), collapse = ", ")), call. = FALSE)
    }
  }

  kff <- tibble::tibble(
    msa = as.character(raw[[msa_col]]),
    hhi = suppressWarnings(as.numeric(raw[[hhi_col]]))
  )
  kff$key <- .hhi_market_key(kff$msa)

  # CBSA crosswalk: user-supplied, or tigris.
  if (is.null(crosswalk)) {
    if (!requireNamespace("tigris", quietly = TRUE) ||
        !requireNamespace("sf", quietly = TRUE)) {
      stop("Packages 'tigris' and 'sf' are required to derive CBSA GEOIDs. ",
           "Install them, or pass a `crosswalk` data frame with `cbsa` and `msa`/`key`.",
           call. = FALSE)
    }
    cb <- sf::st_drop_geometry(
      tigris::core_based_statistical_areas(cb = TRUE, year = year))
    cb <- cb[cb$LSAD == "M1", , drop = FALSE]           # Metropolitan Statistical Areas
    xwalk <- tibble::tibble(cbsa = cb$GEOID, key = .hhi_market_key(cb$NAME))
  } else {
    if (!is.data.frame(crosswalk) || !"cbsa" %in% names(crosswalk)) {
      stop("`crosswalk` must be a data frame with a `cbsa` column.", call. = FALSE)
    }
    xwalk <- tibble::tibble(cbsa = as.character(crosswalk$cbsa))
    xwalk$key <- if ("key" %in% names(crosswalk)) {
      as.character(crosswalk$key)
    } else if ("msa" %in% names(crosswalk)) {
      .hhi_market_key(as.character(crosswalk$msa))
    } else {
      stop("`crosswalk` must contain a `key` or `msa` column.", call. = FALSE)
    }
  }

  merged <- dplyr::inner_join(kff, xwalk, by = "key",
                              relationship = "many-to-many")
  merged <- dplyr::distinct(merged, .data$cbsa, .keep_all = TRUE)
  dplyr::select(merged, "cbsa", "msa", "hhi")
}

#' Join a market HHI covariate onto office data
#'
#' Left-joins market HHI values onto caller/office data by a market key (CBSA)
#' and derives modelling-ready companions: `hhi_k` (HHI / `scale`) and `hhi_cat`
#' (DOJ/FTC concentration category).
#'
#' @param data A data frame with one row per call/office and a market-key column.
#' @param hhi_table A data frame of market HHI values, e.g. from
#'   [mysterycall_read_kff_hhi()].
#' @param market_col Character. Market-key column in `data`. Default `"cbsa"`.
#' @param table_market_col Character. Market-key column in `hhi_table`. Default
#'   `"cbsa"`.
#' @param hhi_col Character. HHI value column in `hhi_table`. Default `"hhi"`.
#' @param scale Numeric divisor for `hhi_k`. Default `1000` (coefficient reads
#'   "per 1000 HHI points").
#' @param prefix Character prepended to added column names. Default `""`.
#'
#' @return `data` with added columns (optionally prefixed): `hhi` (numeric),
#'   `hhi_k` (`hhi / scale`), and `hhi_cat` (ordered factor
#'   `"un-concentrated"` < `"moderate"` < `"high"`). Offices whose market is not
#'   in `hhi_table` receive `NA` and trigger a warning listing how many.
#'
#' @seealso [mysterycall_read_kff_hhi()] for building `hhi_table`.
#' @family census
#' @export
#' @examples
#' offices <- data.frame(office = c("A", "B", "C"),
#'                       cbsa   = c("19740", "12060", "99999"),
#'                       stringsAsFactors = FALSE)
#' hhi_tbl <- data.frame(cbsa = c("19740", "12060"),
#'                       hhi  = c(1450, 2600))
#' suppressWarnings(mysterycall_add_hhi(offices, hhi_tbl))
mysterycall_add_hhi <- function(data,
                                hhi_table,
                                market_col       = "cbsa",
                                table_market_col = "cbsa",
                                hhi_col          = "hhi",
                                scale            = 1000,
                                prefix           = "") {
  if (!is.data.frame(data)) {
    stop(sprintf("`data` must be a data frame, not %s.", class(data)[1L]), call. = FALSE)
  }
  if (!is.data.frame(hhi_table)) {
    stop("`hhi_table` must be a data frame.", call. = FALSE)
  }
  if (!market_col %in% names(data)) {
    stop(sprintf("`market_col` '%s' not found in `data`.", market_col), call. = FALSE)
  }
  for (col in c(table_market_col, hhi_col)) {
    if (!col %in% names(hhi_table)) {
      stop(sprintf("Column '%s' not found in `hhi_table`.", col), call. = FALSE)
    }
  }
  if (!is.numeric(scale) || length(scale) != 1L || scale <= 0) {
    stop("`scale` must be a single positive number.", call. = FALSE)
  }

  key <- as.character(data[[market_col]])
  lut <- stats::setNames(
    suppressWarnings(as.numeric(hhi_table[[hhi_col]])),
    as.character(hhi_table[[table_market_col]])
  )
  lut <- lut[!duplicated(names(lut))]
  hhi <- unname(lut[key])

  n_unmatched <- sum(is.na(hhi) & !is.na(key) & nzchar(key))
  if (n_unmatched) {
    warning(sprintf("%d office row(s) had a market not present in `hhi_table` (HHI set to NA).",
                    n_unmatched), call. = FALSE)
  }

  hhi_cat <- cut(hhi, c(-Inf, 1000, 1800, Inf),
                 labels = c("un-concentrated", "moderate", "high"),
                 ordered_result = TRUE)

  out <- data
  nm <- function(base) paste0(prefix, base)
  out[[nm("hhi")]]     <- hhi
  out[[nm("hhi_k")]]   <- hhi / scale
  out[[nm("hhi_cat")]] <- hhi_cat
  out
}

#' Deprecated alias for mysterycall_add_hhi
#' @param ... Arguments passed to [mysterycall_add_hhi()].
#' @return See [mysterycall_add_hhi()].
#' @keywords internal
#' @name add_hhi
add_hhi <- function(...) {
  .Deprecated("mysterycall_add_hhi")
  mysterycall_add_hhi(...)
}
