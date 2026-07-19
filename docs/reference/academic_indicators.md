# Academic Practice Indicators for Institution Classification

High-confidence indicators for distinguishing academic vs. non-academic
practice settings. Includes pattern-based name matching, known
institution lists, and a weighted scoring system across multiple
evidence tiers.

## Value

No return value. Documentation topic grouping related indicator
constants and helpers; see each function or data object's own help page.

## Details

Evidence-based indicators with calibrated confidence scores:

- ACGME residency/fellowship programs (0.98-0.99)

- COTH (Council of Teaching Hospitals) membership (0.95)

- Medical school affiliations (0.97)

- NIH CTSA awards (0.99)

- NCI cancer center designations (0.98)

- Medicare GME payments (0.95)

## Examples

``` r
# Topic group; see individual constant/function help pages for examples.
head(KNOWN_ACADEMIC_INSTITUTIONS)
#> [1] "JOHNS HOPKINS"         "MAYO CLINIC"           "CLEVELAND CLINIC"     
#> [4] "MASSACHUSETTS GENERAL" "BRIGHAM"               "STANFORD"             
```
