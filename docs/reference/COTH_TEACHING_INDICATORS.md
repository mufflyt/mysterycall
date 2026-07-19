# COTH (Council of Teaching Hospitals) Indicators

String patterns indicating Council of Teaching Hospitals membership.
Confidence: 0.95.

## Usage

``` r
COTH_TEACHING_INDICATORS
```

## Format

Character vector of COTH-related text patterns.

## Value

A character vector of patterns indicating Council of Teaching Hospitals
membership.

## See also

[`mysterycall_classify_academic_affiliation`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_academic_affiliation.md)

Other academic-indicators:
[`ACADEMIC_HOSPITAL_PATTERNS`](https://mufflyt.github.io/mysterycall/reference/ACADEMIC_HOSPITAL_PATTERNS.md),
[`ACGME_PROGRAM_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/ACGME_PROGRAM_INDICATORS.md),
[`KNOWN_ACADEMIC_INSTITUTIONS`](https://mufflyt.github.io/mysterycall/reference/KNOWN_ACADEMIC_INSTITUTIONS.md),
[`MEDICAL_SCHOOL_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICAL_SCHOOL_INDICATORS.md),
[`MEDICARE_GME_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICARE_GME_INDICATORS.md),
[`NCI_CANCER_CENTERS`](https://mufflyt.github.io/mysterycall/reference/NCI_CANCER_CENTERS.md),
[`NIH_CTSA_HUBS`](https://mufflyt.github.io/mysterycall/reference/NIH_CTSA_HUBS.md),
[`mysterycall_check_academic_name_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_academic_name_patterns.md),
[`mysterycall_classify_academic_affiliation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_academic_affiliation.md),
[`mysterycall_get_academic_indicators_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_academic_indicators_summary.md)

## Examples

``` r
COTH_TEACHING_INDICATORS
#> [1] "TEACHING HOSPITAL"             "COUNCIL OF TEACHING HOSPITALS"
#> [3] "COTH MEMBER"                   "AAMC MEMBER"                  
```
