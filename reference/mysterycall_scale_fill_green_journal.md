# Green Journal discrete fill scale

Convenience wrapper for
[`ggplot2::scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
using the Okabe-Ito palette from
[`mysterycall_palette_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_palette_green_journal.md).

## Usage

``` r
mysterycall_scale_fill_green_journal(...)
```

## Arguments

- ...:

  Arguments passed to
  [`ggplot2::scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

## Value

A ggplot2
[ggplot2::Scale](https://ggplot2.tidyverse.org/reference/Scale.html)
object.

## See also

[`mysterycall_scale_color_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scale_color_green_journal.md)
for color aesthetics;
[`mysterycall_palette_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_palette_green_journal.md)
for the underlying color values.

Other green-journal-colors:
[`mysterycall_palette_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_palette_green_journal.md),
[`mysterycall_scale_color_green_journal()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scale_color_green_journal.md)

## Examples

``` r
library(ggplot2)
ggplot(mpg, aes(class, fill = drv)) +
  geom_bar() +
  mysterycall:::mysterycall_scale_fill_green_journal()
```
