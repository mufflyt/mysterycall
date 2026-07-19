# Linear Mixed Models for Wait-Time Analysis

``` r
library(mysterycall)
library(lme4)        # required for model fitting
library(lmerTest)    # recommended — Satterthwaite p-values
library(generics)    # for tidy()
```

------------------------------------------------------------------------

## 1. When to use LMM vs. Poisson/NB GLMM

Mystery-caller studies collect wait times as counts of days from the
call date to the offered appointment date. Two model families cover most
scenarios:

| Situation | Recommended model |
|----|----|
| Wait days roughly symmetric, no strong floor at 0 | [`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md) |
| Outcome right-skewed (many short waits, long tail) | [`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md) with `auto_log = TRUE` (default) |
| Many zeroes or extreme right-skew | [`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md) or [`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md) |
| Binary outcome (accepted/not accepted) | [`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md) |

The function itself diagnoses the distribution automatically:

- **Skewness \> 1 and outcome ≥ 0**: `auto_log = TRUE` (default) applies
  `log1p(wait_days)` before fitting, and back-transforms results to
  *geometric mean ratios* (GMRs) for reporting.
- **Shapiro-Wilk p \< 0.05 on residuals**: a warning is issued and, when
  `sensitivity_poisson = "auto"` (default), a Poisson GLMM is run
  alongside the LMM as a robustness check.

------------------------------------------------------------------------

## 2. Simulated data

The examples below use a synthetic dataset resembling a two-wave
mystery-caller study comparing Medicaid and commercial insurance
patients across 20 physician practices.

``` r
set.seed(42)
n_physicians <- 20
n_calls      <- 4     # calls per physician (2 insurance types × 2 call dates)

sim_data <- data.frame(
  physician  = rep(paste0("Dr", sprintf("%02d", 1:n_physicians)), each = n_calls),
  insurance  = rep(c("Medicaid", "Medicaid", "BCBS", "BCBS"), n_physicians),
  wave       = rep(c("Wave1", "Wave2", "Wave1", "Wave2"), n_physicians),
  # Medicaid callers wait ~8 days longer on average
  wait_days  = round(pmax(0,
    rnorm(n_physicians * n_calls,
          mean = ifelse(rep(c(TRUE, TRUE, FALSE, FALSE), n_physicians), 29, 21),
          sd   = 10)
  )),
  stringsAsFactors = FALSE
)
# Add a business-days column (≈ 5/7 of calendar days)
sim_data$business_days <- round(sim_data$wait_days * 0.71)

head(sim_data)
```

------------------------------------------------------------------------

## 3. Fitting a basic LMM

``` r
fit <- mysterycall_lmm(
  data              = sim_data,
  outcome           = "wait_days",
  predictors        = c("insurance", "wave"),
  random_intercept  = "physician"
)
```

[`print()`](https://rdrr.io/r/base/print.html) produces a structured
report:

``` r
print(fit)
```

Key elements of the returned object:

``` r
# Fixed-effect table in days (or log-scale if auto_log triggered)
fit$coef_table

# Model fit: R-squared, ICC, sigma
list(
  marginal_R2   = fit$r_squared$marginal,
  conditional_R2 = fit$r_squared$conditional,
  sigma          = fit$sigma,
  n_obs          = fit$n,
  n_physicians   = fit$n_clusters
)

# Normality of residuals
fit$normality
```

------------------------------------------------------------------------

## 4. Auto-log transform and geometric mean ratios

When wait times are right-skewed, `auto_log = TRUE` (the default)
applies `log1p(wait_days)` before fitting. A message indicates whether
the transform was triggered. When it is, coefficients are on the log
scale and `fit$log_transformed` is `TRUE`.

``` r
fit$log_transformed
```

If `auto_log` did trigger, interpret results from `$gmr_table` rather
than `$coef_table`:

``` r
if (isTRUE(fit$log_transformed)) {
  fit$gmr_table
} else {
  message("auto_log did not trigger; use $coef_table directly.")
}
```

**How to report GMRs:** A GMR of 0.87 for `insuranceMedicaid` means
Medicaid callers wait, on average, 13% fewer days (× (days + 1)) than
the BCBS reference group (GMR = 0.87, 95% CI 0.75–1.01, p = 0.07).

When `auto_log` did *not* trigger, interpret `coef_table` directly in
days: “Medicaid callers waited 8.2 days longer than BCBS callers (β =
8.2, 95% CI 3.1–13.3, p = 0.002).”

------------------------------------------------------------------------

## 5. Poisson sensitivity analysis

By default (`sensitivity_poisson = "auto"`), a Poisson GLMM is run on
the **original untransformed** outcome whenever the Shapiro-Wilk test on
LMM residuals returns p \< 0.05.

``` r
# Force a sensitivity run regardless of normality
fit_sens <- mysterycall_lmm(
  data              = sim_data,
  outcome           = "wait_days",
  predictors        = c("insurance", "wave"),
  random_intercept  = "physician",
  sensitivity_poisson = TRUE
)

# Inspect the Poisson IRR table
if (!is.null(fit_sens$sensitivity)) {
  fit_sens$sensitivity$irr_table
}
```

Report the sensitivity Poisson model in a supplemental table alongside
the primary LMM. Consistent direction of effects (same sign across both
models) supports robustness of the conclusion.

------------------------------------------------------------------------

## 6. Broom-compatible `tidy()` method

The [`tidy()`](https://generics.r-lib.org/reference/tidy.html) generic
(from the `generics` package) returns a tidy tibble of fixed-effect
estimates, making it easy to pipe into `ggplot2` or `gt`:

``` r
tidy_result <- tidy(fit)
tidy_result
```

------------------------------------------------------------------------

## 7. Calendar vs. business-day sensitivity

To satisfy the M&M promise of a supplemental table comparing
calendar-day and business-day wait times, use
[`mysterycall_calendar_sensitivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_calendar_sensitivity.md):

