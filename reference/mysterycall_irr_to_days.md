# Convert IRRs to absolute wait-time differences in days

Translates incidence rate ratios (IRRs) and their Wald confidence
intervals from a fitted mystery-caller model into clinically
interpretable absolute differences in wait days. Given a reference-group
mean, the conversion is:

## Usage

``` r
mysterycall_irr_to_days(
  model_result,
  baseline_mean,
  exposure_col = NULL,
  ref_group = NULL,
  digits = 1L,
  irr_digits = 2L
)
```

## Arguments

- model_result:

  A `mysterycall_poisson_model` or `mysterycall_nb_model` object, or a
  data frame with columns `term`, `irr`, `ci_lower`, `ci_upper`, and
  (optionally) `p_value_fmt`.

- baseline_mean:

  Numeric scalar. The observed mean wait days in the reference group
  (e.g. the mean for BCBS callers). Obtain this from
  [`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md)
  or `mean(data$wait_days[data$insurance == "BCBS"])`.

- exposure_col:

  Character scalar. Name of the exposure variable whose terms to report
  (e.g. `"insurance"`). Only rows whose `term` starts with this string
  are included. Pass `NULL` to include all non-intercept terms.

- ref_group:

  Character scalar. Label for the reference group used in the narrative
  sentences (e.g. `"BCBS"`). When `NULL`, sentences omit the "compared
  with X" clause.

- digits:

  Integer. Decimal places for days in the output table and sentences.
  Default `1L`.

- irr_digits:

  Integer. Decimal places for IRR in the sentences. Default `2L`.

## Value

A list of class `mysterycall_irr_days` with elements:

- `table`:

  Data frame with columns: `term`, `level` (group label stripped of the
  exposure prefix), `irr`, `days_mean` (reference-group mean x IRR),
  `days_diff` (days_mean - baseline_mean), `days_ci_lower`,
  `days_ci_upper`, `direction` (`"more"` or `"fewer"`), `p_value_fmt`.

- `sentences`:

  Character vector. One manuscript-ready sentence per row.

- `paragraph`:

  Character scalar. All sentences joined into a paragraph.

- `baseline_mean`:

  Numeric. The baseline_mean supplied by the caller.

## Details

\$\$\text{days difference} = \mu\_{\text{ref}} \times (\text{IRR} -
1)\$\$ \$\$\text{CI in days} = \mu\_{\text{ref}} \times
(\text{CI}\_{\text{lower/upper}} - 1)\$\$

Positive values mean the comparison group waits *longer*; negative
values mean the comparison group waits *fewer* days than the reference
group.

## Example sentence

*"Medicaid-insured callers waited a mean of 4.3 additional days compared
with BCBS (95% CI 1.2 to 7.4 days; IRR 1.24, p = 0.003)."*

## See also

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md)
for IRR-scale reporting;
[`mysterycall_irr_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_plot.md)
to visualise the same estimates.

Other reporting:
[`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
[`mysterycall_geographic_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geographic_map.md),
[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md),
[`mysterycall_supplemental_tables()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_supplemental_tables.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`print.mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_abstract_numbers.md),
[`print.mysterycall_irr_days()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md),
[`print.mysterycall_snapshot()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_snapshot.md)

## Examples

``` r
irr_tbl <- data.frame(
  term        = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured"),
  irr         = c(1.00, 1.28, 0.81),
  ci_lower    = c(NA,   1.05, 0.61),
  ci_upper    = c(NA,   1.56, 1.07),
  p_value_fmt = c(NA,   "0.014", "0.134"),
  stringsAsFactors = FALSE
)
result <- mysterycall_irr_to_days(
  irr_tbl,
  baseline_mean = 21,
  exposure_col  = "insurance",
  ref_group     = "BCBS"
)
result$table
#>                 term     level  irr days_mean days_diff days_ci_lower
#> 1  insuranceMedicaid  Medicaid 1.28     26.88      5.88          1.05
#> 2 insuranceUninsured Uninsured 0.81     17.01     -3.99         -8.19
#>   days_ci_upper direction p_value_fmt
#> 1         11.76      more       0.014
#> 2          1.47     fewer       0.134
cat(result$paragraph)
#> Medicaid-insured callers waited a mean of 5.9 more days compared with BCBS (95% CI 1.1 to 11.8 days; IRR 1.28; p = 0.014). Uninsured-insured callers waited a mean of 4.0 fewer days compared with BCBS (95% CI 8.2 to 1.5 days; IRR 0.81; p = 0.134).
```
