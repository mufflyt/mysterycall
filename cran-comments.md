> **Not submission-ready as written.** The environments and check results below
> must be re-run and updated immediately before an actual CRAN submission; the
> numbers here describe the last local run, not a fresh one. See "Before
> submitting" at the bottom.

## Test environments

* macOS 13.7.8 (local), R 4.4.2
* GitHub Actions: ubuntu-latest (R release), plus a full matrix on pushes to
  main -- see `.github/workflows/R-CMD-check.yaml`
* R-hub, on demand via `.github/workflows/rhub.yaml`

win-builder R-devel and R-release are **not** currently part of the automated
matrix. Run them before submitting.

## R CMD check results

Most recent local run: **0 errors | 0 warnings | 6 notes**.

Two of those six are artifacts of the local machine rather than the package:
`Gmisc` is listed in Suggests but not installed here, which produces both a
"package suggested but not available" note and an Rd cross-reference note.
Neither appears on a machine with Suggests installed.

The remaining four:

* installed size is over 5Mb. `data/` is the driver. `LazyDataCompression: xz`
  is already set and `zcta_tract_xwalk` was trimmed from 3.0 MB to 882 KB by
  dropping two columns that are deterministic functions of a third.
* "Lost braces" in `mysterycall_strobe_flow.Rd`, from a literal `{0, 7, 9, 10}`
  in prose.
* 94 marked UTF-8 strings in `data/`.
* one further note; re-run to confirm the current set.

The check is gated strictly in CI: `error-on: '"warning"'` on every event, so
any WARNING fails the build rather than accumulating silently.

## Suggests

All Suggests are CRAN packages. Package code guards optional dependencies with
`requireNamespace(..., quietly = TRUE)` and either returns `NULL`, emits a
`message()`, or calls `stop()` when one is missing.

One known exception: `R/this_one_works.R` calls `jsonlite::fromJSON()`
unguarded. That file is not on the default branch at time of writing; if it
lands, add a guard before submitting.

## Reverse dependencies

None. The package is not currently on CRAN.

## Before submitting

1. Re-run `R CMD check --as-cran` locally and replace the counts above.
2. Run win-builder R-devel and R-release.
3. Confirm the "Test environments" list matches what was actually run.
4. Restore an accurate package-rename note if one applies. A previous version
   of this file claimed the package "renames the package from `mysterycall` to
   `mysterycall`", which is self-contradictory: a find/replace had rewritten
   the old name to the new one on both sides of the sentence. The original
   name is not recoverable from this repository's history, so the section was
   removed rather than guessed at. If a rename genuinely needs declaring,
   write it fresh.
