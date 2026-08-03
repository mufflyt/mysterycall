# Two-part hurdle model for a mystery-caller wait time

Mystery-caller wait times have a two-part structure: an appointment is
either obtained or not (the "hurdle"), and *conditional on* obtaining
one, the wait is a right-skewed count of days. This fits both parts and
returns them together: a binary hurdle model for whether an appointment
was obtained, and a (zero-truncated) negative-binomial model for the
wait among obtained appointments. Both parts accept a practice random
intercept, so the paired / clustered structure of an audit is respected
– an advantage over `pscl::hurdle()`, which cannot cluster.

## Usage

``` r
mysterycall_hurdle_wait(
  data,
  obtained_col,
  wait_col,
  predictors,
  random_intercept = NULL,
  count_family = c("nbinom2", "poisson"),
  truncate_zero = TRUE,
  conf_level = 0.95
)
```

## Arguments

- data:

  A data frame, one row per call.

- obtained_col:

  Name of the binary "appointment obtained" column (the hurdle outcome).
  Coerced with `%in% TRUE`/`1`/`"TRUE"`/`"Yes"`.

- wait_col:

  Name of the wait-time count column: a non-negative numeric (defined
  among obtained appointments; `NA`/missing otherwise).

- predictors:

  Character vector of unique predictor columns, used in both parts. Must
  not include `obtained_col` or `wait_col`.

- random_intercept:

  Optional name of a clustering column (e.g. practice) for a random
  intercept in both parts. `NULL` fits fixed-effects-only.

- count_family:

  Working family for the count part: `"nbinom2"` (default) or
  `"poisson"`.

- truncate_zero:

  If `TRUE` (default) model the wait with a **zero- truncated** count
  distribution fit on waits `> 0` (the hurdle already carries the
  not-obtained cases); if `FALSE` keep same-day (0-day) waits and fit an
  untruncated count model.

- conf_level:

  Confidence level for the reported intervals. Default `0.95`.

## Value

An object of class `"mysterycall_hurdle_wait"`: a list with `hurdle` (a
tibble of odds ratios for the obtainment part) and `count` (a tibble of
incidence-rate ratios for the wait part), each with `term`, `estimate`,
`conf_low`, `conf_high`, `p_value`, plus `n_hurdle`, `n_count`, and the
fitted `hurdle_model` / `count_model`.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the two tables stacked with a `part` column. Requires the glmmTMB
package.

## Details

A hurdle model is the natural default when the wait is right-skewed: the
negative-binomial count part absorbs the skew and overdispersion that a
normal-outcome selection (Heckman) model cannot. It assumes the two
parts are separable given the covariates (selection on observables);
address any residual selection-on-unobservables concern with a
sensitivity analysis –
[`mysterycall_outcome_bounds()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_outcome_bounds.md)
(Manski bounds on the obtainment rate) or
[`mysterycall_leave_one_out()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_leave_one_out.md)
– rather than forcing a Heckman correction.

## Examples

``` r
# \donttest{
set.seed(1)
d <- data.frame(
  practice  = rep(sprintf("p%03d", 1:150), each = 2),
  insurance = rep(c("Commercial", "Medicaid"), 150),
  obtained  = rbinom(300, 1, 0.65))
d$wait_days <- ifelse(d$obtained == 1, rnbinom(300, mu = 16, size = 2), NA)
mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                        random_intercept = "practice")
#> <mysterycall hurdle wait model: hurdle n=300, count n=204 (zero-truncated nbinom2)>
#> 
#> Hurdle part -- appointment obtained (odds ratios):
#> # A tibble: 2 × 5
#>   term              estimate conf_low conf_high  p_value
#>   <chr>                <dbl>    <dbl>     <dbl>    <dbl>
#> 1 (Intercept)           1.94    1.38       2.72 0.000119
#> 2 insuranceMedicaid     1.24    0.762      2.02 0.385   
#> 
#> Count part -- wait days | obtained (incidence rate ratios):
#> # A tibble: 2 × 5
#>   term              estimate conf_low conf_high   p_value
#>   <chr>                <dbl>    <dbl>     <dbl>     <dbl>
#> 1 (Intercept)         14.9     12.6       17.6  7.98e-223
#> 2 insuranceMedicaid    0.935    0.753      1.16 5.42e-  1
# }
```
