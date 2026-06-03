# Determine the cache directory used for downloaded resources

Determine the cache directory used for downloaded resources

## Usage

``` r
mysterycall_cache_dir(...)
```

## Arguments

- ...:

  Optional path components appended to the cache directory.

## Value

Character scalar. Absolute path to the cache directory. When `...` is
empty, returns the cache root (created automatically if absent). When
`...` supplies path components, they are appended via
[`file.path()`](https://rdrr.io/r/base/file.path.html) before returning;
the directory is not created in that case.

## Examples

``` r
mysterycall:::mysterycall_cache_dir()
#> [1] "/home/runner/.cache/R/mysterycall"
mysterycall:::mysterycall_cache_dir("hrr")
#> [1] "/home/runner/.cache/R/mysterycall/hrr"
```
