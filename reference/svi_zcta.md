# Social Vulnerability Index (SVI) by ZCTA

National CDC/ATSDR Social Vulnerability Index for every US ZIP Code
Tabulation Area (ZCTA), computed from American Community Survey (ACS)
5-year estimates with findSVI (`findSVI::find_svi()`), which reproduces
the CDC/ATSDR SVI theme and overall percentile ranks. Keyed on ZCTA
(which corresponds closely to a mailing ZIP), it joins to a physician's
practice ZIP directly, without a tract crosswalk.

## Format

A data frame with about 33,800 rows and 7 columns:

- zcta:

  Five-digit ZIP Code Tabulation Area, as a character string (leading
  zeros preserved).

- svi:

  Overall SVI percentile rank (CDC `RPL_themes`), 0-1; higher = more
  vulnerable.

- svi_socioeconomic:

  Theme 1 – Socioeconomic Status percentile rank (CDC `RPL_theme1`).

- svi_household:

  Theme 2 – Household Characteristics percentile rank (CDC
  `RPL_theme2`).

- svi_minority:

  Theme 3 – Racial and Ethnic Minority Status percentile rank (CDC
  `RPL_theme3`).

- svi_housing_transport:

  Theme 4 – Housing Type and Transportation percentile rank (CDC
  `RPL_theme4`).

- year:

  ACS 5-year vintage end year (2022 = 2018-2022).

## Source

American Community Survey 5-year estimates (US Census Bureau),
summarised by the CDC/ATSDR Social Vulnerability Index methodology as
implemented in findSVI. See
<https://www.atsdr.cdc.gov/placeandhealth/svi/> for the reference
methodology.

## Details

Values are national percentile ranks in `[0, 1]`; higher = more socially
vulnerable. The overall index (`svi`) is the rank of the sum of the four
theme ranks. About 2% of ZCTAs have `NA` (ACS input suppressed or zero
population).

Regenerate with `data-raw/svi_zcta.R` (requires a Census API key in
`CENSUS_API_KEY`). Ranks are national; because findSVI recomputes them
from ACS rather than downloading the CDC release, small differences from
the official CDC ZCTA tables are possible, chiefly at suppressed or
low-population areas.

## See also

[`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md)
for the companion Area Deprivation Index at the same geography.

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`healthgrades_ages`](https://mufflyt.github.io/mysterycall/reference/healthgrades_ages.md),
[`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md),
[`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md),
[`medicaid_fee_index`](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md),
[`zcta_tract_xwalk`](https://mufflyt.github.io/mysterycall/reference/zcta_tract_xwalk.md)

## Examples

``` r
data(svi_zcta)

# Attach SVI to study physicians by practice ZIP (as a 5-digit character)
# study$zcta <- sprintf("%05s", study$practice_zip)
# study <- merge(study, svi_zcta[, c("zcta", "svi")], by = "zcta", all.x = TRUE)
```
