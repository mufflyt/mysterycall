# Map US states to medical society districts and Census regions

Accepts state names (full or two-letter abbreviations, case-insensitive)
and returns the corresponding medical society district or Census region.
Three classification systems are supported:

## Usage

``` r
mysterycall_assign_region(
  state,
  system = c("acog", "aao_hns", "census"),
  na_label = "Unknown"
)
```

## Arguments

- state:

  Character vector of US state names or two-letter abbreviations. Mixed
  formats are accepted (e.g. `c("CO", "Texas", "new york")`).

- system:

  Character scalar specifying the classification system. One of `"acog"`
  (default), `"aao_hns"`, or `"census"`.

- na_label:

  Character scalar returned for unrecognized or `NA` inputs. Default
  `"Unknown"`.

## Value

Character vector the same length as `state`.

## Details

- **`"acog"`** – ACOG Districts I-XII (obstetrics/gynecology)

- **`"aao_hns"`** – AAO-HNS Districts 1-8 (otolaryngology)

- **`"census"`** – US Census Bureau regions: Northeast, Midwest, South,
  West

## See also

[`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md),
[`mysterycall_classify_medical_school()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_medical_school.md),
[`mysterycall_classify_ruca()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_ruca.md)
for other provider demographic classifications.

Other provider characteristics:
[`mysterycall_academic_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_academic_patterns.md),
[`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md),
[`mysterycall_classify_medical_school()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_medical_school.md),
[`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md),
[`mysterycall_classify_ruca()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_ruca.md),
[`mysterycall_collapse_rare()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_collapse_rare.md),
[`mysterycall_extract_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_physician_name.md),
[`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md),
[`mysterycall_government_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_government_patterns.md),
[`mysterycall_impute_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_impute_age.md),
[`mysterycall_most_common_gender()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_most_common_gender.md),
[`mysterycall_parse_certification_subspecialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_certification_subspecialty.md),
[`mysterycall_physician_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physician_age.md),
[`mysterycall_recode_credentials()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_recode_credentials.md),
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md),
[`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md)

## Examples

``` r
states <- c("CO", "Texas", "New York", "california", NA)

mysterycall_assign_region(states, system = "acog")
#> [1] "District VIII" "District XI"   "District II"   "District IX"  
#> [5] "Unknown"      
mysterycall_assign_region(states, system = "aao_hns")
#> [1] "District 7" "District 6" "District 2" "District 8" "Unknown"   
mysterycall_assign_region(states, system = "census")
#> [1] "West"      "South"     "Northeast" "West"      "Unknown"  
```
