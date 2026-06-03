# Recode raw physician credential strings to MD, DO, or Other

Normalizes the messy free-text values found in NPPES
`Provider.Credential.Text` (and similar fields) to one of three
canonical labels. Matching is case-insensitive; MD is checked before DO
so that `"MD/PhD"` maps to `"MD"` rather than falling through.

## Usage

``` r
mysterycall_recode_credentials(x, other_label = "Other")
```

## Arguments

- x:

  Character vector of raw credential strings.

- other_label:

  Character scalar returned when neither MD nor DO pattern matches.
  Default `"Other"`. This label covers all non-physician credentials
  such as PA, NP, RN, DDS, DMD, MBBS, and any unrecognised free-text
  strings.

## Value

Character vector the same length as `x`. `NA` inputs return `NA`.

## Details

Recognised patterns:

- `"MD"`:

  `M.D.`, `MD`, `MD/PhD`, `MD-PhD`, `MD, PhD`, `doctor of medicine`,
  `allopathic`

- `"DO"`:

  `D.O.`, `DO`, `D.O.M.`, `osteopathic`

- `"Other"`:

  everything else (PA, NP, RN, DDS, DMD, MBBS, ...)

## See also

Other provider characteristics:
[`mysterycall_academic_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_academic_patterns.md),
[`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md),
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
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md),
[`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md)

## Examples

``` r
creds <- c("M.D.", "DO", "MD/PhD", "D.O.", "PA-C", "MBBS", NA)
mysterycall_recode_credentials(creds)
#> Error in mysterycall_recode_credentials(creds): could not find function "mysterycall_recode_credentials"
```
