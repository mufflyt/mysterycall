# Generate a complete Materials & Methods section for a mystery-caller study

Produces reviewer-ready prose addressing seven standard reviewer
concerns for audit-by-secret-shopper designs: caller standardization,
call spacing, appointment definition, physician selection, missing data,
business vs. calendar days, and IRB ethics. Numbers are drawn directly
from `data` when supplied so the text stays current as data collection
continues.

## Usage

``` r
mysterycall_materials_methods(
  data = NULL,
  outcome_col = NULL,
  caller_col = NULL,
  group_col = NULL,
  physician_col = NULL,
  accepted_col = "contact_office",
  scenario_col = NULL,
  callers = NULL,
  specialty = "Female Pelvic Medicine and Reconstructive Surgery (FPMRS)",
  n_scenarios = 3L,
  scenario_names = c("pelvic organ prolapse", "stress urinary incontinence",
    "bladder pain/interstitial cystitis"),
  insurance_types = c("Blue Cross Blue Shield (BCBS)", "Medicaid"),
  ref_insurance = "BCBS",
  source_directory = "voicesforpfd.org",
  sampling_method = "random",
  irb_institution = "Colorado Multiple Institutional Review Board (COMIRB)",
  irb_number = "[COMIRB NUMBER REQUIRED]",
  call_hours = "Monday through Friday, 9:00 am - 4:00 pm local time",
  min_interval_hours = 24L,
  caller_assignment = "rotated systematically across physicians and conditions",
  appointment_definition = "first available appointment offered",
  appointments_accepted = FALSE,
  business_days_primary = FALSE,
  business_days_sensitivity = TRUE,
  data_platform = "REDCap",
  script_appendix = "Appendix A",
  r_version = NULL,
  ...
)
```

## Arguments

- data:

  Optional data frame. When supplied, study statistics (N calls, %
  complete, N physicians, caller names) are derived from the data.

- outcome_col:

  Character scalar or `NULL`. Column containing the primary outcome
  (e.g. appointment wait days). Used to compute % complete and to run
  [`mysterycall_caller_reliability()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caller_reliability.md).

- caller_col:

  Character scalar or `NULL`. Column identifying which caller placed
  each call. Caller names are standardized to title case.

- group_col:

  Character scalar or `NULL`. Grouping variable (e.g. `"insurance"`).
  Reserved for future use.

- physician_col:

  Character scalar or `NULL`. Column identifying unique physicians. Used
  to count N physicians.

- accepted_col:

  Character scalar. Column for appointment-acceptance indicator. Default
  `"contact_office"`.

- scenario_col:

  Character scalar or `NULL`. Column for clinical scenario.

- callers:

  Character vector or `NULL`. Fallback caller names when `caller_col` is
  `NULL` or when supplementing data-derived names.

- specialty:

  Character scalar. Specialty label for physician-selection paragraph.

- n_scenarios:

  Integer. Number of clinical scenarios tested. Default `3L`.

- scenario_names:

  Character vector. Names of the clinical scenarios.

- insurance_types:

  Character vector. Insurance types tested.

- ref_insurance:

  Character scalar. Reference insurance type.

- source_directory:

  Character scalar. Physician directory URL/name. Default
  `"voicesforpfd.org"`.

- sampling_method:

  Character scalar. How physicians were sampled. Default `"random"`.

- irb_institution:

  Character scalar. Name of the approving IRB.

- irb_number:

  Character scalar. IRB protocol number. Default prompts for manual
  completion.

- call_hours:

  Character scalar. Hours during which calls were placed.

- min_interval_hours:

  Integer. Minimum hours between calls to the same office. Default
  `24L`.

- caller_assignment:

  Character scalar. How callers were assigned.

- appointment_definition:

  Character scalar. What constitutes an appointment for this study.

- appointments_accepted:

  Logical. Whether appointments were accepted. Default `FALSE`.

- business_days_primary:

  Logical. Whether business days are the primary outcome unit. Default
  `FALSE` (calendar days).

- business_days_sensitivity:

  Logical. Whether a business-days sensitivity analysis was run. Default
  `TRUE`.

- data_platform:

  Character scalar. Data capture platform used.

- script_appendix:

  Character scalar. Appendix label for the call script.

- r_version:

  Character scalar or `NULL`. R version string. Defaults to the running
  R version.

- ...:

  Reserved for future arguments.

## Value

A list of class `mysterycall_materials_methods` with elements:

- `sections`:

  Named list of seven character scalars, one per reviewer concern:
  `caller_standardization`, `call_spacing`, `appointment_definition`,
  `physician_selection`, `missing_data`, `business_days`, `irb`.

- `full_text`:

  Character scalar. All seven paragraphs joined with `"\n\n"`.

- `stats`:

  Named list of computed study statistics.

- `reliability`:

  The `mysterycall_reliability` object from
  [`mysterycall_caller_reliability()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caller_reliability.md),
  or `NULL`.

