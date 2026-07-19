# CONSORT-style inclusion/exclusion flowchart

Produces a top-to-bottom DiagrammeR DOT flow diagram showing the
sequential inclusion and exclusion of providers from the analysis. Each
step is a labelled box with a count; optional exclusion side-boxes
branch off to the right. Requires the `DiagrammeR` package (listed in
Suggests).

## Usage

``` r
mysterycall_flowchart(
  steps,
  exclusions = NULL,
  title = NULL,
  node_width = 3.5,
  font_size = 10L
)
```

## Arguments

- steps:

  Named character vector (or named list coercible to character). Each
  name is a step label and each value is the formatted count to display.
  Steps are rendered top-to-bottom in the order supplied. Example:

      c(
        "Physicians in AAOS Directory" = "671",
        "Functioning Phone Number"     = "501",
        "Successfully Called"          = "432"
      )

- exclusions:

  Optional named character vector. Names must match names in `steps`
  (the step *after* which the exclusion occurred); values are the
  exclusion description displayed in a side box. Example:

      c("Functioning Phone Number" = "170 excluded: no functioning phone")

- title:

  Optional character scalar placed above the diagram. `NULL` (default)
  adds no title node.

- node_width:

  Numeric. Fixed width of each flow box in inches. Default `3.5`.

- font_size:

  Integer. Base font size for node labels. Default `10L`.

## Value

A `DiagrammeR` / `htmlwidget` object. Print it to view in the RStudio
Viewer or a browser; use
[`DiagrammeRsvg::export_svg()`](https://rdrr.io/pkg/DiagrammeRsvg/man/export_svg.html) +
[`rsvg::rsvg_pdf()`](https://docs.ropensci.org/rsvg/reference/rsvg.html)
to save to PDF.

## See also

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)

Other visualization:
[`mysterycall_acceptance_waffle()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_waffle.md),
[`mysterycall_bw_theme()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bw_theme.md),
[`mysterycall_plot_density()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_density.md),
[`mysterycall_plot_line()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_line.md),
[`mysterycall_plot_scatter()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_scatter.md)

## Examples

``` r
mysterycall_flowchart(
  steps = c(
    "Physicians in Directory" = "671",
    "Functioning Phone"       = "501",
    "Both Insurance Types"    = "432",
    "Final Analysis"          = "389"
  ),
  exclusions = c(
    "Functioning Phone"    = "170 excluded: no functioning phone",
    "Both Insurance Types" = "69 excluded: Medicaid not accepted",
    "Final Analysis"       = "43 excluded: incomplete call data"
  )
)

{"x":{"diagram":"digraph flowchart {\n  graph [layout=dot, rankdir=TB, overlap=false, fontsize=10]\n  node [fixedsize=false]\n\n  NPhysicians_in_Directory [label=\"Physicians in Directory\\nn = 671\", shape=box, width=3.5, fontsize=10]\n  NFunctioning_Phone [label=\"Functioning Phone\\nn = 501\", shape=box, width=3.5, fontsize=10]\n  NBoth_Insurance_Types [label=\"Both Insurance Types\\nn = 432\", shape=box, width=3.5, fontsize=10]\n  NFinal_Analysis [label=\"Final Analysis\\nn = 389\", shape=box, width=3.5, fontsize=10]\n  EFunctioning_Phone [label=\"170 excluded: no functioning phone\", shape=box, style=dashed, width=3.0, fontsize=10]\n  EBoth_Insurance_Types [label=\"69 excluded: Medicaid not accepted\", shape=box, style=dashed, width=3.0, fontsize=10]\n  EFinal_Analysis [label=\"43 excluded: incomplete call data\", shape=box, style=dashed, width=3.0, fontsize=10]\n\n  NPhysicians_in_Directory -> NFunctioning_Phone\n  NPhysicians_in_Directory -> EFunctioning_Phone [style=dashed, constraint=false]\n  NFunctioning_Phone -> NBoth_Insurance_Types\n  NFunctioning_Phone -> EBoth_Insurance_Types [style=dashed, constraint=false]\n  NBoth_Insurance_Types -> NFinal_Analysis\n  NBoth_Insurance_Types -> EFinal_Analysis [style=dashed, constraint=false]\n}\n","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}
```
