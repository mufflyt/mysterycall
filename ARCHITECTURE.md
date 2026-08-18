# Architecture & Codebase Orientation

A map of the **mysterycall** codebase for people who need to *read,
navigate, and extend the code* — not just call it. If you only want to
use the package, start with the README and the pkgdown site. If you’re
about to open a PR, read this first, then
[`CONTRIBUTING.md`](https://mufflyt.github.io/mysterycall/CONTRIBUTING.md)
for the mechanics.

------------------------------------------------------------------------

## 1. What the package does

`mysterycall` provides the common functions for **mystery-caller / audit
studies** that measure patient access to care — studies where trained
callers contact provider offices under different insurance scenarios
(e.g. Medicaid vs. a commercial plan) and record whether an appointment
was offered and how long the wait was. The package covers the whole arc:

1.  **Build the provider roster** — NPI/taxonomy search, address
    normalization, academic classification, census/geography enrichment.
2.  **Clean and validate the call log** — one row per call, with an
    insurance arm and recorded outcomes.
3.  **Analyze** — acceptance-rate disparities and wait-time models
    (Poisson / NB / logistic / linear mixed models), with the
    appropriate clustering and CIs.
4.  **Report** — publication-ready tables, STROBE flow diagrams, and
    prose “results-section” sentences, plus a verifiable provenance
    trail.

## 2. The big picture: a two-phase pipeline

Almost everything hangs off two orchestrator functions. Read these two
files first — they are the spine of the package and name the subsystems
they call:

| Phase | Orchestrator | File | What it does |
|----|----|----|----|
| **Collection / cleaning** | [`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md) | `R/run_mystery_caller_workflow.R` | Roster → validated, de-duplicated, standardized call data (phases 1 & 2). |
| **Analysis** | [`mysterycall_run_analysis()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_analysis.md) | `R/run_analysis.R` | A cleaned call log → QC, dedup, demographics, acceptance rates, wait-time models, sensitivity analyses. Runs as a sequence of named, individually-skippable **steps**. |

      roster building            call cleaning                 analysis
     (NPI / taxonomy /   →   run_workflow()   →   run_analysis(steps = c("qc","dedup",
      census / academic)      (phase 1 + 2)         "clean_medicaid","demographics",
                                                    "scenarios","acceptance_rates",
                                                    "wait_times","poisson","sensitivity"))
                                                            │
                                                            ▼
                                           tables · STROBE flow · results paragraphs · audit trail

`run_analysis()` is a good model of the house style: upfront `checkmate`
validation, an internal `.try()` wrapper so one failing step doesn’t
sink the run, and a per-step `if (col %in% names(data))` guard. See §6
for the column-name contract that ties the two phases together.

## 3. Repository layout

    R/                one file per function (or a small tight cluster); ~260 files
    man/              hand-written .Rd — CHECKED IN, see §5. ~600 topics
    tests/testthat/   test-<name>.R mirrors R/<name>.R; testthat edition 3, parallel
    vignettes/        23 task-oriented articles (getting started, workflow, models, …)
    data/ + data-raw/ bundled datasets (e.g. city_state_to_lat_long) and their builders
    inst/extdata/     shapefiles and fixtures
    _pkgdown.yml      the reference index — every exported function is filed here
    NEWS.md           user-facing changelog under the current dev version

## 4. Subsystem map

The `@family` tag on each function is the authoritative grouping (and
drives the pkgdown reference sections). The major families, largest
first:

- **outcomes** — the analytic core: acceptance rates, wait-time models
  (`poisson_model`, `nb_model`, `logistic_model`, `lmm`), IRR/GMR
  helpers, and the power-analysis simulators (`nb_power`,
  `marginal_power`, …).
- **provider / npi / census / address-normalization /
  academic-indicators** — everything that turns a specialty + geography
  into a validated provider roster.
- **data / data-preparation / data-quality / quality / validation /
  safe-joins** — cleaning, de-duplication, flagging, and joins that
  refuse to silently drop rows.
- **manuscript / reporting / table / green-journal-\*** — publication
  output: `results_paragraph`, Table 1, disparities tables,
  docx/flextable export, STROBE flow, and the “Green Journal”
  (Obstetrics & Gynecology) themed figures.
- **workflow / logging / progress / utilities** — orchestration and
  cross-cutting helpers (structured logging, progress spinners, small
  utilities).

When adding a function, pick the family it belongs to and file it in the
matching `_pkgdown.yml` section.

## 5. The documentation model (read this before touching any `R/` doc)

**Roxygen comments live in `R/`, but the generated `man/*.Rd` files are
checked into the repo and must stay in sync.** The canonical workflow
is:

``` r

devtools::document()   # regenerates man/*.Rd and NAMESPACE from the @ tags
```

Consequences for contributors:

- **Always run `document()` after editing any `#'` block or a function
  signature.** CI does not run it for you; a drifted `.Rd` is a real
  `R CMD check` WARNING (codoc / undocumented-arguments).
- **`@family` is bidirectional.** Adding `@family outcomes` to a
  function makes roxygen rewrite the “Other outcomes:” cross-reference
  in *every* other outcomes `.Rd`. Never hand-edit those lists —
  regenerate.
- **Internal helpers use `@noRd`** (no man page) — most are named with a
  leading dot (`.mc_*`, `.fmt_*`). Exported functions are
  `mysterycall_*` and carry `@param`, `@return`, and at least one
  `@examples`.
- Examples that need a network/API or a heavy optional package are
  wrapped in `\dontrun{}` / `@examplesIf requireNamespace(...)`.

## 6. Conventions worth knowing

These are the non-obvious, project-specific rules — the things a
newcomer trips on:

- **Naming.** Exported = `mysterycall_<verb>()`. Internal = dotted
  (`.mc_format_p`, `.wilson_ci`). Deprecated shims live in
  `R/deprecated.R`.
- **Input validation.** Prefer `checkmate::assert_*`; where
  [`stopifnot()`](https://rdrr.io/r/base/stopifnot.html) is used it
  carries a *named* message:
  `stopifnot("`data`must be a data frame" = is.data.frame(data))`.
- **Optional dependencies.** Anything in `Suggests` (ggplot2, survival,
  lme4, glmmTMB, mice, sf, tidycensus, gt, …) is guarded with
  [`requireNamespace("pkg", quietly = TRUE)`](https://rdrr.io/r/base/ns-load.html)
  before first use — never
  [`library()`](https://rdrr.io/r/base/library.html) inside a function.
- **RNG hygiene.** Functions that need a seed use
  `withr::local_seed(seed)`, not
  [`set.seed()`](https://rdrr.io/r/base/Random.html), so they don’t
  clobber the caller’s global random stream.
- **Locale-independent reproducibility.** Sorts whose result affects
  output — a model’s reference level, a provenance hash’s key order —
  use `sort(..., method = "radix")` so they don’t depend on
  `LC_COLLATE`.
- **The phase-2 column contract.** `run_workflow()` renames incoming
  columns to short “standard” names (`reason_for_exclusions` →
  `exclusion_reasons`). `run_analysis()` documents the *long* names as
  defaults but tolerates the short aliases via `.mc_resolve_col()` — so
  the two chain cleanly. If you add a column parameter that both touch,
  wire it through that helper.
- **P-values.** `.mc_format_p()` (in `R/format_pvalue.R`) is the single
  source of truth for p-value strings in tables (`"< 0.001"` /
  `"0.043"`). Manuscript prose uses the spaced `"p < 0.001"` /
  `"p = 0.043"` convention.
- **Wait-time outcome.** The canonical wait-time column is
  `business_days_until_appointment`; `calendar_days` is a documented
  *secondary* column for calendar-vs-business sensitivity.

## 7. Testing conventions

- `test-<name>.R` mirrors `R/<name>.R`; `testthat` edition 3, run in
  parallel (`Config/testthat/parallel: true`).
- Label pattern: `test_that("fn: case → expected", ...)`.
- Guard tests needing a `Suggests` package with
  `skip_if_not_installed("pkg")`.
- Every `test_that` must actually assert — no empty “doesn’t error”
  blocks; use `expect_no_error()` if that really is the assertion.
- Do **not** use `skip_on_cran()` to hide a failing test.

## 8. Adding a new function, end to end

1.  Create `R/<name>.R`. Add roxygen: `@family <group>`, `@param`,
    `@return`, `@seealso` to the related functions, and at least one
    `@examples`.
2.  `devtools::document()` to generate `man/<name>.Rd` and update
    `NAMESPACE`.
3.  File the function in the right `_pkgdown.yml` reference section.
4.  Add `tests/testthat/test-<name>.R` — happy path + `NA`/empty input.
5.  Add a `NEWS.md` bullet under the current dev version.
6.  `devtools::check()` → 0 errors / 0 warnings.

## 9. Where to start reading

- **The analysis spine:** `R/run_analysis.R` — shows the step model,
  validation, and how the outcome subsystems are called.
- **A model, end to end:** `R/poisson_model.R` (or `R/lmm.R`) — fitting,
  the reference-level pick, IRR/GMR tables, and the
  [`print()`](https://rdrr.io/r/base/print.html) method.
- **Reporting:** `R/results_paragraph.R` — how model output becomes a
  sentence.
- **Provenance:** `R/clean_phase_1_results.R` (writer) and
  `R/audit-verify.R` (reader) — the audit-trail hash and its
  verification.
- **Collection:** `R/run_mystery_caller_workflow.R` — the
  phase-1/phase-2 flow.

Questions that aren’t answered here belong in a [GitHub
Issue](https://github.com/mufflyt/mysterycall/issues).
