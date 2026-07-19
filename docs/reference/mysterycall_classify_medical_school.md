# Classify medical school as US_MD, US_DO, CAN_MD, or IMG

Uses pattern matching against curated lists of osteopathic programs,
Canadian medical schools, and international medical school indicators.
Classification priority: DO \> CAN_MD \> IMG \> US_MD. Schools that do
not match any pattern are assumed to be US allopathic (US_MD).

## Usage

``` r
mysterycall_classify_medical_school(school_name, na_label = "Unknown")
```

## Arguments

- school_name:

  Character vector of medical school names as they appear in CMS
  Physician Compare or NPPES data.

- na_label:

  Character scalar returned for `NA` or empty inputs. Default
  `"Unknown"`.

## Value

Character vector the same length as `school_name` with values `"US_MD"`,
`"US_DO"`, `"CAN_MD"`, `"IMG"`, or `na_label`.

## See also

[`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md),
[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md),
[`mysterycall_classify_ruca()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_ruca.md)
for related provider characterization functions.

Other provider characteristics:
[`mysterycall_academic_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_academic_patterns.md),
[`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md),
[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md),
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
schools <- c(
  "University of Colorado School of Medicine",
  "Philadelphia College of Osteopathic Medicine",
  "McGill University Faculty of Medicine",
  "Ross University School of Medicine",
  NA
)
mysterycall_classify_medical_school(schools)
#> [1] "US_MD"   "US_DO"   "CAN_MD"  "IMG"     "Unknown"
```
