# Deduplicate data by insurance and physician phone

Removes duplicate rows so that each unique combination of `phone_col`
and `insurance_col` (and optionally `name_col`) appears only once,
mirroring the source-Rmd pattern:
`df %>% dplyr::distinct(insurance, phone, physician_information, .keep_all = TRUE)`.

## Usage

``` r
mysterycall_dedup_by_insurance(
  data,
  phone_col = "phone",
  insurance_col = "insurance",
  name_col = "physician_information",
  keep_all = TRUE,
  output_dir = NULL,
  filename = "deduped_by_insurance.csv"
)
```

## Arguments

- data:

  A data frame of mystery-caller records.

- phone_col:

  Character scalar. Column used as the unique physician identifier
  (typically a phone number). Default `"phone"`.

- insurance_col:

  Character scalar. Column identifying the insurance type. Default
  `"insurance"`.

- name_col:

  Character scalar or `NULL`. An additional column (e.g.
  `"physician_information"`) included in the distinctness check. Pass
  `NULL` to deduplicate on `phone_col` \\\times\\ `insurance_col` only.
  Default `"physician_information"`.

- keep_all:

  Logical. When `TRUE` (default), all columns are retained in the output
  (equivalent to `.keep_all = TRUE` in
  [`dplyr::distinct()`](https://dplyr.tidyverse.org/reference/distinct.html)).

- output_dir:

  Character scalar or `NULL`. Directory for the CSV output. `NULL`
  (default) writes to a session temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  Pass `NA` to skip writing entirely.

- filename:

  Character scalar. Name of the output CSV file. Default
  `"deduped_by_insurance.csv"`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per unique `phone_col` \\\times\\ `insurance_col` (and
`name_col`, if supplied) combination.

## See also

[`mysterycall_flag_repeat_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md)
for duplicate-call detection; `mysterycall_sanity_checks()` for broader
pre-analysis validation.

Other quality control:
[`mysterycall_clean_medicaid_col()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_medicaid_col.md),
[`mysterycall_flag_excluded_with_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_excluded_with_appointments.md),
[`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md),
[`mysterycall_flag_included_na_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_included_na_appointments.md),
[`mysterycall_flag_repeat_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md)

## Examples

``` r
df <- data.frame(
  phone                = c("555-1234", "555-1234", "555-9999"),
  insurance            = c("Medicaid", "Medicaid", "BCBS"),
  physician_information = c("Dr A", "Dr A", "Dr B"),
  wait_days            = c(3, 3, 7),
  stringsAsFactors     = FALSE
)
mysterycall_dedup_by_insurance(df, output_dir = NA)
#> Removed 1 duplicate row; 2 rows retained.
#> # A tibble: 2 × 4
#>   phone    insurance physician_information wait_days
#>   <chr>    <chr>     <chr>                     <dbl>
#> 1 555-1234 Medicaid  Dr A                          3
#> 2 555-9999 BCBS      Dr B                          7
```
