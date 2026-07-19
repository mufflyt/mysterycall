# Clean Phase 1 Results Data

This function reads the Phase 1 results data file, performs various
cleaning and transformation operations, and prepares the data for
further analysis. It ensures all required fields are present and formats
column names. Missing NPI numbers are handled by generating a unique
`random_id`.

## Usage

``` r
mysterycall_clean_phase1(
  phase1_data,
  output_directory = tempdir(),
  verbose = TRUE,
  notify = TRUE,
  duplicate_rows = TRUE,
  id_seed = NULL,
  output_format = c("csv", "parquet"),
  parent_cohort_hash = NULL
)
```

## Arguments

- phase1_data:

  A data frame containing the Phase 1 results data. Ensure that it
  includes columns like 'for_redcap', 'id', 'names', 'practice_name',
  'phone_number', 'state_name', and optionally 'npi'. If 'npi' is
  missing or any of its values are NA, a `random_id` is generated as a
  fallback. If an 'id' column exists, it will be preserved as
  'original_id'.

- output_directory:

  Directory where the cleaned Phase 1 data should be written. Defaults
  to [`tempdir()`](https://rdrr.io/r/base/tempfile.html). An audit trail
  JSON file will also be saved here.

- verbose:

  Logical. If `TRUE`, progress messages are printed while cleaning.
  Defaults to `TRUE`.

- notify:

  Logical. If `TRUE`, play a notification sound on completion when the
  optional `beepr` package is available. Defaults to `TRUE`.

- duplicate_rows:

  Logical. If `TRUE` (default), each row in `phase1_data` is duplicated
  to build the paired insurance design: the original rows are labelled
  `"Blue Cross/Blue Shield"` and the duplicated rows `"Medicaid"`. A
  `processing_flag_is_duplicate` column tracks which rows are
  duplicates. If `FALSE`, the original number of rows is kept and **no
  insurance is assigned** — the `insurance` column is set to `NA` (with
  a warning), because there is no paired design from which to derive it.
  Set `insurance` yourself from a real input column in that mode.
  (Earlier versions assigned insurance by row-number parity here, i.e.
  by alphabetical sort position, which was arbitrary.)

- id_seed:

  Optional integer seed used when generating fallback random IDs so runs
  can be reproduced without permanently mutating the global RNG state.

- output_format:

  File format to use when writing the cleaned dataset. Supported options
  are "csv" (default) and "parquet".

- parent_cohort_hash:

  Optional character scalar. The `cohort_hash` from an upstream audit
  trail (e.g. from
  [`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
  or a prior cleaning step). When supplied, it is recorded in the audit
  JSON as `parent_cohort_hash` to enable DAG lineage tracing. Must be a
  64-character lowercase hex string (SHA-256) or `NULL` (default).
  Ignored silently if not a valid hex digest.

## Value

Invisibly returns the cleaned data frame (side effect: files are written
to `output_directory`). The returned object carries these attributes:

- `audit_trail`: List containing processing metadata (timestamps, row
  counts, flags)

- `processing_timestamp`: Time when processing completed

- `function_version`: Version number of the function (2.0)

- `output_path`: Path to the saved CSV/Parquet file

- `audit_trail_path`: Path to the saved audit trail JSON file

The returned data frame includes processing flag columns:

- `processing_flag_empty_name`: TRUE if name was empty/whitespace

- `processing_flag_generated_id`: TRUE if random ID was generated (no
  NPI)

- `processing_flag_is_duplicate`: TRUE for duplicated rows (when
  duplicate_rows=TRUE)

- `processing_flag_no_last_name`: TRUE if last name could not be
  extracted

## Details

**New in Version 2.0: Data Provenance and Audit Trail**

This function now includes comprehensive data provenance tracking:

- Preserves original `id` and `npi` columns as `original_id` and
  `original_npi`

- Adds processing flags (e.g., `processing_flag_empty_name`,
  `processing_flag_generated_id`)

- Handles edge cases like whitespace-only strings safely

- Saves audit trail JSON file with processing metadata

- Attaches audit trail and quality metrics as data frame attributes

## Contract

**Inputs:**

- `phase1_data` must contain columns: `names`, `practice_name`,
  `phone_number`, `state_name`, `npi`, `for_redcap`.

- `output_directory` must be writable; function creates it if absent.

**Guarantees:**

- Output rows \\\geq\\ input rows (duplicates may be flagged but are
  never silently dropped unless `remove_duplicates = TRUE`).

- Every output row carries `processing_flag_*` columns documenting the
  reason for any modification.

- A JSON audit trail is written alongside the CSV for provenance.

**Fails if:**

- Required columns are absent from `phase1_data`.

- `output_directory` is not writable and cannot be created.

## Provenance Schema

The JSON audit trail written to
`<output_directory>/audit_trail_<timestamp>.json` always contains these
required fields (see also `tests/fixtures/audit_trail_schema.json`):

    {
      "function_name":        "mysterycall_clean_phase1",
      "input_rows":           <integer>,
      "input_cols":           <integer>,
      "input_colnames":       ["names", "practice_name", ...],
      "output_rows":          <integer>,
      "output_cols":          <integer>,
      "empty_names_count":    <integer>,
      "no_last_name_count":   <integer>,
      "rows_retained_pct":    <number>,
      "rows_duplicated":      <boolean>,
      "original_npi_preserved": <boolean>,
      "quality_metrics": {
        "completeness_npi":   <number>,
        "completeness_phone": <number>,
        "completeness_names": <number>,
        "has_processing_flags": <boolean>
      },
      "start_time":           "<ISO-8601>",
      "end_time":             "<ISO-8601>",
      "duration_seconds":     <number>,
      "r_version":            "<string>",
      "platform":             "<string>",
      "package_version":      "<string>",
      "parameters":           { ... }
    }

The `tests/fixtures/audit_trail_schema.json` file documents which fields
are required, volatile (excluded from snapshot comparisons), and
conditional. This schema is stable across patch versions and constitutes
a public API for downstream reproducibility tooling.

## Performance

O(n) in number of rows. String normalization via
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html)
and `stringr` dominates; expect \< 1 s for 1,000 rows on modern
hardware.

## Called By

- [`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)

- [`mysterycall_run_workflow_logged()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow_logged.md)

## See also

[`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md)
for Phase 2 data cleaning;
[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)
which orchestrates both phases.

Other workflow:
[`mysterycall_call_productivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_call_productivity.md),
[`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md),
[`mysterycall_print_dashboard()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_print_dashboard.md),
[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md),
[`mysterycall_run_workflow_logged()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow_logged.md),
[`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md),
[`mysterycall_verify_artifact()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_verify_artifact.md)

## Examples

``` r
if (FALSE) { # interactive()
library(mysterycall)
file_path <- "/path/to/your/input/file.xls"
phase1_data <- readxl::read_excel(file_path)  # Assuming use of readxl for Excel files
mysterycall_clean_phase1(phase1_data)
}
```
