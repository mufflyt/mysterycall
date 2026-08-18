# Read (or locate) the most recent file matching a pattern - loudly

Mystery-caller pipelines routinely re-export the same REDCap instrument
or roster many times, leaving a directory full of dated files. The
common `latest()` idiom - "glob a folder, pick the newest, read it" - is
a quiet footgun: it returns `NA` (or nothing) when no file matches,
never announces *which* file it chose, and silently reads a stale export
when a fresh one failed to land. A wrong file then flows all the way to
the results with no warning.

## Usage

``` r
mysterycall_read_latest(
  dir,
  pattern = NULL,
  format = NULL,
  read = TRUE,
  max_age_days = NULL,
  recursive = FALSE,
  ignore_case = FALSE,
  quiet = FALSE,
  ...
)
```

## Arguments

- dir:

  Character scalar. Directory to search. Must exist.

- pattern:

  Character scalar or `NULL`. Regular expression matched against file
  names (as in
  [`list.files()`](https://rdrr.io/r/base/list.files.html)). `NULL`
  (default) matches every file. To match a literal string containing
  regex metacharacters, wrap it in
  [`fixed()`](https://stringr.tidyverse.org/reference/modifiers.html)-style
  escaping yourself or pass an anchored pattern such as
  `"^redcap_export_.*\\.csv$"`.

- format:

  Optional character scalar passed to
  [`mysterycall_read_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_table.md):
  `"csv"` or `"parquet"`. When `NULL` (default) the format is inferred
  from the chosen file's extension. Ignored when `read = FALSE`.

- read:

  Logical. When `TRUE` (default) the chosen file is read and its
  contents returned. When `FALSE` only the resolved file path (character
  scalar) is returned.

- max_age_days:

  Positive number or `NULL`. When supplied, a warning is emitted if the
  newest matching file is more than `max_age_days` days old. Default
  `NULL` (no staleness check).

- recursive:

  Logical. When `TRUE`, search `dir` recursively. Default `FALSE`.

- ignore_case:

  Logical. When `TRUE`, `pattern` matching is case-insensitive. Default
  `FALSE`.

- quiet:

  Logical. When `TRUE`, suppress the "chose " announcement message.
  Warnings and errors are still raised. Default `FALSE`.

- ...:

  Additional arguments forwarded to
  [`mysterycall_read_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_table.md)
  when `read = TRUE`.

## Value

When `read = TRUE`, a data frame (tibble) with the resolved absolute
path attached as the `"path"` attribute. When `read = FALSE`, the
resolved file path as a character scalar.

## Details

`mysterycall_read_latest()` is the loud replacement. It:

- **errors** (never returns `NA`) when zero files match, printing the
  directory and pattern that came up empty;

- **announces** the chosen file and its modification time, plus how many
  candidates it beat, so the selection is visible in the log;

- **warns on staleness** when the newest match is older than
  `max_age_days`, catching the "today's export never wrote" case;

- **warns on ties** when two files share the newest modification time,
  because "the newest" is then ambiguous.

By default it reads the file via
[`mysterycall_read_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_table.md)
(CSV or Parquet) and returns the data frame with the resolved path
stored in the `"path"` attribute. Set `read = FALSE` to return just the
path - a drop-in for the bare `latest()` calls that only needed a
filename.

## Migrating from `latest()`

    # Before - silent, returns NA when nothing matches:
    f  <- latest("data/redcap", "\\.csv$")
    df <- read.csv(f)

    # After - announces its choice, errors instead of returning NA,
    # warns if the newest export is more than a day old:
    df <- mysterycall_read_latest("data/redcap", "\\.csv$", max_age_days = 1)
    path <- attr(df, "path")   # which file it actually read

## See also

[`mysterycall_read_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_table.md)
for the underlying reader;
[`mysterycall_resolve_path()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_resolve_path.md)
for constructing standard paths.

Other utilities:
[`.title_case()`](https://mufflyt.github.io/mysterycall/reference/dot-title_case.md),
`%>%`,
[`format_phone_number()`](https://mufflyt.github.io/mysterycall/reference/format_phone_number.md),
[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md),
[`mysterycall_check_api_response()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_api_response.md),
[`mysterycall_check_data_completeness()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_data_completeness.md),
[`mysterycall_check_dependencies()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_dependencies.md),
[`mysterycall_check_no_data_loss()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_data_loss.md),
[`mysterycall_check_no_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_limits.md),
[`mysterycall_download_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_download_file.md),
[`mysterycall_estimate_resources()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_estimate_resources.md),
[`mysterycall_export_with_backup()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_with_backup.md),
[`mysterycall_normalize_file_format()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_file_format.md),
[`mysterycall_parse_redcap_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_redcap_labels.md),
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md),
[`mysterycall_quality_tier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_quality_tier.md),
[`mysterycall_reached_declined_reasons()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reached_declined_reasons.md),
[`mysterycall_read_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_read_table.md),
[`mysterycall_require_arrow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_require_arrow.md),
[`mysterycall_resolve_path()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_resolve_path.md),
[`mysterycall_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_quality_table.md),
[`mysterycall_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scan_for_limits.md),
[`mysterycall_standard_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_labels.md),
[`mysterycall_standard_palette()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_palette.md),
[`mysterycall_write_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table.md)

## Examples

``` r
# Set up a directory with two dated exports
dir <- tempfile("redcap_")
dir.create(dir)
old_file <- file.path(dir, "export_2026-07-01.csv")
new_file <- file.path(dir, "export_2026-07-20.csv")
utils::write.csv(data.frame(x = 1), old_file, row.names = FALSE)
utils::write.csv(data.frame(x = 2), new_file, row.names = FALSE)
# Make the second file unambiguously newer
Sys.setFileTime(old_file, Sys.time() - 3600)

# Return just the path to the newest match
mysterycall_read_latest(dir, "\\.csv$", read = FALSE)
#> mysterycall_read_latest: chose 'export_2026-07-20.csv' (modified 2026-08-18 04:21, 0.0 days ago); beat 1 other candidate(s).
#> [1] "/tmp/RtmpHfUp2D/redcap_21884174e6b7/export_2026-07-20.csv"
```
