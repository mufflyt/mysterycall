# Check if Organization Name Suggests Academic Affiliation

Evaluates organization names against known academic institutions and
tiered pattern lists to determine academic affiliation probability.
Returns the highest confidence match found.

## Usage

``` r
mysterycall_check_academic_name_patterns(org_name, confidence_threshold = 0.85)
```

## Arguments

- org_name:

  Character vector of organization names to evaluate.

- confidence_threshold:

  Numeric. Minimum confidence level to classify as academic. Scores
  below this threshold are zeroed out. Default: `0.85`.

## Value

Data frame with one row per input name and columns:

- academic_indicator:

  Logical. TRUE if name matches an academic pattern at or above the
  confidence threshold.

- confidence_score:

  Numeric. Highest confidence score (0.0-0.99).

- matched_pattern:

  Character. Description of the matching pattern. NA if no match.

## See also

[`mysterycall_classify_academic_affiliation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_academic_affiliation.md)

Other academic-indicators:
[`ACADEMIC_HOSPITAL_PATTERNS`](https://mufflyt.github.io/mysterycall/reference/ACADEMIC_HOSPITAL_PATTERNS.md),
[`ACGME_PROGRAM_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/ACGME_PROGRAM_INDICATORS.md),
[`COTH_TEACHING_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/COTH_TEACHING_INDICATORS.md),
[`KNOWN_ACADEMIC_INSTITUTIONS`](https://mufflyt.github.io/mysterycall/reference/KNOWN_ACADEMIC_INSTITUTIONS.md),
[`MEDICAL_SCHOOL_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICAL_SCHOOL_INDICATORS.md),
[`MEDICARE_GME_INDICATORS`](https://mufflyt.github.io/mysterycall/reference/MEDICARE_GME_INDICATORS.md),
[`NCI_CANCER_CENTERS`](https://mufflyt.github.io/mysterycall/reference/NCI_CANCER_CENTERS.md),
[`NIH_CTSA_HUBS`](https://mufflyt.github.io/mysterycall/reference/NIH_CTSA_HUBS.md),
[`mysterycall_classify_academic_affiliation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_academic_affiliation.md),
[`mysterycall_get_academic_indicators_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_academic_indicators_summary.md)

## Examples

``` r
mysterycall:::mysterycall_check_academic_name_patterns(c("Johns Hopkins Hospital",
                               "Community Hospital",
                               "University of Michigan Medical Center"))
#>   academic_indicator confidence_score               matched_pattern
#> 1               TRUE             0.99 KNOWN_ACADEMIC: JOHNS HOPKINS
#> 2              FALSE             0.00                          <NA>
#> 3               TRUE             0.99 KNOWN_ACADEMIC: UNIVERSITY OF
```
