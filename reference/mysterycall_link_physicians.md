# Probabilistic record linkage of two physician lists without a shared key

Audit sampling frames often must be reconciled against an external
roster – a called cohort against a Medicaid-acceptance list, applicants
against a resident roster – when neither carries an NPI or any other
unique key, only names. Exact-name joins miss `"Katherine"` vs
`"Kathryn"` and every transposition; a deterministic join over-links
common surnames. This wraps fastLink's Fellegi-Sunter linkage with
Jaro-Winkler string comparison on the name fields, optional blocking to
keep the comparison space tractable, and returns the matched pairs with
their posterior match probability so a human can review the borderline
ones. Use it when you have names but no NPI; when you have (or can look
up) an NPI, prefer
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)
/
[`mysterycall_enrich_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_enrich_npi.md).

## Usage

``` r
mysterycall_link_physicians(
  df_a,
  df_b,
  name_cols,
  block_var = NULL,
  threshold = 0.85,
  jw_weight = 0.25,
  partial_match = TRUE
)
```

## Arguments

- df_a, df_b:

  The two data frames to link.

- name_cols:

  Character vector of the shared name columns to match on (must exist in
  both frames), e.g. `c("first_name", "last_name")`.

- block_var:

  Optional character scalar naming a column present in both frames to
  block on (e.g. `"state"`): only records sharing a block value are
  compared, which makes large linkages feasible. Default `NULL` (no
  blocking).

- threshold:

  Posterior-probability cutoff for calling a pair a match. Default
  `0.85`.

- jw_weight:

  Jaro-Winkler prefix weight passed to
  [`fastLink::fastLink()`](https://rdrr.io/pkg/fastLink/man/fastLink.html).
  Default `0.25`.

- partial_match:

  Logical; when `TRUE` (default), allow partial string agreement on the
  `name_cols` (passed to `fastLink`'s `partial.match`).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
of matched pairs – the `name_cols` from each frame (suffixed `_a` /
`_b`), the source row indices `index_a` / `index_b`, and `posterior`
(the match probability) – sorted descending by `posterior`. Zero rows
when nothing clears `threshold`.

## Details

Requires the fastLink package.

## See also

[`mysterycall_normalize_org_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_org_name.md),
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)

Other data integrity:
[`.mc_age_impute()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_impute.md),
[`.mc_age_key()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_age_key.md),
[`.mc_check_acs_vintage()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_acs_vintage.md),
[`.mc_data()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_data.md),
[`.mc_geo_layer()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geo_layer.md),
[`.mc_geocode_point()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geocode_point.md),
[`.mc_healthgrades_ages()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_healthgrades_ages.md),
[`.mc_state_to_abbr()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_state_to_abbr.md),
[`mc-census-vintage`](https://mufflyt.github.io/mysterycall/reference/mc-census-vintage.md),
[`mysterycall_assign_area_covariates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_area_covariates.md),
[`mysterycall_categorize_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_categorize_wait.md),
[`mysterycall_clean_zip()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_zip.md),
[`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md),
[`mysterycall_lookup_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lookup_age.md),
[`mysterycall_parse_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_duration.md)

## Examples

``` r
# \donttest{
if (requireNamespace("fastLink", quietly = TRUE)) {
  a <- data.frame(first_name = c("Katherine", "Robert"),
                  last_name  = c("Smith", "Jones"))
  b <- data.frame(first_name = c("Kathryn", "Bob"),
                  last_name  = c("Smith", "Jones"))
  mysterycall_link_physicians(a, b, c("first_name", "last_name"))
}
#> 
#> ==================== 
#> fastLink(): Fast Probabilistic Record Linkage
#> ==================== 
#> 
#> If you set return.all to FALSE, you will not be able to calculate a confusion table as a summary statistic.
#> Calculating matches for each variable.
#> WARNING: You have no exact matches for first_name.
#> Warning: There are no partial matches. We suggest either changing the value of cut.p or using gammaCK2par() instead
#> Warning: There are no partial matches. We suggest either changing the value of cut.p or using gammaCK2par() instead
#> Getting counts for parameter estimation.
#>     Parallelizing calculation using OpenMP. 1 threads out of 4 are used.
#> Running the EM algorithm.
#> Getting the indices of estimated matches.
#>     Parallelizing calculation using OpenMP. 1 threads out of 4 are used.
#> Deduping the estimated matches.
#> Getting the match patterns for each estimated match.
#> # A tibble: 1 × 7
#>   index_a index_b first_name_a first_name_b last_name_a last_name_b posterior
#>     <dbl>   <dbl> <chr>        <chr>        <chr>       <chr>           <dbl>
#> 1       1       1 Katherine    Kathryn      Smith       Smith           1.000
# }
```
