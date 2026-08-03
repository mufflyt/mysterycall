# Searching the NPI Database Starting with Taxonomy Codes

## Overview

The
[`mysterycall::taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)
data and `mysterycall_search_taxonomy` function in the R package offers
a convenient and efficient way to query the NPI Database for healthcare
providers based on their taxonomy descriptions. This vignette provides a
comprehensive guide on how to effectively utilize this function,
explores its various capabilities, and offers illustrative use cases.

### Installation

Before you can harness the power of the `mysterycall_search_taxonomy`
function, it is essential to ensure that you have the `mysterycall`
package installed. You can effortlessly install it using the following
command:

## Example Usage

### Understanding Taxonomy Descriptions

Taxonomy descriptions, derived from the National Physician Taxonomy
Codes and the NPPES (National Plan and Provider Enumeration System)
database, are fundamental components of the United States healthcare
system. They play a pivotal role in the identification and
categorization of healthcare providers for various purposes, including
billing, insurance, and regulatory compliance.

In particular, the
[`mysterycall::taxonomy`](https://mufflyt.github.io/mysterycall/reference/taxonomy.md)
data frame contains NUCC taxonomy codes utilized in NPPES data files.
Each Taxonomy Code comprises a unique ten-character identifier that aids
in the identification of healthcare provider types and their areas of
expertise. Notably, the OBGYN taxonomy codes are sourced from Version
23.1 dated July 1, 2023.

Taxonomy codes can be obtained from the National Uniform Claim Committee
(NUCC) website here. You can employ these codes to pinpoint specific
taxonomy descriptions for your search. For instance, if you are
interested in finding taxonomy codes that include the string `"GYN"` you
can use this code to facilitate your search in the
`mysterycall_search_taxonomy` function.

``` r

obgyn_taxonomy <- mysterycall::taxonomy %>%
  dplyr::filter(stringr::str_detect(`Classification`, stringr::fixed("GYN", ignore_case = TRUE))) %>%
  dplyr::select(Code, Specialization)
```

``` r
Code       Specialization                                   
   <chr>      <chr>                                            
 1 207V00000X NA                                               
 2 207VC0300X Complex Family Planning                          
 3 207VC0200X Critical Care Medicine                           
 4 207VF0040X Female Pelvic Medicine and Reconstructive Surgery
 5 207VX0201X Gynecologic Oncology                             
 6 207VG0400X Gynecology                                       
 7 207VH0002X Hospice and Palliative Medicine                  
 8 207VM0101X Maternal & Fetal Medicine                        
 9 207VB0002X Obesity Medicine                                 
10 207VX0000X Obstetrics                                       
11 207VE0102X Reproductive Endocrinology 
```

### Search by Taxonomy Description

[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
queries the NPI Registry for individual providers whose self-reported
taxonomy description matches your search string. It is most useful for:

- Building a complete national roster of a subspecialty (e.g.,
  Gynecologic Oncology) when you don’t have existing name lists.
- Filling in board-eligible providers who may not appear in
  board-certification databases.
- Verifying workforce counts from external databases against NPPES
  enrollment.

All search results include a National Provider Identifier (NPI), making
them joinable to CMS Care Compare data and other federal datasets.

### Example Usage

Search for providers in one or more taxonomy descriptions:

``` r

taxonomy_descriptions <- c(
  "Hospice and Palliative Medicine",
  "Gynecologic Oncology"
)

data <- mysterycall_search_taxonomy(taxonomy_to_search = taxonomy_descriptions)
```

Inspect the distribution of results:

``` r

# Providers by gender and state
dplyr::count(data, basic_gender, addresses_state, sort = TRUE)

# Providers by taxonomy description
dplyr::count(data, taxonomies_desc, sort = TRUE)

# Check for multiple matches per NPI (cross-state enrollment)
dplyr::count(data, npi, sort = TRUE) |> dplyr::filter(n > 1)
```

### Cleaning and standardizing the result

The raw output from
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
uses NPPES column names (`basic_*`, `addresses_*`). The snippet below
renames the key columns to match the names expected by
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md)
and other downstream functions, then derives a short subspecialty code.

``` r

# OBGYN subspecialty taxonomy descriptions and their short codes
obgyn_subspecialties <- c(
  "Obstetrics & Gynecology, Female Pelvic Medicine and Reconstructive Surgery" = "FPM",
  "Obstetrics & Gynecology, Gynecologic Oncology"                              = "ONC",
  "Obstetrics & Gynecology, Maternal & Fetal Medicine"                         = "MFM",
  "Obstetrics & Gynecology, Reproductive Endocrinology"                        = "REI"
)

roster_clean <- data |>
  dplyr::distinct(npi, .keep_all = TRUE) |>

  # Keep only OBGYN subspecialist rows
  dplyr::filter(taxonomies_desc %in% names(obgyn_subspecialties)) |>

  # Standardize fields
  dplyr::mutate(
    # 5-digit ZIP only
    zip5               = stringr::str_sub(addresses_postal_code, 1, 5),
    # First initial of middle name only
    basic_middle_name  = stringr::str_sub(basic_middle_name, 1, 1),
    # Remove punctuation from name fields
    dplyr::across(
      c(basic_first_name, basic_last_name, basic_middle_name),
      ~ stringr::str_remove_all(.x, "[[:punct:]]")
    ),
    # Parse enumeration year
    enumeration_year   = as.integer(
      format(as.Date(basic_enumeration_date), "%Y")
    ),
    # Expand single-letter gender code
    gender = dplyr::case_match(
      basic_gender,
      "F" ~ "Female",
      "M" ~ "Male",
      .default = "Unknown"
    ),
    # Short subspecialty code via named-vector lookup
    subspecialty = obgyn_subspecialties[taxonomies_desc]
  ) |>

  # Rename to common schema
  dplyr::rename(
    first_name = basic_first_name,
    last_name  = basic_last_name,
    middle_name = basic_middle_name,
    city       = addresses_city,
    state      = addresses_state,
    phone      = addresses_telephone_number
  ) |>

  dplyr::select(npi, first_name, middle_name, last_name,
                gender, subspecialty, city, state, zip5,
                phone, enumeration_year, taxonomies_desc)
```

### Validating phones after roster construction

Once the roster is clean, validate the phone numbers against the
provider’s reported state using the NANP helper:

``` r

phone_checks <- do.call(rbind, Map(
  mysterycall_validate_phone,
  phone_str      = roster_clean$phone,
  practice_state = roster_clean$state
))

table(phone_checks$validity_flag)
#> valid                  missing   invalid_format
#> 412                    18            7
```

### Function reference

| Parameter | Type | Description |
|----|----|----|
| `taxonomy_to_search` | character vector | One or more NUCC taxonomy description strings |
| `states` | character vector | Optional 2-letter state codes to restrict results |
| `write_snapshot` | logical | Save raw API responses as `.rds` files for offline replay |
| `notify` | logical | Emit progress messages during the search |

The function returns a data frame with one row per unique
NPI–taxonomy–address combination, deduplicated on NPI before returning.

## Conclusion

[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
is the taxonomy-first entry point for roster creation. Pair it with
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)
(name-first) to cross-validate provider counts, and with
[`mysterycall_validate_phone()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_phone.md)
and
[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md)
to build a fully audited enrichment pipeline.

## Features and bugs

If you have ideas for other features that would make taxonomy search
easier, or find a bug, report it at the package issue tracker.
