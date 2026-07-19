# KFF Hospital-Market Concentration (HHI) by Metropolitan Area, 2024

Kaiser Family Foundation (KFF) published Herfindahl-Hirschman Index
(HHI) of hospital-system market concentration for 387 U.S. metropolitan
statistical areas (MSAs) in 2024, together with the systems controlling
each market. Use it as a ready-made market-concentration covariate for
insurance-access analyses: in a highly concentrated market a dominant
system has more latitude to steer scheduling by payer.

## Format

A data frame with 387 rows (one per MSA) and 10 columns:

- msa:

  Character. MSA name in `"City, ST"` form (state suffix may be
  multi-state, e.g. `"New York, NY-NJ-PA"`).

- state_abb:

  Character. Two-letter USPS abbreviation of the MSA's first principal
  state, parsed from `msa`.

- residents_2024:

  Integer. MSA population in 2024.

- market_structure:

  Character. KFF's summary of how many systems control the market, e.g.
  `"1 system has 100% market share"`,
  `"4+ systems have 100% market share"`.

- hhi:

  Numeric. Herfindahl-Hirschman Index in 2024 (0-10000).

- largest_system:

  Character. Name of the largest health system.

- largest_system_share:

  Numeric. Largest system's market share as a proportion (0-1).

- second_largest_system:

  Character. Name of the second-largest system, or `NA` when a single
  system holds 100%.

- second_largest_system_share:

  Numeric. Second-largest system's market share (0-1), or `NA`.

- hhi_cat:

  Ordered factor: `"un-concentrated"` \< `"moderate"` \< `"high"`
  (DOJ/FTC 1000/1800 thresholds).

## Source

Kaiser Family Foundation, "KFF HHI Dataset" (per-MSA HHI, 2024), via the
`mufflyt/consolidation` study repository. See the KFF hospital-
consolidation analyses at <https://www.kff.org/>.

## Details

HHI ranges 0-10000 (sum of squared percent market shares). The
Department of Justice / Federal Trade Commission Horizontal Merger
Guidelines classify markets as un-concentrated (\< 1000), moderately
concentrated (1000-1800), and highly concentrated (\> 1800); those
cut-points define `hhi_cat`.

## See also

[`mysterycall_add_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_add_hhi.md)
to join HHI onto office data and derive `hhi_k` / `hhi_cat`;
[`mysterycall_read_kff_hhi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_kff_hhi.md)
to read/crosswalk the raw KFF workbook;
[medicaid_expansion](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md)
for another state-policy covariate.

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md),
[`medicaid_fee_index`](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)

## Examples

``` r
data(kff_hhi)

# Concentration mix across metros
table(kff_hhi$hhi_cat)
#> 
#> un-concentrated        moderate            high 
#>               4               6             377 

# Most concentrated large metros
big <- kff_hhi[kff_hhi$residents_2024 > 1e6, ]
head(big[order(-big$hhi), c("msa", "hhi", "largest_system")])
#> # A tibble: 6 × 3
#>   msa                                        hhi largest_system                 
#>   <chr>                                    <dbl> <chr>                          
#> 1 Grand Rapids-Wyoming-Kentwood, MI        4821. Corewell Health                
#> 2 Rochester, NY                            4803. University of Rochester Medica…
#> 3 Fresno, CA                               4479. Community Health System        
#> 4 Virginia Beach-Chesapeake-Norfolk, VA-NC 4421. Sentara Health                 
#> 5 Birmingham, AL                           4257. UAB Health System              
#> 6 Raleigh-Cary, NC                         4225. WakeMed Health & Hospitals     

# Attach onto office data with a CBSA crosswalk via mysterycall_add_hhi();
# kff_hhi is the packaged equivalent of mysterycall_read_kff_hhi()'s output.
```
