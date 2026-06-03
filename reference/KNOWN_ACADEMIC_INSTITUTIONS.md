# Known Academic Medical Centers

High-confidence list of major academic institution name patterns for
string matching. Includes Tier 1 (major research universities), Tier 2
(university hospitals), and Tier 3 (academic medical centers).

## Usage

``` r
KNOWN_ACADEMIC_INSTITUTIONS
```

## Format

Character vector of institution name patterns. Matches are performed
case-insensitively using `grepl(fixed = TRUE)`.

## Value

A character vector of institution name patterns used for academic
affiliation classification.

## See also

[`mysterycall_check_academic_name_patterns`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_academic_name_patterns.md),
[`ACADEMIC_HOSPITAL_PATTERNS`](https://mufflyt.github.io/mysterycall/reference/ACADEMIC_HOSPITAL_PATTERNS.md)

Other academic-indicators:
[`ACADEMIC_HOSPITAL_PATTERNS`](https://mufflyt.github.io/mysterycall/reference/ACADEMIC_HOSPITAL_PATTERNS.md),
[`ACGME_PROGRAM_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/ACGME_PROGRAM_INDICATORS.md),
[`COTH_TEACHING_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/COTH_TEACHING_INDICATORS.md),
[`MEDICAL_SCHOOL_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICAL_SCHOOL_INDICATORS.md),
[`MEDICARE_GME_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICARE_GME_INDICATORS.md),
[`NCI_CANCER_CENTERS`](https://mufflyt.github.io/mysterycall/reference/NCI_CANCER_CENTERS.md),
[`NIH_CTSA_HUBS`](https://mufflyt.github.io/mysterycall/reference/NIH_CTSA_HUBS.md),
[`mysterycall_check_academic_name_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_academic_name_patterns.md),
[`mysterycall_classify_academic_affiliation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_academic_affiliation.md),
[`mysterycall_get_academic_indicators_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_academic_indicators_summary.md)

## Examples

``` r
head(KNOWN_ACADEMIC_INSTITUTIONS)
#> Error: object 'KNOWN_ACADEMIC_INSTITUTIONS' not found
```
