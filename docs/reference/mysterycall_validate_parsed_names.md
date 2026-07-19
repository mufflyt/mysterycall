# Validate parsed physician names for quality issues

Extends the output of
[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md)
with a suite of quality-control columns: presence flags, overall
validity, and diagnostic codes for common parsing artefacts such as
credentials misplaced in the last-name field or suspiciously short
surnames.

## Usage

``` r
mysterycall_validate_parsed_names(
  parsed_names,
  require_first = TRUE,
  require_last = TRUE
)
```

## Arguments

- parsed_names:

  A tibble from
  [`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md),
  with at least columns `first_name`, `last_name`, `middle_name`, and
  `parse_confidence`.

- require_first:

  Logical. When `TRUE` (default) rows where `first_name` is `NA` are
  marked `is_valid = FALSE`. Set `FALSE` for data sources that store
  only last names (e.g. single-name lookup tables).

- require_last:

  Logical. When `TRUE` (default) rows where `last_name` is `NA` are
  marked `is_valid = FALSE`. Set `FALSE` when processing mononyms or
  incomplete name strings where absence of a surname is expected.

## Value

The input tibble with additional columns:

- `has_first`, `has_last`, `has_middle`:

  Logical presence flags.

- `valid_first`, `valid_last`:

  Logical – pass the `require_*` gate.

- `is_valid`:

  `valid_first & valid_last`.

- `last_is_credential`:

  Logical – last name looks like `"MD"`, `"PHD"`, etc.

- `last_is_suffix`:

  Logical – last name looks like `"Jr"`, `"III"`, etc.

- `last_too_short`:

  Logical – last name is 1-2 chars (excluding common short surnames such
  as `"Do"`, `"Li"`, `"Ng"`, `"Wu"`).

- `middle_has_particle`:

  Logical – middle name contains a name particle (`"de"`, `"van"`,
  `"von"`, etc.) that may belong in the last name.

- `quality_issue`:

  First detected quality issue code, or `NA`.

## See also

[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md)

Other name-parsing:
[`.handle_do_credential()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_do_credential.md),
[`.handle_three_part_comma()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_three_part_comma.md),
[`.is_name_suffix()`](https://mufflyt.github.io/mysterycall/reference/dot-is_name_suffix.md),
[`.parse_physician_name_impl()`](https://mufflyt.github.io/mysterycall/reference/dot-parse_physician_name_impl.md),
[`mysterycall_format_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_physician_name.md),
[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md),
[`mysterycall_test_name_parser()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_name_parser.md)

## Examples

``` r
parsed <- mysterycall_parse_physician_name(c("Smith, John, Jr.", "MD"))
validated <- mysterycall_validate_parsed_names(parsed)
validated$is_valid       # c(TRUE, FALSE)
#> [1]  TRUE FALSE
validated$quality_issue  # c(NA, "last_name_is_credential")
#> [1] NA NA
```
