# Write a reproducibility snapshot at analysis end

Records the R session state — timestamp, R version, loaded package
versions, any named seeds used during the analysis, and optional
free-text notes — to a structured plain-text file. Call this once at the
very end of a script to capture everything needed to reproduce the run.

## Usage

``` r
mysterycall_session_snapshot(
  file = "session_snapshot.txt",
  seeds = NULL,
  notes = NULL,
  append = FALSE,
  quiet = FALSE
)
```

## Arguments

- file:

  Character scalar. Output file path. Default `"session_snapshot.txt"`.

- seeds:

  Named integer vector or `NULL`. Any seeds used during the analysis,
  e.g. `c(bootstrap = 42L, imputation = 123L)`. Unnamed elements are
  labelled `seed_1`, `seed_2`, etc. Default `NULL`.

- notes:

  Character vector or `NULL`. Free-text notes appended verbatim under
  the `=== NOTES ===` section. Each element is written on its own line.
  Default `NULL`.

- append:

  Logical scalar. If `TRUE` *and* `file` already exists, content is
  appended rather than overwriting. Default `FALSE`.

- quiet:

  Logical scalar. If `FALSE` (default), emits a
  [`base::message()`](https://rdrr.io/r/base/message.html) reporting the
  output path on success.

## Value

`invisible(file)` — the output path — with S3 class
`"mysterycall_snapshot"`. When the return value is printed explicitly,
the file path and first 20 lines of the snapshot are displayed.

## Details

Seeds are often buried inside individual functions; this function
provides a single top-level call that collects them all in one place.

## Output file structure

    === REPRODUCIBILITY SNAPSHOT ===
    Date/Time: <timestamp>
    R Version: <version>
    Platform:  <platform>

    === SEEDS ===
    <name>: <value>

    === LOADED PACKAGES ===
    <pkg>  <version>

    === FULL SESSION INFO ===
    <capture.output(sessionInfo())>

    === NOTES ===
    <notes>

## See also

Other reporting:
[`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md),
[`mysterycall_direction_words`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_supplemental_tables()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_supplemental_tables.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`print.mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_abstract_numbers.md),
[`print.mysterycall_irr_days()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md),
[`print.mysterycall_snapshot()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_snapshot.md)

## Examples

``` r
snap <- tempfile(fileext = ".txt")

# Basic usage — seeds and notes
mysterycall_session_snapshot(
  file  = snap,
  seeds = c(bootstrap = 42L, imputation = 123L),
  notes = "Primary sensitivity analysis.",
  quiet = TRUE
)

# Inspect what was written
out <- mysterycall_session_snapshot(file = snap, append = TRUE, quiet = TRUE)
print(out)
#> Session snapshot: /tmp/Rtmp8uPU4S/file221537e33483.txt
#> ============================================================
#> === REPRODUCIBILITY SNAPSHOT ===
#> ============================================================
#> Date/Time: 2026-08-08 00:16:42 UTC
#> R Version: R version 4.6.1 (2026-06-24)
#> Platform:  x86_64-pc-linux-gnu
#> 
#> === SEEDS ===
#> bootstrap                      42
#> imputation                     123
#> 
#> === LOADED PACKAGES ===
#> Matrix                         1.7-5
#> ggplot2                        4.0.3
#> mysterycall                    1.6.3.9000
#> stringdist                     0.9.17
#> 
#> === FULL SESSION INFO ===
#> R version 4.6.1 (2026-06-24)
#> Platform: x86_64-pc-linux-gnu
#> ... (187 more lines not shown)
```
