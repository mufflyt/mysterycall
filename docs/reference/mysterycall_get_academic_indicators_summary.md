# Export Academic Indicator Summary

Creates a comprehensive summary report of all available academic
indicators, organized by evidence tier.

## Usage

``` r
mysterycall_get_academic_indicators_summary()
```

## Value

A named list with elements:

- `module_version`:

  Character. Package version string.

- `created_date`:

  Character. ISO date string (YYYY-MM-DD).

- `indicators`:

  Named list with three sublists: `tier1_education_training`,
  `tier2_research_clinical`, and `tier3_name_patterns`, each containing
  confidence ranges and indicator scores.

- `total_known_institutions`:

  Integer. Count of known academic institutions in the bundled lookup.

- `total_patterns`:

  Integer. Count of name-pattern rules.

- `usage_notes`:

  Character vector. Recommended usage guidelines.

## See also

[`mysterycall_classify_academic_affiliation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_academic_affiliation.md),
[`mysterycall_check_academic_name_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_academic_name_patterns.md)

Other academic-indicators:
[`ACADEMIC_HOSPITAL_PATTERNS`](https://mufflyt.github.io/mysterycall/reference/ACADEMIC_HOSPITAL_PATTERNS.md),
[`ACGME_PROGRAM_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/ACGME_PROGRAM_INDICATORS.md),
[`COTH_TEACHING_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/COTH_TEACHING_INDICATORS.md),
[`KNOWN_ACADEMIC_INSTITUTIONS`](https://mufflyt.github.io/mysterycall/reference/KNOWN_ACADEMIC_INSTITUTIONS.md),
[`MEDICAL_SCHOOL_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICAL_SCHOOL_INDICATORS.md),
[`MEDICARE_GME_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICARE_GME_INDICATORS.md),
[`NCI_CANCER_CENTERS`](https://mufflyt.github.io/mysterycall/reference/NCI_CANCER_CENTERS.md),
[`NIH_CTSA_HUBS`](https://mufflyt.github.io/mysterycall/reference/NIH_CTSA_HUBS.md),
[`mysterycall_check_academic_name_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_academic_name_patterns.md),
[`mysterycall_classify_academic_affiliation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_academic_affiliation.md)

## Examples

``` r
summary <- mysterycall:::mysterycall_get_academic_indicators_summary()
summary$total_known_institutions
#> [1] 21
names(summary$indicators)
#> [1] "tier1_education_training" "tier2_research_clinical" 
#> [3] "tier3_name_patterns"     
```
