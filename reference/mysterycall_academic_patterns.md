# Return the built-in academic keyword patterns

Convenience accessor so callers can extend rather than replace the
default list:
`academic_patterns = c(mysterycall_academic_patterns(), "my term")`.

## Usage

``` r
mysterycall_academic_patterns()
```

## Value

Character vector of lower-case regex patterns used to identify academic
medical centers and teaching hospitals.

## See also

[`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md)

Other provider characteristics:
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
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md),
[`mysterycall_reorder_by_freq()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reorder_by_freq.md)

## Examples

``` r
# View all built-in academic patterns
mysterycall_academic_patterns()
#>  [1] "university"             "medical center"         "med center"            
#>  [4] "medical college"        "school of medicine"     "teaching hospital"     
#>  [7] "academic"               "children's hospital"    "childrens hospital"    
#> [10] "mayo clinic"            "cleveland clinic"       "johns hopkins"         
#> [13] "memorial sloan"         "md anderson"            "duke"                  
#> [16] "stanford"               "ucsf"                   "ucla"                  
#> [19] "usc"                    "nyu"                    "columbia"              
#> [22] "harvard"                "yale"                   "penn"                  
#> [25] "cornell"                "upmc"                   "vanderbilt"            
#> [28] "emory"                  "baylor"                 "ohio state"            
#> [31] "michigan medicine"      "northwestern"           "mount sinai"           
#> [34] "brigham"                "jefferson"              "health sciences center"
#> [37] "cancer center"          "cancer ctr"             "sch of med"            
#> [40] "dept of oto"            "infirmary"              "health system"         
#> [43] "henry ford"             "uab"                    "suny"                  
#> [46] "oto dept"              

# Extend with a custom term
my_patterns <- c(mysterycall_academic_patterns(), "regional medical center")
mysterycall_classify_practice_setting("Regional Medical Center", academic_patterns = my_patterns)
#> [1] "Academic"
```
