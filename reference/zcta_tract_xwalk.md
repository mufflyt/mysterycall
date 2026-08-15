# ZCTA to Census Tract crosswalk (area-weighted)

A ZIP-to-tract crosswalk for apportioning tract-level measures to
practice ZIPs (or the reverse), built from the US Census Bureau's
authoritative 2020 ZCTA5-to-tract relationship file. It stands in for
HUD's login-gated USPS ZIP crosswalk. ZCTA (ZIP Code Tabulation Area) is
the Census approximation of a mailing ZIP.

## Format

A data frame with about 168,000 rows and 3 columns:

- zcta:

  Five-digit ZIP Code Tabulation Area (2020), character with leading
  zeros.

- tract:

  Eleven-digit 2020 Census tract GEOID (state+county+tract), character.

- arealand_part:

  Land area of the ZCTA-by-tract intersection, in square metres (Census
  `AREALAND_PART`). Both allocation weights are derived from this
  column; see below.

## Source

US Census Bureau, 2020 Census ZCTA5-to-Census-Tract relationship file.
<https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_tract20_natl.txt>

## Details

Each row is one ZCTA-by-tract intersection. Allocation weights are
derived from the Census-computed land area of the intersection, so they
are **area-weighted**. This differs from HUD, whose `res_ratio` /
`bus_ratio` are **address-weighted** (USPS residential and business
delivery counts). For population- or address-based apportionment prefer
HUD's file or a block-level build; area weights are a sound geographic
approximation and are exact for "which tracts a ZIP touches, and by how
much land."

Regenerate with `data-raw/zcta_tract_xwalk.R`, which downloads the
source file directly (no key or login). Rows where a ZCTA has no land
overlap with any tract (all water) are dropped.

Because both indices in this package
([`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md),
[`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md))
are already ZCTA-keyed, this crosswalk is needed only for genuinely
tract-level work – e.g. joining an external tract-level measure to
practice ZIPs via `tract_to_zcta`.

## Allocation weights

Earlier versions shipped two derived ratio columns, `zcta_to_tract` and
`tract_to_zcta`. They were removed because each is a deterministic
function of `arealand_part` within a grouping, and together they cost
2.1 MB of a 2.9 MB file while adding nothing that cannot be recovered in
one line. Rows are unchanged, and row order still puts each ZCTA's
dominant tract first.

To spread a ZIP-level quantity across tracts, or to pick the dominant
tract for a ZIP, recompute the ZCTA-to-tract weight (sums to 1 within a
ZCTA):


    x <- mysterycall::zcta_tract_xwalk
    x$zcta_to_tract <- ave(x$arealand_part, x$zcta,
                           FUN = function(a) a / sum(a))

To aggregate tract-level measures up to a ZIP, recompute the
tract-to-ZCTA weight (sums to 1 within a tract):


    x$tract_to_zcta <- ave(x$arealand_part, x$tract,
                           FUN = function(a) a / sum(a))

Both reproduce the removed columns exactly.

## See also

[`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md)
and
[`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md),
which are already ZCTA-keyed and need no crosswalk for ZIP linkage.

Other datasets:
[`acgme`](https://mufflyt.github.io/mysterycall/reference/acgme.md),
[`acog_districts`](https://mufflyt.github.io/mysterycall/reference/acog_districts.md),
[`acog_presidents`](https://mufflyt.github.io/mysterycall/reference/acog_presidents.md),
[`adi_zcta`](https://mufflyt.github.io/mysterycall/reference/adi_zcta.md),
[`city_state_to_lat_long`](https://mufflyt.github.io/mysterycall/reference/city_state_to_lat_long.md),
[`fips`](https://mufflyt.github.io/mysterycall/reference/fips.md),
[`healthgrades_ages`](https://mufflyt.github.io/mysterycall/reference/healthgrades_ages.md),
[`kff_hhi`](https://mufflyt.github.io/mysterycall/reference/kff_hhi.md),
[`medicaid_expansion`](https://mufflyt.github.io/mysterycall/reference/medicaid_expansion.md),
[`medicaid_fee_index`](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md),
[`physicians`](https://mufflyt.github.io/mysterycall/reference/physicians.md),
[`svi_zcta`](https://mufflyt.github.io/mysterycall/reference/svi_zcta.md),
[`taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)

## Examples

``` r
data(zcta_tract_xwalk)

# Dominant tract for a ZIP
# library(dplyr)
# zcta_tract_xwalk |> filter(zcta == "10001") |> slice_max(zcta_to_tract, n = 1)

# Area-weighted roll-up of a tract-level measure to ZIP
# tract_measure  # data.frame(tract, value)
# zcta_tract_xwalk |>
#   inner_join(tract_measure, by = "tract") |>
#   group_by(zcta) |>
#   summarise(value = sum(value * tract_to_zcta), .groups = "drop")
```
