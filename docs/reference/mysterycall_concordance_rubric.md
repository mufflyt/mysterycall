# Define a Guideline-Concordance Rubric

Builds the reference standard that
[`mysterycall_score_concordance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_score_concordance.md)
scores captured calls against. A rubric is a set of typed items; each
study in the mystery-caller counseling / guideline-adherence literature
is expressed as a rubric assembled from four item types.

## Usage

``` r
mysterycall_concordance_rubric(
  item,
  label = item,
  type = "binary",
  correct = TRUE,
  reference_col = NA_character_,
  tier_lookup = NULL,
  weight = 1,
  na_policy = "not_applicable",
  option_sep = ";"
)
```

## Arguments

- item:

  Character vector. Machine-readable item ids. Each must match a column
  in the captured-call data passed to
  [`mysterycall_score_concordance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_score_concordance.md).
  Must be unique.

- label:

  Character vector. Manuscript-facing wording per item. Recycled to
  `length(item)`. Default: `item`.

- type:

  Character vector. One of `"binary"`, `"expected_present"`,
  `"reference_match"`, `"evidence_tier"`. Recycled. Default `"binary"`.

  `binary`

  :   Concordant when the value equals `correct`.

  `expected_present`

  :   Concordant when the cue was elicited at all (`correct` is forced
      to `TRUE`).

  `reference_match`

  :   Concordant when the value equals a per-row reference column named
      by `reference_col` (gold standard varies by scenario / state /
      date).

  `evidence_tier`

  :   The value is a set of named options per call; concordant when it
      includes at least one option in the `"concordant"` tier of
      `tier_lookup`.

- correct:

  Expected value(s) for `binary` items. A scalar (recycled), a vector of
  length `length(item)`, or a list. Ignored for `reference_match` and
  `evidence_tier`. Default `TRUE`.

- reference_col:

  Character vector. For `reference_match` items, the name of the per-row
  gold-standard column. Recycled. Default `NA`.

- tier_lookup:

  Data frame or `NULL`. For `evidence_tier` items, a table with columns
  `option`, `tier` (`"concordant"` / `"nonconcordant"` / `"neutral"`)
  and optional `effective_from` / `effective_to` dates for
  date-versioned guidelines. Default `NULL`.

- weight:

  Numeric vector. Composite-score weights (\> 0). Recycled. Default `1`.

- na_policy:

  Character vector. How to treat uncodable / unreached items:
  `"not_applicable"` drops the item from that call's denominator (the
  natural handling for within-encounter conversation exits);
  `"incorrect"` counts it as non-concordant against a full denominator.
  Recycled. Default `"not_applicable"`.

- option_sep:

  Character scalar. Delimiter for `evidence_tier` option columns
  supplied as strings. Default `";"`.

## Value

A `mysterycall_rubric` object: a list with element `items` (a
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
of the validated item specifications), `tier_lookup`, and `option_sep`.

## See also

[`mysterycall_score_concordance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_score_concordance.md)

Other concordance:
[`mysterycall_concordance_kappa()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_kappa.md),
[`mysterycall_concordance_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_sentence.md),
[`mysterycall_score_concordance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_score_concordance.md)

## Examples

``` r
# Lungfiel 2023 - a four-item counseling-quality checklist
mysterycall_concordance_rubric(
  item  = c("advised_window", "take_asap", "redose_after_vomit"),
  label = c("Advised on differing windows of effect",
            "Advised to take as soon as possible",
            "Advised re-dosing after vomiting"),
  type  = "binary", correct = TRUE
)
#> <mysterycall_rubric: 3 item(s)>
#>                item   type      na_policy
#>      advised_window binary not_applicable
#>           take_asap binary not_applicable
#>  redose_after_vomit binary not_applicable
```
