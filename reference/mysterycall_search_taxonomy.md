# Search NPI Database by Taxonomy

This function searches the NPI Database for healthcare providers based
on a taxonomy description. The NPI API returns at most 1\\200 records
per query. To retrieve all providers for a large specialty, supply a
character vector of state abbreviations via the `states` argument; the
function will loop over each state and combine the results, effectively
bypassing the 1\\200-record cap.

## Usage

``` r
mysterycall_search_taxonomy(
  taxonomy_to_search,
  states = NULL,
  city = NULL,
  limit = 1200L,
  write_snapshot = TRUE,
  snapshot_dir = NULL,
  notify = TRUE
)
```

## Arguments

- taxonomy_to_search:

  A character vector containing the taxonomy description(s) to search
  for.

- states:

  Optional character vector of two-letter US state abbreviations (e.g.
  `c("CO", "CA", "NY")`). When supplied the search is repeated for each
  state so that all providers are captured even for large specialties
  that exceed the 1\\200-record per-query limit. Pass all 50 state
  abbreviations to perform a complete national search. Defaults to
  `NULL` (national search, capped at `limit` records).

- city:

  Optional city name passed to
  [`npi::npi_search()`](https://docs.ropensci.org/npi/reference/npi_search.html).

- limit:

  Maximum records to request per API call. Capped at 1\\200 by the NPI
  API. Defaults to `1200L`.

- write_snapshot:

  Logical. If `TRUE`, the retrieved data is saved as an `.rds` file for
  later reference. Defaults to `TRUE`.

- snapshot_dir:

  Directory where snapshot files should be written when `write_snapshot`
  is `TRUE`. Defaults to a session-specific folder inside
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) when not supplied.

- notify:

  Logical. If `TRUE`, play a notification sound when processing
  completes (requires the optional `beepr` package). Defaults to `TRUE`.

## Value

A data frame of NPPES records matching the requested taxonomy. Key
columns include `npi`, `first_name`, `last_name`, `taxonomies_desc`
(broad NPPES specialty label), and `taxonomies_primary` (logical).

## Subspecialty source warning

`taxonomies_desc` reflects the NPPES taxonomy code the provider self-
reported to the NPI registry. **Do not use this column to assign
subspecialty.** NPPES taxonomy codes cannot reliably distinguish
subspecialties (e.g. Neurotology vs. General Otolaryngology).
Subspecialty must be derived from board certification data only, using
[`mysterycall_parse_certification_subspecialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_certification_subspecialty.md)
on the ABOHNS `certification_type` field, then reconciled with
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md).

## Output columns

The function returns a curated subset of
[`npi::npi_flatten()`](https://docs.ropensci.org/npi/reference/npi_flatten.html)
output.

**Retained** (after renaming): `npi`, `first_name`, `last_name`,
`middle_name`, `credential`, `addresses_city`, `addresses_state`,
`addresses_postal_code`, `addresses_telephone_number`,
`addresses_country_name`, `taxonomies_desc`, `taxonomies_primary`,
`search_term`. Any columns returned by `npi_flatten()` that are *not* on
the explicit drop list are also retained.

**Always dropped** regardless of what the NPI API returns:

- All `endpoints_*` fields (electronic health endpoint metadata)

- All `other_names_*` fields (former or alternate name records)

- All `identifiers_*` fields (legacy identifier records)

- Supplementary address fields: `addresses_address_2`,
  `addresses_fax_number`, `addresses_address_type`,
  `addresses_country_code`

- Basic metadata: `basic_last_updated`, `basic_status`,
  `basic_name_prefix`, `basic_name_suffix`, `basic_certification_date`

- Secondary taxonomy fields: `taxonomies_code`,
  `taxonomies_taxonomy_group`, `taxonomies_state`, `taxonomies_license`

- Internal working column: `credential_lower`

To access dropped columns, call
[`npi::npi_search()`](https://docs.ropensci.org/npi/reference/npi_search.html)
and
[`npi::npi_flatten()`](https://docs.ropensci.org/npi/reference/npi_flatten.html)
directly before any filtering.

## Contract

**Inputs:**

- `taxonomy_to_search` must be an exact NUCC taxonomy description string
  (see
  [`mysterycall::taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)
  dataset for valid values).

- NPI registry API must be reachable; the function retries up to 3 times
  with exponential back-off before returning an empty data frame.

**Guarantees:**

- Returns a zero-row data frame (never `NULL`) when no records are
  found.

- Output rows are deduplicated on NPI.

- When `write_snapshot = TRUE`, an `.rds` file is written to
  `output_dir` for reproducible re-runs without re-querying the live
  API.

**Fails if:**

- Network is unavailable after all retries (returns empty data frame,
  does not error).

- `states` contains an invalid two-letter abbreviation (silently
  skipped).

## Performance

O(t \* p / 200) HTTP requests where `t` = number of state batches and
`p` = max_records (default 1,200). Each page request targets \< 200
rows. Full national search across all 50 states for one taxonomy takes
~2-5 min depending on registry load. Results are cached in-memory per
session when `use_cache = TRUE`.

## Called By

- [`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)

- [`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)
  (indirectly via taxonomy lookup)

## See also

Other npi:
[`mysterycall_enrich_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_enrich_npi.md),
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md),
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)

## Examples

``` r
if (FALSE) { # interactive()
# National search (limited to 1200 records per taxonomy):
go_data <- mysterycall_search_taxonomy("Gynecologic Oncology")

# Full national search by looping over every state:
all_states <- c(
  "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
  "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
  "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
  "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
  "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"
)
fpmrs_data <- mysterycall_search_taxonomy(
  "Female Pelvic Medicine and Reconstructive Surgery",
  states = all_states
)
}
```
