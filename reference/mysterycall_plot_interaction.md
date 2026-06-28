# Create and plot interaction effects from a Poisson GLMM

Reads an `.rds` dataset, fits a Poisson generalized linear mixed model
with an interaction term, and saves a publication-ready interaction
plot.

## Usage

``` r
mysterycall_plot_interaction(
  data_path,
  response_variable,
  variable_of_interest,
  interaction_variable,
  random_intercept,
  output_path,
  resolution = 100
)
```

## Arguments

- data_path:

  A character string specifying the path to the .rds file containing the
  dataset.

- response_variable:

  A character string specifying the name of the response variable in the
  dataset.

- variable_of_interest:

  A character string specifying the first categorical predictor variable
  in the interaction.

- interaction_variable:

  A character string specifying the second categorical predictor
  variable in the interaction.

- random_intercept:

  A character string specifying the variable to be used as the random
  intercept in the model (e.g., "city").

- output_path:

  A character string specifying the directory where the interaction plot
  will be saved.

- resolution:

  Integer DPI used when saving the plot. Defaults to `100`.

## Value

A named list with two elements:

- `model`:

  The fitted [`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html)
  model object (class `glmerMod`).

- `effects_plot_data`:

  A data frame with one row per `interaction_variable` x
  `variable_of_interest` combination and columns named after those two
  arguments plus `mean_pred` (numeric mean predicted response on the
  link scale).

A PNG file is also written to `output_path` as a side effect.

## Details

The function:

1.  loads data from `data_path`,

2.  standardizes selected columns for modeling,

3.  fits `response ~ interaction + (1 | random_intercept)` with a
    Poisson link,

4.  computes grouped mean predicted responses, and

5.  writes a PNG plot to `output_path`.

Use this helper when comparing how two categorical predictors jointly
relate to a count-like outcome (for example, business days until
appointment).

## See also

[`mysterycall_plot_emmeans()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_emmeans.md),
[`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md)

Other modeling helpers:
[`mysterycall_check_normality()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_check_normality.md),
[`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md),
[`mysterycall_interaction_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_screen.md),
[`mysterycall_overdispersion_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_sentence.md),
[`mysterycall_r2_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_r2_sentence.md),
[`mysterycall_random_effect_variance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_random_effect_variance.md),
[`mysterycall_univariate_lmm_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_lmm_screen.md),
[`mysterycall_univariate_poisson_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_poisson_screen.md)

## Examples

``` r
if (FALSE) { # interactive()
# Example 1: Analyzing the effect of gender and appointment center on wait times
result <- mysterycall_plot_interaction(
  data_path = "Ari/data/Phase2/late_phase_2_ENT_analysis_3.rds",
  response_variable = "business_days_until_appointment",
  variable_of_interest = "central_number_e_g_appointment_center",
  interaction_variable = "gender",
  random_intercept = "city",
  output_path = "Ari/data/figures",
  resolution = 100
)

# Example 2: Examining the interaction between insurance type and scenario on appointment delays
result <- mysterycall_plot_interaction(
  data_path = "data/healthcare_calls.rds",
  response_variable = "business_days_until_appointment",
  variable_of_interest = "insurance_type",
  interaction_variable = "scenario",
  random_intercept = "state",
  output_path = "figures/insurance_scenario_interaction",
  resolution = 150
)

# Example 3: Studying the interaction between gender and subspecialty in wait times
result <- mysterycall_plot_interaction(
  data_path = "data/mystery_caller_study.rds",
  response_variable = "waiting_time_days",
  variable_of_interest = "subspecialty",
  interaction_variable = "gender",
  random_intercept = "clinic_id",
  output_path = "results/waiting_times",
  resolution = 300
)
}
```
