# Getting Data from the US Census Bureau for Isochrones

## Introduction

This vignette demonstrates the usage of the
`mysterycall_get_census_data` function, which is designed to retrieve
Census data for all states’ block groups. It leverages the `censusapi`
package to query the U.S. Census Bureau’s API and collect demographic
information for specified state FIPS codes. We’ll get the population in
each block group using the
[censusapi](https://www.hrecht.com/censusapi/) library and this relies
heavily on her vignette.

#### Centers for Medicare and Medicaid Services Doctors and Clinicians Downloadable file

The Downloadable File is housed in the CMS Medicare Compare (aka
Physician Compare site): [CMS Medicare
Compare](https://data.cms.gov/provider-data/dataset/mj5m-pzi6). We could
have downloaded the full data set file and do a left join but that runs
the risk of being out of date give the data is update monthly. Here is
the data dictionary for the file: [CMS Medicare Compare Data
Dictionar](https://data.cms.gov/provider-data/sites/default/files/data_dictionaries/physician/DOC_Data_Dictionary.pdf).
The Doctors and Clinicians national downloadable file is organized at
the individual clinician level; each line is unique at the
clinicianenrollment record-group-address
(NPI-Ind_enrl_ID-Org_PAC_ID-adrs_id) level. Clinicians with multiple
Medicare enrollment records and/or single enrollments linking to
multiple practice locations are listed on multiple lines.

#### State Federal Information Processing Standards Codes

This function retrieves Census data using censusapi for all states’
block groups by looping over the specified list of state FIPS codes.
This only brings back data on females from “B01001_01, 26, 33:49E”. FIPS
codes, or Federal Information Processing Standards codes, are a
standardized set of codes used to uniquely identify geographic areas in
the United States. These codes are assigned to various administrative
and geographical entities, such as states, counties, cities, and more.
We used block groups for the analysis.

The GEOID for block groups in the United States can be constructed using
the following format: STATECOUNTYTRACTBLOCK_GROUP. Specifically: \*
STATE is a 2-digit code for the state. \* COUNTY is a 3-digit code for
the county. \* TRACT is a 6-digit code for the census tract. \*
BLOCK_GROUP is a 1-digit code for the block group within the tract.

#### Block Group as the Unit of Measurement

In the United States Census Bureau’s geographic hierarchy, a “block
group” is a smaller and more detailed geographic unit used for
collecting and reporting demographic and statistical data. Block groups
are subdivisions of census tracts and are typically designed to contain
between 600 and 3,000 people, although this can vary depending on the
population density of the area. Census block group borders are defined
based on visible and easily identifiable features such as roads, rivers,
streets, or natural boundaries like mountains and parks. The Census
Bureau aims to create block group boundaries that follow these features
to make them easily distinguishable.

Block groups are used as the primary units for collecting detailed
demographic and socioeconomic data during the decennial census and the
American Community Survey (ACS). Census enumerators visit households
within each block group to collect information on population, housing,
employment, income, education, and more. In a densely populated urban
area, a block group might represent a city block or a small neighborhood
within a larger city. For example, a block group could cover a few city
blocks in downtown Manhattan, New York City.

## Data From the US Census Bureau

These variables are part of a dataset obtained from the U.S. Census
Bureau’s American Community Survey (ACS). The U.S. Census Bureau’s
American Community Survey (ACS) is an ongoing nationwide survey
conducted by the United States Census Bureau. It is designed to collect
and provide detailed demographic, social, economic, and housing
information about the American population. Here are some key features
and aspects of the ACS:

- Continuous Survey: The ACS is conducted continuously throughout the
  year, providing updated and current data. Unlike the decennial census,
  which occurs every ten years, the ACS is conducted annually, allowing
  for more frequent and timely information.

- Sampling: The ACS uses a sample-based approach to collect data from a
  representative subset of the U.S. population. The sample includes
  households and individuals from all 50 states, the District of
  Columbia, and Puerto Rico.

- Questionnaire: Respondents are asked to complete a detailed
  questionnaire that covers a wide range of topics, including
  demographics (age, sex, race, etc.), housing characteristics,
  education, employment, income, health insurance, and more.

- Geographic Coverage: The ACS provides data at various geographic
  levels, including national, state, county, city, town, and even census
  tract or block group. This allows for detailed analysis of communities
  and regions.

- Data Release: The ACS releases data in various forms, including
  one-year estimates, three-year estimates, and five-year estimates.
  One-year estimates are available for areas with larger populations,
  while three-year and five-year estimates are designed for smaller
  areas and subpopulations. The five-year estimates provide the most
  reliable data for small geographic areas and specific demographic
  groups.

- Accessibility: ACS data is publicly accessible and can be accessed
  through the Census Bureau’s website, data.census.gov, and other data
  dissemination platforms. Researchers, policymakers, businesses, and
  the general public use ACS data for various purposes, including policy
  development, market research, and community planning.

- Importance: The ACS is a critical tool for understanding the changing
  demographics and socio-economic characteristics of the U.S.
  population. It is used for congressional apportionment, resource
  allocation, grant distribution, and various research purposes.

- Privacy and Confidentiality: The Census Bureau takes privacy and
  confidentiality seriously. Personal information collected in the ACS
  questionnaire is protected by law, and responses are aggregated to
  ensure that individual respondents cannot be identified.

- Census Long Form Replacement: The ACS was introduced to replace the
  long-form questionnaire that was part of the decennial census. The
  long-form collected detailed demographic and housing information, and
  the ACS continues to provide this valuable data on an ongoing basis.

They represent demographic information for block groups within various
states. Here’s an explanation of each variable:

- `name`: This variable represents the name or label of the block group.
- `total_females`: It represents the total number of females in the
  block group.
- `female_21_yo`: This variable represents the number of females aged 21
  years and older in the block group.
- `female_22_to_24_years`: It represents the number of females aged 22
  to 24 years in the block group.
- `female_25_to_29_years`: This variable represents the number of
  females aged 25 to 29 years in the block group.
- `female_30_to_34_years`: It represents the number of females aged 30
  to 34 years in the block group.
- etc.

&nbsp;

        name = NAME,
        total_females = B01001_026E,
        female_21_yo = B01001_033E,
        female_22_to_24_years = B01001_034E,
        female_25_to_29_years = B01001_035E,
        female_30_to_34_years = B01001_036E,
        female_35_to_39_years = B01001_037E,
        female_40_to_44_years = B01001_038E,
        female_45_to_49_years = B01001_039E,
        female_50_to_54_years = B01001_040E,
        female_55_to_59_years = B01001_041E,
        female_60_to_61_years = B01001_042E,
        female_62_to_64_years = B01001_043E,
        female_65_to_66_years = B01001_044E,
        female_67_to_69_years = B01001_045E,
        female_70_to_74_years = B01001_046E,
        female_75_to_79_years = B01001_047E,
        female_80_to_84_years = B01001_048E,
        female_85_years_and_older = B01001_049E,
        fips_state = state

Eventually these data will be matched onto the Block Groups. The block
group shapefile is from the 2021 ACS via [National Historical Geographic
Information System (NHGIS)](https://www.nhgis.org/). To calculate how
many people live within and outside of the drive time isochrones, we’ll
need to identify the percent of each Census block group that lies within
the isochrones.

## Function Description

The get_census_data function retrieves Census data for all states’ block
groups. Here’s a brief description of its parameters:

`us_fips`: A vector of state FIPS (Federal Information Processing
Standards) codes. Each code uniquely identifies a U.S. state. For
example, Colorado is represented by the FIPS code 08.

The resulting data is combined into a single dataframe for analysis.

### Step 1

#### Installation

Before using the
[`mysterycall::mysterycall_get_census_data`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md)
function, you need to install and load the required packages. You can do
this by running the following code:

``` r
# Install and load the necessary packages
install.packages("censusapi")
library(censusapi)
library(dplyr)
library(mysterycall)
```

These lists contain metadata about general variables and the variables
related to race and ethnicity.

##### All Variables

    acs_vars <- censusapi::listCensusMetadata(name = "acs/acs5", 
          vintage = 2019, group = "B01001") %>% 
          readr::write_csv("data/acs_vars.csv")
          
    # This code cleans it up a bit
    acs_vars <- acs_vars %>%
      dplyr::select(-predicateType, -group, -limit, -predicateOnly) %>%
      dplyr::filter(!stringr::str_detect(label, fixed("!!Male:!!", ignore_case = TRUE))) %>%
      dplyr::filter(!stringr::str_detect(label, fixed("Annotation of Margin of Error", ignore_case = TRUE))) %>%
      dplyr::mutate(label = stringr::str_remove(label, regex("^Annotation of Estimate!!Total:!!Female:!!", ignore_case = TRUE))) %>%
      dplyr::filter(!stringr::str_detect(label, fixed("Margin of Error!!", ignore_case = TRUE))) %>%
      dplyr::mutate(label = stringr::str_remove(label, regex("^Annotation of Estimate!!Total:!!Female:!!", ignore_case = TRUE))) %>%
      dplyr::mutate(label = stringr::str_remove(label, regex("^Estimate!!Total:!!Female:!!", ignore_case = TRUE))) %>%
      dplyr::filter(!stringr::str_detect(name, fixed("EA")) & !str_detect(label, fixed("!!Male:"))) %>%
      dplyr::mutate(numbers = purrr::map_chr(str_extract_all(label, "^[:digit:]+"), ~ ifelse(length(.) == 0, NA_character_, paste(.x, collapse = "")))) %>%
      dplyr::mutate(numbers = as.numeric(numbers)) %>%
      dplyr::mutate(numbers = tidyr::replace_na(numbers, 0)) %>%
      dplyr::mutate(numbers = as.numeric(numbers)) %>%
      dplyr::arrange(numbers)
      
    > acs_vars
              name                     label    concept numbers
    1  B01001_026E Estimate!!Total:!!Female: SEX BY AGE       0
    2  B01001_027E             Under 5 years SEX BY AGE       0
    3  B01001_001E          Estimate!!Total: SEX BY AGE       0
    4  B01001_028E              5 to 9 years SEX BY AGE       5
    5  B01001_029E            10 to 14 years SEX BY AGE      10

##### Race Variables

    acs_race_vars <- censusapi::listCensusMetadata(name = "acs/acs5", 
          vintage = 2019, group = "B02001") %>%
          readr::write_csv("data/acs_race_vars.csv")

    #output:
    > acs_race_vars
    # A tibble: 40 × 7
       name         label                                                      concept predicateType group limit predicateOnly
       <chr>        <chr>                                                      <chr>   <chr>         <chr> <dbl> <lgl>        
     1 B02001_010EA Annotation of Estimate!!Total:!!Two or more races:!!Two r… RACE    string        B020…     0 TRUE         
     2 B02001_010MA Annotation of Margin of Error!!Total:!!Two or more races:… RACE    string        B020…     0 TRUE         
     3 B02001_001EA Annotation of Estimate!!Total:                             RACE    string        B020…     0 TRUE         
     4 B02001_001MA Annotation of Margin of Error!!Total:                      RACE    string        B020…     0 TRUE         
     5 B02001_004EA Annotation of Estimate!!Total:!!American Indian and Alask… RACE    string        B020…     0 TRUE         
     6 B02001_004MA Annotation of Margin of Error!!Total:!!American Indian an… RACE    string        B020…     0 TRUE         
     7 B02001_005EA Annotation of Estimate!!Total:!!Asian alone                RACE    string        B020…     0 TRUE         
     8 B02001_005MA Annotation of Margin of Error!!Total:!!Asian alone         RACE    string        B020…     0 TRUE         
     9 B02001_002EA Annotation of Estimate!!Total:!!White alone                RACE    string        B020…     0 TRUE         
    10 B02001_002MA Annotation of Margin of Error!!Total:!!White alone         RACE    string        B020…     0 TRUE  

##### Race and Ethnicity Variables

    acs_raceeth_vars <- censusapi::listCensusMetadata(name = "acs/acs5", 
          vintage = 2019, group = "B03002") %>%
          readr::write_csv("data/acs_raceeth_vars.csv")

### Step 2: Prepare Your Data

Define a vector of state FIPS codes. The 50 U.S. states (FIPS codes
under 56; higher codes are territories) are:

    us_fips_list <- c("01", "02", "04", "05", "06", "08", "09", "10", "11", "12",
                      "13", "15", "16", "17", "18", "19", "20", "21", "22", "23",
                      "24", "25", "26", "27", "28", "29", "30", "31", "32", "33",
                      "34", "35", "36", "37", "38", "39", "40", "41", "42", "44",
                      "45", "46", "47", "48", "49", "50", "51", "53", "54", "55")

### Step 3: Gather the Data from the US Census Bureau API

Call the `mysterycall_get_census_data` function with the `us_fips_list`
vector. The helper adds 2020 Federal Information Processing Standard
(FIPS) identifiers for every geography plus the Census vintage so you
always know which release supplied the estimates. For example:

    all_census_data <- get_census_data(us_fips_list = us_fips_list)

    ##########################################################################
    # Get Census data by block group in relevant states
    # Construct: for=block group:*&in=state:01&in=county:*&in=tract:*
    ###########################################################################

    # The returned list contains one data frame per state FIPS code.
    # Each data frame has columns: GEOID, NAME, and one column per ACS variable
    # requested (e.g. B01001_001E for total population).
    # Combine all states into a single data frame with:
    #   all_census_data <- dplyr::bind_rows(all_census_data)

### Step 4: The function will retrieve Census data for all specified states and combine it into a single dataframe, which you can use for further analysis.

    demographics_bg <- acs_block_group %>%
      rename(
        total_females = B01001_026E,
        female_21_yo = B01001_033E,
        female_22_to_24_years = B01001_034E,
        female_25_to_29_years = B01001_035E,
        female_30_to_34_years = B01001_036E,
        female_35_to_39_years = B01001_037E,
        female_40_to_44_years = B01001_038E,
        female_45_to_49_years = B01001_039E,
        female_50_to_54_years = B01001_040E,
        female_55_to_59_years = B01001_041E,
        female_60_to_61_years = B01001_042E,
        female_62_to_64_years = B01001_043E,
        female_65_to_66_years = B01001_044E,
        female_67_to_69_years = B01001_045E,
        female_70_to_74_years = B01001_046E,
        female_75_to_79_years = B01001_047E,
        female_80_to_84_years = B01001_048E,
        female_85_years_and_older = B01001_049E
      ) %>%
      mutate(
        population = female_21_yo + female_22_to_24_years + female_25_to_29_years +
          female_30_to_34_years + female_35_to_39_years + female_40_to_44_years +
          female_45_to_49_years +
          female_50_to_54_years +
          female_55_to_59_years +
          female_60_to_61_years +
          female_62_to_64_years +
          female_65_to_66_years +
          female_67_to_69_years +
          female_70_to_74_years +
          female_75_to_79_years +
          female_80_to_84_years +
          female_85_years_and_older
      ) %>% #total of reproductive age women
      arrange(statefp, countyfp, tractce, block_group) %>%
      select(
        geoid,
        statefp,
        countyfp,
        tractce,
        block_group,
        vintage,
        name,
        population,
        everything()
      ) %>%
      select(-starts_with("B"), -contains("universe"))

    colnames(demographics_bg)

    demographics_bg <- demographics_bg %>% arrange(geoid)
    readr::write.csv(demographics_bg, "data/acs-block-group-demographics.csv", na = "", row.names = F)
    readr::write_rds(demographics_bg, "data/acs-block-group-demographics.rds")

### Step 5: Join the Data to the Block Groups

Load the block group shapefile with
[`sf::st_read()`](https://r-spatial.github.io/sf/reference/st_read.html)
and join it to the demographic table on the 12-character GEOID. Always
join on GEOID rather than the human-readable `NAME` column, because name
strings differ across ACS vintages (e.g. county name capitalization
changes).

Use
[`mysterycall_safe_left_join()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_safe_left_join.md)
to catch GEOID type mismatches (integer vs. character) and to verify
coverage — every block group in the demographic table should find a
matching geometry.

``` r
# Load the block group shapefile (replace path with your actual file)
bg_shape <- sf::st_read("data/shp/block_group/") |>
  dplyr::select(GEOID, geometry)

# Coerce GEOID to character on both sides before joining
demographics_bg$geoid <- as.character(demographics_bg$geoid)
bg_shape$GEOID        <- as.character(bg_shape$GEOID)

# Safe join: errors if < 99 % of demographic rows find a geometry match
bg_with_geometry <- mysterycall_safe_left_join(
  left         = demographics_bg,
  right        = bg_shape,
  by           = c("geoid" = "GEOID"),
  label_left   = "demographics_bg",
  label_right  = "block_group_shapefile",
  min_coverage = 0.99
)

# Convert the joined data frame to an sf object
bg_sf <- sf::st_as_sf(bg_with_geometry)

# Save the spatial object for the isochrone intersection step
sf::st_write(bg_sf, "data/block_groups_with_demographics.gpkg", delete_dsn = TRUE)
readr::write_rds(bg_sf, "data/block_groups_with_demographics.rds")
```

### Step 6: Add Race and Ethnicity Variables

The `B02001` (Race) and `B03002` (Hispanic or Latino origin by race) ACS
tables augment the sex-by-age estimates with race/ethnicity breakdowns
at the block group level. Fetch them with the same
[`censusapi::getCensus()`](https://www.hrecht.com/censusapi/reference/getCensus.html)
pattern and join to the block group table on GEOID.

``` r
# Fetch race table for a single state (repeat across all FIPS codes)
race_raw <- censusapi::getCensus(
  name    = "acs/acs5",
  vintage = 2021,
  vars    = c("NAME",
              "B02001_001E",   # total population
              "B02001_002E",   # White alone
              "B02001_003E",   # Black or African American alone
              "B02001_004E",   # American Indian and Alaska Native alone
              "B02001_005E",   # Asian alone
              "B02001_006E",   # Native Hawaiian and Other Pacific Islander alone
              "B02001_007E",   # Some other race alone
              "B02001_008E"),  # Two or more races
  region  = "block group:*",
  regionin = "state:08&in=county:*&in=tract:*"
)

race_clean <- race_raw |>
  dplyr::rename(
    pop_total                 = B02001_001E,
    pop_white                 = B02001_002E,
    pop_black                 = B02001_003E,
    pop_aian                  = B02001_004E,
    pop_asian                 = B02001_005E,
    pop_nhpi                  = B02001_006E,
    pop_other_race            = B02001_007E,
    pop_two_or_more_races     = B02001_008E
  ) |>
  dplyr::mutate(
    geoid = paste0(state, county, tract, `block group`),
    pop_nonwhite = pop_total - pop_white
  )

# Fetch Hispanic origin table (B03002)
hisp_raw <- censusapi::getCensus(
  name    = "acs/acs5",
  vintage = 2021,
  vars    = c("B03002_001E",   # total
              "B03002_003E",   # Not Hispanic: White alone
              "B03002_012E"),  # Hispanic or Latino
  region  = "block group:*",
  regionin = "state:08&in=county:*&in=tract:*"
)

hisp_clean <- hisp_raw |>
  dplyr::rename(
    pop_total_hisp  = B03002_001E,
    pop_nhw         = B03002_003E,   # non-Hispanic White
    pop_hispanic    = B03002_012E
  ) |>
  dplyr::mutate(geoid = paste0(state, county, tract, `block group`))

# Join race and ethnicity onto the block group sf object
bg_sf_enriched <- bg_sf |>
  mysterycall_safe_left_join(
    right        = race_clean[, c("geoid", "pop_white", "pop_nonwhite",
                                   "pop_black", "pop_asian", "pop_aian")],
    by           = "geoid",
    label_left   = "bg_sf",
    label_right  = "race_B02001",
    min_coverage = 0.99
  ) |>
  mysterycall_safe_left_join(
    right        = hisp_clean[, c("geoid", "pop_nhw", "pop_hispanic")],
    by           = "geoid",
    label_left   = "bg_sf",
    label_right  = "hispanic_B03002",
    min_coverage = 0.99
  )
```

This enriched block group layer is ready for the isochrone intersection
step described in
[`vignette("create_isochrones", package = "mysterycall")`](https://mufflyt.github.io/mysterycall/articles/create_isochrones.md).

## Usage Tips

- Obtain a Census API key at
  <https://api.census.gov/data/key_signup.html> and set it with
  `censusapi::addApiKey("your_key_here")` or
  `Sys.setenv(CENSUS_KEY = "your_key_here")` before the first call.
- The function includes a one-second pause between state requests to
  respect the Census Bureau’s rate limits. For all 50 states this means
  the full run takes at least 50 seconds — plan accordingly.
- Pin the `vintage` year across all tables in a single study to ensure
  consistent geographies; block group boundaries change between ACS
  releases.
- For publication, report the ACS vintage year and five-year estimate
  period (e.g. “2017–2021 ACS 5-year estimates”) in your methods
  section.

## Conclusion

[`mysterycall_get_census_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_census_data.md)
retrieves sex-by-age block group estimates for any set of US states,
returning a tidy data frame ready for spatial joining and isochrone
overlap analysis. Supplement it with race and Hispanic-origin tables
from the same ACS release to support equity-focused access analyses.

## Features and bugs

If you have ideas for other features that would make the Census workflow
easier, or find a bug, report it at the package issue tracker.
