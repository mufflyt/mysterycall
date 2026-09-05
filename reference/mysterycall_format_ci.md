# Format a confidence interval for reporting

Joins the endpoints of an interval into the string a manuscript prints.
SAMPL asks that the endpoints be separated with `"to"` rather than a
hyphen or a dash, so that a negative lower bound cannot be misread as a
minus sign: `-0.45--0.12` is ambiguous, `-0.45 to -0.12` is not.

## Usage

``` r
mysterycall_format_ci(
  lower,
  upper,
  digits = 2L,
  sep = getOption("mysterycall.ci_sep", " to ")
)
```

## Arguments

- lower, upper:

  Numeric vectors of interval endpoints, recycled against each other.
  `NA` in either endpoint yields `NA` for that element.

- digits:

  Integer. Decimal places for both endpoints. Default `2`.

- sep:

  Character scalar placed between the endpoints. Defaults to
  `getOption("mysterycall.ci_sep", " to ")`, so a whole document can be
  switched with one option.

## Value

A character vector the length of the recycled inputs.

## Details

The separator is an argument rather than a constant because house styles
differ. `gtsummary`'s JAMA and Lancet journal themes make the same
choice this default does, exposing it as a `ci.sep` theme setting; a
journal that insists on a dash can be served by passing `sep` or by
setting `options(mysterycall.ci_sep = )` once, rather than by editing
every formatter in the package.

## References

Lang TA, Altman DG. Basic statistical reporting for articles published
in biomedical journals: the "Statistical Analyses and Methods in the
Published Literature" or the SAMPL Guidelines. *International Journal of
Nursing Studies*. 2015;52(1):5-9.
[doi:10.1016/j.ijnurstu.2014.09.006](https://doi.org/10.1016/j.ijnurstu.2014.09.006)

The `sep` argument follows the pattern set by `gtsummary`'s journal
themes (`gtsummary::theme_gtsummary_journal("jama")`, MIT licensed),
which likewise separate interval endpoints with "to" and expose the
separator as a setting.

## See also

[`mysterycall_format_p()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_p.md)
for the matching p-value formatter, and
[`mysterycall_sampl_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sampl_checklist.md)
for the reporting items these serve.

Other table helpers:
[`mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_disparities_table.md),
[`mysterycall_format_p()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_p.md),
[`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md),
[`mysterycall_max_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_max_table.md),
[`mysterycall_min_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_min_table.md),
[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md),
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md),
[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md),
[`print.mysterycall_disparities_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_disparities_table.md)

## Examples

``` r
mysterycall_format_ci(1.05, 1.57)
#> [1] "1.05 to 1.57"
mysterycall_format_ci(-0.45, -0.12)
#> [1] "-0.45 to -0.12"
mysterycall_format_ci(c(1.05, NA), c(1.57, 2.0))
#> [1] "1.05 to 1.57" NA            
mysterycall_format_ci(0.4, 0.9, digits = 3, sep = " - ")
#> [1] "0.400 - 0.900"
```
