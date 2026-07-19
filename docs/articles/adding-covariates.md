# Adding Physician Covariates to the Wait-Time Model

## Why add physician covariates?

The core exposure in a mystery-caller study is the **insurance type**
presented by the simulated patient. But physicians are not identical: an
academic-center otolaryngologist, a rural solo practitioner, and an
urban multispecialty group physician may have systematically different
scheduling patterns regardless of insurance. If those differences are
large and unaccounted for, they become *residual variance* — noise that
makes it harder to detect the insurance effect you care about.

Adding physician-level covariates does two things simultaneously:

1.  **Controls for confounding.** Estimates of the insurance IRR become
    more precise because the model accounts for reasons why wait times
    differ across physicians that have nothing to do with insurance.
2.  **Reduces residual variance.** When a covariate explains variance in
    the outcome, the unexplained (residual) variance shrinks. Smaller
    residual variance means narrower confidence intervals and greater
    statistical power — you may need fewer physicians in a follow-up
    study.

The trade-off is **degrees of freedom**: every covariate you add costs
parameters, and parameters need data to estimate reliably.

------------------------------------------------------------------------

## Degrees of freedom and the events-per-variable rule

### What is a degree of freedom?

Each fixed-effect term in a regression model uses one degree of freedom.
A continuous predictor (age, years in practice) uses 1. A categorical
predictor with $`k`$ levels uses $`k - 1`$ (one level is absorbed as the
reference category).

For a model with $`p`$ total parameters, you have $`n - p`$**residual**
degrees of freedom — the information left over to estimate error after
all parameters are fitted. Residual df must be positive; the model
becomes singular if it equals zero.

### The events-per-variable (EPV) rule

For count-outcome (Poisson / negative binomial) models, the commonly
used rule of thumb is:

``` math
\text{EPV} = \frac{n_{\text{obs}}}{p} \geq 10
```

Below EPV = 10, parameter estimates become unstable and confidence
intervals widen unpredictably. Below EPV = 5, the model is unreliable
and results should not be reported.

### How mysterycall warns you

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
and
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md)
both check the EPV ratio **before fitting** and emit actionable
warnings:

``` r
# 40 observations, 5 predictors with many levels → low EPV
small_df <- data.frame(
  wait_days = rpois(40, 18),
  insurance = rep(c("Medicaid","BCBS"), 20),
  state     = sample(state.name[1:20], 40, replace = TRUE),  # 20 levels = 19 df
  physician = rep(paste0("Dr_", 1:8), 5),
  stringsAsFactors = FALSE
)

mysterycall_poisson_model(
  small_df,
  outcome          = "wait_days",
  predictors       = c("insurance", "state"),
  random_intercept = "physician"
)
#> Warning: Low events-per-variable ratio: 40 observations / 20 model parameters
#>   = 2.0 obs/param. Model estimates will be unreliable. Remove predictors
#>   or collect more data.
```

The safest path when EPV \< 10 is to **aggregate** categorical
predictors (e.g., use ACOG district instead of individual states, or
`"Academic"` vs. `"Private"` instead of hospital name) rather than
simply dropping the information.

### How many parameters does your study support?

A practical rule for planning:

| Physicians enrolled | Max safe parameters | Example model |
|----|----|----|
| 36 | 3 | insurance + scenario |
| 60 | 6 | insurance + scenario + gender + setting |
| 120 | 12 | insurance + scenario + gender + setting + ACOG district (11 df) |
| 200 | 20 | insurance + scenario + gender + setting + age category (3 df) + ACOG district (11 df) |

------------------------------------------------------------------------

## Overdispersion

### What it means

Poisson regression assumes **mean = variance**. Real wait-time data
routinely violates this: a physician who is very busy some weeks and
slow others will show variance far exceeding the mean (a physician
effect that the random intercept alone doesn’t absorb). This is
**overdispersion**.

The overdispersion ratio $`\phi`$ is computed as Pearson $`\chi^2`$ /
residual df. A value near 1 means the Poisson variance assumption holds.
Values \> 2 indicate problematic overdispersion.

