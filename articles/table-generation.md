# Generating Publication Tables

``` r

library(mysterycall)
```

------------------------------------------------------------------------

## 1. Overview: Tables a Mystery-Caller Manuscript Needs

A completed mystery-caller study typically requires four tables for
publication. Understanding what each table communicates — and to whom —
is the first step in building it correctly.

**Table 1 — Baseline characteristics of the provider sample** This is
the standard descriptive table found in every observational study. It
describes the providers who were *sampled*, not the outcomes of the
calls. Rows are provider characteristics (specialty, gender, practice
setting, urban vs. rural classification). Columns are the study strata
(usually insurance type: Medicaid vs. private insurance, or some broader
grouping). Journals such as NEJM and JAMA expect Table 1 to appear
before the results section and to demonstrate that the sampling was
balanced or to quantify imbalances that readers should bear in mind.

**Table 2 — Appointment acceptance rates by insurance type** This is the
disparity table. Its primary purpose is to show whether providers were
significantly more or less likely to offer an appointment to a Medicaid
caller than to a private-insurance caller. Each row is typically a
provider subgroup (subspecialty, region, practice type). Cells contain
appointment acceptance rates with 95% confidence intervals. An adjusted
odds ratio or risk ratio from a logistic or Poisson regression model
appears alongside.

**Table 3 — Wait times by subspecialty (or insurance type)** For studies
that record how many days until the next available appointment, Table 3
summarizes the wait-time distribution. Because wait times are
right-skewed and often overdispersed, medians and interquartile ranges
are more appropriate than means and standard deviations, and Poisson or
negative binomial model summaries are often reported alongside.

**Disparity supplement table** Many journals request a supplementary
table reporting fully adjusted model estimates for every covariate, not
just the primary insurance-type comparison. This table is typically
formatted as a forest-plot data source and exported to CSV for the
journal’s online supplement.

