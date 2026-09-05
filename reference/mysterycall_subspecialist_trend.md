# Trend of OB-GYN subspecialist density per 100,000 women over time

Computes subspecialists per 100,000 women for each subspecialty and year
from **raw counts** (numerator) divided by the **total female
population** (denominator), then draws a multi-year line/point trend –
one line per subspecialty – with optional direct end-of-line labels. The
density is derived from the inputs (`count / population * per`), never
typed, so the figure cannot disagree with its own numbers.

## Usage

``` r
mysterycall_subspecialist_trend(
  counts,
  population,
  subspecialty_col = "subspecialty",
  year_col = "year",
  count_col = "count",
  pop_year_col = "year",
  pop_col = "population",
  per = 1e+05,
  title = "OB-GYN Subspecialists per 100,000 Women",
  show_year_range = TRUE,
  y_lab = "Subspecialists per 100,000 women",
  x_lab = NULL,
  palette = NULL,
  label_ends = TRUE,
  point_size = 1.9,
  line_width = 1,
  conf_level = NULL,
  trend_test = FALSE,
  numerator_source = NULL,
  denominator_source = paste0("U.S. Census Bureau, American Community Survey ",
    "1-year estimates, table B01001 (B01001_026E, ", "total female population)"),
  denominator_vintage = NULL,
  accessed = NULL,
  notes = NULL,
  caption = NULL,
  write_provenance = TRUE,
  output_path = NULL,
  width = 9,
  height = 5.5,
  dpi = 300
)
```

## Arguments

- counts:

  Subspecialist counts (numerator). One of:

  - a **long** data frame with the columns named by `subspecialty_col`,
    `year_col`, and `count_col`;

  - a **wide** data frame with a `subspecialty_col` column plus one
    numeric column per year (headers like `2013` or `X2013`);

  - a **matrix** with subspecialty row names and year column names.

- population:

  Total female population (denominator). One of: a year-named numeric
  vector (names are years, e.g. `setNames(pop, 2013:2023)`), an unnamed
  numeric vector ordered by year, or a data frame with the columns
  `pop_year_col` and `pop_col`. Must cover every year present in
  `counts`.

- subspecialty_col, year_col, count_col:

  Column names for the long/wide `counts` form. Defaults
  `"subspecialty"`, `"year"`, `"count"`.

- pop_year_col, pop_col:

  Column names when `population` is a data frame. Defaults `"year"`,
  `"population"`.

- per:

  Numeric denominator scale. Default `1e5` (per 100,000 women).

- title:

  Character. Plot title. The observed year range is appended when
  `show_year_range = TRUE`.

- show_year_range:

  Logical. Append `", <min>-<max>"` to `title`. Default `TRUE`.

- y_lab, x_lab:

  Axis labels. `x_lab` defaults to `NULL` (no label, since the axis
  shows years).

