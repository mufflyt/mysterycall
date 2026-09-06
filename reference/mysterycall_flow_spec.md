# Validate a participant-flow specification

Checks that a STROBE/CONSORT participant flow actually closes: each step
on the spine, minus the exclusions leaving it, equals the next step, and
the children of every split sum to their parent. Returns a validated
object for
[`mysterycall_strobe_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_diagram.md)
to draw.

## Usage

``` r
mysterycall_flow_spec(
  spine,
  exclusions = list(),
  splits = list(),
  assert = TRUE
)

# S3 method for class 'mysterycall_flow_spec'
print(x, ...)
```

## Arguments

- spine:

  Named numeric vector of the main-column boxes, top to bottom, in
  order. At least two entries. Names are the box labels.

- exclusions:

  Named list. Each name must match a `spine` entry, and is the step the
  exclusion arrow leaves FROM. Each element is a named numeric vector of
  one or more reasons; the names become the exclusion box lines. Steps
  with no exclusions may be omitted.

- splits:

  Named list. Each name must match a `spine` entry or another split's
  child. Each element is a named numeric vector whose values must sum to
  the named parent. Use this for a terminal published/not-published
  split, or a breakdown that stays inside its parent rather than leaving
  the study.

- assert:

  Logical. When `TRUE` (default), arithmetic that does not close is an
  error. `FALSE` still type-checks but permits a deliberately partial
  diagram; the returned object records `closed = FALSE`.

- x:

  A `mysterycall_flow_spec`.

- ...:

  Ignored.

## Value

An object of class `mysterycall_flow_spec`: a list with `spine`,
`exclusions`, `splits` and `closed`.

## Details

The arithmetic is the point. A renderer draws what it is handed, so a
flow diagram can be internally plausible and still disagree with the
study it describes. Validating separately from drawing means the same
check can run in a test suite, where a stale figure is actually caught,
rather than only at render time on someone's laptop.

## See also

[`mysterycall_strobe_diagram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_diagram.md)
to draw a validated spec,
[`mysterycall_strobe_flow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_flow.md)
for the mystery-caller-specific diagram.

## Examples

``` r
# The AAGL abstract-publication cohort (mufflyt/abstract_lifetime).
spec <- mysterycall_flow_spec(
  spine = c(
    "Abstracts parsed from congress supplements" = 1154,
    "Oral presentation cohort"                   = 1106,
    "Evaluated for publication status"           = 1051
  ),
  exclusions = list(
    "Abstracts parsed from congress supplements" = c("Video presentations" = 48),
    "Oral presentation cohort"                   = c("Adjudication unresolved" = 55)
  ),
  splits = list(
    "Evaluated for publication status" = c("Published" = 170, "Not published" = 881),
    "Not published" = c("No qualifying publication" = 839,
                        "Publication predates the congress" = 42)
  )
)
spec
#> <mysterycall_flow_spec> arithmetic closes
#>   Abstracts parsed from congress supplements: n = 1,154
#>       -> excluded: Video presentations, n = 48
#>   Oral presentation cohort: n = 1,106
#>       -> excluded: Adjudication unresolved, n = 55
#>   Evaluated for publication status: n = 1,051
#>   Evaluated for publication status splits into Published (n = 170) + Not published (n = 881)
#>   Not published splits into No qualifying publication (n = 839) + Publication predates the congress (n = 42)

# A step that does not close is an error, and the message names the step.
try(mysterycall_flow_spec(
  spine = c("Screened" = 100, "Analysed" = 90),
  exclusions = list("Screened" = c("Ineligible" = 5))
))
#> Error : this flow does not close:
#>   - Screened (100) minus 5 excluded is 95, but the next step Analysed is 90
```
