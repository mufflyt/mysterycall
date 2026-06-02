# Generate a Summary Sentence for the Most Common Gender, Specialty, Training, and Academic Affiliation

This function calculates and returns a sentence that describes the most
common gender, specialty, training, and academic affiliation in the
provided dataset.

## Usage

``` r
mysterycall_most_common_gender(data)
```

## Arguments

- data:

  A data frame containing the columns `gender`, `specialty`,
  `Provider.Credential.Text`, and `academic_affiliation`.

## Value

A length-1 character string naming the most common value and its
proportion (rounded to 1 decimal place) for each of `gender`,
`specialty`, `Provider.Credential.Text`, and `academic_affiliation`.
When a column is entirely `NA`, the proportion is reported as `NaN`. In
case of a tie, the level that sorts first alphabetically is returned.

## Details

The function filters out missing values in each column before
determining the most common value. It then calculates the proportion of
this most common value relative to the total non-missing values in that
column.

## See also

[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md)
for tabulating any single categorical variable;
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md)
for upstream gender standardisation.

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
[`mysterycall_parse_certification_subspecialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_certification_subspecialty.md),
[`mysterycall_physician_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physician_age.md),
[`mysterycall_recode_credentials()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_recode_credentials.md),
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md),
[`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md)

## Examples

``` r
# Example 1: Basic usage with a small dataset
data <- data.frame(
  gender = c("Male", "Female", "Female", "Male", "Male"),
  specialty = c("Cardiology", "Cardiology", "Neurology", "Cardiology", "Neurology"),
  Provider.Credential.Text = c("MD", "MD", "DO", "MD", "DO"),
  academic_affiliation = c("Yes", "No", "Yes", "No", "Yes")
)
result <- mysterycall_most_common_gender(data)
print(result)
#> [1] "The most common gender in the dataset was male (60%). The most common specialty was Cardiology (60%). The most common training was MD (60%). The academic affiliation status most frequently occurring was yes (60%)."

# Example 2: Handling missing data
df_with_na <- data.frame(
  gender = c("Male", NA, "Female", "Male", "Male"),
  specialty = c("Cardiology", "Cardiology", "Neurology", NA, "Neurology"),
  Provider.Credential.Text = c("MD", "MD", "DO", "MD", "DO"),
  academic_affiliation = c("Yes", "No", "Yes", "No", NA)
)
result <- mysterycall_most_common_gender(df_with_na)
print(result)
#> [1] "The most common gender in the dataset was male (75%). The most common specialty was Cardiology (50%). The most common training was MD (60%). The academic affiliation status most frequently occurring was no (50%)."

# Example 3: Different proportions with a larger dataset
df_large <- data.frame(
  gender = c(rep("Male", 70), rep("Female", 30)),
  specialty = c(rep("Cardiology", 50), rep("Neurology", 30), rep("Orthopedics", 20)),
  Provider.Credential.Text = c(rep("MD", 60), rep("DO", 40)),
  academic_affiliation = c(rep("Yes", 40), rep("No", 60))
)
result <- mysterycall_most_common_gender(df_large)
print(result)
#> [1] "The most common gender in the dataset was male (70%). The most common specialty was Cardiology (50%). The most common training was MD (60%). The academic affiliation status most frequently occurring was no (60%)."
```
