# State-Level Choropleth Map of Acceptance Rates

Draws a CONUS (or full US) choropleth of per-state appointment
acceptance rates using ggplot2, maps, and viridis. Binary 0/1 outcome
columns are aggregated to per-state means automatically; columns already
containing rates (0-1) are used directly.

## Usage

``` r
mysterycall_geographic_map(
  data,
  state_col = "state",
  outcome_col = "offered",
  fill_label = "Acceptance rate",
  title = NULL,
  subtitle = NULL,
  palette = c("viridis", "magma", "plasma", "inferno", "cividis"),
  direction = 1L,
  low_states_warn = 5L,
  na_color = "grey80",
  include_alaska_hawaii = FALSE
)
```

## Arguments

- data:

  data.frame. Must contain at least `state_col` and `outcome_col`.

- state_col:

  Character. Column containing state abbreviations (e.g. `"CO"`, `"CA"`)
  or full state names (e.g. `"Colorado"`). Default `"state"`.

- outcome_col:

  Character. Column containing either binary 0/1 outcomes or
  per-observation acceptance rates (0-1 numeric). Default `"offered"`.

- fill_label:

  Character. Legend title shown on the fill scale. Default
  `"Acceptance rate"`.

- title:

  Character or `NULL`. Plot title. Default `NULL`.

- subtitle:

  Character or `NULL`. Plot subtitle. Default `NULL`.

- palette:

  Character. Viridis color palette. One of `"viridis"`, `"magma"`,
  `"plasma"`, `"inferno"`, or `"cividis"`. Default `"viridis"`.

- direction:

  Integer. Viridis scale direction: `1` (low color = low value; default)
  or `-1` (reversed).

- low_states_warn:

  Integer. Issue a
  [`base::warning()`](https://rdrr.io/r/base/warning.html) for any state
  with fewer than this many non-missing observations. Default `5L`.

- na_color:

  Character. Fill color for states not present in `data`. Default
  `"grey80"`.

- include_alaska_hawaii:

  Logical. When `FALSE` (default), Alaska (`AK`) and Hawaii (`HI`) are
  dropped before aggregation and mapping, producing a standard CONUS
  choropleth.

## Value

A `ggplot` object of class `c("gg", "ggplot")`, returned invisibly.
Print or assign the return value to display the map.

## State identifier format

The function detects whether `state_col` contains abbreviations or full
names by sampling the first non-missing value. When the value is two
characters or fewer it is treated as an abbreviation and looked up in
base::state.abb / base::state.name. Longer values are lower-cased and
joined directly to the map polygon data. DC and US territories are not
present in the built-in datasets and will appear as no-data states.

## Outcome aggregation

When every non-missing value in `outcome_col` is exactly 0 or 1, the
column is treated as binary and aggregated to a per-state acceptance
rate via [`base::tapply()`](https://rdrr.io/r/base/tapply.html)
(`mean(x, na.rm = TRUE)`). Any other numeric column is also averaged per
state, so passing a pre-computed rate works as expected.

## See also

[`mysterycall_map_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_acceptance_rate.md)
for a simpler one-call choropleth;
[`mysterycall_forest_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_forest_plot.md)
for model-level visualization.

Other reporting:
[`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md),
[`mysterycall_supplemental_tables()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_supplemental_tables.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`print.mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_abstract_numbers.md),
[`print.mysterycall_irr_days()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md),
[`print.mysterycall_snapshot()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_snapshot.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# --- Binary outcome example (0/1 call outcomes per row) --------------------
set.seed(42)
n <- 300
df <- data.frame(
  state   = sample(c("CO", "CA", "TX", "NY", "FL", "WA", "OR"), n,
                   replace = TRUE),
  offered = rbinom(n, 1, 0.60),
  stringsAsFactors = FALSE
)
p <- mysterycall_geographic_map(
  df,
  title    = "Appointment Acceptance Rate by State",
  subtitle = "Mystery-caller study, n = 300 calls"
)
print(p)

# --- Pre-aggregated rates (one row per state) ------------------------------
rate_df <- data.frame(
  state = c("CO", "CA", "TX", "NY", "FL"),
  rate  = c(0.55, 0.72, 0.48, 0.63, 0.81),
  stringsAsFactors = FALSE
)
mysterycall_geographic_map(
  rate_df,
  outcome_col = "rate",
  palette     = "plasma",
  direction   = -1L,
  fill_label  = "Acceptance\nrate"
)
} # }
```
