# Check Normality and Summarize Data

Checks the normality of a variable using the Shapiro-Wilk test, returns
summary statistics, and—crucially—generates a manuscript-ready
`$interpretation` sentence that identifies count data and recommends
Poisson regression when appropriate.

## Usage

``` r
mysterycall_check_normality(
  data,
  variable,
  outcome_label = NULL,
  group_label = NULL
)
```

## Arguments

- data:

  A dataframe containing the data.

- variable:

  A string specifying the column name of the variable to be checked and
  summarized.

- outcome_label:

  Optional character scalar. Human-readable label for the outcome used
  in the interpretation sentence (e.g., `"days until appointment"`).
  Defaults to `variable`.

- group_label:

  Optional character scalar. Human-readable label for the grouping
  variable used in the interpretation sentence (e.g.,
  `"insurance type"`). Defaults to `"the grouping variable"`.

## Value

A named list containing:

- `is_normal`:

  Logical. `TRUE` if Shapiro-Wilk p \> 0.05.

- `p_value`:

  Numeric. Shapiro-Wilk p-value.

- `w_statistic`:

  Numeric. Shapiro-Wilk W statistic.

- `is_count`:

  Logical. `TRUE` if all non-missing values are non-negative integers —
  heuristic for count outcomes.

- `mean`, `sd`:

  Numeric scalars (present when `is_normal = TRUE`).

- `median`, `iqr`:

  Numeric scalars (present when `is_normal = FALSE`).

- `interpretation`:

  Character scalar. A single manuscript-ready paragraph describing the
  distribution and, for non-normal count data, recommending Poisson
  regression over t-test or Kruskal-Wallis.

Side effects: emits a histogram + density plot and a Q-Q plot.

## Interpretation sentence

When the data are **not normally distributed** and **consist of counts**
(non-negative integers), the returned sentence reads:

*"The data is not normally distributed (Shapiro-Wilk W = X, p = Y). Plus
it is count data. t-test assumes that data is normally distributed, and
comparing the means of count data is also not appropriate. We can check
the incidence rate ratio (IRR) for comparison of outcome among the
categories of
[group](https://ggplot2.tidyverse.org/reference/aes_group_order.html).
Better to use Poisson regression."*

## See also

[`mysterycall_simple_poisson()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_simple_poisson.md)
for the Poisson model this function recommends;
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md)
for downstream variable standardization.

Other modeling helpers:
[`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md),
[`mysterycall_interaction_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_interaction_screen.md),
[`mysterycall_overdispersion_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_overdispersion_sentence.md),
[`mysterycall_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_interaction.md),
[`mysterycall_r2_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_r2_sentence.md),
[`mysterycall_random_effect_variance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_random_effect_variance.md),
[`mysterycall_univariate_lmm_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_lmm_screen.md),
[`mysterycall_univariate_poisson_screen()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_univariate_poisson_screen.md)

## Examples

``` r
sample_data <- data.frame(
  business_days_until_appointment = c(1L, 3L, 2L, 5L, 0L, 4L, 7L, 2L, 1L, 14L)
)
result <- mysterycall_check_normality(
  sample_data, "business_days_until_appointment",
  outcome_label = "days until appointment",
  group_label   = "insurance type"
)
#> Normality check for 'business_days_until_appointment': n = 10
#> Not normally distributed. Median = 2.5, IQR = 3.5 [count data — Poisson recommended]
#> The data is not normally distributed (Shapiro-Wilk W = 0.813, p = 0.021). Plus it is count data. t-test assumes that data is normally distributed, and comparing the means of count data is also not appropriate. We can check the incidence rate ratio (IRR) for comparison of days until appointment among the categories of insurance type. Better to use Poisson regression. Median days until appointment: 2.5 (IQR: 3.5).
cat(result$interpretation)
#> The data is not normally distributed (Shapiro-Wilk W = 0.813, p = 0.021). Plus it is count data. t-test assumes that data is normally distributed, and comparing the means of count data is also not appropriate. We can check the incidence rate ratio (IRR) for comparison of days until appointment among the categories of insurance type. Better to use Poisson regression. Median days until appointment: 2.5 (IQR: 3.5).
```
