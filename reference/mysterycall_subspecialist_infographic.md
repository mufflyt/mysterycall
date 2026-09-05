# Workforce-density infographic for OB-GYN subspecialists

Reproduces the "clinicians per unit" infographic style (a titled header
bar over one accent-coloured panel per subspecialty) as a single ggplot2
object, repurposed to show **subspecialists per 100,000 women** at two
time points. Each panel shows the subspecialty, the percent change, and
the `year_start` -\> `year_end` values with a direction arrow. Percent
change is computed from the supplied values, never typed in, so the
figure cannot disagree with its own numbers.

## Usage

``` r
mysterycall_subspecialist_infographic(
  subspecialty = c("Gynecologic Oncology", "Maternal-Fetal Medicine",
    "Reproductive Endocrinology & Infertility", "Urogynecology"),
  start,
  end,
  abbrev = NULL,
  data = NULL,
  subspecialty_col = "subspecialty",
  start_col = "start",
  end_col = "end",
  abbrev_col = "abbrev",
  year_start = 2018L,
  year_end = 2023L,
  title = "OB-GYN Subspecialists per 100,000 Women",
  palette = c("#1F4E66", "#2F6F3E"),
  header_fill = "#2E6E8E",
  increase_color = "#2F6F3E",
  decrease_color = "#B22222",
  color_pct_by = c("direction", "panel"),
  digits = 2L,
  numerator_source = NULL,
  denominator_source = paste0("U.S. Census Bureau, American Community Survey ",
    "1-year estimates, table B01001 (B01001_026E, ", "total female population)"),
  denominator_vintage = NULL,
  accessed = NULL,
  notes = NULL,
  caption = NULL,
  write_provenance = TRUE,
  output_path = NULL,
  width = 10,
  height = 4.8,
  dpi = 300
)
```

## Arguments

- subspecialty:

  Character vector of panel labels. Defaults to the four ABOG OB-GYN
  subspecialties (Gynecologic Oncology, Maternal-Fetal Medicine,
  Reproductive Endocrinology & Infertility, Urogynecology).

- start, end:

  Numeric vectors of density values (subspecialists per 100,000 women)
  at `year_start` and `year_end`. Same length as `subspecialty`.
  Required unless supplied via `data`.

- abbrev:

  Character vector of short badge labels (one per panel). When `NULL`
  (default) a sensible abbreviation is derived from `subspecialty` (e.g.
  "MFM", "REI"); a newline in a badge splits it across two lines.

- data:

  Optional data frame carrying the values instead of the vectors.
  Columns are named by `subspecialty_col`, `start_col`, `end_col`, and
  optionally `abbrev_col`. When supplied it overrides the vector
  arguments.

- subspecialty_col, start_col, end_col, abbrev_col:

  Column names read from `data`. Defaults `"subspecialty"`, `"start"`,
  `"end"`, `"abbrev"`.

- year_start, year_end:

  Integer years shown under each value and appended to the header title.
  Defaults `2018` and `2023`.

- title:

  Character. Header title; the year range is appended automatically
  (e.g. `"...: 2018-2023"`).

- palette:

  Character vector of panel accent colours, recycled across panels
  (defaults alternate a blue and a green, matching the source figure).

- header_fill:

  Character. Fill colour of the header bar.

- increase_color, decrease_color:

  Character. Colours for a rising vs. falling density (used for the
  percent change when `color_pct_by = "direction"`, and always for the
  value arrow).

- color_pct_by:

  One of `"direction"` (default; green up / red down) or `"panel"`
  (colour the percent change with the panel accent, like the source
  figure).

- digits:

  Integer. Decimal places for the density values. Default `2`.

- numerator_source:

  Character or `NULL`. Citation for the subspecialist densities/counts.
  Recorded in the provenance and, if set, shown in the caption.

- denominator_source:

  Character. Citation for the female-population denominator. Defaults to
  the U.S. Census ACS 1-year table B01001 (`B01001_026E`). Set to `NULL`
  to omit.

- denominator_vintage:

  Character or `NULL`. Extra denominator detail recorded in the
  provenance.

- accessed:

  Date or character or `NULL`. When the source data were pulled
  (recorded in the provenance and caption).

- notes:

  Character or `NULL`. Free-text note recorded in the provenance.

- caption:

  Character, `NULL`, or `NA`. Bottom source caption. `NULL` (default)
  auto-builds a source line from provenance; `NA` (or `""`) draws none;
  a string is used verbatim.

- write_provenance:

  Logical. When `output_path` is set, also write provenance sidecars
  next to the image: a human-readable `<output>.provenance.txt` and,
  when jsonlite is installed, a machine-readable
  `<output>.provenance.json` (schema `mysterycall/provenance`) carrying
  the record and the per-panel values. Default `TRUE`.

- output_path:

  Character or `NULL`. File path to save via
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  (`.png`, `.pdf`, `.tiff`, `.svg`). `NULL` (default) writes nothing.

- width, height:

  Numeric. Saved size in inches. Defaults `10` x `4.8`.

- dpi:

  Integer. Resolution for raster output. Default `300`.

## Value

A ggplot2 object (invisibly); `attr(p, "provenance")` holds a
`mysterycall_provenance` record. When `output_path` is set the image is
written (plus `<output>.provenance.txt` and, if jsonlite is installed,
`<output>.provenance.json` sidecars unless `write_provenance = FALSE`)
and the path messaged.

## Details

You supply the density values; nothing is imputed. Provide them either
as the `start` / `end` vectors (paste-friendly) or through a `data`
frame.

## See also

[`mysterycall_flow_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_diagram.md),
[`mysterycall_strobe_flow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_flow.md)

Other manuscript:
[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md),
[`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md),
[`mysterycall_flow_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_diagram.md),
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
[`mysterycall_literature_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_literature_table.md),
[`mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_materials_methods.md),
[`mysterycall_methods_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_methods_paragraph.md),
[`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md),
[`mysterycall_multi_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_model_table.md),
[`mysterycall_results_report()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_report.md),
[`mysterycall_sampl_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sampl_checklist.md),
[`mysterycall_sample_size_text()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_size_text.md),
[`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md),
[`mysterycall_sensitivity_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_table.md),
[`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md),
[`mysterycall_strobe_flow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_flow.md),
[`mysterycall_subspecialist_trend()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_trend.md),
[`mysterycall_summarize_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_demographics.md),
[`mysterycall_table2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table2.md),
[`print.mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_materials_methods.md),
[`print.mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_comparison_table.md),
[`print.mysterycall_multi_model_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_multi_model_table.md),
[`print.mysterycall_results_report()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_results_report.md),
[`print.mysterycall_sampl_checklist()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_sampl_checklist.md),
[`print.mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_strobe_checklist.md),
[`print.mysterycall_table2()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table2.md)

## Examples

``` r
# Paste your own per-100,000-women densities for the four ABOG subspecialties:
mysterycall_subspecialist_infographic(
  start = c(1.20, 0.95, 0.80, 0.40),   # 2018
  end   = c(1.35, 1.02, 0.88, 0.61)    # 2023
)

# Or from a data frame, with custom panels and a saved file:
df <- data.frame(
  subspecialty = c("Gynecologic Oncology", "Maternal-Fetal Medicine"),
  start        = c(1.20, 0.95),
  end          = c(1.35, 1.02)
)
if (FALSE) { # \dontrun{
mysterycall_subspecialist_infographic(data = df,
                                      output_path = "subspecialists_per_100k.png")
} # }
```
