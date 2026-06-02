# Impute physician age from medical school graduation year

Estimates a physician's current age as: \$\$\text{age} =
(\text{ref\\year} - \text{grad\\year}) + \text{age\\offset}\$\$ where
`age_offset` (default 27) is the median age at US medical school
graduation. This method has been validated against Doximity birth-year
data for 32,998 OB/GYN physicians (r = 0.962, MAE = 2.1 years) and 348
ENT physicians (r = 0.957, MAE = 1.7 years); see the technical appendix.

## Usage

``` r
mysterycall_impute_age(
  grad_year,
  ref_year = as.integer(format(Sys.Date(), "%Y")),
  age_offset = 27L,
  min_age = 25,
  max_age = 90
)
```

## Arguments

- grad_year:

  Integer or numeric vector of medical school graduation years (4-digit,
  e.g. `1995`). `NA` values produce `NA` output.

- ref_year:

  Integer scalar. Reference year for the calculation. Defaults to the
  current calendar year (`as.integer(format(Sys.Date(), "%Y"))`).

- age_offset:

  Integer scalar. Assumed age at graduation. Default `27L` (validated
  median for US physicians).

- min_age:

  Numeric. Minimum plausible physician age. Values below this threshold
  are replaced with `NA`. Default `25`.

- max_age:

  Numeric. Maximum plausible physician age. Values above this threshold
  are replaced with `NA`. Default `90`.

## Value

Integer vector the same length as `grad_year`. `NA` is returned for
elements where `grad_year` is `NA`, where the computed age is below
`min_age`, or where it exceeds `max_age` (with a
[`base::warning()`](https://rdrr.io/r/base/warning.html) in each case).

## Details

Implausible results (age \< 0 after computing, or age \< `min_age`) are
set to `NA` with a warning.

## References

Muffly T, et al. Validation of Physician Age Imputation Method
(Graduation Year + 27). Technical Appendix, 2026.

## See also

[`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md)

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
[`mysterycall_most_common_gender()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_most_common_gender.md),
[`mysterycall_parse_certification_subspecialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_certification_subspecialty.md),
[`mysterycall_physician_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physician_age.md),
[`mysterycall_recode_credentials()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_recode_credentials.md),
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md),
[`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md)

## Examples

``` r
# Physician who graduated in 1995; current year 2026 -> age ~ 58
mysterycall_impute_age(1995)
#> [1] 58

# Vectorized
mysterycall_impute_age(c(1980, 1995, 2010, NA))
#> [1] 73 58 43 NA
```
