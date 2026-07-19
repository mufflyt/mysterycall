# Verify the content-addressable identity of an audit trail JSON file

Loads an audit JSON written by
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md),
strips the volatile fields, recomputes the SHA-256 digest of the stable
payload, and compares it against the stored `artifact_id`. A mismatch
means the file was modified after it was written or the `artifact_id`
was computed with different logic.

## Usage

``` r
mysterycall_verify_artifact(audit_path)
```

## Arguments

- audit_path:

  Character scalar. Path to an `audit_trail_*.json` file.

## Value

Invisibly returns `TRUE` if verification passes. Throws an informative
error if verification fails or the file cannot be parsed.

## Contract

**Inputs:**

- `audit_path` must point to a readable JSON file produced by
  [`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
  at schema version \>= 1.2.0.

**Guarantees:**

- Returns `TRUE` (invisibly) only when `artifact_id` matches the
  recomputed digest. Any other outcome raises an error with a diagnostic
  message.

- Never modifies the audit file.

**Fails if:**

- `audit_path` does not exist or is not valid JSON.

- The file was produced by a schema version prior to 1.2.0 (no
  `artifact_id`).

- The recomputed digest does not match the stored `artifact_id`.

## Called By

- Downstream validation scripts and CI pipelines

## See also

Other workflow:
[`mysterycall_call_productivity()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_call_productivity.md),
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md),
[`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md),
[`mysterycall_print_dashboard()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_print_dashboard.md),
[`mysterycall_run_workflow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow.md),
[`mysterycall_run_workflow_logged()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_run_workflow_logged.md),
[`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md)

## Examples

``` r
if (FALSE) { # interactive()
# Verify an audit file written by clean_phase1
mysterycall_verify_artifact("path/to/audit_trail_2026-05-09.json")
}
```
