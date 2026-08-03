![mysterycall hex-sticker
logo](https://github.com/mufflyt/mysterycall/assets/44621942/3c4faeb4-7fe5-42e8-b2bf-7832588c6f57)

[![Project Status:
Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![R ≥
4.1](https://img.shields.io/badge/R-%E2%89%A54.1-276DC3?logo=r&logoColor=white)](https://cran.r-project.org/)
[![R-CMD-check](https://github.com/mufflyt/mysterycall/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mufflyt/mysterycall/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/mufflyt/mysterycall/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/mufflyt/mysterycall/actions/workflows/pkgdown.yaml)
[![CRAN
status](https://www.r-pkg.org/badges/version/mysterycall)](https://CRAN.R-project.org/package=mysterycall)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/grand-total/mysterycall)](https://cran.r-project.org/package=mysterycall)
[![Codecov test
coverage](https://codecov.io/gh/mufflyt/mysterycall/branch/main/graph/badge.svg)](https://app.codecov.io/gh/mufflyt/mysterycall?branch=main)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ORCID](https://img.shields.io/badge/ORCID-0000--0002--2044--1693-A6CE39?logo=orcid&logoColor=white)](https://orcid.org/0000-0002-2044-1693)
[![GitHub last
commit](https://img.shields.io/github/last-commit/mufflyt/mysterycall)](https://github.com/mufflyt/mysterycall/commits/main)
[![GitHub
issues](https://img.shields.io/github/issues/mufflyt/mysterycall)](https://github.com/mufflyt/mysterycall/issues)
[![pkgdown
docs](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://mufflyt.github.io/mysterycall/)

## Statement of Need

Measuring patient access to healthcare requires assembling a provider
roster, placing calls under a standardized script, recording wait times
and refusal rates, and then modelling disparities by insurance type,
race, or geography. Each step involves bespoke data-engineering work
that research teams currently solve ad hoc: custom scripts to loop
around the NPI API’s 1,200-record cap, manual regular expressions to
parse name fields, silent
[`dplyr::left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
calls that multiply rows when a lookup table has duplicates, and
hand-crafted Poisson models that lack overdispersion diagnostics.

**mysterycall** consolidates this work into a single, tested, documented
pipeline. It provides taxonomy-based NPI search that bypasses the record
cap, NANP phone validation with state-geography checks, physician name
parsing with credential and surname disambiguation, safe join wrappers
that enforce coverage and uniqueness guarantees, Poisson mixed-effects
modelling with IRR reporting, and publication-ready table export
(drive-time isochrones and mapping are available through the companion
`mysterymaps` package). The target users are clinical researchers and
health-services researchers who conduct mystery-caller or audit studies
and need reproducible, auditable workflows rather than one-off scripts.

------------------------------------------------------------------------

**mysterycall** provides a toolkit for mystery caller and audit studies
that evaluate patient access to healthcare. It handles the study
workflow: finding providers in the NPI registry, validating their
records, analyzing acceptance and wait-time disparities, and producing
publication-ready tables. Geocoding, drive-time isochrones, and mapping
live in the companion `mysterymaps` package.

## Installation

``` r

# install.packages("pak")
pak::pkg_install("mufflyt/mysterycall")
```

The package loads quickly. Heavier modelling and Census packages are
optional and loaded only when first needed:

``` r

install.packages("lme4")                               # mixed-effects models
install.packages("censusapi")                          # Census block-group data
```

## Quick start

A typical mystery caller study builds a provider roster, then analyzes
the call outcomes:

``` r

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

# ── 2. Analyze acceptance and wait-time disparities ───────────────────────────

# `calls` is your completed call log: one row per call to a provider in the
# roster above, with an `insurance` arm and recorded outcomes/wait times.

# Medicaid vs. private acceptance rate with Wilson CIs and a gap sentence
rates <- mysterycall_acceptance_rate_calc(calls, insurance_col = "insurance")
print(rates)

# Wait-time model: incidence rate ratios by insurance, clustered by practice
fit <- mysterycall_poisson_model(
  calls,
  outcome = "business_days_until_appointment",
  predictors = "insurance",
  random_intercept = "practice"
)
mysterycall_irr_plot(fit)
```

> **Geocoding, drive-time isochrones, and mapping now live in the
> companion [`mysterymaps`](https://github.com/mufflyt/mysterymaps)
> package** (`mysterymaps::mysterymaps_geocode()`,
> `mysterymaps::mysterymaps_isochrones_for_df()`,
> `mysterymaps::mysterymaps_map_base()`). `mysterycall` focuses on the
> mystery-caller study design, analysis, and manuscript outputs.

## Gallery

[TABLE]

## How mysterycall compares to alternatives

| Capability | mysterycall | `npi` package | `humaniformat` | Manual `dplyr` |
|----|----|----|----|----|
| NPI search — state-looping to bypass 1,200-record cap | ✅ | ❌ | ❌ | ❌ |
| NANP phone validation + state-geography check | ✅ | ❌ | ❌ | ❌ |
| Physician name parsing with DO/Vietnamese disambiguation | ✅ | ❌ | Partial | ❌ |
| Safe joins with coverage enforcement | ✅ | ❌ | ❌ | ❌ |
| Drive-time isochrones + Census overlay (via companion `mysterymaps`) | ✅ | ❌ | ❌ | ❌ |
| Poisson GLMM with IRR reporting | ✅ | ❌ | ❌ | ❌ |
| Disparities table with Wilson CIs | ✅ | ❌ | ❌ | ❌ |
| Green Journal–compliant figure export | ✅ | ❌ | ❌ | ❌ |

`npi` and `humaniformat` are excellent single-purpose packages.
`mysterycall` integrates them into a validated, end-to-end study
pipeline with audit trails, coverage guards, and publication-ready
output.

## Core functions

| Stage | Function | Description |
|----|----|----|
| **Find providers** | [`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md) | NPI search by taxonomy; loops over states to bypass the 1,200-record cap |
|  | [`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md) | NPI search by first/last name |
|  | [`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md) | Remove invalid NPI numbers before enrichment |
|  | [`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md) | Pull demographics from CMS Physician Compare |
|  | [`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md) | Estimate physician gender via the Genderize.io API |
| **Census** | [`mysterycall_get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md) | ACS block-group demographics by state FIPS |
| **Geospatial** | *(moved to [`mysterymaps`](https://github.com/mufflyt/mysterymaps))* | Geocoding, drive-time isochrones, isochrone/block-group overlap, and Leaflet/HRR maps |
| **Tables** | [`mysterycall_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_overall.md) | Table 1 summary (via `arsenal`) |
|  | [`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md) | Column-percentage tables |

## Built-in datasets

| Dataset | Description |
|----|----|
| `taxonomy` | NUCC taxonomy codes (v23.1) for all OBGYN subspecialties |
| `acog_districts` | State → ACOG district + Census subregion crosswalk |
| `acgme` | All 318 ACGME-accredited OBGYN residency programs |
| `physicians` | Sample roster of 4,659 OBGYN subspecialists with coordinates |
| `fips` | State FIPS codes and abbreviations |
| `city_state_to_lat_long` | City/state → lat/lon lookup table |
| `acog_presidents` | Historical ACOG presidents data |
| `census_summaries` | Pre-computed Census block-group demographics |

``` r

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

**Getting started** - [Searching the NPI Database by
Taxonomy](https://mufflyt.github.io/mysterycall/articles/my-vignette.html) -
[Search & Process
NPI](https://mufflyt.github.io/mysterycall/articles/search_and_process_npi.html) -
[Workflow
Orchestration](https://mufflyt.github.io/mysterycall/articles/workflow-orchestration.html)

**Data quality** - [Phone Validation, Name Parsing, and Safe
Joins](https://mufflyt.github.io/mysterycall/articles/data-quality.html)

**Analysis and reporting** - [Statistical Analysis (Poisson GLMMs,
disparities, bootstrap
CIs)](https://mufflyt.github.io/mysterycall/articles/statistical-analysis.html) -
[Provider Classification (RUCA, practice setting, census
region)](https://mufflyt.github.io/mysterycall/articles/provider-classification.html) -
[Table
Generation](https://mufflyt.github.io/mysterycall/articles/table-generation.html) -
[Get Census
Data](https://mufflyt.github.io/mysterycall/articles/get_census_data.html)

## Citing mysterycall

``` r

citation("mysterycall")
```

> Muffly, T. (2026). *mysterycall: Mystery Caller Study Tools for
> Healthcare Access Research* (R package version 1.6.3.9000).
> <https://github.com/mufflyt/mysterycall>

## Contributing

Contributions are welcome. Please read
[CONTRIBUTING.md](https://mufflyt.github.io/mysterycall/CONTRIBUTING.md)
for the development workflow, coding style, and pull-request process.
Bug reports and feature requests are best filed as [GitHub
issues](https://github.com/mufflyt/mysterycall/issues).

## Code of conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://mufflyt.github.io/mysterycall/CODE_OF_CONDUCT.md). By
participating you agree to abide by its terms.

## License

MIT © Tyler Muffly. See
[LICENSE.md](https://mufflyt.github.io/mysterycall/LICENSE.md) for the
full text.
