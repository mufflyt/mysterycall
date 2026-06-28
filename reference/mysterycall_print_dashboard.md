# Print a formatted summary dashboard

Prints a Unicode-box-drawing summary table showing row counts at each
stage of the mystery caller workflow.

## Usage

``` r
mysterycall_print_dashboard(results)
```

## Arguments

- results:

  Named list of workflow results as returned by
  [`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md).

## Value

Invisible NULL.

## See also

Other workflow:
[`mysterycall_call_productivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_call_productivity.md),
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md),
[`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md),
[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md),
[`mysterycall_run_workflow_logged()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow_logged.md),
[`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md),
[`mysterycall_verify_artifact()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_verify_artifact.md)

## Examples

``` r
if (FALSE) { # interactive()
results <- mysterycall_run_workflow_logged(phase1_data = my_data)
mysterycall:::mysterycall_print_dashboard(results)
}
```
