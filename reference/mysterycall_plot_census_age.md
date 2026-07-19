# Plot the distribution of female age groups

Plot the distribution of female age groups

## Usage

``` r
mysterycall_plot_census_age(
  census_df,
  group_var = NULL,
  output_dir = NULL,
  file_prefix = "census_age_distribution",
  dpi = 600,
  verbose = TRUE
)
```

## Arguments

- census_df:

  A data frame produced by
  [`mysterycall_get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md)
  (or another table containing equivalent columns).

- group_var:

  Optional single column name used to facet the distribution. When
  supplied, stacked bars are produced for each value of `group_var`. Set
  to `NULL` (the default) to visualize the aggregate distribution across
  all rows in `census_df`.

- output_dir:

  Directory where image files should be written. Defaults to a
  session-specific directory from
  [`mysterycall_tempdir()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).

- file_prefix:

  Prefix used when writing plot files. Defaults to
  "census_age_distribution".

- dpi:

  Resolution used when saving the plots (defaults to 600 DPI).

- verbose:

  When `TRUE`, prints the output file paths after saving.

## Value

Invisibly returns the generated ggplot object.

## See also

Other census:
[`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md),
[`mysterycall_add_medicaid_expansion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_medicaid_expansion.md),
[`mysterycall_get_acs_adults_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md),
[`mysterycall_get_acs_female_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_female_insurance.md),
[`mysterycall_get_acs_women_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_women_18_90.md),
[`mysterycall_get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md),
[`mysterycall_get_county_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_county_provider_counts.md),
[`mysterycall_get_payer_mix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_payer_mix.md),
[`mysterycall_read_kff_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_kff_hhi.md),
[`mysterycall_summarize_census()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_census.md),
[`mysterycall_summarize_county_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_county_enrollment.md),
[`print.mysterycall_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_provider_counts.md)

## Examples

``` r
if (FALSE) { # interactive()
  mysterycall_plot_census_age(census_example, group_var = "statefp", verbose = FALSE)
}
```
