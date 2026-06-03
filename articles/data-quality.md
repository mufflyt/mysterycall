# Data Quality: Phone Validation, Name Parsing, and Safe Joins

## Overview

Mystery-caller studies assemble provider rosters from several upstream
sources (NPPES, CMS Care Compare, internal call logs) that each carry
their own formatting quirks. Three categories of data-quality problems
arise repeatedly:

1.  **Phone numbers** — formatting noise (`(303) 555-1234`,
    `303.555.1234`, `+13035551234`) and area codes that don’t match the
    provider’s reported state.
2.  **Physician names** — a single free-text name field that must be
    split into first / middle / last / suffix components before being
    used in call scripts or de-duplication logic.
3.  **Table joins** — silent row multiplication when the right-hand
    table is not unique on the join key, or silent data loss when a
    large fraction of left-hand rows find no match on the right.

This vignette walks through the `mysterycall` helpers that address each
problem. All code runs without any API keys using only built-in package
data.

------------------------------------------------------------------------

## 1. Phone validation (`mysterycall_validate_phone`)

### Background

The North American Numbering Plan (NANP) defines the structure of US
phone numbers:

    NPA-NXX-XXXX

where **NPA** (Numbering Plan Area, the “area code”) must have a first
digit of 2–9, and **NXX** (the central-office code) must also have a
first digit of 2–9 and must not be an N11 service code (211, 311, …,
911).

