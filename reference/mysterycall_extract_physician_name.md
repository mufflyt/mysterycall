# Extract a formatted physician name from a raw string

Strips credential suffixes (MD, DO, PhD, etc.), removes leading titles
(Dr., Prof.), and returns either `"Dr. LastName"`, the bare last name,
or a cleaned full name. Handles both `"First Last"` and `"Last, First"`
formats.

## Usage

``` r
mysterycall_extract_physician_name(
  x,
  format = c("dr_last", "last", "full_clean")
)
```

## Arguments

- x:

  Character vector of raw physician name strings.

- format:

  Character scalar controlling the output format:

  `"dr_last"`

  :   `"Dr. Smith"` (default).

  `"last"`

  :   `"Smith"`.

  `"full_clean"`

  :   Full name with credentials and titles removed.

## Value

Character vector the same length as `x`. `NA` for blank/`NA` inputs.

## See also

Other provider characteristics:
[`mysterycall_academic_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_academic_patterns.md),
[`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md),
[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md),
[`mysterycall_classify_medical_school()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_medical_school.md),
[`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md),
[`mysterycall_classify_ruca()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_ruca.md),
[`mysterycall_collapse_rare()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_collapse_rare.md),
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
nms <- c("John Smith MD", "Dr. Jane Doe, PhD", "JONES, Robert",
         "Mary Williams, MD, FACS", NA)
mysterycall:::mysterycall_extract_physician_name(nms)
#> [1] "Dr. Smith"    "Dr. Doe"      "Dr. JONES"    "Dr. Williams" NA            
mysterycall:::mysterycall_extract_physician_name(nms, format = "last")
#> [1] "Smith"    "Doe"      "JONES"    "Williams" NA        
```