**Prerequisite:**
[`mysterycall_prepare_table1_vars()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_table1_vars.md)
(documented in the provider-classification vignette) must be run before
calling any of the table functions in this vignette. That function
creates the standardized columns (`age_category`, `gender_std`,
`ruca_category`, `region_std`) that the table functions expect.

------------------------------------------------------------------------

## 2. Table 1 with Base R: `mysterycall_table1()`

[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md)
produces a publication-ready Table 1 using only base R and the `arsenal`
package. It is the recommended function when you want precise control
over every cell and need output that can be exported to any format
(HTML, PDF, Word, plain text).

### 2.1 Building a synthetic provider data frame

Throughout this vignette we use a 200-row synthetic data frame that
mirrors the structure of a real mystery-caller study analysis file.

``` r

set.seed(2024)
n <- 200

analysis_data <- data.frame(
  # Provider characteristics
  age_category      = sample(c("< 40", "40-49", "50-59", "60+"),
                             n, replace = TRUE,
                             prob = c(0.20, 0.35, 0.30, 0.15)),
  gender_std        = sample(c("Female", "Male"),
                             n, replace = TRUE, prob = c(0.55, 0.45)),
  subspecialty      = sample(
    c("General OB/GYN", "Urogynecology", "Gynecologic Oncology",
      "Maternal-Fetal Medicine", "Reproductive Endocrinology"),
    n, replace = TRUE,
    prob = c(0.45, 0.15, 0.15, 0.15, 0.10)
  ),
  practice_setting  = sample(c("Academic", "Private", "Community Health Center",
                               "Hospital-Based"),
                             n, replace = TRUE,
                             prob = c(0.30, 0.40, 0.15, 0.15)),
  region_std        = sample(c("Northeast", "Midwest", "South", "West"),
                             n, replace = TRUE,
                             prob = c(0.22, 0.26, 0.36, 0.16)),
  ruca_category     = sample(c("Urban", "Large Rural", "Small Rural", "Isolated"),
                             n, replace = TRUE,
                             prob = c(0.75, 0.12, 0.08, 0.05)),

  # Call outcome variables
  insurance_type    = sample(c("Medicaid", "Private"),
                             n, replace = TRUE),
  appt_offered      = sample(c("Yes", "No", NA_character_),
                             n, replace = TRUE, prob = c(0.60, 0.35, 0.05)),
  wait_days         = pmax(0L, as.integer(
    ifelse(runif(n) < 0.05, NA_integer_,
           round(rnorm(n, mean = 18, sd = 12)))
  ))
)
```

### 2.2 Full parameter documentation

``` r

tbl1 <- mysterycall_table1(
  data             = analysis_data,
  covariates       = c("age_category", "gender_std", "subspecialty",
                       "practice_setting", "region_std", "ruca_category"),
  stratify_by      = "insurance_type",
  include_overall  = TRUE,
  cont_stats       = "median_iqr",    # "mean_sd", "median_iqr", or c("mean_sd","median_iqr")
  digits           = 1,               # decimal places for percentages
  p_value          = TRUE,            # adds chi-sq / Kruskal-Wallis p-value column
  min_cell         = 5,               # use Fisher's exact test when expected cell < 5
  variable_labels  = c(
    age_category     = "Provider age, years",
    gender_std       = "Physician sex",
    subspecialty     = "Subspecialty",
    practice_setting = "Practice setting",
    region_std       = "US Census region",
    ruca_category    = "Rurality (RUCA category)"
  )
)

print(tbl1)
```

**Parameter details:**

**`covariates`** — a character vector of column names that will appear
as row groups in the table. The function detects whether each variable
is continuous (numeric or integer with \> 5 unique values) or
categorical (factor or character, or numeric with ≤ 5 unique values) and
formats accordingly.

**`stratify_by`** — the column whose unique values become the
stratification columns. Pass `NULL` to generate an unstratified table
with a single “Overall” column.

**`include_overall`** — when `TRUE`, a column labelled “Overall” is
prepended to the stratification columns, showing counts and percentages
across the full sample regardless of stratum.

**`cont_stats`** — controls how continuous variables (e.g., `wait_days`)
are summarized: \* `"mean_sd"`: Mean ± SD, appropriate when the
distribution is approximately normal. \* `"median_iqr"`: Median \[IQR\],
appropriate for right-skewed variables like wait times. \*
`c("mean_sd", "median_iqr")`: Both rows are printed. Useful in
supplements or data-quality tables but rarely appropriate for a primary
manuscript table.

**`p_value`** — when `TRUE`, a column of p-values is appended. For
categorical variables, the function runs a Pearson chi-squared test; if
any expected cell count is below `min_cell`, it switches to Fisher’s
exact test. For continuous variables, it runs a Kruskal-Wallis test
(regardless of whether `cont_stats` is `"mean_sd"` or `"median_iqr"`)
because mystery-caller data rarely satisfy the normality assumptions
required for a standard t-test or ANOVA.

**Interpreting p-values in this context:** In a mystery-caller study,
the p-values in Table 1 test whether the *sampling* was balanced by
insurance type. They do not test the primary hypothesis (appointment
disparity). A significant p-value in Table 1 means that providers
assigned to the Medicaid and private-insurance call scenarios differ on
that characteristic, which is relevant if the split was done by
something other than
[`mysterycall_split_and_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_split_and_save.md).
If the split was random (as it should be), all Table 1 p-values should
be non-significant.

**`variable_labels`** — a named character vector where names are column
names in `data` and values are the display labels that appear in the
table. This is where you translate snake_case column names to the
mixed-case, abbreviation-spelled-out labels that journals require.

**`min_cell`** — default 5, following the standard Fisher’s exact test
threshold used in most biostatistics textbooks. For subspecialty
comparisons with rare specialties (e.g., Reproductive Endocrinology
appears in \< 5% of rows), this threshold will trigger Fisher’s exact
test automatically. Note that the function prints a message when it
switches tests:

    # Note: Using Fisher's exact test for 'subspecialty' (minimum expected
    # cell count = 2.3, below threshold of 5).

### 2.3 A note on categorical vs. continuous detection

[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md)
classifies variables automatically, but you can override this by
converting columns to the appropriate type before calling the function:

``` r

# Force wait_days to be treated as continuous (it has many unique values
# but is stored as integer, so auto-detection is correct here)
# Force age_category to be treated as categorical even though it looks ordinal
analysis_data$age_category <- factor(
  analysis_data$age_category,
  levels = c("< 40", "40-49", "50-59", "60+"),
  ordered = TRUE
)
```

------------------------------------------------------------------------

## 3. Table 1 with gtsummary: `mysterycall_table1_gtsummary()`

`gtsummary` produces richer formatted output than the base-R approach
and integrates directly with Word, HTML, and PDF export pipelines. Use
it when:

