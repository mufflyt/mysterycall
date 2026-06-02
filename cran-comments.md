## Test environments

* macOS 15.6 (local), R 4.6.0
* win-builder R-devel
* win-builder R-release
* GitHub Actions (R-hub) — Linux / macOS / Windows

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Package rename

This submission renames the package from `tyler` to `mysterycall`. The previous
`tyler` package was never accepted to CRAN. All exported functions now carry the
`mysterycall_` prefix. The former `tyler_` and unprefixed names are retained as
deprecated backward-compatibility shims via `.Deprecated()`.

## Suggests

All Suggests are CRAN packages. Each usage in package code is guarded with
`requireNamespace(..., quietly = TRUE)` and functions either return `NULL`,
emit a `message()`, or call `stop()` when an optional package is missing.

## Reverse dependencies

There are no reverse dependencies (new submission).
