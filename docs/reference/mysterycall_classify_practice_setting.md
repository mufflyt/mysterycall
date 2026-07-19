# Classify physician practice setting from facility/organization name

Applies a three-tier keyword search to facility or organization names:
Government \> Academic \> Private Practice. Government is checked first
so that VA and military facilities are not mis-classified as Academic
when their name also contains "Medical Center" or a university name. If
the name matches no pattern but is non-empty, it defaults to
`"Private Practice"`. Missing or empty values return `na_label`.

## Usage

``` r
mysterycall_classify_practice_setting(
  facility_name,
  academic_patterns = NULL,
  government_patterns = NULL,
  na_label = "Unknown"
)
```

## Arguments

- facility_name:

  Character vector of facility or organization names.

- academic_patterns:

  Character vector of lower-case substrings (or regex patterns)
  indicating academic affiliation. When `NULL` (default) the built-in
  list of 40+ patterns is used. Supply your own vector to override
  completely; use `c(mysterycall_academic_patterns(), "my term")` to
  extend.

- government_patterns:

  Character vector of lower-case patterns for government/military
  settings. `NULL` uses the built-in list.

- na_label:

  Character scalar returned for `NA` or blank input. Default
  `"Unknown"`.

## Value

Character vector the same length as `facility_name` with values
`"Academic"`, `"Government"`, `"Private Practice"`, or `na_label`.

## Details

This is a pure-R, vectorized function with no package dependencies
beyond base R.

## See also

[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md),
[`mysterycall_classify_medical_school()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_medical_school.md),
[`mysterycall_classify_ruca()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_ruca.md),
[`mysterycall_academic_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_academic_patterns.md),
[`mysterycall_government_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_government_patterns.md)
for related provider characterization helpers.

Other provider characteristics:
[`mysterycall_academic_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_academic_patterns.md),
[`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md),
[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md),
[`mysterycall_classify_medical_school()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_medical_school.md),
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
names <- c(
  "University of Colorado Medical Center",
  "VA Medical Center Denver",
  "Denver ENT Associates LLC",
  NA
)
mysterycall_classify_practice_setting(names)
#> [1] "Academic"         "Government"       "Private Practice" "Unknown"         
```
