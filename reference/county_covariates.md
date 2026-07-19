# County provider counts and Medicare/Medicaid enrollment covariates

Two covariate builders that summarise physician supply and public-payer
enrollment at the county (5-digit FIPS) level, for merging onto
mystery-caller office data as environment covariates alongside the ACS
payer mix from
[`mysterycall_get_payer_mix()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_payer_mix.md).

- [`mysterycall_get_county_provider_counts()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_county_provider_counts.md)
  collapses a provider roster (one row per NPI, or per NPI-location) to
  a distinct-provider count per county, optionally scaled to a
  per-capita density.

- [`mysterycall_summarize_county_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_county_enrollment.md)
  aggregates CMS Medicare and Medicaid enrollment to the county level
  and derives the Medicaid-to-Medicare ratio and an access category. Its
  input can be assembled from
  [`mysterycall_get_cms_enrollment()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_cms_enrollment.md)
  (single-county CMS reader).

Both operate on data frames you supply (an NPPES/roster extract, a CMS
enrollment file), so they carry no large bundled data and stay
reproducible.
