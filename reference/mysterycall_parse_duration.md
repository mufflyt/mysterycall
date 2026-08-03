# Parse messy free-text call durations to a numeric unit

Mystery-caller logs capture hold time and call length as free text a
caller typed in a hurry – `"1.5min"`, `"1min 45 sec"`, `"30sec"`,
`"2min 30 sec"`, a bare `"90"`, an `"O"` meant as zero. Studies
routinely hand-build a lookup table of every variant they happen to see,
which is brittle and does not transfer to the next audit. This parses
the common forms directly: it sums any minute tokens (`N min`, `N m`)
and second tokens (`N sec`, `N s`) it finds, and falls back to treating
a bare number as `default_unit`.

## Usage

``` r
mysterycall_parse_duration(
  x,
  output_unit = c("seconds", "minutes"),
  default_unit = c("minutes", "seconds")
)
```

## Arguments

- x:

  Character (or numeric) vector of durations.

- output_unit:

  One of `"seconds"` (default) or `"minutes"`; the unit of the returned
  numbers.

- default_unit:

  One of `"minutes"` (default) or `"seconds"`; how to interpret an entry
  that is a bare number with no `min`/`sec` token (e.g. `"3"`). Set this
  to match the column's convention.

## Value

A numeric vector the length of `x`, in `output_unit`. Entries that are
missing, empty, or contain no recoverable number return `NA`.

## Details

Matching is case-insensitive. `"o"`/`"O"` alone (a common stand-in for
zero) parses to `0`. Decimals are supported in either token (`"2.75min"`
-\> 165 s). When both minute and second tokens are present they are
added (`"1min 45 sec"` -\> 105 s).

## See also

[`mysterycall_categorize_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_categorize_wait.md)

Other data integrity:
[`.mc_age_impute()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_impute.md),
[`.mc_age_key()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_key.md),
[`.mc_check_acs_vintage()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_acs_vintage.md),
[`.mc_data()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_data.md),
[`.mc_geo_layer()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geo_layer.md),
[`.mc_geocode_point()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_point.md),
[`.mc_healthgrades_ages()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_healthgrades_ages.md),
[`.mc_state_to_abbr()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_state_to_abbr.md),
[`mc-census-vintage`](https://mufflyt.github.io/mysterycall/reference/mc-census-vintage.md),
[`mysterycall_assign_area_covariates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_area_covariates.md),
[`mysterycall_categorize_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_categorize_wait.md),
[`mysterycall_clean_zip()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_zip.md),
[`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md),
[`mysterycall_link_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_link_physicians.md),
[`mysterycall_lookup_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lookup_age.md)

## Examples

``` r
mysterycall_parse_duration(
  c("1.5min", "1min 45 sec", "30sec", "O", "2.75min, 30sec", "3"),
  output_unit = "seconds"
)
#> [1]  90 105  30   0 195 180
# bare "3" as minutes -> 180 s; "O" -> 0
```
