# Bin physician ages into decade categories

Returns a character label for each age, using decade brackets suitable
for Table 1 demographic summaries. The break points match the standard
used in mystery caller studies: Under 30, 30-39, 40-49, 50-59, 60-69,
70+.

## Usage

``` r
mysterycall_age_category(
  age,
  breaks = c(30, 40, 50, 60, 70),
  labels = NULL,
  na_label = "Unknown",
  as_factor = FALSE
)
```

## Arguments

- age:

  Numeric vector of physician ages. `NA` values return `na_label`.

- breaks:

  Numeric vector of break points defining the category boundaries.
  Default `c(30, 40, 50, 60, 70)` produces six bins: `"<30"`, `"30-39"`,
  `"40-49"`, `"50-59"`, `"60-69"`, `"70+"`.

- labels:

  Character vector of length `length(breaks) + 1` giving the label for
  each bin. When `NULL` (default) labels are auto-generated from the
  break points.

- na_label:

  Character scalar used for `NA` inputs. Default `"Unknown"`.

- as_factor:

  Logical. When `TRUE` returns an ordered factor with levels in the
  order defined by `labels`. Default `FALSE`.

## Value

Character vector (or ordered factor) the same length as `age`.

## See also

[`mysterycall_impute_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_impute_age.md)

Other provider characteristics:
[`mysterycall_academic_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_academic_patterns.md),
[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md),
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
ages <- c(28, 35, 47, 55, 63, 72, NA)
mysterycall_age_category(ages)
#> [1] "<30"     "30-39"   "40-49"   "50-59"   "60-69"   "70+"     "Unknown"
# [1] "<30"     "30-39"   "40-49"   "50-59"   "60-69"   "70+"     "Unknown"
```
