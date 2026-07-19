# Leave-one-group-out refit sensitivity

Refits a model repeatedly, each time dropping all rows belonging to one
level of a grouping variable (e.g. leave-one-caller-out,
leave-one-site-out), and tabulates how a target coefficient – and,
optionally, the joint significance of a factor – moves across refits. A
headline estimate that is stable when any single group is removed is
more credible than one that hinges on one caller or site.

## Usage

``` r
mysterycall_leave_one_out(
  model,
  data,
  group,
  term,
  joint_predictor = NULL,
  exponentiate = TRUE,
  min_rows = 10L
)
```

## Arguments

- model:

  A fitted model (`glm`, `glmer`, `glmmTMB`, ...) or a mysterycall model
  wrapper; the underlying fit is extracted automatically.

- data:

  The data frame the model was fit on (needed to subset and refit).

- group:

  Column in `data` whose levels are left out one at a time.

- term:

  Name of the coefficient to track across refits (e.g.
  `"ent_typePediatrics"`).

- joint_predictor:

  Optional predictor to also joint-test on each refit (via
  [`mysterycall_joint_test()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_joint_test.md)),
  adding a `joint_p` column.

- exponentiate:

  If `TRUE` (default) report `exp(estimate)` (odds/rate ratio) alongside
  the estimate.

- min_rows:

  Skip a leave-out fit if fewer than this many rows remain. Default
  `10`.

## Value

An object of class `"mysterycall_leave_one_out"`: a list with `table` (a
tibble: `group_excluded`, `n`, `estimate`, optional `ratio`,
`std_error`, `p_value`, optional `joint_p`, `converged`) and `full` (the
target estimate/ratio/p on the complete data).
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the table.

## Examples

``` r
set.seed(1)
d <- data.frame(
  y = rbinom(300, 1, 0.4),
  grp = factor(sample(c("a", "b", "c"), 300, TRUE)),
  caller = factor(sample(paste0("c", 1:5), 300, TRUE))
)
fit <- glm(y ~ grp, family = binomial, data = d)
mysterycall_leave_one_out(fit, d, group = "caller", term = "grpb",
                          joint_predictor = "grp")
#> <mysterycall leave-one-group-out: term 'grpb', 5 refits>
#>   full-data ratio: 0.92 (p = 0.786)
#> # A tibble: 5 × 8
#>   group_excluded     n estimate ratio std_error p_value joint_p converged
#>   <chr>          <int>    <dbl> <dbl>     <dbl>   <dbl>   <dbl> <lgl>    
#> 1 c1               241  -0.112  0.894     0.330   0.735   0.885 TRUE     
#> 2 c2               235   0.106  1.11      0.329   0.747   0.941 TRUE     
#> 3 c3               244   0.0193 1.02      0.324   0.952   0.789 TRUE     
#> 4 c4               242  -0.238  0.788     0.331   0.473   0.406 TRUE     
#> 5 c5               238  -0.215  0.806     0.346   0.534   0.281 TRUE     
```
