# Changelog

## mysterycall 1.6.3.9000 (development version)

### Bug fixes

- [`mysterycall_run_analysis()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_analysis.md)
  no longer emits a deprecation warning on every run. Its
  `acceptance_rates` step now calls an internal worker
  (`.mc_insurance_acceptance_rates()`) instead of the deprecated
  [`mysterycall_insurance_acceptance_rates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_acceptance_rates.md),
  with identical output. The public deprecated function is unchanged
  (still works and still warns for external callers).
- [`mysterycall_compare_waves()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compare_waves.md)
  now returns an `iqr` (interquartile range) column for continuous
  outcomes, alongside the existing `q1` / `q3`, matching its documented
  headline statistics and the test expectations.
- Refreshed the
  [`mysterycall_overdispersion_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_sentence.md)
  test snapshot to match the graduated “Mild overdispersion” wording the
  function now emits.
- Added the 68 documented-but-unindexed topics (datasets,
  [`print()`](https://rdrr.io/r/base/print.html) /
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  methods, and additional exported functions) to the pkgdown reference
  index so
  [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
  no longer errors on missing topics.

### Census geography vintage

The 2020 Census redrew tracts, block groups, and ZCTAs. Several paths
could cross that boundary and fail silently as `NA` rather than
erroring. All four are now closed.

- **Census benchmark and vintage are pinned package-wide** via the new
  internal constants `.MC_CENSUS_BENCHMARK` and `.MC_CENSUS_VINTAGE`
  (`Public_AR_Current` / `Census2020_Current`).
  [`mysterycall_geocode_address()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode_address.md)
  previously defaulted to `vintage = "Current_Current"`, which tracks
  whatever the Bureau currently serves, while its documentation promised
  2020 GEOIDs. Both vintages return identical geography today, so
  results do not change; the pin makes the documented behavior a
  guarantee instead of a coincidence, and keeps the geocoder in step
  with the 2020-vintage bundled datasets.

- **Geography layers are now matched by substring, not exact name.** The
  geocoder renames layers between vintages – the ZCTA layer is
  `"Zip Code Tabulation Areas"` under `Census2020_Current` but
  `"2020 Census ZIP Code Tabulation Areas"` under `Current_Current`. The
  old exact-string lookup would have returned `NA` for every row after a
  rename, silently zeroing ADI and SVI. New internal helper
  [`.mc_geo_layer()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_geo_layer.md).

- **[`mysterycall_assign_area_covariates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_area_covariates.md)
  now warns** when the geocoder answers successfully but returns no ZCTA
  layer, which distinguishes a vintage or layer-name break from ordinary
  geocoding loss. Previously both looked like uniformly missing
  covariates.

- **ACS pulls warn when the requested year predates the bundled boundary
  vintage.**
  [`mysterycall_get_acs_adults_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_adults_18_90.md),
  [`mysterycall_get_acs_women_18_90()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_acs_women_18_90.md),
  and
  [`mysterycall_get_payer_mix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_payer_mix.md)
  accept years back to 2009/2012, but the bundled `adi_zcta`,
  `svi_zcta`, and `zcta_tract_xwalk` are 2020-vintage (2018–2022 ACS).
  Joining a pre-2022 pull at a boundary-sensitive geography to those
  datasets silently drops split, merged, or renumbered areas. Silence
  with `options(mysterycall.quiet_vintage = TRUE)` when the mismatch is
  intended. New internal helper
  [`.mc_check_acs_vintage()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_acs_vintage.md).

### Documentation

- [`mysterycall_classify_ruca()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_ruca.md)
  no longer claims a RUCA crosswalk is “bundled in this package” – none
  is, and the same help page already directed users to USDA ERS. Adds a
  vintage warning: 2010 RUCA files are keyed to 2010 tracts, which will
  not join cleanly to the 2020-vintage tract GEOIDs this package
  produces.

- `CITATION.cff` and `codemeta.json` reported version 1.4.0 while
  `DESCRIPTION` and `NEWS.md` were at 1.6.3.9000. Synced.

### New features

- [`mysterycall_census_female_population()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_census_female_population.md):
  fetch the **total female population** denominator by year (ACS table
  B01001, `B01001_026E`) via `tidycensus`, returning a year-named vector
  or `data.frame(year, population)` that plugs straight into the
  `population` argument of the density figures. Handles the missing ACS
  1-year 2020 table via `fill_2020` (substitute 5-year, skip, or error).
- New **“Subspecialist density per 100,000 women”** vignette walks the
  full path (counts + denominator → density → trend/infographic) with
  confidence intervals and provenance, and the three new functions are
  added to the pkgdown reference index.
- Both subspecialist-density figures now carry **detailed provenance**.
  Each records a structured `mysterycall_provenance` object — metric,
  computation, numerator/denominator descriptions and citations,
  denominator vintage, scale, year range, generating call, package
  version, data-access date, and creation timestamp — attached as
  `attr(figure, "provenance")` and printed by a
  `print.mysterycall_provenance` method. A source caption is drawn on
  the figure (auto-built from the citations, overridable or
  suppressible), and saving the image also writes provenance sidecars
  containing the full record plus the per-point value table: a
  human-readable `<output>.provenance.txt` and, when `jsonlite` is
  installed, a machine-readable `<output>.provenance.json` (schema
  `mysterycall/provenance`) for downstream pipelines. New arguments:
  `numerator_source`, `denominator_source` (defaulting to the Census ACS
  `B01001_026E` citation), `denominator_vintage`, `accessed`, `notes`,
  `caption`, `write_provenance`.
- [`mysterycall_subspecialist_trend()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_trend.md)
  gains a `trend_test` argument: fits a per-subspecialty log-linear
  regression of count on year with an offset of `log(population)`
  (Poisson or `"quasipoisson"`) and attaches the tidy result as
  `attr(p, "trend_test")` — annual rate ratio, confidence interval,
  percent change per year and over the span, and the year-term p-value.
  The statistics fold into the `.txt`/`.json` provenance sidecars, and
  (with `label_ends`) each line label shows the rate ratio per year and
  a significance star.
- [`mysterycall_subspecialist_trend()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_trend.md)
  gains a `conf_level` argument: when set (e.g. `0.95`) it computes an
  **exact Poisson confidence interval** for each rate (base R, no new
  dependency), draws it as a shaded band per subspecialty, and adds
  `density_low` / `density_high` to the returned `$data`. The interval
  method is recorded in the provenance.
- [`mysterycall_subspecialist_trend()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_trend.md):
  a multi-year density trend (one line per subspecialty) of
  **subspecialists per 100,000 women**, computed from **raw counts**
  (numerator) divided by the **total female population** (denominator).
  The density is derived from the inputs (`count / population * per`),
  never typed. Accepts counts as a long/wide data frame or a matrix, and
  the female- population denominator as a year-named vector, an ordered
  vector, or a data frame; the docs include the exact Census ACS
  `B01001_026E` call to fetch the denominators. Population figures are
  intentionally **not** bundled (they need to be a cited vintage).
  Returns a `ggplot` whose `$data` carries the computed density table.
- [`mysterycall_subspecialist_infographic()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_infographic.md):
  a workforce-density infographic (titled header bar over one
  accent-coloured panel per subspecialty), styled after the “clinicians
  per unit” figures, repurposed to show **subspecialists per 100,000
  women** at two time points. Defaults to the four ABOG OB-GYN
  subspecialties; takes the density values as `start`/`end` vectors or a
  `data` frame and derives the percent change from them (so the figure
  can never disagree with its own numbers). Returns a `ggplot` object
  and can save via `output_path`.
- [`mysterycall_strobe_flow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_flow.md)
  gains an `engine` argument. The default `engine = "ggplot2"` is
  unchanged. New `engine = "gmisc"` renders the *same* pipeline-derived
  counts with the Gmisc grid engine
  ([`Gmisc::boxGrob()`](https://rdrr.io/pkg/Gmisc/man/box.html) /
  [`Gmisc::connectGrob()`](https://rdrr.io/pkg/Gmisc/man/connect.html)),
  whose boxes auto-size to their text and whose connectors re-route
  automatically – so long per-code exclusion lists no longer overflow
  the fixed-coordinate ggplot2 layout. The count derivation
  ([`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md)
  waterfall, exclusion summary, and the logistic/wait-time analytic
  samples) is shared by both engines, so the diagram cannot disagree
  with the models regardless of renderer. Gmisc is a `Suggests`-only
  dependency; the ggplot2 default needs nothing new. The gmisc engine
  returns a grid `gTree` and supports the same `output_path` saving
  (png/tiff/jpeg/pdf/svg, with raster format pairing).

### Consolidation and deprecation

- [`mysterycall_acceptance_rate_calc()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate_calc.md)
  gains a `medicaid_screen_group` argument that restricts the
  `medicaid_accept_col` NA-screen to named insurance group(s) instead of
  applying it to all groups. This lets the general calculator reproduce
  the one behavior only the hardcoded two-group helper could – an
  asymmetric Medicaid-only screen, so a Medicaid-accept field that is
  `NA` on non-Medicaid rows no longer zeroes those groups’ rates.
- [`mysterycall_insurance_acceptance_rates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_acceptance_rates.md)
  is **deprecated** in favor of
  `mysterycall_acceptance_rate_calc(medicaid_screen_group = "Medicaid")`,
  of which it is the two-group (Medicaid/BCBS) special case. It still
  works and keeps its exact manuscript paragraph.
- Added mutual `@seealso` links across the overlapping ZIP cleaners
  (`clean_zip` / `extract_zip5` / `normalize_zip5`), the wait-time
  summaries (`wait_time_by_group` / `wait_time_summary`), and the
  emmeans plotters (`plot_emmeans` / `plot_emmeans_interaction` /
  `plot_emmeans_full`) to clarify which to use.

### New functions

Generalized from the `isochrones` ENT access study (power/GLM) and the
original urogyn `mystery_shopper_data` study (data prep), which
hand-rolled them – filling the package’s missing power quadrants and
reusable field-cleaning helpers:

- [`mysterycall_adjusted_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_adjusted_power.md):
  Monte Carlo power for a covariate-adjusted negative-binomial GLMM with
  a **cluster ICC** – a rural (exposure) fixed effect, a subspecialty
  fixed effect, nuisance adjustment covariates, and a state-level random
  intercept whose SD is derived from a target ICC
  (`sigma = sqrt(ICC/(1-ICC) * 1/phi)`). Fills the gap left by the
  existing physician-clustered power tools, which cannot express a
  higher-level cluster as an ICC or adjust for confounders (`glmmTMB`).
- [`mysterycall_ttest_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ttest_power.md):
  analytic two-group **continuous-outcome** power (Cohen’s d) with an
  unequal-allocation solver, for a study with a fixed natural exposure
  fraction (e.g. 15% rural). The package’s other analytic power tools
  are all count/binary (`pwr`).
- [`mysterycall_lm_interaction_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lm_interaction_power.md):
  analytic Cohen’s f-squared power for each main effect and interaction
  of a saturated factorial model, at small/medium effect sizes (`pwr`).
- [`mysterycall_parse_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_duration.md):
  parse messy free-text call durations (`"1min 45 sec"`, `"1.5min"`,
  `"30sec"`, a bare number, `"O"`) to seconds or minutes – replaces the
  brittle per-study lookup table for hold-time and call-length fields.
- [`mysterycall_clean_zip()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_zip.md):
  take the first ZIP when several are present, strip a ZIP+4 suffix, and
  left-pad to five digits (restoring leading zeros lost to numeric
  parsing).
- [`mysterycall_categorize_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_categorize_wait.md):
  bin a days-to-appointment vector into weekly categories plus a binary
  “\>N-week wait” threshold flag, standardizing the headline-outcome
  convention.
- [`mysterycall_link_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_link_physicians.md):
  probabilistic record linkage of two physician lists that share no key,
  via `fastLink` Jaro-Winkler name matching with optional blocking – for
  reconciling a called cohort against an external roster when there is
  no NPI (`fastLink`).

Generalized from the `labubu` mystery-caller study, which hand-rolled
them – design-integrity checks, a population-average sensitivity model,
and two matched figures that were previously inline in the study’s
analysis scripts:

- [`mysterycall_scenario_coverage()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_coverage.md):
  per-cluster scenario-coverage table for a matched multi-scenario audit
  – how many practices were reached under the full set of scenarios
  (complete) versus a partial set or a single scenario, plus a
  missing-count per scenario. A design-integrity guard, since an
  unmatched cluster key silently becomes a one-scenario singleton and
  deflates the paired denominator of
  [`mysterycall_paired_acceptance_mcnemar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_acceptance_mcnemar.md)
  /
  [`mysterycall_paired_wait_within_practice()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_wait_within_practice.md).
  [`print()`](https://rdrr.io/r/base/print.html) and
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  methods.

- [`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md):
  edit-distance (`adist`) near-duplicate detector over cluster keys –
  catches the mistyped grouping value (`"Womens"` vs. `"Women's"`) that
  [`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md)
  cannot, because the strings differ. Flags a pair when its raw or
  length-normalized edit distance is within threshold; the safety net
  that keeps a typo from splitting one practice into two clusters.

- [`mysterycall_gee()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_gee.md):
  population-average GEE (`geepack`, exchangeable working correlation,
  robust SEs) as a marginal companion to the subject-specific
  [`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md)
  GLMM – uses every record including the singletons and dyads a matched
  analysis drops. Returns an odds-ratio table with a complete-separation
  flag; [`print()`](https://rdrr.io/r/base/print.html) and
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  methods.

- [`mysterycall_plot_raincloud()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_raincloud.md):
  violin + boxplot + jittered-points figure of a numeric outcome by
  group (the canonical skewed-wait-time-by-scenario plot).

- [`mysterycall_plot_paired_slope()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_paired_slope.md):
  within-cluster slope plot – one line per practice across the scenarios
  it was called under – the visual companion to the matched paired
  analyses.

- [`mysterycall_hurdle_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hurdle_wait.md):
  a two-part hurdle model for a mystery-caller wait time, generalized
  from the private-equity urogynecology audit. Fits a binary hurdle
  (appointment obtained yes/no) and a zero-truncated negative-binomial
  count model for the wait among obtained appointments, each with an
  optional practice random intercept so the clustered structure of an
  audit is respected – an advantage over `pscl::hurdle()`, which cannot
  cluster. The negative-binomial count part absorbs the skew and
  overdispersion that a normal-outcome selection (Heckman) model cannot;
  it assumes selection on observables, and any residual
  selection-on-unobservables concern is addressed with a sensitivity
  analysis
  ([`mysterycall_outcome_bounds()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_outcome_bounds.md)
  Manski bounds or
  [`mysterycall_leave_one_out()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_leave_one_out.md))
  rather than a Heckman correction. Returns odds-ratio and
  incidence-rate-ratio tables plus both fitted models, with
  [`print()`](https://rdrr.io/r/base/print.html) and
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  methods.

## mysterycall 1.6.3

### New functions

Reporting artifacts for supplementary digital content:

- [`mysterycall_crisp_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_crisp_checklist.md):
  a fillable simulated-patient (CRiSP-style) reporting checklist
  covering the covert-methodology items a generic STROBE checklist omits
  (justification of the covert method, caller recruitment and training,
  detection/contamination, ethics of deception, limitations of the
  method). Companion to
  [`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md).
- [`mysterycall_model_equation()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_equation.md):
  render a fitted GLM(M) as a LaTeX equation (link-transformed outcome
  over the fixed-effect terms plus a random intercept), dependency-free
  – reads the family/link, terms, and grouping factor off the fit.
  Symbolic form by default (with a term legend) or with fitted
  coefficients substituted; wraps in `$$...$$` for R Markdown.

Case-control design tooling, generalized from a private-equity-ownership
mystery-caller study:

- [`mysterycall_build_matched_controls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_build_matched_controls.md):
  builds a propensity-score-matched control cohort – fit a propensity
  model on treated units vs. a candidate pool, then greedily match each
  treated unit 1:1 to its nearest control on the propensity score,
  within an exact stratum (e.g. same state) and an optional geographic
  caliper, without replacement. Returns matched pairs, the matched rows
  from each arm, the propensity model, and a covariate-balance table.
  The “callable control” constraints (same state, short drive) are the
  ones audit teams actually impose and that off-the-shelf matchers do
  not express directly.
- [`mysterycall_geocode_city_state()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geocode_city_state.md):
  look up latitude/longitude for a city + two-letter state against the
  bundled ~32,000-place table (no network, no API key) – enough to seed
  a distance caliper or QC how far apart matched practices sit. Supports
  a manual-override table for places the bundled data misses.
- [`mysterycall_normalize_org_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_org_name.md):
  normalize organization / practice names to a canonical join key
  (upper-case, expand `&`, drop apostrophes/periods and legal-entity
  suffixes like LLC/PC/PA, squish) so the same practice compares equal
  when matching a caller cohort against an external roster.

### Documentation

- New vignette **“Assembling supplementary digital content”**: generates
  a journal manuscript’s supplementary package from the fitted models
  and call log – model equations in LaTeX, the crude-vs-adjusted model
  table, disparity table, absolute-scale effect, literature comparison,
  a missing-data analysis, a per-caller evaluation, forest /
  cumulative-access figures at journal specification, an interactive
  Leaflet practice map and an ACOG-district choropleth, the STROBE
  **and** CRiSP reporting checklists, non-response bounds and
  leave-one-caller-out sensitivity analyses, and export to workbook /
  Word / CSV.
- New vignette **“Designing a matched-control mystery-caller audit”**:
  an end-to-end case-control workflow (geocode a roster, build a
  propensity-score-matched control cohort inside a geographic caliper,
  assemble the paired calling list, and analyse the completed audit with
  the matched McNemar and paired-wait tests), motivated by a
  private-equity-ownership study.
- New vignette **“A matched-pair mystery-caller analysis”**: a worked,
  end-to-end analysis on a simulated paired call log that exercises the
  tools added in 1.6.2 together – a clustering key, two data-integrity
  passes, the access cascade, non-response bounds, the cumulative-access
  curve, the matched McNemar and paired-wait comparisons, small-sample
  categorical and rank tests, outcome classification and guideline
  concordance, an adjusted model with a joint test and leave-one-out
  sensitivity, and simulation-based power.

## mysterycall 1.6.2

### New functions

Matched-pair within-practice analyses, generalized from the `labubu`
mystery-caller study (which hand-rolled them). The matched-pair design –
the same practice called under two scenarios (insurance types, caller
personas) – is the package’s core paradigm, but the package previously
offered only the unmatched GLMM; these add the matched comparison that
removes each practice’s baseline generosity:

- [`mysterycall_paired_acceptance_mcnemar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_acceptance_mcnemar.md):
  exact McNemar test on a binary acceptance outcome for each pairwise
  scenario contrast – discordant split, odds ratio, exact p-value, and
  the minimum detectable odds ratio at a chosen power (effective n is
  the discordant count, since only discordant practices carry
  information).
- [`mysterycall_paired_wait_within_practice()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_paired_wait_within_practice.md):
  the continuous analogue – pairs practices called under both scenarios,
  reports the mean within-practice wait difference with a paired-t CI,
  the paired t-test and Wilcoxon signed-rank p-values, and the minimum
  detectable difference in days.

(Scenario-stratified acceptance/wait summaries the same study also
produced are already covered by
[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md)
and
[`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md)
with `group_by = "scenario"`, so no new function was added for those.)

A third batch, generalized from `grace-ent`’s reviewer-response analyses
– model-robustness and non-response reporting helpers:

- [`mysterycall_outcome_bounds()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_outcome_bounds.md):
  Manski-style worst-case / best-case bounds on a proportion under
  non-response (assign every incomplete call first to failure, then to
  success, over the full sampling universe), alongside the complete-case
  rate with a Wilson CI. The assumption-free interval reviewers ask for
  so a headline offer/acceptance rate is not quietly conditioned on
  completed calls.
- [`mysterycall_joint_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_joint_test.md):
  joint likelihood-ratio test of a multi-level predictor (is
  subspecialty / caller / insurance significant *as a block*?),
  refitting without every term that involves the predictor. The
  statistic is computed from the log-likelihoods (`chi^2 = 2 dlogLik`,
  `df =` parameter-count difference), which sidesteps a real footgun –
  [`lme4::glmer`](https://rdrr.io/pkg/lme4/man/glmer.html) labels the
  LRT degrees-of-freedom column `"Df"` while `glmmTMB` labels it
  `"Chi Df"`, and reading the wrong one yields the total parameter count
  and a wrong p-value.
- [`mysterycall_leave_one_out()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_leave_one_out.md):
  leave-one-group-out refit sensitivity – drop each level of a grouping
  variable (e.g. each caller/site), refit, and tabulate how a target
  coefficient (and, optionally, a factor’s joint p) moves, to show an
  estimate does not hinge on any single group. Composes with
  [`mysterycall_joint_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_joint_test.md).

A second batch generalized from the downstream ENT study (`grace-ent`) –
clustering, single-contact time-to-appointment, and simulation-based
power for the two-part / population-marginal designs these studies
actually use:

- [`mysterycall_cluster_id()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cluster_id.md):
  coalesce a random-intercept/grouping key from an ordered list of
  columns (e.g. CBSA -\> county FIPS), giving each still-missing row its
  own singleton cluster. Closes a footgun – the model fitters require a
  `random_intercept` column but the package previously gave you nothing
  to build one, and blank/`NA` keys silently collapse into one giant
  cluster and corrupt the random-effect variance.
- [`mysterycall_cumulative_access_curve()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cumulative_access_curve.md):
  the empirical cumulative proportion of calls that had secured an
  appointment by business-day `t` – the correct primitive for a
  single-contact design, where
  [`mysterycall_kaplan_meier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_kaplan_meier.md)’s
  right-censoring of non-offered calls implies follow-up the design does
  not have. Each curve plateaus at the share obtained within the horizon
  (the offer rate when every wait falls inside it). Optional step-curve
  figure.
- [`mysterycall_twopart_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_twopart_power.md):
  Monte Carlo power for the two-part outcome (offer as a Bernoulli on
  the full sample; wait as a negative binomial on the offered subset)
  that access audits universally have – reports the power for each part
  separately, since a single-outcome calculator understates the wait
  model’s sample (it runs on the offered subset). Depends only on
  `MASS`.
- [`mysterycall_marginal_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_power.md):
  Monte Carlo power for a post-stratification-weighted,
  population-marginal effect in a paired-call design (each subject
  called under two conditions; a stratum oversampled in the sample but
  reweighted to a target population mix). Reports power for the
  conditional interaction, the unweighted marginal effect, and the
  population-weighted marginal effect. Needs `glmmTMB` +
  `marginaleffects`.
- [`mysterycall_type_i_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_type_i_check.md)
  and
  [`mysterycall_find_mde()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_find_mde.md):
  generic companions to any simulation power function – a
  null-calibration self-check (observed type I rate + exact binomial
  CI + verdict) and a minimum-detectable-effect binary search over a
  user-supplied power function.

Generalized from analysis logic that the downstream ENT study
(`grace-ent`) had been hand-rolling in its own scripts, so every
mystery-caller study inherits it:

- [`mysterycall_access_cascade()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_access_cascade.md)
  (+
  [`mysterycall_cascade_stage()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cascade_stage.md)):
  summarizes a sequence of access constructs across the call pathway
  (reached a live office -\> accepting new patients -\> sees the
  presented complaint -\> appointment offered -\> with whom) as a tidy
  count / denominator / percent table with Wilson confidence intervals,
  plus an optional funnel figure. Denominators may be the full analytic
  sample (`"total"`), a strictly nested previous stage (`"previous"`),
  another named stage (for “share of offers”-style sub-breakdowns), or a
  fixed number – so one call mixes a nested funnel with conditional
  sub-measures. Depends only on base R (+ `ggplot2` for the figure).

- [`mysterycall_reconcile_offer_outcome()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_offer_outcome.md):
  finds and optionally fixes rows where a coarse binary “appointment
  offered” flag contradicts a granular disposition field, in both
  directions (flag understates vs. overstates the outcome), treating the
  granular outcome as authoritative and clearing dependent fields (wait
  time, appointment date) when a row flips to “not offered”. Fills a gap
  the `mysterycall_flag_*` family did not cover (they compare exclusion
  reason vs. wait time, never a summary boolean vs. a disposition).

- [`mysterycall_check_consistency()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_consistency.md)
  (+
  [`mysterycall_consistency_rule()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_consistency_rule.md)
  and
  [`mysterycall_default_consistency_rules()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_default_consistency_rules.md)):
  a declarative cross-field rule engine – the general form of the
  one-off `mysterycall_flag_*` checks. Runs a list of rules over a call
  log and returns a single priority-sorted correction worklist (flag /
  priority / description / action per flagged row). Ships a
  study-agnostic starter rule set (appointment date with no answered
  office, taking-new-patients with no appointment date, complete record
  with no call date, missing caller, and `WAIT_NO_OFFER` – a wait time
  recorded when no appointment was offered, the detector companion to
  [`mysterycall_reconcile_offer_outcome()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_offer_outcome.md))
  whose column names are configurable and which no-op on logs missing
  those fields.

- [`mysterycall_export_gsheet_caller_list()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_gsheet_caller_list.md):
  writes a mystery-caller list in Google-Sheets import format
  (study-title row; name/phone/NPI/`<stage>` header; ordered by state
  with matched pairs kept adjacent; CRLF line endings and minimal
  quoting for clean spreadsheet round-tripping). Depends only on
  `readr`/`checkmate`. (Recovered from a stale feature branch and
  re-landed on current `main`.)

### Manuscript-output improvements

Fixes for issues previously worked around by editing package source or
post-processing in downstream study scripts – now parameters/functions
so every study inherits them:

- [`mysterycall_multi_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_model_table.md)
  gains `cell_layout`. The default `"stacked"` keeps the p-value on a
  second line (correct for gt/HTML and the console print method);
  `"inline"` puts the whole cell on one line
  (`"1.45 (1.02-2.05), p=0.038"`) so the table renders correctly in a
  Markdown/pandoc **pipe table**, which cannot hold a multi-line cell
  (the embedded newline otherwise spilled every p-value onto its own
  row).
- [`mysterycall_kaplan_meier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_kaplan_meier.md)
  gains `ylab` (was a hardcoded label). The default is now the
  plain-language `"Callers still awaiting an appointment (%)"`.
- [`mysterycall_forest_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_forest_plot.md)
  and
  [`mysterycall_irr_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_plot.md)
  gain `show_significance_legend` (default `FALSE`). When `TRUE`, a
  single `"p < 0.05"` / `"n.s."` legend is drawn; the default keeps the
  current legend-free look.
- New
  [`mysterycall_region_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_region_labels.md):
  one row per US state with its AAO-HNS (or ACOG / Census) region and an
  approximate centroid, ready to overlay on a state choropleth as a
  [`geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html)
  layer. Dependency-free (base `state.center` +
  [`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md)).

### Bug fixes

- Adversarial / semantic / boundary-value test suites for the
  concordance, categorical, and call-outcome modules (211 new tests)
  surfaced and fixed:
  - [`mysterycall_multiresponse_tabulate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multiresponse_tabulate.md)
    now counts **distinct** options per call, so a call listing the same
    option twice no longer inflates `mean_options_per_call` (prevalence
    and co-occurrence already deduped).
  - [`mysterycall_concordance_kappa()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_kappa.md)
    now errors when the two rater frames have unequal row counts and no
    `call_id_col` (previously it silently recycled the shorter column
    and misreported `n`); it also validates that the item columns are
    present.
  - [`mysterycall_cmh_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cmh_test.md)
    and
    [`mysterycall_ordinal_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ordinal_model.md)
    now raise clear, actionable errors for degenerate inputs (a single
    stratum; a fewer-than-3 level outcome) instead of leaking the
    underlying `mantelhaen.test` / `polr` messages.

### New functions

- **Multi-category / multi-response call outcomes**
  (`R/call_outcomes.R`), the third roadmap item, turning the binary “did
  they book?” into the graded, multi-state outcomes these audits
  actually measured:
  - [`mysterycall_multiresponse_tabulate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multiresponse_tabulate.md)
    summarises a “check-all-that-apply” outcome (e.g. the set of pain
    options a clinic offers): per-option prevalence with Wilson
    intervals, an option co-occurrence matrix, and options-per-call
    summaries, optionally by group. Non-responding calls (`NA`) are
    excluded from denominators; a call that responded but named nothing
    still counts.
  - [`mysterycall_classify_call_outcome()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_call_outcome.md)
    maps raw/free-text dispositions to a standard call-outcome taxonomy
    (appointment offered, declined, insurance-verification / referral /
    records required, new-patient restriction, phone gatekeeping, not
    reached) via an overridable keyword map.
  - [`mysterycall_outcome_gradient()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_outcome_gradient.md)
    summarises an ordered multi-category outcome (an access tier, a
    triage disposition) with per-level Wilson intervals and cumulative
    proportions.
  - [`mysterycall_ordinal_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ordinal_model.md)
    fits a proportional-odds model (via
    [`MASS::polr`](https://rdrr.io/pkg/MASS/man/polr.html)) for a graded
    ordinal outcome, returning odds ratios with Wald intervals and
    p-values.
- **Small-sample categorical statistics toolkit** (`R/categorical.R`),
  the second roadmap item from the audit-study synthesis. A
  dependency-free layer for the contingency-table designs these studies
  actually use, where the GLMM core is overkill:
  - [`mysterycall_test_categorical()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_categorical.md)
    cross-tabulates two variables and tests association, auto-selecting
    between Pearson’s chi-squared and an exact test (Fisher, or
    Fisher-Freeman-Halton for larger tables) by expected cell counts,
    reports Cramer’s V, and can add Benjamini-Hochberg-adjusted post-hoc
    pairwise proportion comparisons for a binary outcome.
  - [`mysterycall_cmh_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cmh_test.md)
    runs a Cochran-Mantel-Haenszel test across a matching stratum
    (within-unit / paired persona designs), with the common odds ratio
    for the 2x2xK case.
  - [`mysterycall_prevalence_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prevalence_ci.md)
    gives per-category prevalences with Wilson, Clopper-Pearson, or Wald
    intervals, optionally within a grouping variable.
  - [`mysterycall_compare_ranks()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_compare_ranks.md)
    runs Kruskal-Wallis / Mann-Whitney with an effect size and per-group
    medians (IQR) for skewed numeric outcomes.
- **Guideline-concordance scoring engine** (`R/concordance.R`),
  scaffolded from a synthesis of eight mystery-caller audit studies.
  Scores what staff *said* or *did* against a reference standard at the
  item level, then rolls up to call- and study-level summaries:
  - [`mysterycall_concordance_rubric()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_rubric.md)
    builds the reference standard from four item types — `binary`,
    `expected_present`, `reference_match` (per-row gold standard), and
    `evidence_tier` (named options scored against a date-versioned
    lookup).
  - [`mysterycall_score_concordance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_score_concordance.md)
    returns per-item concordance rates with Wilson CIs, per-call
    composite scores, an overall summary, and an optional per-group
    breakdown. Item denominators track applicability separately from the
    call count, so within-encounter conversation exits are handled
    natively.
  - [`mysterycall_concordance_kappa()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_kappa.md)
    computes per-item Cohen’s kappa and percent agreement across two
    raters.
  - [`mysterycall_concordance_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_concordance_sentence.md)
    emits numbers-locked manuscript prose (overall composite or per
    item), in the existing prose-builder family.

## mysterycall 1.6.1

### Improvements

- [`mysterycall_kaplan_meier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_kaplan_meier.md)
  figure polish:
  - New `legend_title` argument. The legend title now defaults to a
    prettified `group_col` (e.g. `"sub4"` -\> `"Sub4"`,
    `"insurance_type"` -\> `"Insurance Type"`) instead of the raw
    variable name; pass an explicit string
    (`legend_title = "Subspecialty"`) or `""` to drop it.
  - Empty factor levels in `group_col` are now dropped
    ([`droplevels()`](https://rdrr.io/r/base/droplevels.html)). An
    unused level previously desynced
    [`nlevels()`](https://rdrr.io/r/base/nlevels.html) from the fitted
    strata, which surfaced as stray `-N` suffixes on the risk-table row
    labels (or a hard row-count error).
  - Tightened styling: risk-table columns align with the curve gridlines
    (shared breaks), the first group sits at the top of the risk table,
    the number-at- risk counts at day 0 are no longer clipped, the
    risk-table row labels are bold and colour-matched to the curves, and
    the legend renders on a single row with thicker keys.

### New functions

- [`mysterycall_get_direction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md)
  and
  [`mysterycall_get_change_verb()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md):
  manuscript/ abstract helpers that pick a direction word
  (“higher”/“lower”, “increasing”/“decreasing”, etc.) from the **sign of
  the data**, so prose can never contradict the numbers it describes.
  Vectorized, NA-safe, with a `tol` no-change band and fully
  configurable words per subspecialty/table.

### Bug fixes

- `mysterycall_clean_phase1(duplicate_rows = FALSE)` no longer
  fabricates an `insurance` label by row-number parity (which made a
  physician’s insurance depend on alphabetical sort position). In
  non-paired mode the `insurance` column is now set to `NA` with a
  warning, so callers assign it from their own data. The default paired
  path (`duplicate_rows = TRUE`) is unchanged. (Bug 21)

### Documentation

- New vignette **“Writing the Results Section”**
  (`writing-results-section`): assembles a ready-to-paste manuscript
  Results narrative from the prose builders
  ([`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
  [`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
  [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
  [`mysterycall_wait_time_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_sentence.md),
  [`mysterycall_get_direction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md)
  /
  [`mysterycall_get_change_verb()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md)),
  with every direction word tied to the sign of the data so the prose
  can never contradict the tables. Runs on plain data frames, so it
  builds fast and needs no model fitting.

### Covariate reader hardening

- [`mysterycall_get_cms_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_cms_enrollment.md)
  and
  [`mysterycall_get_hrsa_ahrf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_hrsa_ahrf.md)
  now validate their input schema up front and fail with an explicit
  message that names the missing column(s)/table and what was actually
  found, instead of an opaque
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html)
  or SQL error deep in the call. Both functions’ documentation now
  spells out the exact expected schema (`get_hrsa_ahrf` requires a
  preprocessed `ahrf_county_data` DuckDB table — the raw fixed-width
  AHRF is not read directly; CSV input is not supported).
- [`mysterycall_get_cms_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_cms_enrollment.md)
  matches FIPS leading-zero-safe:
  [`read.csv()`](https://rdrr.io/r/utils/read.table.html) parses
  `"08031"` as the integer `8031`, so numeric FIPS (in the CSV and in
  the `county_fips` argument) are now left-padded to five characters
  before matching, and the returned `FIPS` column is a zero-padded
  string.
- Added offline, fixture-based tests (temp CSV / temp DuckDB) for
  [`mysterycall_get_cms_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_cms_enrollment.md),
  [`mysterycall_get_hrsa_ahrf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_hrsa_ahrf.md),
  and
  [`mysterycall_track_clinician_churn()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_track_clinician_churn.md).

### Source-audit bug fixes (wave 4)

- `city_state_to_lat_long` dataset now matches its documented schema:
  columns `city`, `state` (two-letter USPS abbreviation incl. DC/PR),
  `lat`, `long`. It previously shipped `state` full names plus
  `latitude`/`longitude`, so `$lat` / `$long` returned `NULL` and any
  two-letter-`state` join matched zero rows. The `data-raw/` build
  script now performs the rename + abbreviation.
- [`mysterycall_acceptance_waffle()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_waffle.md)
  default `bcbs_label` corrected to the package-canonical
  `"Blue Cross/Blue Shield"` (no spaces); the old spaced default
  [`stop()`](https://rdrr.io/r/base/stop.html)ed with “No rows found” on
  canonical data.
- Removed a contradictory (always-FALSE) dead predicate in
  `data-raw/benchmark_name_parser.R`.

### Source-audit bug fixes (waves 1-3)

A full read of `R/` surfaced correctness bugs that fed wrong numbers
into data, models, and manuscript text. Fixed in this version (BUGS.md
[\#5](https://github.com/mufflyt/mysterycall/issues/5)-#20,
[\#22](https://github.com/mufflyt/mysterycall/issues/22)-#47):

- **Data integrity / joins:** missing NPIs no longer stringify to `"NA"`
  in the shared reader (`utils-io.R`) or
  [`clean_phase_1_results()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md),
  which had collapsed every missing-NPI row to a colliding `doctor_id`;
  `flag_repeat_physicians()` /
  [`save_quality_check_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall-deprecated.md)
  now key duplicate detection on id only (not id + name);
  [`prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/prepare_calls.md)
  no longer injects phantom all-NA rows in the `na_exclusions = "drop"`
  branch; `exclusion_summary()` reports an explicit `n_unrecognized`
  bucket instead of silently counting unknown reasons as included.

- **Statistics / models:** `nb_power()` and
  `sensitivity_both_insurance()` now treat the paired (within-physician)
  design as paired; `power_analysis()` no longer double-counts calls in
  the unpaired branch;
  [`model_mae_rmse()`](https://mufflyt.github.io/mysterycall/reference/model_mae_rmse.md)
  uses [`expm1()`](https://rdrr.io/r/base/Log.html) (not
  [`exp()`](https://rdrr.io/r/base/Log.html)) to invert `log1p`;
  `univariate_lmm_screen()` returns an additive `Estimate` (renamed from
  the meaningless exponentiated “IRR”); `interaction_screen()` bases
  significance on interaction terms only (not `min(p)` over main
  effects) and uses `<= alpha`; `lmm.R` builds Wald CIs with a t
  quantile matching the Satterthwaite p-value.

- **Reporting / plots:** `wait_time_sentence()` prints `< 0.001` instead
  of `0`; `write_results_paragraph()` only claims significance when a
  level clears alpha; `wait_time_crossover()` reports the correct group
  beyond the crossover; `irr_plot()` no longer permutes significance
  colors; `icc` prints the confidence level (not `n_boot`) in its CI
  label; `plot_emmeans_interaction()` handles Poisson
  (`type = "response"`);
  [`plot_effects()`](https://mufflyt.github.io/mysterycall/reference/plot_effects.md)
  respects `type`; `plot_disparities()` uses a proper
  difference-of-proportions CI; density/scatter plots keep same-day
  (0-day) appointments under `transform = "none"`.

- **Classifiers / parsers / data:** anchored country/brand substrings in
  `classify_medical_school()` and `classify_practice_setting()`
  (Indiana/New Mexico/Nova/Penn no longer misclassified);
  `parse_physician_name()` handles the documented “Last, First” format;
  NANP table adds PR 787 / GU 671 / VI 340; the `fips` dataset docs now
  match the shipped state table; hardcoded “including the District of
  Columbia” clauses are gated on DC actually being present.

  Note: BUGS.md [\#21](https://github.com/mufflyt/mysterycall/issues/21)
  (non-duplicate-mode insurance assignment) was left as-is; the proposed
  change conflicts with the package’s intended and tested
  insurance-assignment behavior and warrants a product decision.

### Bug fixes

- [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md):
  the narrative sentences no longer take
  [`abs()`](https://rdrr.io/r/base/MathFun.html) of the day-scale
  confidence-interval bounds. Signs are preserved, so a zero-crossing
  (non-significant) CI such as `[-6.5, +11.4]` is printed with its
  negative lower bound instead of being flipped to a spurious positive
  interval; interval-crossing estimates are now flagged “(difference not
  statistically significant)”.
- [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md)
  and
  [`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md):
  report wording is parameterized via new `subject` (default
  `"callers"`) and, for
  [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
  `exposure_descriptor` (default `"insured"`) arguments. Set
  `exposure_descriptor = NULL` for non-insurance exposures so sentences
  read “Laryngology callers” rather than “Laryngology-insured callers”.
  Defaults preserve existing insurance-study output.
- [`mysterycall_overdispersion_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_test.md):
  documented (new “Mixed-effects caveat” section) that
  [`df.residual()`](https://rdrr.io/r/stats/df.residual.html) counts
  only fixed-effect parameters for GLMMs, so phi is an approximation
  there;
  [`DHARMa::testDispersion()`](https://rdrr.io/pkg/DHARMa/man/testDispersion.html)
  is recommended for a formal GLMM dispersion check. The NB/GLMM-aware
  interpretation branch (low residual phi is expected, not overfitting)
  is now shipped in the built package.

### New functions

#### Environment / market covariates

- mysterycall_get_payer_mix(): county payer mix from ACS S2701 +
  coverage-type tables (B27002/B27003/C27006/C27007/B27001) — Private /
  Public / Medicaid / Medicare / Uninsured shares with propagated 90%
  MOEs
- mysterycall_get_county_provider_counts(): distinct providers per
  county FIPS, with optional per-100k density and specialty breakdown
- mysterycall_summarize_county_enrollment(): aggregate county
  Medicare/Medicaid enrollment (e.g. from
  mysterycall_get_cms_enrollment()) into a Medicaid-to- Medicare ratio
  and DOJ/FTC-style access category
- mysterycall_add_medicaid_expansion(): join ACA Medicaid-expansion
  status by state, with an as-of-call-date flag that correctly
  classifies NC (2023-12-01) and SD (2023-07-01) calls made before those
  states expanded
- mysterycall_read_kff_hhi() / mysterycall_add_hhi(): KFF per-MSA
  market- concentration HHI as a covariate (hhi, hhi_k = hhi/1000,
  DOJ/FTC hhi_cat)

#### Covariate lookups (from consolidation / isochrones)

- mysterycall_medicaid_fee_index(): retrieve KFF state-level
  Medicaid-to-Medicare fee index ratios

- mysterycall_calculate_spatial_density(): compute local clinic
  concentration using vectorized Haversine distance

- mysterycall_model_zero_wait(): model same-day appointments (zero wait
  times) via binomial logistic regression

- mysterycall_compare_count_families(): compare Poisson, linear NB, and
  quadratic NB mixed models via AIC/BIC

- mysterycall_model_nonlinear(): fit natural cubic splines or polynomial
  terms for continuous predictors and plot curves

- mysterycall_calculate_hq_distance(): compute Haversine distance to
  private equity platform regional headquarters for instrumental
  variable analysis

- mysterycall_track_clinician_churn(): track longitudinal clinician
  staffing and annual churn rates at the practice level from NPPES
  history in DuckDB

- mysterycall_get_acs_female_insurance(): query Census API for female
  insurance enrollment percentages at the census tract level

- mysterycall_get_hrsa_ahrf(): retrieve county-level health resource and
  clinician metrics from HRSA AHRF

- mysterycall_get_cms_enrollment(): extract monthly Medicare/Medicaid
  enrollment from CMS reports

- mysterycall_run_analysis(): full 9-step pipeline orchestrator

- mysterycall_irr_table() / mysterycall_model_gt(): publication-ready gt
  tables

- mysterycall_dedup_by_insurance(): deduplicate by phone x insurance

- mysterycall_physicians_with_detail(): fetch full rows for flagged IDs

- mysterycall_descriptive_stats(): median / Q1 / Q3 with sentence

- mysterycall_distribution_summary(): modal category with sentence

- mysterycall_demographics_sentence(): prose from
  gender/specialty/credential distributions

- mysterycall_wait_time_by_group(): grouped median / IQR table

- mysterycall_wait_time_sentence(): Poisson p-values woven into prose

- mysterycall_insurance_wait_sentence(): Medicaid vs BCBS IRR paragraph

- mysterycall_scenario_summary(): call counts by scenario with sentence

- mysterycall_sensitivity_both_insurance(): paired-insurance sensitivity
  analysis

- mysterycall_univariate_lmm_screen(): LMM univariate predictor screen
  with IRR

- mysterycall_interaction_screen(): pairwise interaction LMM screen with
  AIC

- mysterycall_univariate_poisson_screen(): simple GLM Poisson predictor
  screen

- mysterycall_r2_sentence(): marginal / conditional R² prose

- mysterycall_random_effect_variance(): ICC + VarCorr table with
  interpretation

- mysterycall_overdispersion_sentence(): Pearson phi dispersion test
  with tiers

- mysterycall_clean_medicaid_col(): recode Medicaid acceptance to 0/1

- mysterycall_facet_histogram(): faceted histogram with stats annotation

- mysterycall_log_histogram(): log-scale faceted histogram

- mysterycall_simple_poisson(): simple Poisson GLM with IRR table and
  manuscript sentence

- mysterycall_flag_repeat_physicians(): QC flag for repeated physician
  entries

- mysterycall_flag_exclusion_discrepancy(): QC flag for excluded rows
  with wait times

- mysterycall_flag_excluded_with_appointments(): QC flag for excluded
  rows with days \> 0

- mysterycall_flag_included_na_appointments(): QC flag for included rows
  with NA days

- mysterycall_sample_demographics(): physician sample summary with
  sentence

- mysterycall_insurance_acceptance_rates(): Medicaid vs BCBS acceptance
  rate computation

### Improvements

- Lme4 singular-fit warnings suppressed in lmm/interaction/r2/randeff
  functions
- NA rows pre-filtered in histogram functions before ggplot construction
- p_adjust_method parameter added to univariate_lmm_screen,
  univariate_poisson_screen, interaction_screen
- Input validation standardised with checkmate across all new functions

### Vignettes

- “Mystery Caller Workflow” vignette added: end-to-end 12-section
  walkthrough

## mysterycall 1.6.0

Released 2026-06-25.

### ✨ New functions

- **[`mysterycall_predict_appointment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_predict_appointment.md)**
  — generates predicted appointment- acceptance probabilities (plus
  optional delta-method 95% CIs) for new patient or practice profiles
  from a fitted `mysterycall_logistic_model` object. Population-level
  predictions (`re.form = NA`) are the default, appropriate for new
  practices unseen during model training.

- **[`mysterycall_enrich_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_enrich_npi.md)**
  — end-to-end NPI enrichment pipeline: validates NPIs, looks up
  clinician data, genderizes first names, classifies practice setting,
  and assigns ACOG/census regions. Returns a deduplicated data frame.

- **[`mysterycall_parse_redcap_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_redcap_labels.md)**
  — parses REDCap data-dictionary choice labels into tidy `data.frame`s
  matching scenario × insurance × NPI patterns used in mystery-caller
  study designs.

- **[`mysterycall_calendar_sensitivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_calendar_sensitivity.md)**
  — side-by-side comparison of wait-time LMMs fit on calendar days
  vs. business days, reporting coefficient deltas and flagging results
  that differ meaningfully between the two timescales.

- **`medicaid_expansion`** data object — 51-row KFF-sourced dataset
  recording each state’s Medicaid expansion status (adopted / not
  adopted) for use in stratified analyses.

### ✨ Improvements

- **broom-compatible
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html) methods**
  added for `mysterycall_lmm`, `mysterycall_logistic_model`, and
  `mysterycall_poisson_model` result objects via the `generics` package
  (now in `Imports`).

- **[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md)**
  — auto log-transform now reports geometric-mean ratios (GMR) with
  confidence intervals alongside the standard coefficient table.

- **`assign_region()`** — factor inputs are now silently coerced to
  character rather than erroring; non-character, non-factor input gives
  a clear error.

- **[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md)**
  — duplicate columns are dropped before column-binding to prevent
  `cbind` errors when API responses overlap with base data frame
  columns.

- **`caller_reliability()`** — emits a
  [`warning()`](https://rdrr.io/r/base/warning.html) (not an error) when
  fewer than 30 complete pairs are found, noting that ICC and kappa
  estimates are unreliable at small *n*.

- **[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md)**
  — gains an
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) S3
  method so results can be piped directly into `flextable` or
  [`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html).

- **`bizdays` fallback** —
  [`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md)
  now falls back to calendar days with a
  [`message()`](https://rdrr.io/r/base/message.html) instead of
  [`stop()`](https://rdrr.io/r/base/stop.html)-ing when the `bizdays`
  package is not installed.

### 🐛 Bug fixes

- Fixed a namespace-locking bug in the test suite: 37 test files were
  calling
  [`library(mysterycall)`](https://mufflyt.github.io/mysterycall/)
  inside `devtools::test()`, which locked the package namespace and
  silently broke all subsequent `with_mocked_bindings()` calls. All such
  calls have been removed.

- Fixed 11-digit NPI generation in regression-match-rate mocks when *n*
  \> 10 (changed from `paste0("123456789", 0:(n-1))` to
  `sprintf("1%09d", seq_len(n))`).

- Corrected ACOG district for Texas: District XI (not VII).

------------------------------------------------------------------------

## mysterycall 1.5.0

Released 2026-06-15.

### ✨ New functions

- **[`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md)**
  — merges phase-1 provider list with REDCap wave schedule, assigns
  callers, and exports call sheets ready for upload.

- **[`mysterycall_strobe_flow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_flow.md)**
  — generates a STROBE-compliant participant flow diagram (DiagrammeR /
  Graphviz) from a named list of screening counts.

- **[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md)**
  — fits a mixed-effects logistic regression for binary outcomes (e.g.,
  appointment offered yes/no), returns odds ratios, CIs, and a
  publication-ready OR table.

- **[`mysterycall_forest_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_forest_plot.md)**
  — renders a forest plot from any
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html)- compatible
  model object, with optional reference-line and faceting by outcome
  variable.

- **[`mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_auto_model.md)**
  — selects the best GLMM family (Poisson, negative-binomial,
  zero-inflated) by AIC/BIC and overdispersion diagnostics, with an
  optional linear mixed-model evaluation step.

### ✨ Improvements

- [`mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_auto_model.md)
  gained an LMM evaluation step that fits a log-transformed LMM as an
  additional candidate and includes it in the AIC comparison table.

- Comprehensive adversarial + semantic test suite for
  `mysterycall_auto_model` (52 passing tests, 1 skip).

------------------------------------------------------------------------

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
  - Replaced
    [`ggforce::geom_circle`](https://ggforce.data-imaginist.com/reference/geom_circle.html)
    in
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
  `mysterycall_geocode()`,
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
  `mysterycall_clear_isochrone_cache()`. Call it after processing a
  large batch to reclaim memory.

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
  → use `mysterycall_isochrones_for_df()`
- `process_and_save_isochrones()` → use
  `mysterycall_isochrones_for_df()`

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
- Added `mysterycall_geocode()` to simplify geocoding lists of
  addresses.
- Added vignette skeleton on aggregating provider data.
