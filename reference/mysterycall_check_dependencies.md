# Check for required R package dependencies

Check for required R package dependencies

## Usage

``` r
mysterycall_check_dependencies(
  packages,
  install = FALSE,
  repos = getOption("repos"),
  quietly = FALSE
)
```

## Arguments

- packages:

  Character vector of package names to verify.

- install:

  Logical; when `TRUE`, attempt to install missing packages using
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html).
  Defaults to `FALSE`.

- repos:

  Character vector of repositories to forward to
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  when `install = TRUE`.

- quietly:

  Logical flag controlling console output. When `TRUE`, suppresses
  status messages.

## Value

A tibble summarizing the dependency status for each package.

## See also

Other utilities:
[`.title_case()`](https://mufflyt.github.io/mysterycall/reference/dot-title_case.md),
`%>%`,
[`format_phone_number()`](https://mufflyt.github.io/mysterycall/reference/format_phone_number.md),
[`mysterycall_assess_data_quality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assess_data_quality.md),
[`mysterycall_check_api_response()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_api_response.md),
[`mysterycall_check_data_completeness()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_data_completeness.md),
[`mysterycall_check_no_data_loss()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_data_loss.md),
[`mysterycall_check_no_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_no_limits.md),
[`mysterycall_download_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_download_file.md),
[`mysterycall_estimate_resources()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_estimate_resources.md),
[`mysterycall_export_with_backup()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_export_with_backup.md),
[`mysterycall_normalize_file_format()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_file_format.md),
[`mysterycall_preflight_check()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_preflight_check.md),
[`mysterycall_quality_tier()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_quality_tier.md),
[`mysterycall_require_arrow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_require_arrow.md),
[`mysterycall_resolve_path()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_resolve_path.md),
[`mysterycall_save_quality_table()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_save_quality_table.md),
[`mysterycall_scan_for_limits()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scan_for_limits.md),
[`mysterycall_standard_labels()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_labels.md),
[`mysterycall_standard_palette()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_standard_palette.md)

## Examples

``` r
# \donttest{
mysterycall_check_dependencies(c("dplyr", "sf"), install = FALSE)
#> # A tibble: 2 × 4
#>   package installed version install_command              
#>   <chr>   <lgl>     <chr>   <chr>                        
#> 1 dplyr   TRUE      1.2.1   "install.packages(\"dplyr\")"
#> 2 sf      TRUE      1.1-1   "install.packages(\"sf\")"   
# }
```
