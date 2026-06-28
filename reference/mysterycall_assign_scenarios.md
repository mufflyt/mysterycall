# Assign call scenarios to generalist providers

In mystery caller studies, generalist providers are called using a
vignette that matches a subspecialty present in the same city/state.
This function groups providers by location, detects which subspecialty
scenarios are available locally, and assigns scenarios to generalists in
round-robin order so that calls are balanced across scenarios.

## Usage

``` r
mysterycall_assign_scenarios(
  data,
  location_cols = c("city", "state_code"),
  specialty_col = "specialty_primary",
  generalist_level,
  scenario_map,
  id_col = NULL,
  scenario_col = "scenario"
)
```

## Arguments

- data:

  A data frame containing provider records. One row = one provider.

- location_cols:

  Character vector of column names that define a geographic group
  (default `c("city", "state_code")`). Rows are grouped by all columns
  together.

- specialty_col:

  Character scalar. Column holding each provider's specialty (default
  `"specialty_primary"`).

- generalist_level:

  Character scalar. The value in `specialty_col` that identifies
  generalist providers who will receive scenario assignments.

- scenario_map:

  Named character vector mapping subspecialty values in `specialty_col`
  to scenario labels. Example:
  `c("Neurotology" = "Neurotology", "Pediatric Otolaryngology" = "Pediatric Otolaryngology")`.
  Each name is a value that appears in `specialty_col`; each value is
  the scenario label that will be assigned to generalists in cities
  where that subspecialty is present. **The subspecialty values used as
  names here must derive from board certification data (e.g. ABOHNS via
  [`mysterycall_parse_certification_subspecialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_parse_certification_subspecialty.md))
  and must not come from NPPES `taxonomies_desc` or DAC taxonomy
  codes.**

- id_col:

  Optional character scalar. Column used to sort rows within each
  location group before round-robin assignment. When `NULL` (default)
  the existing row order is used.

- scenario_col:

  Character scalar. Name of the new scenario column to create (default
  `"scenario"`).

## Value

`data` with one additional character column named `scenario_col`.

## Details

Non-generalist rows receive their own specialty as the scenario.
Generalists in locations that have no matching subspecialists receive
`NA`.

## See also

[`mysterycall_check_generalist_presence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_generalist_presence.md)
to validate paired generalist coverage before assigning scenarios;
[`mysterycall_reconcile_specialty()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_specialty.md)
for specialty harmonization.

## Examples

``` r
df <- data.frame(
  city          = c("Denver", "Denver", "Denver", "Denver", "Boulder", "Boulder"),
  state_code    = "CO",
  specialty_primary = c(
    "General Otolaryngology", "General Otolaryngology",
    "Neurotology", "Pediatric Otolaryngology",
    "General Otolaryngology", "Neurotology"
  ),
  id = 1:6,
  stringsAsFactors = FALSE
)
mysterycall_assign_scenarios(
  df,
  generalist_level = "General Otolaryngology",
  scenario_map     = c("Neurotology"               = "Neurotology",
                       "Pediatric Otolaryngology"  = "Pediatric Otolaryngology"),
  id_col           = "id"
)
#> Scenarios assigned to 3/3 generalist rows; stored in column 'scenario'.
#>      city state_code        specialty_primary id                 scenario
#> 1  Denver         CO   General Otolaryngology  1              Neurotology
#> 2  Denver         CO   General Otolaryngology  2 Pediatric Otolaryngology
#> 3  Denver         CO              Neurotology  3              Neurotology
#> 4  Denver         CO Pediatric Otolaryngology  4 Pediatric Otolaryngology
#> 5 Boulder         CO   General Otolaryngology  5              Neurotology
#> 6 Boulder         CO              Neurotology  6              Neurotology
```
