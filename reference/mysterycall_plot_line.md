# Create a Line Plot with Optional Transformations and Grouping

This function creates a line plot using ggplot2 with options for
transforming the y-axis, grouping lines, and saving the plot with a
specified resolution. The plot can be saved in both TIFF and PNG formats
with automatic filename generation.

## Usage

``` r
mysterycall_plot_line(
  plot_data,
  x_var,
  y_var,
  y_transform = "none",
  dpi = 600,
  output_dir = NULL,
  file_prefix = "line_plot",
  use_geom_line = FALSE,
  geom_line_group = NULL,
  point_color = "viridis",
  line_color = "viridis",
  verbose = TRUE
)
```

## Arguments

- plot_data:

  A dataframe containing the data to be plotted. Must contain the
  variables specified in `x_var` and `y_var`.

- x_var:

  A string representing the column name for the x-axis variable. This
  should be a categorical or factor variable.

- y_var:

  A string representing the column name for the y-axis variable. This
  should be a numeric variable.

- y_transform:

  A string specifying the transformation for the y-axis: "log" for log
  transformation (log1p), "sqrt" for square root transformation, or
  "none" for no transformation. Default is "none".

- dpi:

  An integer specifying the resolution of the saved plot in dots per
  inch (DPI). Default is 600 for print-ready outputs.

- output_dir:

  A string representing the directory where the plot files will be
  saved. Defaults to a session-specific folder inside
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

- file_prefix:

  A string used as the prefix for the generated plot filenames. The
  filenames will have a timestamp appended to ensure uniqueness. Default
  is "line_plot".

- use_geom_line:

  A boolean indicating whether to include lines connecting points for
  grouped data. Default is FALSE.

- geom_line_group:

  A string representing the column name to group the lines by when
  `use_geom_line` is TRUE. This should be a categorical or factor
  variable.

- point_color:

  A string specifying the color of the points. Default is "viridis",
  which uses the viridis color palette.

- line_color:

  A string specifying the color of the summary line (median). Default is
  "viridis" to match the accessible palette.

- verbose:

  A boolean indicating whether to print messages about the saved plot
  locations. Default is TRUE.

## Value

A ggplot2 object (`c("gg", "ggplot")`), returned invisibly. As a side
effect, writes a `.tiff` and a `.png` file to `output_dir` with
filenames of the form `<file_prefix>_<timestamp>.tiff/.png`. A
`stat_summary` median line is always overlaid; individual points are
shown via `geom_point`.

## See also

[`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md)
for jittered point plots;
[`mysterycall_plot_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_density.md)
for density distribution plots.

Other visualization:
[`mysterycall_acceptance_waffle()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_waffle.md),
[`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md),
[`mysterycall_flowchart()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flowchart.md),
[`mysterycall_plot_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_density.md),
[`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md)

## Examples

``` r
if (FALSE) { # interactive()
example_data <- data.frame(
  insurance = rep(c("Medicaid", "Commercial", "Medicare"), each = 3),
  business_days_until_appointment = c(1.5, 2.1, 2.8, 1.7, 2.3, 2.5, 1.9, 2.6, 3.1)
)
mysterycall_plot_line(
  plot_data = example_data,
  x_var = "insurance",
  y_var = "business_days_until_appointment",
  y_transform = "none",
  dpi = 50,
  output_dir = tempdir(),
  file_prefix = "demo_line",
  verbose = FALSE
)
}
```
