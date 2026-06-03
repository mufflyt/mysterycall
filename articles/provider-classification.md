# Provider Classification and Demographic Enrichment

``` r

library(mysterycall)
library(dplyr)
```

------------------------------------------------------------------------

## 1. Overview

A mystery-caller study begins with a **provider roster**: a list of
physicians whose appointment-scheduling behavior will be tested. Before
any statistical model can be estimated, that roster must be enriched
with demographic, geographic, and practice-setting variables. Raw data
from the National Provider Identifier (NPI) registry and related sources
are not analysis-ready on their own — field names are cryptic,
geographic codes are numeric, and key variables like physician age and
gender are often missing or incomplete.

This vignette walks through every enrichment step implemented in
`mysterycall`, from the initial NPI search through to a Table 1-ready
data frame.

### The enrichment pipeline

    Raw NPPES data (CSV / API)
            |
            v
    [1] validate_and_remove_invalid_npi()   -- drop deactivated or duplicate NPIs
            |
            v
    [2] mysterycall_classify_practice_setting()   -- Academic / Government / Private
            |
            v
    [3] Join USDA RUCA crosswalk                  -- attach ruca_code to each ZIP
            |
            v
    [4] mysterycall_classify_ruca()               -- Urban / Suburban / Rural
            |
            v
    [5] mysterycall_assign_region()               -- Census / ACOG / AAO-HNS region
            |
            v
    [6] mysterycall_classify_medical_school()     -- US_MD / US_DO / CAN_MD / IMG
            |
            v
    [7] mysterycall_impute_age()                  -- estimated age from grad year
        mysterycall_age_category()                -- decade brackets for Table 1
            |
            v
    [8] mysterycall_genderize()                   -- API gender backfill for ~5% missing
            |
            v
    [9] mysterycall_prepare_table1_vars()         -- standardize and combine all vars
            |
            v
    [10] Analysis-ready data frame

Each step is independent enough to be run on its own, but the order
matters: you cannot classify RUCA codes until you have joined the
crosswalk, and you cannot call
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md)
until you have raw gender values to standardize.

**Target audience:** Physician researchers who will execute this code
themselves. No prior experience with the NPPES API or USDA geographic
data systems is assumed.

------------------------------------------------------------------------

## 2. Practice setting classification

### What is practice setting?

In mystery-caller research, **practice setting** is one of the strongest
predictors of appointment availability and wait time. Academic medical
centers have complex scheduling systems, residents who share patient
loads, and often longer wait times. Government facilities (VA, military)
operate under federal mandates and may have different referral patterns.
Private practices behave differently again.

