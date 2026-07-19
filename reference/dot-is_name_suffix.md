# Test whether a post-comma name segment is a suffix or credential

Distinguishes a genuine generational suffix / professional credential
(`"Jr."`, `"MD"`, `"PhD"`, ...) from a given name. Used to tell the
documented `"Last, First"` format apart from `"First Last, MD"`.

## Usage

``` r
.is_name_suffix(x)
```

## Arguments

- x:

  Character scalar (a single comma-delimited segment, trimmed).

## Value

Logical scalar; `TRUE` when `x` looks like a suffix/credential.

## See also

Other name-parsing:
[`.handle_do_credential()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_do_credential.md),
[`.handle_three_part_comma()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_three_part_comma.md),
[`.parse_physician_name_impl()`](https://mufflyt.github.io/mysterycall/reference/dot-parse_physician_name_impl.md),
[`mysterycall_format_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_physician_name.md),
[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md),
[`mysterycall_test_name_parser()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_name_parser.md),
[`mysterycall_validate_parsed_names()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_parsed_names.md)
