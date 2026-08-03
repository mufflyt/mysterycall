# Fetch total female population by year (denominator for density figures)

Downloads the **total female population** (ACS table B01001, variable
`B01001_026E`, "Estimate!!Total!!Female") for one geography across a
range of years, returning a denominator ready to pass to the
`population` argument of
[`mysterycall_subspecialist_trend()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_trend.md)
or
[`mysterycall_subspecialist_infographic()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_infographic.md).
Wraps
[`tidycensus::get_acs()`](https://walker-data.com/tidycensus/reference/get_acs.html),
so a Census API key (env var `CENSUS_API_KEY`) and an internet
connection are required.

## Usage

``` r
mysterycall_census_female_population(
  years = 2013:2023,
  survey = c("acs1", "acs5"),
  geography = "us",
  variable = "B01001_026E",
  fill_2020 = c("acs5", "skip", "error"),
  as = c("vector", "data.frame"),
  verbose = TRUE
)
```

## Arguments

- years:

  Integer vector of survey years. Default `2013:2023`.

- survey:

  `"acs1"` (1-year, default) or `"acs5"` (5-year, smoother and available
  for every year including 2020).

- geography:

  Census geography passed to
  [`tidycensus::get_acs()`](https://walker-data.com/tidycensus/reference/get_acs.html).
  Default `"us"` (one national total per year).

- variable:

  ACS variable for total female population. Default `"B01001_026E"`.

- fill_2020:

  How to handle 2020 when `survey = "acs1"`: `"acs5"` (default;
  substitute the ACS 5-year value and message), `"skip"` (return `NA`
  for 2020), or `"error"` (stop).

- as:

  `"vector"` (default) returns a year-named numeric vector;
  `"data.frame"` returns a `data.frame(year, population)`. Both forms
  are accepted directly by the density functions' `population` argument.

- verbose:

  Logical. Message substitutions/progress. Default `TRUE`.

## Value

A year-named numeric vector, or a `data.frame(year, population)`.

## Details

The ACS 1-year table was **not released for 2020**; `fill_2020` controls
how that year is handled when `survey = "acs1"`.

## See also

[`mysterycall_subspecialist_trend()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_trend.md),
[`mysterycall_subspecialist_infographic()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_infographic.md)

Other census:
[`mysterycall_get_acs_women_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_women_18_90.md)

## Examples

``` r
if (FALSE) { # interactive()
# Requires CENSUS_API_KEY and internet.
fem_pop <- mysterycall_census_female_population(2013:2023, survey = "acs5")
# feed straight into the trend figure:
# mysterycall_subspecialist_trend(counts, population = fem_pop)
}
```
