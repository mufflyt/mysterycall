# Print a mysterycall_disparities_table

Prints a formatted table of disparity metrics with group sizes,
acceptance rates, Wilson confidence intervals, absolute risk
differences, relative risks, and p-values versus the reference group.
Column headers are labelled using the `ci_method` and `alpha` attributes
stored on the object.

## Usage

``` r
# S3 method for class 'mysterycall_disparities_table'
print(x, ...)
```

## Arguments

- x:

  A `mysterycall_disparities_table` object returned by
  [`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md).

- ...:

  Ignored.

## Value

Invisibly returns `x`.

## See also

[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md)

Other table helpers:
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md),
[`mysterycall_format_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_ci.md),
[`mysterycall_format_p()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_p.md),
[`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md),
[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md),
[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md),
[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md),
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md),
[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md)

## Examples

``` r
set.seed(1)
df <- data.frame(
  insurance = sample(c("Medicaid", "Private", "Medicare"), 120, replace = TRUE),
  accepted  = rbinom(120, 1, 0.5)
)
disp_table <- mysterycall_disparities_table(df, "accepted", "insurance",
                                            ref_group = "Private")
print(disp_table)
#> Disparity table -- 3 groups | ref: 'Private' | wilson 95% CI
#> Group                       n  n_acc     Rate  95% CI            Abs.Diff  RR (95% CI)             p-value
#> ---------------------------------------------------------------------------------------------------- 
#> Private                    44     21    47.7%  33.8% to 62.1%       (ref)  1.00 (ref)              (ref)
#> Medicaid                   38     18    47.4%  32.5% to 62.7%     -0.4 pp  0.99 (0.63 to 1.57)     0.974
#> Medicare                   38     18    47.4%  32.5% to 62.7%     -0.4 pp  0.99 (0.63 to 1.57)     0.974
```
