# Academic Hospital Name Patterns

Tiered list of string patterns indicating academic hospital affiliation,
organized by confidence level: very_high (0.95-0.99), high (0.85-0.94),
and moderate (0.75-0.84).

## Usage

``` r
ACADEMIC_HOSPITAL_PATTERNS
```

## Format

Named list with three character vector elements:

- very_high:

  Patterns at confidence 0.95 (e.g., "SCHOOL OF MEDICINE").

- high:

  Patterns at confidence 0.90 (e.g., "UNIVERSITY HOSPITAL").

- moderate:

  Patterns at confidence 0.80 (e.g., "MEDICAL CENTER").

## Value

A named list of character vectors of hospital name patterns, grouped by
confidence tier.

## See also

[`mysterycall_check_academic_name_patterns`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_academic_name_patterns.md),
[`KNOWN_ACADEMIC_INSTITUTIONS`](https://mufflyt.github.io/mysterycall/reference/KNOWN_ACADEMIC_INSTITUTIONS.md)

Other academic-indicators:
[`ACGME_PROGRAM_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/ACGME_PROGRAM_INDICATORS.md),
[`COTH_TEACHING_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/COTH_TEACHING_INDICATORS.md),
[`KNOWN_ACADEMIC_INSTITUTIONS`](https://mufflyt.github.io/mysterycall/reference/KNOWN_ACADEMIC_INSTITUTIONS.md),
[`MEDICAL_SCHOOL_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICAL_SCHOOL_INDICATORS.md),
[`MEDICARE_GME_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICARE_GME_INDICATORS.md),
[`NCI_CANCER_CENTERS`](https://mufflyt.github.io/mysterycall/reference/NCI_CANCER_CENTERS.md),
[`NIH_CTSA_HUBS`](https://mufflyt.github.io/mysterycall/reference/NIH_CTSA_HUBS.md),
[`mysterycall_check_academic_name_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_academic_name_patterns.md),
[`mysterycall_classify_academic_affiliation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_academic_affiliation.md),
[`mysterycall_get_academic_indicators_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_academic_indicators_summary.md)
