# Clean raw mystery-caller data for publication-ready analysis

Transforms a raw REDCap / Phase-2 export into a tidy, human-readable
data frame suitable for
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html),
regression models, and manuscript tables. Steps include deduplication,
age categorisation, value recoding, factor-level ordering by frequency,
column renaming to title-case labels, and optional PII removal.

## Usage

``` r
mysterycall_clean_data(
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
  drop_pii = TRUE,
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

## Value

A cleaned `data.frame` with:

- Deduplicated rows (one row per physician).

- An `"Age category"` column (ordered factor) when `age_col` is present.

- Recoded and frequency-ordered factor columns.

- Human-readable, title-case column names for all recognised fields.

- PII columns removed when `drop_pii = TRUE`.

## Recode convention

Each `recode_*` argument is a named character vector where **names** are
the raw (input) values and **values** are the desired display labels.
Non-matching values are left unchanged. Pass an empty vector
(`character(0)`) to suppress recoding for a particular column.

## Optional dependencies

`tidyr` (in `Suggests`) is used for forward-filling; `zoo` and `forcats`
are used opportunistically when installed. All three are optional: the
function degrades gracefully to built-in fallbacks when they are absent.

## See also

[`mysterycall_clean_data_keep_identifiers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data_keep_identifiers.md)
for a variant that retains PII columns;
[`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md)
for the base-R frequency-ordering used as a `forcats` fallback.

Other data utilities:
[`mysterycall_clean_data_keep_identifiers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_data_keep_identifiers.md)

## Examples

``` r
# Minimal example with base R only ------------------------------------------
set.seed(42)
raw <- data.frame(
  phone         = c("303-111-2222", "303-111-2222", "720-555-9999"),
  age           = c(55, 55, 72),
  insurance     = c("Medicaid", "Medicaid", "Medicare"),
  gender        = c("Female", "Female", "Male"),
  Provider.Credential.Text = c("MD", "MD", "DO"),
  academic_affiliation     = c("University", NA, "Community"),
  cbsatype10               = c("Metro", "Metro", "Micro"),
  business_days_until_appointment = c(7L, 7L, 14L),
  central_number_e_g_appointment_center = c("Yes", "Yes", "No"),
  first  = c("Jane", "Jane", "Bob"),
  last   = c("Doe",  "Doe",  "Smith"),
  record_id = 1:3,
  stringsAsFactors = FALSE
)

cleaned <- mysterycall_clean_data(raw)
#> mysterycall_clean_data: 3 row(s), 12 column(s) received.
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
#>   Dropped PII column(s): phone, first, last, record_id.
#> mysterycall_clean_data: returning 2 row(s), 9 column(s).
print(names(cleaned))
#> [1] "age"                             "Insurance"                      
#> [3] "Gender"                          "Physician credential"           
#> [5] "Academic affiliation"            "Rurality"                       
#> [7] "Business days until appointment" "Central scheduling"             
#> [9] "Age category"                   
print(cleaned[["Age category"]])
#> [1] 50-59 yrs >=70 yrs 
#> Levels: 50-59 yrs >=70 yrs <50 yrs 60-69 yrs

# Custom age breaks ---------------------------------------------------------
cleaned2 <- mysterycall_clean_data(
  raw,
  age_breaks = c(-Inf, 45, 65, Inf),
  age_labels = c("<45 yrs", "45-64 yrs", ">=65 yrs")
)
#> mysterycall_clean_data: 3 row(s), 12 column(s) received.
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
#>   Dropped PII column(s): phone, first, last, record_id.
#> mysterycall_clean_data: returning 2 row(s), 9 column(s).
print(cleaned2[["Age category"]])
#> [1] 45-64 yrs >=65 yrs 
#> Levels: 45-64 yrs >=65 yrs <45 yrs

# Skip age processing entirely ----------------------------------------------
cleaned3 <- mysterycall_clean_data(raw, age_col = NULL)
#> mysterycall_clean_data: 3 row(s), 12 column(s) received.
#>   Removing 1 duplicate row(s) based on 'phone'.
#>   Forward-filled column(s): academic_affiliation, cbsatype10.
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
#>   Dropped PII column(s): phone, first, last, record_id.
#> mysterycall_clean_data: returning 2 row(s), 8 column(s).
stopifnot(!"Age category" %in% names(cleaned3))
```
