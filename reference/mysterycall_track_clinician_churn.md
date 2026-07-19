# Track Clinician Churn at a Specific Practice Location (NPPES History)

Since Tax Identifiers (TINs) are private, this function tracks office
locations longitudinally using physical practice address matches and
organization NPI associations within a historical NPPES DuckDB database.

## Usage

``` r
mysterycall_track_clinician_churn(
  db_path,
  street_address,
  zip_code,
  table_name = "temporal_obgyn_only_all_years"
)
```

## Arguments

- db_path:

  Path to the DuckDB database (e.g. "/Volumes/MufflySamsung
  1/nppes_historical.duckdb").

- street_address:

  Character. Practice Location Address Line 1.

- zip_code:

  Character. Five-digit ZIP code.

- table_name:

  Character. Name of the historical NPPES table to query in the DuckDB
  database. Default `"temporal_obgyn_only_all_years"`.

## Value

A data frame containing annual staffing levels, entries, exits, and
churn rates.
