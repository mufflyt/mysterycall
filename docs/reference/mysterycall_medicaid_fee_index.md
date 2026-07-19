# Retrieve State-Level Medicaid-to-Medicare Fee Index Ratios

Looks up the Kaiser Family Foundation (KFF) Medicaid-to-Medicare fee
index for a vector of state abbreviations. The index is the ratio of
what a state's Medicaid program pays to what Medicare pays for the same
services; a value below 1 means Medicaid reimburses below Medicare.
Values are read from the packaged
[medicaid_fee_index](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md)
dataset (2024, All Services; all 50 states + DC) so the function and the
data cannot drift apart.

## Usage

``` r
mysterycall_medicaid_fee_index(states, fallback = NULL)
```

## Arguments

- states:

  Character vector of two-letter state abbreviations (e.g.
  `c("FL", "NJ", "CA")`). Case- and whitespace-insensitive.

- fallback:

  Numeric scalar used for states not present in the dataset (invalid
  codes, territories) and for Tennessee, whose 2024 index is `NA` (no
  comprehensive fee-for-service Medicaid fee schedule). Defaults to the
  national All-Services average (0.75). Pass `NA` to preserve genuine
  missingness instead of filling it.

## Value

A numeric vector, the same length and order as `states`, of fee index
ratios (with `fallback` substituted as described).

## See also

[medicaid_fee_index](https://mufflyt.github.io/mysterycall/reference/medicaid_fee_index.md)
for the underlying dataset.

## Examples

``` r
mysterycall_medicaid_fee_index(c("FL", "NJ", "CA"))
#> [1] 0.64 0.61 0.67

# Preserve NA for Tennessee / unknown states instead of the national average
mysterycall_medicaid_fee_index(c("TN", "CA", "ZZ"), fallback = NA)
#> [1]   NA 0.67   NA
```
