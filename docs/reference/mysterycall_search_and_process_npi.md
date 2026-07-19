# Search and Process NPI Numbers

Searches the NPI registry by provider name, filters by taxonomy and
credentials, and accumulates results across batches. Supports resume
capability for interrupted runs (via `resume = TRUE`), structured
logging to CSV or plain-text files, and optional progress callbacks for
long-running workflows. Failed searches are automatically retried (up to
3 attempts) with exponential backoff.

## Usage

``` r
mysterycall_search_and_process_npi(
  data,
  enumeration_type = "ind",
  limit = NULL,
  country_code = "US",
  filter_credentials = c("MD", "DO"),
  save_chunk_size = 10,
  dest_dir = NULL,
  file_format = NULL,
  accumulate_path = NULL,
  resume = FALSE,
  progress_log = NULL,
  notify = TRUE,
  progress_callback = NULL,
  heartbeat_seconds = NULL,
  progress_log_format = c("text", "csv")
)
```

## Arguments

- data:

  A data frame with columns `first` and `last` containing the provider
  names to search.

- enumeration_type:

  The enumeration type for NPI search (e.g., "ind", "org", "all").
  Default is "ind".

- limit:

  The maximum number of search results to request for each name pair.
  Default is 5.

- country_code:

  Filter for only the "US".

- filter_credentials:

  A character vector containing the credentials to filter the NPI
  results. Default is c("MD", "DO").

- save_chunk_size:

  The number of results to save per chunk. Default is 10.

- dest_dir:

  Destination directory to save chunked results. Default is NULL (no
  files written). Files are written using the format specified by
  `file_format`.

- file_format:

  Optional override controlling whether chunked and accumulated results
  are saved as "csv" or "parquet". When `NULL`, the format defaults to
  CSV unless `accumulate_path` ends with ".parquet".

- accumulate_path:

  Optional output path that accumulates every non-empty result. When
  provided, results are appended after each successful lookup using the
  format inferred from `file_format` or the file extension.

- resume:

  Logical. If `TRUE` and `accumulate_path` already exists, names that
  have been processed previously (based on the `search_term` column) are
  skipped.

- progress_log:

  Optional file path used to log progress updates. The log file is
  appended to and created automatically if it does not exist.

- notify:

  Logical. If `TRUE`, play a notification sound when processing
  completes (requires the optional `beepr` package). Defaults to `TRUE`.

- progress_callback:

  Optional function invoked with a named list each time progress is
  updated. The list contains fields such as `event`, `timestamp`,
  `search_term`, `rows`, `index`, and `total`.

- heartbeat_seconds:

  Optional numeric value specifying how frequently (in seconds) to emit
  a "still processing" heartbeat update while iterating over names. Set
  to `NULL` to disable the heartbeat.

- progress_log_format:

  Either "text" (default) to append human readable lines to
  `progress_log` or "csv" to write structured entries with columns
  `timestamp`, `event`, `search_term`, `rows`, and `detail`.

## Value

A data frame with 8 columns:

- `npi`:

  Character. 10-digit NPI identifier; deduplicated within results.

- `first_name`:

  Character. Provider first name from the NPI registry.

- `last_name`:

  Character. Provider last name from the NPI registry.

- `middle_name`:

  Character. Provider middle name; `NA` when absent.

- `credential`:

  Character. Degree credential string (e.g., `"MD"`, `"DO"`).

- `taxonomies_desc`:

  Character. Taxonomy classification from the NPI registry.

- `search_term`:

  Character. The `first last` name string that was looked up.

- `resume_row_index`:

  Integer. Row number from input `data`; disambiguates providers with
  identical names.

Rows are deduplicated by NPI and sorted by `last_name`, `first_name`.
When `resume = TRUE` and `accumulate_path` already exists, previously
processed names are skipped and new results are appended to that file.
Returns an empty data frame with these columns when no matches pass the
credential and taxonomy filters.

## See also

[`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md)
for downstream NPI validation;
[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)
which orchestrates this function;
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
for taxonomy-based registry searches.

Other npi:
[`mysterycall_enrich_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_enrich_npi.md),
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md),
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)

## Examples

``` r
if (FALSE) { # interactive()
df <- data.frame(first = "John", last = "Doe")
results <- mysterycall_search_and_process_npi(df)
}
```