### How mysterycall warns you

[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md)
computes and stores `$overdispersion` and emits a warning when
$`\phi > 2`$:

``` r
result <- mysterycall_poisson_model(
  mc_data,
  outcome          = "wait_days",
  predictors       = c("insurance"),
  random_intercept = "npi"
)
result$overdispersion
#> [1] 3.47
#> Warning: Overdispersion detected (phi = 3.47). Standard errors may be
#>   underestimated. Consider a negative binomial model.
```

### What to do about it

Switch to
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md).
The negative binomial distribution adds a **dispersion parameter**
$`\theta`$ (theta) such that:

``` math
\text{Var}(Y) = \mu + \frac{\mu^2}{\theta}
```

As $`\theta \to \infty`$, the variance equals the mean (Poisson). As
$`\theta \to 0`$, the distribution becomes more overdispersed. The NB
model estimates $`\theta`$ from the data and absorbs excess variance
into it rather than into the fixed-effect standard errors.

[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md)
warns you when:

- **$`\theta < 1`$**: extreme overdispersion even for NB — consider a
  zero-inflated model.
- **Residual $`\phi > 2`$ after NB fit**: the NB model still underfits —
  investigate zero-inflation or outlying observations.
- **$`\theta > 100`$**: minimal overdispersion — a Poisson model is
  probably adequate; compare AIC.

------------------------------------------------------------------------

## Available physician covariates

The `mysterycall` package provides functions to derive physician-level
covariates from the NPI registry, which contains information on all
licensed US clinicians.

### Practice setting (academic vs. private)

``` r
# After pulling clinician data with mysterycall_get_clinician_data()
mc_data$practice_setting <- mysterycall_classify_practice_setting(
  facility_name = mc_data$facility_name
)
# Returns "Academic", "Government", or "Private Practice"
table(mc_data$practice_setting)
```

Academic institutions have structured scheduling offices and residents;
they often have longer wait times for new-patient appointments than
private practices. Including this variable typically explains 10–20% of
residual variance in wait-time studies.

### Physician gender (from first name)

``` r
# Requires genderize.io API key stored in GENDERIZE_API_KEY env var
mc_data <- mysterycall_genderize(
  data        = mc_data,
  first_name  = "physician_first_name",
  last_name   = "physician_last_name"  # optional, improves accuracy
)
# Adds columns: gender, gender_probability
```

Gender may be associated with scheduling patterns (some studies show
female physicians see more patients per day). It is not a primary
hypothesis variable — include it as a *confounder control*.

### Physician age

``` r
# If graduation year is available (from NPI record)
mc_data$physician_age <- as.integer(format(Sys.Date(), "%Y")) -
  mc_data$graduation_year

# Binned for reporting and to reduce degrees of freedom
mc_data$age_category <- mysterycall_age_category(mc_data$physician_age)
# Returns "< 40", "40-54", "55-64", "65+"

# Summary sentence for manuscript methods:
mysterycall_physician_age(mc_data, "physician_age")
#> "The median age was 52.00 years (IQR: 43.0–61.0 years)."
```

Older physicians may have established patient panels that limit
new-patient availability.

### Geographic location

``` r
# Urban / Suburban / Rural from RUCA codes
mc_data$urbanicity <- mysterycall_classify_ruca(mc_data$ruca_code)

# ACOG district (12 levels → 11 df) or Census region (4 levels → 3 df)
mc_data$acog_district  <- mysterycall_assign_region(mc_data$state, type = "acog")
mc_data$census_region  <- mysterycall_assign_region(mc_data$state, type = "census")
```

Geographic factors drive systematic differences in physician density,
payer mix, and scheduling norms. ACOG districts (12 levels, 11 df) are
the right granularity for specialty studies — they are clinically
meaningful and consume far fewer degrees of freedom than individual
states (50 levels, 49 df).

------------------------------------------------------------------------

## Pulling covariates from the NPI registry

