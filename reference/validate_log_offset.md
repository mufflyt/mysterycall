# Validate an Exposure Column Used as a Log Offset

A log offset requires a strictly positive, finite exposure: `log(0)` is
`-Inf` and `log(x)` for `x < 0` is `NaN`. Either value makes the model
frame unusable, and the fitting engine drops the affected rows silently,
so the model is estimated on a smaller cohort than the caller is told
about. This check refuses the input instead.

## Usage

``` r
validate_log_offset(x, name, check_positive = TRUE, row_ids = NULL)
```

## Arguments

- x:

  Numeric vector of exposures.

- name:

  Character scalar naming the column for error messages.

- check_positive:

  Logical flag. When `FALSE`, only the `NaN` check runs, for use on the
  supplied column before complete-case filtering.

- row_ids:

  Optional integer vector mapping positions in `x` back to rows of the
  caller's data frame, so that a reported row number refers to the
  record the analyst can actually look up. Supply this whenever `x` is a
  filtered cohort rather than the original column.

## Value

`invisible(TRUE)`. Called for the error side effect.

## Details

The offending values are never replaced with a small positive constant;
choosing such a constant is a study-specific decision that belongs to
the analyst, not to this function.

`NA` exposures are permitted: they are a declared exclusion that the
caller's complete-case filter removes and reports. The positivity check
is therefore applied to the complete-case cohort, so that a row excluded
for an unrelated reason cannot abort an otherwise valid analysis. The
`NaN` check is separate and runs on the supplied column, because
[`complete.cases()`](https://rdrr.io/r/stats/complete.cases.html) cannot
tell `NaN` from `NA`.

## See also

Other validation:
[`.audit_volatile_fields`](https://mufflyt.github.io/mysterycall/reference/dot-audit_volatile_fields.md),
[`.load_nanp_lookup()`](https://mufflyt.github.io/mysterycall/reference/dot-load_nanp_lookup.md),
[`.mc_check_coord_axis()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_check_coord_axis.md),
[`.mc_conv_warning_pattern()`](https://mufflyt.github.io/mysterycall/reference/dot-mc_conv_warning_pattern.md),
[`assert_model_cohort()`](https://mufflyt.github.io/mysterycall/reference/assert_model_cohort.md),
[`summarise_fit_warnings()`](https://mufflyt.github.io/mysterycall/reference/summarise_fit_warnings.md),
[`validate_coordinates()`](https://mufflyt.github.io/mysterycall/reference/validate_coordinates.md),
[`validate_dataframe()`](https://mufflyt.github.io/mysterycall/reference/validate_dataframe.md),
[`validate_outcome_finite()`](https://mufflyt.github.io/mysterycall/reference/validate_outcome_finite.md),
[`validate_required_columns()`](https://mufflyt.github.io/mysterycall/reference/validate_required_columns.md),
[`validate_scalar_positive_numeric()`](https://mufflyt.github.io/mysterycall/reference/validate_scalar_positive_numeric.md),
[`warn_non_integer_counts()`](https://mufflyt.github.io/mysterycall/reference/warn_non_integer_counts.md)
