# Internal: perform all cleaning steps common to both exported functions

Called by both
[`mysterycall_clean_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data.md)
and
[`mysterycall_clean_data_keep_identifiers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data_keep_identifiers.md).

## Usage

``` r
.mc_clean_core(
  data,
  id_col,
  age_col,
  age_breaks,
  age_labels,
  wait_col,
  insurance_col,
  gender_col,
  credential_col,
  academic_col,
  rurality_col,
  central_col,
  transfers_col,
  recode_credential,
  recode_academic,
  recode_rurality,
  recode_central,
  drop_pii,
  fill_cols,
  keep_all
)
```

## Arguments

- data:

  A data frame of raw mystery-caller records (e.g. a REDCap export).
  Must be a `data.frame` or subclass thereof.

- id_col:

  Character scalar. Column used to identify unique physicians for
  deduplication (first occurrence kept). Set to `NULL` to skip
  deduplication. Default `"phone"`.

- age_col:

  Character scalar or `NULL`. Name of the numeric age column. When
  `NULL`, age processing is skipped entirely. Default `"age"`.

- age_breaks:

  Numeric vector of cut points passed to
  [`base::cut()`](https://rdrr.io/r/base/cut.html). Default
  `c(-Inf, 50, 60, 70, Inf)`.

- age_labels:

  Character vector of category labels, length `length(age_breaks) - 1`.
  Default `c("<50 yrs", "50-59 yrs", "60-69 yrs", ">=70 yrs")`.

- wait_col:

  Character scalar or `NULL`. Wait-time column (business days). Renamed
  to `"Business days until appointment"` in output. Default
  `"business_days_until_appointment"`.

- insurance_col:

  Character scalar or `NULL`. Default `"insurance"`. Renamed to
  `"Insurance"` in output.

- gender_col:

  Character scalar or `NULL`. Default `"gender"`. Renamed to `"Gender"`
  in output.

- credential_col:

  Character scalar or `NULL`. Column holding raw NPPES credential
  strings (`"MD"`, `"DO"`, etc.). Default `"Provider.Credential.Text"`.
  Renamed to `"Physician credential"` in output.

- academic_col:

  Character scalar or `NULL`. Default `"academic_affiliation"`. Renamed
  to `"Academic affiliation"` in output.

- rurality_col:

  Character scalar or `NULL`. CBSA type column. Default `"cbsatype10"`.
  Renamed to `"Rurality"` in output.

- central_col:

  Character scalar or `NULL`. Central-scheduling indicator column.
  Default `"central_number_e_g_appointment_center"`. Renamed to
  `"Central scheduling"` in output.

- transfers_col:

  Character scalar or `NULL`. Number-of-transfers column. No recode is
  applied; the column is kept as-is. Default `NULL` (skip).

- recode_credential:

  Named character vector mapping raw credential values to display
  labels. Default
  `c("MD" = "Allopathic training", "DO" = "Osteopathic training")`.

- recode_academic:

  Named character vector mapping raw academic-affiliation values.
  Default `c("University" = "Academic Practice")`.

- recode_rurality:

  Named character vector mapping raw CBSA-type values. Default
  `c("Metro" = "Metropolitan area", "Micro" = "Rural area")`.

- recode_central:

  Named character vector mapping raw central-scheduling values. Default
  `c("Yes" = "Yes, central scheduling")`.

- drop_pii:

  Logical. When `TRUE` (default), columns named `first`, `last`,
  `middle`, `phone`, `address`, `notes`, `record_id`, `npi`, and `zip`
  (case-insensitive) are removed from the output.

- fill_cols:

  Character vector of column names to forward-fill
  (last-observation-carried-forward) before any recoding or renaming.
  Uses [`tidyr::fill()`](https://rdrr.io/pkg/tidyr/man/fill.html) when
  the package is installed, then
  [`zoo::na.locf()`](https://rdrr.io/pkg/zoo/man/na.locf.html), then a
  pure-base-R loop. Columns absent from `data` are silently ignored.
  Default `c("academic_affiliation", "cbsatype10")`.

- keep_all:

  Logical. When `TRUE`, the full column set (minus PII) is returned.
  When `FALSE`, only the set of standardized columns defined by the
  `*_col` parameters is returned.

## Value

A cleaned data frame.
