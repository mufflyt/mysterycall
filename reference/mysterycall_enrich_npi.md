# Integrated NPI enrichment pipeline

Runs the standard mysterycall NPI enrichment pipeline in one call:

1.  Fetch clinician data via
    [`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md)

2.  Infer gender from first name via
    [`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md)

3.  Classify practice setting via
    [`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md)

4.  Assign ACOG district via
    [`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md)

5.  (Optional) Deduplicate on NPI, keeping the row with the most non-NA
    values

## Usage

``` r
mysterycall_enrich_npi(
  data,
  first_name_col = "first_name",
  state_col = "state",
  address_col = "address",
  acog_out = "acog_district",
  dedup = TRUE,
  quiet = FALSE
)
```

## Arguments

- data:

  A data frame with at least an `npi` column (character or numeric).

- first_name_col:

  Name of the column containing the provider's first name, used for
  gender inference. Default `"first_name"`. Set to `NULL` to skip
  genderization.

- state_col:

  Name of the column containing US state (full name or two-letter
  abbreviation) for ACOG district assignment. Default `"state"`. Set to
  `NULL` to skip region assignment.

- address_col:

  Name of the column containing the practice address, used by
  [`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md).
  Default `"address"`. Set to `NULL` to skip practice classification.

- acog_out:

  Name of the output column for the ACOG district. Default
  `"acog_district"`.

- dedup:

  Logical. When `TRUE` (default), deduplicate on `npi`, keeping the row
  with the greatest number of non-NA values.

- quiet:

  Logical. When `TRUE`, suppress step messages. Default `FALSE`.

## Value

A data frame (tibble) with all original columns plus enrichment columns
added by each pipeline step. Steps that are skipped (because
`first_name_col`, `state_col`, or `address_col` is `NULL`, or because a
required package is absent) leave the data unchanged.

## See also

[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md),
[`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md),
[`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md),
[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md)

Other npi:
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md),
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md),
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)

## Examples

``` r
# Requires live NPPES API access and (optionally) a Genderize.io API key.
if (FALSE) { # \dontrun{
roster <- data.frame(
  npi        = c("1234567893", "9876543210"),
  first_name = c("Jane", "John"),
  state      = c("CO", "NY"),
  stringsAsFactors = FALSE
)
enriched <- mysterycall_enrich_npi(roster)
} # }
```