The function
[`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md)
assigns each provider to one of three categories: `"Academic"`,
`"Government"`, or `"Private Practice"`. It also returns `"Unknown"` (or
your custom `na_label`) when the input is `NA` or blank.

### The three-tier hierarchy

Classification is performed in a fixed priority order:

    Government  (checked first)
        |
        v
    Academic    (checked second)
        |
        v
    Private Practice  (default when no pattern matches)

**Government is always checked first.** This is a deliberate design
decision. Consider “VA Medical Center Denver”: the substring
`"medical center"` appears in the academic pattern list because most
facilities with that phrase in their name are teaching hospitals. But
the VA is a federal government facility, not an academic one. Checking
government patterns first ensures that VA and military facilities are
never mis-classified as Academic, regardless of what other words appear
in their name.

If a name matches no government or academic pattern but is non-empty, it
is classified as `"Private Practice"`. This is the correct default for
the vast majority of physician names in NPPES, which tend to be short
strings like `"Smith ENT Associates LLC"` that contain no institutional
keywords.

### Built-in patterns

`mysterycall` ships with two accessor functions that let you inspect —
and extend — the built-in keyword lists without having to look at the
source code.

``` r

# View all built-in academic patterns (40+ keywords)
mysterycall_academic_patterns()
```

The built-in academic list includes broad institutional keywords like
`"university"`, `"medical center"`, `"teaching hospital"`, and
`"health sciences center"`, as well as named institutions that are
academically affiliated even when the word “university” does not appear
in their name: `"mayo clinic"`, `"cleveland clinic"`, `"johns hopkins"`,
`"memorial sloan"`, `"md anderson"`, and flagship programs at `"duke"`,
`"stanford"`, `"ucsf"`, `"yale"`, `"upmc"`, `"vanderbilt"`, and dozens
more.

``` r

# View all built-in government/military patterns
mysterycall_government_patterns()
```

The government list matches `"va "` (note the trailing space, to avoid
matching “Nevada”), `"veterans"`, `"dod "`, `"department of defense"`,
`"military"`, `"army"`, `"navy"`, `"air force"`, `"walter reed"`,
`"tricare"`, `"indian health"`, `"ihs"`, `"federal"`, `"county health"`,
and `"public health"`.

All pattern matching is performed against the **lowercase** version of
the facility name, so you never need to worry about whether your data
uses title case, all caps, or mixed case. The function calls
[`tolower()`](https://rdrr.io/r/base/chartr.html) internally before any
pattern comparison.

### Extending vs replacing patterns

You have two options when the built-in lists do not cover your study
population:

**Option 1 — Extend:** Keep all built-in patterns and add your own. This
is the recommended approach for most researchers.

``` r

# Add "regional medical center" to the academic list without losing any built-ins
my_academic <- c(mysterycall_academic_patterns(), "regional medical center", "academic health")

# Add a state health department abbreviation to the government list
my_gov <- c(mysterycall_government_patterns(), "state health dept", "chc ")

roster <- roster |>
  dplyr::mutate(
    practice_setting = mysterycall_classify_practice_setting(
      org_name,
      academic_patterns   = my_academic,
      government_patterns = my_gov
    )
  )
```

**Option 2 — Replace:** Supply your own complete pattern vectors. Do
this only if your study uses a highly specialized provider population
(e.g., only correctional health facilities) where the built-in patterns
are likely to produce false positives.

``` r

# Replace academic patterns entirely with a minimal set for a corrections study
corrections_academic <- c("prison hospital", "correctional medical center")

roster <- roster |>
  dplyr::mutate(
    practice_setting = mysterycall_classify_practice_setting(
      org_name,
      academic_patterns = corrections_academic   # government_patterns uses built-in default
    )
  )
```

### Real-world classification examples

The following examples illustrate how the hierarchy resolves ambiguous
cases:

``` r

test_names <- c(
  "University of Colorado Medical Center",  # Academic: "university" and "medical center" match
  "VA Medical Center Denver",               # Government: "va " matches before "medical center" is tested
  "Denver Women's ENT Associates LLC",      # Private Practice: no academic or government match
  "Johns Hopkins Medicine",                 # Academic: "johns hopkins" in built-in list
  "Walter Reed National Military Medical Center", # Government: "walter reed" and "military" match
  "Vanderbilt-Ingram Cancer Center",        # Academic: "vanderbilt" and "cancer center" match
  "",                                       # Unknown: blank input
  NA_character_                             # Unknown: NA input
)

mysterycall_classify_practice_setting(test_names)
#> [1] "Academic"         "Government"       "Private Practice"
#> [4] "Academic"         "Government"       "Academic"
#> [7] "Unknown"          "Unknown"
```

The `na_label` parameter controls what is returned for `NA` and blank
inputs. The default is `"Unknown"`, but you may prefer `NA_character_`
for downstream [`is.na()`](https://rdrr.io/r/base/NA.html) checks:

``` r

mysterycall_classify_practice_setting(NA_character_, na_label = NA_character_)
#> [1] NA
```

### Applying to a full roster

``` r

roster <- roster |>
  dplyr::mutate(
    practice_setting = mysterycall_classify_practice_setting(org_name)
  )

# Check the distribution — expect Private Practice to dominate
table(roster$practice_setting, useNA = "always")
```

A typical otolaryngology roster might look like:

    Academic         Government   Private Practice        Unknown
          42                 8              247              3

If you see more than 5% `"Unknown"`, it usually means a significant
share of providers have `NA` in the `org_name` field. Investigate with
`filter(is.na(org_name))` before proceeding.

### Common mistake: case sensitivity

[`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md)
applies [`tolower()`](https://rdrr.io/r/base/chartr.html) to
`facility_name` internally before pattern matching, so
`"UNIVERSITY OF COLORADO"`, `"University of Colorado"`, and
`"university of colorado"` all produce `"Academic"`. You do **not** need
to pre-process the case of your input column. If you supply your own
`academic_patterns` or `government_patterns`, write them in
**lowercase** — they are matched against the lowercased name, so an
uppercase pattern like `"University"` will never match.

------------------------------------------------------------------------

## 3. Urban/Rural classification with RUCA codes

### What are RUCA codes?

**Rural-Urban Commuting Area (RUCA) codes** are a geographic
classification system developed by the USDA Economic Research Service
(ERS). They assign a numeric code to each US ZIP code based on the
population density of the area and the proportion of workers who commute
to an urban core. RUCA codes are widely used in health services research
to characterize provider practice locations on an urban-to-rural
continuum.

RUCA codes range from 1 to 10:

| Code | Description                                        |
|------|----------------------------------------------------|
| 1    | Metropolitan area core: primary flow in urban area |
| 2    | Metropolitan area high commuting                   |
| 3    | Metropolitan area low commuting                    |
| 4    | Micropolitan area core                             |
| 5    | Micropolitan high commuting                        |
| 6    | Micropolitan low commuting                         |
| 7    | Small town core                                    |
| 8    | Small town high commuting                          |
| 9    | Small town low commuting                           |
| 10   | Rural areas                                        |

`mysterycall` maps these ten codes to three clinically meaningful tiers:

| RUCA range | Category |
|------------|----------|
| 1–3        | Urban    |
| 4–6        | Suburban |
| 7–10       | Rural    |

This three-tier mapping is the standard used in most healthcare access
studies and by the Federal Office of Rural Health Policy.

### Where to get the crosswalk file

The USDA ERS publishes a ZIP-to-RUCA crosswalk at:

> <https://www.ers.usda.gov/data-products/rural-urban-commuting-area-codes>

Download the **ZIP code file** (not the census tract file). As of 2023,
the file is named something like `ruca2010revised.xlsx`. Export it to
CSV. The two columns you need are the ZIP code column (typically
`ZIP_CODE`) and the primary RUCA code column (typically `RUCA1`).

### Step 1: Load and clean the crosswalk

``` r

library(readr)

ruca_crosswalk <- read_csv(
  "data-raw/ruca2010revised.csv",
  col_types = cols(
    ZIP_CODE = col_character(),  # keep leading zeros: "01234" not 1234
    RUCA1    = col_double()
  )
) |>
  dplyr::select(zip5 = ZIP_CODE, ruca_code = RUCA1) |>
  dplyr::distinct(zip5, .keep_all = TRUE)  # one row per ZIP
```

**Critical:** Always read ZIP codes as character, not integer. ZIP codes
like `01234` (Massachusetts) will lose their leading zero if read as
numeric, causing all New England providers to fail the join.

### Step 2: Prepare the ZIP column in your roster

NPPES exports ZIP codes in a column named `addresses_postal_code`. That
column often contains 9-digit ZIP+4 codes (e.g., `80204-2127`). You need
the 5-digit base ZIP only.

``` r

roster <- roster |>
  dplyr::mutate(
    zip5 = stringr::str_sub(addresses_postal_code, 1L, 5L)
  )
```

### Step 3: Join the crosswalk using `mysterycall_safe_left_join()`

``` r

roster_with_ruca <- mysterycall_safe_left_join(
  left         = roster,
  right        = ruca_crosswalk,
  by           = "zip5",
  label_left   = "roster",
  label_right  = "USDA RUCA crosswalk",
  min_coverage = 0.90   # warn if >10% of providers have unmatched ZIPs
)
```

[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md)
performs several safety checks automatically:

- It asserts that `ruca_crosswalk` has unique keys on `zip5` (no
  duplicate ZIP rows that would fan out your roster).
- It coerces mismatched column types (e.g., if one side has `zip5` as
  integer and the other as character) to prevent silent zero-match
  joins.
- It reports join coverage: what fraction of roster rows found a
  matching ZIP in the crosswalk.
- It stops with an informative error if coverage falls below
  `min_coverage`.

If coverage is below 90%, inspect the unmatched ZIPs:

``` r

unmatched <- dplyr::anti_join(roster, ruca_crosswalk, by = "zip5")
table(unmatched$addresses_state)
```

Post office box ZIP codes, US territories (Guam, Puerto Rico, US Virgin
Islands), and military APO/FPO addresses are the most common sources of
unmatched ZIPs. Decide in advance whether these providers should be
excluded from the RUCA analysis or assigned a manual code.

### Step 4: Classify RUCA codes

``` r

roster_with_ruca <- roster_with_ruca |>
  dplyr::mutate(
    geography = mysterycall_classify_ruca(ruca_code)
  )

table(roster_with_ruca$geography, useNA = "always")
```

### Ordered factor for ggplot2 and ordinal models

When using RUCA category as an outcome in an ordinal logistic regression
or as an axis in a ggplot2 bar chart, you want the levels to appear in
geographic order (Urban \< Suburban \< Rural), not alphabetical order.
Use `as_factor = TRUE`:

``` r

roster_with_ruca <- roster_with_ruca |>
  dplyr::mutate(
    geography_f = mysterycall_classify_ruca(ruca_code, as_factor = TRUE)
  )

levels(roster_with_ruca$geography_f)
#> [1] "Urban"    "Suburban" "Rural"    "Unknown"

# Now ggplot2 and MASS::polr() will use the correct order automatically
```

### Custom breakpoints

The default cutpoints (1–3=Urban, 4–6=Suburban, 7–10=Rural) follow USDA
ERS convention, but some journals and federal agencies use a two-tier
(Metro vs Non-Metro) or an alternative three-tier system. You can change
the thresholds with `urban_max` and `suburban_max`:

``` r

# Two-tier: Metro (RUCA 1-3) vs Non-Metro (RUCA 4-10)
roster_with_ruca <- roster_with_ruca |>
  dplyr::mutate(
    geography_2tier = mysterycall_classify_ruca(
      ruca_code,
      urban_max    = 3,
      suburban_max = 3,   # no Suburban tier; anything >3 is Rural
      labels       = c("Metro", "Metro", "Non-Metro"),  # labels[1] and [2] collapse
      na_label     = "Unknown"
    )
  )
```

Actually, for a strict two-tier system the cleanest approach is:

``` r

roster_with_ruca <- roster_with_ruca |>
  dplyr::mutate(
    geography_metro = dplyr::case_when(
      is.na(ruca_code)  ~ "Unknown",
      ruca_code <= 3    ~ "Metro",
      TRUE              ~ "Non-Metro"
    )
  )
```

### Coverage check

Always report the fraction of providers with missing RUCA codes in your
methods section:

``` r

n_total    <- nrow(roster_with_ruca)
n_missing  <- sum(is.na(roster_with_ruca$ruca_code))
pct_missing <- round(n_missing / n_total * 100, 1)

message(sprintf(
  "%d of %d providers (%.1f%%) had no RUCA code (unmatched ZIP).",
  n_missing, n_total, pct_missing
))
```

A missing rate above 5% should trigger a manual review of the unmatched
ZIP codes.

------------------------------------------------------------------------

## 4. Census region assignment

### Which system should you use?

[`mysterycall_assign_region()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_assign_region.md)
supports three geographic classification systems. The right choice
depends on your study population and the expected readership:

| System | Use when |
|----|----|
| `"census"` | General US population health research; Census Bureau regions (Northeast, Midwest, South, West) are recognised by all audiences |
| `"acog"` | OB/GYN studies; ACOG Districts I–XII align with ACOG committee structure and are cited in obstetrics journals |
| `"aao_hns"` | Otolaryngology studies; AAO-HNS Districts 1–8 align with the specialty’s committee structure |

For a multi-specialty mystery-caller study, use `"census"`. For a study
submitted to *Obstetrics & Gynecology* or *AJOG*, use `"acog"`. For a
study in *Otolaryngology-Head and Neck Surgery* or *Laryngoscope*, use
`"aao_hns"`.

### All three systems with examples

``` r

states <- c("CO", "Texas", "New York", "california", "Massachusetts", NA)

# US Census Bureau regions
mysterycall_assign_region(states, system = "census")
#> [1] "West"      "South"     "Northeast" "West"      "Northeast" "Unknown"

# ACOG Districts
mysterycall_assign_region(states, system = "acog")
#> [1] "District VIII" "District VII"  "District II"   "District IX"
#> [5] "District I"    "Unknown"

# AAO-HNS Districts
mysterycall_assign_region(states, system = "aao_hns")
#> [1] "District 7" "District 6" "District 2" "District 8"
#> [5] "District 1" "Unknown"
```

The function accepts: - **Two-letter abbreviations** (`"CO"`, `"TX"`) —
case-insensitive, so `"co"` and `"CO"` both work. - **Full state names**
(`"Colorado"`, `"Texas"`) — case-insensitive, so `"colorado"`,
`"COLORADO"`, and `"Colorado"` all work. Internal title-casing logic
handles common prepositions correctly (e.g., `"district of columbia"`
maps correctly because `"of"` is preserved lowercase in the lookup
key). - **Mixed formats in the same vector** —
`c("CO", "Texas", "new york")` resolves correctly.

### Applying to a roster

``` r

roster <- roster |>
  dplyr::mutate(
    census_region = mysterycall_assign_region(addresses_state, system = "census"),
    acog_district = mysterycall_assign_region(addresses_state, system = "acog")
  )

# Summary table
table(roster$census_region, useNA = "always")
```

### Handling territories and possessions

Puerto Rico (`"PR"`), Guam (`"GU"`), and the US Virgin Islands (`"VI"`)
are included in the ACOG and AAO-HNS maps but not in the Census Bureau
regional map (they are not states and are not assigned to a Census
region). They will return `"Unknown"` with `system = "census"`. This is
intentional and correct.

``` r

mysterycall_assign_region(c("PR", "GU", "VI"), system = "acog")
#> [1] "District IV" "Unknown"     "District IV"   # GU is AAO-HNS only

mysterycall_assign_region(c("PR", "GU", "VI"), system = "census")
#> [1] "Unknown" "Unknown" "Unknown"
```

------------------------------------------------------------------------

## 5. Medical school classification

### Why classify medical school?

Physician training background is a potential confounder in access
studies. Internationally trained physicians (IMGs) are
disproportionately located in rural and underserved areas and may have
different scheduling practices. Osteopathic physicians (DOs) have a
distinct training philosophy and may be distributed differently across
specialties and geographic regions. Knowing whether a physician trained
at a US allopathic school, a US osteopathic school, a Canadian school,
or an international school helps you control for training-related
heterogeneity.

### The four classification categories

[`mysterycall_classify_medical_school()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_medical_school.md)
assigns one of four values:

| Category   | Meaning                                              |
|------------|------------------------------------------------------|
| `"US_MD"`  | US allopathic medical school (LCME-accredited)       |
| `"US_DO"`  | US osteopathic medical school (COCA-accredited)      |
| `"CAN_MD"` | Canadian medical school (LCMCC/AFMC member)          |
| `"IMG"`    | International medical graduate (all other countries) |

Classification priority is: `US_DO` \> `CAN_MD` \> `IMG` \> `US_MD`.
Schools that match no DO, Canadian, or international pattern are assumed
to be US allopathic. This is the correct default because the
LCME-accredited school list is far larger than the DO and Canadian
lists, making a permissive default more practical than enumerating all
155 US allopathic schools.

### Applying to a roster

The school name column in NPPES is typically found via the CMS Physician
Compare or NPI registry enrichment workflow, not in the base NPPES
download. It may be labelled `medical_school_name`,
`training_institution`, or similar.

``` r

schools <- c(
  "University of Colorado School of Medicine",   # US_MD
  "Philadelphia College of Osteopathic Medicine",# US_DO: "osteopathic" matches DO list
  "McGill University Faculty of Medicine",        # CAN_MD: "mcgill" in Canadian list
  "Ross University School of Medicine",           # IMG: "ross university" in IMG list
  "Universidad Nacional Autonoma de Mexico",      # IMG: "universidad" matches IMG list
  NA_character_                                   # Unknown
)

mysterycall_classify_medical_school(schools)
#> [1] "US_MD"   "US_DO"   "CAN_MD"  "IMG"     "IMG"     "Unknown"

# Apply to a roster column
roster <- roster |>
  dplyr::mutate(
    med_school_type = mysterycall_classify_medical_school(medical_school_name)
  )
```

### Intersection with credential column

An important nuance: a physician with a `"DO"` credential in NPPES who
graduated from a US osteopathic school is classified as `"US_DO"`. But a
physician with an `"MD"` credential who graduated from a school matching
the IMG pattern is classified as `"IMG"` — international medical
graduates who obtained USMLE equivalence and a US medical license still
practice with MD credentials in the US.

Do not substitute the credential column (`basic_credential`) for the
medical school column. They measure different things. A physician can be
credentialed as `"MD"` and still be an IMG if they obtained their degree
from a foreign school.

``` r

# Correct: classify by school name; use credential only as a secondary check
roster <- roster |>
  dplyr::mutate(
    med_school_type = mysterycall_classify_medical_school(medical_school_name),
    # Flag potential mismatches: DO credential but school classified as US_MD
    credential_mismatch = (basic_credential == "DO") & (med_school_type == "US_MD")
  )

# If credential_mismatch > 0, investigate: school name may be missing or malformed
sum(roster$credential_mismatch, na.rm = TRUE)
```

------------------------------------------------------------------------

## 6. Age imputation from graduation year

### The NPPES age gap

The National Provider Identifier (NPI) registry does not publish
physician birth year. This is a deliberate privacy protection. However,
the registry does publish medical school graduation year, which is a
strong proxy for age.
[`mysterycall_impute_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_impute_age.md)
converts graduation year to estimated current age using the formula:

    estimated_age = ref_year - grad_year + age_offset

where `age_offset` (default 27) is the median age at US medical school
graduation. This method has been validated against Doximity birth-year
data for over 32,000 OB/GYN physicians (r = 0.962, mean absolute error =
2.1 years) and 348 ENT physicians (r = 0.957, MAE = 1.7 years).

### The `ref_year` parameter

**Always pin `ref_year` to your study’s data collection year.** Do not
use the default (current calendar year) in a paper whose data were
collected in a prior year. If your calls were made in 2023, use
`ref_year = 2023L`. This ensures that the estimated ages in your
analysis correspond to the physicians’ ages at the time they were
called, not at the time you are writing the paper.

``` r

roster <- roster |>
  dplyr::mutate(
    age_imputed = mysterycall_impute_age(
      graduation_year,
      ref_year   = 2023L,  # pin to your data collection year
      age_offset = 27L     # validated median age at US med school graduation
    )
  )
```

### Warnings for implausible values

[`mysterycall_impute_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_impute_age.md)
issues a warning in two situations:

1.  **Future graduation years** (`grad_year > ref_year`): This almost
    always indicates a data entry error. For example,
    `graduation_year = 20220` (a typo for 2022) will produce a future
    year warning. Investigate these before proceeding.

2.  **Implausible ages** (below `min_age = 25` or above `max_age = 90`):
    Values outside this range are set to `NA` with a warning. A
    physician who graduated in 1924 would be computed as age 129 in 2023
    — almost certainly a data entry error in NPPES. Check these rows
    manually.

``` r

# Example showing how warnings fire
mysterycall_impute_age(
  c(1980, 2010, 2028, 1920),  # 2028 is future; 1920 gives age > 90
  ref_year   = 2023L,
  age_offset = 27L
)
# Warning: 1 graduation year(s) exceed ref_year (2023) and will produce NA ages.
# Warning: 1 imputed age(s) outside [25, 90] set to NA. Check graduation years.
#> [1] 70 40 NA NA
```

### Converting to decade brackets for Table 1

Raw imputed age is a continuous variable, which is appropriate for
regression models. For Table 1, decade brackets are conventional.
[`mysterycall_age_category()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_age_category.md)
bins ages into standard brackets:

``` r

roster <- roster |>
  dplyr::mutate(
    age_category = mysterycall_age_category(
      age_imputed,
      breaks    = c(30, 40, 50, 60, 70),  # creates 6 bins
      as_factor = TRUE   # ordered factor for correct table ordering
    )
  )

levels(roster$age_category)
#> [1] "<30"     "30-39"   "40-49"   "50-59"   "60-69"   "70+"     "Unknown"

table(roster$age_category, useNA = "always")
```

If you want non-standard age breaks — for example, to combine the
youngest and oldest bins for a specialty where physicians under 35 are
rare — supply custom breaks and labels:

``` r

roster <- roster |>
  dplyr::mutate(
    age_4cat = mysterycall_age_category(
      age_imputed,
      breaks = c(40, 50, 60),
      labels = c("<40", "40-49", "50-59", "60+"),
      as_factor = TRUE
    )
  )
```

The `breaks` vector defines the left boundaries of the intervals
(exclusive lower bound). The rule is: a physician with age exactly 40
falls into the “40-49” category, not “\<40”.

------------------------------------------------------------------------

## 7. Gender backfill with Genderize.io

### The NPPES gender gap

NPPES records physician sex in the `basic_gender` column as `"M"` or
`"F"`. However, approximately 5% of records are missing this field,
either because the physician declined to provide it or because it was
not required when their NPI was registered. Missing gender is not random
— it is more common among older physicians who registered early in the
NPPES era and among physicians with non-Western names.

[`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md)
fills in missing gender values by querying the
[Genderize.io](https://genderize.io) API, which predicts gender from
first names using a database of hundreds of millions of social media
profiles. The API returns a predicted gender, a probability (0–1), and a
name count (how many individuals with that name were in the database).

### API rate limits and cost

The free tier of Genderize.io allows **1,000 unique name lookups per
month**.
[`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md)
deduplicates names before querying, so if your roster has 300 providers
but only 180 unique first names, it uses only 180 API credits. If you
expect to run this step multiple times (e.g., during development), cache
the output by specifying `output_dir`.

If you exceed the free tier, the API returns HTTP 429.
[`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md)
catches this and raises an informative error rather than silently
returning empty data. Paid tiers are available at
<https://genderize.io/#pricing>.

### The `data_or_path` parameter

[`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md)
accepts either a data frame or a file path to a CSV or Parquet roster.
Your input **must have a column named `first_name`**. If NPPES data uses
`basic_first_name`, rename it first:

``` r

roster_for_genderize <- roster |>
  dplyr::rename(first_name = basic_first_name)
```

### Running the genderize step

Because this step makes live API calls, it should be run **once** and
the output cached. Do not run it on every `Rmd` knit. Use `eval = FALSE`
in the vignette chunk and point to the cached output file.

``` r

# Run this interactively ONCE, then save the output
genderized <- mysterycall_genderize(
  data_or_path  = roster_for_genderize,
  output_dir    = "data-processed/genderized",  # cache to a stable directory
  output_format = "csv"
)
```

Columns added by
[`mysterycall_genderize()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_genderize.md):

| Column | Type | Description |
|----|----|----|
| `gender` | character | `"male"`, `"female"`, or `NA` (ambiguous name) |
| `probability` | double | API confidence score, 0–1 |
| `count` | integer | Number of individuals with that name in the Genderize.io database |

### Filtering by probability threshold

The API can predict gender for almost any name, but with widely varying
confidence. A probability of 0.51 for a name means the API is
essentially guessing. A common threshold for research use is 0.90:

``` r

# Load the cached genderized output
genderized <- readr::read_csv("data-processed/genderized/genderized_20231015120000_roster.csv")

# Apply a probability threshold before using the gender prediction
genderized <- genderized |>
  dplyr::mutate(
    gender_api = dplyr::if_else(
      probability >= 0.90,
      gender,
      NA_character_   # treat low-confidence predictions as missing
    )
  )
```

### Combining Genderize.io with NPPES gender

Use Genderize.io only to fill in what NPPES is missing. Do not override
NPPES `basic_gender` values with API predictions — the physician
self-reported their gender to the registry, which is more authoritative
than a name-based prediction.

``` r

genderized <- genderized |>
  dplyr::mutate(
    # Keep NPPES gender when available; fall back to Genderize.io when missing
    gender_combined = dplyr::case_when(
      basic_gender %in% c("M", "F")     ~ basic_gender,          # NPPES takes precedence
      probability >= 0.90 & !is.na(gender) ~ toupper(substr(gender, 1, 1)),  # "male" -> "M"
      TRUE                              ~ NA_character_
    )
  )

# Summarize coverage improvement
before <- mean(is.na(roster$basic_gender))
after  <- mean(is.na(genderized$gender_combined))
message(sprintf(
  "Gender coverage: %.1f%% missing before genderize; %.1f%% missing after.",
  before * 100, after * 100
))
```

------------------------------------------------------------------------

## 8. Preparing Table 1 variables

### Purpose of `mysterycall_prepare_table1_vars()`

Once you have run all the enrichment steps above, the resulting data
frame contains a mix of raw NPPES values, API outputs, and
custom-classified columns — often with inconsistent capitalization and
coding.
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md)
is a convenience wrapper that standardizes all demographic columns in a
single call, producing consistently named output columns ready for Table
1.

It does four things: 1. Imputes age from graduation year (if
`grad_year_col` is supplied and `age_col` is not). 2. Creates
decade-bracket age categories. 3. Standardizes gender to `"Male"` /
`"Female"` / `"Unknown"`. 4. Passes through practice setting and region
columns under standard names.

### All parameters

| Parameter | Default | Purpose |
|----|----|----|
| `age_col` | `NULL` | Name of an existing age column; skips imputation if supplied |
| `grad_year_col` | `NULL` | Graduation year column for age imputation |
| `gender_col` | `NULL` | Raw gender column to standardize |
| `setting_col` | `NULL` | Practice setting column (passed through as `setting_std`) |
| `region_col` | `NULL` | Region column (passed through as `region_std`) |
| `ref_year` | current year | Reference year for age imputation — pin this to your data year |

### Gender standardization and the binary warning

[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md)
maps gender values to a **binary classification**: `"Male"`, `"Female"`,
or `"Unknown"`. The following input values are recognised:

| Input value                            | Output `gender_std` |
|----------------------------------------|---------------------|
| `"male"`, `"m"`, `"Male"`, `"M"`       | `"Male"`            |
| `"female"`, `"f"`, `"Female"`, `"F"`   | `"Female"`          |
| `NA`, `""`, `"unknown"`, anything else | `"Unknown"`         |

Matching is case-insensitive and whitespace-trimmed. Non-binary and
ambiguous values are silently bucketed into `"Unknown"` with a warning
message. **Before calling this function**, inspect your gender column
for unexpected values:

``` r

# Always inspect before standardizing
table(roster$gender_combined, useNA = "always")
#>    F    M    NA
#>  142  155    3

# If you see anything unexpected (e.g., "non-binary", "unknown", "X"),
# decide how to handle it before calling prepare_table1_vars().
```

This is a deliberate design choice for mystery-caller research: studies
typically report binary sex assigned at registry registration, not
gender identity. If your study protocol requires tracking non-binary
providers separately, do not use this wrapper — handle gender
standardization manually.

### Complete example

``` r

analysis_ready <- genderized |>
  mysterycall_prepare_table1_vars(
    grad_year_col = "graduation_year",   # will compute age_imputed and age_category
    gender_col    = "gender_combined",   # will compute gender_std
    setting_col   = "practice_setting",  # will copy to setting_std
    region_col    = "census_region",     # will copy to region_std
    ref_year      = 2023L                # pin to data collection year
  )

# New columns added:
# age_imputed, age_category, gender_std, setting_std, region_std
dplyr::glimpse(analysis_ready |> dplyr::select(age_imputed, age_category,
                                                 gender_std, setting_std, region_std))
```

------------------------------------------------------------------------

## 9. Stratified sampling

### When you need a balanced pilot sample

Mystery-caller pilot studies often specify a target number of calls per
subspecialty. If your full roster has 800 physicians but your
IRB-approved protocol allows only 90 calls (30 per subspecialty), you
need a balanced random sample.
[`mysterycall_stratified_sample()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_stratified_sample.md)
provides this.

### Parameters

| Parameter     | Type      | Purpose                                        |
|---------------|-----------|------------------------------------------------|
| `group_col`   | character | Column to stratify on (e.g., `"subspecialty"`) |
| `n_per_group` | integer   | Target rows per group                          |
| `seed`        | integer   | Random seed for reproducibility                |

### Behavior when a group is smaller than `n_per_group`

Groups with fewer rows than `n_per_group` are **returned in full without
upsampling**. Upsampling (returning a group with replacement) would
duplicate physician records, creating artificial inflation of the study
denominator. If you have only 15 pediatric otolaryngologists in your
roster and request `n_per_group = 30`, all 15 will be returned.

``` r

set.seed(42L)  # for documentation; pass seed= instead in production

pilot_roster <- mysterycall_stratified_sample(
  data        = roster,
  group_col   = "subspecialty",
  n_per_group = 30L,
  seed        = 42L
)

# Verify balance
table(pilot_roster$subspecialty)
#> General Otolaryngology       Head and Neck Oncology   Laryngology
#>                      30                           30          30

# Groups returned in full when smaller than n_per_group
nrow(pilot_roster)  # may be < 30 * n_groups if any group was small
```

### Reproducibility note

Always specify `seed` when using this function in a paper. Without a
fixed seed, every run of
[`mysterycall_stratified_sample()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_stratified_sample.md)
will produce a different sample. Pin the seed to your IRB approval date
or a meaningful constant and document it in your methods.

------------------------------------------------------------------------

## 10. Checking for over-called physicians

### Why duplicates matter

In a mystery-caller study, each physician should receive exactly the
number of calls specified in the protocol (typically one call per
insurance type in a multi-wave design). Data entry errors, system
glitches, or human error can cause a physician to be called more times
than intended. These **over-called physicians** must be identified
before analysis: including extra calls would inflate apparent acceptance
rates and introduce within-physician correlation that violates
independence assumptions.

[`mysterycall_check_duplicates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_duplicates.md)
returns a subset of the call log containing only physicians who have
been called more than `max_calls` times.

### Parameters and output

| Parameter | Default | Purpose |
|----|----|----|
| `id_col` | required | Name of the physician identifier column (e.g., `"npi"`) |
| `max_calls` | `2L` | Maximum allowed calls per physician |

The returned data frame: - Contains only **flagged physicians** (those
exceeding `max_calls`). - Has an additional `n_calls` column showing how
many times each physician appears. - Is sorted descending by `n_calls`
(worst offenders first). - Has an attribute `"n_flagged"` with the count
of unique flagged physicians.

``` r

flagged <- mysterycall_check_duplicates(
  call_log,
  id_col    = "npi",
  max_calls = 2L   # each physician should appear at most twice (one per insurance arm)
)

# How many unique physicians were over-called?
attr(flagged, "n_flagged")
#> [1] 4

# Inspect the worst offenders
head(flagged[, c("npi", "physician_name", "call_date", "insurance", "n_calls")])
```

### Remediation options

Once you have identified over-called physicians, you have two options:

**Option 1 — Keep the first N calls and discard extras:** This is
appropriate when the extra calls were genuine scheduling errors and you
want to retain the valid calls.

``` r

# Keep only the first 2 calls per NPI (chronological order)
call_log_clean <- call_log |>
  dplyr::arrange(npi, call_date) |>
  dplyr::group_by(npi) |>
  dplyr::slice_head(n = 2L) |>
  dplyr::ungroup()
```

**Option 2 — Exclude all calls for over-called physicians:** This is
appropriate when the extra calls may have introduced contamination
(e.g., the physician or scheduler recognised the caller after the first
call) and you cannot determine which calls are valid.

``` r

flagged_npis <- unique(flagged$npi)
call_log_clean <- dplyr::filter(call_log, !npi %in% flagged_npis)

message(sprintf(
  "Excluded %d physicians (%d calls) from analysis due to over-calling.",
  length(flagged_npis),
  sum(call_log$npi %in% flagged_npis)
))
```

Document your choice in the methods section and in the CONSORT flow
diagram.

------------------------------------------------------------------------

## 11. Complete pipeline example

This section assembles all previous steps into a single, reproducible
pipeline. We build a synthetic 300-row roster that mimics the structure
of a real NPPES export, run every enrichment function, and produce a
final analysis-ready data frame.

### Step 0: Build a synthetic roster

``` r

set.seed(2023L)
n <- 300L

subspecialties <- c(
  "General Otolaryngology", "Laryngology", "Head and Neck Oncology",
  "Rhinology", "Otology / Neurotology", "Pediatric Otolaryngology"
)

org_names <- c(
  # Academic
  "University of Colorado Medical Center", "Vanderbilt University Medical Center",
  "UCSF Department of Otolaryngology", "Ohio State Wexner Medical Center",
  "Mount Sinai Health System",
  # Government
  "VA Medical Center Denver", "Walter Reed National Military Medical Center",
  "Indian Health Service Hospital",
  # Private Practice
  "Denver ENT Associates LLC", "Rocky Mountain Otolaryngology PA",
  "Midwest ENT Group", "Pacific Ear Nose Throat",
  "Suburban Otolaryngology Practice", "Southwest ENT Specialists LLC"
)

states_vec <- c(
  "CO", "TX", "CA", "NY", "FL", "OH", "GA", "IL", "NC", "PA",
  "WA", "AZ", "MA", "MI", "TN", "VA", "MO", "WI", "MN", "OR"
)

# Simulate 9-digit ZIP codes (NPPES format)
zip_base <- c(
  "80204", "78201", "90001", "10001", "33101",
  "43201", "30301", "60601", "27601", "19101",
  "98101", "85001", "02101", "48201", "37201",
  "22201", "63101", "53201", "55101", "97201"
)

roster_raw <- data.frame(
  npi                  = paste0("1", sprintf("%09d", seq_len(n))),
  basic_first_name     = sample(c("James", "Emily", "Michael", "Sarah", "David",
                                   "Jennifer", "Robert", "Lisa", "William", "Karen",
                                   "Christopher", "Linda", "Matthew", "Jessica",
                                   "Ashley", "Ryan", "Mia", "Jordan"), n, replace = TRUE),
  basic_last_name      = paste0("Physician_", seq_len(n)),
  basic_gender         = sample(c("M", "F", NA_character_), n,
                                 replace = TRUE, prob = c(0.55, 0.40, 0.05)),
  basic_credential     = sample(c("MD", "DO", "MD, PhD", "DO, MPH"), n,
                                 replace = TRUE, prob = c(0.75, 0.15, 0.08, 0.02)),
  org_name             = sample(org_names, n, replace = TRUE),
  addresses_state      = sample(states_vec, n, replace = TRUE),
  addresses_postal_code = paste0(
    sample(zip_base, n, replace = TRUE),
    "-",
    sprintf("%04d", sample(0:9999, n, replace = TRUE))
  ),
  taxonomies_desc      = sample(subspecialties, n, replace = TRUE),
  graduation_year      = sample(1975:2018, n, replace = TRUE),
  medical_school_name  = sample(c(
    "University of Colorado School of Medicine",
    "Philadelphia College of Osteopathic Medicine",
    "McGill University Faculty of Medicine",
    "Ross University School of Medicine",
    "Harvard Medical School",
    "Stanford University School of Medicine",
    "Midwestern University Chicago College of Osteopathic Medicine"
  ), n, replace = TRUE, prob = c(0.35, 0.10, 0.05, 0.05, 0.20, 0.20, 0.05)),
  stringsAsFactors = FALSE
)
```

### Step 1: Classify practice setting

``` r

roster_raw <- roster_raw |>
  dplyr::mutate(
    practice_setting = mysterycall_classify_practice_setting(org_name)
  )

table(roster_raw$practice_setting)
```

### Step 2: Join RUCA crosswalk (tiny example)

For this synthetic example we create a minimal crosswalk. In real usage,
replace this with the downloaded USDA ERS file.

``` r

# Extract 5-digit ZIP from NPPES 9-digit format
roster_raw <- roster_raw |>
  dplyr::mutate(zip5 = substr(addresses_postal_code, 1L, 5L))

# Tiny crosswalk for demonstration
ruca_crosswalk_demo <- data.frame(
  zip5      = c("80204", "78201", "90001", "10001", "33101",
                "43201", "30301", "60601", "27601", "19101",
                "98101", "85001", "02101", "48201", "37201",
                "22201", "63101", "53201", "55101", "97201"),
  ruca_code = c(1, 1, 1, 1, 1,
                1, 1, 1, 1, 1,
                1, 1, 2, 1, 1,
                1, 1, 2, 2, 2),
  stringsAsFactors = FALSE
)

roster_with_ruca <- mysterycall_safe_left_join(
  left         = roster_raw,
  right        = ruca_crosswalk_demo,
  by           = "zip5",
  label_left   = "roster",
  label_right  = "ruca_crosswalk",
  min_coverage = 0.80
)
```

### Step 3: Classify RUCA into geographic tier

``` r

roster_with_ruca <- roster_with_ruca |>
  dplyr::mutate(
    geography    = mysterycall_classify_ruca(ruca_code),
    geography_f  = mysterycall_classify_ruca(ruca_code, as_factor = TRUE)
  )
```

### Step 4: Assign Census region

``` r

roster_with_ruca <- roster_with_ruca |>
  dplyr::mutate(
    census_region = mysterycall_assign_region(addresses_state, system = "census"),
    aao_district  = mysterycall_assign_region(addresses_state, system = "aao_hns")
  )
```

### Step 5: Classify medical school

``` r

roster_with_ruca <- roster_with_ruca |>
  dplyr::mutate(
    med_school_type = mysterycall_classify_medical_school(medical_school_name)
  )

table(roster_with_ruca$med_school_type)
```

### Step 6: Impute age and categorize

``` r

roster_with_ruca <- roster_with_ruca |>
  dplyr::mutate(
    age_imputed  = mysterycall_impute_age(graduation_year, ref_year = 2023L),
    age_category = mysterycall_age_category(age_imputed, as_factor = TRUE)
  )
```

### Step 7: Genderize (run once, cache output)

This step makes live API calls. Run it once interactively and save the
result. The `eval=FALSE` chunk below will not execute during
[`knitr::knit()`](https://rdrr.io/pkg/knitr/man/knit.html).

``` r

# Step 7a: Prepare first_name column required by mysterycall_genderize()
roster_for_gender <- roster_with_ruca |>
  dplyr::rename(first_name = basic_first_name)

# Step 7b: Query Genderize.io API (run ONCE; cache output)
# NOTE: Requires internet access; consumes API quota (1000 names/month free tier)
genderized <- mysterycall_genderize(
  data_or_path  = roster_for_gender,
  output_dir    = "data-processed/genderized",
  output_format = "csv"
)

# Step 7c: Apply probability threshold and combine with NPPES gender
genderized <- genderized |>
  dplyr::mutate(
    gender_api = dplyr::if_else(
      !is.na(probability) & probability >= 0.90,
      toupper(substr(gender, 1L, 1L)),  # "male" -> "M", "female" -> "F"
      NA_character_
    ),
    # NPPES takes precedence; Genderize fills in missing values only
    gender_combined = dplyr::case_when(
      basic_gender %in% c("M", "F")  ~ basic_gender,
      !is.na(gender_api)             ~ gender_api,
      TRUE                           ~ NA_character_
    )
  ) |>
  # Restore the original column name before prepare_table1_vars()
  dplyr::rename(basic_first_name = first_name)
```

### Step 8: Prepare Table 1 variables

``` r

# If you skipped step 7, substitute genderized with roster_with_ruca
# and set gender_col = "basic_gender"

analysis_ready <- genderized |>
  mysterycall_prepare_table1_vars(
    grad_year_col = "graduation_year",
    gender_col    = "gender_combined",
    setting_col   = "practice_setting",
    region_col    = "census_region",
    ref_year      = 2023L
  )
```

### Step 9: Select analysis-ready columns

``` r

final_roster <- analysis_ready |>
  dplyr::select(
    # Identifiers
    npi,
    basic_first_name, basic_last_name,
    # Practice characteristics
    taxonomies_desc,
    setting_std,          # Academic / Government / Private Practice
    med_school_type,      # US_MD / US_DO / CAN_MD / IMG
    # Geography
    addresses_state,
    census_region,
    aao_district,
    geography,            # Urban / Suburban / Rural
    # Demographics
    age_imputed,
    age_category,
    gender_std            # Male / Female / Unknown
  )
```

### Step 10: Inspect the result

``` r

dplyr::glimpse(final_roster)
```

Expected output structure:

    Rows: 300
    Columns: 14
    $ npi              <chr> "1000000001", "1000000002", ...
    $ basic_first_name <chr> "James", "Emily", "Michael", ...
    $ basic_last_name  <chr> "Physician_1", "Physician_2", ...
    $ taxonomies_desc  <chr> "General Otolaryngology", "Laryngology", ...
    $ setting_std      <chr> "Private Practice", "Academic", ...
    $ med_school_type  <chr> "US_MD", "US_DO", "CAN_MD", ...
    $ addresses_state  <chr> "CO", "TX", "CA", ...
    $ census_region    <chr> "West", "South", "West", ...
    $ aao_district     <chr> "District 7", "District 6", "District 8", ...
    $ geography        <chr> "Urban", "Urban", "Urban", ...
    $ age_imputed      <int> 58, 43, 67, ...
    $ age_category     <ord> 50-59, 40-49, 60-69, ...
    $ gender_std       <chr> "Male", "Female", "Male", ...

### Producing Table 1

With the final roster prepared, pass it directly to
[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md):

``` r

t1 <- mysterycall_table1(
  final_roster,
  covariates = c(
    "gender_std",
    "age_category",
    "setting_std",
    "geography",
    "census_region",
    "med_school_type"
  ),
  stratify_by = "taxonomies_desc",
  variable_labels = c(
    gender_std    = "Sex",
    age_category  = "Age category",
    setting_std   = "Practice setting",
    geography     = "Urban/Rural",
    census_region = "Census region",
    med_school_type = "Medical school type"
  )
)

# Print the table
print(t1)

# Or access the underlying tibble for knitr::kable() formatting
knitr::kable(t1$table, caption = "Table 1. Provider characteristics by subspecialty.")
```

------------------------------------------------------------------------

## Session information

``` r

sessionInfo()
```
