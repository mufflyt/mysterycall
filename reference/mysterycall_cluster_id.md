# Build a random-intercept clustering key by coalescing columns

The mixed-model fitters
([`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
...) all require a `random_intercept` column, but a geographic
mystery-caller study rarely has a single clean grouping key: a metro
(CBSA) code exists for urban practices, falls back to a county FIPS for
the rest, and some rows have neither. Leaving those rows blank or `NA`
is a quiet footgun – they collapse into one giant pseudo-cluster and
corrupt the estimated random-effect variance.

## Usage

``` r
mysterycall_cluster_id(
  data,
  cols,
  solo_prefix = "solo_",
  empty_as_missing = TRUE
)
```

## Arguments

- data:

  A data frame.

- cols:

  Character vector of candidate key columns, most specific first (e.g.
  `c("cbsa_code", "county_fips")`). Each must exist in `data`.

- solo_prefix:

  Prefix for the singleton keys given to rows that no column resolves.
  Default `"solo_"`. Set to `NA` to instead leave those rows `NA` (and
  emit a warning naming how many) if you would rather drop or inspect
  them.

- empty_as_missing:

  Logical; treat empty strings (and, after trimming, whitespace-only
  strings) as missing. Default `TRUE`.

## Value

A character vector of length `nrow(data)`: the clustering key.

## Details

This helper coalesces an ordered list of candidate columns into one
grouping vector: for each row it takes the first non-missing, non-empty
value across `cols` (in order), and gives every row that is *still*
unresolved its own singleton cluster (`solo_<rownum>`) so it contributes
as an independent group rather than being merged.

## Examples

``` r
d <- data.frame(
  cbsa_code   = c("16980", "", NA, "31080"),
  county_fips = c("17031", "17097", "", "06037")
)
mysterycall_cluster_id(d, c("cbsa_code", "county_fips"))
#> [1] "16980"  "17097"  "solo_3" "31080" 
# -> c("16980", "17097", "solo_3", "31080")
```
