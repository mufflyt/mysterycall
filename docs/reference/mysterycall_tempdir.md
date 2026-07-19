# Internal helper for package-specific temporary directories

Provides a stable location within
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) that can be reused
across functions which need to write ephemeral artifacts while avoiding
modifications to the user's working tree. Directories are created on
demand when `create = TRUE`.

## Usage

``` r
mysterycall_tempdir(..., create = FALSE)
```

## Arguments

- ...:

  Optional path components appended to the base directory.

- create:

  Logical flag. When `TRUE`, ensure the directory exists.

## Value

A character vector containing the resolved path.
