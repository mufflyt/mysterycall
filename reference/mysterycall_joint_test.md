# Joint likelihood-ratio test for a multi-level predictor

Tests whether a categorical predictor matters *as a whole* – e.g. "does
subspecialty (7 levels) jointly predict access?" – by refitting the
model without every term that involves the predictor (its main effect
and any interaction) and comparing the two fits with a likelihood-ratio
test.

## Usage

``` r
mysterycall_joint_test(model, predictor)
```

## Arguments

- model:

  A fitted model (`glm`,
  [`lme4::glmer`](https://rdrr.io/pkg/lme4/man/glmer.html)/`lmer`,
  `glmmTMB`, ...) or a mysterycall model wrapper
  (`mysterycall_logistic_model`, `mysterycall_nb_model`,
  `mysterycall_lmm`, ...); the underlying fit is extracted
  automatically.

- predictor:

  Name of the predictor to test jointly. Must appear as a fixed-effect
  term in the model.

## Value

An object of class `"mysterycall_joint_test"`: a list with `predictor`,
`chisq`, `df`, `p_value`, `dropped_terms` (the terms removed),
`logLik_full`, `logLik_reduced`.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns a
one-row tibble.

## Details

The test statistic is computed directly from the log-likelihoods
(`chi^2 = 2(logLik_full - logLik_reduced)`, `df =` the difference in the
number of estimated parameters). This deliberately avoids reading the
degrees of freedom off an
[`anova()`](https://rdrr.io/r/stats/anova.html) table, which is a known
footgun: [`lme4::glmer`](https://rdrr.io/pkg/lme4/man/glmer.html) labels
that column `"Df"` (already the difference) while `glmmTMB` labels it
`"Chi Df"`, and grabbing the wrong one yields the total parameter count
instead of the factor's df and a badly wrong p-value.

## Examples

``` r
d <- data.frame(
  y = rbinom(200, 1, 0.4),
  grp = factor(sample(letters[1:4], 200, TRUE)),
  x = rnorm(200)
)
fit <- glm(y ~ grp + x, family = binomial, data = d)
mysterycall_joint_test(fit, "grp")
#> <mysterycall joint LRT: grp>
#>   chi-square(3) = 7.15, p = 0.0673
#>   dropped: grp
```
