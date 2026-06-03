# Getting Started with mysterycall

## Introduction

The `mysterycall` package provides a comprehensive, end-to-end toolkit
for conducting mystery caller studies in healthcare research. This
vignette walks you through a simplified, reproducible example of the
entire workflow: from generating a provider roster, to preparing the
data for callers, to analyzing the results.

``` r

library(mysterycall)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

## Step 1: Building a Provider Roster

In a real study, you would likely use
[`mysterycall_search_taxonomy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_taxonomy.md)
or
[`mysterycall_search_and_process_npi()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_search_and_process_npi.md)
to query the NPPES registry. For this example, we will use a small
subset of the bundled `physicians` dataset.

``` r

# Load bundled physician data
data(physicians)

# Select a sample for our dummy study (50 rows so the demo model has
# enough within-group variation across subspecialties)
set.seed(1978)
roster <- physicians %>%
  dplyr::slice_sample(n = 50) %>%
  mutate(
    phone_number = "555-555-1212", # Dummy phone
    practice_name = paste("Clinic", dplyr::row_number()),
    state = "CO"
  )

head(roster)
#> # A tibble: 6 × 8
#>          NPI name     subspecialty   lat   long phone_number practice_name state
#>        <dbl> <chr>    <chr>        <dbl>  <dbl> <chr>        <chr>         <chr>
#> 1 1790702322 Fareesa… Female Pelv…  41.9  -87.6 555-555-1212 Clinic 1      CO   
#> 2 1437595758 Cassand… Reproductiv…  39.6 -105.  555-555-1212 Clinic 2      CO   
#> 3 1477627164 Ghasan … Reproductiv…  29.8  -95.4 555-555-1212 Clinic 3      CO   
#> 4 1457766958 Sun Kwo… Maternal-Fe…  42.6  -83.0 555-555-1212 Clinic 4      CO   
#> 5 1093734956 Michael… Reproductiv…  38.6  -90.2 555-555-1212 Clinic 5      CO   
#> 6 1497871792 Cynthia… Female Pelv…  42.3  -87.6 555-555-1212 Clinic 6      CO
```

## Step 2: Preparing Data for Callers

Before handing off the data, we need to ensure it is clean and properly
formatted. We can use the package’s normalization utilities.

``` r

# Normalize names and practice locations
clean_roster <- roster %>%
  mutate(
    # In a real workflow, you might use mysterycall_normalize_address_df here
    practice_name = toupper(practice_name),
    # Assign random scenarios (e.g., Medicaid vs. Private Insurance)
    insurance_scenario = sample(c("Medicaid", "Private"), nrow(.), replace = TRUE)
  )

# Verify the cleaned data
head(clean_roster)
#> # A tibble: 6 × 9
#>          NPI name     subspecialty   lat   long phone_number practice_name state
#>        <dbl> <chr>    <chr>        <dbl>  <dbl> <chr>        <chr>         <chr>
#> 1 1790702322 Fareesa… Female Pelv…  41.9  -87.6 555-555-1212 CLINIC 1      CO   
#> 2 1437595758 Cassand… Reproductiv…  39.6 -105.  555-555-1212 CLINIC 2      CO   
#> 3 1477627164 Ghasan … Reproductiv…  29.8  -95.4 555-555-1212 CLINIC 3      CO   
#> 4 1457766958 Sun Kwo… Maternal-Fe…  42.6  -83.0 555-555-1212 CLINIC 4      CO   
#> 5 1093734956 Michael… Reproductiv…  38.6  -90.2 555-555-1212 CLINIC 5      CO   
#> 6 1497871792 Cynthia… Female Pelv…  42.3  -87.6 555-555-1212 CLINIC 6      CO   
#> # ℹ 1 more variable: insurance_scenario <chr>
```

## Step 3: The Handoff

You can use
[`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md)
to divide the roster among your research assistants.

``` r

# Example of splitting the roster (not evaluated here to prevent file creation)
# mysterycall_split_and_save(
#   clean_roster, 
#   output_directory = tempdir(), 
#   lab_assistant_names = c("Caller A", "Caller B")
# )
```

## Step 4: Analyzing Results