- You need publication-quality HTML output for a journal submission
  system that accepts HTML tables.
- You are preparing a Word document for collaborators who will
  copy-paste the table into a manuscript template.
- You want `bold_labels()`, `add_n()`, `add_overall()`, or other
  gtsummary modifiers without writing custom formatting code.

Use
[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md)
(Section 2) when you need a plain-text or PDF output with
`arsenal`-style formatting, or when you need a p-value column that falls
back to Fisher’s exact test automatically.

### 3.1 Parameters

``` r

tbl1_gt <- mysterycall_table1_gtsummary(
  data         = analysis_data,
  vars         = c("age_category", "gender_std", "subspecialty",
                   "practice_setting", "region_std", "ruca_category"),
  strata_col   = "insurance_type",
  label_list   = list(
    age_category     ~ "Provider age, years",
    gender_std       ~ "Physician sex",
    subspecialty     ~ "Subspecialty",
    practice_setting ~ "Practice setting",
    region_std       ~ "US Census region",
    ruca_category    ~ "Rurality (RUCA category)"
  ),
  missing      = "no",     # "no" = omit missing row; "ifany" = show if any missing
  percent      = "column", # "column" (default), "row", or "cell"
  overall_last = TRUE      # place Overall column after strata, not before
)
```

**`label_list`** uses a formula syntax (`variable ~ "Label"`) rather
than a named vector. This is the gtsummary convention and supports more
complex label specifications (e.g., multi-line labels).

**`missing`** — `"no"` omits the “Unknown” row from the table, which is
appropriate when your protocol treats missing data as MCAR and you have
imputed or excluded missing rows before building the table. Use
`"ifany"` when you want readers to see the extent of missing data, which
is appropriate for a supplement table but unusual in a primary
manuscript table.

**`percent`** — `"column"` is almost always correct for Table 1. Column
percentages show what fraction of Medicaid-assigned providers fall into
each category, which is what readers need to assess balance. Row
percentages would show what fraction of female physicians were assigned
to Medicaid vs. private insurance, which is usually not the estimand of
interest in Table 1.

### 3.2 Chaining gtsummary modifiers

