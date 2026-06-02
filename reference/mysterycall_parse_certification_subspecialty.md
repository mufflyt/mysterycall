# Map an ABOHNS certification_type string to a subspecialty label

Parses the ABOHNS `certification_type` field (e.g.
`"Otolaryngology - Head & Neck Surgery + Neurotology + Sleep Medicine"`)
and returns the most-specific subspecialty label. Priority order:
Neurotology \> Pediatric Otolaryngology \> Sleep Medicine \> Facial
Plastic Surgery. When none match, returns `default`.

## Usage

``` r
mysterycall_parse_certification_subspecialty(
  cert_type,
  default = NA_character_
)
```

## Arguments

- cert_type:

  Character vector of ABOHNS `certification_type` strings, one element
  per provider. Values like
  `"Otolaryngology - Head & Neck Surgery + Neurotology"` are parsed for
  subspecialty patterns. Pass `NA` for providers without ABOHNS records;
  they will receive `default`.

- default:

  Character scalar returned when no subspecialty pattern is detected
  (including `NA` or blank input). Default `NA_character_`.

## Value

Character vector the same length as `cert_type`. Values are one of
`"Otology/Neurotology"`, `"Pediatric Otolaryngology"`,
`"Sleep Medicine"`, `"Facial Plastic Surgery"`, or `default`.

## Authoritative subspecialty source

This function is the **only authorised way** to derive subspecialty
labels in the mysterycall workflow. NPPES (`taxonomies_desc`) and DAC
(Data at CMS) taxonomy codes reflect broad specialty groupings and must
not be used to assign subspecialty. Pass the output of this function as
`secondary_col` in
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md)
to correctly populate subspecialty via board certification evidence
only.

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
[`mysterycall_physician_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physician_age.md),
[`mysterycall_recode_credentials()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_recode_credentials.md),
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md),
[`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md)

## Examples

``` r
cert <- c(
  "Otolaryngology - Head & Neck Surgery + Neurotology",
  "Otolaryngology + Pediatric Otolaryngology + Sleep Medicine",
  "Otolaryngology - Head & Neck Surgery",
  NA
)
mysterycall_parse_certification_subspecialty(cert)
#> [1] "Otology/Neurotology"      "Pediatric Otolaryngology"
#> [3] NA                         NA                        
```
