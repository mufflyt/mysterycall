# Look up physician age by name and state

Attaches an estimated current-year age to physicians for whom you have a
name and a state but no NPI, by matching against the bundled
[healthgrades_ages](https://mufflyt.github.io/mysterycall/reference/healthgrades_ages.md)
reference. Matching is case-, punctuation-, and whitespace-insensitive
on normalised `(last_name, first_name, state)` – the same key the
reference is deduplicated on – so each query resolves to at most one
physician.

## Usage

``` r
mysterycall_lookup_age(
  first_name,
  last_name,
  state,
  reference = NULL,
  impute = TRUE
)
```

## Arguments

- first_name, last_name:

  Character vectors of given and family names. Recycled against each
  other; must be the same length (or length 1).

- state:

  Character vector of practice states, as two-letter USPS abbreviations
  or full state names. Recycled to match the names. `NA` or empty states
  never match.

- reference:

  Optional data frame to match against, defaulting to the package's
  [healthgrades_ages](https://mufflyt.github.io/mysterycall/reference/healthgrades_ages.md).
  Must contain `first_name`, `last_name`, `state`, and `age_current`;
  supply your own only for testing or to use an updated roster.

- impute:

  Logical. When `TRUE` (default), unmatched physicians receive a
  fallback age so the column has full coverage: the median `age_current`
  of the reference within the query's state, or the national median when
  the state is unknown or unseen. Imputed rows are always flagged
  (`age_imputed`, and `age_source` set to `"imputed_state_median"` /
  `"imputed_national_median"`) so they can be excluded or modelled
  separately. When `FALSE`, unmatched ages stay `NA`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per query, in input order, containing the echoed query
columns and the matched fields:

- first_name, last_name, state:

  The query values (state upper-cased to its two-letter form).

- matched:

  Logical; `TRUE` when a reference physician was found by name and state
  (never `TRUE` for an imputed row).

- age_current:

  Estimated current-year age. Observed when `matched`, imputed when
  `age_imputed`, or `NA` when unmatched and `impute = FALSE`.

- age_imputed:

  Logical; `TRUE` when `age_current` is a fallback estimate rather than
  a matched value.

- honorific, npi, city, age_at_scrape, scrape_year, age_source, n_obs:

  The matched reference fields, or `NA` when unmatched. For imputed rows
  `age_source` records which fallback was used.

## Details

The reference is keyed on state because names alone over-link (there are
many "Michael Miller"s); requiring a matching state removes most
spurious hits. State may be given as a two-letter USPS abbreviation
(`"CA"`) or a full name (`"California"`); full names are converted
automatically.

Ages are vendor-reported estimates projected to the reference year (2026
in the shipped data); treat them as approximate. When a match's `n_obs`
is large but the underlying scrapes disagreed, the returned age is that
of the most recent dated scrape (see
[healthgrades_ages](https://mufflyt.github.io/mysterycall/reference/healthgrades_ages.md)).

## See also

[healthgrades_ages](https://mufflyt.github.io/mysterycall/reference/healthgrades_ages.md)
for the reference dataset and its caveats;
[`mysterycall_link_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_link_physicians.md)
for probabilistic name linkage when a state-blocked exact match is too
strict.

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
[`mysterycall_link_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_link_physicians.md),
[`mysterycall_parse_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_duration.md)

## Examples

``` r
# Unmatched "Nobody Xyzzy" gets an imputed CO age, flagged age_imputed = TRUE
mysterycall_lookup_age(
  first_name = c("Gioi", "Debra", "Nobody"),
  last_name  = c("Smith-Nguyen", "Acerenza", "Xyzzy"),
  state      = c("California", "MD", "CO")
)
#> # A tibble: 3 × 13
#>   first_name last_name    state matched age_current age_imputed honorific npi   
#>   <chr>      <chr>        <chr> <lgl>         <dbl> <lgl>       <chr>     <chr> 
#> 1 Gioi       Smith-Nguyen CA    TRUE             69 FALSE       MD        16191…
#> 2 Debra      Acerenza     MD    TRUE             58 FALSE       DO        19321…
#> 3 Nobody     Xyzzy        CO    FALSE            64 TRUE        NA        NA    
#> # ℹ 5 more variables: city <chr>, age_at_scrape <int>, scrape_year <int>,
#> #   age_source <chr>, n_obs <int>

# Leave unmatched ages as NA instead
mysterycall_lookup_age("Nobody", "Xyzzy", "CO", impute = FALSE)
#> # A tibble: 1 × 13
#>   first_name last_name state matched age_current age_imputed honorific npi  
#>   <chr>      <chr>     <chr> <lgl>         <int> <lgl>       <chr>     <chr>
#> 1 Nobody     Xyzzy     CO    FALSE            NA FALSE       NA        NA   
#> # ℹ 5 more variables: city <chr>, age_at_scrape <int>, scrape_year <int>,
#> #   age_source <chr>, n_obs <int>
```
