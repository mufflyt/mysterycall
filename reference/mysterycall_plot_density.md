# Create a Density Plot for Mystery Caller Studies with Optional Transformations

This function generates a density plot designed for mystery caller
studies, allowing for the visualization of waiting times or similar
outcomes across different categories, such as insurance types. The
function supports transformations on the x-axis and custom labels.

## Usage

``` r
mysterycall_plot_density(
  data,
  x_var,
  fill_var,
  x_transform = "none",
  dpi = 600,
  output_dir = NULL,
  file_prefix = "density_plot",
  x_label = NULL,
  y_label = "Density",
  plot_title = NULL,
  verbose = TRUE
)
```

## Arguments

- data:

  A dataframe containing the data to be plotted. Must contain the
  variables specified in `x_var` and `fill_var`.

- x_var:

  A string representing the column name for the x-axis variable. This
  should be a numeric variable (e.g., waiting time in days).

- fill_var:

  A string representing the column name for the fill variable. This
  should be a categorical or factor variable (e.g., insurance type).

- x_transform:

  A string specifying the transformation for the x-axis: "log" for log
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
  is "density_plot".

- x_label:

  A string specifying the label for the x-axis. Default is `NULL` (uses
  x_var).

- y_label:

  A string specifying the label for the y-axis. Default is "Density".

- plot_title:

  A string specifying the title of the plot. Default is `NULL` (no
  title).

- verbose:

  A boolean indicating whether to print messages about the saved plot
  locations. Default is TRUE.

## Value

A ggplot2 object (`c("gg", "ggplot")`), returned invisibly. As a side
effect, writes a `.tiff` and a `.png` file to `output_dir` with
filenames of the form `<file_prefix>_<timestamp>.tiff/.png`.

## See also

[`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md)
for jittered point plots;
[`mysterycall_plot_line()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_line.md)
for median-trend line plots;
[`mysterycall_save_green_journal_figure()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_green_journal_figure.md)
to export at journal resolution.

Other visualization:
[`mysterycall_acceptance_waffle()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_waffle.md),
[`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md),
[`mysterycall_flowchart()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flowchart.md),
[`mysterycall_plot_line()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_line.md),
[`mysterycall_plot_paired_slope()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_paired_slope.md),
[`mysterycall_plot_raincloud()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_raincloud.md),
[`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md)

## Examples

``` r
if (FALSE) { # interactive()
example_data <- data.frame(
  insurance = rep(c("Medicaid", "Commercial"), each = 3),
  business_days_until_appointment = c(1.5, 2.2, 3.1, 1.8, 2.5, 2.9)
)
mysterycall_plot_density(
  data = example_data,
  x_var = "business_days_until_appointment",
  fill_var = "insurance",
  x_transform = "none",
  dpi = 50,
  output_dir = tempdir(),
  file_prefix = "demo_density",
  x_label = "Waiting Times in Days",
  y_label = "Density",
  plot_title = "Example Density Plot",
  verbose = FALSE
)
}
```