``` r
sens <- mysterycall_calendar_sensitivity(
  data             = sim_data,
  calendar_col     = "wait_days",
  business_col     = "business_days",
  predictors       = c("insurance", "wave"),
  random_intercept = "physician",
  ref_label        = "BCBS (commercial)",
  supp_table_num   = "S2"
)
```

The comparison table:

``` r
sens$summary_table
```

Whether all term directions are consistent across both measurement
approaches:

``` r
sens$all_consistent
```

The ready-to-paste supplemental paragraph:

``` r
cat(sens$paragraph)
```

------------------------------------------------------------------------

## 8. Diagnostic plots

[`plot()`](https://rdrr.io/r/graphics/plot.default.html) dispatches on
the `mysterycall_lmm` class to produce Q-Q and residual-vs-fitted plots:

``` r
plot(fit)
```

A well-specified LMM shows:

- **Q-Q plot**: points close to the diagonal reference line.
- **Residuals vs. fitted**: no strong pattern; spread roughly constant.

If the Q-Q plot shows a pronounced right tail, the `auto_log` transform
or a Poisson/NB GLMM is warranted.

------------------------------------------------------------------------

## 9. Model comparison

Fit two models with `REML = FALSE` for valid AIC-based comparison:

``` r
fit_full    <- mysterycall_lmm(sim_data, "wait_days",
                                c("insurance", "wave"), "physician",
                                REML = FALSE)
fit_reduced <- mysterycall_lmm(sim_data, "wait_days",
                                "insurance", "physician",
                                REML = FALSE)

data.frame(
  model = c("Full (insurance + wave)", "Reduced (insurance only)"),
  AIC   = c(fit_full$aic,    fit_reduced$aic),
  BIC   = c(fit_full$bic,    fit_reduced$bic)
)
```

Lower AIC/BIC favours the more parsimonious model. Use
[`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md)
for a print-ready table.

------------------------------------------------------------------------

## 10. Reporting checklist

When writing up an LMM analysis from a mystery-caller study:

1.  **Sample**: report `fit$n` complete cases and `fit$n_clusters`
    physicians.
2.  **Model form**: “We fitted a linear mixed model with a random
    intercept for physician practice
    ([`lme4::lmer`](https://rdrr.io/pkg/lme4/man/lmer.html)).”
3.  **P-values**: “Denominator degrees of freedom were estimated using
    the Satterthwaite approximation (`lmerTest`).”
4.  **Transform**: if `fit$log_transformed`, report GMRs with 95% CI
    from `$gmr_table`. If not, report β (days) from `$coef_table`.
5.  **Normality**: report Shapiro-Wilk W and p from `fit$normality`.
6.  **R²**: report marginal and conditional R² (Nakagawa & Schielzeth
    2013).
7.  **Sensitivity**: if `sensitivity_poisson` ran, cite the Poisson IRR
    table in a supplemental section (use
    [`mysterycall_calendar_sensitivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_calendar_sensitivity.md)
    to generate the paragraph automatically).

------------------------------------------------------------------------

## References

Nakagawa S, Schielzeth H (2013). A general and simple method for
obtaining R² from generalized linear mixed-effects models. *Methods in
Ecology and Evolution* 4(2):133–142.
<doi:10.1111/j.2041-210x.2012.00261.x>

Asplin BR, Rhodes KV, Levy H, et al. (2005). Insurance status and access
to urgent ambulatory care follow-up appointments. *JAMA*
294(10):1248–1254. <doi:10.1001/jama.294.10.1248>
