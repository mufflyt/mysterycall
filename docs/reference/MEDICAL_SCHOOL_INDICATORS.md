# Medical School Affiliation Patterns

String patterns indicating medical school affiliation. Confidence: 0.97.

## Usage

``` r
MEDICAL_SCHOOL_INDICATORS
```

## Format

Character vector of medical school text patterns.

## Value

A character vector of patterns indicating medical school affiliation.

## See also

[`mysterycall_classify_academic_affiliation`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_academic_affiliation.md)

Other academic-indicators:
[`ACADEMIC_HOSPITAL_PATTERNS`](https://mufflyt.github.io/mysterycall/reference/ACADEMIC_HOSPITAL_PATTERNS.md),
[`ACGME_PROGRAM_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/ACGME_PROGRAM_INDICATORS.md),
[`COTH_TEACHING_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/COTH_TEACHING_INDICATORS.md),
[`KNOWN_ACADEMIC_INSTITUTIONS`](https://mufflyt.github.io/mysterycall/reference/KNOWN_ACADEMIC_INSTITUTIONS.md),
[`MEDICARE_GME_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICARE_GME_INDICATORS.md),
[`NCI_CANCER_CENTERS`](https://mufflyt.github.io/mysterycall/reference/NCI_CANCER_CENTERS.md),
[`NIH_CTSA_HUBS`](https://mufflyt.github.io/mysterycall/reference/NIH_CTSA_HUBS.md),
[`mysterycall_check_academic_name_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_academic_name_patterns.md),
[`mysterycall_classify_academic_affiliation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_academic_affiliation.md),
[`mysterycall_get_academic_indicators_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_academic_indicators_summary.md)

## Examples

``` r
MEDICAL_SCHOOL_INDICATORS
#> [1] "SCHOOL OF MEDICINE"              "MEDICAL SCHOOL"                 
#> [3] "COLLEGE OF MEDICINE"             "MEDICAL COLLEGE"                
#> [5] "AFFILIATED WITH.*MEDICAL SCHOOL" "AFFILIATED WITH.*UNIVERSITY"    
```
