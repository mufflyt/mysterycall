# Classify Academic vs. Non-Academic Practice Setting

Combines organization name patterns, optional hospital affiliation data,
and optional specialty-based adjustments to classify academic vs.
non-academic practice settings using a weighted scoring system.

## Usage

``` r
mysterycall_classify_academic_affiliation(
  org_name,
  hospital_affiliation = NULL,
  specialty = NULL
)
```

## Arguments

- org_name:

  Character vector of organization names to classify.

- hospital_affiliation:

  Character vector or NULL. Optional hospital affiliation names for
  additional pattern matching. Must be same length as `org_name` if
  provided. Default: `NULL`.

- specialty:

  Character vector or NULL. Optional physician specialties.
  Research-intensive specialties receive a 0.05 confidence boost. Must
  be same length as `org_name` if provided. Default: `NULL`.

## Value

Data frame with one row per input and columns:

- academic_classification:

  Character. "Academic" or "Non-Academic".

- confidence_score:

  Numeric. Confidence in the classification (0-1).

- matched_pattern:

  Character. Highest-scoring pattern match, or NA.

## See also

[`mysterycall_check_academic_name_patterns`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_academic_name_patterns.md),
[`mysterycall_get_academic_indicators_summary`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_academic_indicators_summary.md)

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
[`mysterycall_get_academic_indicators_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_academic_indicators_summary.md)

## Examples

``` r
mysterycall:::mysterycall_classify_academic_affiliation("University of Michigan Medical Center")
#>   academic_classification confidence_score               matched_pattern
#> 1                Academic             0.99 KNOWN_ACADEMIC: UNIVERSITY OF
mysterycall:::mysterycall_classify_academic_affiliation("Community Regional Hospital")
#>   academic_classification confidence_score matched_pattern
#> 1            Non-Academic                0            <NA>
```
