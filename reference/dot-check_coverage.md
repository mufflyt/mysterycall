# Enforce Join Coverage Thresholds

Enforces coverage \>= min_coverage and output rows \<= left_n (no
fan-out).

## Usage

``` r
.check_coverage(left_n, matched_n, label_left, label_right, min_coverage, by)
```

## Arguments

- left_n:

  Number of rows in left table.

- matched_n:

  Number of rows that found a match.

- label_left:

  Label for left table.

- label_right:

  Label for right table.

- min_coverage:

  Minimum allowed coverage (0-1).

- by:

  Join keys.

## Value

`invisible(TRUE)` on success; stops on failure.
