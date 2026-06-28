# Order a column's factor levels by descending frequency

Uses
[`forcats::fct_infreq()`](https://forcats.tidyverse.org/reference/fct_inorder.html)
when available; otherwise delegates to the package's own
[`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md).

## Usage

``` r
.mc_infreq_col(data, col)
```

## Arguments

- data:

  A data frame.

- col:

  Column name to reorder.

## Value

     `data` with `col` converted to a frequency-ordered factor.
