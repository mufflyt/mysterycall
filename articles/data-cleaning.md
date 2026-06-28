# Data Cleaning: A Complete Workflow for Mystery Caller Studies

## Overview

A mystery caller study typically produces two raw datasets:

1.  **Phase 1** — the call scheduling log (physician name, practice,
    phone, state, NPI, insurance type)
2.  **Phase 2** — the call outcome log (wait time, appointment date,
    call result)

Both datasets need cleaning before analysis. This vignette walks through
every `mysterycall` cleaning tool in the order you would typically apply
them, using only synthetic data so no API keys are required.

------------------------------------------------------------------------

## 1. NPI validation (`mysterycall_validate_npi`)

National Provider Identifier (NPI) numbers are the primary join key
across all downstream tables. Bad NPIs must be caught early — a row with
a wrong NPI will silently match the wrong physician in every subsequent
lookup.

[`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md)
applies three checks in order:

1.  Strip non-digit characters and leading/trailing whitespace.
2.  Require exactly 10 digits.
3.  Validate the Luhn checksum (the algorithm the NPI standard
    mandates).

``` r

raw <- data.frame(
  npi           = c("1234567893", "0000000000", "123456789X", NA, "1234567893 "),
  physician_name = c("Smith, Alice", "Jones, Bob", "Park, Carol",
                     "Lee, David", "Smith, Alice"),
  stringsAsFactors = FALSE
)

validated <- mysterycall_validate_npi(raw)
#> 1 NPI value(s) are not 10 digits and were dropped before Luhn validation: 123456789
#> 1 NPI value(s) are 10 digits but failed the Luhn checksum and were dropped: 0000000000
#> Validated 4 candidate NPI(s): 1 wrong length, 1 failed Luhn, 2 passed.
validated[, c("npi", "npi_is_valid", "physician_name")]
#>          npi npi_is_valid physician_name
#> 1 1234567893         TRUE   Smith, Alice
#> 2 1234567893         TRUE   Smith, Alice
```

Only rows where `npi_is_valid == TRUE` survive. The returned data frame
is a strict subset of the input — no rows are ever added.

------------------------------------------------------------------------

## 2. Phone validation (`mysterycall_validate_phone`)

Office phone numbers collected during calls come in many formats. Before
you can use them for scheduling or re-call logic, validate each number
against North American Numbering Plan (NANP) rules and optionally
cross-check the area code against the physician’s reported state.

``` r

phones <- c(
  "(303) 555-1212",   # valid CO number
  "800-555-0199",     # toll-free — valid syntax, no state match
  "555-1212",         # missing area code — invalid
  NA,
  "13035551212"       # with leading country code — should strip to 10 digits
)

phone_results <- mysterycall_validate_phone(
  phones,
  practice_state = "CO"
)
phone_results
#>   phone_e164_valid phone_npa phone_state_from_npa phone_area_code_matches_state
#> 1             TRUE       303                   CO                          TRUE
#> 2            FALSE       800            toll-free                         FALSE
#> 3            FALSE      <NA>                 <NA>                         FALSE
#> 4            FALSE      <NA>                 <NA>                         FALSE
#> 5             TRUE       303                   CO                          TRUE
#>        phone_validity_flag
#> 1                    valid
#> 2 area_code_state_mismatch
#> 3           invalid_format
#> 4                  missing
#> 5                    valid
```

The `phone_validity_flag` column distinguishes five outcomes:

| Flag | Meaning |
|----|----|
| `"valid"` | Passes all NANP rules and area code matches state |
| `"missing"` | NA or blank |
| `"invalid_format"` | Wrong digit count or invalid NPA/NXX digits |
| `"unknown_area_code"` | Syntactically valid but area code not in lookup table |
| `"area_code_state_mismatch"` | Valid syntax, known area code, but wrong state |

Pass `practice_state = NULL` to skip the state-matching check when you
only want syntax validation.

------------------------------------------------------------------------

## 3. Address normalization

Addresses from NPPES and practice websites use inconsistent
abbreviations (“Street” vs “St”, “Suite” vs “Ste”, “California” vs
“CA”). The normalizer functions standardize each component to USPS
format so addresses can be matched or geocoded reliably.

Apply the functions in this order:

### 3a. ASCII normalization

``` r

# mysterycall_ascii_norm() is an internal helper; shown here for illustration.
raw_addr <- "123 Cafe Boulevard, Suite 4A"
mysterycall:::mysterycall_ascii_norm(raw_addr)
```

### 3b. Directional normalization (North → N, Northeast → NE)

``` r

mysterycall_normalize_directionals("1400 North Main Street")
mysterycall_normalize_directionals("201 Southeast Oak Avenue")
```

### 3c. Street suffix normalization (Street → ST, Boulevard → BLVD)

``` r

mysterycall_normalize_suffix("100 MAIN STREET")
mysterycall_normalize_suffix("500 OAK BOULEVARD SUITE 3")
```

### 3d. Unit designator normalization (Suite → STE, Apartment → APT)

``` r

mysterycall_normalize_units("100 Main St Suite 4", addr2 = NA)
mysterycall_normalize_units("200 Elm Ave", addr2 = "Apartment 7B")
```

### 3e. State abbreviation normalization

``` r

mysterycall_normalize_state("California")
mysterycall_normalize_state("new york")
mysterycall_normalize_state("CO")   # already abbreviated — returned as-is
```

### 3f. ZIP code normalization (zero-pad to 5 digits)

``` r

mysterycall_normalize_zip5(c("80202", "1234", "12345-6789", NA))
```

### 3g. P.O. Box detection

Flag addresses that cannot be visited in person:

``` r

mysterycall_is_po_box(c("P.O. Box 123", "100 Main Street", "PO Box 99", NA))
```

### Full address pipeline

Pipe all steps together for a data frame:

``` r

df_addr <- data.frame(
  addr1 = c("1234 north main street", "500 Oak Blvd Suite 3A",
             "P.O. Box 77", "789 Southeast Elm Avenue"),
  addr2 = c(NA, NA, NA, "Room 12"),
  state = c("Colorado", "california", "NY", "Texas"),
  zip   = c("80202", "90210", "10001", "77001"),
  stringsAsFactors = FALSE
)

df_addr$addr1_norm  <- sapply(df_addr$addr1, function(a) {
  a |>
    mysterycall_ascii_norm() |>
    mysterycall_normalize_directionals() |>
    mysterycall_normalize_suffix() |>
    mysterycall_strip_suite()
})
df_addr$state_abbr  <- mysterycall_normalize_state(df_addr$state)
df_addr$zip5        <- mysterycall_normalize_zip5(df_addr$zip)
df_addr$is_po_box   <- mysterycall_is_po_box(df_addr$addr1)

df_addr[, c("addr1_norm", "state_abbr", "zip5", "is_po_box")]
```

------------------------------------------------------------------------

## 4. Phase 1 log cleaning (`mysterycall_clean_phase1`)

The Phase 1 log is the scheduling dataset — one row per physician per
insurance type called.
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
performs:

- Column name standardization via
  [`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html)
