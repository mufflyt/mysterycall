# Standardize DO credential format

Converts "Linda Smith D.O." -\> "Linda Smith, D.O." while leaving "Linda
Do" (Vietnamese surname) untouched.

## Usage

``` r
.handle_do_credential(names_raw)
```

## Arguments

- names_raw:

  Character vector of raw physician names.

## Value

Character vector with standardized DO credentials.

## See also

Other name-parsing:
[`.handle_three_part_comma()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_three_part_comma.md),
[`.is_name_suffix()`](https://mufflyt.github.io/mysterycall/reference/dot-is_name_suffix.md),
[`.parse_physician_name_impl()`](https://mufflyt.github.io/mysterycall/reference/dot-parse_physician_name_impl.md),
[`mysterycall_format_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_physician_name.md),
[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md),
[`mysterycall_test_name_parser()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_name_parser.md),
[`mysterycall_validate_parsed_names()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_parsed_names.md)
