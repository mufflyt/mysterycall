# Healthgrades Physician Ages (current-year-adjusted)

A deduplicated national roster of physician ages assembled from
Healthgrades profile scrapes collected between 2013 and 2024,
cross-walked to National Provider Identifier (NPI) numbers via the GOBA
/ ABOG board-certification file where available. Every observed age is
projected forward to a common reference year so ages are directly
comparable regardless of when the source profile was scraped.

## Format

A data frame with roughly 88,000 rows and 12 columns:

- first_name:

  Given name, title-cased (character).

- middle_initial:

  Single-letter middle initial, or `NA` (character).

- last_name:

  Family name, title-cased (character).

- honorific:

  Physician degree: `"MD"`, `"DO"`, or `NA` (character).

- npi:

  Ten-digit National Provider Identifier as a character string, or `NA`
  when no source carried one (character).

- city:

  Practice city, title-cased, or `NA` (character).

- state:

  Two-letter USPS state abbreviation, or `NA` (character).

- age_current:

  Age adjusted to the reference year (integer). Equals
  `age_at_scrape + (reference_year - scrape_year)`.

- age_at_scrape:

  Age as reported on the source profile at the time of the scrape
  (integer).

- scrape_year:

  Year the authoritative age was observed (integer). Rows sourced from
  the GOBA merged-age column carry `2016` by convention (see Details).

- age_source:

  Provenance tag for the authoritative row, e.g. `"raw_2013"`,
  `"raw_2016"`, `"merged_all"`, `"goba_merged_hg"` (character).

- n_obs:

  Number of source observations merged into this physician (integer).

## Source

Healthgrades physician profiles (scrapes 2013-2024) joined to the GOBA /
ABOG board-certification crosswalk for NPI. Raw files are archived
offline and are not distributed with the package; see
`data-raw/healthgrades_ages.R` for the full build.

## Details

Each physician appears once. When the same person was seen in more than
one scrape, the most recent scrape supplies the authoritative age and
the other fields (NPI, middle initial, city, honorific) are coalesced
across all of that person's observations. See `n_obs` for the number of
source rows that were merged into each final row.

**Current-year adjustment.** Ages are re-based with
`age_current = age_at_scrape + (reference_year - scrape_year)`. The
reference year is set when the dataset is built (2026 for the shipped
version); regenerate via `data-raw/healthgrades_ages.R` to advance it.

**GOBA merged age.** The GOBA crosswalk supplies NPI numbers but its
`age MERGED HG` column has no per-row scrape date. Those rows are tagged
`scrape_year = 2016` (the mid-point of the Healthgrades scrape era) so
they can be re-aged, and are flagged `age_source == "goba_merged_hg"`;
filter these out if you require a strictly dated provenance.

**Deduplication.** Physicians are keyed on normalised
`(last_name, first_name, state)`. Homonyms in different states are kept
separate; a small residual of records sharing an NPI but with divergent
name spellings (for example compound given names) may remain unmerged.

**Provenance and cautions.** Data originate from a commercial physician
directory (Healthgrades) and were scraped over more than a decade; ages
are self-reported or vendor-estimated and were not validated against a
primary source. Treat as an approximate demographic reference, not an
authoritative vital record.

## See also

[`mysterycall_parse_physician_name`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md)
for the name parser used to build this table.

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md),
[`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md),
[`medicaid_fee_index`](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md),
[`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md),
[`zcta_tract_xwalk`](https://mufflyt.github.io/mysterycall/reference/zcta_tract_xwalk.md)

## Examples

``` r
data(healthgrades_ages)

# Attach an estimated current age to study physicians by NPI
# study <- merge(study, healthgrades_ages[, c("npi", "age_current")],
#                by = "npi", all.x = TRUE)

# Restrict to dated scrapes only (drop the GOBA merged-age fallback)
dated <- healthgrades_ages[healthgrades_ages$age_source != "goba_merged_hg", ]
```
