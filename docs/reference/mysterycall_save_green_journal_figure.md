# Save a figure in Green Journal submission format

Exports a ggplot in all formats needed for journal submission:

- **TIFF** (300 DPI, LZW compression) – primary submission format

- **PDF** (cairo, font-embedded) – vector companion for review

- **PNG** (300 DPI) – web / presentation companion

- **CSV** – underlying data for peer-review transparency

## Usage

``` r
mysterycall_save_green_journal_figure(
  plot,
  path_stem,
  layout = c("double_column", "single_column"),
  height = NULL,
  plot_data = NULL,
  csv = TRUE
)

mysterycall_save_publication_figure(
  plot,
  path_stem,
  layout = c("double_column", "single_column"),
  height = NULL,
  plot_data = NULL,
  csv = TRUE
)
```

## Arguments

- plot:

  A `ggplot` object.

- path_stem:

  Character. Path without extension (e.g., `"figures/figure1"`).
  Extensions are added automatically.

- layout:

  Character. `"single_column"` (3.5 in) or `"double_column"` (7.0 in).
  Controls width per Green Journal specs.

- height:

  Numeric. Height in inches. Default: `width * 0.7`, capped at 9.0 in
  (Green Journal maximum).

- plot_data:

  Optional data frame for CSV export. `NULL` extracts `plot$data`.

- csv:

  Logical. Export CSV (default `TRUE`).

## Value

Invisible character vector of file paths written (PNG, PDF, and/or CSV
depending on arguments).

## Details

Geometry columns (`sfc`) are automatically dropped from the CSV export.
Output directories are created recursively as needed.

## See also

[`mysterycall_theme_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal.md),
[`mysterycall_theme_green_journal_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_map.md)
for themes to apply before saving;
[`mysterycall_palette_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_palette_green_journal.md)
for the color palette.

## Examples

``` r
if (FALSE) { # interactive()
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + mysterycall_theme_green_journal()
mysterycall_save_green_journal_figure(p, "figures/fig1", layout = "double_column")
# Creates: figures/fig1.tiff  figures/fig1.pdf  figures/fig1.png
#          figures/fig1_data.csv
}
```
