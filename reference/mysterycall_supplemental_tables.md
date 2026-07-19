# Export a publication-ready supplemental Excel workbook

Collects results from
[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
and/or
[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md)
into a single, formatted Excel workbook ready for journal submission as
an online supplement.

## Usage

``` r
mysterycall_supplemental_tables(
  logistic_fit = NULL,
  poisson_fit = NULL,
  lmm_fit = NULL,
  extra_tables = list(),
  file = "supplemental_tables.xlsx",
  overwrite = FALSE,
  author = NULL
)
```

## Arguments

- logistic_fit:

  A `mysterycall_logistic_model` object returned by
  [`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
  or `NULL` (default). When non-`NULL`, the full odds-ratio table (all
  terms, including the intercept) is written to **Sheet 1 "OR Table"**.

- poisson_fit:

  A `mysterycall_poisson_model` or `mysterycall_nb_model` object, or
  `NULL` (default). When non-`NULL`, the full IRR table is written to
  **Sheet 2 "IRR Table"**.

- lmm_fit:

  A `mysterycall_lmm` object returned by
  [`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
  or `NULL` (default). When non-`NULL`, the coefficient table is written
  as an additional sheet ("LMM Coefs"); if a geometric-mean-ratio table
  is present it is appended as "LMM GMR".

- extra_tables:

  A named `list` of `data.frame`s to include as additional sheets. Each
  element name becomes the sheet name (truncated to 31 characters as
  required by Excel). Default
  [`list()`](https://rdrr.io/r/base/list.html).

- file:

  Character scalar. Output file path. The `.xlsx` extension is appended
  automatically when absent. Default `"supplemental_tables.xlsx"`.

- overwrite:

  Logical. When `FALSE` (default) the function stops if `file` already
  exists. Set `TRUE` to silently overwrite.

- author:

  Character scalar or `NULL`. Author name written to the workbook's
  Creator property. Default `NULL` (uses the current system user via
  [`Sys.info()`](https://rdrr.io/r/base/Sys.info.html)).

## Value

`invisible(file)` — the normalised absolute path to the written
workbook, so the path can be captured and passed to downstream
functions.

## Details

Each sheet receives zebra-stripe row shading, a bold dark-blue header
row, and auto-fitted column widths. The workbook metadata records the
author name (when supplied) and the creation date.

### Sheet contents

|  |  |
|----|----|
| Sheet | Populated when |
| **OR Table** | `logistic_fit` is non-`NULL` |
| **IRR Table** | `poisson_fit` is non-`NULL` |
| **Model Comparison** | at least two of the three model fits are non-`NULL` |
| **Complete Cases** | any model fit is non-`NULL` |
| **Session Info** | always |
| **LMM Coefs** | `lmm_fit` is non-`NULL` |
| **LMM GMR** | `lmm_fit` non-`NULL` and `lmm_fit$gmr_table` non-`NULL` |
| *(extra names)* | corresponding element of `extra_tables` |

### Requires

The `openxlsx` package must be installed (it is listed in `Suggests`).
Install with `install.packages("openxlsx")`.

## See also

[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md),
[`mysterycall_lmm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_lmm.md),
[`mysterycall_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_table.md)

Other reporting:
[`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md),
[`mysterycall_direction_words`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`print.mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_abstract_numbers.md),
[`print.mysterycall_irr_days()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md),
[`print.mysterycall_snapshot()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_snapshot.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Logistic + Poisson fits from a mystery-caller dataset
set.seed(42)
df <- data.frame(
  offered   = rbinom(80, 1L, 0.7),
  wait_days = rpois(80, lambda = 12),
  insurance = rep(c("Medicaid", "BCBS"), 40),
  physician = rep(paste0("Dr", 1:20), each = 4L),
  stringsAsFactors = FALSE
)

log_fit <- mysterycall_logistic_model(df, "offered",   "insurance", "physician")
poi_fit <- mysterycall_poisson_model(df, "wait_days",  "insurance", "physician")

out <- mysterycall_supplemental_tables(
  logistic_fit = log_fit,
  poisson_fit  = poi_fit,
  file         = "supplement.xlsx",
  overwrite    = TRUE,
  author       = "Tyler Muffly"
)
message("Workbook written to: ", out)
} # }
```
