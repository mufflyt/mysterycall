# Generate a sample-size methods sentence

Calls
[`mysterycall_cochran_n()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cochran_n.md)
and returns a ready-to-paste sentence for the methods section of a
mystery-caller manuscript.

## Usage

``` r
mysterycall_sample_size_text(N, margin_of_error = 0.05)
```

## Arguments

- N:

  Integer. Total population size.

- margin_of_error:

  Numeric in `(0, 1)`. Desired margin of error. Default `0.05` (+/-5%).

## Value

A single character string ready to paste into a manuscript methods
section describing the required sample size.

## See also

[`mysterycall_cochran_n()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_cochran_n.md)
for the underlying sample-size formula;
[`mysterycall_methods_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_methods_paragraph.md)
to generate the full methods paragraph.

Other manuscript:
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
[`mysterycall_methods_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_methods_paragraph.md),
[`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md),
[`mysterycall_summarize_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_demographics.md)

## Examples

``` r
mysterycall_sample_size_text(369)
#> Error in mysterycall_sample_size_text(369): could not find function "mysterycall_sample_size_text"
```
