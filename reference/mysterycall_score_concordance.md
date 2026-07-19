# Score Captured Calls Against a Concordance Rubric

Compares each captured call to the reference standard defined by a
[`mysterycall_concordance_rubric()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_rubric.md)
and returns call-level composite scores, item-level concordance rates
(with Wilson confidence intervals), and an overall summary. Item
denominators track *applicability* separately from the number of calls,
so within-encounter conversation exits (which shrink an item's
denominator) are handled natively rather than being mistaken for a zero.

## Usage

``` r
mysterycall_score_concordance(
  data,
  rubric,
  call_id_col = NULL,
  group_col = NULL,
  date_col = NULL,
  conf_level = 0.95,
  output_dir = NULL,
  filename = "concordance_item_rates.csv"
)
```

## Arguments

- data:

  A data frame with one row per call. Rubric item ids are columns.
  `evidence_tier` items hold either a list-column of option vectors or a
  delimited string (see `option_sep` on the rubric).

- rubric:

  A `mysterycall_rubric` from
  [`mysterycall_concordance_rubric()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_rubric.md).

- call_id_col:

  Character scalar or `NULL`. Column uniquely identifying a call. `NULL`
  uses the row index.

- group_col:

  Character scalar or `NULL`. Optional grouping column; when supplied,
  the result carries a per-group composite summary suitable for a
  disparities table.

- date_col:

  Character scalar or `NULL`. Optional call-date column used to select
  the `evidence_tier` rows in force at call time (date-versioned
  guidelines).

- conf_level:

  Numeric. Confidence level for item-rate Wilson intervals. Default
  `0.95`.

- output_dir:

  Character scalar or `NULL`. Directory for the item-rate CSV. `NULL`
  writes to a session temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).
  Pass `NA` to skip writing.

- filename:

  Character scalar. Output CSV file name. Default
  `"concordance_item_rates.csv"`.

## Value

A `mysterycall_concordance` object: a list with

- `call_scores`:

  Tibble, one row per call: `call_id`, `n_applicable`, `n_concordant`,
  `score_pct`, `weighted_pct`.

- `item_rates`:

  Tibble, one row per item: `item`, `label`, `type`, `n_applicable`,
  `n_concordant`, `rate`, `ci_lower`, `ci_upper`.

- `overall`:

  Named list: `mean_score_pct`, `sd_score_pct`, `median_score_pct`,
  `n_calls`, `mean_items_applicable`.

- `by_group`:

  Tibble or `NULL`: per-group `n_calls`, `mean_score_pct`,
  `sd_score_pct`.

- `rubric`, `settings`:

  The rubric and call settings.

## See also

Other concordance:
[`mysterycall_concordance_kappa()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_kappa.md),
[`mysterycall_concordance_rubric()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_rubric.md),
[`mysterycall_concordance_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_sentence.md)

## Examples

``` r
calls <- data.frame(
  advised_window     = c(TRUE, TRUE, FALSE, NA,   TRUE),
  take_asap          = c(TRUE, FALSE, TRUE, TRUE, TRUE),
  redose_after_vomit = c(FALSE, TRUE, NA,   TRUE, TRUE),
  district           = c("A", "A", "B", "B", "B")
)
rub <- mysterycall_concordance_rubric(
  item = c("advised_window", "take_asap", "redose_after_vomit"),
  type = "binary", correct = TRUE
)
res <- mysterycall_score_concordance(calls, rub, group_col = "district",
                                     output_dir = NA)
res$item_rates
#> # A tibble: 3 × 8
#>   item             label type  n_applicable n_concordant  rate ci_lower ci_upper
#>   <chr>            <chr> <chr>        <int>        <int> <dbl>    <dbl>    <dbl>
#> 1 advised_window   advi… bina…            4            3  0.75    0.301    0.954
#> 2 take_asap        take… bina…            5            4  0.8     0.376    0.964
#> 3 redose_after_vo… redo… bina…            4            3  0.75    0.301    0.954
```
