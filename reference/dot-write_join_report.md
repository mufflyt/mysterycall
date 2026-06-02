# Write Join Audit Report

Writes a one-row CSV audit record; atomic (write to .tmp, then rename).

## Usage

``` r
.write_join_report(metrics, report_prefix)
```

## Arguments

- metrics:

  Data frame with join metrics.

- report_prefix:

  Character scalar for filename.

## Value

`invisible(NULL)`.
