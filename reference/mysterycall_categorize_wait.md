# Bin a wait-time-to-appointment into weekly categories and a threshold flag

Audit results are usually reported two ways: an ordered set of weekly
bins (how the wait distribution is shaped) and a single
clinically-meaningful binary threshold – classically "more than a
two-week wait", the headline access outcome. This standardizes both from
a numeric days-to-appointment vector so the "\>N-week" convention is
defined once instead of re-derived with a fresh
[`cut()`](https://rdrr.io/r/base/cut.html) in every analysis.

## Usage

``` r
mysterycall_categorize_wait(
  x,
  threshold_days = 14,
  bin_width = 7,
  max_bin = 28
)
```

## Arguments

- x:

  Numeric vector of business days (or calendar days) until the
  appointment.

- threshold_days:

  Numeric. The binary cutoff; `over_threshold` is `TRUE` when
  `x > threshold_days`. Default `14` (a two-week wait).

- bin_width:

  Numeric. Width of each ordered bin in days. Default `7` (weekly).

- max_bin:

  Numeric. The last finite bin edge; values above it fall in a single
  top `"> max_bin"` bin. Default `28`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
the length of `x` with columns `days` (the input), `bin` (an ordered
factor of weekly categories), and `over_threshold` (logical). `NA` days
give `NA` in both derived columns.

## See also

[`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md),
[`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md)

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
[`mysterycall_clean_zip()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_zip.md),
[`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md),
[`mysterycall_link_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_link_physicians.md),
[`mysterycall_lookup_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lookup_age.md),
[`mysterycall_parse_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_duration.md)

## Examples

``` r
mysterycall_categorize_wait(c(3, 10, 15, 30, NA))
#> # A tibble: 5 × 3
#>    days bin   over_threshold
#>   <dbl> <ord> <lgl>         
#> 1     3 0-7   FALSE         
#> 2    10 8-14  FALSE         
#> 3    15 15-21 TRUE          
#> 4    30 > 28  TRUE          
#> 5    NA NA    NA            
```
