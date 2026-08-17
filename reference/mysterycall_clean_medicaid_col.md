# Clean and binarise a Medicaid acceptance column

Recodes ambiguous or non-informative responses in a Medicaid acceptance
column to `NA`, then creates a binary 0/1 numeric column where the
specified `yes_value` maps to `1` and all other non-`NA` values map to
`0`.

## Usage

``` r
mysterycall_clean_medicaid_col(
  data,
  col = "does_the_physician_accept_medicaid",
  na_values = c("NA as this was a Blue Cross/Blue Shield call.",
    "No answer, unable to determine if they accept Medicaid."),
  yes_value = "Yes they accept Medicaid",
  out_col_cleaned = NULL,
  out_col_numeric = NULL
)
```

## Arguments

- data:

  A data frame containing the source column.

- col:

  Character scalar. Name of the column to clean. Default
  `"does_the_physician_accept_medicaid"`.

- na_values:

  Character vector. Values to recode as `NA`. Default:
  `c("NA as this was a Blue Cross/Blue Shield call.", "No answer, unable to determine if they accept Medicaid.")`.

- yes_value:

  Character scalar. The value in the cleaned column that should be
  mapped to `1`; all other non-`NA` values -\> `0`. Default
  `"Yes they accept Medicaid"`.

- out_col_cleaned:

  Character scalar or `NULL`. Name for the cleaned character column.
  Defaults to `paste0("cleaned_", col)`.

- out_col_numeric:

  Character scalar or `NULL`. Name for the binary numeric column.
  Defaults to `paste0(out_col_cleaned, "_numeric")`.

## Value

The input data frame with two new columns appended:

- `<out_col_cleaned>`:

  Character. Original values with `na_values` replaced by `NA`.

- `<out_col_numeric>`:

  Numeric (`0`/`1`/`NA`). `1` where cleaned column equals `yes_value`;
  `0` otherwise; `NA` where cleaned column is `NA`.

Emits an informative message reporting recoding counts.

## Messages

`"Recoded [n_na] values to NA in '[col]'. [n_yes] records coded 1, [n_no] records coded 0."`

## See also

[`mysterycall_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_normality.md)
for downstream variable checks.

Other quality control:
[`mysterycall_dedup_by_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_dedup_by_insurance.md),
[`mysterycall_flag_excluded_with_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_excluded_with_appointments.md),
[`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md),
[`mysterycall_flag_included_na_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_included_na_appointments.md),
[`mysterycall_flag_repeat_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md),
[`mysterycall_guard_contaminated_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_guard_contaminated_wait.md)

## Examples

``` r
df <- data.frame(
  does_the_physician_accept_medicaid = c(
    "Yes they accept Medicaid",
    "No",
    "NA as this was a Blue Cross/Blue Shield call.",
    "No answer, unable to determine if they accept Medicaid.",
    "Yes they accept Medicaid"
  ),
  stringsAsFactors = FALSE
)
result <- suppressMessages(mysterycall_clean_medicaid_col(df))
result[, c("cleaned_does_the_physician_accept_medicaid",
           "cleaned_does_the_physician_accept_medicaid_numeric")]
#>   cleaned_does_the_physician_accept_medicaid
#> 1                   Yes they accept Medicaid
#> 2                                         No
#> 3                                       <NA>
#> 4                                       <NA>
#> 5                   Yes they accept Medicaid
#>   cleaned_does_the_physician_accept_medicaid_numeric
#> 1                                                  1
#> 2                                                  0
#> 3                                                 NA
#> 4                                                 NA
#> 5                                                  1
```