The returned object is a standard
[`gtsummary::tbl_summary`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
object and accepts all gtsummary modifiers:

``` r

tbl1_gt |>
  gtsummary::bold_labels() |>           # bold the variable name rows
  gtsummary::add_n() |>                 # add total N per stratum
  gtsummary::add_p() |>                 # add chi-sq / Kruskal-Wallis p-values
  gtsummary::modify_caption(
    "**Table 1.** Baseline Characteristics of Sampled Providers by Insurance Type"
  )
```

### 3.3 Exporting to Word

``` r

tbl1_gt |>
  gtsummary::bold_labels() |>
  gtsummary::add_n() |>
  gtsummary::as_flex_table() |>
  flextable::save_as_docx(
    path = "/study/tables/table1_baseline.docx"
  )
```

The resulting `.docx` file contains a formatted table that uses the
Normal style in Word, making it straightforward to copy into a journal
manuscript template. All cell borders, bold labels, and footnotes are
preserved.

------------------------------------------------------------------------

## 4. Overall Summary Table to PDF: `mysterycall_table_overall()`

[`mysterycall_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_overall.md)
is designed for **quick quality-assurance snapshots during data
collection**, not for publication. It reads an RDS file (or a data
frame), generates an
[`arsenal::tableby()`](https://mayoverse.github.io/arsenal/reference/tableby.html)
summary, and writes a PDF to disk in a single call. It is the fastest
way to answer the question “What does our dataset look like right now?”
at the weekly coordinator check-in meeting.

### 4.1 When to use `table_overall` vs. `mysterycall_table1()`

| Situation | Recommended function |
|----|----|
| Weekly QA check-in during data collection | [`mysterycall_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_overall.md) |
| Final manuscript Table 1 | [`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md) or [`mysterycall_table1_gtsummary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1_gtsummary.md) |
| Need Fisher’s exact test fallback | [`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md) |
| Need Word / HTML output | [`mysterycall_table1_gtsummary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1_gtsummary.md) |
| Need to share PDF with non-R users quickly | [`mysterycall_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_overall.md) |

### 4.2 Parameters and example

``` r

mysterycall_table_overall(
  input_file_path   = "/study/phase2_output/analysis_ready.rds",
  output_directory  = "/study/tables/qa",
  title             = "Mystery Caller Study — QA Snapshot 2024-03-15",
  selected_columns  = c("age_category", "gender_std", "subspecialty",
                        "practice_setting", "region_std", "ruca_category",
                        "appt_offered", "wait_days"),
  label_translations = c(
    age_category     = "Provider age",
    gender_std       = "Physician sex",
    appt_offered     = "Appointment offered",
    wait_days        = "Days until next appointment"
  )
)
#> Writing QA table to /study/tables/qa/qa_snapshot_20240315.pdf
#> Done. Table has 8 variables and 1688 observations.
```

`label_translations` is a named character vector that maps column names
to display labels. Unlike
[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md),
this function does not accept a formula interface — use the named-vector
syntax.

------------------------------------------------------------------------

## 5. Percentage Tables: `mysterycall_table_percentages()`

[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md)
produces cross-tabulation tables with row-wise or column-wise
percentages and optional 95% confidence intervals. It is most often used
to build Table 2 — appointment acceptance rates broken down by insurance
type and provider subgroup.

### 5.1 Row vs. column percentages

In a mystery-caller disparity study:

- **Row percentages** — “Of the Medicaid calls to Female physicians,
  what percent were offered an appointment?” This is the most intuitive
  framing for Table 2 and is the default (`direction = "row"`).
- **Column percentages** — “Of all the calls that resulted in an
  appointment offer, what percent were Medicaid calls?” This is useful
  for understanding the composition of the contacted sample but is
  rarely the primary estimand.

### 5.2 Example: appointment offered by insurance type

``` r

pct_tbl <- mysterycall_table_percentages(
  data        = analysis_data[!is.na(analysis_data$appt_offered), ],
  row_var     = "subspecialty",
  col_var     = "insurance_type",
  outcome_var = "appt_offered",
  outcome_val = "Yes",      # the value that counts as "success"
  direction   = "row",
  conf_level  = 0.95,
  digits      = 1
)

knitr::kable(
  pct_tbl,
  caption = "Table 2. Appointment Acceptance Rate (%) by Subspecialty and Insurance Type"
)
```

The output data frame contains one row per subspecialty with columns:

| Column         | Description                              |
|----------------|------------------------------------------|
| `subspecialty` | Row label                                |
| `Medicaid_n`   | Number of Medicaid calls completed       |
| `Medicaid_pct` | % offered appointment (Medicaid callers) |
| `Medicaid_CI`  | 95% CI for Medicaid percentage           |
| `Private_n`    | Number of Private calls completed        |
| `Private_pct`  | % offered appointment (Private callers)  |
| `Private_CI`   | 95% CI for Private percentage            |

The 95% CIs use the Wilson score interval by default, which is
recommended for proportions near 0 or 1 and for small cell sizes — both
of which are common in subspecialty subgroups of mystery-caller studies.

------------------------------------------------------------------------

## 6. Proportion Tables: `mysterycall_table_proportion()`

[`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md)
is closely related to
[`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md)
but reports the numerator *N* and the proportion as a fraction
side-by-side, rather than combining them into a formatted “60.2% (95%
CI: 52.1% to 67.9%)” string. This format is required by some journals
(particularly JAMA-network journals) that prefer separate columns for N
and proportion.

### 6.1 Difference from percentage tables

| Function | Output cell format |
|----|----|
| [`mysterycall_table_percentages()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_percentages.md) | `"60.2% (95% CI: 52.1–67.9%)"` |
| [`mysterycall_table_proportion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_proportion.md) | `n = 89`, `proportion = 0.602` |

The proportion format also facilitates downstream statistical
programming: you can feed `n` and `proportion` directly into
[`prop.test()`](https://rdrr.io/r/stats/prop.test.html) or a
meta-analysis function without parsing formatted strings.

### 6.2 Example: wait-time category by subspecialty

``` r

# Create a wait-time category
analysis_data$wait_category <- cut(
  analysis_data$wait_days,
  breaks  = c(-Inf, 7, 14, 28, Inf),
  labels  = c("< 1 week", "1-2 weeks", "2-4 weeks", "> 4 weeks"),
  right   = TRUE
)

prop_tbl <- mysterycall_table_proportion(
  data        = analysis_data[!is.na(analysis_data$wait_days), ],
  row_var     = "wait_category",
  col_var     = "subspecialty",
  conf_level  = 0.95
)

knitr::kable(
  prop_tbl,
  caption = "Table 3. Wait-Time Category by Subspecialty (N and proportion)"
)
```

------------------------------------------------------------------------

## 7. Disparity Table for a Manuscript: `mysterycall_disparities_table()`

The disparity table is the centerpiece of a mystery-caller manuscript.
It reports the primary statistical comparison — whether Medicaid callers
were significantly less likely to be offered an appointment than
private-insurance callers — with full model-based adjustment for
provider characteristics.

The statistical modelling that produces the estimates underlying this
table is documented in the statistics vignette. This section focuses
exclusively on **formatting** the disparity table for publication.

### 7.1 Printing with a bold reference row

Many journals require that the reference category within each
categorical variable be labelled clearly (e.g., “Ref.” in the OR column
and bold text in the variable label).
[`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) does not
support conditional bold formatting natively, but the `kableExtra`
package does:

``` r

library(kableExtra)

# Assume 'disparity_result' is the output of mysterycall_disparities_table()
disp_tbl <- disparity_result$formatted_table

# Identify the reference rows (OR == "Ref." or 1.00 with no CI)
ref_rows <- which(disp_tbl$adjusted_or == "Ref.")

knitr::kable(
  disp_tbl,
  col.names = c("Variable", "Category", "Medicaid %",
                "Private %", "Adjusted OR", "95% CI", "p-value"),
  caption   = "Table 2. Adjusted Odds Ratios for Appointment Acceptance by Insurance Type"
) |>
  kableExtra::kable_styling(full_width = FALSE) |>
  kableExtra::row_spec(ref_rows, bold = TRUE, italic = TRUE) |>
  kableExtra::footnote(
    general = "OR = odds ratio; CI = confidence interval. Reference categories
    shown in bold italics. Models adjusted for physician sex, subspecialty,
    practice setting, US Census region, and rurality (RUCA category).",
    threeparttable = TRUE
  )
```

### 7.2 Adding significance stars

Some journals — and all conference poster sessions — expect significance
stars (\* p \< 0.05; \*\* p \< 0.01; \*\*\* p \< 0.001) alongside
adjusted p-values. Add them as a separate column after extracting
numeric p-values:

``` r

# Extract numeric p-values (assumes a 'p_numeric' column in the result)
disp_tbl$stars <- dplyr::case_when(
  disp_tbl$p_numeric < 0.001 ~ "***",
  disp_tbl$p_numeric < 0.01  ~ "**",
  disp_tbl$p_numeric < 0.05  ~ "*",
  TRUE                        ~ ""
)

# Combine with formatted p-value for display
disp_tbl$p_display <- paste0(
  formatC(disp_tbl$p_numeric, format = "f", digits = 3),
  disp_tbl$stars
)
```

Note: Some journals (including NEJM and JAMA) explicitly prohibit
significance stars in favour of exact p-values. Check the target
journal’s instructions for authors before adding stars.

### 7.3 Exporting to CSV for a journal supplement

The online supplement of a disparity manuscript typically requires a
machine-readable version of the full adjusted model results:

``` r

# Export the full disparity table to CSV for the supplement
write.csv(
  disp_tbl,
  file      = "/study/tables/supplement_table_S1_disparity.csv",
  row.names = FALSE,
  na        = ""    # journals prefer empty strings to "NA" in CSV supplements
)

# Optionally, also write an Excel version for non-R collaborators
openxlsx::write.xlsx(
  disp_tbl,
  file       = "/study/tables/supplement_table_S1_disparity.xlsx",
  sheetName  = "Disparity Table",
  colNames   = TRUE,
  rowNames   = FALSE
)
```

------------------------------------------------------------------------

## 8. Exporting Tables to PDF: `mysterycall_write_table_pdf()`

[`mysterycall_write_table_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table_pdf.md)
takes an
[`arsenal::tableby`](https://mayoverse.github.io/arsenal/reference/tableby.html)
object (the internal representation produced by
[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md)
and
[`mysterycall_table_overall()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table_overall.md))
and writes a formatted PDF via R Markdown and a LaTeX engine.