- `callers_standardized`:

  Character vector. Title-case caller names used in the text.

- `items_needing_input`:

  Character vector. Placeholders that require manual completion before
  submission.

## Details

Caller names in `caller_col` are standardized to title case
([`tools::toTitleCase`](https://rdrr.io/r/tools/toTitleCase.html))
before any output is produced. Inter-caller reliability is computed via
[`mysterycall_caller_reliability()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caller_reliability.md)
when both `caller_col` and `outcome_col` are provided.

## See also

[`mysterycall_caller_reliability()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caller_reliability.md),
[`mysterycall_business_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_business_days.md),
[`mysterycall_missing_data_analysis()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_missing_data_analysis.md)

Other manuscript:
[`mysterycall_combined_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_combined_results_table.md),
[`mysterycall_export_results_docx()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_results_docx.md),
[`mysterycall_flow_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flow_diagram.md),
[`mysterycall_format_results_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_results_table.md),
[`mysterycall_literature_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_literature_table.md),
[`mysterycall_methods_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_methods_paragraph.md),
[`mysterycall_model_comparison_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_model_comparison_table.md),
[`mysterycall_multi_model_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_multi_model_table.md),
[`mysterycall_results_report()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_report.md),
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
[`print.mysterycall_strobe_checklist()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_strobe_checklist.md),
[`print.mysterycall_table2()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_table2.md)

## Examples

``` r
m <- mysterycall_materials_methods(
  callers    = c("Lizeth", "Merilyn", "Jessica"),
  irb_number = "COMIRB-2024-001"
)
print(m)
#> === Materials & Methods Section ===
#> 
#> -- caller standardization --
#> Three female research team members (Jessica, Lizeth, and Merilyn) were trained
#> as standardized callers prior to data collection. All callers used an identical
#> verbatim call script (see Appendix A); no improvisation was permitted. Callers
#> identified themselves as prospective new patients, provided the scripted
#> clinical complaint, stated their insurance type when asked, and requested the
#> first available appointment offered. Calls were placed during standard business
#> hours (Monday through Friday, 9:00 am - 4:00 pm local time). [Inter-caller
#> reliability results pending - run mysterycall_caller_reliability()]
#> 
#> 
#> -- call spacing --
#> To minimize scheduler recognition across repeated calls to the same practice, a
#> minimum interval of 24 hours elapsed between any two calls to the same
#> physician's office. Caller assignment was rotated systematically across
#> physicians and conditions to prevent caller-by-condition confounding.
#> 
#> 
#> -- appointment definition --
#> The primary outcome was the number of calendar days from the date of the call
#> to the date of the first available appointment offered. Callers recorded the
#> appointment date offered but did not confirm or accept any appointment. Calls
#> in which no appointment was offered were recorded as unsuccessful and excluded
#> from wait-time analyses.
#> 
#> 
#> -- physician selection --
#> Eligible physicians were board-certified Female Pelvic Medicine and
#> Reconstructive Surgery (FPMRS) specialists identified through a random sample
#> of the patient-facing physician directory (voicesforpfd.org). [N physicians -
#> confirm from data]. Physicians were not contacted in advance and were unaware
#> of their inclusion in the study.
#> 
#> 
#> -- missing data --
#> [N complete] of [N total] calls ([%]) had a complete appointment date. To
#> evaluate whether calls with missing appointment dates differed systematically
#> from those with complete data, physician and call characteristics were compared
#> between groups (see Supplemental Table [X] for the missing data analysis).
#> 
#> 
#> -- business days --
#> Although business days are the preferred scheduling metric, calendar days were
#> used as the primary unit because federal holiday calendars vary by state and
#> institution. A sensitivity analysis using business days (excluding weekends and
#> U.S. federal holidays) is reported in Supplemental Table [X].
#> 
#> 
#> -- irb --
#> The study was approved by the Colorado Multiple Institutional Review Board
#> (COMIRB) (Protocol No. COMIRB-2024-001). Given that office staff were unaware
#> they were being observed, the board granted a waiver of informed consent,
#> classifying the study as minimal risk. No protected health information was
#> collected, and no actual appointments were scheduled. The verbatim call script
#> is reproduced in Appendix A.
#> 
#> 
#> Items requiring manual input:
#>   [ ] Inter-caller reliability results (provide caller_col and outcome_col)
#>   [ ] N physicians (provide physician_col)
#>   [ ] N total calls (provide data)
#>   [ ] N complete calls (provide outcome_col)
#>   [ ] Supplemental table number for missing data analysis
#>   [ ] Supplemental table number for business-days sensitivity analysis
```
