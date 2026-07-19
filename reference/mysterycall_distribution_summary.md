# Distribution summary for a categorical column

Returns the modal (most frequent) level of a categorical column together
with a full frequency table, mirroring the source-Rmd pattern:


    df %>%
      filter(!is.na(!!sym(column))) %>%
      group_by(!!sym(column)) %>%
      summarise(count = n()) %>%
      mutate(total = sum(count), percent = (count / total) * 100) %>%
      arrange(desc(count)) %>%
      slice(1)

## Usage

``` r
mysterycall_distribution_summary(data, column, digits = 1L)
```

## Arguments

- data:

  A data frame.

- column:

  Character scalar. Name of the categorical column.

- digits:

  Integer. Decimal places for the percentage. Default `1`.

## Value

A named list:

- `level`:

  The modal category value (as character).

- `count`:

  Frequency of the modal level.

- `total`:

  Total non-NA observations.

- `percent`:

  Percentage of total for the modal level, rounded to `digits` decimal
  places.

- `sentence`:

  Character string:
  `"The most common [column] was [level] (n = [count]/N = [total], [percent]%)."`

- `full_table`:

  A
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  with columns `level`, `count`, and `percent` for every non-NA
  category, ordered descending by `count`.

## See also

[`mysterycall_descriptive_stats()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_descriptive_stats.md)
for numeric summaries.

Other descriptive helpers:
[`mysterycall_demographics_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_demographics_sentence.md),
[`mysterycall_descriptive_stats()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_descriptive_stats.md),
[`mysterycall_facet_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_facet_histogram.md),
[`mysterycall_log_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_histogram.md),
[`mysterycall_physicians_with_detail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physicians_with_detail.md),
[`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md),
[`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)

## Examples

``` r
df <- data.frame(
  insurance = c("Medicaid", "BCBS", "Medicaid", "Medicaid", "BCBS", NA),
  stringsAsFactors = FALSE
)
mysterycall_distribution_summary(df, "insurance")
#> $level
#> [1] "Medicaid"
#> 
#> $count
#> [1] 3
#> 
#> $total
#> [1] 5
#> 
#> $percent
#> [1] 60
#> 
#> $sentence
#> [1] "The most common insurance was Medicaid (n = 3/N = 5, 60.0%)."
#> 
#> $full_table
#> # A tibble: 2 × 3
#>   level    count percent
#>   <chr>    <int>   <dbl>
#> 1 Medicaid     3      60
#> 2 BCBS         2      40
#> 
```
