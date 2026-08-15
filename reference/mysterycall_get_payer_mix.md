# Build a county payer mix from ACS health-insurance coverage tables

Constructs a fuller insurance "payer mix" than the insured-vs-uninsured
split used in most access studies. Combines the ACS Subject table
**S2701** ("Selected Characteristics of Health Insurance Coverage", used
here for the headline insured / uninsured rates and the population
denominator) with the detailed coverage-type tables to add **Private**,
**Public**, **Medicaid**, and **Medicare** shares:

## Usage

``` r
mysterycall_get_payer_mix(
  year = NULL,
  states = NULL,
  geography = "county",
  verbose = TRUE
)
```

## Arguments

- year:

  Integer. ACS 5-year survey end-year (2012-2023). Required — no
  default, to keep results reproducible.

- states:

  Character vector of two-letter state abbreviations, or `NULL` for all
  states (slow). Default `NULL`.

- geography:

  Character scalar passed to
  [`tidycensus::get_acs()`](https://walker-data.com/tidycensus/reference/get_acs.html).
  Default `"county"`. Other useful values: `"tract"`, `"state"`,
  `"zcta"`.

- verbose:

  Logical. Print progress messages. Default `TRUE`.

## Value

A tibble with one row per geography and columns:

- `GEOID`, `NAME`:

  Geography identifier and label.

- `total_pop`, `total_pop_moe`:

  Civilian noninstitutionalized population (S2701 denominator) and its
  MOE.

- `n_private`, `n_public`, `n_medicare`, `n_medicaid`, `n_uninsured`:

  Population counts with each coverage type.

- `*_moe`:

  Propagated 90% MOE for each count.

- `pct_private`, `pct_public`, `pct_medicare`, `pct_medicaid`,
  `pct_uninsured`:

  Share of `total_pop` (0-100) with each coverage type.

- `pct_insured_s2701`, `pct_uninsured_s2701`:

  Headline insured / uninsured percentages taken directly from S2701.

- `year`:

  The ACS end-year supplied.

## Details

- Private:

  Table **B27002** — "With private health insurance".

- Public:

  Table **B27003** — "With public coverage".

- Medicare:

  Table **C27006** — "With Medicare coverage".

- Medicaid:

  Table **C27007** — "With Medicaid/means-tested public coverage".

- Uninsured:

  Table **B27001** — "No health insurance coverage", plus the S2701
  percent-uninsured estimate.

Because a person may hold more than one coverage type (e.g. dual
Medicare + Medicaid), the type shares are computed as a percentage of
the total civilian noninstitutionalized population and do **not** sum to
100. Coverage-type counts are obtained by summing every sex-by-age leaf
whose label carries the relevant "With ..." phrase, so the function
self-corrects across ACS vintages rather than depending on hard-coded
cell numbers.

Margins of error are propagated with the Census Bureau sum-of-squares
rule, \\MOE\_{sum} = \sqrt{\sum MOE_i^2}\\ (ACS Handbook Appendix 3);
all MOEs are at the 90% confidence level.

## Note

Requires a Census API key in the `CENSUS_API_KEY` environment variable
(see
[`tidycensus::census_api_key()`](https://walker-data.com/tidycensus/reference/census_api_key.html)).
Shares are `NA` where `total_pop` is zero.

## See also

[`mysterycall_get_acs_female_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_female_insurance.md)
for the female-only, single-county tract version built from the same
sex-by-coverage-type tables; this builder generalises it (all persons,
multi-state, any geography, with MOEs);
[`mysterycall_get_acs_adults_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md)
and
[`mysterycall_summarize_census()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_census.md)
for other ACS covariate builders;
[`mysterycall_get_county_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_county_provider_counts.md)
and
[`mysterycall_summarize_county_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_county_enrollment.md)
for the provider-supply and Medicare/Medicaid-enrollment covariates that
pair with payer mix.

Other census:
[`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md),
[`mysterycall_add_medicaid_expansion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_medicaid_expansion.md),
[`mysterycall_census_female_population()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_census_female_population.md),
[`mysterycall_get_acs_adults_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md),
[`mysterycall_get_acs_female_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_female_insurance.md),
[`mysterycall_get_acs_women_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_women_18_90.md),
[`mysterycall_get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md),
[`mysterycall_get_county_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_county_provider_counts.md),
[`mysterycall_plot_census_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_census_age.md),
[`mysterycall_read_kff_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_kff_hhi.md),
[`mysterycall_summarize_census()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_census.md),
[`mysterycall_summarize_county_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_county_enrollment.md),
[`print.mysterycall_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_provider_counts.md)

## Examples

``` r
if (FALSE) { # interactive()
co <- mysterycall_get_payer_mix(year = 2022, states = "CO")
head(co[, c("NAME", "pct_private", "pct_medicaid", "pct_medicare",
            "pct_uninsured")])
}
```
