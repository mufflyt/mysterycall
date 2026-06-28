# Draw a STROBE-compliant flow diagram for mystery-caller (secret-shopper) studies

Produces a publication-quality STROBE/CONSORT-style participant flow
diagram using ggplot2. The diagram shows the complete filtering
waterfall from the raw call log to the two downstream analysis
populations (logistic model and wait-time model), with a right-side
exclusion branch that lists each exclusion-code category and its count.

## Usage

``` r
mysterycall_strobe_flow(
  data = NULL,
  prepared = NULL,
  col_calldate = "calldate1",
  col_exclusions = "exclusions",
  col_appdate = "appdate",
  n_total = NULL,
  n_calldate = NULL,
  n_included = NULL,
  n_logistic = NULL,
  n_waittime = NULL,
  excl_no_calldate = NULL,
  excl_detail = NULL,
  label_total = "Call attempts logged",
  label_calldate = "Call date recorded\n(call was placed)",
  label_included = "Scheduling discussion possible\n(exclusion code = 0)",
  label_logistic = "Logistic analysis\nOutcome: appointment offered (yes/no)",
  label_waittime = "Wait-time analysis\nOutcome: days to appointment",
  title = "STROBE Flow Diagram - Mystery-Caller Study",
  output_path = NULL,
  width = 9,
  height = 11,
  dpi = 300
)
```

## Arguments

- data:

  A data frame (raw REDCap export) **or** a character string giving the
  path to a CSV file. When supplied,
  [`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md)
  is called internally using `col_calldate`, `col_exclusions`, and
  `col_appdate` to derive all N counts automatically. All `n_*`
  arguments and `excl_detail` are ignored when `data` is provided.

- prepared:

  A `mysterycall_prepared` object returned by
  [`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md).
  Counts are extracted automatically. Ignored when `data` is supplied.

- col_calldate:

  Character. Name of the call-date column in `data`. Default
  `"calldate1"`.

- col_exclusions:

  Character. Name of the exclusion-code column in `data`. Default
  `"exclusions"`.

- col_appdate:

  Character. Name of the appointment-date column in `data`. Default
  `"appdate"`.

- n_total:

  Integer. Total call records. Required when neither `data` nor
  `prepared` is supplied.

- n_calldate:

  Integer. Records with a call date present.

- n_included:

  Integer. Records with exclusion code 0 (scheduling discussion took
  place).

- n_logistic:

  Integer. Records entering the logistic model. Defaults to
  `n_included`.

- n_waittime:

  Integer. Records entering the wait-time model (appointment date
  present).

- excl_no_calldate:

  Integer. Records dropped for missing call date. Default:
  `n_total - n_calldate`.

- excl_detail:

  Named integer vector of per-code exclusion counts. Names are REDCap
  codes as characters (`"1"`, `"2"`, ..., `"NA"`). Derived automatically
  when `data` or `prepared` is supplied.

- label_total:

  Character. Box label for the initial count.

- label_calldate:

  Character. Box label for the call-date step.

- label_included:

  Character. Box label for the included set.

- label_logistic:

  Character. Box label for the logistic analysis.

- label_waittime:

  Character. Box label for the wait-time analysis.

- title:

  Character. Plot title.

- output_path:

  Character or `NULL`. File path to save the diagram (`.png`, `.tiff`,
  `.pdf`, `.svg`). When `NULL` (default), no file is written. Raster
  formats also save a paired copy in the other format.

- width:

  Numeric. Width in inches. Default `9`.

- height:

  Numeric. Height in inches. Default `11`.

- dpi:

  Integer. Resolution for raster formats. Default `300`.

## Value

A `ggplot2` object (invisibly).

## Details

**Three input modes - use whichever is most convenient:**

1.  **Raw data frame or CSV path** (`data`): all counts and exclusion
    details are computed automatically by calling
    [`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md)
    internally. This is the recommended path for most users.

2.  **`mysterycall_prepared` object** (`prepared`): pass the object
    returned by
    [`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md)
    directly. Useful when you have already run the preparation step.

3.  **Explicit counts** (`n_total`, `n_calldate`, ...): supply every N
    value by hand. Useful for manual overrides or non-REDCap data.

**REDCap exclusion-code labels:**

- Code 1 - Closed medical system (Kaiser / military)

- Code 2 - On hold \> 5 minutes

- Code 3 - Wrong number or wrong specialty

- Code 5 - Phone not answered / busy signal

- Code 6 - Physician's personal phone

- Code 7 - Referral required before scheduling

- Code 8 - Voicemail

- Code 9 - Not accepting new patients

- Code 10 - Must see midlevel provider first

- Code NA - Exclusion code pending review

## See also

[`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md),
[`mysterycall_flow_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_diagram.md),
[`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md)

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
[`mysterycall_sample_size_text()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_size_text.md),
[`mysterycall_save_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_plot.md),
[`mysterycall_sensitivity_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_table.md),
[`mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_checklist.md),
[`mysterycall_summarize_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_demographics.md),
[`mysterycall_table2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table2.md),
[`print.mysterycall_materials_methods()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_materials_methods.md),
[`print.mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_model_comparison_table.md),
[`print.mysterycall_multi_model_table()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_multi_model_table.md),
[`print.mysterycall_results_report()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_results_report.md),
[`print.mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_strobe_checklist.md),
[`print.mysterycall_table2()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table2.md)

## Examples

``` r
# Mode 1: from a data frame (simplest) — requires an existing CSV file.
if (FALSE) { # \dontrun{
raw <- read.csv("ICVsPOPVsSUI_DATA_2026-06-23_1225.csv",
                stringsAsFactors = FALSE)
mysterycall_strobe_flow(data = raw,
                        title = "STROBE Flow - ICVs vs POP vs SUI Study")
} # }

# Mode 2: from a mysterycall_prepared object — requires prepare_calls() first.
if (FALSE) { # \dontrun{
prepped <- mysterycall_prepare_calls(raw)
mysterycall_strobe_flow(prepared = prepped)
} # }

# Mode 3: explicit counts (for non-REDCap data or manual overrides)
mysterycall_strobe_flow(
  n_total    = 743,
  n_calldate = 737,
  n_included = 141,
  n_waittime = 100
)
```
