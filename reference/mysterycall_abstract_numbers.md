# Distil key abstract numbers from fitted model objects

Extracts and formats the 5-6 numbers that go into a manuscript abstract
from the fitted model objects produced by
[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
and
[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md).
This eliminates manual copy-paste transcription errors when writing
abstracts.

## Usage

``` r
mysterycall_abstract_numbers(
  logistic_fit = NULL,
  poisson_fit = NULL,
  lmm_fit = NULL,
  exposure_term,
  ref_label = "the reference group",
  comparison_label = NULL,
  outcome_label = "appointment acceptance",
  digits_or = 2L,
  digits_p = 3L,
  acceptance_rate = NULL
)
```

## Arguments

- logistic_fit:

  A `mysterycall_logistic_model` object returned by
  [`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
  or `NULL`. Provides N, OR, CI, and p-value for the primary binary
  outcome (appointment offered).

- poisson_fit:

  A `mysterycall_poisson_model` or `mysterycall_nb_model` object, or
  `NULL`. Provides N, IRR, CI, and p-value for wait time.

- lmm_fit:

  A `mysterycall_lmm` object returned by
  [`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
  or `NULL`. Provides N, beta coefficient, CI, and p-value for
  continuous wait time. When the LMM was log-transformed
  (`$log_transformed == TRUE`), the beta is on the log-days scale and
  the unit label reflects that.

- exposure_term:

  Character scalar. The exact term name to extract from each model
  coefficient table (e.g. `"insuranceMedicaid"`). Must match the `term`
  column of `or_table`, `irr_table`, or `coef_table` exactly.

- ref_label:

  Character scalar. Human-readable reference group label used in the
  abstract sentence (e.g. `"commercial insurance"`). Default
  `"the reference group"`.

- comparison_label:

  Character scalar or `NULL`. Human-readable label for the comparison
  group (e.g. `"Medicaid"`). When `NULL` (default), it is derived from
  `exposure_term` by stripping the leading run of lowercase letters
  (e.g. `"insuranceMedicaid"` becomes `"Medicaid"`).

- outcome_label:

  Character scalar. Human-readable outcome description used in the
  abstract sentence. Default `"appointment acceptance"`.

- digits_or:

  Integer. Decimal places for OR, IRR, and beta coefficients. Default
  `2L`.

- digits_p:

  Integer. Decimal places for p-values. Default `3L`.

- acceptance_rate:

  Named numeric vector of length 2, or `NULL`. Should be of the form
  `c(ref = 0.82, comparison = 0.61)` and provide the raw acceptance
  rates for the reference and comparison groups. Used to compute the
  absolute percentage-point gap. When `NULL` (default), the gap is
  omitted from the sentence.

## Value

A list of class `mysterycall_abstract_numbers` with elements:

- `n_total`:

  `integer`. Total calls from the first non-`NULL` fit (`logistic_fit`,
  then `poisson_fit`, then `lmm_fit`).

- `or`:

  `numeric`. Odds ratio, or `NA_real_` when `logistic_fit` is `NULL` or
  `exposure_term` is not found.

- `or_ci`:

  `character`. Formatted as `"0.62 (0.41-0.94)"`, or `NA`.

- `or_p`:

  `character`. Formatted p-value (e.g. `"0.024"` or `"< 0.001"`), or
  `NA`.

- `irr`:

  `numeric`. Incidence rate ratio, or `NA_real_`.

- `irr_ci`:

  `character` or `NA`.

- `irr_p`:

  `character` or `NA`.

- `beta`:

  `numeric`. LMM fixed-effect coefficient (days or log-days), or
  `NA_real_`.

- `beta_ci`:

  `character` or `NA`.

- `beta_p`:

  `character` or `NA`.

- `absolute_gap`:

  `numeric`. `ref_rate - comparison_rate` in proportion units, or
  `NA_real_` when `acceptance_rate` is `NULL`.

- `abstract_sentence`:

  `character`. Full abstract-ready sentence combining all available
  statistics.

- `numbers_list`:

  Named `character` vector of all formatted numbers suitable for
  copy-paste into a manuscript.

## Abstract sentence structure

The sentence is assembled from available components in this order:

1.  Lead: `"Among [N] total calls, "`.

2.  OR clause (if `logistic_fit` is non-`NULL`): primary clause.

3.  IRR clause (if `poisson_fit` is non-`NULL`): primary clause when no
    OR is present; otherwise appended after a semicolon.

4.  LMM beta clause (if `lmm_fit` is non-`NULL`): primary clause when no
    OR or IRR is present; otherwise appended after a semicolon.

5.  Absolute gap suffix (if `acceptance_rate` is non-`NULL`): appended
    as
    `", with an absolute [outcome_label] gap of [X] percentage points ([ref]% vs. [comparison]%)"`.

## See also

[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md)

Other reporting:
[`mysterycall_direction_words`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md),
[`mysterycall_supplemental_tables()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_supplemental_tables.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`print.mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_abstract_numbers.md),
[`print.mysterycall_irr_days()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md),
[`print.mysterycall_snapshot()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_snapshot.md)

## Examples

``` r
# --- Minimal example: logistic fit only -------------------------------------
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
result$abstract_sentence
#> [1] "Among 412 total calls, Medicaid callers were 38% less likely to be offered appointment acceptance than commercial insurance callers (OR 0.62, 95% CI 0.41-0.94, p = 0.024), with an absolute appointment acceptance gap of 21 percentage points (82% vs. 61%)."

# --- Extended example: logistic + Poisson fit -------------------------------
fake_poisson <- structure(
  list(
    n         = 298L,
    irr_table = data.frame(
      term      = c("(Intercept)", "insuranceMedicaid"),
      irr       = c(0.95, 1.40),
      ci_lower  = c(0.70, 1.12),
      ci_upper  = c(1.29, 1.75),
      p_value   = c(0.782, 0.003),
      stringsAsFactors = FALSE
    )
  ),
  class = "mysterycall_poisson_model"
)

result2 <- mysterycall_abstract_numbers(
  logistic_fit  = fake_logistic,
  poisson_fit   = fake_poisson,
  exposure_term = "insuranceMedicaid",
  ref_label     = "commercial insurance",
  acceptance_rate = c(ref = 0.82, comparison = 0.61)
)
result2$abstract_sentence
#> [1] "Among 412 total calls, Medicaid callers were 38% less likely to be offered appointment acceptance than commercial insurance callers (OR 0.62, 95% CI 0.41-0.94, p = 0.024); wait times were 40% longer (IRR 1.40, 95% CI 1.12-1.75, p = 0.003), with an absolute appointment acceptance gap of 21 percentage points (82% vs. 61%)."
```
