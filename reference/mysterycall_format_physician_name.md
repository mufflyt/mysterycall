# Format parsed physician name components into a display string

Reassembles the structured columns produced by
[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md)
into a human-readable name string. All arguments are vectorised.

## Usage

``` r
mysterycall_format_physician_name(
  first_name,
  last_name,
  middle_name = NA,
  suffix = NA,
  format = "last_first",
  include_suffix = TRUE
)
```

## Arguments

- first_name, last_name:

  Character vectors. Required.

- middle_name:

  Character vector. Default `NA` (omitted).

- suffix:

  Character vector of professional or generational suffixes (`"MD"`,
  `"Jr."`). Default `NA` (omitted).

- format:

  Character scalar – output layout:

  `"last_first"`

  :   (default) `"Smith, John A., MD"`

  `"first_last"`

  :   `"John A. Smith, MD"`

  `"formal"`

  :   Same as `"last_first"` with suffix always appended.

- include_suffix:

  Logical. When `FALSE` the suffix is always omitted. Default `TRUE`.

## Value

Character vector the same length as the longest input argument.

## See also

[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md)

Other name-parsing:
[`.handle_do_credential()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_do_credential.md),
[`.handle_three_part_comma()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_three_part_comma.md),
[`.is_name_suffix()`](https://mufflyt.github.io/mysterycall/reference/dot-is_name_suffix.md),
[`.parse_physician_name_impl()`](https://mufflyt.github.io/mysterycall/reference/dot-parse_physician_name_impl.md),
[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md),
[`mysterycall_test_name_parser()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_name_parser.md),
[`mysterycall_validate_parsed_names()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_parsed_names.md)

## Examples

``` r
mysterycall_format_physician_name("John", "Smith", middle_name = "A.",
                                  suffix = "MD")
#> [1] "Smith, John A., MD"
# "Smith, John A., MD"

mysterycall_format_physician_name("Maria", "de la Cruz",
                                  format = "first_last",
                                  include_suffix = FALSE)
#> [1] "Maria de la Cruz"
# "Maria de la Cruz"
```
