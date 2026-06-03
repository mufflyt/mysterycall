# Save a ggplot2 figure with publication-quality defaults

A thin wrapper around
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
that:

- Defaults to 300 dpi, 8 x 6 inches, white background.

- Creates the output directory automatically if it does not exist.

- Returns the output path invisibly so calls can be piped.

## Usage

``` r
mysterycall_save_plot(
  plot,
  path,
  width = 8,
  height = 6,
  dpi = 300L,
  bg = "white",
  ...
)
```

## Arguments

- plot:

  A `ggplot` object.

- path:

  Character scalar. Full path (including filename and extension) where
  the plot should be saved. Common extensions: `.png`, `.pdf`, `.svg`,
  `.tiff`.

- width:

  Numeric. Width in inches. Default `8`.

- height:

  Numeric. Height in inches. Default `6`.

- dpi:

  Integer. Dots per inch. Default `300` (publication quality).

- bg:

  Character scalar. Background color. Default `"white"`.

- ...:

  Additional arguments forwarded to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

The output `path` (character scalar), invisibly. Assign the return value
to capture the path for downstream use; printing is suppressed.

## See also

[`mysterycall_plot_stacked_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_stacked_bar.md),
[`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md),
[`mysterycall_plot_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_density.md)
for functions that produce plots to pass here.

Other manuscript:
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
[`mysterycall_methods_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_methods_paragraph.md),
[`mysterycall_sample_size_text()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_size_text.md),
[`mysterycall_summarize_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_demographics.md)

## Examples

``` r
if (FALSE) { # interactive()
p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
mysterycall_save_plot(p, "figures/mpg_vs_weight.png")
}
```
