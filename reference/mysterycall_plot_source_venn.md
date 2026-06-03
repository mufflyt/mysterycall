# Three-circle Venn diagram for data-source overlap

Visualizes how three data sources (A, B, C) cover a universe of
providers, labelling each region with its count and the center with the
three-way intersection count and percentage. The result is a
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object, optionally written to disk.

## Usage

``` r
mysterycall_plot_source_venn(
  data_or_path,
  A_col = "nppes",
  B_col = "pc",
  C_col = "dac",
  universe_col = "npis",
  source_short = c("NPPES", "PC", "DAC"),
  source_long = c("NPPES", "Physician Compare", "DAC"),
  fills = c("#2196F3", "#4CAF50", "#FF9800"),
  border_colors = c("#1565C0", "#2E7D32", "#E65100"),
  title = "Gender Data Availability Across Sources",
  subtitle = NULL,
  caption = NULL,
  output_path = NULL,
  width = 11,
  height = 9,
  dpi = 300L,
  bg = "white"
)
```

## Arguments

- data_or_path:

  A named list whose elements are character or numeric vectors of
  provider IDs, **or** a file path to an `.rds` file containing such a
  list.

- A_col, B_col, C_col:

  Character scalars naming the list elements that correspond to circles
  A, B, and C respectively. Defaults: `"nppes"`, `"pc"`, `"dac"`.

- universe_col:

  Character scalar naming the list element that contains the complete
  universe of provider IDs. When `NULL` the universe is taken as
  `union(A, union(B, C))`. Default `"npis"`.

- source_short:

  Character vector of length 3. Short labels used inside the
  intersection region annotations (e.g. `"NPPES + PC"`).

- source_long:

  Character vector of length 3. Full labels used in the bold header
  annotations above/below each circle.

- fills:

  Character vector of length 3. Fill colors for circles A, B, C (hex or
  R color names).

- border_colors:

  Character vector of length 3. Border and text colors matching each
  circle.

- title, subtitle, caption:

  Character scalars for plot text. When `subtitle` or `caption` is
  `NULL` a sensible default is auto-generated from the counts.

- output_path:

  Optional file path. When supplied the plot is saved with
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).
  The file format is inferred from the extension (`.png`, `.pdf`,
  `.svg`, etc.).

- width, height:

  Numeric. Plot dimensions in inches passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).
  Defaults `11` x `9`.

- dpi:

  Integer. Resolution for raster output. Default `300`.

- bg:

  Character scalar. Background color passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).
  Default `"white"`.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. Returned visibly when `output_path` is `NULL` so it prints to
the active graphics device. Returned
[`invisible()`](https://rdrr.io/r/base/invisible.html) when
`output_path` is supplied (the save is the intended side effect); assign
the return value to capture the object for further modification.

## Data format

The input list must have at minimum three named elements whose values
are vectors of provider identifiers (typically NPI strings). Example:

    d <- list(
      npis  = c("A","B","C","D","E"),   # universe
      nppes = c("A","B","C"),
      pc    = c("B","C","D"),
      dac   = c("C","D","E")
    )
    mysterycall_plot_source_venn(d)

## See also

Other plotting:
[`mysterycall_plot_disparities()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_disparities.md),
[`mysterycall_plot_emmeans()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans.md)

## Examples

``` r
if (FALSE) { # interactive()
d <- list(
  npis  = as.character(1:100),
  nppes = as.character(1:70),
  pc    = as.character(30:90),
  dac   = as.character(50:100)
)
p <- mysterycall_plot_source_venn(d, title = "Demo Venn Diagram")
print(p)
}
```
