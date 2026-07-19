# Extract County-Level Metrics from HRSA Area Health Resources File (AHRF)

Reads county-level population, OB-GYN supply, and public-coverage
metrics from a **preprocessed** AHRF DuckDB database.

## Usage

``` r
mysterycall_get_hrsa_ahrf(ahrf_db_path, county_fips)
```

## Arguments

- ahrf_db_path:

  Path to a DuckDB database holding the preprocessed `ahrf_county_data`
  table (see Details).

- county_fips:

  Character. Five-digit State-County FIPS code.

## Value

A data frame containing total population, OB-GYN supply, and public
coverage metrics for the requested county (0 rows if the FIPS is
absent).

## Details

The raw HRSA Area Health Resources File ships as fixed-width ASCII with
cryptic field codes, so this function does **not** read it directly. It
expects a DuckDB database containing a table named `ahrf_county_data`
that has already been reshaped to the following columns (built upstream,
e.g. in a `data-raw/` script):

- `fips`:

  Five-digit state-county FIPS code.

- `county_name`, `state_abbrev`:

  County name and state abbreviation.

- `pop_total`:

  Total county population.

- `obgyn_count`:

  OB-GYN clinician supply.

- `medicaid_enrolled`:

  Medicaid enrollment count.

The function validates that the `ahrf_county_data` table and every
required column exist, erroring with an explicit message (naming what is
missing and what was found) rather than emitting an opaque SQL error.
CSV input is not currently supported.
