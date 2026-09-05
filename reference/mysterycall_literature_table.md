# Build a literature comparison table of prior mystery-caller study ORs

Accepts a user-supplied data frame of published mystery-caller
audit-study odds ratios, optionally appends the current study's result,
applies consistent formatting, and returns a tidy comparison table ready
for the manuscript Discussion section. An optional forest plot and a
ready-to-paste Discussion sentence are also produced.

## Usage

``` r
mysterycall_literature_table(
  prior_studies,
  current_study = NULL,
  sort_by = c("year", "or", "author", "specialty"),
  digits = 2L,
  highlight_current = TRUE,
  include_forest = FALSE
)
```

## Arguments

- prior_studies:

  A data frame of published odds-ratio estimates with the following
  **required** columns:

  - `author`: Character. Citation label, e.g.
    `"Bisgaier & Rhodes 2011"`.

  - `year`: Integer. Publication year.

  - `specialty`: Character. Clinical specialty studied.

  - `insurance_comparison`: Character. Comparison label, e.g.
    `"Medicaid vs. Private"`.

  - `or`: Numeric. Odds ratio point estimate.

  - `ci_lower`: Numeric. Lower bound of the 95 % CI.

  - `ci_upper`: Numeric. Upper bound of the 95 % CI.

  - `n`: Integer. Total calls made in that study.

  Optional columns – included in the formatted table when present:
  `setting`, `outcome_label`, `notes`.

- current_study:

  A named list (or `NULL`). When non-`NULL`, a row labelled
  `"[Current study]"` is appended **after** the prior studies but
  **before** sorting. Required list elements mirror the required columns
  of `prior_studies`: `author`, `year`, `specialty`,
  `insurance_comparison`, `or`, `ci_lower`, `ci_upper`, `n`. Optional
  elements: `setting`, `outcome_label`, `notes`. The `author` element,
  if provided, is overwritten with `"[Current study]"`.

- sort_by:

  Character scalar controlling row order of the formatted table. One of
  `"year"` (default), `"or"`, `"author"`, or `"specialty"`.

- digits:

  Non-negative integer scalar. Decimal places for OR and CI values.
  Default `2L`.

- highlight_current:

  Logical. When `TRUE` (default) and `current_study` is non-`NULL`,
  `"***"` is appended to the Author cell of the current-study row in the
  formatted output.

- include_forest:

  Logical. Default `FALSE`. When `TRUE` **and** ggplot2 is installed, a
  simple forest plot is built and returned as `$forest_plot`. When
  ggplot2 is absent and `include_forest = TRUE`, a warning is issued and
  `$forest_plot` remains `NULL`.

## Value

A list of class `mysterycall_literature_table` containing:

- `table`:

  Data frame formatted for printing or export with columns `Author`,
  `Year`, `Specialty`, `Comparison`, `N`, `"OR (95% CI)"`, and
  `Direction`. Optional columns `Setting`, `Outcome`, `Notes` are
  included when the corresponding source columns are present. The
  `Direction` column takes one of three values: `"Disparity detected"`
  (95 % CI excludes 1), `"Favors equity"` (CI includes 1 and OR is
  within \[0.80, 1.25\]), or `"NS"` (CI includes 1 but OR is outside
  that range).

- `forest_plot`:

  A ggplot2 object, or `NULL` when `include_forest = FALSE` or ggplot2
  is unavailable.

- `n_studies`:

  Integer. Number of studies in the comparison table (including the
  current study, if supplied).

- `or_range`:

  Character. Human-readable OR range, e.g. `"0.31-0.87"`.

- `sentence`:

  Character. Ready-to-paste Discussion sentence summarising the
  literature context, e.g.
  `"Across 12 published mystery-caller studies, ORs for Medicaid vs. private insurance ranged from 0.31 to 0.87, consistent with our finding of OR = 0.62."`.
  When `current_study` is `NULL` the phrase
  `"consistent with our finding of OR = X.XX"` is omitted.

## Direction labels

The `Direction` column is derived purely from the 95 % CI provided in
`prior_studies` (and `current_study`). Studies with a CI that
**excludes** 1 are labelled `"Disparity detected"`. Among studies whose
CI includes 1, those with an OR in \[0.80, 1.25\] are labelled
`"Favors equity"`; the remainder are labelled `"NS"` (not significant
but OR suggests a meaningful gap).

## See also

[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_forest_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_forest_plot.md)

Other manuscript:
[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md),
[`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md),
[`mysterycall_flow_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_diagram.md),
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
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
prior <- data.frame(
  author               = c("Bisgaier & Rhodes 2011",
                            "Lowe et al. 2012",
                            "Kugelmass 2016",
                            "Saloner et al. 2015"),
  year                 = c(2011L, 2012L, 2016L, 2015L),
  specialty            = c("Pediatrics", "Orthopedics",
                            "Psychiatry", "Primary Care"),
  insurance_comparison = rep("Medicaid vs. Private", 4L),
  or                   = c(0.38, 0.61, 0.45, 0.87),
  ci_lower             = c(0.22, 0.44, 0.31, 0.72),
  ci_upper             = c(0.65, 0.85, 0.66, 1.05),
  n                    = c(1612L, 800L, 360L, 1560L),
  stringsAsFactors     = FALSE
)

current <- list(
  author               = "Acosta & Mufflyt",
  year                 = 2025L,
  specialty            = "Urogynecology",
  insurance_comparison = "Medicaid vs. Private",
  or                   = 0.62,
  ci_lower             = 0.41,
  ci_upper             = 0.94,
  n                    = 480L
)

result <- mysterycall_literature_table(
  prior_studies   = prior,
  current_study   = current,
  sort_by         = "year",
  digits          = 2L,
  include_forest  = FALSE
)

print(result)
#> 
#> -- Mystery-caller literature comparison (5 studies) --
#> 
#>                  Author Year     Specialty           Comparison    N
#>  Bisgaier & Rhodes 2011 2011    Pediatrics Medicaid vs. Private 1612
#>        Lowe et al. 2012 2012   Orthopedics Medicaid vs. Private  800
#>     Saloner et al. 2015 2015  Primary Care Medicaid vs. Private 1560
#>          Kugelmass 2016 2016    Psychiatry Medicaid vs. Private  360
#>      [Current study]*** 2025 Urogynecology Medicaid vs. Private  480
#>          OR (95% CI)          Direction
#>  0.38 (0.22 to 0.65) Disparity detected
#>  0.61 (0.44 to 0.85) Disparity detected
#>  0.87 (0.72 to 1.05)      Favors equity
#>  0.45 (0.31 to 0.66) Disparity detected
#>  0.62 (0.41 to 0.94) Disparity detected
#> 
#> OR range: 0.38 to 0.87
#> 
#> Discussion sentence:
#> Across 4 published mystery-caller studies, ORs for Medicaid vs. Private ranged from 0.38 to 0.87, consistent with our finding of OR = 0.62. 
result$sentence
#> [1] "Across 4 published mystery-caller studies, ORs for Medicaid vs. Private ranged from 0.38 to 0.87, consistent with our finding of OR = 0.62."
```
