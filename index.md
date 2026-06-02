v1.3.0  ·  R package

End-to-end toolkit for mystery caller and audit studies evaluating
patient access to healthcare — from NPI roster building to drive-time
isochrones, Census demographics, and publication-ready maps and tables.

[Function
reference](https://mufflyt.github.io/mysterycall/reference/index.md)
[Vignettes](https://mufflyt.github.io/mysterycall/articles/index.md)
[GitHub](https://github.com/mufflyt/mysterycall)

\# Install from GitHub  
pak::pkg_install("mufflyt/mysterycall")  
  
\# Optional geospatial/modelling packages (loaded on demand)  
install.packages(c("hereR", "sf", "leaflet", "censusapi", "lme4"))

Four-stage workflow

1

#### Build roster

Search the NPI registry by taxonomy across all 50 states, bypass the
1,200-record API cap, and enrich with CMS demographics.

2

#### Geocode

Convert provider addresses to lat/lon via the Google Maps API,
deduplicating so each unique address is only looked up once.

3

#### Drive-time isochrones

Generate drive-time polygons (30 / 60 / 120 / 180 min) using the
drive-time routing service, with built-in memoization for large batches.

4

#### Analyse & report

Overlay Census block-group demographics, compute overlap areas, and
produce Leaflet maps and `arsenal` summary tables.

Key functions

🔍

#### Provider search

[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)  
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)  
[`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md)  
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md)

📍

#### Geocoding & isochrones

[`mysterycall_geocode()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode.md)  
[`mysterycall_isochrones_for_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_isochrones_for_df.md)  
[`mysterycall_create_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_isochrones.md)  
[`mysterycall_clear_isochrone_cache()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clear_isochrone_cache.md)

🗺️

#### Mapping

[`mysterycall_map_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_physicians.md)  
[`mysterycall_map_block_group()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_block_group.md)  
[`mysterycall_map_acog_districts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_map_acog_districts.md)  
[`mysterycall_hrr_maps()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hrr_maps.md)

📊

#### Census & tables

[`mysterycall_get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md)  
[`mysterycall_calculate_overlap()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_calculate_overlap.md)  
[`mysterycall_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_overall.md)  
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md)

Example figures

![OBGYN subspecialist counts bar
chart](reference/figures/fig-subspecialty-counts.png)

**Provider roster** — subspecialist counts from the built-in
`physicians` dataset

``` mc-gallery-code
library(mysterycall)

# Search NPI registry by taxonomy
providers <- mysterycall_search_taxonomy(
  "Gynecologic Oncology",
  states = c("CA", "TX", "NY", "FL")
)

# Built-in dataset has 4,659 providers
count(physicians, subspecialty)
```

![US map of OBGYN
subspecialists](reference/figures/fig-physician-map.png)

**Geographic distribution** — dot map of providers coloured by
subspecialty

``` mc-gallery-code
# physicians dataset includes lat/long
mysterycall_map_physicians(
  physicians,
  popup_var = "name"
)
```

![100% stacked bar of acceptance
rates](reference/figures/fig-stacked-bar.png)

**100% stacked bar** — acceptance vs. rejection proportions with call
counts

``` mc-gallery-code
mysterycall_plot_stacked_bar(
  data          = call_data,
  outcome_col   = "accepted",
  group_col     = "subspecialty",
  fill_labels   = c("Not Accepted", "Accepted"),
  order_by_rate = TRUE
)
```

![Grouped bar chart of acceptance rates by
insurance](reference/figures/fig-acceptance-rates.png)

**Acceptance rates** — Medicaid vs. private insurance by subspecialty

``` mc-gallery-code
call_data |>
  group_by(subspecialty, insurance) |>
  summarise(rate = mean(accepted)) |>
  ggplot(aes(subspecialty, rate * 100,
             fill = insurance)) +
  geom_col(position = "dodge") +
  coord_flip()
```

![US choropleth of acceptance rates by
state](reference/figures/fig-acceptance-map.png)

**Choropleth map** — appointment acceptance rate by state

``` mc-gallery-code
state_rates <- call_data |>
  group_by(state) |>
  summarise(rate = mean(accepted))

mysterycall_map_acceptance_rate(
  state_rates,
  region_col = "state",
  rate_col   = "rate",
  palette    = "viridis"
)
```

![Wilson CI disparity plot](reference/figures/fig-disparities.png)

**Insurance disparity** — Wilson 95% CIs via
`mysterycall_disparities_table`

``` mc-gallery-code
disp <- mysterycall_disparities_table(
  call_data,
  outcome_col = "accepted",
  group_col   = "insurance",
  ref_group   = "Private",
  ci_method   = "wilson"
)
print(disp)
```

![IRR forest plot from Poisson
GLMM](reference/figures/fig-irr-forest.png)

**IRR forest plot** — incidence rate ratios from a Poisson GLMM

``` mc-gallery-code
model <- mysterycall_poisson_model(
  call_data,
  outcome       = "wait_days",
  predictors    = c("insurance", "subspecialty"),
  random_effect = "physician"
)
mysterycall_irr_plot(model, x_log = TRUE)
```

![Estimated marginal means interaction
plot](reference/figures/fig-emmeans-interaction.png)

**Estimated marginal means** — Medicaid vs. private wait days by
subspecialty

``` mc-gallery-code
m <- lm(
  wait_days ~ insurance * subspecialty,
  data = call_data
)
mysterycall_plot_emmeans_interaction(
  model    = m,
  specs    = c("subspecialty", "insurance"),
  variable = "Estimated Wait Days"
)
```

![Overlapping density curves by insurance
type](reference/figures/fig-wait-density.png)

**Wait-time density** — overlapping distributions with group medians

``` mc-gallery-code
mysterycall_plot_density(
  data       = call_data,
  x_var      = "wait_days",
  fill_var   = "insurance",
  plot_title = "Days Until Appointment",
  output_dir = NULL
)
```

![Jittered scatter plot of wait days by
subspecialty](reference/figures/fig-scatter.png)

**Jittered scatter** — raw wait-day observations by subspecialty

``` mc-gallery-code
mysterycall_plot_scatter(
  plot_data  = call_data,
  x_var      = "subspecialty",
  y_var      = "wait_days",
  output_dir = NULL,
  verbose    = FALSE
)
```

![Sqrt-scaled histogram of wait
times](reference/figures/fig-distribution.png)

**Wait-time histogram** — sqrt-scaled count distribution

``` mc-gallery-code
mysterycall_plot_distribution(
  x     = call_data$wait_days,
  title = "Appointment Wait Time (days)",
  bins  = 25L
)
```

![Sample size vs IRR power curve](reference/figures/fig-power-curve.png)

**Power curve** — providers per arm needed to detect a given IRR

``` mc-gallery-code
mysterycall_equation_figure(
  lambda0   = 14,        # baseline wait (days)
  irr_seq   = seq(1.1, 1.8, by = 0.05),
  power     = 0.80,
  both_arms = TRUE
)
```

![CONSORT flow diagram](reference/figures/fig-flowchart.png)

**CONSORT flowchart** — sequential inclusion/exclusion for audit studies

``` mc-gallery-code
mysterycall_flowchart(
  steps = c(
    "NPI Registry"     = "4,659",
    "Valid phone"      = "4,201",
    "Call completed"   = "3,872",
    "Final sample"     = "3,547"
  ),
  exclusions = c(
    "Valid phone"    = "458: no valid phone",
    "Call completed" = "329: unanswered",
    "Final sample"   = "325: incomplete data"
  )
)
```

![Three-panel residual diagnostics](reference/figures/fig-residuals.png)

**Residual diagnostics** — three-panel model check for Poisson GLMM fit

``` mc-gallery-code
model <- mysterycall_poisson_model(
  call_data,
  outcome       = "wait_days",
  predictors    = c("insurance", "subspecialty"),
  random_effect = "physician"
)
mysterycall_plot_residuals(model)
```

Example tables

![gtsummary Table 1 by insurance type](reference/figures/tbl-table1.png)

**Table 1 — Provider characteristics** stratified by insurance type via
[`mysterycall_table1_gtsummary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1_gtsummary.md)

``` mc-gallery-code
tbl1 <- mysterycall_table1_gtsummary(
  data       = call_data,
  vars       = c("subspecialty", "gender",
                 "academic", "wait_days", "accepted"),
  strata_col = "insurance",
  label_list = list(
    subspecialty = "Subspecialty",
    wait_days    = "Wait days (median [IQR])",
    accepted     = "Appointment accepted, n (%)"
  )
)
tbl1 |>
  gtsummary::bold_labels() |>
  gtsummary::as_gt()
```

![Appointment acceptance disparity table by
insurance](reference/figures/tbl-disparities.png)

**Disparities table** — acceptance rates, Wilson CIs, absolute
difference, and relative risk via
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md)

``` mc-gallery-code
disp <- mysterycall_disparities_table(
  call_data,
  outcome_col = "accepted",
  group_col   = "insurance",
  ref_group   = "Private",
  ci_method   = "wilson"
)
print(disp)
```

![Poisson GLMM incidence rate ratio
table](reference/figures/tbl-model.png)

**Model table — Incidence rate ratios** from a Poisson GLMM via
[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md)

``` mc-gallery-code
model <- mysterycall_poisson_model(
  call_data,
  outcome          = "wait_days",
  predictors       = c("insurance", "subspecialty"),
  random_intercept = "physician"
)

# Extract print-ready IRR table
mysterycall_model_table(model)
```

![Wait-time summary statistics by insurance
type](reference/figures/tbl-wait-time.png)

**Wait-time summary** — median, IQR, min/max, and Wilcoxon test via
[`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md)

``` mc-gallery-code
wts <- mysterycall_wait_time_summary(
  call_data,
  wait_col = "wait_days",
  group_by = "insurance"
)

# Summary statistics data frame
wts$summary

# Test result
wts$interpretation
```

![Subspecialty frequency and percentage
table](reference/figures/tbl-frequency.png)

**Frequency table** — counts and column percentages for a categorical
variable via
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md)

