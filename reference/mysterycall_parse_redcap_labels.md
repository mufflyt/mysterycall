# Parse REDCap field labels into choice-code / label tables

REDCap exports choice fields as pipe-delimited strings such as
`"1, Yes | 2, No | 3, Prefer not to answer"`. This function converts one
or more such strings — typically stored in the
`select_choices_or_calculations` column of a REDCap data dictionary —
into a tidy data frame with one row per choice, making it easy to recode
raw numeric codes to human-readable labels or to build factor variables.

## Usage

``` r
mysterycall_parse_redcap_labels(
  labels,
  sep_choice = " | ",
  sep_code = ", ",
  trim = TRUE
)
```

## Arguments

- labels:

  Character vector of REDCap label strings. Each element is one field's
  choices in the canonical REDCap format:
  `"<code>, <label> | <code>, <label> | ..."`. Unnamed elements are
  assigned sequential field names (`field_1`, `field_2`, …); supply a
  **named** vector to control the `field` column in the output.

- sep_choice:

  Character scalar. Separator between choices within a single label
  string. Default `" | "` (space-pipe-space). REDCap uses this
  consistently, but some exports omit the surrounding spaces — adjust as
  needed.

- sep_code:

  Character scalar. Separator between the numeric code and the
  human-readable label within a single choice. Default `", "`.

- trim:

  Logical. When `TRUE` (default), strip leading/trailing whitespace from
  codes and labels.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns:

- `field`:

  Field name, taken from the names of `labels`; defaults to `"field_1"`,
  `"field_2"`, … when `labels` is unnamed.

- `code`:

  Raw choice code (character), as exported by REDCap.

- `label`:

  Human-readable choice label (character).

Rows are ordered by field then by their original order within each
field.

## Common usage

    dict <- read.csv("REDCapDataDictionary.csv", stringsAsFactors = FALSE)
    choices <- setNames(dict$select_choices_or_calculations, dict$variable_name)
    choices <- choices[nzchar(choices)]   # drop empty / calculated fields

    parsed <- mysterycall_parse_redcap_labels(choices)

    # Build a recode lookup for one field
    lookup <- parsed[parsed$field == "insurance_type", ]
    df$insurance_label <- lookup$label[match(df$insurance_type, lookup$code)]

## See also

[`mysterycall_recode_credentials()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_recode_credentials.md)
for specialty-credential recoding

Other utilities:
[`.title_case()`](https://mufflyt.github.io/mysterycall/reference/dot-title_case.md),
`%>%()`,
[`format_phone_number()`](https://mufflyt.github.io/mysterycall/reference/format_phone_number.md),
[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md),
[`mysterycall_check_api_response()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_api_response.md),
[`mysterycall_check_data_completeness()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_data_completeness.md),
[`mysterycall_check_dependencies()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_dependencies.md),
[`mysterycall_check_no_data_loss()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_data_loss.md),
[`mysterycall_check_no_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_limits.md),
[`mysterycall_download_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_download_file.md),
[`mysterycall_estimate_resources()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_estimate_resources.md),
[`mysterycall_export_with_backup()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_with_backup.md),
[`mysterycall_normalize_file_format()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_file_format.md),
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md),
[`mysterycall_quality_tier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_quality_tier.md),
[`mysterycall_reached_declined_reasons()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reached_declined_reasons.md),
[`mysterycall_read_latest()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_latest.md),
[`mysterycall_read_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_table.md),
[`mysterycall_require_arrow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_require_arrow.md),
[`mysterycall_resolve_path()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_resolve_path.md),
[`mysterycall_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_quality_table.md),
[`mysterycall_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scan_for_limits.md),
[`mysterycall_standard_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_labels.md),
[`mysterycall_standard_palette()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_palette.md),
[`mysterycall_write_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table.md)

## Examples

``` r
raw <- c(
  scenario = "1, Straight couple | 2, Lesbian couple | 3, Single woman",
  accepted = "0, No | 1, Yes | 99, Unknown"
)
mysterycall_parse_redcap_labels(raw)
#> # A tibble: 6 × 3
#>   field    code  label          
#>   <chr>    <chr> <chr>          
#> 1 scenario 1     Straight couple
#> 2 scenario 2     Lesbian couple 
#> 3 scenario 3     Single woman   
#> 4 accepted 0     No             
#> 5 accepted 1     Yes            
#> 6 accepted 99    Unknown        
```
