# Canonical exclusion-code / label-string crosswalk

The package contains two inclusion conventions that evolved
independently:

## Usage

``` r
mysterycall_exclusion_crosswalk(
  inclusion_value = "Able to contact",
  logistic_include_codes = c(0L, 7L, 9L, 10L)
)
```

## Arguments

- inclusion_value:

  Character scalar. The `reason_for_exclusions` value the label path
  treats as included. Default `"Able to contact"`.

- logistic_include_codes:

  Integer vector. Exclusion codes the integer path includes in the
  logistic dataset. Default `c(0L, 7L, 9L, 10L)` - matches
  [`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html),
one row per known exclusion code, with columns:

- `code`:

  Integer exclusion code (as used by
  [`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md)).

- `code_label`:

  Human-readable label for the integer code.

- `label_category`:

  Semantic key from
  [`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md)'s
  `exclusion_categories`, or `NA` for codes with no label-path category
  (`included`, or codes the label path does not bucket).

- `label_string`:

  Default `reason_for_exclusions` string the label path expects for this
  code, or `NA` where none exists.

- `reached`:

  Logical. Was the office reached? (Distinguishes reached-but-excluded
  codes from unreachable ones.)

- `in_logistic`:

  Logical. Integer path includes this code in the logistic
  (appointment-offered) dataset.

- `in_waittime`:

  Logical. Integer path includes this code in the wait-time dataset
  (code 0 only).

- `label_included`:

  Logical. Label path counts this code as included (`"Able to contact"`,
  i.e. code 0 only).

## Details

- the **integer-code path**
  ([`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md),
  [`mysterycall_strobe_flow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_flow.md))
  derives samples from an integer `exclusions` column on the *raw*
  REDCap export; and

- the **label-string path**
  ([`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
  [`mysterycall_acceptance_rate_calc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate_calc.md),
  [`mysterycall_insurance_acceptance_rates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_acceptance_rates.md),
  and the workflow runners) derives samples from a
  `reason_for_exclusions` string column on the *cleaned* export,
  treating `"Able to contact"` as the included set.

The two paths do **not** define the same included set. This function
returns the mapping between them as data, so the divergence is
inspectable rather than implicit. It is the single source of truth used
by
[`mysterycall_reconcile_inclusion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_inclusion.md).

## The key divergence

The integer logistic set (`logistic_include_codes`, default
`c(0, 7, 9, 10)`) keeps codes 7 (referral required), 9 (not accepting
new patients), and 10 (must see midlevel first) as *included* calls with
an appointment-not-offered outcome. The label path classifies those same
calls as **exclusions** – they are never `"Able to contact"`. Rows where
`in_logistic` is `TRUE` but `label_included` is `FALSE` are exactly that
gap.

## See also

[`mysterycall_reconcile_inclusion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_inclusion.md),
[`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md)

Other data-preparation:
[`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md),
[`mysterycall_reconcile_inclusion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_inclusion.md),
[`print.mysterycall_prepared()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_prepared.md),
[`print.mysterycall_reconciliation()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_reconciliation.md)

## Examples

``` r
cw <- mysterycall_exclusion_crosswalk()
# The three codes where the two inclusion definitions disagree:
cw[cw$in_logistic & !cw$label_included, c("code", "code_label")]
#> # A tibble: 3 × 2
#>    code code_label                
#>   <int> <chr>                     
#> 1     7 Referral required         
#> 2     9 Not accepting new patients
#> 3    10 Must see midlevel first   
```
