# Build a Manuscript-Ready Demographics Sentence

For each supplied column, finds the modal (most common) non-NA level,
its count, the total non-NA count, and the percentage. The results are
assembled into a single manuscript-ready sentence. Clauses for
subspecialty and credential can be suppressed by passing `NULL` to the
corresponding column argument.

## Usage

``` r
mysterycall_demographics_sentence(
  data,
  gender_col = "gender",
  subspecialty_col = "Subspecialty",
  credential_col = "Provider.Credential.Text",
  digits = 1L,
  label_gender = "physician gender",
  label_subspecialty = "subspecialty",
  label_credential = "professional qualification"
)
```

## Arguments

- data:

  A data frame.

- gender_col:

  Character scalar. Column name for physician gender. Default
  `"gender"`.

- subspecialty_col:

  Character scalar or `NULL`. Column name for subspecialty. Pass `NULL`
  to omit that clause. Default `"Subspecialty"`.

- credential_col:

  Character scalar or `NULL`. Column name for professional
  credential/qualification. Pass `NULL` to omit. Default
  `"Provider.Credential.Text"`.

- digits:

  Integer. Decimal places for percentages. Default `1`.

- label_gender:

  Character. Human-readable label for the gender clause. Default
  `"physician gender"`.

- label_subspecialty:

  Character. Human-readable label for the subspecialty clause. Default
  `"subspecialty"`.

- label_credential:

  Character. Human-readable label for the credential clause. Default
  `"professional qualification"`.

## Value

A character scalar (the sentence, visibly). The per-column summary
statistics are attached as attribute `"stats"` (a named list with
elements `$gender`, `$subspecialty`, `$credential`, each a list with
fields `level`, `count`, `total`, `pct`). Invisibly, the full named list
is also available via `attr(result, "stats")`.

## See also

Other descriptive helpers:
[`mysterycall_descriptive_stats()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_descriptive_stats.md),
[`mysterycall_distribution_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_distribution_summary.md),
[`mysterycall_facet_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_facet_histogram.md),
[`mysterycall_log_histogram()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_histogram.md),
[`mysterycall_physicians_with_detail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_physicians_with_detail.md),
[`mysterycall_scenario_coverage()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_coverage.md),
[`mysterycall_scenario_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_scenario_summary.md),
[`mysterycall_sensitivity_both_insurance()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_sensitivity_both_insurance.md)

## Examples

``` r
df <- data.frame(
  gender                   = c("Male", "Male", "Female", "Male"),
  Subspecialty             = c("REI", "MFM", "REI", "REI"),
  Provider.Credential.Text = c("MD", "DO", "MD", "MD"),
  stringsAsFactors = FALSE
)
sent <- mysterycall_demographics_sentence(df)
#> In our dataset, the most common physician gender was Male (n = 3/N = 4, 75.0%). Additionally, the predominant subspecialty observed was REI (n = 3/N = 4, 75.0%). Additionally, the most prevalent professional qualification was MD (n = 3/N = 4, 75.0%).
cat(sent)
#> In our dataset, the most common physician gender was Male (n = 3/N = 4, 75.0%). Additionally, the predominant subspecialty observed was REI (n = 3/N = 4, 75.0%). Additionally, the most prevalent professional qualification was MD (n = 3/N = 4, 75.0%).
```
