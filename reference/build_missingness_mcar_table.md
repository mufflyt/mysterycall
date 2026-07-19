# Per-variable missingness table paired with Little's MCAR test

Computes a tidy per-variable missingness summary and, on the item-level
numeric subset, Little's MCAR test. Structural (missing-by-design)
variables are reported but excluded from the test.

## Usage

``` r
build_missingness_mcar_table(
  data,
  item_vars,
  structural_vars = character(0),
  var_labels = NULL,
  unknown_tokens = .MCAR_UNKNOWN_TOKENS,
  mcar_vars = NULL,
  run_mcar = TRUE,
  make_gt = FALSE,
  gt_title = "Variable Missingness and Little's MCAR Test"
)
```

## Arguments

- data:

  `[data.frame]` One row per analytic unit (e.g., per NPI).

- item_vars:

  `[character]` Variables whose missingness is item-level (MCAR is a
  meaningful question). These, when numeric, feed Little's test.

- structural_vars:

  `[character]` Variables missing by design (conditional on a subgroup).
  Reported, never tested. Default none.

- var_labels:

  `[named character]` Optional `var -> pretty label`. Unlabelled
  variables fall back to their name.

- unknown_tokens:

  `[character]` Lower-cased tokens treated as present-but-uninformative.
  Default `.MCAR_UNKNOWN_TOKENS`.

- mcar_vars:

  `[character|NULL]` Explicit variable set for Little's test. Default
  `NULL` = the numeric columns among `item_vars`.

- run_mcar:

  `[logical]` Run Little's test. Default `TRUE`.

- make_gt:

  `[logical]` Also return a `gt` table. Default `FALSE`.

- gt_title:

  `[character]` Title for the gt table.

## Value

A list with:

- missingness:

  tibble: variable, label, missingness_type, n_total, n_missing,
  pct_missing, n_unknown, n_informative, pct_informative.

- mcar:

  list: statistic, df, p.value, n_missing_patterns, vars_tested,
  n_rows_tested, note — or `NULL` if not run/possible.

- interpretation:

  character: calibrated narrative (structural vs item-level; large-N
  caveat).

- gt:

  a `gt_tbl` if `make_gt=TRUE` and gt is installed, else `NULL`.

## Examples

``` r
if (FALSE) { # \dontrun{
res <- build_missingness_mcar_table(
  data           = cohort,
  item_vars      = c("gender", "age_years", "state", "latitude", "longitude"),
  structural_vars= c("years_active", "retirement_year", "total_go"),
  var_labels     = c(gender = "Gender", age_years = "Age (years)")
)
res$missingness
res$mcar$statistic; res$mcar$p.value
cat(res$interpretation)
} # }
```
