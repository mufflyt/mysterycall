# Green Journal ggplot2 theme

Publication-quality theme conforming to *Obstetrics & Gynecology* (Green
Journal, Wolters Kluwer) 2024 author guidelines: white background,
Arial/sans font, black axes with tick marks, minimal gridlines, bottom
legend. Pair with
[`mysterycall_palette_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_palette_green_journal.md)
and
[`mysterycall_save_green_journal_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_green_journal_figure.md)
for a complete submission workflow.

## Usage

``` r
mysterycall_theme_green_journal(base_size = 10, base_family = "Arial")

mysterycall_theme_publication(base_size = 10, base_family = "Arial")
```

## Arguments

- base_size:

  Numeric. Base font size in points (default 10; Green Journal range
  8-12 pt, minimum 6 pt for labels).

- base_family:

  Character. Font family. Defaults to `"Arial"` with automatic fallback
  to `"sans"` when Arial is unavailable.

## Value

A
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## See also

[`mysterycall_theme_green_journal_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_map.md),
[`mysterycall_theme_green_journal_faceted()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_faceted.md),
[`mysterycall_save_green_journal_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_green_journal_figure.md)

Other green-journal-themes:
[`mysterycall_theme_green_journal_faceted()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_faceted.md),
[`mysterycall_theme_green_journal_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_map.md)

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  mysterycall:::mysterycall_theme_green_journal()
```
