# Build a propensity-score-matched control cohort

Many mystery-caller audits are case-control by design: a treated group
(private-equity-owned practices, hospital-acquired practices, a specific
chain) is compared against otherwise-similar controls. To make the
comparison fair – and to keep the call burden bounded – you match each
treated practice to a nearby, comparable control. This builds that
matched cohort: it fits a propensity model on the treated units versus a
candidate pool, then greedily matches each treated unit 1:1 to its
nearest control on the propensity score, within an exact stratum (e.g.
same state) and an optional geographic caliper, without replacement.

## Usage

``` r
mysterycall_build_matched_controls(
  treated,
  candidates,
  ps_formula,
  id_col,
  exact = NULL,
  coords = NULL,
  caliper_miles = 10,
  min_in_caliper = 1L,
  cluster_col = NULL,
  seed = 42
)
```

## Arguments

- treated:

  Data frame of treated units (one row per unit, unless `cluster_col` is
  set).

- candidates:

  Data frame of candidate controls. Must contain the propensity
  covariates, `id_col`, any `exact` columns, and (if used) the `coords`
  columns.

- ps_formula:

  A two-sided formula `treatment ~ x1 + x2 + ...`. The left-hand side
  names the treatment indicator this function creates internally (1 for
  `treated`, 0 for `candidates`); the right-hand side are the matching
  covariates, which must exist in both frames.

- id_col:

  Name of the unique identifier column (present in both frames).

- exact:

  Optional character vector of columns that a control must match the
  treated unit on exactly (e.g. `"state"`). Default `NULL`.

- coords:

  Optional length-2 character vector naming latitude and longitude
  columns (in both frames), used for the distance caliper. `NULL`
  disables the caliper. See
  [`mysterycall_geocode_city_state()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode_city_state.md)
  to populate them.

- caliper_miles:

  Maximum control distance in miles (haversine). Ignored when `coords`
  is `NULL`. Default `10`.

- min_in_caliper:

  Require at least this many candidates within the caliper before a
  treated unit is matched (guards against matching to an isolated
  control). Default `1`.

- cluster_col:

  Optional column identifying clusters (e.g. an office/site shared by
  several treated providers). When set, at most one treated unit per
  cluster is matched; units within a cluster are tried in random order
  until one matches.

- seed:

  Integer seed for the within-cluster shuffle (reproducibility). Default
  `42`.

## Value

An object of class `"mysterycall_matched_controls"`: a list with `pairs`
(a tibble: `pair_id`, `treated_id`, `control_id`, `ps_treated`,
`ps_control`, `ps_diff`, `distance_miles`), `matched_treated`,
`matched_controls` (the matched rows from each input), `ps_model` (the
fitted `glm`), `balance` (standardized mean differences for numeric
covariates, treated vs matched controls), and counts `n_treated`,
`n_matched`, `n_unmatched`.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
`pairs`.

## Details

The greedy nearest-neighbour scheme is the one audit teams actually use
when a control must be *callable* (same state, a short drive away),
which off-the- shelf matchers do not express directly. For unconstrained
statistical matching consider the MatchIt package instead.

## Examples

``` r
set.seed(1)
treated <- data.frame(
  npi = 1:20, state = sample(c("CO", "TX"), 20, TRUE),
  lat = runif(20, 39, 40), lon = runif(20, -105, -104),
  years = rpois(20, 12), female = rbinom(20, 1, 0.5))
candidates <- data.frame(
  npi = 101:400, state = sample(c("CO", "TX"), 300, TRUE),
  lat = runif(300, 39, 40), lon = runif(300, -105, -104),
  years = rpois(300, 10), female = rbinom(300, 1, 0.5))
m <- mysterycall_build_matched_controls(
  treated, candidates, treatment ~ years + female,
  id_col = "npi", exact = "state", coords = c("lat", "lon"),
  caliper_miles = 40)
m
#> <mysterycall matched controls: 20 of 20 treated matched (0 unmatched)>
#>   median control distance: 20.4 miles; max ps difference: 0.077
#> 
#> Covariate balance (standardized mean differences):
#> # A tibble: 2 × 4
#>   covariate mean_treated mean_control    smd
#>   <chr>            <dbl>        <dbl>  <dbl>
#> 1 years             11.8         11.8 0.0315
#> 2 female             0.4          0.4 0     
```
