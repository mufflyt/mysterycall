# Render a fitted model as a LaTeX equation

Supplementary methods sections often print the statistical model as an
equation. This builds the LaTeX for a fitted generalized linear (mixed)
model – the link-transformed outcome as a linear predictor over the
fixed-effect terms, plus any random intercept – without the equatiomatic
dependency. It reads the family/link, the fixed-effect term labels, and
the random-effect grouping factor(s) straight off the fit.

## Usage

``` r
mysterycall_model_equation(
  model,
  coefficients = FALSE,
  digits = 3,
  wrap = TRUE
)
```

## Arguments

- model:

  A fitted model (`glm`,
  [`lme4::glmer`](https://rdrr.io/pkg/lme4/man/glmer.html)/`lmer`,
  `glmmTMB`) or a mysterycall model wrapper
  (`mysterycall_logistic_model`, `mysterycall_poisson_model`,
  `mysterycall_nb_model`, `mysterycall_lmm`); the underlying fit is
  extracted automatically.

- coefficients:

  If `TRUE`, substitute the fitted coefficient values for the symbolic
  \\\beta\\s (a fitted equation); if `FALSE` (default) keep the symbolic
  \\\beta_k\\ with a term legend.

- digits:

  Rounding for fitted coefficients when `coefficients = TRUE`. Default
  `3`.

- wrap:

  If `TRUE` (default) wrap the returned string in `$$ ... $$` display
  delimiters so it renders directly in R Markdown; if `FALSE` return the
  bare math.

## Value

A length-1 character string of LaTeX, with a `"legend"` attribute
mapping each \\\beta_k\\ to its term label (when
`coefficients = FALSE`). Printed via
[`cat()`](https://rdrr.io/r/base/cat.html) inside a `results='asis'`
chunk it renders as an equation.

## Examples

``` r
d <- data.frame(y = rbinom(100, 1, 0.5), x = rnorm(100),
                grp = factor(sample(letters[1:5], 100, TRUE)))
fit <- glm(y ~ x, family = binomial, data = d)
cat(mysterycall_model_equation(fit))
#> $$\operatorname{logit}\left(\Pr(\text{y}=1)\right) = \beta_0 + \beta_{1}\,\text{x}$$
```
