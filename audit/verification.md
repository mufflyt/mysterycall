# Verification evidence

Evidence for the statistical-integrity work on the
`srr-audit-and-coordinate-gate` branch. Every number here was produced by a
command recorded alongside it, so a maintainer can re-run any claim rather
than trusting this file.

## Baseline

Verified against the checkout before any change, because the assessment that
prompted the work quoted figures that had to be checked:

| Claim | Assessment said | Actual |
|---|---|---|
| Files in `R/` | 265 | 265 |
| Exports | 316 | 316 |
| S3 methods | 89 | 89 (now 122) |
| Test files | 484 | 483 (now 489) |
| Workflows / vignettes | 10 / 28 | 10 / 28 (now 29) |
| Version / commit | 1.6.3.9000 / `55bf9cc` | confirmed |

The assessment's own counts were therefore close but not exact, and its
verdicts measured *potential* compliance rather than implemented behaviour.
That distinction is why the work below started from reproducing defects
rather than from the assessment's conclusions.

## Defects, each reproduced before being changed

Reproduction was the gate: nothing was "fixed" on the strength of a report.

| # | Defect | Reproduction |
|---|---|---|
| 1 | Latitude 500 accepted, returns a plausible neighbour count | `mysterycall_calculate_spatial_density(c(500, 500.0001), c(-83, -83))` → `1 1` |
| 2 | Missing coordinate reported as density `0` | `(c(40, NA), c(-83, -83))` → `0 0`, indistinguishable from isolation |
| 3 | Reported cohort ≠ fitted cohort | 120 rows, 3 negative exposures → `nobs(model)` 117, object reported `n = 120`, `n_dropped = 0` |
| 4 | Zero / infinite exposure fails cryptically | `glmer() failed to fit: PIRLS loop resulted in NaN value` |
| 5 | Non-integer outcome misfiled as non-convergence | ~1,900 muffled warnings stored; `converged` set `FALSE` |
| 6 | `coef()` returns `NULL` silently | `coef(fit)` → `NULL`; same for `fitted()`, `residuals()` |
| 7 | `confint()` ignored the fitted `conf_level` | model fitted at 0.90 → `confint()` returned 0.95 bounds labelled "2.5 %" |
| 8 | `confint()` on an LMM used `z`, not Satterthwaite `t` | intervals up to 12% narrower than the fitter's own `coef_table` |
| 9 | Boundary-singular fit reported non-convergent | optimizer code `0`, `singular TRUE`, `converged FALSE` |
| 10 | `summary()` blank for LMM / logistic | `$coefficients` `NULL`; "Fit warnings: 0" fabricated |
| 11 | Convergence warning discardable by the cap | glmmTMB eigenvalue warning dropped past 10 distinct warnings |
| 12 | ZINB dispersion inflated | 2.492 reported vs 0.965 correct, on 29% structural zeros |
| 13 | `dispformula` dispersion reported as exactly `0` | `theta` `NA` → all residuals `NA` → `sum(na.rm = TRUE)` = 0 |
| 14 | Package failed to load without `stats` attached | `object 'nobs' not found whilst loading namespace` |

Numbers 7–11 were introduced by the fix for 1–6 and found by independent
review; 12–14 by a second review round. 14 was found by R CMD check after an
earlier installed-package check had passed **for the wrong reason** — it ran
in a session where `stats` was already attached.

## Fault injection

Passing tests do not show that tests can detect anything. Fourteen defects
were injected one at a time into a disposable `git worktree`, each reverted
before the next so mutations never compose, and the main working tree never
mutated.

```sh
python3 audit/fault-injection.py /path/to/disposable/worktree
```

| Mutation | Guard it removes |
|---|---|
| M1, M2 | Offset positivity validation (Poisson, NB) |
| M3 | Outcome finiteness check |
| M4 | `strict_counts` passthrough |
| M5 | Convergence/warning separation |
| M6 | `dispersion_details` on the returned object |
| M7 | `coef()` delegating to the engine |
| M8 | Analytic-cohort assertion |
| M9 | An S3 registration in `NAMESPACE` |
| M10 | `NaN` exposure rejection |
| M11 | `pmatch()` in the cohort-altering-argument guard |
| M12 | `confint()` honouring the fitted `conf_level` |
| M13 | Satterthwaite `t` for the LMM |
| M14 | Dispersion NA guard |

Every mutation must fail **the test written for it**, not merely something.
`audit/fault-injection-results.json` records the run.

