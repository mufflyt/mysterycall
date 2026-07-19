# Flag Physicians Included More Than a Threshold Number of Times

A quality-control check that identifies physician-call combinations
appearing more than `threshold` times in the dataset. Returns a summary
table and optionally writes it to CSV for audit review.

## Usage

``` r
mysterycall_flag_repeat_physicians(
  data,
  id_col = "id_number",
  name_col = "physician_information",
  threshold = 2L,
  output_dir = NULL,
  filename = "quality_check_repeat_physicians.csv"
)
```

## Arguments

- data:

  A data frame of mystery-caller records.

- id_col:

  Character scalar. Name of the physician identifier column (e.g.
  `"id_number"`, `"npi"`).

- name_col:

  Character scalar. Name of the physician name/info column (e.g.
  `"physician_information"`). Set to `NULL` to group by `id_col` only.

- threshold:

  Integer. Flag physicians with a call count **greater than** this
  value. Default `2`.

- output_dir:

  Character scalar or `NULL`. Directory for the CSV output. `NULL`
  (default) writes to a session temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  Pass `NA` to skip writing entirely.

- filename:

  Character scalar. Name of the output CSV file. Default
  `"quality_check_repeat_physicians.csv"`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per flagged physician group, columns `<id_col>`,
`<name_col>` (if supplied), and `n_calls` (descending). Returns a
zero-row tibble (invisibly) when no physicians exceed the threshold.

## Quality control interpretation

In mystery-caller studies each target physician is typically called once
or twice per wave. A count exceeding the threshold may indicate
duplicate data entry, a scheduling error, or a data-linkage problem that
should be resolved before analysis.

## See also

[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)
for broader pre-analysis checks.

Other quality control:
[`mysterycall_clean_medicaid_col()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_medicaid_col.md),
[`mysterycall_dedup_by_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_dedup_by_insurance.md),
[`mysterycall_flag_excluded_with_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_excluded_with_appointments.md),
[`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md),
[`mysterycall_flag_included_na_appointments()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_included_na_appointments.md)

## Examples

``` r
df <- data.frame(
  id_number            = c("A", "A", "A", "B", "B", "C"),
  physician_information = c("Dr Smith", "Dr Smith", "Dr Smith",
                            "Dr Jones", "Dr Jones", "Dr Lee"),
  stringsAsFactors = FALSE
)
# Dr Smith appears 3 times (> 2) and should be flagged
result <- mysterycall_flag_repeat_physicians(df, output_dir = NA)
#> Quality check: 1 physician record(s) appear more than 2 time(s).
result
#> # A tibble: 1 × 3
#>   id_number physician_information n_calls
#>   <chr>     <chr>                   <int>
#> 1 A         Dr Smith                    3
```
