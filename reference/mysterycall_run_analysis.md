# Run the Full Mystery-Caller Analysis Pipeline

A high-level orchestrator that chains quality-control checks,
deduplication, Medicaid column cleaning, demographic summaries, scenario
counts, insurance acceptance rates, wait-time analyses, Poisson
regression, and a sensitivity analysis into a single reproducible call.
Each step is wrapped in error handling so that a failure in one step
does not abort the rest of the pipeline.

## Usage

``` r
mysterycall_run_analysis(
  data,
  outcome_col = "business_days_until_appointment",
  insurance_col = "insurance",
  id_col = "id_number",
  phone_col = "phone",
  exclusion_col = "reason_for_exclusions",
  scenario_col = "scenario",
  medicaid_col = "does_the_physician_accept_medicaid",
  medicaid_label = "Medicaid",
  bcbs_label = "Blue Cross/Blue Shield",
  contact_value = "Able to contact",
  output_dir = NA,
  steps = c("qc", "dedup", "clean_medicaid", "demographics", "scenarios",
    "acceptance_rates", "wait_times", "poisson", "sensitivity"),
  verbose = TRUE
)
```

## Arguments

- data:

  A data frame of mystery-caller records.

- outcome_col:

  Character scalar. Name of the numeric wait-time column. Default
  `"business_days_until_appointment"`.

- insurance_col:

  Character scalar. Insurance type column. Default `"insurance"`.

- id_col:

  Character scalar. Physician identifier column. Default `"id_number"`.

- phone_col:

  Character scalar. Physician phone column. Default `"phone"`.

- exclusion_col:

  Character scalar. Exclusion-reason column. Default
  `"reason_for_exclusions"`.

- scenario_col:

  Character scalar. Scenario label column. Default `"scenario"`.

- medicaid_col:

  Character scalar. Medicaid acceptance column. Default
  `"does_the_physician_accept_medicaid"`.

- medicaid_label:

  Character scalar. Value in `insurance_col` identifying Medicaid calls.
  Default `"Medicaid"`.

- bcbs_label:

  Character scalar. Value in `insurance_col` identifying Blue Cross/Blue
  Shield calls. Default `"Blue Cross/Blue Shield"`.

- contact_value:

  Character scalar. Value in `exclusion_col` indicating a successful
  contact. Default `"Able to contact"`.

- output_dir:

  Character scalar or `NA`. Directory for CSV outputs. `NA` (default)
  skips all file writing. Pass `NULL` to write to session temp
  directories via
  [`mysterycall_tempdir`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tempdir.md).

- steps:

  Character vector. Which analysis steps to run. Any subset of
  `c("qc","dedup","clean_medicaid","demographics","scenarios", "acceptance_rates","wait_times","poisson","sensitivity")`.
  Default runs all nine steps.

- verbose:

  Logical. If `TRUE` (default), emit progress messages from the
  orchestrator. Sub-function messages are unaffected.

## Value

Invisibly returns a named list with one slot per pipeline step plus
three bookkeeping elements:

- `qc`:

  List with elements `repeat_physicians` (tibble from
  [`mysterycall_flag_repeat_physicians`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md))
  and `exclusion_discrepancy` (tibble from
  [`mysterycall_flag_exclusion_discrepancy`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md)).
  `NULL` when the step is not in `steps`.

- `dedup`:

  Deduplicated tibble from
  [`mysterycall_dedup_by_insurance`](https://mufflyt.github.io/mysterycall/reference/mysterycall_dedup_by_insurance.md),
  or `NULL`. When non-`NULL` the working data is updated for all
  subsequent steps.

- `clean_medicaid`:

  Data frame with two new cleaned columns from
  [`mysterycall_clean_medicaid_col`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_medicaid_col.md),
  or `NULL`. When non-`NULL` the working data is updated for all
  subsequent steps.

- `demographics`:

  Named list from
  [`mysterycall_sample_demographics`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_demographics.md)
  (includes `summary_sentence`), or `NULL`.

- `scenarios`:

  Named list from
  [`mysterycall_scenario_summary`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md)
  (includes `sentence`), or `NULL`.

- `acceptance_rates`:

  Named list from
  [`mysterycall_insurance_acceptance_rates`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_acceptance_rates.md)
  (includes `paragraph`), or `NULL`.

- `wait_times`:

  Named list from
  [`mysterycall_insurance_wait_sentence`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_wait_sentence.md),
  or `NULL`.

- `poisson`:

  Object of class `mysterycall_simple_poisson` from
  [`mysterycall_simple_poisson`](https://mufflyt.github.io/mysterycall/reference/mysterycall_simple_poisson.md)
  (includes `irr_table`), or `NULL`.

- `sensitivity`:

  Named list from
  [`mysterycall_sensitivity_both_insurance`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)
  (includes `n_both`), or `NULL`.

- `data_deduped`:

  Data frame. The working data after any deduplication and
  Medicaid-column cleaning steps have been applied.

- `steps_run`:

  Character vector of step names that were requested via the `steps`
  argument.

- `steps_errored`:

  Character vector of step names that encountered an error or had
  missing required columns.

## See also

[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)
builds and cleans the call log this analyzes; together they form the
collection -\> analysis pipeline.

## Examples

``` r
if (FALSE) { # \dontrun{
set.seed(1)
n <- 20
phones <- paste0("555-", sprintf("%04d", seq_len(n)))
df <- data.frame(
  id_number  = rep(paste0("NPI", seq_len(n)), 2L),
  phone      = rep(phones, 2L),
  insurance  = c(rep("Medicaid", n), rep("Blue Cross/Blue Shield", n)),
  reason_for_exclusions = sample(
    c("Able to contact", "Not available"), 2L * n, replace = TRUE
  ),
  business_days_until_appointment = rpois(2L * n, 14L),
  scenario   = sample(c("HIP scenario", "SHOULDER scenario"), 2L * n,
                      replace = TRUE),
  does_the_physician_accept_medicaid = sample(
    c("Yes they accept Medicaid", "No"), 2L * n, replace = TRUE
  ),
  state = sample(c("Colorado", "Texas", "Florida"), 2L * n, replace = TRUE),
  stringsAsFactors = FALSE
)
result <- mysterycall_run_analysis(df, output_dir = NA)
cat(result$demographics$summary_sentence)
print(result$poisson$irr_table)
} # }
```
