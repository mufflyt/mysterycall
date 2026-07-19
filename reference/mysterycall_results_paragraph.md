# Generate a results paragraph for a logistic mystery caller model

Produces ready-to-paste results sentences describing odds ratios (OR)
from a logistic regression, formatted for clinical manuscripts. Accepts
a `mysterycall_logistic_model` object or a plain data frame with OR
columns. For IRR-based (Poisson / negative-binomial) results use
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md)
instead.

## Usage

``` r
mysterycall_results_paragraph(
  model_result,
  ref_group,
  exposure_col,
  outcome_label = "appointment acceptance",
  alpha = 0.05,
  or_digits = 2L,
  ci_digits = 2L,
  p_digits = 3L,
  subject = "callers"
)
```

## Arguments

- model_result:

  A `mysterycall_logistic_model` object returned by
  [`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
  **or** a data frame with at minimum the columns `term`, `or`,
  `ci_lower`, `ci_upper`, and `p_value`.

- ref_group:

  Character scalar: the reference group label used in the sentence (e.g.
  `"commercial insurance"`).

- exposure_col:

  Character scalar: the name of the exposure variable whose levels are
  to be narrated (e.g. `"insurance"`). Terms whose name starts with this
  string are selected; the leading prefix is stripped to recover the
  level label.

- outcome_label:

  Character scalar: human-readable outcome description placed after
  "likely to be offered". Default `"appointment acceptance"`.

- alpha:

  Numeric scalar in (0, 1): significance threshold kept for downstream
  use; does not currently filter sentences. Default `0.05`.

- or_digits:

  Integer scalar: decimal places for the OR value. Default `2L`.

- ci_digits:

  Integer scalar: decimal places for CI bounds. Default `2L`.

- p_digits:

  Integer scalar: decimal places for p-values. Default `3L`.

- subject:

  Character scalar: the noun for the units being narrated. Default
  `"callers"`. Set to another noun (e.g. `"patients"`) for studies whose
  exposure is not caller-based.

## Value

A single character string. One sentence is produced per non-intercept
term matching `exposure_col`. Sentences are separated by a single space.
Sentence form:

- OR \< 1:
  `"<Level> callers were <X>% less likely to be offered <outcome_label> (OR <or>, 95% CI <lo>-<hi>, p=<p>)."`

- OR \> 1:
  `"<Level> callers were <X>% more likely to be offered <outcome_label> (OR <or>, 95% CI <lo>-<hi>, p=<p>)."`

- OR = 1:
  `"<Level> callers had similar odds of being offered <outcome_label> compared with <ref_group> (OR 1.00, 95% CI <lo>-<hi>, p=<p>)."`

When `p < 0.001` the p-value is rendered as `"p < 0.001"`.

## See also

[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md)

Other reporting:
[`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md),
[`mysterycall_direction_words`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md),
[`mysterycall_supplemental_tables()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_supplemental_tables.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`print.mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_abstract_numbers.md),
[`print.mysterycall_irr_days()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md),
[`print.mysterycall_snapshot()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_snapshot.md)

## Examples

``` r
or_tbl <- data.frame(
  term     = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured"),
  or       = c(2.10, 0.62, 0.41),
  ci_lower = c(1.20, 0.41, 0.22),
  ci_upper = c(3.68, 0.94, 0.76),
  p_value  = c(0.008, 0.024, 0.0004),
  stringsAsFactors = FALSE
)
mysterycall_results_paragraph(or_tbl, "commercial insurance", "insurance")
#> [1] "Medicaid callers were 38% less likely to be offered appointment acceptance (OR 0.62, 95% CI 0.41-0.94, p=0.024). Uninsured callers were 59% less likely to be offered appointment acceptance (OR 0.41, 95% CI 0.22-0.76, p < 0.001)."
```