The fastest path is to use
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md)
to retrieve all available registry fields for your physician list:

``` r
# mc_npis: character vector of NPI numbers
clinician_info <- mysterycall_get_clinician_data(npi_list = mc_npis)

mc_data <- dplyr::left_join(mc_data, clinician_info, by = "npi")

# Derive covariates from registry fields
mc_data$practice_setting <- mysterycall_classify_practice_setting(
  mc_data$organization_name
)
mc_data$urbanicity <- mysterycall_classify_ruca(mc_data$ruca_code)
mc_data$acog_district <- mysterycall_assign_region(mc_data$state, type = "acog")
```

------------------------------------------------------------------------

## Fitting the recommended full model

### The model equation

The recommended multilevel negative binomial model with physician
covariates is:

``` math
\log(\mu_{ij}) = \beta_0
  + \beta_1 \text{Medicaid}_{ij}
  + \beta_2 \text{Incontinence}_{ij}
  + \beta_3 \text{Prolapse}_{ij}
  + \beta_4 \text{Male}_{ij}
  + \beta_5 \text{Academic}_{ij}
  + \beta_6 \text{Rural}_{ij}
  + \sum_{k=2}^{12} \gamma_k \text{ACOGDistrict}_{kij}
  + u_j
```

Where:

- $`Y_{ij} \sim \text{NegBin}(\mu_{ij}, \theta)`$
- $`i`$ = individual mystery call, $`j`$ = physician NPI
- $`\beta_0`$ = intercept (log expected wait for reference group: BCBS +
  Bladder pain, female, private, urban, District I)
- $`\beta_1`$ = log IRR for Medicaid vs BCBS
- $`\beta_2, \beta_3`$ = log IRR for scenario vs. Bladder Pain
- $`\beta_4`$ = log IRR for male vs. female physician
- $`\beta_5`$ = log IRR for Academic vs. Private Practice
- $`\beta_6`$ = log IRR for Rural vs. Urban
- $`\gamma_k`$ = fixed effect for ACOG District $`k`$ (District I is
  reference)
- $`u_j \sim \mathcal{N}(0, \sigma_u^2)`$ = physician-level random
  intercept

Total fixed-effect parameters: 1 + 1 + 2 + 1 + 1 + 1 + 11 = **18
parameters**

This is safe for $`n \geq 180`$ observations (EPV = 10).

### In R

``` r
nb_full <- mysterycall_nb_model(
  data             = mc_data,
  outcome          = "wait_days",
  predictors       = c("insurance", "scenario",
                        "physician_gender", "practice_setting",
                        "urbanicity", "acog_district"),
  random_intercept = "npi"
)

print(nb_full)
mysterycall_irr_plot(nb_full)
mysterycall_format_results_table(nb_full)
```

### Comparing models with AIC

