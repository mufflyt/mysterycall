# Draw a validated STROBE participant-flow diagram

Renders a
[`mysterycall_flow_spec()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_spec.md)
as a STROBE/CONSORT participant-flow diagram: a main column of steps,
exclusion boxes teeing off to the right, and any splits drawn beneath
their parent.

## Usage

``` r
mysterycall_strobe_diagram(
  spec,
  title = NULL,
  output_path = NULL,
  width = 9,
  height = 7,
  dpi = 300,
  base_size = 10,
  background = "white"
)
```

## Arguments

- spec:

  A `mysterycall_flow_spec` from
  [`mysterycall_flow_spec()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_spec.md).

- title:

  Character or `NULL`. Plot title.

- output_path:

  Character or `NULL`. Where to save. Extension picks the device
  (`.png`, `.pdf`, `.svg`, ...). `NULL` returns the plot undrawn.

- width, height:

  Numeric. Inches. Defaults 9 and 7.

- dpi:

  Integer. Raster resolution. Default 300.

- base_size:

  Numeric. Base text size in points. Default 10.

- background:

  Colour for the plot background. Default `"white"`.
  [`ggplot2::theme_void()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
  leaves the background blank, which writes a TRANSPARENT PNG – fine on
  a white web page, unpredictable once the figure is placed in a Word
  manuscript or on a coloured slide, where whatever is behind it shows
  through the boxes. Pass `NA` for a transparent background
  deliberately.

## Value

Invisibly, the `ggplot` object.

## Details

Uses ggplot2 only. There is no Graphviz or htmlwidget path, and so no
headless browser is needed to write a PNG – the diagram renders in a
plain CI container, which is where a check of its numbers is worth
having.

## See also

[`mysterycall_flow_spec()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_spec.md)

## Examples

``` r
spec <- mysterycall_flow_spec(
  spine = c("Screened" = 100, "Enrolled" = 80),
  exclusions = list("Screened" = c("Ineligible" = 15, "Declined" = 5)),
  splits = list("Enrolled" = c("Completed" = 70, "Withdrew" = 10))
)
p <- mysterycall_strobe_diagram(spec, title = "Participant flow")
```