- palette:

  Optional character vector of colours, one per subspecialty (passed to
  [`ggplot2::scale_colour_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)).
  `NULL` uses the ggplot2 default.

- label_ends:

  Logical. Label each line at its final year and hide the legend
  (`TRUE`, default) instead of showing a legend.

- point_size, line_width:

  Numeric point size and line width.

- conf_level:

  Numeric in `(0, 1)` or `NULL`. When set (e.g. `0.95`), an exact
  Poisson confidence interval is computed for each rate and drawn as a
  shaded band per subspecialty; the limits are added to `$data` as
  `density_low` / `density_high`. `NULL` (default) draws no interval.
  Treats each count as Poisson given its year's population denominator.

- trend_test:

  `FALSE` (default), `TRUE`, `"poisson"`, or `"quasipoisson"`. When
  enabled, fits a per-subspecialty log-linear regression of count on
  year with an offset of `log(population)`, i.e. a model of the rate's
  annual change, and attaches the tidy result as `attr(p, "trend_test")`
  (annual rate ratio, CI, percent change per year and over the span, and
  the year-term p-value). `TRUE` uses Poisson (Wald); `"quasipoisson"`
  uses a t-test on the overdispersion-scaled SE. The CI uses
  `conf_level` when set, else 95%. When `label_ends` is on, each line's
  label also shows the rate ratio per year and a significance star.

- numerator_source:

  Character or `NULL`. Citation for the subspecialist counts (e.g.
  `"ABOG certified-diplomate counts, 2013-2023"`). Recorded in the
  provenance and, if set, shown in the figure caption.

- denominator_source:

  Character. Citation for the female-population denominator. Defaults to
  the U.S. Census ACS 1-year table B01001 (`B01001_026E`). Set to `NULL`
  to omit.

- denominator_vintage:

  Character or `NULL`. Extra denominator detail recorded in the
  provenance (e.g. `"ACS 1-year 2013-2023; 2020 from ACS 5-year"`).

- accessed:

  Date or character or `NULL`. When the source data were pulled
  (recorded in the provenance and caption).

- notes:

  Character or `NULL`. Free-text note recorded in the provenance.

- caption:

  Character, `NULL`, or `NA`. Figure caption. `NULL` (default)
  auto-builds a source line from the numerator/denominator provenance;
  `NA` (or `""`) draws no caption; a string is used verbatim.

- write_provenance:

  Logical. When `output_path` is set, also write provenance sidecars
  next to the image: a human-readable `<output>.provenance.txt` and,
  when jsonlite is installed, a machine-readable
  `<output>.provenance.json` (schema `mysterycall/provenance`) carrying
  the record and the per-point density table. Default `TRUE`.

- output_path:

  Character or `NULL`. File path to save via
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).
  `NULL` (default) writes nothing.

- width, height:

  Numeric. Saved size in inches. Defaults `9` x `5.5`.

- dpi:

  Integer. Resolution for raster output. Default `300`.

## Value

A ggplot2 object (invisibly). Its `$data` holds the computed density
table (`subspecialty`, `year`, `count`, `population`, `density`, plus
`density_low` / `density_high` when `conf_level` is set). When
`trend_test` is enabled, `attr(p, "trend_test")` holds the
per-subspecialty trend statistics (and they are folded into the JSON/txt
provenance sidecars). `attr(p, "provenance")` holds a
`mysterycall_provenance` record (metric, computation,
numerator/denominator sources, package version, access date, and
creation timestamp). When saved, `<output>.provenance.txt` and (if
jsonlite is installed) `<output>.provenance.json` sidecars are written
alongside the image (unless `write_provenance = FALSE`).

## Details

**You supply both the counts and the denominators.** No population
figures are bundled with the package (they go stale and would need to be
a cited vintage). To fetch the total-female-population denominators from
the U.S. Census ACS 1-year tables (variable `B01001_026E`,
"Estimate!!Total!!Female"), one call per year:


    # requires an internet connection and (optionally) a Census API key
    fem_pop <- vapply(2013:2023, function(y) {
      u <- sprintf(
        "https://api.census.gov/data/%d/acs/acs1?get=B01001_026E&for=us:1", y)
      as.numeric(jsonlite::fromJSON(u)[2, 1])
    }, numeric(1))
    names(fem_pop) <- 2013:2023
    # NB: the ACS 1-year 2020 table was not released; use the 5-year 2020
    #     table or a Population Estimates (PEP) value for that year.

## See also

[`mysterycall_subspecialist_infographic()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_infographic.md)
for the two-point (start -\> end) infographic version.

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
[`mysterycall_subspecialist_infographic()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_subspecialist_infographic.md),
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
# Long-format counts + a year-named female-population denominator.
counts <- data.frame(
  subspecialty = rep(c("Gynecologic Oncology", "Urogynecology"), each = 3),
  year         = rep(c(2013, 2018, 2023), times = 2),
  count        = c(1900, 2200, 2600, 900, 1400, 2100)
)
fem_pop <- c(`2013` = 160477237, `2018` = 165000000, `2023` = 168000000)
mysterycall_subspecialist_trend(counts, population = fem_pop)
```
