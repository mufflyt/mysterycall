# Print method for mysterycall_reliability objects

Print method for mysterycall_reliability objects

## Usage

``` r
# S3 method for class 'mysterycall_reliability'
print(x, ...)
```

## Arguments

- x:

  A `mysterycall_reliability` object.

- ...:

  Ignored.

## Value

`invisible(x)`.

## See also

Other caller-management:
[`mysterycall_caller_reliability()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_caller_reliability.md)

## Examples

``` r
# \donttest{
df <- data.frame(
  caller  = c("A", "A", "B", "B"),
  outcome = c(1L, 0L, 1L, 1L)
)
res <- mysterycall_caller_reliability(df, "caller", "outcome")
#> Only 2 complete pair(s) found. ICC and kappa are unreliable with fewer than 30 pairs; interpret results with caution.
print(res)
#> -- mysterycall_caller_reliability --
#> Method       : kappa 
#> Statistic    : NA 
#> 95% CI       : [ NA , NA ]
#> N pairs      : 2 
# }
```
