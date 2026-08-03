# Clean and standardize ZIP codes to five digits

Two ZIP hygiene steps recur in every audit that joins practices to
ZIP-indexed data (income, rurality, HRR): a cell sometimes holds more
than one ZIP (`"03110, 03756"`), and New England / Puerto Rico ZIPs lose
their leading zero the moment the column is read as a number (`3110` for
`03110`). This takes the first ZIP when several are present, strips a
ZIP+4 suffix, and left-pads to five digits so the key joins correctly.

## Usage

``` r
mysterycall_clean_zip(x)
```

## Arguments

- x:

  Character or numeric vector of ZIP codes.

## Value

A character vector the length of `x`: a five-character ZIP, or `NA` for
entries with no digits.

## See also

[`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md).
Related ZIP helpers:
[`mysterycall_extract_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_zip5.md)
(strip ZIP+4 / pad, single-ZIP cells) and
[`mysterycall_normalize_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_zip5.md)
(address-pipeline variant). `clean_zip()` additionally splits multi-ZIP
cells (`"03110, 03756"` -\> first).

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
[`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md),
[`mysterycall_link_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_link_physicians.md),
[`mysterycall_lookup_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lookup_age.md),
[`mysterycall_parse_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_duration.md)

## Examples

``` r
mysterycall_clean_zip(c("03110, 03756", 3110, "12345-6789", "", NA))
#> [1] "03110" "03110" "12345" NA      NA     
# -> c("03110", "03110", "12345", NA, NA)
```
