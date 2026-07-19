# Core implementation of physician name parsing

Internal workhorse function for
[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md).

## Usage

``` r
.parse_physician_name_impl(physician_name, remove_titles)
```

## Arguments

- physician_name:

  Character vector of physician name strings.

- remove_titles:

  Logical scalar. Whether to strip leading titles.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with parsed name components.

## See also

Other name-parsing:
[`.handle_do_credential()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_do_credential.md),
[`.handle_three_part_comma()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_three_part_comma.md),
[`.is_name_suffix()`](https://mufflyt.github.io/mysterycall/reference/dot-is_name_suffix.md),
[`mysterycall_format_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_physician_name.md),
[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md),
[`mysterycall_test_name_parser()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_name_parser.md),
[`mysterycall_validate_parsed_names()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_parsed_names.md)