[`mysterycall_validate_phone()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_phone.md)
strips formatting, enforces those structural rules, and — optionally —
checks that the area code belongs to the provider’s reported practice
state using the bundled `inst/extdata/nanp_area_codes_us.csv` lookup
table.

### Basic usage

``` r

# A well-formed Colorado number
mysterycall_validate_phone("(303) 555-1234")
#>   phone_e164_valid phone_npa phone_state_from_npa phone_area_code_matches_state
#> 1             TRUE       303                   CO                            NA
#>   phone_validity_flag
#> 1               valid

# Missing number
mysterycall_validate_phone(NA_character_)
#>   phone_e164_valid phone_npa phone_state_from_npa phone_area_code_matches_state
#> 1            FALSE      <NA>                 <NA>                            NA
#>   phone_validity_flag
#> 1             missing

# Non-NANP format (too few digits)
mysterycall_validate_phone("555-1234")
#>   phone_e164_valid phone_npa phone_state_from_npa phone_area_code_matches_state
#> 1            FALSE      <NA>                 <NA>                            NA
#>   phone_validity_flag
#> 1      invalid_format
```

The function always returns a data frame with five columns:

| Column | Type | Meaning |
|----|----|----|
| `phone_e164_valid` | logical | `TRUE` if the number passes all NANP rules |
| `phone_npa` | character | The three-digit area code, or `NA` |
| `phone_state_from_npa` | character | State associated with the NPA in the lookup table |
| `phone_area_code_matches_state` | logical | `TRUE` if NPA ↔︎ `practice_state` agree; `NA` if no state was supplied |
| `phone_validity_flag` | character | One of the five validity codes below |

| Flag | Meaning |
|----|----|
| `valid` | Passes all NANP rules; area code matches practice state (if supplied) |
| `missing` | Input is `NA` or empty |
| `invalid_format` | Cannot be reduced to a 10-digit NANP number |
| `unknown_area_code` | Digits are structurally valid but NPA is not in the lookup table |
| `area_code_state_mismatch` | NPA is valid but registered to a different state |

### State-mismatch detection

Pass the provider’s two-letter state abbreviation to catch numbers whose
area code is registered to a different state:

``` r

# Colorado provider with a New York area code
mysterycall_validate_phone("(212) 555-0199", practice_state = "CO")
#>   phone_e164_valid phone_npa phone_state_from_npa phone_area_code_matches_state
#> 1            FALSE       212                   NY                         FALSE
#>        phone_validity_flag
#> 1 area_code_state_mismatch
```

### Validating a full roster column

``` r

roster <- data.frame(
  npi            = c("1234567890", "0987654321", "1111111111"),
  phone          = c("(720) 555-0101", "999-0000", "(303) 867-5309"),
  practice_state = c("CO",            "CO",        "CO"),
  stringsAsFactors = FALSE
)

# vectorised: one call per row, returns a data frame
phone_results <- do.call(rbind, Map(
  mysterycall_validate_phone,
  phone_str      = roster$phone,
  practice_state = roster$practice_state
))

cbind(roster["npi"], phone_results[, c("phone_e164_valid", "phone_validity_flag")])
#>                       npi phone_e164_valid phone_validity_flag
#> (720) 555-0101 1234567890             TRUE               valid
#> 999-0000       0987654321            FALSE      invalid_format
#> (303) 867-5309 1111111111             TRUE               valid
```

The NANP lookup table is lazy-loaded once per session and cached
internally, so repeated calls in a loop incur no extra I/O.

------------------------------------------------------------------------

## 2. Name parsing (`mysterycall_parse_physician_name`)

### Background

Provider names arrive from NPPES and call logs in several formats:

- `"Jane A. Smith, MD"` — credential after name
- `"Smith, Jane A."` — last-first comma format (two-part)
- `"Smith, Jane, Jr."` — last-first-suffix three-part comma format
- `"María de la Cruz"` — name particle in the last name
- `"Robert Smith DO"` — `DO` credential that must not become `last_name`
- `"Linda Do"` — Vietnamese surname `Do` that must **not** be treated as
  a credential

[`mysterycall_parse_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_physician_name.md)
wraps
[`humaniformat::parse_names()`](https://rdrr.io/pkg/humaniformat/man/parse_names.html)
and applies deterministic post-processing rules for these edge cases,
then assigns a confidence level (`high` / `medium` / `low`) so
downstream consumers can flag low-confidence parses for manual review.

### Single name

``` r

mysterycall_parse_physician_name("Smith, Jane, Jr.")
#> # A tibble: 1 × 7
#>   first_name middle_name last_name suffix title parse_confidence parse_warnings
#>   <chr>      <chr>       <chr>     <chr>  <chr> <chr>            <chr>         
#> 1 Jane       NA          Smith     Jr.    NA    high             NA
```

### Vectorised over a column

``` r

raw_names <- c(
  "Maria de la Cruz",
  "Smith, John, Jr.",
  "Robert Smith DO",
  "Linda Do",
  NA_character_
)

parsed <- mysterycall_parse_physician_name(raw_names)
parsed[, c("first_name", "last_name", "suffix", "parse_confidence", "parse_warnings")]
#> # A tibble: 5 × 5
#>   first_name last_name  suffix parse_confidence parse_warnings
#>   <chr>      <chr>      <chr>  <chr>            <chr>         
#> 1 Maria      de la Cruz NA     high             NA            
#> 2 John       Smith      Jr.    high             NA            
#> 3 Robert     Smith      DO     high             NA            
#> 4 Linda      Do         NA     high             NA            
#> 5 NA         NA         NA     low              parsing_failed
```

### Using the built-in `physicians` dataset

``` r

# Parse the 4,659 physician names from the bundled roster
parsed_physicians <- mysterycall_parse_physician_name(
  mysterycall::physicians$name
)

# Confidence breakdown
table(parsed_physicians$parse_confidence)
#> 
#>   high medium 
#>   4656      3
```

### Validating parsed output

After parsing a full roster, call
[`mysterycall_validate_parsed_names()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_parsed_names.md)
to flag structural quality problems in each row:

``` r

validated <- mysterycall_validate_parsed_names(parsed)

# Overview of quality issues
table(validated$quality_issue, useNA = "ifany")
#> 
#> low_confidence_parse                 <NA> 
#>                    1                    4

# Rows that are not valid (missing first or last name)
validated[!validated$is_valid, c("first_name", "last_name",
                                  "parse_confidence", "quality_issue")]
#> # A tibble: 1 × 4
#>   first_name last_name parse_confidence quality_issue       
#>   <chr>      <chr>     <chr>            <chr>               
#> 1 NA         NA        low              low_confidence_parse
```

Rows with `parse_confidence == "low"` or a non-`NA` `quality_issue`
should be reviewed manually before use in call scripts.

### Formatting names for output

Once parsed, use
[`mysterycall_format_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_physician_name.md)
to render names in a consistent house style:

``` r

mysterycall_format_physician_name(
  first_name     = "Jane",
  last_name      = "Smith",
  middle_name    = "A.",
  suffix         = "MD",
  format         = "last_first",
  include_suffix = TRUE
)
#> [1] "Smith, Jane A., MD"

# Vectorised
mysterycall_format_physician_name(
  first_name  = c("John",  "Maria"),
  last_name   = c("Smith", "Cruz"),
  suffix      = c("MD",    NA),
  format      = "first_last"
)
#> [1] "John Smith, MD" "Maria Cruz"
```

### Built-in edge-case test suite

The function ships with 13 known-difficult cases (DO credential,
Vietnamese surnames, three-part comma, hyphenated names) that you can
run at any time to verify parser behavior after an upgrade:

``` r

tbl <- mysterycall_test_name_parser()
#> 
#> === mysterycall name parser -- edge-case suite ===
#> 
#> [1] 'John Smith'
#>     first='John'  last='Smith'  middle=''  suffix=''
#>     confidence=high  [OK]
#> 
#> [2] 'Mary Johnson, MD'
#>     first='Mary'  last='Johnson'  middle=''  suffix='MD'
#>     confidence=high  [OK]
#> 
#> [3] 'Robert Brown, Jr.'
#>     first='Robert'  last='Brown'  middle=''  suffix='Jr.'
#>     confidence=high  [OK]
#> 
#> [4] 'Robert Smith DO'
#>     first='Robert'  last='Smith'  middle=''  suffix='DO'
#>     confidence=high  [OK]
#> 
#> [5] 'Linda Do'
#>     first='Linda'  last='Do'  middle=''  suffix=''
#>     confidence=high  [OK]
#> 
#> [6] 'Smith, John, Jr.'
#>     first='John'  last='Smith'  middle=''  suffix='Jr.'
#>     confidence=high  [OK]
#> 
#> [7] 'Williams, Mary, Sr.'
#>     first='Mary'  last='Williams'  middle=''  suffix='Sr.'
#>     confidence=high  [OK]
#> 
#> [8] 'Maria de la Cruz'
#>     first='Maria'  last='de la Cruz'  middle=''  suffix=''
#>     confidence=high  [OK]
#> 
#> [9] 'Jan van der Berg'
#>     first='Jan'  last='van der Berg'  middle=''  suffix=''
#>     confidence=high  [OK]
#> 
#> [10] 'Jean-Anthony P. Do'
#>     first='Jean-Anthony'  last='Do'  middle='P.'  suffix=''
#>     confidence=high  [OK]
#> 
#> [11] 'Mary-Ann O'Connor, MD, PhD'
#>     first='Mary-Ann'  last='O'Connor'  middle=''  suffix='MD, PhD'
#>     confidence=high  [OK]
#> 
#> [12] 'Madonna'
#>     first='Madonna'  last=''  middle=''  suffix=''
#>     confidence=medium  [FAIL]
#> 
#> [13] 'Prince'
#>     first='Prince'  last=''  middle=''  suffix=''
#>     confidence=medium  [FAIL]
#> 
#> --- 11/13 valid  |  11/13 high-confidence  |  0 quality issues ---
cat(sprintf("%d / %d high-confidence valid parses\n",
            sum(tbl$is_valid & tbl$parse_confidence == "high"),
            nrow(tbl)))
#> 11 / 13 high-confidence valid parses
```

------------------------------------------------------------------------

## 3. Safe joins (`mysterycall_safe_left_join` and friends)

### The problem with silent join failures

A plain
[`dplyr::left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
will silently:

- **Multiply rows** if the right-hand key is not unique (a many-to-one
  match becomes many-to-many).
- **Drop rows** if the join key types don’t match (e.g., integer
  vs. character NPI), causing every row to land in the unmatched group.
- **Return no warning** when 40 % of left-hand NPIs have no match on the
  right.

The `mysterycall_safe_*_join()` family wraps `dplyr` joins with pre- and
post-join assertions that make these failures loud.

### `mysterycall_safe_left_join`

``` r

calls <- data.frame(
  npi  = c("1111111111", "2222222222", "3333333333"),
  date = as.Date(c("2025-01-10", "2025-01-11", "2025-01-12")),
  stringsAsFactors = FALSE
)

demographics <- data.frame(
  npi    = c("1111111111", "2222222222"),
  gender = c("Female", "Male"),
  stringsAsFactors = FALSE
)

# 2 of 3 left rows match → coverage = 66.7 % < 95 % threshold → error
tryCatch(
  suppressMessages(mysterycall_safe_left_join(
    left         = calls,
    right        = demographics,
    by           = "npi",
    label_left   = "call_log",
    label_right  = "demographics",
    min_coverage = 0.95
  )),
  error = function(e) message("Caught: ", conditionMessage(e))
)
#> Caught: Join coverage 66.7% below 95.0% threshold -- lost 1 rows. call_log -> demographics on npi.

# Lower threshold to match the actual coverage
result <- suppressMessages(mysterycall_safe_left_join(
  left         = calls,
  right        = demographics,
  by           = "npi",
  label_left   = "call_log",
  label_right  = "demographics",
  min_coverage = 0.60
))
result
#>          npi       date gender
#> 1 1111111111 2025-01-10 Female
#> 2 2222222222 2025-01-11   Male
#> 3 3333333333 2025-01-12   <NA>
```

### Key-type harmonization

If one table stores NPI as integer and the other as character, a plain
join silently returns zero matches. The safe join coerces both sides to
character:

``` r

left2  <- data.frame(npi = 1111111111L, stringsAsFactors = FALSE)
right2 <- data.frame(npi = "1111111111", x = 42L, stringsAsFactors = FALSE)

suppressMessages(mysterycall_safe_left_join(
  left2, right2, by = "npi",
  label_left  = "left",
  label_right = "right",
  min_coverage = 0
))
#>          npi  x
#> 1 1111111111 42
```

### Asserting uniqueness before a join

[`mysterycall_assert_unique_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assert_unique_keys.md)
lets you verify that a table is unique on one or more columns before
passing it to any join:

``` r

dupes <- data.frame(
  npi    = c("1111111111", "1111111111"),
  source = c("NPPES", "CMS"),
  stringsAsFactors = FALSE
)

# Error: found 1 duplicate group
tryCatch(
  mysterycall_assert_unique_keys(dupes, key_cols = "npi", label = "demographics"),
  error = function(e) message("Caught: ", conditionMessage(e))
)
#> Caught: demographics: expected unique key(s) [npi] but found 1 duplicate group(s) affecting 2 row(s). Samples: npi = 1111111111

# Pass dedupe = TRUE to drop duplicates instead:
clean <- suppressMessages(
  mysterycall_assert_unique_keys(dupes, key_cols = "npi",
                                  label = "demographics", dedupe = TRUE)
)
nrow(clean)
#> [1] 1
```

### Inner, semi, and anti joins

``` r

# Inner join — only matched rows; defaults to min_coverage = 0.90
result_inner <- suppressMessages(mysterycall_safe_inner_join(
  left        = calls,
  right       = demographics,
  by          = "npi",
  label_left  = "call_log",
  label_right = "demographics",
  min_coverage = 0.60
))
nrow(result_inner)   # 2 rows: only matched NPIs
#> [1] 2

# Semi join — keep left rows that match; no right columns added
matched_calls <- suppressMessages(mysterycall_safe_semi_join(
  left        = calls,
  right       = demographics,
  by          = "npi",
  label_left  = "call_log",
  label_right = "demographics",
  min_coverage = 0.60
))
matched_calls   # 2 rows, same columns as calls
#>          npi       date
#> 1 1111111111 2025-01-10
#> 2 2222222222 2025-01-11

# Anti join — keep left rows with NO match
unmatched_calls <- suppressMessages(mysterycall_safe_anti_join(
  left        = calls,
  right       = demographics,
  by          = "npi",
  label_left  = "call_log",
  label_right = "demographics"
))
unmatched_calls   # 1 row: NPI 3333333333
#>          npi       date
#> 1 3333333333 2025-01-12
```

------------------------------------------------------------------------

## 4. Putting it together: a complete roster QA pipeline

The built-in `physicians` dataset contains 4,659 OBGYN subspecialists
with NPI and name. The block below demonstrates the full data-quality
pipeline without any API calls.

``` r

library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

# ── 1. Parse physician names ──────────────────────────────────────────────────
roster <- mysterycall::physicians |>
  select(NPI, name, subspecialty)

parsed_names <- mysterycall_parse_physician_name(roster$name)
roster <- bind_cols(roster, parsed_names)

low_conf <- filter(roster, parse_confidence == "low")
message(sprintf("%d name(s) flagged as low-confidence (%.1f%%)",
                nrow(low_conf), 100 * nrow(low_conf) / nrow(roster)))
#> 0 name(s) flagged as low-confidence (0.0%)

# ── 2. Validate parsed names ──────────────────────────────────────────────────
validated_names <- mysterycall_validate_parsed_names(parsed_names)
issues <- filter(validated_names, !is.na(quality_issue))
message(sprintf("%d name quality issue(s) detected:", nrow(issues)))
#> 21 name quality issue(s) detected:
print(table(issues$quality_issue))
#> 
#> last_name_suspiciously_short      name_particle_in_middle 
#>                           19                            2

# ── 3. Illustrate a safe join with a synthetic demographics sidecar ───────────
# In a real study this would be CMS Care Compare or similar
demographics_sidecar <- data.frame(
  NPI    = roster$NPI[1:4000],       # 4,000 of 4,659 have demographics
  gender = sample(c("Female", "Male", "Unknown"),
                  4000, replace = TRUE, prob = c(.7, .28, .02)),
  stringsAsFactors = FALSE
)

roster_enriched <- suppressMessages(
  mysterycall_safe_left_join(
    left         = roster,
    right        = demographics_sidecar,
    by           = "NPI",
    label_left   = "physicians",
    label_right  = "demographics_sidecar",
    min_coverage = 0.85   # expect ≥ 85 % match rate
  )
)

# Coverage summary
cat(sprintf(
  "Roster rows: %d  |  Enriched rows: %d  |  Coverage: %.1f%%\n",
  nrow(roster), nrow(roster_enriched),
  100 * mean(!is.na(roster_enriched$gender))
))
#> Roster rows: 4659  |  Enriched rows: 4659  |  Coverage: 85.9%
```
