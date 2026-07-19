# Clean and process Phase 2 data

This function reads data from a file or data frame, cleans column names,
and applies renaming based on specified criteria to facilitate data
analysis. The function logs each step of the process, including data
loading, column cleaning, and renaming for transparency.

## Usage

``` r
mysterycall_clean_phase2(
  data_or_path,
  required_strings,
  standard_names,
  output_directory = NULL,
  output_format = c("csv", "parquet")
)
```

## Arguments

- data_or_path:

  Path to the data file or a data frame.

- required_strings:

  Vector of substrings for which to search in column names.

- standard_names:

  Character vector of replacement names, the same length as
  `required_strings`, applied to matched columns in order.

- output_directory:

  Directory where the cleaned dataset should be written. Defaults to a
  session-specific folder inside
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) when not provided.

- output_format:

  File format to use when persisting the cleaned dataset. Supported
  values are "csv" (default) and "parquet".

## Value

A data frame with processed data.

## Column name transformation

All input column names are converted to **lowercase snake_case** by
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html)
**unconditionally** before `required_strings` pattern matching.
Transformation cannot be disabled. Common examples:

|                            |                                        |
|----------------------------|----------------------------------------|
| **Input column name**      | **After `clean_names()`**              |
| `"Physician Information"`  | `"physician_information"`              |
| `"NPI Number"`             | `"npi_number"`                         |
| `"Q1-2023 Revenue"`        | `"q1_2023_revenue"`                    |
| `"able_to_contact_office"` | `"able_to_contact_office"` (unchanged) |
| `"ContactOfficeYN"`        | `"contact_office_yn"`                  |

To preview the exact names your data will have, run
`names(janitor::clean_names(your_data))` before calling this function,
then write `required_strings` to match those transformed names.

## Output file timestamps

Output filenames include a timestamp from
[`Sys.time()`](https://rdrr.io/r/base/Sys.time.html), which uses the
**local system timezone** (not UTC). Filenames produced on systems in
different timezones will reflect different local times for the same
wall-clock moment. To force UTC filenames, wrap the call:

    withr::with_timezone("UTC", {
      mysterycall_clean_phase2(data, required_strings, standard_names)
    })

## See also

[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
for Phase 1 data cleaning;
[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md)
which orchestrates both phases;
[`mysterycall_rename_columns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_rename_columns.md)
for the underlying column-renaming logic.

Other workflow:
[`mysterycall_call_productivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_call_productivity.md),
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md),
[`mysterycall_print_dashboard()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_print_dashboard.md),
[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md),
[`mysterycall_run_workflow_logged()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow_logged.md),
[`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md),
[`mysterycall_verify_artifact()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_verify_artifact.md)

## Examples

``` r
if (FALSE) { # interactive()
# Assuming an input path to a CSV file
input_path <- "path_to_your_data.csv"
required_strings <- c("physician_information", "able_to_contact_office")
standard_names <- c("physician_info", "contact_office")
cleaned_data <- mysterycall_clean_phase2(input_path, required_strings, standard_names)

# Directly using a data frame
df <- data.frame(
  doc_info = 1:5,
  contact_data = 6:10
)
required_strings <- c("doc_info", "contact_data")
standard_names <- c("doctor_info", "patient_contact_info")
cleaned_df <- mysterycall_clean_phase2(df, required_strings, standard_names)
print(cleaned_df)
}
```
