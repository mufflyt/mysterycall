# Pipeline Guarantees

This document describes the operational guarantees provided by the
`mysterycall` workflow pipeline. Each section covers a specific class of
guarantee that callers and downstream consumers can rely on.

------------------------------------------------------------------------

## Workflow DAG

The mystery caller pipeline is a directed acyclic graph. Every major
node is a `mysterycall_*` function; arrows show data flow.

    taxonomy_terms ──► mysterycall_search_taxonomy()
                              │
    name_data ──────► mysterycall_search_and_process_npi()
                              │
                              ▼
    phase1_data ──────► mysterycall_clean_phase1()
                              │
                              ▼
                       mysterycall_validate_npi()
                              │
                              ▼
                       mysterycall_split_and_save() ──► Excel workbooks
                              │
    phase2_data ──────► mysterycall_clean_phase2()
                              │
                              ▼
                       mysterycall_save_quality_table() ──► quality CSV
                              │
                              ▼
                       mysterycall_not_contacted_states() ──► coverage summary

[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)
and
[`mysterycall_run_workflow_logged()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow_logged.md)
execute this entire graph in sequence with structured logging.

------------------------------------------------------------------------

## NPI Registry Retry State Machine

[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
implements exponential back-off when the NPI registry returns an error:

                    ┌─────────────────────┐
                    │   Request Page      │
                    └──────────┬──────────┘
                               │
                        ┌──────▼──────┐
                        │  Success?   │
                        └──────┬──────┘
                     Yes │          │ No
                         ▼          ▼
                  ┌──────────┐  ┌──────────────────┐
                  │ Append   │  │ attempt < 3?     │
                  │ results  │  └──────┬───────────┘
                  └──────────┘    Yes  │     No
                                   ▼         ▼
                            ┌──────────┐  ┌──────────┐
                            │ Backoff  │  │ Log warn │
                            │ 2^k secs │  │ return   │
                            └────┬─────┘  │ empty df │
                                 │        └──────────┘
                                 └──► Request Page

Back-off delays: attempt 1 → 1 s, attempt 2 → 2 s, attempt 3 → 4 s.
After 3 failures the function returns a zero-row data frame, never an
error.

------------------------------------------------------------------------

## Phase 1 Cleaning Pipeline

[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
applies transformations in this fixed order:

    Input data frame
          │
          ▼
    janitor::clean_names()          ← normalize column names
          │
          ▼
    type_convert()                  ← coerce column types
          │
          ▼
    Flag empty/whitespace names     ← processing_flag_empty_name
          │
          ▼
    Extract last name               ← processing_flag_no_last_name
          │
          ▼
    Generate ID if NPI absent       ← processing_flag_generated_id
          │
          ▼
    Flag duplicate rows             ← processing_flag_is_duplicate
          │
          ▼
    Write audit trail JSON
          │
          ▼
    Write output CSV
          │
          ▼
    Return annotated data frame

Each stage is idempotent when re-run on already-flagged data.

------------------------------------------------------------------------

## Reproducibility Guarantees

**Deterministic cleaning:**
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
applied to the same input with the same parameters always produces
byte-identical output. Column reordering, name normalization via
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html),
and NPI formatting are all deterministic.

**Snapshot-based replay:**
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
writes an `.rds` snapshot of every NPI registry response when
`write_snapshot = TRUE`. Re-running the pipeline with snapshot files
present does not require live API access.

**Seeded workload splits:**
[`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md)
accepts a `seed` argument (default `1978`) so the same call list is
always divided identically among lab assistants when the seed is held
constant.

------------------------------------------------------------------------

## Audit Trail Guarantees

**Per-run JSON provenance:** Every call to
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
writes a JSON audit trail to
`<output_directory>/audit_trail_<timestamp>.json`. The full schema is
documented in `tests/fixtures/audit_trail_schema.json`; required fields:

``` json
{
  "function_name":          "mysterycall_clean_phase1",
  "input_rows":             500,
  "input_cols":             6,
  "input_colnames":         ["names","practice_name","phone_number","state_name","npi","for_redcap"],
  "output_rows":            500,
  "output_cols":            19,
  "empty_names_count":      3,
  "no_last_name_count":     1,
  "rows_retained_pct":      100,
  "rows_duplicated":        false,
  "original_npi_preserved": true,
  "quality_metrics": {
    "completeness_npi":     0.94,
    "completeness_phone":   1.0,
    "completeness_names":   0.99,
    "has_processing_flags": true
  },
  "start_time":             "2026-05-09T12:00:00",
  "end_time":               "2026-05-09T12:00:02",
  "duration_seconds":       2.1
}
```

