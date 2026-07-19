# Collapse rare factor/character levels into an "Other" category

Replaces any level (or unique value) that appears fewer than `threshold`
times with `other_label`. Factors are returned as factors with updated
levels; character vectors are returned as character.

## Usage

``` r
mysterycall_collapse_rare(x, threshold = 50L, other_label = "Other")
```

## Arguments

- x:

  A character or factor vector.

- threshold:

  Minimum count to retain a level. Levels with fewer observations are
  collapsed. Default `50L`.

- other_label:

  Character scalar used as the replacement label. Default `"Other"`.

## Value

A vector the same length and type as `x`. Character input returns
character; factor input returns a factor with updated levels (rare
levels removed, `other_label` appended at the end if any collapsing
occurred). Relative order of retained levels is preserved.

## See also

[`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md)
to reorder factor levels by frequency;
[`mysterycall_recode_credentials()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_recode_credentials.md)
for credential grouping.

Other provider characteristics:
[`mysterycall_academic_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_academic_patterns.md),
[`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md),
[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md),
[`mysterycall_classify_medical_school()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_medical_school.md),
[`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md),
[`mysterycall_classify_ruca()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_ruca.md),
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
x <- c(rep("Otolaryngology", 80), rep("Urology", 30), rep("Dermatology", 5))
mysterycall_collapse_rare(x, threshold = 10)
#>   [1] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>   [5] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>   [9] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [13] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [17] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [21] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [25] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [29] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [33] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [37] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [41] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [45] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [49] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [53] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [57] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [61] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [65] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [69] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [73] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [77] "Otolaryngology" "Otolaryngology" "Otolaryngology" "Otolaryngology"
#>  [81] "Urology"        "Urology"        "Urology"        "Urology"       
#>  [85] "Urology"        "Urology"        "Urology"        "Urology"       
#>  [89] "Urology"        "Urology"        "Urology"        "Urology"       
#>  [93] "Urology"        "Urology"        "Urology"        "Urology"       
#>  [97] "Urology"        "Urology"        "Urology"        "Urology"       
#> [101] "Urology"        "Urology"        "Urology"        "Urology"       
#> [105] "Urology"        "Urology"        "Urology"        "Urology"       
#> [109] "Urology"        "Urology"        "Other"          "Other"         
#> [113] "Other"          "Other"          "Other"         
```
