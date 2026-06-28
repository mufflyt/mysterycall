# Ensure the Dartmouth Atlas HRR boundary shapefile is available locally

Downloads the shapefile archive from the Dartmouth Atlas website when it
is not already present in the user's cache directory. The archive is
expanded in-place and the path to the `.shp` file is returned.

## Usage

``` r
ensure_hrr_shapefile(quiet = TRUE)
```

## Arguments

- quiet:

  Logical flag passed to
  [`mysterycall_download_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_download_file.md)
  to silence the underlying download tooling.

## Value

The absolute path to the HRR boundary shapefile.

## Examples

``` r
# Requires internet access to download an ~8 MB shapefile on first call.
if (FALSE) { # \dontrun{
mysterycall:::ensure_hrr_shapefile()
} # }
```
