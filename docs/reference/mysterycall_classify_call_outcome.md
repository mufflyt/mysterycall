# Map Raw Call Dispositions to a Standard Outcome Taxonomy

Collapses free-text or heterogeneous call-disposition labels into a
small, analysable set of canonical states that recur across access
audits – so an appointment blocked pending insurance verification, a
referral, or records is distinguished from a plain refusal, and phone
gatekeeping and unreachable numbers become their own funnel stages
(Pollack 2016, Sharma 2025, Hodson 2025).

## Usage

``` r
mysterycall_classify_call_outcome(x, mapping = NULL, other = "other")
```

## Arguments

- x:

  Character vector of raw disposition text (one per call).

- mapping:

  Named list or `NULL`. Names are canonical levels; values are
  case-insensitive regular expressions matched against `x`. The first
  matching pattern (in list order) wins. `NULL` uses a built-in default
  map covering the common access-audit states.

- other:

  Character scalar. Level assigned when nothing matches. Default
  `"other"`.

## Value

A factor with levels in `mapping` order followed by `other`.

## See also

Other call-outcomes:
[`mysterycall_multiresponse_tabulate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multiresponse_tabulate.md),
[`mysterycall_ordinal_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ordinal_model.md),
[`mysterycall_outcome_gradient()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_outcome_gradient.md)

## Examples

``` r
raw <- c("Appointment offered in 12 days", "Needs a referral first",
         "Won't give info over the phone", "No answer after 3 tries",
         "Must verify insurance ID number")
mysterycall_classify_call_outcome(raw)
#> [1] appointment_offered             referral_required              
#> [3] gatekeeping_no_info             not_reached                    
#> [5] insurance_verification_required
#> 9 Levels: not_reached gatekeeping_no_info ... other
```
