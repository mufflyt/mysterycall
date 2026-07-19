# Manuscript-Ready Concordance Sentence

Turns a
[`mysterycall_score_concordance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_score_concordance.md)
result into a numbers-locked sentence, in the package's prose-builder
family. With `item = NULL` it describes the overall composite; naming an
`item` describes that item's concordance rate and confidence interval.

## Usage

``` r
mysterycall_concordance_sentence(
  x,
  item = NULL,
  subject = "clinics",
  digits = 1L
)
```

## Arguments

- x:

  A `mysterycall_concordance` object.

- item:

  Character scalar or `NULL`. A rubric item id, or `NULL` for the
  overall composite sentence.

- subject:

  Character scalar. Noun for the audited units. Default `"clinics"`.

- digits:

  Integer. Rounding digits for percentages. Default `1`.

## Value

A character scalar.

## See also

Other concordance:
[`mysterycall_concordance_kappa()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_kappa.md),
[`mysterycall_concordance_rubric()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_rubric.md),
[`mysterycall_score_concordance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_score_concordance.md)

## Examples

``` r
calls <- data.frame(advised_window = c(TRUE, TRUE, FALSE, NA, TRUE))
rub <- mysterycall_concordance_rubric("advised_window", type = "binary")
res <- mysterycall_score_concordance(calls, rub, output_dir = NA)
cat(mysterycall_concordance_sentence(res, item = "advised_window",
                                     subject = "pharmacies"))
#> pharmacies were concordant with the standard for "advised_window" in 75.0% of calls (n = 4; 95% CI 30.1-95.4%).
```
