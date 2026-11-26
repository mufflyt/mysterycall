# Canonical ZIP-5 extraction core

The single implementation behind
[`mysterycall_clean_zip()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_zip.md),
[`mysterycall_extract_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_zip5.md)
and
[`mysterycall_normalize_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_zip5.md).
All three used to re-implement extract-first-digit-run / truncate /
left-pad independently, and the copies diverged in exactly the edge
cases each was written to fix (a dropped leading zero survived in one
copy and not another). The only contract difference that survives
consolidation is `min_digits`: `extract_zip5` treats runs shorter than 3
digits as not-a-ZIP (`NA`), while the other two left-pad even a single
digit.

## Usage

``` r
.zip5_core(x, min_digits = 1L)
```

## Arguments

- x:

  Character or numeric vector.

- min_digits:

  Minimum digit-run length accepted as a ZIP candidate.

## Value

Character vector of 5-digit ZIPs or `NA`.

## Details

The first digit RUN – not the first five digits of the concatenated
digit string – is what gets padded, because the hyphen in `"7001-1234"`
is the only thing marking where the 5-digit part ends when its leading
zero was dropped; concatenating first yields `"70011"` there. Digit runs
that are not a ZIP shape are `NA` rather than truncated: 6 or 10+ digits
cannot be a ZIP or a lost-zero ZIP+4 (a phone number in the ZIP column
used to become a ZIP), 7-8 digits are a ZIP+4 that lost its leading
zero(s), and scientific notation is unrecoverable corruption, not
digits.
