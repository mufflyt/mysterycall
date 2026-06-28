# Waffle chart of insurance acceptance rates

Produces a side-by-side waffle chart comparing appointment acceptance
rates for two insurance groups (e.g. Medicaid vs. Blue Cross Blue
Shield). Each square represents one call; shading encodes Accepted vs.
Declined.

## Usage

``` r
mysterycall_acceptance_waffle(
  acceptance_result,
  medicaid_label = "Medicaid",
  bcbs_label = "Blue Cross / Blue Shield",
  colors = c(Accepted = "grey20", Declined = "grey85"),
  rows = 10L,
  title = NULL,
  flip = FALSE,
  monochrome = TRUE,
  dpi = 150L,
  output_dir = NULL,
  filename = "acceptance_waffle.png"
)
```

## Arguments

- acceptance_result:

  A data frame with at least columns `insurance_type`, `outcome` (values
  `"Accepted"` / `"Declined"`), and `n`. Typically the output of
  `table(df$insurance_type, df$outcome)` or a
  [`dplyr::count()`](https://dplyr.tidyverse.org/reference/count.html)
  summary.

- medicaid_label:

  Character scalar. Label for the Medicaid panel. Default `"Medicaid"`.

- bcbs_label:

  Character scalar. Label for the BCBS panel. Default
  `"Blue Cross / Blue Shield"`.

- colors:

  Named character vector. Colours for each outcome level. Default
  `c(Accepted = "grey20", Declined = "grey85")`.

- rows:

  Integer. Number of rows in each waffle grid. Default `10L`.

- title:

  Character or `NULL`. Main chart title added via patchwork. `NULL`
  produces no title.

- flip:

  Logical. If `TRUE`, flip the waffle orientation (columns become rows).
  Default `FALSE`.

- monochrome:

  Logical. If `TRUE` (default), apply
  [`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md)
  to each panel for Greene-journal compatibility.

- dpi:

  Integer. Resolution for the saved PNG. Default `150L`.

- output_dir:

  Character scalar or `NA`. Directory for PNG output. `NA` skips
  writing. Defaults to a session temp directory.

- filename:

  Character scalar. Output file name. Default `"acceptance_waffle.png"`.

## Value

A `patchwork` / `ggplot` object, returned invisibly.

## Details

Inspired by Nicola Rennie (2024), "Five Charts You Can Make with the
`waffle` Package", <https://nrennie.rbind.io/>.

## Note

Requires the waffle and patchwork packages (listed in `Suggests`).
Install with: `install.packages(c("waffle", "patchwork"))`.

## See also

Other visualization:
[`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md),
[`mysterycall_flowchart()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flowchart.md)

## Examples

``` r
if (FALSE) { # requireNamespace("waffle", quietly = TRUE) && requireNamespace("patchwork", quietly = TRUE)
acc <- data.frame(
  insurance_type = c("Medicaid", "Medicaid", "BCBS", "BCBS"),
  outcome        = c("Accepted", "Declined", "Accepted", "Declined"),
  n              = c(47L, 53L, 72L, 28L),
  stringsAsFactors = FALSE
)
mysterycall_acceptance_waffle(acc, output_dir = NA)
}
```