M14 is worth recording because the first run missed it. The guard was inline
in both fitters, no public input reached that branch, and deleting it broke
no test. An untestable guard is not a guard, so it was extracted to
`.mc_dispersion_ratio()` and asserted directly; re-injecting the same
mutation then failed the expected test.

## R CMD check

Run with `TESTTHAT_PARALLEL=FALSE`, matching `test-coverage.yaml`, because
this suite has a history of parallel workers dying into an opaque
`.Rout.fail`.

| Commit | ERROR | WARNING | NOTE | tests |
|---|---|---|---|---|
| `98c7e27`, parallel | 1 | 4 | 7 | ERROR |
| `98c7e27`, serial | 0 | 1 | 6 | OK |
| `adf034a` | 0 | 1 | 5 | OK |
| `b51cb81` | 0 | 1 | 5 | OK |

The ERROR was the missing `importFrom(stats, nobs)`; three of the four
WARNINGs had the same cause. The remaining NOTE drop was excluding `srr/`
from the tarball.

What remains, each attributed rather than assumed:

- **WARNING** — `'qpdf' is needed for checks on size reduction of PDFs`. A
  missing local tool, not a package property.
- **5 NOTEs**, all pre-existing. Verified by checking that every file they
  name is unchanged on this branch, and that the lost-braces line in
  `man/mysterycall_strobe_flow.Rd` is byte-identical on `main`: CRAN "new
  submission" plus a 404 at `acog.org`; undefined globals
  `tyler_read_table`/`tyler_write_table`; lost braces; `torPort` undocumented
  in usage; and two slow examples (`mysterycall_power_curve` 196s,
  `mysterycall_nb_power` 26s).

## Numerical equivalence

The point of the work was to stop wrong numbers, not to produce different
ones.

- Poisson fixed effects, standard errors and p-values are **bit-identical**
  to a direct `lme4::glmer(..., nAGQ = 0L)` fit; the NB path to a direct
  `glmmTMB` fit, including `theta` against `sigma()`.
- `irr == exp(estimate)` and `ci == exp(estimate ± z·se)` hold exactly, and
  `confint()` now agrees with `irr_table` at every level tested (0.80, 0.90,
  0.95, 0.99).
- Independent review confirmed `main` and HEAD agree exactly on the full
  `irr_table`, `n`, dispersion, `theta`, AIC, BIC and `converged` for a
  fixed synthetic dataset.
- The NB dispersion change is numerically inert for a model without
  zero-inflation: the engine residuals and the superseded hand-rolled formula
  agree to machine precision (`0.998641386325` both ways, plain and with an
  offset). A test recomputes the superseded formula inline so a future change
  that *does* move a valid number fails.

Three values change, each previously wrong: ZINB dispersion (2.49 → 0.965),
`dispformula` dispersion (0 → 0.993), and `confint()` at a non-0.95 fitted
level.

## Installed-package checks

Because `S3method(nobs, ...)` needs its generic at load time, registration
was verified in a genuinely installed package in a bare session:

```sh
R CMD INSTALL --library=/tmp/lib --no-docs .
R_DEFAULT_PACKAGES=NULL Rscript -e 'loadNamespace("mysterycall", lib.loc="/tmp/lib")'
```

All 32 accessor registrations present (8 generics × 4 classes); namespace
loads with no default packages attached.

## Independent review

Two read-only review passes, each given the code and the questions but not
the implementing engineer's conclusions. The first found 8 defects, 4 of them
introduced by the work it was reviewing. The second found 7, including one in
the first round's own fix: the overflow sentinel emitted by
`summarise_fit_warnings()` contained the word "convergence", so the pattern
that classifies warnings matched the sentinel itself and a clean fit with 11
or more distinct unrelated warnings reported `converged = FALSE`.

Both rounds ran in-session rather than from a separate terminal. That is a
real limitation: the second round's findings have not themselves been
independently reviewed.

## Known limitations

- `DESCRIPTION` pins `Config/roxygen2/version: 8.0.0` while a newer roxygen
  may be installed locally, in which case `devtools::document()` reflows
  `NAMESPACE` and several `.Rd` files. Until the pin is resolved, `NAMESPACE`
  is not reproducible from the roxygen tags alone.
- The dispersion denominator debits fixed-effect parameters only. For a
  zero-inflation or dispersion model it does not debit the extra parameters
  those estimate, so the statistic is mildly anticonservative there;
  `dispersion_details$df_engine` records the alternative convention.
- The Pearson dispersion statistic is approximate for a GLMM in any case: its
  reference chi-square distribution is asymptotic and does not hold exactly
  once random effects are estimated.
