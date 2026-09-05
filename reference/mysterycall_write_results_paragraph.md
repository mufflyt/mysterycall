# Generate a results paragraph for a mystery caller Poisson model

Produces a ready-to-paste results sentence describing IRRs from a
multivariable Poisson regression, formatted for clinical manuscripts.

## Usage

``` r
mysterycall_write_results_paragraph(
  model_result,
  ref_group,
  exposure_col,
  outcome_label = "appointment acceptance",
  alpha = 0.05,
  irr_digits = 2L,
  ci_digits = 2L,
  p_digits = 3L
)
```

## Arguments

- model_result:

  A `mysterycall_poisson_model` or `mysterycall_nb_model` object (with
  element `$irr_table`), or a data frame with columns `term`, `irr`,
  `ci_lower`, `ci_upper`, and `p_value`.

- ref_group:

  Character scalar: the reference group label (e.g.
  `"commercial insurance"`).

- exposure_col:

  Character scalar: name of the exposure variable whose terms are to be
  described (e.g. `"insurance"`).

- outcome_label:

  Character scalar: human-readable outcome label. Default
  `"appointment acceptance"`.

- alpha:

  Numeric: significance level. Default 0.05. (Currently reserved for
  future use.)

- irr_digits:

  Integer: decimal places for IRR. Default 2L.

- ci_digits:

  Integer: decimal places for CI bounds. Default 2L.

- p_digits:

  Integer: decimal places for p-value. Default 3L.

## Value

A single character string containing all result sentences.

## See also

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
which produces the `model_result` input;
[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md)
for tabular summaries of the same outcome data.

Other reporting:
[`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md),
[`mysterycall_direction_words`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md),
[`mysterycall_supplemental_tables()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_supplemental_tables.md),
[`print.mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_abstract_numbers.md),
[`print.mysterycall_irr_days()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md),
[`print.mysterycall_snapshot()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_snapshot.md)

## Examples

``` r
irr_tbl <- data.frame(
  term     = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured"),
  irr      = c(1.0, 0.72, 0.55),
  ci_lower = c(NA,  0.60, 0.40),
  ci_upper = c(NA,  0.86, 0.75),
  p_value  = c(NA,  0.0003, 0.0000001),
  stringsAsFactors = FALSE
)
mysterycall_write_results_paragraph(irr_tbl, "commercial insurance", "insurance")
#> [1] "In multivariable Poisson regression, insurance was significantly associated with appointment acceptance (see Table X). Compared with commercial insurance, callers presenting as Medicaid had an IRR of 0.72 (95% CI 0.60 to 0.86; p < 0.001) for appointment acceptance. Compared with commercial insurance, callers presenting as Uninsured had an IRR of 0.55 (95% CI 0.40 to 0.75; p < 0.001) for appointment acceptance."
```
