# Standardize demographic variables for Table 1

Convenience wrapper that applies age imputation, age categorization, and
gender standardization in one call. All output columns are **added** to
the input data frame - originals are never replaced or removed.
Arguments set to `NULL` are silently skipped so you can standardize only
the variables your dataset contains.

## Usage

``` r
mysterycall_prepare_table1_vars(
  data,
  age_col = NULL,
  grad_year_col = NULL,
  gender_col = NULL,
  setting_col = NULL,
  region_col = NULL,
  ref_year = as.integer(format(Sys.Date(), "%Y"))
)
```

## Arguments

- data:

  A data frame.

- age_col:

  Optional character scalar naming an existing numeric age column. When
  supplied, `age_category` is derived from it.

- grad_year_col:

  Optional character scalar naming a graduation-year column. Used to
  impute age when `age_col` is `NULL`.

- gender_col:

  Optional character scalar naming a gender/sex column. Values are
  recoded to `"Male"` (inputs `"m"` or `"male"`), `"Female"` (inputs
  `"f"` or `"female"`), or `"Unknown"` for any other value including
  `NA`. Matching is case-insensitive and whitespace-trimmed. This is a
  **binary classification**: non-binary or ambiguous values are silently
  bucketed into `"Unknown"`.

- setting_col:

  Optional character scalar naming a practice-setting column. Passed
  through as `setting_std`.

- region_col:

  Optional character scalar naming a region column. Passed through as
  `region_std`.

- ref_year:

  Integer reference year for age imputation. Default: current calendar
  year.

## Value

`data` with zero or more additional standardized columns appended (only
columns whose source `*_col` parameter was non-`NULL` are created):

- `age_imputed`:

  Numeric. Estimated age derived from `grad_year_col` as
  `ref_year - grad_year`. Only added when `grad_year_col` is supplied.

- `age_category`:

  Character. Age group binned from `age_col` or `age_imputed` (e.g.,
  `"<35"`, `"35-44"`, `"45-54"`, `"55-64"`, `">=65"`). Only added when
  `age_col` or `grad_year_col` is supplied.

- `gender_std`:

  Character. Standardized gender: `"Male"`, `"Female"`, or `"Unknown"`.
  Only added when `gender_col` is supplied.

- `setting_std`:

  Character. Practice setting, copied from the source column. Only added
  when `setting_col` is supplied.

- `region_std`:

  Character. Region, copied from the source column. Only added when
  `region_col` is supplied.

## Gender standardization

The `gender_std` column is produced by a binary lookup applied
case-insensitively after whitespace trimming:

|                                                     |                  |
|-----------------------------------------------------|------------------|
| **Input value**                                     | **`gender_std`** |
| `"male"`, `"m"`, `"Male"`, `"M"`                    | `"Male"`         |
| `"female"`, `"f"`, `"Female"`, `"F"`                | `"Female"`       |
| `NA`                                                | `"Unknown"`      |
| `""`, `"unknown"`, `"non-binary"`, any other string | `"Unknown"`      |

Non-binary values and any future Genderize.io API additions are all
mapped to `"Unknown"` silently. Before calling this function, inspect
`table(data[[gender_col]], useNA = "always")` to check for unexpected
values that will be bucketed into `"Unknown"`.

## See also

[`mysterycall_nppes_gender()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nppes_gender.md)
and
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md)
for the registry-reported gender that produces the raw `gender` column;
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)
to validate data quality before processing.

Other data management:
[`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md),
[`mysterycall_check_generalist_presence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_generalist_presence.md),
[`mysterycall_extract_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_zip5.md),
[`mysterycall_luhn_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_luhn_check.md),
[`mysterycall_merge_with_prefix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_merge_with_prefix.md),
[`mysterycall_rename_columns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_rename_columns.md),
[`mysterycall_stratified_sample()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_stratified_sample.md)

## Examples

``` r
df <- data.frame(
  grad_year = c(1990, 2000, 2010),
  gender    = c("Female", "M", "male")
)
mysterycall_prepare_table1_vars(df, grad_year_col = "grad_year",
                                 gender_col = "gender", ref_year = 2026L)
#>   grad_year gender age_imputed age_category gender_std
#> 1      1990 Female          63        60-69     Female
#> 2      2000      M          53        50-59       Male
#> 3      2010   male          43        40-49       Male
```
