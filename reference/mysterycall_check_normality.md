# Check Normality and Summarize Data

This function checks the normality of a specified variable in a
dataframe using the Shapiro-Wilk test and provides summary statistics
(mean and standard deviation if normal, median and IQR if not normal).

## Usage

``` r
mysterycall_check_normality(data, variable)
```

## Arguments

- data:

  A dataframe containing the data.

- variable:

  A string specifying the column name of the variable to be checked and
  summarized.

## Value

A named list with either:

- mean, sd:

  Numeric scalars (if Shapiro-Wilk p \> 0.05, data approximately
  normal).

- median, iqr:

  Numeric scalars (if Shapiro-Wilk p \<= 0.05, data non-normal).

Also emits a histogram + density plot and a Q-Q plot via side effects.

## See also

[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md)
for downstream variable standardization;
[`mysterycall_physician_age()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physician_age.md)
for age summary statistics.

Other modeling helpers:
[`mysterycall_create_formula()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_create_formula.md),
[`mysterycall_plot_interaction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_plot_interaction.md)

## Examples

``` r
sample_data <- data.frame(
  business_days_until_appointment = c(1.5, 2.0, 1.8, 2.2, 1.9, 2.1, 2.3)
)
mysterycall_check_normality(sample_data, "business_days_until_appointment")
#> Error in mysterycall_check_normality(sample_data, "business_days_until_appointment"): could not find function "mysterycall_check_normality"
```
