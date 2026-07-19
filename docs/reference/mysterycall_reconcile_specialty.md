# Three-tier specialty reconciliation with audit columns

Applies a three-tier decision rule:

1.  **Tier 1 (high)**: primary column is non-missing and non-default -
    use it as-is.

2.  **Tier 2 (medium)**: primary is missing or the default label, but
    the secondary column is informative - adopt the secondary value.

3.  **Tier 3 (low)**: both sources are uninformative - set specialty to
    `default`.

Two audit columns are appended: one recording which source was used and
one recording the confidence tier.

## Usage

``` r
mysterycall_reconcile_specialty(
  data,
  primary_col,
  secondary_col = NULL,
  default = "General",
  source_col = "specialty_source",
  confidence_col = "specialty_confidence"
)
```

## Arguments

- data:

  A data frame.

- primary_col:

  Character scalar. Column containing the broad specialty label from a
  registry source such as NPPES or DAC (e.g.
  `"Otolaryngology - Head & Neck Surgery"`). Do not use this column to
  carry subspecialty values; subspecialty must come via `secondary_col`
  from board certification data only.

- secondary_col:

  Optional character scalar. Column containing a subspecialty label
  derived **exclusively from board certification data** (e.g. ABOHNS
  `certification_type` parsed by
  [`mysterycall_parse_certification_subspecialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_certification_subspecialty.md)).
  DAC and NPPES columns must not be passed here for subspecialty
  purposes.

- default:

  Character scalar. The "uninformative" label that triggers tier-2 or
  tier-3 logic. Default `"General"`.

- source_col:

  Character scalar. Name of the new audit column recording which source
  was used. Default `"specialty_source"`.

- confidence_col:

  Character scalar. Name of the new audit column recording the tier
  (`"high"`, `"medium"`, or `"low"`). Default `"specialty_confidence"`.

## Value

The input `data` frame with the same row count, where:

- `primary_col` is updated: tier-2 rows receive the `secondary_col`
  value.

- A new character column (named by `source_col`) records which source
  was used (`"primary"`, `"secondary"`, or `"default"`).

- A new character column (named by `confidence_col`) records the
  resolution tier (`"high"`, `"medium"`, or `"low"`).

## Subspecialty source rule

**Subspecialty values must only come from board certification data.**
NPPES (`taxonomies_desc`) and DAC (Data at CMS) report broad specialty
taxonomy codes that do not reliably distinguish subspecialties such as
Neurotology or Pediatric Otolaryngology. Always supply board
certification data (e.g. ABOHNS) in `secondary_col` when subspecialty
resolution is needed. Passing an NPPES or DAC column as `secondary_col`
for subspecialty will produce incorrect Tier-2 assignments that appear
valid but are not. Use
[`mysterycall_parse_certification_subspecialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_certification_subspecialty.md)
to derive a subspecialty column from the ABOHNS `certification_type`
field before calling this function.

## See also

Other provider characteristics:
[`mysterycall_academic_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_academic_patterns.md),
[`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md),
[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md),
[`mysterycall_classify_medical_school()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_medical_school.md),
[`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md),
[`mysterycall_classify_ruca()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_ruca.md),
[`mysterycall_collapse_rare()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_collapse_rare.md),
[`mysterycall_extract_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_extract_physician_name.md),
[`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md),
[`mysterycall_government_patterns()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_government_patterns.md),
[`mysterycall_impute_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_impute_age.md),
[`mysterycall_most_common_gender()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_most_common_gender.md),
[`mysterycall_parse_certification_subspecialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_certification_subspecialty.md),
[`mysterycall_physician_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physician_age.md),
[`mysterycall_recode_credentials()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_recode_credentials.md),
[`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md)

## Examples

``` r
df <- data.frame(
  specialty_npi   = c("Otolaryngology", "General", NA, "Rhinology"),
  specialty_abohns = c(NA, "Laryngology", "Rhinology", "General")
)
mysterycall_reconcile_specialty(
  df,
  primary_col   = "specialty_npi",
  secondary_col = "specialty_abohns"
)
#>    specialty_npi specialty_abohns specialty_source specialty_confidence
#> 1 Otolaryngology             <NA>    specialty_npi                 high
#> 2    Laryngology      Laryngology specialty_abohns               medium
#> 3      Rhinology        Rhinology specialty_abohns               medium
#> 4      Rhinology          General    specialty_npi                 high
```
