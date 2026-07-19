# Export a caller list in Google Sheets import format

Writes a mystery-caller list to a CSV shaped for import into Google
Sheets: a study-title row (cell A1), a
`name / phone / NPI / <stage_col>` header, then one row per clinician
with the stage-tracking column left blank for callers. Rows are ordered
by state with each matched pair kept adjacent (the `group_last` arm
placed second within a pair).

## Usage

``` r
mysterycall_export_gsheet_caller_list(
  src,
  out,
  study_title = "Mystery Caller Study",
  stage_col = "Stage 1 Calling",
  name_col = "Provider Name",
  phone_col = "Phone",
  npi_col = "NPI",
  state_col = "State",
  pair_col = "Matched Pair ID",
  group_col = "PE_or_Not",
  group_last = "PE",
  backup = NULL,
  verbose = TRUE
)
```

## Arguments

- src:

  Path to the calling sheet CSV (one row per clinician). Must contain
  `name_col`, `phone_col`, `npi_col`, `state_col`, `pair_col`, and
  `group_col`.

- out:

  Path to write the Google Sheets-formatted CSV.

- study_title:

  Character string placed in the first row (cell A1).

- stage_col:

  Name of the blank tracking column callers fill, e.g.
  `"Stage 1 Calling"`.

- name_col, phone_col, npi_col:

  Input columns copied to the output, in this order. Their names are
  reused verbatim as the output header.

- state_col, pair_col:

  Columns used for ordering. `pair_col` is coerced to numeric so pairs
  sort naturally; each matched pair stays adjacent.

- group_col, group_last:

  Within a pair, the row whose `group_col` equals `group_last` is placed
  second (e.g. put `"PE"` after `"Non-PE"`).

- backup:

  Optional path for a one-time backup of an existing `out` file. The
  backup is written only if it does not already exist, preserving the
  original. `NULL` (default) skips backup.

- verbose:

  Emit progress messages.

## Value

(Invisibly) the ordered data frame that was written.

## Details

The file is written with CRLF line endings and minimal quoting so it
round-trips cleanly through spreadsheet tools.

## Examples

``` r
if (FALSE) { # \dontrun{
mysterycall_export_gsheet_caller_list(
  src = "calling_sheet.csv",
  out = "caller_list_for_google_sheets.csv",
  study_title = "Mystery Caller Study")
} # }
```
