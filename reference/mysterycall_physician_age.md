# Summarise physician age as median (IQR) text

Computes the median, Q1, and Q3 of a numeric age column (ignoring `NA`)
and returns a ready-to-paste sentence for manuscript methods or results
sections.

## Usage

``` r
mysterycall_physician_age(data, age_column)
```

## Arguments

- data:

  A data frame containing the age data.

- age_column:

  Character scalar naming the numeric column in `data` that holds
  physician ages.

## Value

A single character string of the form
`"The median age was XX.XX years (IQR: Q1.X--Q3.X years)."` where the
median is rounded to 2 decimal places and IQR bounds to 1.

## Details

`NA` values in `age_column` are removed before computing quantiles
(i.e., `na.rm = TRUE`). All quantiles use the default R `type = 7`
interpolation.

## See also

[`mysterycall_impute_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_impute_age.md)
to derive age from graduation year;
[`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md)
to bin ages into publication-ready groups.

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
[`mysterycall_recode_credentials()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_recode_credentials.md),
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md),
[`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md)

## Examples

``` r
# Example 1: Basic usage with a small dataset
data <- data.frame(age = c(30, 40, 50, 60, 35, 45, 55, 65))
summary_sentence <- mysterycall_physician_age(data, "age")
print(summary_sentence)
#> [1] "The median age of the dataset was 47.5 (IQR 25th percentile 38.8 to 75th percentile 56.2)."

# Example 2: Handling missing data
df_with_na <- data.frame(age = c(30, 40, NA, 60, 35, NA, 55, 65))
summary_sentence <- mysterycall_physician_age(df_with_na, "age")
print(summary_sentence)
#> [1] "The median age of the dataset was 47.5 (IQR 25th percentile 36.2 to 75th percentile 58.8)."

# Example 3: Different age distribution
df_large <- data.frame(age = c(rep(30, 70), rep(40, 30), rep(50, 20), rep(60, 10)))
summary_sentence <- mysterycall_physician_age(df_large, "age")
print(summary_sentence)
#> [1] "The median age of the dataset was 30 (IQR 25th percentile 30 to 75th percentile 40)."
```
