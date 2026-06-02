# ACOG Districts Data

This dataset contains information about American College of
Obstetricians and Gynecologists (ACOG) districts, including their
two-letter state abbreviations and full state names.

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
[`cityStateToLatLong`](https://mufflyt.github.io/mysterycall/reference/cityStateToLatLong.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)

## Examples

``` r
# Load the ACOG Districts Data
data(ACOG_Districts)

# Inspect the dataset
print(ACOG_Districts)
#> # A tibble: 52 × 4
#>    State                ACOG_District Subregion     State_Abbreviations
#>    <chr>                <chr>         <chr>         <chr>              
#>  1 Alabama              District VII  District VII  AL                 
#>  2 Alaska               District VIII District VIII AK                 
#>  3 Arizona              District VIII District VIII AZ                 
#>  4 Arkansas             District VII  District VII  AR                 
#>  5 California           District IX   District IX   CA                 
#>  6 Colorado             District VIII District VIII CO                 
#>  7 Connecticut          District I    District I    CT                 
#>  8 Delaware             District IV   District IV   DE                 
#>  9 District of Columbia District IV   District IV   DC                 
#> 10 Florida              District XII  District XII  FL                 
#> # ℹ 42 more rows

# Get a summary of the dataset
summary(ACOG_Districts)
#>        State      ACOG_District     Subregion  State_Abbreviations
#>  Length   :52   Length   :52    Length   :52   Length   :52       
#>  N.unique :52   N.unique :11    N.unique :11   N.unique :52       
#>  N.blank  : 0   N.blank  : 0    N.blank  : 0   N.blank  : 0       
#>  Min.nchar: 4   Min.nchar:10    Min.nchar:10   Min.nchar: 2       
#>  Max.nchar:20   Max.nchar:13    Max.nchar:13   Max.nchar: 2       

# Perform data analysis and exploration
```
