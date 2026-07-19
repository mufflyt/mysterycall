# Search and Process NPI Numbers

## Overview

[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)
is the name-based entry point for roster creation. Use it when you
already have clinician first and last names from a patient directory,
credentialing list, or manually curated study roster and need to recover
likely NPI matches.

The current exported interface expects a data frame passed through the
`data` argument. That data frame must contain:

- `first`
- `last`

### Minimal input

``` r
sample_names <- tibble::tibble(
  first = c("Jane", "Maria", "Alex"),
  last = c("Smith", "Garcia", "Johnson")
)

sample_names
```

### Basic search

The simplest call looks like this:

``` r
results <- mysterycall_search_and_process_npi(
  data = sample_names,
  notify = FALSE
)
```

By default the function searches for U.S. individual NPIs and filters to
common physician credentials such as `MD` and `DO`.

### Customizing the search

For most projects you will want to set a few operational parameters
explicitly, especially if the roster is large.

``` r
results <- mysterycall_search_and_process_npi(
  data = sample_names,
  enumeration_type = "ind",
  limit = 10,
  country_code = "US",
  filter_credentials = c("MD", "DO"),
  notify = FALSE
)
```

### Tracking long runs

Large name-based searches can take time. The function supports progress
logs, chunked saves, and resumable accumulation files.

``` r
results <- mysterycall_search_and_process_npi(
  data = sample_names,
  limit = 10,
  dest_dir = "npi_chunks",
  accumulate_path = "npi_results.csv",
  resume = TRUE,
  progress_log = "npi_progress.csv",
  progress_log_format = "csv",
  heartbeat_seconds = 30,
  notify = FALSE
)
```

This is useful when the roster is large enough that you want durable
progress tracking or expect to resume after an interruption.

### What comes back

The returned object is a data frame of candidate NPI matches. Key
columns:

| Column | Description |
|----|----|
| `npi` | 10-digit National Provider Identifier (character) |
| `basic_first_name` | First name from NPPES |
| `basic_last_name` | Last name from NPPES |
| `basic_middle_name` | Middle name from NPPES |
| `basic_gender` | `"M"` or `"F"` as reported to NPPES |
| `basic_credential` | Credential string (e.g. `"MD"`, `"DO"`) |
| `addresses_state` | Two-letter state abbreviation of primary practice |
| `addresses_telephone_number` | Primary phone number (unformatted) |
| `taxonomies_desc` | Self-reported specialty taxonomy description |
| `search_term` | The `"first last"` input pair that produced this match |

``` r
dplyr::glimpse(results)

results |>
  dplyr::count(search_term, sort = TRUE)
```

### Cleaning the result set

Name-based matches are often one-to-many. A common first cleanup step is
to deduplicate on `npi` and then inspect specialty or geography fields.

``` r
results_unique <- results |>
  dplyr::distinct(npi, .keep_all = TRUE)

results_unique |>
  dplyr::count(taxonomies_desc, sort = TRUE)
```

### Validating returned names and phones

After deduplication, run the data quality helpers on the raw NPPES
fields before any downstream joins:

``` r
# Parse names returned from NPPES into structured components
parsed_names <- do.call(rbind, lapply(
  paste(results_unique$basic_first_name, results_unique$basic_last_name),
  mysterycall_parse_physician_name
))

low_conf <- parsed_names[parsed_names$confidence == "low", ]
if (nrow(low_conf)) message(nrow(low_conf), " low-confidence name parses — review manually")

# Validate phone numbers against the provider's reported state
phone_checks <- do.call(rbind, Map(
  mysterycall_validate_phone,
  phone_str      = results_unique$addresses_telephone_number,
  practice_state = results_unique$addresses_state
))

table(phone_checks$validity_flag)
```

### Joining to clinician enrichment safely

Use
[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md)
when attaching CMS Care Compare data to catch NPI type mismatches and
coverage gaps:

``` r
clinician_data <- mysterycall_get_clinician_data(results_unique)

roster_enriched <- mysterycall_safe_left_join(
  left         = results_unique,
  right        = clinician_data,
  by           = "npi",
  label_left   = "npi_search_results",
  label_right  = "cms_clinician_data",
  min_coverage = 0.80
)
```

### Practical guidance

- Start with a small roster to confirm that your filters are behaving as
  expected.
- Expect ambiguous matches for common names; always inspect
  `search_term` counts.
- Save progress when running large overnight jobs.
- Deduplicate and validate phones and names before downstream joins.

## Next step

If your project begins from a specialty rather than a name list, see the
taxonomy-search vignette for
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md).
For phone validation, name parsing, and safe joins see
[`vignette("data-quality", package = "mysterycall")`](https://mufflyt.github.io/mysterycall/articles/data-quality.md).
