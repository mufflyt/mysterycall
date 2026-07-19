# Infer physician gender from first names via Genderize.io

Queries the [Genderize.io](https://genderize.io) API for first-name
gender predictions and joins the results back to the input roster. First
names are deduplicated before querying to minimize API calls. The
enriched roster is written to `output_dir` with a timestamp in the
filename.

## Usage

``` r
mysterycall_genderize(
  data_or_path,
  output_dir = NULL,
  output_format = c("csv", "parquet")
)
```

## Arguments

- data_or_path:

  A data frame with at least a `first_name` column, or a file path
  (character scalar) to a CSV or Parquet roster.

- output_dir:

  Character scalar. Directory where the genderized roster is saved.
  Defaults to a session-specific subfolder of
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

- output_format:

  `"csv"` (default) or `"parquet"`. Format for the saved output file.

## Value

A data frame with the same row count and all original columns as
`data_or_path`, with three new columns appended:

- `gender`:

  Character. `"male"`, `"female"`, or `NA` for ambiguous or unknown
  names.

- `probability`:

  Numeric in \[0, 1\]. API prediction confidence.

- `count`:

  Integer. Historical frequency of the name in the Genderize.io
  database.

Side effect: the enriched roster is written to `output_dir` as CSV or
Parquet with a timestamp in the filename.

## Details

Requires a `first_name` column in the input data. HTTP errors from the
API are raised as errors immediately (no silent fallback).

## Gender coding

Genderize.io returns `"male"`, `"female"`, or `NULL` for ambiguous or
unknown names. The API does not currently return non-binary values.
`NULL` responses are stored as `NA` in the raw `gender` output column.
If the API ever adds non-binary values they will be stored as-is in
`gender` but will be recoded to `"Unknown"` by
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md).

The `probability` column (0-1) reflects the API's prediction confidence.
Names with low probability may be genuine but uncommon (e.g.,
gender-neutral names). A common post-processing filter:

    result <- mysterycall_genderize(data)
    high_conf <- dplyr::filter(result, probability >= 0.70 | is.na(gender))

## API response schema

Each Genderize.io JSON entry is expected to contain exactly four fields.
Expected structure (single entry):

    { "name": "james", "gender": "male", "probability": 0.92, "count": 12345 }

Any additional fields returned by the API are silently dropped. If the
API renames or removes one of these four fields, the corresponding
output column will contain `NA` without an explicit error or warning.
See the API documentation at <https://genderize.io/#docs> for the
current schema.

## Output file timestamps

Output filenames include a timestamp from
[`Sys.time()`](https://rdrr.io/r/base/Sys.time.html), which uses the
**local system timezone** (not UTC). Files produced on systems in
different timezones will reflect different local times for the same
wall-clock moment. To standardize to UTC:

    withr::with_timezone("UTC", mysterycall_genderize(data))

Alternatively, supply a meaningful `output_dir` path that encodes the
study date rather than relying on the auto-generated timestamp.

## See also

[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md)
for downstream gender recoding to `"Male"`/`"Female"`/`"Unknown"`.

Other provider characteristics:
[`mysterycall_academic_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_academic_patterns.md),
[`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md),
[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md),
[`mysterycall_classify_medical_school()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_medical_school.md),
[`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md),
[`mysterycall_classify_ruca()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_ruca.md),
[`mysterycall_collapse_rare()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_collapse_rare.md),
[`mysterycall_extract_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_physician_name.md),
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
if (FALSE) { # interactive()
result <- mysterycall_genderize("sample.csv")
result <- mysterycall_genderize(my_dataframe)  # also accepts a data frame directly
}
```
