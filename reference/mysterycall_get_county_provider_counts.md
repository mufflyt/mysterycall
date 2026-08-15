# Count distinct providers per county

Aggregates a provider roster to the number of distinct providers (NPIs)
in each county, with an optional per-capita density. County-level
physician supply is a standard confounder for insurance-based access
disparities: a Medicaid patient's odds of getting an appointment depend
partly on how many clinicians practise locally.

## Usage

``` r
mysterycall_get_county_provider_counts(
  providers,
  npi_col = "npi",
  county_col = "fips_county",
  taxonomy_col = NULL,
  population = NULL,
  pop_county_col = "fips_county",
  pop_col = "population",
  per = 1e+05,
  denominator_label = NULL
)
```

## Arguments

- providers:

  A data frame with one row per provider (or per provider-location);
  duplicate NPIs within a county are counted once.

- npi_col:

  Character. Column holding the NPI (or any provider id used for the
  distinct count). Default `"npi"`.

- county_col:

  Character. Column holding the county FIPS code (values are zero-padded
  to 5 characters). Default `"fips_county"`.

- taxonomy_col:

  Character or `NULL`. Optional taxonomy/specialty column; when
  supplied, an additional per-county-per-specialty count is returned in
  `by_specialty`. Default `NULL`.

- population:

  A data frame of county populations for density, or `NULL` to skip
  density. Default `NULL`.

- pop_county_col, pop_col:

  Character. Columns in `population` holding the county FIPS and the
  population count. Defaults `"fips_county"` / `"population"`.

- per:

  Numeric. Density scaling (providers per `per` residents). Default
  `100000`.

- denominator_label:

  Character or `NULL`. When supplied (e.g. `"women"`), it is appended to
  the density column name so it self-documents the denominator you
  passed via `pop_col` – for example `providers_per_100k_women` when
  `population` holds a female count. `NULL` (default) keeps the generic
  `providers_per_100k`. This changes only the column name, not the
  arithmetic.

## Value

A list of class `mysterycall_provider_counts` with elements:

- `by_county`:

  Tibble: `fips_county`, `n_providers`, and (when `population` supplied)
  `population` and the density column (`providers_per_100k`, or
  `providers_per_100k_<denominator_label>` when `denominator_label` is
  set), scaled by `per`.

- `by_specialty`:

  Tibble of `fips_county`, taxonomy, `n_providers`, or `NULL` when
  `taxonomy_col` is `NULL`.

- `n_counties`:

  Integer count of counties represented.

Rows with a missing county FIPS emit a warning and are dropped.

## See also

Other census:
[`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md),
[`mysterycall_add_medicaid_expansion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_medicaid_expansion.md),
[`mysterycall_census_female_population()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_census_female_population.md),
[`mysterycall_get_acs_adults_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md),
[`mysterycall_get_acs_female_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_female_insurance.md),
[`mysterycall_get_acs_women_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_women_18_90.md),
[`mysterycall_get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md),
[`mysterycall_get_payer_mix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_payer_mix.md),
[`mysterycall_plot_census_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_census_age.md),
[`mysterycall_read_kff_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_kff_hhi.md),
[`mysterycall_summarize_census()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_census.md),
[`mysterycall_summarize_county_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_county_enrollment.md),
[`print.mysterycall_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_provider_counts.md)

## Examples

``` r
roster <- data.frame(
  npi         = sprintf("1%09d", 1:6),
  fips_county = c("08031", "08031", "8031", "48201", "48201", NA),
  taxonomy    = c("OBGYN", "OBGYN", "FM", "OBGYN", "OBGYN", "FM"),
  stringsAsFactors = FALSE
)
pop <- data.frame(fips_county = c("08031", "48201"),
                  population   = c(715522, 4731145))
mysterycall_get_county_provider_counts(roster, population = pop)
#> Warning: 1 provider row(s) had a missing/blank county FIPS and were dropped.
#> === County Provider Counts ===
#> Counties: 2 | Total distinct providers: 5
#> Median density: 0.2 (providers_per_100k)
#> # A tibble: 2 × 4
#>   fips_county n_providers population providers_per_100k
#>   <chr>             <int>      <dbl>              <dbl>
#> 1 08031                 3     715522             0.419 
#> 2 48201                 2    4731145             0.0423

# Female denominator -> self-documenting column `providers_per_100k_women`
women <- data.frame(fips_county = c("08031", "48201"),
                    population   = c(361000, 2350000))
mysterycall_get_county_provider_counts(roster, population = women,
                                       denominator_label = "women")
#> Warning: 1 provider row(s) had a missing/blank county FIPS and were dropped.
#> === County Provider Counts ===
#> Counties: 2 | Total distinct providers: 5
#> Median density: 0.5 (providers_per_100k_women)
#> # A tibble: 2 × 4
#>   fips_county n_providers population providers_per_100k_women
#>   <chr>             <int>      <dbl>                    <dbl>
#> 1 08031                 3     361000                   0.831 
#> 2 48201                 2    2350000                   0.0851
```