### 8.1 Basic usage

``` r

mysterycall_write_table_pdf(
  object   = tbl1,        # arsenal tableby object from mysterycall_table1()
  filename = "/study/tables/table1_baseline.pdf"
)
```

### 8.2 Common issue: LaTeX not installed

The most frequent error when using this function is:

    Error in mysterycall_write_table_pdf():
      pandoc-citeproc: could not find a LaTeX installation.
      Please install a LaTeX distribution or run tinytex::install_tinytex().

The solution is to install TinyTeX, a minimal LaTeX distribution that is
sufficient for the PDF tables produced by this function:

``` r

# Install TinyTeX (one-time setup, ~200 MB download)
install.packages("tinytex")
tinytex::install_tinytex()

# Then re-run the table export
mysterycall_write_table_pdf(
  object   = tbl1,
  filename = "/study/tables/table1_baseline.pdf"
)
```

If you are working in a restricted computing environment where LaTeX
cannot be installed (e.g., a hospital IT-managed machine), use the HTML
alternative.

### 8.3 Alternative: export to HTML with `knitr::kable()`

``` r

# knitr::kable() does not require LaTeX
html_table <- knitr::kable(
  as.data.frame(summary(tbl1, text = "html")),
  format  = "html",
  caption = "Table 1. Baseline Characteristics"
)

# Save to standalone HTML file
writeLines(
  c(
    "<!DOCTYPE html><html><body>",
    as.character(html_table),
    "</body></html>"
  ),
  con = "/study/tables/table1_baseline.html"
)
```

