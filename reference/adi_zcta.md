# Area Deprivation Index (ADI) by ZCTA

National Area Deprivation Index for every US ZIP Code Tabulation Area
(ZCTA), computed from American Community Survey (ACS) 5-year estimates
with sociome (`sociome::get_adi()`), which reproduces the Singh ADI via
the Kolak et al. three-factor decomposition. Because it is keyed on ZCTA
(which corresponds closely to a mailing ZIP), it joins to a physician's
practice ZIP directly, without a tract crosswalk.

## Format

A data frame with about 33,800 rows and 6 columns:

- zcta:

  Five-digit ZIP Code Tabulation Area, as a character string (leading
  zeros preserved).

- adi:

  National linear Area Deprivation Index; higher = more deprived,
  roughly mean 100 / SD 20. `NA` where ACS inputs were suppressed.

- adi_financial_strength:

  Financial Strength factor score (one of the three Kolak et al. ADI
  sub-domains).

- adi_economic_hardship:

  Economic Hardship and Inequality factor score.

- adi_education:

  Educational Attainment factor score.

- year:

  ACS 5-year vintage end year (2022 = 2018-2022).

## Source

American Community Survey 5-year estimates (US Census Bureau),
summarised by the Area Deprivation Index of Singh (2003) as implemented
in sociome: Kolak, Bhatt, Park, Padron & Molefe (2020), "Quantification
of Neighborhood-Level Social Determinants of Health in the Continental
United States," *JAMA Network Open* 3(1):e1919928.

## Details

The index is national and relative: higher values indicate greater
neighbourhood socioeconomic deprivation. sociome scales the linear ADI
to approximately mean 100 / standard deviation 20 across the areas
supplied (here, all US ZCTAs). Roughly 3% of ZCTAs have `NA` ADI because
the ACS suppressed one or more input variables for that area.

Regenerate with `data-raw/adi_zcta.R` (requires a Census API key in
`CENSUS_API_KEY`). Advancing the ACS vintage or the ZCTA set will change
the relative scaling, so ADI values are comparable only within a single
build.

## See also

[`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md)
for the companion CDC Social Vulnerability Index at the same geography.

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`healthgrades_ages`](https://mufflyt.github.io/mysterycall/reference/healthgrades_ages.md),
[`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md),
[`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md),
[`medicaid_fee_index`](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md),
[`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md),
[`zcta_tract_xwalk`](https://mufflyt.github.io/mysterycall/reference/zcta_tract_xwalk.md)

## Examples

``` r
data(adi_zcta)

# Attach ADI to study physicians by practice ZIP (as a 5-digit character)
# study$zcta <- sprintf("%05s", study$practice_zip)
# study <- merge(study, adi_zcta[, c("zcta", "adi")], by = "zcta", all.x = TRUE)
```