Use
[`mysterycall_select_best_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_select_best_model.md)
to compare the base and full specifications:

``` r
nb_base <- mysterycall_nb_model(
  mc_data, "wait_days",
  predictors       = c("insurance", "scenario"),
  random_intercept = "npi"
)

mysterycall_select_best_model(
  list(base = nb_base, full = nb_full),
  method = "AIC"
)
```

Choose the model with the lowest AIC. If the full model AIC is more than
2–4 units lower, the covariates improve fit enough to retain. If the AIC
is higher (over-fitting), drop the least-theoretically-motivated
variable first.

------------------------------------------------------------------------

## Effect on power: how covariates reduce required sample size

Adding covariates that genuinely explain variance in the outcome reduces
the **residual standard deviation** $`\sigma`$. The power formula for
detecting an IRR of $`\delta`$ is approximately:

``` math
n \approx \frac{2\sigma^2 (z_{\alpha/2} + z_\beta)^2}{(\log \delta)^2}
```

If a covariate reduces $`\sigma`$ by 15%, the required $`n`$ falls by
$`\approx 28\%`$ ($`1 - 0.85^2`$).

| Covariates added | Variance explained (R²) | Residual SD vs. baseline | Physicians needed (per group) |
|:---|:---|:---|---:|
| None (insurance + scenario only) | 0% | baseline | 48 |
| Add gender + setting | 10% | -5% | 43 |
| Add urbanicity | 13% | -7% | 42 |
| Add setting + ACOG district | 20% | -11% | 38 |
| Full model (all above) | 30% | -16% | 34 |

Approximate power analysis: detecting a 25% IRR difference (80% power, α
= 0.05), assuming baseline SD ≈ 30 days.

**Important caveats:**

1.  The R² figures are estimates. Whether a given covariate *actually*
    explains 10% or 2% of variance depends on your data. Check
    `1 - (residual variance with covariate) / (residual variance without)`
    after fitting both models.
2.  Adding a covariate that explains little variance increases
    parameters without reducing noise — effectively *hurting* power.
3.  The EPV constraint is binding: if adding a covariate drops EPV below
    10, you need more physicians before you can include it.

------------------------------------------------------------------------

## Decision checklist before adding a covariate

| Question | If yes → | If no → |
|----|----|----|
| Is it available for all (or nearly all) physicians? | Include it | Impute or exclude |
| Does it explain ≥ 5% of residual variance (from literature or pilot data)? | Include it | Drop it |
| Does EPV remain ≥ 10 after adding it? | Safe to include | Aggregate or exclude |
| Is it a primary hypothesis variable? | Include regardless | Depends on variance explained |
| Does AIC improve by ≥ 2 after adding it? | Keep it | Consider dropping |

------------------------------------------------------------------------

## Complete workflow

``` r
library(mysterycall)

# 1. Pull NPI registry data
clin <- mysterycall_get_clinician_data(npi_list = mc_data$npi)
mc_data <- dplyr::left_join(mc_data, clin, by = "npi")

# 2. Derive physician covariates
mc_data$practice_setting <- mysterycall_classify_practice_setting(mc_data$org_name)
mc_data$urbanicity       <- mysterycall_classify_ruca(mc_data$ruca_code)
mc_data$acog_district    <- mysterycall_assign_region(mc_data$state, type = "acog")

# 3. Fit base Poisson to check overdispersion
base_poi <- mysterycall_poisson_model(
  mc_data, "wait_days",
  predictors       = c("insurance", "scenario"),
  random_intercept = "npi"
)
base_poi$overdispersion  # if > 2, switch to NB

# 4. Fit NB with covariates
nb_full <- mysterycall_nb_model(
  mc_data, "wait_days",
  predictors       = c("insurance", "scenario",
                        "practice_setting", "urbanicity", "acog_district"),
  random_intercept = "npi"
)
# EPV and overdispersion warnings fire automatically if thresholds are crossed

# 5. Compare models
mysterycall_select_best_model(
  list(poisson_base = base_poi, nb_full = nb_full),
  method = "AIC"
)

# 6. Report results
print(nb_full)
mysterycall_irr_plot(nb_full)
mysterycall_write_results_paragraph(nb_full, ref_group = "BCBS", exposure_col = "insurance")
```

------------------------------------------------------------------------

## See also

- [`vignette("statistical-analysis")`](https://mufflyt.github.io/mysterycall/articles/statistical-analysis.md)
  — base Poisson and NB model workflow
- [`vignette("power-analysis")`](https://mufflyt.github.io/mysterycall/articles/power-analysis.md)
  — full power calculation and sample-size planning
- [`vignette("provider-classification")`](https://mufflyt.github.io/mysterycall/articles/provider-classification.md)
  — detail on
  [`mysterycall_classify_practice_setting()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_classify_practice_setting.md)
  and related helpers
- \[mysterycall_poisson_model()\], \[mysterycall_nb_model()\] — model
  fitting functions
- \[mysterycall_select_best_model()\] — AIC / BIC / LRT model comparison
- \[mysterycall_classify_practice_setting()\],
  \[mysterycall_classify_ruca()\], \[mysterycall_assign_region()\] —
  covariate derivation
