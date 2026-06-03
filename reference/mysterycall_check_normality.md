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
#> Starting normality check and summary calculation for variable: business_days_until_appointment
#> Data extracted for variable: business_days_until_appointment
#> Shapiro-Wilk normality test completed with p-value: 0.873269208208328
#> The p-value is greater than 0.05, indicating that the data is approximately normal.
#> Histogram with Density Plot created.
#> Q-Q Plot created.
#> Data is approximately normal. Mean: 1.97142857142857, SD: 0.26903708365382
#> $mean[1] 1.971429$sd[1] 0.2690371
#> Summary calculation completed for variable: business_days_until_appointment
#> $mean
#> [1] 1.971429
#> 
#> $sd
#> [1] 0.2690371
#> 
```
