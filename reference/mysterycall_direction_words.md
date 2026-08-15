# Direction and change words wired to the sign of the data

Small helpers for manuscript and abstract prose that pick a direction
word from the **sign of a value**, so the words can never drift out of
step with the numbers they describe. Both functions are vectorized and
return `NA_character_` for `NA` input.

`mysterycall_get_direction()` chooses a comparison word (default
`"higher"` / `"lower"` / `"no different"`);
`mysterycall_get_change_verb()` chooses a trend word (default
`"increasing"` / `"decreasing"` / `"stable"`). Every word is an
argument, so each subspecialty or table can supply its own vocabulary
while the positive/negative/zero mapping stays fixed to the data.

## Usage

``` r
mysterycall_get_direction(
  x,
  positive = "higher",
  negative = "lower",
  zero = "no different",
  tol = 0
)

mysterycall_get_change_verb(
  x,
  increasing = "increasing",
  decreasing = "decreasing",
  stable = "stable",
  tol = 0
)
```

## Arguments

- x:

  Numeric vector. The signed quantity (e.g. a difference, slope, or
  percent change). Its sign selects the word.

- positive:

  Word used when `x > tol`. Default `"higher"`.

- negative:

  Word used when `x < -tol`. Default `"lower"`.

- zero:

  Word used when `abs(x) <= tol`. Default `"no different"`.

- tol:

  Non-negative numeric scalar. Values with `abs(x) <= tol` are treated
  as no change and get the zero word. Default `0` (exact zero only).

- increasing:

  Word used when `x > tol`. Default `"increasing"`.

- decreasing:

  Word used when `x < -tol`. Default `"decreasing"`.

- stable:

  Word used when `abs(x) <= tol`. Default `"stable"`.

## Value

A character vector the same length as `x`.

## See also

Other reporting:
[`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md),
[`mysterycall_exclusion_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_exclusion_summary.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md),
[`mysterycall_supplemental_tables()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_supplemental_tables.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`print.mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_abstract_numbers.md),
[`print.mysterycall_irr_days()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md),
[`print.mysterycall_snapshot()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_snapshot.md)

## Examples

``` r
mysterycall_get_direction(c(2.4, -1.1, 0, NA))
#> [1] "higher"       "lower"        "no different" NA            
# "higher" "lower" "no different" NA

mysterycall_get_change_verb(c(3.2, -0.4, 0))
#> [1] "increasing" "decreasing" "stable"    
# "increasing" "decreasing" "stable"

# Subspecialty-specific vocabulary, still tied to the data sign:
slope <- -0.8
sprintf("The MFM workforce is %s (%.1f per year).",
        mysterycall_get_change_verb(slope), slope)
#> [1] "The MFM workforce is decreasing (-0.8 per year)."
```