Required fields are always present. Volatile fields (`start_time`,
`end_time`, `duration_seconds`, `r_version`, `platform`,
`package_version`, `parameters`) are present but excluded from snapshot
regression comparisons.

**Audit schema migration policy:** `schema_version` follows semantic
versioning (`MAJOR.MINOR.PATCH`). Downstream tooling must pin to a MAJOR
version. The rules:

| Change type                                  | Version bump |
|----------------------------------------------|--------------|
| Fix a `_comment` or documentation string     | PATCH        |
| Add a new volatile or conditional field      | PATCH        |
| Add a new required field with a safe default | MINOR        |
| Rename or remove a required field            | **MAJOR**    |
| Change a field’s type                        | **MAJOR**    |
| Change the `cohort_hash` algorithm           | **MAJOR**    |

The full history is in `tests/fixtures/audit_trail_schema.json` under
`migration_policy.history`.

**Workflow summary:**
[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)
always returns a `workflow_summary` data frame recording row counts and
retention rates at every pipeline stage, even when upstream steps
encounter errors.

------------------------------------------------------------------------

## Data Integrity Guarantees

**No silent row loss:**
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
never silently drops rows. Rows flagged for issues (empty name,
duplicate, etc.) are marked with `processing_flag_*` columns and
retained in the output unless `remove_duplicates = TRUE` is explicitly
set.

**NPI integrity:**
[`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md)
removes only rows whose NPI is `NA`, non-10-digit, or fails the Luhn
checksum. It never adds rows. Output NPI column is always character
type.

**Zero-row safety:**
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
returns a zero-row data frame (never `NULL`) when no registry records
match the taxonomy description or when the network is unavailable after
retries.

**Workload completeness:**
[`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md)
assigns every input row to exactly one assistant’s workbook via
round-robin; no row is omitted or duplicated across workbooks.

------------------------------------------------------------------------

## Failure and Recovery Guarantees

**NPI registry retries:**
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
retries failed HTTP requests up to 3 times with exponential back-off (1
s, 2 s, 4 s). If all retries fail, the function logs a warning and
returns an empty data frame; it does not throw an error.

**Missing package handling:** All optional dependencies (mapping, Excel
I/O, progress bars, etc.) are guarded with
[`requireNamespace(..., quietly = TRUE)`](https://rdrr.io/r/base/ns-load.html).
Functions degrade gracefully: map functions skip rendering; progress
bars fall back to [`message()`](https://rdrr.io/r/base/message.html)
output; Excel export falls back to CSV.

**Workflow isolation:**
[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)
wraps each pipeline stage in `tryCatch`. A failure in Phase 2 cleaning
does not prevent the Phase 1 output from being written and returned.

------------------------------------------------------------------------

## Spatial Contract Guarantees

**CRS consistency:** All spatial outputs from
[`mysterycall_geocode()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode.md),
[`mysterycall_create_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_isochrones.md),
and
[`mysterycall_calculate_overlap()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_calculate_overlap.md)
use EPSG:4326 (WGS 84) unless explicitly transformed by the caller.

**Bounding-box validity:** Latitude values are constrained to \[18°,
72°\] and longitude values to \[−180°, −65°\] for US providers. Rows
outside these bounds in
[`mysterycall::physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md)
are NA (geocode failures) and are flagged accordingly.

------------------------------------------------------------------------

## API Contract Guarantees

**NPI registry pagination:**
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
paginates in 200-record pages up to `max_records` (default 1,200). The
returned data frame is deduplicated on NPI to prevent double-counting
providers that appear in multiple pages.

**Geocoding idempotency:**
[`mysterycall_geocode()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode.md)
returns cached coordinates for addresses already geocoded in the current
session, preventing redundant API charges.

------------------------------------------------------------------------

## Glossary

See `system.file("glossary.md", package = "mysterycall")` for
definitions of all domain-specific terms used throughout this package.
