# Split data into multiple parts and save each part as separate Excel files

This function splits the data based on provided lab assistant names and
saves each part as a separate Excel file. It allows the arrangement of
calls by insurance type to prioritize Medicaid in the first two days and
Blue Cross/Blue Shield in the last two days.

## Usage

``` r
mysterycall_split_and_save(
  data_or_path,
  output_directory,
  lab_assistant_names,
  seed = 1978,
  complete_file_prefix = "complete_non_split_version_",
  split_file_prefix = "",
  recursive_create = TRUE,
  insurance_order = c("Medicaid", "Blue Cross/Blue Shield")
)
```

## Arguments

- data_or_path:

  Either a dataframe containing the input data or a path to the input
  data file (RDS, CSV, Parquet, or XLS/XLSX).

- output_directory:

  Directory where output Excel files will be saved.

- lab_assistant_names:

  Vector of lab assistant names to name the output files.

- seed:

  Seed value for randomization (default is 1978).

- complete_file_prefix:

  Prefix for the complete output file name (default is
  "complete_non_split_version\_").

- split_file_prefix:

  Prefix for each split output file name (default is empty).

- recursive_create:

  Logical indicating if directories should be created recursively
  (default is TRUE).

- insurance_order:

  Vector of insurance types ordered by priority for call scheduling
  (default is c("Medicaid", "Blue Cross/Blue Shield")).

## Value

[`invisible()`](https://rdrr.io/r/base/invisible.html) character vector
of absolute file paths to the created Excel files. Element 1 is the
combined "all callers" workbook; subsequent elements are the
per-assistant split workbooks in the order of `lab_assistant_names`.
Capture with `paths <- mysterycall_split_and_save(...)` to use the paths
downstream.

## Contract

**Inputs:**

- `lab_assistant_names` must have \\\geq\\ 2 entries; function errors if
  only one name is provided.

- `seed` controls the random assignment of rows to assistants; the same
  seed always produces the same split.

- `output_directory` is created if absent.

**Guarantees:**

- Every input row appears in exactly one assistant's workbook (no row
  duplication, no silent omission).

- Workbooks are sorted by `insurance_order` so Medicaid rows appear
  first.

- A combined "all callers" workbook is written in addition to individual
  files.

**Disaster Prevention:** Prevents unequal workload distribution by using
round-robin row assignment rather than random block sampling, which can
produce highly skewed splits for small rosters.

## Performance

O(n log n) due to sorting. Excel I/O via `openxlsx` dominates for large
rosters; expect ~2-5 s for 500 rows.

## Called By

- [`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)

## See also

Other workflow:
[`mysterycall_call_productivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_call_productivity.md),
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md),
[`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md),
[`mysterycall_print_dashboard()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_print_dashboard.md),
[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md),
[`mysterycall_run_workflow_logged()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow_logged.md),
[`mysterycall_verify_artifact()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_verify_artifact.md)

## Examples

``` r
if (FALSE) { # interactive()
input_data <- readr::read_csv("/path/to/your/input/file.csv")
output_directory <- "/path/to/your/output/directory"
lab_assistant_names <- c("Label1", "Label2", "Label3")
insurance_order <- c("Medicaid", "Blue Cross/Blue Shield")
mysterycall_split_and_save(
  data_or_path = input_data,
  output_directory = output_directory,
  lab_assistant_names = lab_assistant_names,
  insurance_order = insurance_order
)
}
```
