# Changelog

## mysterycall 1.4.0

Released 2026-06-02.

### 💥 Breaking changes

- **Data objects renamed to snake_case** to align with package style:

  - `cityStateToLatLong` → `city_state_to_lat_long`
  - `ACOG_Districts` → `acog_districts` Update code that referenced
    these objects directly. The .rda files in `data/` were renamed
    accordingly.

- **Many internal helpers removed from the public API.** 79 functions
  were demoted from exported to internal as part of rOpenSci submission
  prep — logging helpers (`mysterycall_log_*`), progress-bar primitives
  (`mysterycall_progress_*`, `mysterycall_multi_*`,
  `mysterycall_spinner_*`), address-normalizer field helpers (now
  wrapped by
  [`mysterycall_normalize_address_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_address_df.md)),
  sanity-check internals, and unprefixed deprecation shims. Total
  exports dropped from 230 to 152. If your code used any of these,
  switch to a `mysterycall:::name()` call or refactor to use the
  higher-level wrappers.

- **`provider` package dependency removed.** The optional GitHub-only
  `provider` package is no longer listed in `Suggests`.
  [`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md)
  still detects it dynamically if installed.

### ✨ Improvements

- **CRAN-readiness fixes.** `R CMD check --as-cran` now passes with zero
  errors, zero warnings, and only the standard “New submission” NOTE.
  Highlights:

  - Stripped `install.packages('X')` instructions from ~70 error
    messages.
  - Replaced `ggforce::geom_circle` in
    [`mysterycall_plot_source_venn()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_source_venn.md)
    with a base-ggplot2 `geom_polygon` implementation (no `ggforce`
    dep).
  - Replaced
    [`tigris::fips_codes`](https://rdrr.io/pkg/tigris/man/fips_codes.html)
    example with a hardcoded vector (no `tigris` dep).
  - Fixed 301/404 URLs (HERE developer portal, ACGME, USDA ERS).
  - Soft-fail in
    [`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)
    when optional Suggests are missing.
  - Vignettes guard chunks that use Suggests-only deps with
    [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html).

- **rOpenSci alignment.** R/ filenames lowercased (`ACOG_Districts.R`,
  `Splitting_dataframe_to_send_to_callers.R`, `cityStateToLatLong.R`,
  `states_where_physicians_were_NOT_contacted.R` → snake_case
  equivalents). All 12 publication/green-journal theme and palette
  functions now carry the `mysterycall_` prefix (e.g.,
  [`mysterycall_theme_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal.md),
  [`mysterycall_palette_publication()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_palette_green_journal.md)).

- **Suggests dependency reduction.** Dropped four unused packages
  (`imager`, `leaflet.extras`, `tmap`, `tigris`) plus `ggforce`.
  Suggests count: 48 → 43.

- **Documentation hygiene.** `devtools::document()` now runs cleanly;
  data documentation converted from the trailing-string-literal pattern
  to the universal `@name + NULL` pattern. New tests added for
  `R/academic_indicators.R` and `R/audit-verify.R`. ORCID and R-version
  badges added to README and pkgdown index.

## mysterycall 1.3.0

Released 2026-05-08.

### 💥 Breaking changes (with backward compatibility)

- Package renamed from `mysterycall` to `mysterycall`.
  [`library(mysterycall)`](https://mufflyt.github.io/mysterycall/) will
  no longer work; use
  [`library(mysterycall)`](https://mufflyt.github.io/mysterycall/).
- All 100 exported functions now carry the `mysterycall_` prefix (e.g.,
  [`mysterycall_geocode()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode.md),
  [`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)).
  The previous `mysterycall_` prefix names are retained as deprecated
  shims that emit a warning and forward to the new name. The even-older
  unprefixed names (e.g.,
  [`check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md))
  continue to work as double-deprecated shims.

### ✨ New functions

**Data quality and validation**

- [`mysterycall_validate_phone()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_phone.md)
  — validates US phone numbers against NANP structural rules (NPA/NXX
  first-digit constraints, N11 service codes) and optionally checks that
  the area code belongs to the provider’s reported practice state via a
  bundled lookup table. Returns a tidy data frame with
  `phone_e164_valid`, `phone_npa`, `phone_state_from_npa`,
  `phone_area_code_matches_state`, and `phone_validity_flag` columns.
  Fully vectorised; lookup table is lazy-loaded and cached per session.

- [`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md)
  — converts free-text physician name strings (board certification data,
  NPPES, CMS sources) into structured first / middle / last / suffix /
  title fields with confidence scoring (`high` / `medium` / `low`) and
  warning flags. Handles DO credential vs. Vietnamese surname
  disambiguation (`"Robert Smith DO"` → suffix `"DO"`; `"Linda Do"` →
  last name `"Do"`), three-part comma format (`"Smith, John, Jr."`),
  hyphenated names, and name particles.

- [`mysterycall_validate_parsed_names()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_parsed_names.md)
  — extends parse output with quality flags: `has_first`, `has_last`,
  `is_valid`, `last_is_credential`, `last_is_suffix`, `last_too_short`,
  `middle_has_particle`, `quality_issue`.

- [`mysterycall_format_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_physician_name.md)
  — reassembles parsed components into `"last_first"`, `"first_last"`,
  or `"formal"` display strings; vectorised.

- [`mysterycall_test_name_parser()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_name_parser.md)
  — runs a 13-case edge-case accuracy suite and prints a per-case report
  to the console. An extended 30-case benchmark corpus is available in
  `inst/extdata/name_benchmark_corpus.csv`; the evaluation script is in
  `data-raw/benchmark_name_parser.R`.

**Safe join wrappers**

- [`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md)
  — wraps
  [`dplyr::left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
  with key-type harmonisation, right-side uniqueness assertion, coverage
  threshold enforcement (`min_coverage`, default 0.98),
  row-multiplication guard (`max_duplication`, default 1.02×), and
  optional CSV audit report.

- [`mysterycall_safe_inner_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_inner_join.md)
  — wraps
  [`dplyr::inner_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
  with the same guards; default `min_coverage = 0.90`.

- [`mysterycall_safe_semi_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_semi_join.md)
  — wraps
  [`dplyr::semi_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html)
  with a keep-rate threshold; default `min_coverage = 0.50`.

- [`mysterycall_safe_anti_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_anti_join.md)
  — wraps
  [`dplyr::anti_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html)
  with an over-exclusion cap (`max_matched`, default 1.0).

- [`mysterycall_assert_unique_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assert_unique_keys.md)
  — asserts that specified columns form a unique key; optionally
  deduplicates (first row kept) instead of erroring.

**Package infrastructure**

- `humaniformat` moved from `Suggests` → `Imports`; the runtime
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) guard has
  been removed.
- 119 new `test_that` blocks across three new test files
  (`test-validate-phone.R`, `test-parse-physician-name.R`,
  `test-join-safety.R`).
- Five new vignettes: `data-quality`, `statistical-analysis`,
  `provider-classification`, `workflow-orchestration`,
  `table-generation`.
- `CITATION.cff` updated with full abstract, keywords, and affiliation.
- `CONTRIBUTING.md` expanded to a full developer guide.

### ✅ rOpenSci compliance

- Replaced all 34 `\dontrun{}` blocks with `@examplesIf interactive()`.
- Replaced 18 live [`print()`](https://rdrr.io/r/base/print.html) calls
  with [`message()`](https://rdrr.io/r/base/message.html) or
  [`invisible()`](https://rdrr.io/r/base/invisible.html).
- Moved `sf` from `Imports` to `Suggests`; added
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) guards in
  8 geospatial functions to avoid forcing GDAL/GEOS/PROJ on all users.
- Bumped minimum R version from 3.5.0 to 4.1.0.
- Removed duplicate `Maintainer:` field from `DESCRIPTION`.
- Added GitHub issue/PR templates and `repostatus.org` badge.

------------------------------------------------------------------------

## mysterycall 1.2.2

Released 2026-05-04.

### 🐛 Bug fixes

- [`library(mysterycall)`](https://mufflyt.github.io/mysterycall/) no
  longer crashes R or causes system memory exhaustion. Seven heavy
  packages (`ggmap`, `ggspatial`, `hereR`, `leaflet`, `leaflet.extras`,
  `lme4`, `censusapi`) were moved from `Imports` to `Suggests` so their
  compiled spatial libraries (GDAL, GEOS, PROJ) are loaded **only when
  the relevant function is first called**, not on package attach. Two
  packages declared in `Imports` but never called (`tigris`, `effects`)
  were removed entirely.

- [`create_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  no longer accumulates memoized results in RAM indefinitely. The
  internal memoization object is now exposed through
  [`mysterycall_clear_isochrone_cache()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clear_isochrone_cache.md).
  Call it after processing a large batch to reclaim memory.

- [`create_isochrones_for_dataframe()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  and
  [`create_individual_isochrone_plots()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  previously called
  [`beepr::beep()`](https://rdrr.io/pkg/beepr/man/beep.html)
  unconditionally even though `beepr` is a suggested package. Both calls
  are now guarded with
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html).

### ✨ New features

- [`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
  gains three new arguments:
  - **`states`** — loops over each state and deduplicates on NPI,
    bypassing the NPI API’s hard 1,200-record-per-query cap. Pass all 50
    state abbreviations to perform a complete national search.
  - **`city`** — optional city filter passed directly to
    [`npi::npi_search()`](https://docs.ropensci.org/npi/reference/npi_search.html).
  - **`limit`** — controls records per API call (max 1,200).
- All mapping and geospatial functions now emit a clear
  [`stop()`](https://rdrr.io/r/base/stop.html) message with the exact
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  command if a required optional package is not installed.

------------------------------------------------------------------------

## mysterycall 1.2.1

Released 2025-10-23.

### 📝 Documentation

- Released to align all metadata artifacts with the package website and
  codemeta specification.
- Introduced an **Imotive News & Changelog** vignette centralizing
  release notes.
- Documented how
  [`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)
  coordinates roster creation, validation, call preparation, and QA for
  Imotive projects.

### ✨ New features

- [`mysterycall_not_contacted_states()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_not_contacted_states.md)
  now ignores rows without affirmative contact outcomes and reports the
  number of unique physicians reached.

### 🗑️ Deprecated

- [`search_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  → use
  [`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)
- [`test_and_process_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  → use
  [`mysterycall_isochrones_for_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_isochrones_for_df.md)
- [`process_and_save_isochrones()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  → use
  [`mysterycall_isochrones_for_df()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_isochrones_for_df.md)

------------------------------------------------------------------------

## mysterycall 0.0.0.9000

### 🌱 Initial development

- Added `NEWS.md` to track changes.
- Verified R-CMD-check workflows on macOS, Windows, and Ubuntu.
- Moved `provider` to `Suggests`; added runtime checks throughout.
- Refactored
  [`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md)
  to use the Genderize.io API, removing the dependency on the non-CRAN
  `genderdata` package.
- Added
  [`mysterycall_geocode()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode.md)
  to simplify geocoding lists of addresses.
- Added vignette skeleton on aggregating provider data.