- Text squishing and phone formatting
- NPI preservation and random-ID generation for rows without NPIs
- Optional row duplication for insurance pairing
- Academic/private practice classification
- Audit trail generation (JSON) for data provenance

``` r

phase1_raw <- data.frame(
  Names         = c("Smith, Alice MD", "Jones, Bob DO", "Park, Carol MD"),
  practice_name = c("Denver University Medical", "Downtown Family Clinic",
                    "Rocky Mountain Surgery"),
  phone_number  = c("3035551212", "(720) 555-9999", "303-555-8888"),
  state_name    = c("Colorado", "Colorado", "Colorado"),
  npi           = c("1234567893", NA, "1578798779"),
  for_redcap    = c(NA, NA, NA),
  stringsAsFactors = FALSE
)

result_phase1 <- mysterycall_clean_phase1(
  phase1_raw,
  output_directory = tempdir(),
  verbose          = FALSE,
  duplicate_rows   = TRUE
)
#> 
#> ── Column specification ────────────────────────────────────────────────────────
#> cols(
#>   Names = col_character(),
#>   practice_name = col_character(),
#>   phone_number = col_character(),
#>   state_name = col_character(),
#>   npi = col_double()
#> )

result_phase1[, c("id", "dr_name", "insurance", "phone_number", "academic",
                  "processing_flag_generated_id")]
#>   id   dr_name              insurance   phone_number         academic
#> 1  1    Dr. DO Blue Cross/Blue Shield (720) 555-9999 Private Practice
#> 2  2    Dr. DO               Medicaid (720) 555-9999 Private Practice
#> 3  3 Dr. Carol Blue Cross/Blue Shield (303) 555-8888 Private Practice
#> 4  4 Dr. Carol               Medicaid (303) 555-8888 Private Practice
#> 5  5 Dr. Alice Blue Cross/Blue Shield (303) 555-1212       University
#> 6  6 Dr. Alice               Medicaid (303) 555-1212       University
#>   processing_flag_generated_id
#> 1                        FALSE
#> 2                        FALSE
#> 3                        FALSE
#> 4                        FALSE
#> 5                        FALSE
#> 6                        FALSE
```

