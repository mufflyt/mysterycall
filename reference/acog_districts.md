# ACOG Districts Data

This dataset contains information about American College of
Obstetricians and Gynecologists (ACOG) districts, including their
two-letter state abbreviations and full state names. It is useful for
grouping states into regional districts for subgroup analysis in mystery
caller studies.

## Format

A data frame with the following columns:

- State:

  Full name of the US state.

- ACOG_District:

  ACOG district designation (Roman numeral or letter code).

- Subregion:

  Geographic subregion within the ACOG district.

- State_Abbreviations:

  Two-letter US state abbreviation.

## Source

Data was obtained from the official ACOG website:
<https://www.acog.org/community/districts-and-sections>

## Value

A tibble where each row represents an ACOG district with its
corresponding two-letter abbreviation and full state name.

## See also

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md),
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
# Load the ACOG Districts Data
data(acog_districts)

# Inspect the dataset
head(acog_districts)
#> # A tibble: 6 × 4
#>   State      ACOG_District Subregion     State_Abbreviations
#>   <chr>      <chr>         <chr>         <chr>              
#> 1 Alabama    District VII  District VII  AL                 
#> 2 Alaska     District VIII District VIII AK                 
#> 3 Arizona    District VIII District VIII AZ                 
#> 4 Arkansas   District VII  District VII  AR                 
#> 5 California District IX   District IX   CA                 
#> 6 Colorado   District VIII District VIII CO                 

# Group by district
table(acog_districts$ACOG_District)
#> 
#>    District I   District II  District III   District IV   District IX 
#>             6             1             2             9             1 
#>    District V   District VI  District VII District VIII   District XI 
#>             4             7             8            12             1 
#>  District XII 
#>             1 
```
