# Run the end-to-end mystery caller workflow

This helper orchestrates the core steps required to prepare and execute
a mystery caller campaign. It stitches together roster creation, NPI
validation, call sheet preparation, workload splitting, and Phase 2 data
hygiene checks so teams can focus on execution instead of plumbing.

## Usage

``` r
mysterycall_run_workflow(
  taxonomy_terms = NULL,
  name_data = NULL,
  phase1_data,
  lab_assistant_names,
  output_directory,
  phase2_data,
  phase2_output_directory = output_directory,
  quality_check_path,
  phase1_output_directory = output_directory,
  split_insurance_order = c("Medicaid", "Blue Cross/Blue Shield"),
  phase2_required_strings = c("physician_information", "able_to_contact_office",
    "are_we_including", "reason_for_exclusions", "appointment_date",
    "number_of_transfers", "call_time", "hold_time", "notes", "person_completing",
    "state", "npi", "name"),
  phase2_standard_names = c("physician_info", "contact_office", "included_in_study",
    "exclusion_reasons", "appt_date", "transfer_count", "call_duration", "hold_duration",
    "notes", "completed_by", "state", "npi", "name"),
  npi_search_args = list(),
  all_states = NULL,
  taxonomy_states = NULL,
  verbose = interactive(),
  npi_progress_observer = NULL
)
```

## Arguments

- taxonomy_terms:

  Character vector of taxonomy descriptions to pass to
  [`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md).
  Set to `NULL` to skip taxonomy-based searches.

- name_data:

  Optional data frame containing `first` and `last` columns to use with
  [`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md).
  Provide `NULL` to skip name-based searches.

- phase1_data:

  Data frame holding Phase 1 calling roster information to pass to
  [`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md).

- lab_assistant_names:

  Character vector of caller names used when splitting the cleaned
  roster via
  [`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md).
  Must contain at least two entries.

- output_directory:

  Directory where
  [`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md)
  should write the complete and per-caller workbooks.

- phase2_data:

  Data frame or file path consumed by
  [`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md).

- phase2_output_directory:

  Directory where Phase 2 exports should be written. Defaults to
  `output_directory`.

- quality_check_path:

  File path where
  [`mysterycall_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_quality_table.md)
  should write the quality check CSV.

- phase1_output_directory:

  Directory where
  [`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
  should write the cleaned Phase 1 CSV. Defaults to `output_directory`.

- split_insurance_order:

  Ordering passed to
  [`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md)'s
  `insurance_order` argument. Defaults to
  `c("Medicaid", "Blue Cross/Blue Shield")`.

- phase2_required_strings:

  Character vector of substrings used when standardizing Phase 2 column
  names via
  [`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md).

- phase2_standard_names:

  Replacement names corresponding to `phase2_required_strings`.

- npi_search_args:

  Named list of additional arguments forwarded to
  [`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md).

- all_states:

  Optional character vector of all states to supply to
  [`mysterycall_not_contacted_states()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_not_contacted_states.md).

- taxonomy_states:

  Optional character vector of two-letter state abbreviations forwarded
  to
  [`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
  as its `states` argument. When `NULL` (default) the search is national
  and capped at 1,200 records per taxonomy term. Pass all 50
  abbreviations to bypass the cap for large specialties.

- verbose:

  Logical. When `TRUE`, print stage updates to the console while running
  the workflow. Defaults to
  [`interactive()`](https://rdrr.io/r/base/interactive.html).

- npi_progress_observer:

  Optional callback that receives progress updates from
  [`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md).
  It is invoked with the same payload as the `progress_callback`
  argument for that function.

## Value

A list containing intermediate artifacts from each workflow stage:
`roster`, `validated_roster`, `cleaned_phase1`, `cleaned_phase2`,
`coverage_summary`, `quality_check_table`, and a `workflow_summary` data
frame documenting row counts, retention rates, and output paths for
audit transparency.

## Contract

**Inputs:**

- `phase1_data` must contain columns: `names`, `practice_name`,
  `phone_number`, `state_name`, `npi`, `for_redcap`.

- `lab_assistant_names` must have at least two entries for workload
  splitting.

- `output_directory` must be writable; created automatically if absent.

**Guarantees:**

- Output list always contains `workflow_summary` even when upstream
  steps fail.

- Row counts at each stage are recorded in `workflow_summary` for audit
  transparency.

- Files written to `output_directory` are overwritten deterministically
  on re-run with the same inputs.

**Fails if:**

- `phase1_data` is missing required columns (error from
  [`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)).

- `lab_assistant_names` has fewer than two entries.

- `output_directory` is not writable and cannot be created.

## Performance

Complexity is approximately O(n) in number of Phase 1 rows for local
steps. NPI registry calls via
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
add O(t \* p) where `t` = number of taxonomy terms and `p` = max records
per term (default 1,200). Budget ~5-30 s per taxonomy term depending on
network latency.

## Calls

- [`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
  (when `taxonomy_terms` is non-NULL)

- [`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)
  (when `name_data` is non-NULL)

- [`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)

- [`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md)

- [`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md)

- [`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md)

- [`mysterycall_not_contacted_states()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_not_contacted_states.md)

- [`mysterycall_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_quality_table.md)

## See also

Stage functions called by this workflow:
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md),
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md),
[`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md),
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md),
[`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md).
Run
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md)
before starting to catch missing API keys and malformed inputs early.

Other workflow:
[`mysterycall_call_productivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_call_productivity.md),
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md),
[`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md),
[`mysterycall_print_dashboard()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_print_dashboard.md),
[`mysterycall_run_workflow_logged()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow_logged.md),
[`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md),
[`mysterycall_verify_artifact()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_verify_artifact.md)

## Examples

``` r
if (FALSE) { # interactive()
results <- mysterycall_run_workflow(
  phase1_data = data.frame(
    names = "Jane Doe", practice_name = "Clinic A",
    phone_number = "555-0100", state_name = "Colorado",
    npi = "1234567890", for_redcap = "Yes"
  ),
  lab_assistant_names = c("Alice", "Bob"),
  output_directory = tempdir(),
  phase2_data = data.frame(),
  quality_check_path = file.path(tempdir(), "qc.csv")
)
}
```