The resulting HTML file can be opened in any browser and printed to PDF
using the browser’s built-in print function (File → Print → Save as PDF
on macOS and Windows), without requiring any LaTeX installation.

------------------------------------------------------------------------

## 9. Writing the Methods and Results Paragraph: `mysterycall_write_results_paragraph()`

[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md)
generates a structured prose paragraph suitable for the Methods and
Results sections of a manuscript. It extracts key statistics from the
model result and the disparity table and formats them according to APA
7th edition number-formatting conventions (two decimal places for
statistics, three for p-values, confidence intervals in brackets).

### 9.1 Generating the paragraph

``` r

paragraph <- mysterycall_write_results_paragraph(
  model_result    = poisson_model_result,   # output of mysterycall_poisson_model()
  disparity_table = disp_tbl,              # output of mysterycall_disparities_table()
  outcome_label   = "appointment acceptance",
  insurance_var   = "insurance_type",
  ref_level       = "Private",
  alt_level       = "Medicaid"
)

cat(paragraph)
```

A typical output looks like:

    Among 1,688 completed calls to 844 unique providers, Medicaid callers were
    significantly less likely to be offered an appointment than private-insurance
    callers (59.2% vs. 72.4%; adjusted odds ratio [aOR] 0.61, 95% CI [0.51,
    0.73]; p < 0.001). This disparity persisted after adjustment for physician
    sex, subspecialty, practice setting, US Census region, and rurality
    (aOR 0.63, 95% CI [0.53, 0.75]; p < 0.001). Among subspecialties,
    the largest disparity was observed in Urogynecology (aOR 0.44, 95% CI
    [0.28, 0.70]; p < 0.001) and the smallest in Gynecologic Oncology
    (aOR 0.81, 95% CI [0.58, 1.13]; p = 0.21).

### 9.2 APA-style number formatting

The function applies the following formatting rules automatically:

- **Odds ratios and risk ratios** — two decimal places (e.g., `0.61`,
  not `0.6` or `0.613`).
- **Percentages** — one decimal place (e.g., `59.2%`).
- **p-values** — three decimal places with `< 0.001` substituted for any
  value below 0.001 (e.g., `p = 0.031`, `p < 0.001`).
- **Confidence intervals** — in square brackets with two decimal places
  (e.g., `[0.51, 0.73]`), following APA 7th edition Table 7.21.
- **Large counts** — comma-formatted (e.g., `1,688`, not `1688`).

Copy the paragraph output directly into your manuscript draft. Most
medical journal style guides are compatible with APA number formatting
for statistics; check the target journal’s instructions for authors if
you are unsure.

------------------------------------------------------------------------

## 10. Complete End-to-End Table Generation Example

This section demonstrates building all three primary manuscript tables
and exporting them, using the 200-provider synthetic data frame defined
in Section 2.1.

### 10.1 Step 0 — Prepare variables

