# Mystery Caller Workflow: From Raw Data to Manuscript

## Overview

Mystery-caller (secret-shopper) studies measure disparities in
healthcare access by having trained callers pose as patients requesting
appointments under different insurance types. Each physician in the
sampling frame is called once per insurance type; the caller records
whether an appointment was offered and, if so, how many business days
until the earliest available slot. The `mysterycall` package provides a
structured pipeline from raw call logs to manuscript-ready statistics,
covering quality control, deduplication, descriptive summaries,
regression modeling, and sensitivity analyses.

## Simulated Data

We construct a 200-row data frame representing 100 physician offices,
each called twice — once under Medicaid and once under Blue Cross/Blue
Shield.

``` r

suppressMessages({
  library(mysterycall)

  set.seed(42)
  n_phy  <- 100L
  ids    <- sprintf("%03d", seq_len(n_phy))
  phones <- paste0("555-", sprintf("%04d", seq_len(n_phy)))

  raw_df <- data.frame(
    id_number             = rep(ids, each = 2L),
    phone                 = rep(phones, each = 2L),
    physician_information = paste0("Dr. Physician ", rep(ids, each = 2L)),
    insurance             = rep(c("Medicaid", "Blue Cross/Blue Shield"), n_phy),
    stringsAsFactors      = FALSE
  )

  raw_df$reason_for_exclusions <- sample(
    c("Able to contact", "Physician not available", "Number disconnected"),
    200L, replace = TRUE, prob = c(0.70, 0.20, 0.10)
  )

  # Appointment wait times only for successfully-contacted rows
  raw_df$business_days_until_appointment <- ifelse(
    raw_df$reason_for_exclusions == "Able to contact",
    rpois(200L, lambda = 14L) + 1L,
    NA_integer_
  )

  # Medicaid acceptance column: realistic for Medicaid rows, boilerplate for BCBS
  medicaid_vals <- sample(
    c(
      "Yes they accept Medicaid",
      "No",
      "No answer, unable to determine if they accept Medicaid."
    ),
    200L, replace = TRUE, prob = c(0.55, 0.30, 0.15)
  )
  raw_df$does_the_physician_accept_medicaid <- ifelse(
    raw_df$insurance == "Medicaid",
    medicaid_vals,
    "NA as this was a Blue Cross/Blue Shield call."
  )

  raw_df$scenario <- sample(
    c("HIP scenario", "SHOULDER scenario", "KNEE scenario"),
    200L, replace = TRUE
  )
  raw_df$gender <- sample(c("Male", "Female"), 200L, replace = TRUE)
  raw_df$state  <- sample(
    c(
      "Colorado", "Texas", "California", "New York", "Florida",
      "Illinois", "Pennsylvania", "Ohio", "Georgia", "Michigan"
    ),
    200L, replace = TRUE
  )
  raw_df$notes <- NA_character_
})

dim(raw_df)
#> [1] 200  11
head(raw_df[, c("id_number", "phone", "insurance",
                "reason_for_exclusions", "business_days_until_appointment")])
#>   id_number    phone              insurance   reason_for_exclusions
#> 1       001 555-0001               Medicaid     Number disconnected
#> 2       001 555-0001 Blue Cross/Blue Shield     Number disconnected
#> 3       002 555-0002               Medicaid         Able to contact
#> 4       002 555-0002 Blue Cross/Blue Shield Physician not available
#> 5       003 555-0003               Medicaid         Able to contact
#> 6       003 555-0003 Blue Cross/Blue Shield         Able to contact
#>   business_days_until_appointment
#> 1                              NA
#> 2                              NA
#> 3                              11
#> 4                              NA
#> 5                              12
#> 6                              13
```

## Quality Control

Two QC checks are run on the raw data.
[`mysterycall_flag_repeat_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md)
identifies physician records appearing more than the expected number of
times.
[`mysterycall_flag_exclusion_discrepancy()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_exclusion_discrepancy.md)
flags rows that are marked as excluded but nonetheless carry a
non-negative appointment wait time — a logical contradiction indicating
a data-entry error.

