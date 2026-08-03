# Flag near-duplicate cluster keys (likely mistyped grouping values)

A random-intercept mystery-caller analysis clusters calls by a practice
/ cluster key. When that key is entered by hand across data-collection
waves, a single mistyped character (`"Aurora Womens Health"` vs.
`"Aurora Women's Health"`) splits one practice into two, silently
corrupting the estimated random-effect variance and deflating every
paired denominator (see
[`mysterycall_scenario_coverage()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_coverage.md)).
Exact-duplicate checks
([`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md))
cannot catch this because the strings differ. This scans all unique keys
with an edit-distance
([`utils::adist()`](https://rdrr.io/r/utils/adist.html)) and returns the
pairs that are close enough to be worth a human's eyes – a loud safety
net rather than a silent singleton.

## Usage

``` r
mysterycall_flag_near_duplicate_keys(
  keys,
  max_edit = 4L,
  max_norm = 0.15,
  ignore_case = TRUE,
  output_dir = NA,
  filename = NA
)
```

## Arguments

- keys:

  Character vector of cluster keys (or a data-frame column). Missing and
  empty entries are dropped before comparison.

- max_edit:

  Integer. Flag a pair when its raw edit distance is at most this.
  Default `4L`.

- max_norm:

  Numeric in `[0, 1]`. Flag a pair when its normalized edit distance is
  at most this. Default `0.15`.

- ignore_case:

  Logical; compare case-insensitively. Default `TRUE`.

- output_dir, filename:

  Optional CSV export of the flagged pairs. `output_dir = NA` (default)
  skips writing; `NULL` writes to a session temp directory via
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per flagged pair – columns `key_a`, `key_b`,
`edit_distance` (integer), `norm_distance` (rounded to 3) – sorted by
`edit_distance` then `norm_distance`. Zero rows (with the same columns)
when nothing is flagged.

## Details

A pair is flagged when its raw edit distance is at most `max_edit`
**or** its length-normalized distance (edit distance / longer key
length) is at most `max_norm`. The `OR` catches both short keys a few
characters apart and long keys differing by a small fraction. Comparison
is case- and whitespace-insensitive by default; feed keys already run
through
[`mysterycall_normalize_org_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_org_name.md)
to cut false positives.

## See also

[`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md),
[`mysterycall_normalize_org_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_org_name.md),
[`mysterycall_scenario_coverage()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_coverage.md)

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
[`mysterycall_link_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_link_physicians.md),
[`mysterycall_lookup_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lookup_age.md),
[`mysterycall_parse_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_duration.md)

## Examples

``` r
keys <- c("Aurora Womens Health", "Aurora Women's Health",
          "Denver Fertility", "Boulder OBGYN")
mysterycall_flag_near_duplicate_keys(keys)
#> # A tibble: 1 × 4
#>   key_a                key_b                 edit_distance norm_distance
#>   <chr>                <chr>                         <int>         <dbl>
#> 1 Aurora Womens Health Aurora Women's Health             1         0.048
```
