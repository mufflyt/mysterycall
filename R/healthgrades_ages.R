#' Healthgrades Physician Ages (current-year-adjusted)
#'
#' A deduplicated national roster of physician ages assembled from Healthgrades
#' profile scrapes collected between 2013 and 2024, cross-walked to National
#' Provider Identifier (NPI) numbers via the GOBA / ABOG board-certification
#' file where available. Every observed age is projected forward to a common
#' reference year so ages are directly comparable regardless of when the source
#' profile was scraped.
#'
#' Each physician appears once. When the same person was seen in more than one
#' scrape, the most recent scrape supplies the authoritative age and the other
#' fields (NPI, middle initial, city, honorific) are coalesced across all of
#' that person's observations. See \code{n_obs} for the number of source rows
#' that were merged into each final row.
#'
#' @format A data frame with roughly 88,000 rows and 12 columns:
#' \describe{
#'   \item{first_name}{Given name, title-cased (character).}
#'   \item{middle_initial}{Single-letter middle initial, or \code{NA}
#'     (character).}
#'   \item{last_name}{Family name, title-cased (character).}
#'   \item{honorific}{Physician degree: \code{"MD"}, \code{"DO"}, or \code{NA}
#'     (character).}
#'   \item{npi}{Ten-digit National Provider Identifier as a character string,
#'     or \code{NA} when no source carried one (character).}
#'   \item{city}{Practice city, title-cased, or \code{NA} (character).}
#'   \item{state}{Two-letter USPS state abbreviation, or \code{NA} (character).}
#'   \item{age_current}{Age adjusted to the reference year (integer). Equals
#'     \code{age_at_scrape + (reference_year - scrape_year)}.}
#'   \item{age_at_scrape}{Age as reported on the source profile at the time of
#'     the scrape (integer).}
#'   \item{scrape_year}{Year the authoritative age was observed (integer). Rows
#'     sourced from the GOBA merged-age column carry \code{2016} by convention
#'     (see Details).}
#'   \item{age_source}{Provenance tag for the authoritative row, e.g.
#'     \code{"raw_2013"}, \code{"raw_2016"}, \code{"merged_all"},
#'     \code{"goba_merged_hg"} (character).}
#'   \item{n_obs}{Number of source observations merged into this physician
#'     (integer).}
#' }
#'
#' @details
#' **Current-year adjustment.** Ages are re-based with
#' \code{age_current = age_at_scrape + (reference_year - scrape_year)}. The
#' reference year is set when the dataset is built (2026 for the shipped
#' version); regenerate via \code{data-raw/healthgrades_ages.R} to advance it.
#'
#' **GOBA merged age.** The GOBA crosswalk supplies NPI numbers but its
#' \code{age MERGED HG} column has no per-row scrape date. Those rows are tagged
#' \code{scrape_year = 2016} (the mid-point of the Healthgrades scrape era) so
#' they can be re-aged, and are flagged \code{age_source == "goba_merged_hg"};
#' filter these out if you require a strictly dated provenance.
#'
#' **Deduplication.** Physicians are keyed on normalised
#' \code{(last_name, first_name, state)}. Homonyms in different states are kept
#' separate; a small residual of records sharing an NPI but with divergent name
#' spellings (for example compound given names) may remain unmerged.
#'
#' **Provenance and cautions.** Data originate from a commercial physician
#' directory (Healthgrades) and were scraped over more than a decade; ages are
#' self-reported or vendor-estimated and were not validated against a primary
#' source. Treat as an approximate demographic reference, not an authoritative
#' vital record.
#'
#' @source Healthgrades physician profiles (scrapes 2013-2024) joined to the
#'   GOBA / ABOG board-certification crosswalk for NPI. Raw files are archived
#'   offline and are not distributed with the package; see
#'   \code{data-raw/healthgrades_ages.R} for the full build.
#'
#' @examples
#' data(healthgrades_ages)
#'
#' # Attach an estimated current age to study physicians by NPI
#' # study <- merge(study, healthgrades_ages[, c("npi", "age_current")],
#' #                by = "npi", all.x = TRUE)
#'
#' # Restrict to dated scrapes only (drop the GOBA merged-age fallback)
#' dated <- healthgrades_ages[healthgrades_ages$age_source != "goba_merged_hg", ]
#'
#' @seealso \code{\link{mysterycall_parse_physician_name}} for the name parser
#'   used to build this table.
#' @keywords dataset
#' @family datasets
#' @name healthgrades_ages
#' @docType data
NULL