``` r

suppressMessages({
  repeat_flag <- mysterycall_flag_repeat_physicians(
    raw_df,
    output_dir = NA
  )

  disc_flag <- mysterycall_flag_exclusion_discrepancy(
    raw_df,
    output_dir = NA
  )
})

repeat_flag
#> # A tibble: 0 × 3
#> # ℹ 3 variables: id_number <chr>, physician_information <chr>, n_calls <int>
disc_flag
#> [1] physician_information           id_number                      
#> [3] notes                           reason_for_exclusions          
#> [5] business_days_until_appointment
#> <0 rows> (or 0-length row.names)
```

Both checks pass: no physician exceeds the call-count threshold and no
excluded row carries a valid wait time.

## Deduplication

[`mysterycall_dedup_by_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_dedup_by_insurance.md)
removes duplicate rows so each phone x insurance x physician combination
appears exactly once.

``` r

df <- suppressMessages(
  mysterycall_dedup_by_insurance(raw_df, output_dir = NA)
)
nrow(df)
#> [1] 200
```

## Clean Medicaid Column

[`mysterycall_clean_medicaid_col()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_medicaid_col.md)
recodes ambiguous or non-informative responses to `NA` and appends a
binary 0/1 numeric indicator.

``` r

df <- suppressMessages(
  mysterycall_clean_medicaid_col(df)
)
table(df$cleaned_does_the_physician_accept_medicaid, useNA = "ifany")
#> 
#>                       No Yes they accept Medicaid                     <NA> 
#>                       29                       55                      116
```

## Sample Demographics

[`mysterycall_sample_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_demographics.md)
computes total call counts, insurance-group physician counts, and
geographic coverage, then returns a manuscript-ready sentence.

``` r

demo <- suppressMessages(
  mysterycall_sample_demographics(df, output_dir = NA)
)
cat(demo$summary_sentence, "\n")
#> Our sample included 200 calls to physician offices from 10 states, excluding Alabama, Alaska, Arizona, Arkansas, Connecticut, Delaware, Hawaii, Idaho, Indiana, Iowa, Kansas, Kentucky, Louisiana, Maine, Maryland, Massachusetts, Minnesota, Mississippi, Missouri, Montana, Nebraska, Nevada, New Hampshire, New Jersey, New Mexico, North Carolina, North Dakota, Oklahoma, Oregon, Rhode Island, South Carolina, South Dakota, Tennessee, Utah, Vermont, Virginia, Washington, West Virginia, Wisconsin, Wyoming and District of Columbia.
```

## Scenario Counts

[`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md)
tabulates calls by scenario and produces a descriptive sentence ready
for insertion into the Participants section.

``` r

scen <- suppressMessages(
  mysterycall_scenario_summary(
    df,
    scenario_levels = c(
      hip      = "HIP scenario",
      shoulder = "SHOULDER scenario",
      knee     = "KNEE scenario"
    ),
    contact_col = "reason_for_exclusions",
    output_dir  = NA
  )
)
print(scen$counts)
#> # A tibble: 3 × 3
#>   scenario          count percent
#>   <chr>             <int>   <dbl>
#> 1 KNEE scenario        69    34.5
#> 2 SHOULDER scenario    67    33.5
#> 3 HIP scenario         64    32
cat(scen$sentence, "\n")
#> There were 200 calls, with sports medicine orthopedists specializing in 64 hip, 67 shoulder, and 69 knee.
```

## Acceptance Rates