``` mc-gallery-code
freq_df <- mysterycall_table_percentages(
  call_data,
  "subspecialty"
)
print(freq_df)
```

![Subspecialty proportion table](reference/figures/tbl-proportion.png)

**Proportion table** — n and % of total calls per group via
[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md)

``` mc-gallery-code
prop_df <- mysterycall_table_proportion(
  call_data,
  subspecialty        # unquoted column name
)
print(prop_df)
```

Built-in datasets

| Dataset | Description | Rows |
|----|----|----|
| `taxonomy` | NUCC taxonomy codes (v23.1) for OBGYN subspecialties | ~900 |
| `acog_districts` | State → ACOG district + Census subregion crosswalk | 51 |
| `acgme` | All 318 ACGME-accredited OBGYN residency programs | 318 |
| `physicians` | Sample roster of OBGYN subspecialists with coordinates | 4,659 |
| `fips` | State FIPS codes and abbreviations | 51 |
| `acog_presidents` | Historical ACOG presidents | — |
| `census_summaries` | Pre-computed Census block-group demographics | — |

Learn more

| Vignette | Topic |
|----|----|
| [Create Isochrones](https://mufflyt.github.io/mysterycall/articles/create_isochrones.md) | Drive-time polygons from geocoded addresses |
| [Geocoding](https://mufflyt.github.io/mysterycall/articles/geocode.md) | Address → lat/lon with Google Maps |
| [Get Census Data](https://mufflyt.github.io/mysterycall/articles/get_census_data.md) | ACS block-group demographics |
| [Search & Process NPI](https://mufflyt.github.io/mysterycall/articles/search_and_process_npi.md) | Name-based provider lookup |
| [Aggregating Provider Data](https://mufflyt.github.io/mysterycall/articles/aggregating_provider_data.md) | Combining taxonomy + NPI data |
| [News & Changelog](https://mufflyt.github.io/mysterycall/articles/imotive-news.md) | Release notes |

Citation

``` r

citation("mysterycall")
```

> Muffly, T. (2026). *mysterycall: Mystery Caller Study Tools for
> Healthcare Access Research* (R package version 1.3.0).
> <https://github.com/mufflyt/mysterycall>
