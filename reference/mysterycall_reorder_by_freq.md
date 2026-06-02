# Reorder a factor (or character vector) by descending frequency

Returns a factor whose levels are ordered from most to least common.
This is the standard preparation step before passing a categorical
variable to ggplot2 bar charts or
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html).

## Usage

``` r
mysterycall_reorder_by_freq(x, decreasing = TRUE, na_level = NULL)
```

## Arguments

- x:

  A factor or character vector.

- decreasing:

  Logical. `TRUE` (default) sorts most-frequent first; `FALSE` sorts
  least-frequent first.

- na_level:

  Character scalar or `NULL`. When non-`NULL`, `NA` values are replaced
  with this string and included as the last level. Default `NULL` (NAs
  kept as `NA`).

## Value

A factor with levels sorted by frequency.

## Details

Equivalent to `forcats::fct_infreq()` but implemented in pure base R
with no additional dependencies.

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
[`mysterycall_recode_credentials()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_recode_credentials.md),
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md)

## Examples

``` r
x <- c("B", "A", "A", "C", "B", "B", "C", NA)
mysterycall_reorder_by_freq(x)
#> [1] B    A    A    C    B    B    C    <NA>
#> Levels: B A C
# levels: B (3), A (2), C (2), then by appearance for ties

# Useful in ggplot2:
# ggplot(df, aes(x = mysterycall_reorder_by_freq(specialty))) + geom_bar()
```