``` r

# These preparations mirror what mysterycall_prepare_table1_vars() does
# (run that function on your real data instead)
analysis_data$age_category <- factor(
  analysis_data$age_category,
  levels = c("< 40", "40-49", "50-59", "60+")
)
analysis_data$appt_offered_binary <- as.integer(
  analysis_data$appt_offered == "Yes"
)
```

### 10.2 Step 1 — Table 1: Baseline characteristics stratified by subspecialty

``` r

table1_final <- mysterycall_table1(
  data            = analysis_data,
  covariates      = c("age_category", "gender_std", "practice_setting",
                      "region_std", "ruca_category", "insurance_type"),
  stratify_by     = "subspecialty",
  include_overall = TRUE,
  cont_stats      = "median_iqr",
  digits          = 1,
  p_value         = TRUE,
  min_cell        = 5,
  variable_labels = c(
    age_category     = "Provider age, years",
    gender_std       = "Physician sex",
    practice_setting = "Practice setting",
    region_std       = "US Census region",
    ruca_category    = "Rurality (RUCA category)",
    insurance_type   = "Insurance type assigned"
  )
)

# Export to PDF
mysterycall_write_table_pdf(
  object   = table1_final,
  filename = "/study/tables/table1_by_subspecialty.pdf"
)
```

Because we stratify by subspecialty (5 columns) with an Overall column,
the resulting table is wide. Consider using landscape orientation if
your journal allows it;
[`mysterycall_write_table_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table_pdf.md)
detects wide tables automatically and applies landscape orientation when
the number of columns exceeds 6.

### 10.3 Step 2 — Table 2: Appointment acceptance rates by insurance type

``` r

# First compute the disparity estimates
# (assumes mysterycall_poisson_model() has already been run — see stats vignette)
disparity_result <- mysterycall_disparities_table(
  data          = analysis_data[!is.na(analysis_data$appt_offered), ],
  outcome_var   = "appt_offered_binary",
  insurance_var = "insurance_type",
  ref_level     = "Private",
  covariates    = c("age_category", "gender_std", "subspecialty",
                    "practice_setting", "region_std", "ruca_category")
)

# Format and print
knitr::kable(
  disparity_result$formatted_table,
  col.names = c("Variable", "Category", "Medicaid % (n)",
                "Private % (n)", "Unadjusted OR",
                "Adjusted OR", "95% CI", "p-value"),
  caption   = paste(
    "Table 2. Appointment Acceptance Rates and Adjusted Odds Ratios",
    "by Insurance Type Among Obstetrics & Gynecology Providers"
  )
) |>
  kableExtra::kable_styling(full_width = FALSE) |>
  kableExtra::footnote(
    general = paste(
      "OR = odds ratio; CI = confidence interval.",
      "Adjusted models include physician sex, subspecialty, practice setting,",
      "US Census region, and RUCA rurality category as covariates."
    ),
    threeparttable = TRUE
  )

# Export to CSV for journal supplement
write.csv(
  disparity_result$formatted_table,
  file      = "/study/tables/table2_disparity.csv",
  row.names = FALSE,
  na        = ""
)
```

### 10.4 Step 3 — Table 3: Median wait days by insurance type

``` r

# Summarize wait times by insurance type using the Poisson model summary
# (assumes mysterycall_poisson_model() has been run — see stats vignette)
wait_summary <- analysis_data |>
  dplyr::filter(!is.na(wait_days)) |>
  dplyr::group_by(insurance_type) |>
  dplyr::summarize(
    n            = dplyr::n(),
    median_days  = median(wait_days),
    q1           = quantile(wait_days, 0.25),
    q3           = quantile(wait_days, 0.75),
    pct_gt28days = round(mean(wait_days > 28) * 100, 1),
    .groups      = "drop"
  ) |>
  dplyr::mutate(
    median_iqr = paste0(median_days, " [", q1, "–", q3, "]")
  )

knitr::kable(
  wait_summary[, c("insurance_type", "n", "median_iqr", "pct_gt28days")],
  col.names = c("Insurance Type", "N", "Median days [IQR]", "% > 28 days"),
  caption   = paste(
    "Table 3. Days to Next Available Appointment by Insurance Type",
    "(Completed Calls with Appointment Offered)"
  )
)
```

### 10.5 Step 4 — Export all three tables to PDF

``` r

# Table 1 was already exported in Step 1.
# Export Table 2 (disparity) to PDF:
mysterycall_write_table_pdf(
  object   = disparity_result$arsenal_object,
  filename = "/study/tables/table2_disparity.pdf"
)

# Table 3 (wait times) is a simple data frame, not an arsenal object;
# use knitr → rmarkdown → PDF for it:
rmarkdown::render(
  input       = "/study/scripts/table3_waittimes.Rmd",
  output_file = "/study/tables/table3_waittimes.pdf",
  params      = list(data_path = "/study/phase2_output/analysis_ready.rds")
)

message(
  "All three tables exported.\n",
  "  Table 1: /study/tables/table1_by_subspecialty.pdf\n",
  "  Table 2: /study/tables/table2_disparity.pdf\n",
  "  Table 3: /study/tables/table3_waittimes.pdf\n",
  "  Table 2 CSV supplement: /study/tables/table2_disparity.csv"
)
```

------------------------------------------------------------------------

## 11. Frequency Helpers: `mysterycall_max_table()` and `mysterycall_min_table()`

These helpers quickly identify the most- and least-common values in any
vector — useful for sanity-checking free-text columns or building
footnotes.

``` r

set.seed(3)
subspecialties <- sample(
  c("General OB/GYN", "MFM", "GYN Oncology", "REI", "FPMRS", "General OB/GYN",
    "General OB/GYN", "MFM", "General OB/GYN", "REI"),
  size = 120, replace = TRUE
)

# Most common subspecialty
cat("Most common:\n")
#> Most common:
print(mysterycall_max_table(subspecialties))
#> [1] "General OB/GYN"

# Least common subspecialty
cat("\nLeast common:\n")
#> 
#> Least common:
print(mysterycall_min_table(subspecialties))
#> [1] "GYN Oncology"
```

## 12. Formatting Percentages: `mysterycall_format_pct()`

[`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md)
converts a numeric proportion to a character string with a configurable
number of decimal places — useful for inline reporting and table cells.

