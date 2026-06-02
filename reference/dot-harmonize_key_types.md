# Harmonize Key Column Types

Coerces mismatched key column types to character on both sides to
prevent silent 0-match joins after RDS/Parquet round-trips (e.g. integer
-\> double).

## Usage

``` r
.harmonize_key_types(
  left,
  right,
  by,
  label_left = "left",
  label_right = "right"
)
```

## Arguments

- left:

  Data frame.

- right:

  Data frame.

- by:

  Join keys.

- label_left:

  Label for left table.

- label_right:

  Label for right table.

## Value

A named list with "left" and "right" data frames.
