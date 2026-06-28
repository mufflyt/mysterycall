#' Three-tier specialty reconciliation with audit columns
#'
#' @name mysterycall_reconcile_specialty
NULL

#' Reconcile specialty labels across primary and secondary sources
#'
#' Applies a three-tier decision rule:
#' \enumerate{
#'   \item **Tier 1 (high)**: primary column is non-missing and non-default -
#'     use it as-is.
#'   \item **Tier 2 (medium)**: primary is missing or the default label, but
#'     the secondary column is informative - adopt the secondary value.
#'   \item **Tier 3 (low)**: both sources are uninformative - set specialty to
#'     `default`.
#' }
#' Two audit columns are appended: one recording which source was used and one
#' recording the confidence tier.
#'
#' @section Subspecialty source rule:
#'   **Subspecialty values must only come from board certification data.**
#'   NPPES (`taxonomies_desc`) and DAC (Data at CMS) report broad specialty
#'   taxonomy codes that do not reliably distinguish subspecialties such as
#'   Neurotology or Pediatric Otolaryngology. Always supply board certification
#'   data (e.g. ABOHNS) in `secondary_col` when subspecialty resolution is
#'   needed. Passing an NPPES or DAC column as `secondary_col` for subspecialty
#'   will produce incorrect Tier-2 assignments that appear valid but are not.
#'   Use [mysterycall_parse_certification_subspecialty()] to derive a
#'   subspecialty column from the ABOHNS `certification_type` field before
#'   calling this function.
#'
#' @param data A data frame.
#' @param primary_col Character scalar. Column containing the broad specialty
#'   label from a registry source such as NPPES or DAC (e.g.
#'   `"Otolaryngology - Head & Neck Surgery"`). Do not use this column to
#'   carry subspecialty values; subspecialty must come via `secondary_col`
#'   from board certification data only.
#' @param secondary_col Optional character scalar. Column containing a
#'   subspecialty label derived **exclusively from board certification data**
#'   (e.g. ABOHNS `certification_type` parsed by
#'   [mysterycall_parse_certification_subspecialty()]). DAC and NPPES columns
#'   must not be passed here for subspecialty purposes.
#' @param default Character scalar. The "uninformative" label that triggers
#'   tier-2 or tier-3 logic. Default `"General"`.
#' @param source_col Character scalar. Name of the new audit column recording
#'   which source was used. Default `"specialty_source"`.
#' @param confidence_col Character scalar. Name of the new audit column
#'   recording the tier (`"high"`, `"medium"`, or `"low"`).
#'   Default `"specialty_confidence"`.
#'
#' @return The input `data` frame with the same row count, where:
#'   - `primary_col` is updated: tier-2 rows receive the `secondary_col` value.
#'   - A new character column (named by `source_col`) records which source was
#'     used (`"primary"`, `"secondary"`, or `"default"`).
#'   - A new character column (named by `confidence_col`) records the
#'     resolution tier (`"high"`, `"medium"`, or `"low"`).
#'
#' @family provider characteristics
#' @export
#'
#' @examples
#' df <- data.frame(
#'   specialty_npi   = c("Otolaryngology", "General", NA, "Rhinology"),
#'   specialty_abohns = c(NA, "Laryngology", "Rhinology", "General")
#' )
#' mysterycall_reconcile_specialty(
#'   df,
#'   primary_col   = "specialty_npi",
#'   secondary_col = "specialty_abohns"
#' )
mysterycall_reconcile_specialty <- function(data,
                                             primary_col,
                                             secondary_col   = NULL,
                                             default         = "General",
                                             source_col      = "specialty_source",
                                             confidence_col  = "specialty_confidence") {
  if (!is.data.frame(data))
    stop(sprintf("`data` must be a data frame, not %s.", class(data)[1L]), call. = FALSE)
  if (!primary_col %in% names(data))
    stop(sprintf("Column '%s' not found in `data`.\nAvailable columns: %s",
                 primary_col, paste(names(data), collapse = ", ")), call. = FALSE)

  out <- data
  out[[source_col]]     <- NA_character_
  out[[confidence_col]] <- NA_character_

  primary <- as.character(out[[primary_col]])

  # -- Tier 1: primary is informative -------------------------------------------
  t1 <- !is.na(primary) & nzchar(trimws(primary)) & primary != default
  out[[source_col]][t1]     <- primary_col
  out[[confidence_col]][t1] <- "high"

  # -- Tier 2: secondary fills the gap ------------------------------------------
  if (!is.null(secondary_col)) {
    if (!secondary_col %in% names(data)) {
      stop(sprintf("Column '%s' not found in `data`.\nAvailable columns: %s",
                   secondary_col, paste(names(data), collapse = ", ")), call. = FALSE)
    }
    secondary <- as.character(out[[secondary_col]])
    t2 <- !t1 & !is.na(secondary) & nzchar(trimws(secondary)) & secondary != default
    out[[primary_col]] <- ifelse(t2, secondary, as.character(out[[primary_col]]))
    out[[source_col]][t2]     <- secondary_col
    out[[confidence_col]][t2] <- "medium"
  }

  # -- Tier 3: fall back to default ---------------------------------------------
  t3 <- is.na(out[[source_col]])
  out[[source_col]][t3]     <- "default"
  out[[confidence_col]][t3] <- "low"
  primary_now <- as.character(out[[primary_col]])
  fill_default <- t3 & (is.na(primary_now) | !nzchar(trimws(primary_now)) | primary_now == default)
  out[[primary_col]][fill_default] <- default

  out
}
