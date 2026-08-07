# Print method for mysterycall_abstract_numbers objects

Displays each element of `numbers_list` with its name, one entry per
line, making the key abstract numbers easy to scan and copy-paste.

## Usage

``` r
# S3 method for class 'mysterycall_abstract_numbers'
print(x, ...)
```

## Arguments

- x:

  A `mysterycall_abstract_numbers` object returned by
  [`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md).

- ...:

  Ignored.

## Value

`invisible(x)`.

## See also

Other reporting:
[`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md),
[`mysterycall_direction_words`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md),
[`mysterycall_supplemental_tables()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_supplemental_tables.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`print.mysterycall_irr_days()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md),
[`print.mysterycall_snapshot()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_snapshot.md)

## Examples

``` r
fake_logistic <- structure(
  list(
    n        = 412L,
    or_table = data.frame(
      term     = c("(Intercept)", "insuranceMedicaid"),
      or       = c(2.10, 0.62),
      ci_lower = c(1.20, 0.41),
      ci_upper = c(3.68, 0.94),
      p_value  = c(0.008, 0.024),
      stringsAsFactors = FALSE
    )
  ),
  class = "mysterycall_logistic_model"
)
result <- mysterycall_abstract_numbers(
  logistic_fit     = fake_logistic,
  exposure_term    = "insuranceMedicaid",
  ref_label        = "commercial insurance",
  comparison_label = "Medicaid",
  acceptance_rate  = c(ref = 0.82, comparison = 0.61)
)
print(result)
#> mysterycall_abstract_numbers
#> 
#>   n_total                   412
#>   OR                        0.62
#>   OR_CI                     0.41-0.94
#>   OR_full                   0.62 (0.41-0.94)
#>   OR_p                      0.024
#>   absolute_gap_pct          21%
#>   ref_rate_pct              82%
#>   comparison_rate_pct       61%
#>   abstract_sentence        
#>     Among 412 total calls, Medicaid callers were 38% less likely to be
#>     offered appointment acceptance than commercial insurance callers
#>     (OR 0.62, 95% CI 0.41-0.94, p = 0.024), with an absolute
#>     appointment acceptance gap of 21 percentage points (82% vs. 61%).
#> 
```
