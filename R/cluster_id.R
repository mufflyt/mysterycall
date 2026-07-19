#' Build a random-intercept clustering key by coalescing columns
#'
#' The mixed-model fitters ([mysterycall_logistic_model()],
#' [mysterycall_nb_model()], [mysterycall_lmm()], ...) all require a
#' `random_intercept` column, but a geographic mystery-caller study rarely has a
#' single clean grouping key: a metro (CBSA) code exists for urban practices,
#' falls back to a county FIPS for the rest, and some rows have neither. Leaving
#' those rows blank or `NA` is a quiet footgun -- they collapse into one giant
#' pseudo-cluster and corrupt the estimated random-effect variance.
#'
#' This helper coalesces an ordered list of candidate columns into one grouping
#' vector: for each row it takes the first non-missing, non-empty value across
#' `cols` (in order), and gives every row that is *still* unresolved its own
#' singleton cluster (`solo_<rownum>`) so it contributes as an independent group
#' rather than being merged.
#'
#' @param data A data frame.
#' @param cols Character vector of candidate key columns, most specific first
#'   (e.g. `c("cbsa_code", "county_fips")`). Each must exist in `data`.
#' @param solo_prefix Prefix for the singleton keys given to rows that no column
#'   resolves. Default `"solo_"`. Set to `NA` to instead leave those rows `NA`
#'   (and emit a warning naming how many) if you would rather drop or inspect
#'   them.
#' @param empty_as_missing Logical; treat empty strings (and, after trimming,
#'   whitespace-only strings) as missing. Default `TRUE`.
#'
#' @return A character vector of length `nrow(data)`: the clustering key.
#'
#' @examples
#' d <- data.frame(
#'   cbsa_code   = c("16980", "", NA, "31080"),
#'   county_fips = c("17031", "17097", "", "06037")
#' )
#' mysterycall_cluster_id(d, c("cbsa_code", "county_fips"))
#' # -> c("16980", "17097", "solo_3", "31080")
#' @export
mysterycall_cluster_id <- function(data, cols, solo_prefix = "solo_",
                                   empty_as_missing = TRUE) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_character(cols, min.len = 1L, any.missing = FALSE)
  checkmate::assert_subset(cols, names(data))
  checkmate::assert_flag(empty_as_missing)

  n <- nrow(data)
  key <- rep(NA_character_, n)

  is_missing <- function(x) {
    x <- as.character(x)
    m <- is.na(x)
    if (empty_as_missing) m <- m | !nzchar(trimws(x))
    m
  }

  for (col in cols) {
    need <- is_missing(key)
    if (!any(need)) break
    cand <- as.character(data[[col]][need])
    cand[is_missing(cand)] <- NA_character_
    key[need] <- cand
  }

  unresolved <- is_missing(key)
  if (any(unresolved)) {
    if (is.na(solo_prefix)) {
      key[unresolved] <- NA_character_
      warning(sprintf(paste0("%d row(s) had no non-missing value across %s and ",
                            "were left NA (solo_prefix = NA)."),
                      sum(unresolved), paste(cols, collapse = ", ")),
              call. = FALSE)
    } else {
      checkmate::assert_string(solo_prefix)
      key[unresolved] <- paste0(solo_prefix, which(unresolved))
    }
  }
  key
}
