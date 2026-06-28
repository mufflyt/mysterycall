# Predict appointment probability for new patient profiles

Generates predicted probabilities of appointment acceptance (and
optional confidence intervals) from a fitted
[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md)
object. Predictions are **population-level** by default
(`re.form = NA`), which is appropriate for new practices not seen during
model training.

## Usage

``` r
mysterycall_predict_appointment(
  fit,
  newdata,
  re.form = NA,
  conf_level = 0.95,
  allow_new_levels = TRUE,
  ci = TRUE
)
```

## Arguments

- fit:

  A `mysterycall_logistic_model` object returned by
  [`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md).

- newdata:

  A data frame of new patient/practice profiles to predict. Must contain
  all fixed-effect predictors used when fitting `fit`.

- re.form:

  Formula or `NA`. Passed to
  [`lme4::predict.merMod()`](https://rdrr.io/pkg/lme4/man/predict.merMod.html).
  `NA` (default) gives **population-level** predictions (ignores random
  effects – appropriate for new practices). `NULL` includes the
  estimated random effects for practices already in the training data.

- conf_level:

  Numeric in (0, 1). Confidence level for the intervals. Default `0.95`.

- allow_new_levels:

  Logical. Whether to allow new random-effect levels (new practice
  names) in `newdata`. Default `TRUE`.

- ci:

  Logical. Whether to compute confidence intervals via the delta method
  on the logit scale. Default `TRUE`. Set to `FALSE` for faster
  predictions when CIs are not needed.

## Value

The input `newdata` data frame with three columns appended:

- `prob`:

  Predicted probability of appointment acceptance (0-1).

- `ci_lower`:

  Lower confidence bound on the probability scale. `NA` when
  `ci = FALSE`.

- `ci_upper`:

  Upper confidence bound on the probability scale. `NA` when
  `ci = FALSE`.

## Details

**Delta method CIs:** Standard errors are computed by propagating the
fixed-effects variance-covariance matrix through the model matrix for
`newdata`, then transforming the Wald interval from the logit scale back
to the probability scale via
[`plogis()`](https://rdrr.io/r/stats/Logistic.html). This approach
ignores random-effect uncertainty and is therefore anti-conservative
when the number of clusters is small.

**Population-level vs. cluster-level:** With `re.form = NA` (default),
predictions represent the average practice. With `re.form = NULL`, the
function uses estimated random intercepts for practices seen during
training; new practice names require `allow_new_levels = TRUE` (which
sets the random intercept to zero, equivalent to an average practice).

## See also

[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
[`mysterycall_forest_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_forest_plot.md)

## Examples

``` r
# \donttest{
set.seed(1)
df <- data.frame(
  practice  = rep(paste0("P", 1:10), each = 6),
  insurance = rep(c("Medicaid", "BCBS"), 30),
  scenario  = rep(c("A", "B", "C"), 20),
  accepted  = rbinom(60, 1, prob = ifelse(
    rep(c("Medicaid", "BCBS"), 30) == "Medicaid", 0.35, 0.65
  ))
)
fit <- mysterycall_logistic_model(df, "accepted",
                                  c("insurance", "scenario"),
                                  "practice")
#> Warning: Low events-per-variable: 25 events / 4 parameters = 6.2. Convention recommends >= 10.
#> Fitting Logistic GLMER: accepted ~ insurance + scenario + (1 | practice)
#> Model fitted: n=60, physicians=10, AIC=86.5, events=35/60 (58.3%)
new_profiles <- data.frame(
  insurance = c("Medicaid", "BCBS", "Medicaid"),
  scenario  = c("A",        "A",    "B"),
  practice  = c("new1",     "new1", "new2")
)
mysterycall_predict_appointment(fit, new_profiles)
#>   insurance scenario practice   prob ci_lower ci_upper
#> 1  Medicaid        A     new1 0.4825   0.2350   0.7389
#> 2      BCBS        A     new1 0.7214   0.4472   0.8923
#> 3  Medicaid        B     new2 0.5402   0.2774   0.7824
# }
```
