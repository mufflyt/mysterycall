# Clean mystery-caller data while retaining all identifier columns

A convenience wrapper around
[`mysterycall_clean_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data.md)
that sets `drop_pii = FALSE` by default and preserves every column in
the input (including `phone`, `npi`, `first`, `last`, etc.). Useful
during QC when you need to trace a cleaned record back to its source.

## Usage

``` r
mysterycall_clean_data_keep_identifiers(
  data,
  id_col = "phone",
  age_col = "age",
  age_breaks = c(-Inf, 50, 60, 70, Inf),
  age_labels = c("<50 yrs", "50-59 yrs", "60-69 yrs", ">=70 yrs"),
  wait_col = "business_days_until_appointment",
  insurance_col = "insurance",
  gender_col = "gender",
  credential_col = "Provider.Credential.Text",
  academic_col = "academic_affiliation",
  rurality_col = "cbsatype10",
  central_col = "central_number_e_g_appointment_center",
  transfers_col = NULL,
  recode_credential = c(MD = "Allopathic training", DO = "Osteopathic training"),
  recode_academic = c(University = "Academic Practice"),
  recode_rurality = c(Metro = "Metropolitan area", Micro = "Rural area"),
  recode_central = c(Yes = "Yes, central scheduling"),
  drop_pii = FALSE,
  fill_cols = c("academic_affiliation", "cbsatype10")
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

  Logical. Default `FALSE` (keep identifier columns). Set to `TRUE` to
  mimic the behaviour of
  [`mysterycall_clean_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data.md).

- fill_cols:

  Character vector of column names to forward-fill
  (last-observation-carried-forward) before any recoding or renaming.
  Uses
  [`tidyr::fill()`](https://tidyr.tidyverse.org/reference/fill.html)
  when the package is installed, then
  [`zoo::na.locf()`](https://rdrr.io/pkg/zoo/man/na.locf.html), then a
  pure-base-R loop. Columns absent from `data` are silently ignored.
  Default `c("academic_affiliation", "cbsatype10")`.

## Value

A cleaned `data.frame` identical in structure to the output of
[`mysterycall_clean_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data.md),
but with PII/identifier columns retained. The physician-identifier
column (`id_col`) is always present in the output regardless of other
settings.

## Details

All parameters are identical to
[`mysterycall_clean_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data.md);
only the default for `drop_pii` differs.

## See also

[`mysterycall_clean_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data.md)
for the PII-dropping variant.

Other data utilities:
[`mysterycall_clean_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data.md)

## Examples

``` r
raw <- data.frame(
  phone    = c("303-111-2222", "303-111-2222", "720-555-9999"),
  age      = c(55, 55, 72),
  insurance = c("Medicaid", "Medicaid", "Medicare"),
  gender   = c("Female", "Female", "Male"),
  Provider.Credential.Text = c("MD", "MD", "DO"),
  academic_affiliation     = c("University", NA, "Community"),
  cbsatype10               = c("Metro", "Metro", "Micro"),
  business_days_until_appointment = c(7L, 7L, 14L),
  central_number_e_g_appointment_center = c("Yes", "Yes", "No"),
  first  = c("Jane", "Jane", "Bob"),
  last   = c("Doe",  "Doe",  "Smith"),
  npi    = c("1234567890", "1234567890", "0987654321"),
  record_id = 1:3,
  stringsAsFactors = FALSE
)

# Identifiers are retained (phone, npi, first, last, record_id all present)
kcleaned <- mysterycall_clean_data_keep_identifiers(raw)
#> mysterycall_clean_data: 3 row(s), 13 column(s) received.
#>   Removing 1 duplicate row(s) based on 'phone'.
#>   Forward-filled column(s): academic_affiliation, cbsatype10.
#>   Created 'age_category' from 'age'.
#>   Recoded 'Provider.Credential.Text' (credential).
#>   Recoded 'academic_affiliation' (academic).
#>   Recoded 'cbsatype10' (rurality).
#>   Recoded 'central_number_e_g_appointment_center' (central scheduling).
#>   Renamed 'business_days_until_appointment' -> 'Business days until appointment'.
#>   Renamed 'insurance' -> 'Insurance'.
#>   Renamed 'gender' -> 'Gender'.
#>   Renamed 'Provider.Credential.Text' -> 'Physician credential'.
#>   Renamed 'academic_affiliation' -> 'Academic affiliation'.
#>   Renamed 'cbsatype10' -> 'Rurality'.
#>   Renamed 'central_number_e_g_appointment_center' -> 'Central scheduling'.
#>   Renamed 'age_category' -> 'Age category'.
#> mysterycall_clean_data: returning 2 row(s), 14 column(s).
stopifnot(all(c("phone", "npi", "first", "last") %in% names(kcleaned)))

# Deduplication still happens - only 2 unique physicians
stopifnot(nrow(kcleaned) == 2L)
```