``` r

rates <- c(0.91, 0.638, 0.54, 0.00, 1.00, 0.085)
knitr::kable(
  data.frame(
    raw_rate     = rates,
    formatted_1d = mysterycall_format_pct(rates, digits = 1),
    formatted_0d = mysterycall_format_pct(rates, digits = 0)
  ),
  col.names = c("Raw proportion", "1 decimal place", "0 decimal places"),
  caption   = "`mysterycall_format_pct()` output for typical acceptance rates."
)
```

| Raw proportion | 1 decimal place | 0 decimal places |
|---------------:|:----------------|:-----------------|
|          0.910 | 91.0%           | 91%              |
|          0.638 | 63.8%           | 64%              |
|          0.540 | 54.0%           | 54%              |
|          0.000 | 0.0%            | 0%               |
|          1.000 | 100.0%          | 100%             |
|          0.085 | 8.5%            | 8%               |

[`mysterycall_format_pct()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_pct.md)
output for typical acceptance rates. {.table}

------------------------------------------------------------------------

### A note on journal-specific requirements

**NEJM** — Tables must be submitted as separate files. Use
[`mysterycall_write_table_pdf()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_table_pdf.md)
for each table individually, then convert to EPS or TIFF at 600 DPI
using the journal’s figure preparation guidelines (NEJM treats tables as
figures in its online submission system). Do not embed significance
stars; report exact p-values. Confidence intervals in parentheses, not
brackets.

**JAMA and JAMA Network journals** — Accept Word or PDF. The
[`mysterycall_table1_gtsummary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1_gtsummary.md)
→
[`gtsummary::as_flex_table()`](https://www.danieldsjoberg.com/gtsummary/reference/as_flex_table.html)
→
[`flextable::save_as_docx()`](https://davidgohel.github.io/flextable/reference/save_as_docx.html)
pipeline (Section 3.3) produces JAMA-compliant Word output. JAMA
requires that Table 1 report “No.” (not “N” or “n”) as the column header
for counts.

**Obstetrics & Gynecology (Green Journal)** — Accepts Word. Prefers that
percentages be reported as whole numbers for proportions \> 10% and one
decimal place for proportions \< 10%. Set `digits = 0` in
[`mysterycall_table1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_table1.md)
and apply a custom formatting function for small proportions. The Green
Journal does not require p-values in Table 1 for randomised or balanced
designs.
