# Reorder three-part comma-separated names

Converts "Smith, John, Jr." -\> "John Smith, Jr." so humaniformat
handles it correctly.

## Usage

``` r
.handle_three_part_comma(x)
```

## Arguments

- x:

  Character vector of physician names.

## Value

Character vector with reordered name components.

## See also

Other name-parsing:
[`.handle_do_credential()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_do_credential.md),
[`.is_name_suffix()`](https://mufflyt.github.io/mysterycall/reference/dot-is_name_suffix.md),
[`.parse_physician_name_impl()`](https://mufflyt.github.io/mysterycall/reference/dot-parse_physician_name_impl.md),
[`mysterycall_format_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_physician_name.md),
[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md),
[`mysterycall_test_name_parser()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_name_parser.md),
[`mysterycall_validate_parsed_names()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_parsed_names.md)