After your callers return the completed spreadsheets, you would clean
them using
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)
and
[`mysterycall_clean_phase2()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase2.md).

Let’s simulate the results of the calls:

``` r

# Simulate caller responses
results <- clean_roster %>%
  mutate(
    able_to_contact_office = "Yes",
    are_we_including = "Yes",
    appointment_date = sample(seq(as.Date('2024-01-01'), as.Date('2024-03-01'), by="day"), nrow(.), replace=TRUE),
    call_time = "09:00",
    hold_time = "00:02",
    # Simulate that Private insurance has a higher acceptance rate;
    # store as integer (0/1) because mysterycall_poisson_model requires
    # a numeric outcome >= 0.
    accepted = as.integer(ifelse(insurance_scenario == "Private",
                     sample(c(1, 0), nrow(.), replace = TRUE, prob = c(0.8, 0.2)),
                     sample(c(1, 0), nrow(.), replace = TRUE, prob = c(0.4, 0.6))))
  )
```

### Table 1: Demographics

Generate a quick Table 1 of your provider sample.

``` r

# Prepare variables for Table 1
t1_data <- mysterycall_prepare_table1_vars(results)

# Generate the table
t1 <- mysterycall_table1(
  data = t1_data,
  covariates = c("insurance_scenario"),
  stratify_by = "accepted",
  include_overall = TRUE
)

print(t1)
#> Table 1 (Overall N=50, 0 N=24, 1 N=26)
#> Stratified by: accepted
#> 
#> # A tibble: 2 × 6
#>   variable           level    Overall    `0 (N=24)` `1 (N=26)` p_value
#>   <chr>              <chr>    <chr>      <chr>      <chr>      <chr>  
#> 1 insurance_scenario Medicaid 27 (54.0%) 20 (83.3%) 7 (26.9%)  <0.001 
#> 2 insurance_scenario Private  23 (46.0%) 4 (16.7%)  19 (73.1%) NA
```

### Multivariable Modeling

Finally, run a Poisson regression with robust standard errors to analyze
the primary outcome (appointment acceptance rate).

``` r

# Fit a Poisson mixed model: subspecialty as random intercept allows
# the demo model to converge with this small simulated sample.
model <- mysterycall_poisson_model(
  data             = results,
  outcome          = "accepted",
  predictors       = "insurance_scenario",
  random_intercept = "subspecialty"
)
#> 24 row(s) have accepted = 0 (same-day appointments). Poisson handles zeros; verify these are intentional.
#> Fitting Poisson GLMER: accepted ~ insurance_scenario + (1 | subspecialty)
#> boundary (singular) fit: see help('isSingular')
#> Warning: Convergence issues detected:
#>   boundary (singular) fit: see help('isSingular')
#> Consider simplifying predictors or using nAGQ = 1.
#> Warning: Singular fit: random-intercept variance is ~0. The physician-level
#> random effect explains little variation.
#> Model fitted: n=50, physicians=6, AIC=84.2, overdispersion=0.50

# Print the incidence rate ratios (IRR)
print(model)
#> Poisson GLMER  n = 50  physicians = 6  AIC = 84.2  BIC = 89.9
#>   Warning: convergence warnings; singular fit
#>   Reference levels: insurance_scenario='Medicaid'
#> 
#> Fixed effects (IRR with Wald CI):
#> # A tibble: 2 × 5
#>   term                        irr ci_lower ci_upper p_value_fmt
#>   <chr>                     <dbl>    <dbl>    <dbl> <chr>      
#> 1 (Intercept)               0.259    0.124    0.544 <0.001     
#> 2 insurance_scenarioPrivate 3.19     1.34     7.58  0.009      
#> 
#> Random intercept (subspecialty):  variance = 0.0000  SD = 0.0000

# Generate a manuscript-ready results paragraph
mysterycall_write_results_paragraph(
  model_result = model,
  ref_group = "Private",
  exposure_col = "insurance_scenario",
  outcome_label = "appointment acceptance"
)
#> [1] "In multivariable Poisson regression, insurance_scenario was significantly associated with appointment acceptance (see Table X). Compared with Private, callers presenting as Private had an IRR of 3.19 (95% CI 1.34-7.58; p = 0.009) for appointment acceptance."
```

## Conclusion

This vignette covered the basic lifecycle of a mystery caller study. For
deep dives into specific topics like geospatial routing, Census
integration, or power analysis, please explore the other vignettes
provided with the package.
