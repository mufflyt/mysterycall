# Crosswalk between REDCap integer exclusion codes and label strings

Compares, record by record, whether the integer-code path and the
label-string path agree on inclusion, and surfaces exactly where they
disagree. This is a **diagnostic only** - it changes no data and picks
no winner. Use it to confirm (against real data) whether swapping the
current label-based scripts to
[`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md)
would change the analytic sample, before committing to that
consolidation.

## Usage

``` r
mysterycall_reconcile_inclusion(
  data,
  code_col = "exclusions",
  label_col = "reason_for_exclusions",
  id_col = NULL,
  set = c("logistic", "waittime"),
  inclusion_value = "Able to contact",
  logistic_include_codes = c(0L, 7L, 9L, 10L),
  crosswalk = NULL
)
```

## Arguments

- data:

  A data frame containing both `code_col` and `label_col`.

- code_col:

  Character scalar. Integer exclusion-code column. Default
  `"exclusions"`.

- label_col:

  Character scalar. Label-string column. Default
  `"reason_for_exclusions"`.

- id_col:

  Character scalar or `NULL`. Record identifier carried into the
  discrepancy table for follow-up. Default `NULL`.

- set:

  Which inclusion set to reconcile. `"logistic"` (default) compares the
  integer logistic set (`logistic_include_codes`) against the label
  included set - this is where the paths diverge. `"waittime"` compares
  the integer wait-time set (code 0) against the label included set,
  which are expected to agree.

- inclusion_value:

  Character scalar. Label value treated as included. Default
  `"Able to contact"`.

- logistic_include_codes:

  Integer vector forwarded to
  [`mysterycall_exclusion_crosswalk()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_crosswalk.md).
  Default `c(0L, 7L, 9L, 10L)`.

- crosswalk:

  A crosswalk tibble from
  [`mysterycall_exclusion_crosswalk()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_crosswalk.md).
  Built from `inclusion_value` and `logistic_include_codes` when not
  supplied.

## Value

A list of class `mysterycall_reconciliation` with elements:

- `set`:

  The set reconciled (`"logistic"` or `"waittime"`).

- `n`:

  Total rows compared.

- `n_agree`:

  Rows where both paths agree (both include or both exclude).

- `n_disagree`:

  Rows where the paths disagree.

- `agree_rate`:

  `n_agree / n`.

- `discrepancies`:

  Data frame of the disagreeing rows, with `disagreement_type`
  (`"code_only"` = integer path includes, label path excludes;
  `"label_only"` = the reverse), both keys, the code label, and `id_col`
  when supplied.

- `by_code`:

  Data frame: for each integer code, how many rows the label path
  counted as included vs excluded, and whether that matches the
  crosswalk expectation.

- `label_mismatches`:

  Data frame of rows whose `label_col` string is inconsistent with the
  crosswalk's expected string for their integer code (a data-entry
  integrity check independent of inclusion). `NULL` when none.

- `crosswalk`:

  The crosswalk used.

## Details

The data frame must carry **both** keys on the same rows: the integer
`exclusions` code (from the raw export) and the `reason_for_exclusions`
string (from the cleaned export). Reconciliation is the one scenario
where you have both.

## See also

[`mysterycall_exclusion_crosswalk()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_crosswalk.md),
[`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md),
[`mysterycall_acceptance_rate_calc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate_calc.md)

Other data-preparation:
[`mysterycall_exclusion_crosswalk()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_crosswalk.md),
[`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md),
[`print.mysterycall_prepared()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_prepared.md),
[`print.mysterycall_reconciliation()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_reconciliation.md)

## Examples

``` r
df <- data.frame(
  id                    = 1:6,
  exclusions            = c(0L, 0L, 9L, 7L, 5L, 10L),
  reason_for_exclusions = c(
    "Able to contact", "Able to contact",
    "Not accepting new patients",
    "Physician referral required before scheduling appointment",
    "Phone not answered or busy signal on repeat calls",
    "Must see midlevel first"
  ),
  stringsAsFactors = FALSE
)
rec <- mysterycall_reconcile_inclusion(df, id_col = "id")
#> mysterycall_reconcile_inclusion [logistic]: 3/6 rows agree (50.0%); 3 disagree (3 code_only, 0 label_only).
rec
#> === Inclusion Reconciliation [logistic set] ===
#> 
#> Rows compared:  6
#> Agree:          3 (50.0%)
#> Disagree:       3
#>   code_only  (integer includes, label excludes): 3
#>   label_only (label includes, integer excludes): 0
#> 
#> -- Discrepancies (first 10) --
#>  id disagreement_type code                 code_label
#>   3         code_only    9 Not accepting new patients
#>   4         code_only    7          Referral required
#>   6         code_only   10    Must see midlevel first
#>                                                      label included_by_code
#>                                 Not accepting new patients             TRUE
#>  Physician referral required before scheduling appointment             TRUE
#>                                    Must see midlevel first             TRUE
#>  included_by_label
#>              FALSE
#>              FALSE
#>              FALSE
#> 
#> -- Per-code label classification --
#>  code                 code_label n n_label_included n_label_excluded
#>     0                   Included 2                2                0
#>     5    Phone not answered/busy 1                0                1
#>     7          Referral required 1                0                1
#>     9 Not accepting new patients 1                0                1
#>    10    Must see midlevel first 1                0                1
#>  crosswalk_included
#>                TRUE
#>               FALSE
#>               FALSE
#>               FALSE
#>               FALSE
# Codes 9, 7, 10 are the divergence: integer-logistic includes them,
# the label path does not.
rec$discrepancies
#>   id disagreement_type code                 code_label
#> 1  3         code_only    9 Not accepting new patients
#> 2  4         code_only    7          Referral required
#> 3  6         code_only   10    Must see midlevel first
#>                                                       label included_by_code
#> 1                                Not accepting new patients             TRUE
#> 2 Physician referral required before scheduling appointment             TRUE
#> 3                                   Must see midlevel first             TRUE
#>   included_by_label
#> 1             FALSE
#> 2             FALSE
#> 3             FALSE
```
