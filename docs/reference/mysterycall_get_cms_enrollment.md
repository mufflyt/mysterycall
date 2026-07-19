# Retrieve CMS Monthly County-Level Enrollment Reports

Reads a county-level CMS monthly enrollment CSV export and returns the
row(s) for a single county. The CSV must already be in the tidy county
format used by this function; the raw CMS release is reshaped into these
columns upstream.

## Usage

``` r
mysterycall_get_cms_enrollment(cms_csv_path, county_fips)
```

## Arguments

- cms_csv_path:

  Path to the tidy CMS monthly enrollment CSV (see Details).

- county_fips:

  Five-digit State-County FIPS code to filter to. Leading zeros are
  handled: numeric FIPS (in the CSV or this argument) are left-padded to
  five characters before matching, so `"08031"` and `8031` both work.

## Value

A data frame (0 or more rows) with columns `FIPS` (a zero-padded
five-character string), `County`, `State`, `Medicare Enrollment`,
`Medicaid/CHIP Enrollment`, and `Report_Month`.

## Details

The CSV is expected to contain (with these exact, case-sensitive
headers):

- `FIPS`:

  Five-digit state-county FIPS code.

- `County`, `State`:

  County and state names.

- `Medicare Enrollment`:

  Medicare beneficiary count.

- `Medicaid/CHIP Enrollment`:

  Medicaid/CHIP beneficiary count.

- `Report_Month`:

  Reporting month label.

The function validates that every one of these columns is present and
errors with an explicit message (naming the missing columns and the
columns actually found) rather than failing deep inside
[`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html).
