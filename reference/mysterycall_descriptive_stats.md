# Descriptive statistics for a numeric column

Computes the median, 25th and 75th percentiles, non-missing count, and
missing count for a named numeric column in a data frame, mirroring the
source-Rmd pattern:


    median_val <- round(median(df[[column]], na.rm = TRUE), 2)
    q25 <- quantile(df[[column]], probs = 0.25, na.rm = TRUE)
    q75 <- quantile(df[[column]], probs = 0.75, na.rm = TRUE)
    list(median = median_val, q25 = q25, q75 = q75)

## Usage

``` r
mysterycall_descriptive_stats(data, column, digits = 2L, digits_q = 0L)
```

## Arguments

- data:

  A data frame.

- column:

  Character scalar. Name of the numeric column to summarise.

- digits:

  Integer. Number of decimal places for the median. Default `2`.

- digits_q:

  Integer. Number of decimal places for the quartiles (Q1 and Q3).
  Default `0`.

## Value

A named list with elements:

- `median`:

  Rounded median (non-NA values).

- `q25`:

  25th percentile, rounded to `digits_q` places.

- `q75`:

  75th percentile, rounded to `digits_q` places.

- `n`:

  Number of non-NA observations.

- `n_missing`:

  Number of NA observations.

- `sentence`:

  Character string: `"Median [column]: [median] (IQR: [q25]–[q75])."`

## Details

Also returns a human-readable `$sentence` field.

## See also

[`mysterycall_distribution_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_distribution_summary.md)
for categorical summaries.

Other descriptive helpers:
[`mysterycall_demographics_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_demographics_sentence.md),
[`mysterycall_distribution_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_distribution_summary.md),
[`mysterycall_facet_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_facet_histogram.md),
[`mysterycall_log_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_histogram.md),
[`mysterycall_physicians_with_detail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physicians_with_detail.md),
[`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md),
[`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)

## Examples

``` r
df <- data.frame(wait = c(1, 3, 5, 7, NA))
mysterycall_descriptive_stats(df, "wait")
#> $median
#> [1] 4
#> 
#> $q25
#> [1] 2
#> 
#> $q75
#> [1] 6
#> 
#> $n
#> [1] 4
#> 
#> $n_missing
#> [1] 1
#> 
#> $sentence
#> [1] "Median wait: 4.00 (IQR: 2–6)."
#> 
```
