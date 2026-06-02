
# mysterycall

<!-- badges: start -->
<img src="https://github.com/mufflyt/mysterycall/assets/44621942/3c4faeb4-7fe5-42e8-b2bf-7832588c6f57" width="15%" align="right">

[![Project Status: Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![R ≥ 4.1](https://img.shields.io/badge/R-%E2%89%A54.1-276DC3?logo=r&logoColor=white)](https://cran.r-project.org/)
[![R-CMD-check](https://github.com/mufflyt/mysterycall/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mufflyt/mysterycall/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/mufflyt/mysterycall/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/mufflyt/mysterycall/actions/workflows/pkgdown.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/mysterycall)](https://CRAN.R-project.org/package=mysterycall)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/grand-total/mysterycall)](https://cran.r-project.org/package=mysterycall)
[![Codecov test coverage](https://codecov.io/gh/mufflyt/mysterycall/branch/main/graph/badge.svg)](https://app.codecov.io/gh/mufflyt/mysterycall?branch=main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ORCID](https://img.shields.io/badge/ORCID-0000--0002--2044--1693-A6CE39?logo=orcid&logoColor=white)](https://orcid.org/0000-0002-2044-1693)
[![GitHub last commit](https://img.shields.io/github/last-commit/mufflyt/mysterycall)](https://github.com/mufflyt/mysterycall/commits/main)
[![GitHub issues](https://img.shields.io/github/issues/mufflyt/mysterycall)](https://github.com/mufflyt/mysterycall/issues)
[![pkgdown docs](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://mufflyt.github.io/mysterycall/)
<!-- badges: end -->

## Statement of Need

Measuring patient access to healthcare requires assembling a provider roster,
placing calls under a standardised script, recording wait times and refusal
rates, and then modelling disparities by insurance type, race, or geography.
Each step involves bespoke data-engineering work that research teams currently
solve ad hoc: custom scripts to loop around the NPI API's 1,200-record cap,
manual regular expressions to parse name fields, silent `dplyr::left_join()`
calls that multiply rows when a lookup table has duplicates, and hand-crafted
Poisson models that lack overdispersion diagnostics.

**mysterycall** consolidates this work into a single, tested, documented
pipeline. It provides taxonomy-based NPI search that bypasses the record cap,
NANP phone validation with state-geography checks, physician name parsing with
credential and surname disambiguation, safe join wrappers that enforce coverage
and uniqueness guarantees, drive-time isochrone generation, Census demographic
overlay, Poisson mixed-effects modelling with IRR reporting, and
publication-ready table and map export. The target users are clinical
researchers and health-services researchers who conduct mystery-caller or audit
studies and need reproducible, auditable workflows rather than one-off scripts.

---

**mysterycall** provides a toolkit for mystery caller and audit studies that evaluate
patient access to healthcare. It handles the full workflow: finding providers
in the NPI registry, validating and geocoding their addresses, generating
drive-time isochrones, overlaying Census demographics, and producing publication-ready
tables and maps.

## Installation

```r
# install.packages("pak")
pak::pkg_install("mufflyt/mysterycall")
```

The package loads quickly. Geospatial and modelling packages are optional and
loaded only when first needed:

```r
install.packages(c("hereR", "sf", "lwgeom"))  # drive-time isochrones
install.packages("leaflet")                            # interactive maps
install.packages("ggmap")                              # Google Maps geocoding
install.packages(c("ggspatial", "rnaturalearth"))      # HRR hex maps
install.packages("lme4")                               # mixed-effects models
install.packages("censusapi")                          # Census block-group data
```

## Quick start

A typical mystery caller study moves through four stages:

```r
library(mysterycall)
library(dplyr)

# ── 1. Build a provider roster ────────────────────────────────────────────────

# Search by taxonomy across all 50 states (bypasses the 1,200-record API cap)
all_states <- c(
  "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN",
  "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV",
  "NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN",
  "TX","UT","VT","VA","WA","WV","WI","WY"
)

gyn_onc <- mysterycall_search_taxonomy("Gynecologic Oncology", states = all_states)

# Validate NPI numbers before downstream lookups
gyn_onc_valid <- mysterycall_validate_npi(gyn_onc)

# Enrich with CMS Physician Compare demographics
gyn_onc_enriched <- mysterycall_get_clinician_data(gyn_onc_valid)

# ── 2. Geocode ────────────────────────────────────────────────────────────────

# Requires a Google Maps API key in GOOGLE_API_KEY env var
geocoded <- mysterycall_geocode(
  gyn_onc_enriched,
  google_maps_api_key = Sys.getenv("GOOGLE_API_KEY")
)

# ── 3. Drive-time isochrones ──────────────────────────────────────────────────

# Requires a routing API key in HERE_API_KEY env var
isochrones <- mysterycall_isochrones_for_df(
  geocoded,
  breaks = c(1800, 3600, 7200, 10800)   # 30 / 60 / 120 / 180 min
)

# Free the in-memory isochrone cache after a large batch
mysterycall_clear_isochrone_cache()

# ── 4. Map ────────────────────────────────────────────────────────────────────

mysterycall_map_physicians(geocoded, popup_var = "name")
```

## Gallery

<table>
<tr>
<td width="50%">

**Provider roster** — subspecialist counts from the built-in `physicians` dataset
(`mysterycall_search_taxonomy`)

<img src="man/figures/fig-subspecialty-counts.png" width="100%">

</td>
<td width="50%">

**Geographic distribution** — dot map of 4,659 OBGYN subspecialists across the US
(`mysterycall_map_physicians`)

<img src="man/figures/fig-physician-map.png" width="100%">

</td>
</tr>
<tr>
<td width="50%">

**Acceptance rates** — Medicaid vs. private insurance by subspecialty
(`mysterycall_plot_stacked_bar`)

<img src="man/figures/fig-acceptance-rates.png" width="100%">

</td>
<td width="50%">

**Insurance disparity** — Wilson 95% CIs by insurance type
(`mysterycall_disparities_table`)

<img src="man/figures/fig-disparities.png" width="100%">

</td>
</tr>
<tr>
<td width="50%">

**Choropleth map** — appointment acceptance rate by state
(`mysterycall_map_acceptance_rate`)

<img src="man/figures/fig-acceptance-map.png" width="100%">

</td>
<td width="50%">

**Wait-time distribution** — overlapping densities with group medians
(`mysterycall_plot_density`)

<img src="man/figures/fig-wait-density.png" width="100%">

</td>
</tr>
<tr>
<td width="50%">

**IRR forest plot** — incidence rate ratios from a Poisson GLMM
(`mysterycall_irr_plot`)

<img src="man/figures/fig-irr-forest.png" width="100%">

</td>
<td width="50%">

**Power curve** — providers per arm needed to detect a given IRR
(`mysterycall_equation_figure`)

<img src="man/figures/fig-power-curve.png" width="100%">

</td>
</tr>
<tr>
<td width="50%">

**CONSORT flowchart** — sequential inclusion/exclusion for audit studies
(`mysterycall_flowchart`)

<img src="man/figures/fig-flowchart.png" width="100%">

</td>
<td width="50%">

**Residual diagnostics** — three-panel model check for Poisson GLMM fit
(`mysterycall_plot_residuals`)

<img src="man/figures/fig-residuals.png" width="100%">

</td>
</tr>
<tr>
<td width="50%">

**100% stacked bar** — acceptance vs. rejection proportions with call counts
(`mysterycall_plot_stacked_bar`)

<img src="man/figures/fig-stacked-bar.png" width="100%">

</td>
<td width="50%">

**Estimated marginal means** — Medicaid vs. private wait days by subspecialty
(`mysterycall_plot_emmeans_interaction`)

<img src="man/figures/fig-emmeans-interaction.png" width="100%">

</td>
</tr>
<tr>
<td width="50%">

**Jittered scatter** — raw wait-day observations by subspecialty
(`mysterycall_plot_scatter`)

<img src="man/figures/fig-scatter.png" width="100%">

</td>
<td width="50%">

**Wait-time histogram** — sqrt-scaled count distribution
(`mysterycall_plot_distribution`)

<img src="man/figures/fig-distribution.png" width="100%">

</td>
</tr>
</table>

## How mysterycall compares to alternatives

| Capability | mysterycall | `npi` package | `humaniformat` | Manual `dplyr` |
|---|---|---|---|---|
| NPI search — state-looping to bypass 1,200-record cap | ✅ | ❌ | ❌ | ❌ |
| NANP phone validation + state-geography check | ✅ | ❌ | ❌ | ❌ |
| Physician name parsing with DO/Vietnamese disambiguation | ✅ | ❌ | Partial | ❌ |
| Safe joins with coverage enforcement | ✅ | ❌ | ❌ | ❌ |
| Drive-time isochrone generation (HERE API) | ✅ | ❌ | ❌ | ❌ |
| Census demographic overlay on isochrones | ✅ | ❌ | ❌ | ❌ |
| Poisson GLMM with IRR reporting | ✅ | ❌ | ❌ | ❌ |
| Disparities table with Wilson CIs | ✅ | ❌ | ❌ | ❌ |
| Green Journal–compliant figure export | ✅ | ❌ | ❌ | ❌ |

`npi` and `humaniformat` are excellent single-purpose packages.
`mysterycall` integrates them into a validated, end-to-end study pipeline
with audit trails, coverage guards, and publication-ready output.

## Core functions

| Stage | Function | Description |
|---|---|---|
| **Find providers** | `mysterycall_search_taxonomy()` | NPI search by taxonomy; loops over states to bypass the 1,200-record cap |
| | `mysterycall_search_and_process_npi()` | NPI search by first/last name |
| | `mysterycall_validate_npi()` | Remove invalid NPI numbers before enrichment |
| | `mysterycall_get_clinician_data()` | Pull demographics from CMS Physician Compare |
| | `mysterycall_genderize()` | Estimate physician gender via the Genderize.io API |
| **Geocode** | `mysterycall_geocode()` | Convert addresses to lat/lon via Google Maps |
| **Isochrones** | `mysterycall_isochrones_for_df()` | Drive-time polygons for every row using a drive-time routing service |
| | `mysterycall_create_isochrones()` | Single-location drive-time polygon |
| | `mysterycall_clear_isochrone_cache()` | Release the in-session memoization cache |
| **Census** | `mysterycall_get_census_data()` | ACS block-group demographics by state FIPS |
| | `mysterycall_calculate_overlap()` | Overlap area between isochrones and block groups |
| **Maps** | `mysterycall_map_physicians()` | Interactive Leaflet dot map coloured by ACOG district |
| | `mysterycall_map_block_group()` | Block-group overlap map exported to HTML + PNG |
| | `mysterycall_hrr_maps()` | Hexagon density map by Hospital Referral Region |
| **Tables** | `mysterycall_table_overall()` | Table 1 summary (via `arsenal`) |
| | `mysterycall_table_percentages()` | Column-percentage tables |

## Built-in datasets

| Dataset | Description |
|---|---|
| `taxonomy` | NUCC taxonomy codes (v23.1) for all OBGYN subspecialties |
| `acog_districts` | State → ACOG district + Census subregion crosswalk |
| `acgme` | All 318 ACGME-accredited OBGYN residency programs |
| `physicians` | Sample roster of 4,659 OBGYN subspecialists with coordinates |
| `fips` | State FIPS codes and abbreviations |
| `city_state_to_lat_long` | City/state → lat/lon lookup table |
| `acog_presidents` | Historical ACOG presidents data |
| `census_summaries` | Pre-computed Census block-group demographics |

```r
# Example: find all OBGYN taxonomy codes
library(mysterycall)
library(dplyr)
library(stringr)

taxonomy |>
  filter(str_detect(Classification, fixed("GYN", ignore_case = TRUE))) |>
  select(Code, Specialization)
#> # A tibble: 11 × 2
#>    Code       Specialization
#>    <chr>      <chr>
#>  1 207V00000X Obstetrics & Gynecology
#>  2 207VF0040X Female Pelvic Medicine and Reconstructive Surgery
#>  3 207VX0201X Gynecologic Oncology
#>  4 207VM0101X Maternal & Fetal Medicine
#>  5 207VE0102X Reproductive Endocrinology
#>  ...
```

## Learn more

Full documentation, function reference, and worked vignettes:
**<https://mufflyt.github.io/mysterycall/>**

**Getting started**
- [Searching the NPI Database by Taxonomy](https://mufflyt.github.io/mysterycall/articles/my-vignette.html)
- [Search & Process NPI](https://mufflyt.github.io/mysterycall/articles/search_and_process_npi.html)
- [Workflow Orchestration](https://mufflyt.github.io/mysterycall/articles/workflow-orchestration.html)

**Data quality**
- [Phone Validation, Name Parsing, and Safe Joins](https://mufflyt.github.io/mysterycall/articles/data-quality.html)

**Geospatial**
- [Geocoding](https://mufflyt.github.io/mysterycall/articles/geocode.html)
- [Create Isochrones](https://mufflyt.github.io/mysterycall/articles/create_isochrones.html)

**Analysis and reporting**
- [Statistical Analysis (Poisson GLMMs, disparities, bootstrap CIs)](https://mufflyt.github.io/mysterycall/articles/statistical-analysis.html)
- [Provider Classification (RUCA, practice setting, census region)](https://mufflyt.github.io/mysterycall/articles/provider-classification.html)
- [Table Generation](https://mufflyt.github.io/mysterycall/articles/table-generation.html)
- [Get Census Data](https://mufflyt.github.io/mysterycall/articles/get_census_data.html)

## Citing mysterycall

```r
citation("mysterycall")
```

> Muffly, T. (2026). *mysterycall: Mystery Caller Study Tools for Healthcare
> Access Research* (R package version 1.3.0).
> <https://github.com/mufflyt/mysterycall>

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for
the development workflow, coding style, and pull-request process. Bug reports
and feature requests are best filed as
[GitHub issues](https://github.com/mufflyt/mysterycall/issues).

## Code of conduct

Please note that this project is released with a
[Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating you agree
to abide by its terms.

## License

MIT © Tyler Muffly. See [LICENSE.md](LICENSE.md) for the full text.