The function invisibly returns the cleaned data frame and writes two
files to `output_directory`:

- `clean_phase_1_results_<timestamp>.csv` (or `.parquet` if
  `output_format = "parquet"`)
- `audit_trail_<timestamp>.json` — machine-readable provenance record

### Accessing the audit trail

``` r

trail <- attr(result_phase1, "audit_trail")
cat(sprintf(
  "Rows: %d → %d  |  Duration: %.2fs  |  NPI completeness: %.0f%%\n",
  trail$input_rows,
  trail$output_rows,
  trail$duration_seconds,
  trail$quality_metrics$completeness_npi * 100
))
```

------------------------------------------------------------------------

## 5. Duplicate detection (`mysterycall_check_duplicates`)

Physicians called more than the protocol allows inflate your sample and
bias results. Flag repeat calls before analysis:

``` r

calls <- data.frame(
  npi         = c("1234567893", "1234567893", "1234567893",
                  "9876543210", "9876543210"),
  call_date   = as.Date(c("2024-01-10", "2024-01-12", "2024-01-15",
                           "2024-01-10", "2024-01-11")),
  insurance   = c("BCBS", "Medicaid", "BCBS",
                  "BCBS", "Medicaid"),
  stringsAsFactors = FALSE
)

dup_report <- mysterycall_check_duplicates(calls, id_col = "npi", max_calls = 2L)
dup_report
#>          npi  call_date insurance n_calls
#> 1 1234567893 2024-01-10      BCBS       3
#> 2 1234567893 2024-01-12  Medicaid       3
#> 3 1234567893 2024-01-15      BCBS       3
```

Rows flagged by
[`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md)
should be reviewed and removed (or justified) before the primary
analysis.

------------------------------------------------------------------------

## 6. Column renaming (`mysterycall_rename_columns`)

Raw exports from REDCap or spreadsheets often have verbose or
inconsistent column names. Use
[`mysterycall_rename_columns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_rename_columns.md)
to rename by substring match:

``` r

messy <- data.frame(
  physician_full_name_as_entered = "Smith, Alice",
  office_telephone_number        = "303-555-1212",
  national_provider_identifier   = "1234567893",
  stringsAsFactors = FALSE
)

clean <- mysterycall_rename_columns(
  messy,
  target_strings = c("physician_full_name", "telephone", "national_provider"),
  new_names      = c("physician_name", "phone", "npi")
)
#> --- Starting to search and rename columns based on target substrings ---
#> Matched 1 column(s) by substring match for 'physician_full_name': physician_full_name_as_entered
#> Renamed 'physician_full_name_as_entered' to 'physician_name'.
#> 
#> Matched 1 column(s) by substring match for 'telephone': office_telephone_number
#> Renamed 'office_telephone_number' to 'phone'.
#> 
#> Matched 1 column(s) by substring match for 'national_provider': national_provider_identifier
#> Renamed 'national_provider_identifier' to 'npi'.
#> 
#> --- Column renaming complete. Final column set: physician_name, phone, npi ---
names(clean)
#> [1] "physician_name" "phone"          "npi"
```

------------------------------------------------------------------------

## 7. Clinician data retrieval (`mysterycall_get_clinician_data`)