[`mysterycall_insurance_acceptance_rates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_acceptance_rates.md)
computes Medicaid and Blue Cross/Blue Shield acceptance rates using
distinct-physician numerators and denominators that exclude unreachable
physician offices.

``` r

rates <- suppressMessages(
  mysterycall_insurance_acceptance_rates(df, output_dir = NA)
)
#> Warning in mysterycall_insurance_acceptance_rates(df, output_dir = NA):
#> mysterycall_insurance_acceptance_rates() is deprecated. Use
#> mysterycall_acceptance_rate_calc(medicaid_screen_group = "Medicaid") instead.
cat(rates$paragraph, "\n")
#> Medicaid Acceptance Rate: Out of the total number of physicians assigned Medicaid insurance (100), 65 physicians accepted Medicaid and provided an appointment, resulting in an acceptance rate of 100.0%. Blue Cross/Blue Shield Acceptance Rate: Among the physicians assigned Blue Cross/Blue Shield insurance (100), 64 accepted this insurance and provided an appointment, yielding an acceptance rate of 100.0%.
```

## Wait Times

[`mysterycall_wait_time_by_group()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_by_group.md)
provides median (IQR) wait times per group.
[`mysterycall_wait_time_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_sentence.md)
additionally fits a Poisson GLM to obtain p-values for each group versus
the reference and assembles a full paragraph.

``` r

wt_grp <- suppressMessages(
  mysterycall_wait_time_by_group(
    df,
    group_col  = "insurance",
    output_dir = NA
  )
)
print(wt_grp)
#> # A tibble: 2 × 5
#>   insurance              median_days    q1    q3     n
#>   <chr>                        <dbl> <dbl> <dbl> <int>
#> 1 Blue Cross/Blue Shield        14.5    12    17    64
#> 2 Medicaid                      14      11    17    65

wt_sent <- suppressMessages(
  mysterycall_wait_time_sentence(df, group_col = "insurance")
)
cat(wt_sent$sentence, "\n")
#> The median wait time across all insurance was 14 business days (IQR: 11 to 17). Specifically, the median wait time was 14 days (IQR: 12 to 17) for Blue Cross/Blue Shield, 14 days (IQR: 11 to 17) for Medicaid. The p-value for Medicaid vs Blue Cross/Blue Shield was 0.900.
```

## Poisson Model

[`mysterycall_simple_poisson()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_simple_poisson.md)
fits a Poisson GLM and returns an incidence rate ratio (IRR) table with
confidence intervals and a manuscript-ready summary statement. Poisson
regression is preferred over rank tests because the outcome (days until
appointment) is a count variable.

``` r

poisson_res <- suppressMessages(
  mysterycall_simple_poisson(
    df,
    outcome        = "business_days_until_appointment",
    group          = "insurance",
    reference      = "Blue Cross/Blue Shield",
    outcome_label  = "business days until appointment",
    use_profile_ci = FALSE
  )
)

knitr::kable(
  poisson_res$irr_table[, c("level", "irr", "ci_lower", "ci_upper", "p_value_fmt")],
  digits    = 3,
  caption   = "Poisson regression incidence rate ratios (reference: Blue Cross/Blue Shield)",
  col.names = c("Group", "IRR", "95% CI Lower", "95% CI Upper", "P-value")
)
```

| Group    |   IRR | 95% CI Lower | 95% CI Upper | P-value |
|:---------|------:|-------------:|-------------:|:--------|
| Medicaid | 1.006 |        0.919 |        1.101 | 0.900   |

Poisson regression incidence rate ratios (reference: Blue Cross/Blue
Shield) {.table}

## Sensitivity Analysis

[`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)
identifies physicians called under both Medicaid and Blue Cross/Blue
Shield and compares their wait times, providing a paired check of
whether the observed acceptance-rate difference holds within physicians.

``` r

sens <- suppressMessages(
  mysterycall_sensitivity_both_insurance(df, output_dir = NA)
)
cat(sens$sentence, "\n")
#> Of 100 physicians called, 100 (100.0%) were called under both Medicaid and Blue Cross/Blue Shield. Among these physicians, mean wait times were 14.6 days (SD 3.8) for Medicaid vs 14.5 days (SD 3.5) for BCBS (t-test p = 0.450).
```

## Mapping to Manuscript Sections

The functions used in this vignette map directly to standard manuscript
sections.
[`mysterycall_sample_demographics()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sample_demographics.md)
and
[`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md)
supply the **Participants** paragraph of the Methods section.
[`mysterycall_insurance_acceptance_rates()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_insurance_acceptance_rates.md)
drives the primary **Results** sentence reporting acceptance rates by
insurance type.
[`mysterycall_wait_time_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_sentence.md)
and
[`mysterycall_simple_poisson()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_simple_poisson.md)
together produce the **Statistical Analysis** paragraph and the IRR
table reported in the Results. Finally,
[`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)
supplies the **Sensitivity Analysis** subsection, which compares paired
physician records across insurance types to assess whether the
acceptance-rate gap reflects within-physician differences in scheduling
behavior.
