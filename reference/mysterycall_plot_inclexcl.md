# CONSORT-style inclusion/exclusion flowchart for mystery-caller studies

Builds a DiagrammeR DOT diagram tailored to mystery-caller study
reporting. Unlike the generic
[`mysterycall_flowchart()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flowchart.md),
this function understands the standard mystery-caller study phases
(identification, screening, enrollment, analysis) and lays out exclusion
boxes on the right side with dashed arrows.

## Usage

``` r
mysterycall_plot_inclexcl(
  counts,
  exclusions = NULL,
  subspecialty_breakdown = NULL,
  title = NULL,
  node_width = 3.5,
  font_size = 10L
)
```

## Arguments

- counts:

  Named integer vector. Names are phase labels shown in the main boxes;
  values are physician counts at each phase. At least 2 phases are
  required.

- exclusions:

  Named list mapping a phase label (must be in `counts`) to a character
  string describing the exclusion reason and count (e.g.
  `list(Screening = "142 excluded: no phone number")`. Each entry
  produces a dashed side box to the right of the named phase.

- subspecialty_breakdown:

  Optional named integer vector. When supplied, the bottom box gains an
  extra line listing subspecialty counts (e.g.
  `c("General" = 120, "Neurotology" = 58, "Pediatric" = 44)`).

- title:

  Optional character scalar shown above the diagram.

- node_width:

  Numeric. Width of the main boxes in inches. Default `3.5`.

- font_size:

  Integer. Font size in points. Default `10L`.

## Value

A
[`DiagrammeR::grViz`](https://rich-iannone.github.io/DiagrammeR/reference/grViz.html)
object representing the CONSORT flow diagram. Renders automatically in
the RStudio Viewer and RMarkdown HTML output. To export to SVG or PDF:

    svg_text <- DiagrammeRsvg::export_svg(diagram)
    rsvg::rsvg_pdf(chartr("\n", "", svg_text), "consort.pdf")

## Details

Optionally appends a subspecialty distribution table in the final node.

## See also

[`mysterycall_flowchart()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flowchart.md)
for a generic multi-step flowchart;
[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md)
to compute the counts that feed this diagram.

Other outcomes:
[`.as_positive_logical()`](https://mufflyt.github.io/mysterycall/reference/dot-as_positive_logical.md),
[`.disp_rate_ci()`](https://mufflyt.github.io/mysterycall/reference/dot-disp_rate_ci.md),
[`.fmt_model_pval()`](https://mufflyt.github.io/mysterycall/reference/dot-fmt_model_pval.md),
[`.fmt_pvalue()`](https://mufflyt.github.io/mysterycall/reference/dot-fmt_pvalue.md),
[`.me_find_mf_col()`](https://mufflyt.github.io/mysterycall/reference/dot-me_find_mf_col.md),
[`.me_mf_to_orig()`](https://mufflyt.github.io/mysterycall/reference/dot-me_mf_to_orig.md),
[`.wait_stats()`](https://mufflyt.github.io/mysterycall/reference/dot-wait_stats.md),
[`.wilson_ci()`](https://mufflyt.github.io/mysterycall/reference/dot-wilson_ci.md),
[`mysterycall_acceptance_rate()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_acceptance_rate.md),
[`mysterycall_bootstrap_ci()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_bootstrap_ci.md),
[`mysterycall_irr_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_plot.md),
[`mysterycall_marginal_effects()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_marginal_effects.md),
[`mysterycall_model_metrics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_metrics.md),
[`mysterycall_plot_distribution()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_distribution.md),
[`mysterycall_plot_effect()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_effect.md),
[`mysterycall_plot_emmeans_full()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans_full.md),
[`mysterycall_plot_emmeans_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans_interaction.md),
[`mysterycall_plot_residuals()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_residuals.md),
[`mysterycall_plot_sjplot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_sjplot_interaction.md),
[`mysterycall_plot_stacked_bar()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_stacked_bar.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_screen_interactions()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_screen_interactions.md),
[`mysterycall_select_best_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_select_best_model.md),
[`mysterycall_wait_time_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_summary.md),
[`print.mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_poisson_model.md)

## Examples

``` r
if (FALSE) { # interactive()
mysterycall_plot_inclexcl(
  counts = c(
    Identified = 612,
    Screened   = 470,
    Enrolled   = 301,
    Analyzed   = 301
  ),
  exclusions = list(
    Identified = "142 excluded:\n  No phone number (n=87)\n  Duplicate NPI (n=55)",
    Screened   = paste0("169 excluded:\n",
      "  Not accepting new patients (n=112)\n",
      "  No appointment offered (n=57)")
  ),
  subspecialty_breakdown = c(General = 120, Neurotology = 58,
                              Pediatric = 44, Other = 79),
  title = "Mystery Caller Study -- ENT"
)
}
```
