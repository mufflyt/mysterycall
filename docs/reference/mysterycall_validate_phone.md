# Validate North-American (NANP) phone number strings

Strips non-digit characters, applies North American Numbering Plan
(NANP) syntactic rules, looks up each area code's home state, and
optionally checks whether that state matches the physician's practice
state.

## Usage

``` r
mysterycall_validate_phone(phone_str, practice_state = NULL, nanp_path = NULL)
```

## Arguments

- phone_str:

  Character vector of phone strings (NAs allowed). Accepts common
  formats: `"(NPA) NXX-XXXX"`, `"NPA-NXX-XXXX"`, bare 10 digits, or
  `"1NPANXXXXXX"`.

- practice_state:

  Character vector of 2-letter US state postal codes, the same length as
  `phone_str` or length 1 (recycled). Pass `NULL` to skip the
  state-matching check (all `phone_area_code_matches_state` entries will
  be `NA`).

- nanp_path:

  Optional path to a custom NANP lookup CSV. When `NULL` (default) the
  bundled `inst/extdata/nanp_area_codes_us.csv` is used.

## Value

A data frame with one row per element of `phone_str` and columns:

- `phone_e164_valid`:

  Logical. `TRUE` if the number passes all NANP syntactic rules.

- `phone_npa`:

  Character. The 3-digit North American Numbering Plan area code, or
  `NA_character_` when the number is syntactically invalid.

- `phone_state_from_npa`:

  Character. The 2-letter US postal abbreviation for the area code's
  registered state, or `NA_character_` when the area code is absent from
  the bundled lookup table.

- `phone_area_code_matches_state`:

  Logical. `TRUE` when `phone_state_from_npa` exactly matches
  `practice_state`; `FALSE` when they differ; `NA` when `practice_state`
  is `NULL`.

- `phone_validity_flag`:

  Character. One of `"valid"`, `"missing"`, `"invalid_format"`,
  `"unknown_area_code"`, or `"area_code_state_mismatch"`.

## Details

Syntactic validity rules applied:

- Exactly 10 digits after stripping non-digits (an optional leading
  `"1"` country code is dropped first).

- NPA first digit (N) is 2-9.

- NXX first digit (N) is 2-9.

- NXX is not an N11 code (e.g. 911, 411, 211).

Area-code-to-state mapping is loaded from the bundled
`inst/extdata/nanp_area_codes_us.csv` file. Pass `nanp_path` to override
with a custom CSV that has columns `area_code` (integer) and `state`
(2-letter US postal abbreviation).

## Data format

    mysterycall_validate_phone(
      c("(303) 555-1212", "555-1212", NA, "800-555-0199"),
      practice_state = "CO"
    )

## See also

[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md)
to structure name strings;
[`mysterycall_validate_parsed_names()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_parsed_names.md)
for name-level quality checks;
[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md)
to attach validated phone data to a roster.

Other data quality:
[`mysterycall_not_contacted_states()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_not_contacted_states.md),
[`mysterycall_remove_constants()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_remove_constants.md),
[`mysterycall_remove_near_zero()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_remove_near_zero.md)

## Examples

``` r
mysterycall_validate_phone(
  c("(303) 555-1212", "555-1212", NA),
  practice_state = "CO"
)
#>   phone_e164_valid phone_npa phone_state_from_npa phone_area_code_matches_state
#> 1             TRUE       303                   CO                          TRUE
#> 2            FALSE      <NA>                 <NA>                         FALSE
#> 3            FALSE      <NA>                 <NA>                         FALSE
#>   phone_validity_flag
#> 1               valid
#> 2      invalid_format
#> 3             missing

# Without state matching
mysterycall_validate_phone(c("2125551234", "0005551234"), practice_state = NULL)
#>   phone_e164_valid phone_npa phone_state_from_npa phone_area_code_matches_state
#> 1             TRUE       212                   NY                            NA
#> 2            FALSE       000                 <NA>                            NA
#>   phone_validity_flag
#> 1               valid
#> 2      invalid_format
```
