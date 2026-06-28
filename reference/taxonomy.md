# Taxonomy Codes for Obstetricians and Gynecologists

This dataset contains taxonomy codes for Obstetricians and Gynecologists
among other healthcare providers.

## Format

A data frame with three columns:

- Code:

  NUCC (National Uniform Claim Committee) taxonomy code (character).

- Classification:

  Provider classification (e.g., "Allopathic & Osteopathic Physicians").

- Specialization:

  Specialty within the classification (e.g., "Obstetrics & Gynecology").

## Source

<https://www.nucc.org/images/stories/PDF/taxonomy_23_0.pdf>

## See also

[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md)
to look up provider taxonomy codes from the NPI registry;
[acgme](https://mufflyt.github.io/mysterycall/reference/acgme.md) for
ACGME residency program data.

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md)

## Examples

``` r
data(taxonomy)
print(taxonomy[1:3, ])
#> # A tibble: 3 × 3
#>   Code       Classification Specialization                    
#>   <chr>      <chr>          <chr>                             
#> 1 101Y00000X Counselor      NA                                
#> 2 101YA0400X Counselor      Addiction (Substance Use Disorder)
#> 3 101YM0800X Counselor      Mental Health                     
```
