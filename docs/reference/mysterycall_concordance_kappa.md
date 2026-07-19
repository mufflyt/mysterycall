# Per-Item Inter-Rater Agreement for a Concordance Rubric

Computes Cohen's kappa and percent agreement for each rubric item across
two independent coders/callers of the *same* calls – the reliability
metric that dual-coder counseling audits report (and that several
published studies collected the raw material for but never computed).

## Usage

``` r
mysterycall_concordance_kappa(rater1, rater2, rubric, call_id_col = NULL)
```

## Arguments

- rater1, rater2:

  Data frames of identical shape, one row per call in the same order (or
  aligned by `call_id_col`), each holding the rubric item columns as
  coded by one rater.

- rubric:

  A `mysterycall_rubric`. Only its `item` ids are used.

- call_id_col:

  Character scalar or `NULL`. If supplied, the two frames are aligned on
  this key before comparison; otherwise row order is assumed.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `item`, `kappa`, `pct_agree`, `n`.

## See also

Other concordance:
[`mysterycall_concordance_rubric()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_rubric.md),
[`mysterycall_concordance_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_sentence.md),
[`mysterycall_score_concordance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_score_concordance.md)

## Examples

``` r
r1 <- data.frame(asked_age = c(TRUE, TRUE, FALSE, TRUE))
r2 <- data.frame(asked_age = c(TRUE, FALSE, FALSE, TRUE))
rub <- mysterycall_concordance_rubric("asked_age", type = "expected_present")
mysterycall_concordance_kappa(r1, r2, rub)
#> # A tibble: 1 × 4
#>   item      kappa pct_agree     n
#>   <chr>     <dbl>     <dbl> <int>
#> 1 asked_age   0.5      0.75     4
```