Once NPIs are validated, enrich your roster with NPPES data (specialty,
address, credential) via the `provider` package. This step requires the
`provider` package to be installed from GitHub:

``` r

remotes::install_github("andrewallenbruce/provider")
```

``` r

npi_df <- data.frame(
  npi = c("1234567893", "1578798779"),
  stringsAsFactors = FALSE
)

# Returns NULL silently per NPI when 'provider' is not installed.
clinician_info <- mysterycall_get_clinician_data(npi_df)
#> 1 NPI value(s) are 10 digits but failed the Luhn checksum and were dropped: 1578798779
#> Validated 2 candidate NPI(s): 0 wrong length, 1 failed Luhn, 1 passed.
#> NPI 1234567893: package 'provider' is not installed.
clinician_info
#> [1] npi          npi_is_valid
#> <0 rows> (or 0-length row.names)
```

The returned tibble has one row per NPI and carries columns such as
`taxonomies_desc` (NPPES taxonomy code), `basic_first_name`,
`basic_last_name`, and practice address fields.

> **Important:** Do not use `taxonomies_desc` to assign subspecialty.
> NPPES taxonomy codes reflect broad specialty groupings only. Use
> [`mysterycall_parse_certification_subspecialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_certification_subspecialty.md)
> for subspecialty assignment.

------------------------------------------------------------------------

## Putting it all together

A complete cleaning pipeline for a new mystery caller dataset:

``` r

library(mysterycall)

# 1. Validate NPIs
raw      <- readr::read_csv("phase1_raw.csv")
valid    <- mysterycall_validate_npi(raw)

# 2. Clean Phase 1 log
phase1   <- mysterycall_clean_phase1(
  valid,
  output_directory = "output/",
  verbose          = TRUE
)

# 3. Validate phone numbers
phone_ok <- mysterycall_validate_phone(
  phase1$phone_number,
  practice_state = phase1$state_name
)
phase1   <- cbind(phase1, phone_ok)

# 4. Normalize addresses
phase1$addr1_clean <- with(phase1, {
  mysterycall_normalize_directionals(
    mysterycall_normalize_suffix(
      mysterycall_ascii_norm(address_line_1)
    )
  )
})
phase1$state_abbr <- mysterycall_normalize_state(phase1$state_name)

# 5. Detect duplicates
dups     <- mysterycall_check_duplicates(phase1, id_col = "npi", max_calls = 2L)
phase1   <- phase1[phase1$npi %in% dups$npi[dups$n_calls <= 2L], ]

# 6. Enrich with NPPES clinician data (requires 'provider' package)
enriched <- mysterycall_get_clinician_data(phase1)
```

------------------------------------------------------------------------

## Function reference

| Function | Purpose |
|----|----|
| [`mysterycall_validate_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_npi.md) | Luhn-validate NPI numbers; drop invalid rows |
| [`mysterycall_validate_phone()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_phone.md) | NANP syntax check + area-code-to-state match |
| [`mysterycall_ascii_norm()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_ascii_norm.md) | Strip non-ASCII characters and collapse whitespace |
| [`mysterycall_normalize_directionals()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_directionals.md) | Expand/abbreviate N/S/E/W/NE/… |
| [`mysterycall_normalize_suffix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_suffix.md) | Street → ST, Boulevard → BLVD, etc. |
| [`mysterycall_normalize_units()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_units.md) | Suite → STE, Apartment → APT, etc. |
| [`mysterycall_normalize_state()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_state.md) | Full state name → 2-letter abbreviation |
| [`mysterycall_normalize_zip5()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_normalize_zip5.md) | Zero-pad ZIP to 5 digits |
| [`mysterycall_strip_suite()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strip_suite.md) | Remove suite/unit token from address line 1 |
| [`mysterycall_is_po_box()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_is_po_box.md) | Detect P.O. Box addresses |
| [`mysterycall_has_street_number()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_has_street_number.md) | Detect addresses that include a building number |
| [`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md) | Full Phase 1 log cleaning with audit trail |
| [`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md) | Flag physicians called more than N times |
| [`mysterycall_rename_columns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_rename_columns.md) | Rename columns by substring match |
| [`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md) | Retrieve NPPES data via `provider` package |
