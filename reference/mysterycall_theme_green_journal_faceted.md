# Green Journal faceted map theme

Variant of
[`mysterycall_theme_green_journal_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_map.md)
for small-multiple map panels (e.g., maps by year or drive-time
threshold). Uses negative panel spacing to eliminate white gaps between
tightly tiled map panels.

## Usage

``` r
mysterycall_theme_green_journal_faceted(base_size = 9)

mysterycall_theme_publication_faceted(base_size = 9)
```

## Arguments

- base_size:

  Numeric. Base font size (default 9, smaller for panels).

## Value

A
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## See also

[`mysterycall_theme_green_journal_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_map.md)
for single-panel maps;
[`mysterycall_theme_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal.md)
for non-spatial plots.

Other green-journal-themes:
[`mysterycall_theme_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal.md),
[`mysterycall_theme_green_journal_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_theme_green_journal_map.md)

## Examples

``` r
if (FALSE) { # interactive()
library(ggplot2)
ggplot(tracts_sf) +
  geom_sf(aes(fill = rate)) +
  facet_wrap(~year) +
  mysterycall_theme_green_journal_faceted()
}
```
