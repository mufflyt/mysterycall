# Writing the Results Section

## Why generate Results prose programmatically?

The Results section of an access-disparities manuscript restates numbers
that already live in your model output and tables. Re-typing them by
hand invites a whole class of bug: the sentence says “increasing” while
the coefficient is negative, an odds ratio below 1 is described as “more
likely”, or a confidence interval that crosses the null is written as if
it were bounded away from zero.

`mysterycall` provides a family of **prose builders** that take your
estimates and emit manuscript-ready sentences whose wording is derived
from the *sign and magnitude of the data*. Wire the narrative to these
builders and the words can never drift out of step with the tables.

| Builder | Input | Produces |
|----|----|----|
| [`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md) | OR table (logistic) | odds-of-acceptance sentences |
| [`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md) | IRR table (Poisson/NB) | wait-time IRR sentences |
| [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md) | IRR table + reference mean | absolute day differences (signed CI) |
| [`mysterycall_wait_time_sentence()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_wait_time_sentence.md) | raw data | median/IQR + log-rank-style summary |
| [`mysterycall_get_direction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md) | any signed number | “higher”/“lower” (configurable) |
| [`mysterycall_get_change_verb()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md) | any signed number | “increasing”/“decreasing” (configurable) |

Every builder here works on a plain data frame, so this vignette needs
no model fitting — but the same objects are returned by
[`mysterycall_logistic_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_logistic_model.md),
[`mysterycall_poisson_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_poisson_model.md),
and
[`mysterycall_nb_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_nb_model.md).

## A worked example

Two physician subspecialties are compared with a reference group for (a)
whether a new-patient appointment was offered and (b) how long the wait
was. We build the estimate tables directly; in practice they come from
your fitted models’ `$or_table` / `$irr_table` elements.

``` r

# Odds ratios for "appointment offered" (logistic regression output)
or_tbl <- data.frame(
  term     = c("(Intercept)", "insuranceMedicaid", "insuranceMedicare"),
  or       = c(2.10, 0.62, 0.88),
  ci_lower = c(1.20, 0.41, 0.63),
  ci_upper = c(3.68, 0.94, 1.23),
  p_value  = c(0.008, 0.024, 0.451),
  stringsAsFactors = FALSE
)

# Incidence rate ratios for wait days (Poisson/NB regression output).
# `p_value` (numeric) is used by write_results_paragraph(); `p_value_fmt`
# (character) is used by irr_to_days() for the in-sentence p-value.
irr_tbl <- data.frame(
  term        = c("(Intercept)", "insuranceMedicaid", "insuranceMedicare"),
  irr         = c(1.00, 1.28, 1.04),
  ci_lower    = c(NA,   1.05, 0.90),
  ci_upper    = c(NA,   1.56, 1.20),
  p_value     = c(NA,   0.014, 0.590),
  p_value_fmt = c(NA,   "0.014", "0.590"),
  stringsAsFactors = FALSE
)
```

### Appointment acceptance (odds ratios)

``` r

acceptance <- mysterycall_results_paragraph(
  or_tbl,
  ref_group     = "commercial insurance",
  exposure_col  = "insurance",
  outcome_label = "a new-patient appointment"
)
cat(acceptance)
#> Medicaid callers were 38% less likely to be offered a new-patient appointment (OR 0.62, 95% CI 0.41-0.94, p=0.024). Medicare callers were 12% less likely to be offered a new-patient appointment (OR 0.88, 95% CI 0.63-1.23, p=0.451).
```

The intro clause claims significance **only** when a level actually
clears `alpha`; the direction (“less likely” / “more likely” / “similar
odds”) is chosen from whether each OR sits below, above, or at 1.

### Wait-time incidence rate ratios

``` r

wait_irr <- mysterycall_write_results_paragraph(
  irr_tbl,
  ref_group     = "commercial insurance",
  exposure_col  = "insurance",
  outcome_label = "time to appointment"
)
cat(wait_irr)
#> In multivariable Poisson regression, insurance was significantly associated with time to appointment (see Table X). Compared with commercial insurance, callers presenting as Medicaid had an IRR of 1.28 (95% CI 1.05-1.56; p = 0.014) for time to appointment. Compared with commercial insurance, callers presenting as Medicare had an IRR of 1.04 (95% CI 0.90-1.20; p = 0.590) for time to appointment.
```

### Translating IRRs to absolute days (signed CIs)

IRRs are hard for readers to feel.
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md)
multiplies them by the reference-group mean wait to report absolute day
differences — and it keeps the **sign** of the confidence interval,
flagging any interval that crosses zero as not statistically
significant.

``` r

days <- mysterycall_irr_to_days(
  irr_tbl,
  baseline_mean = 21,          # mean wait (days) in the reference group
  exposure_col  = "insurance",
  ref_group     = "commercial insurance"
)
cat(days$paragraph)
#> Medicaid-insured callers waited a mean of 5.9 more days compared with commercial insurance (95% CI +1.1 to +11.8 days; IRR 1.28; p = 0.014). Medicare-insured callers waited a mean of 0.8 more days compared with commercial insurance (95% CI -2.1 to +4.2 days; IRR 1.04; p = 0.590) (difference not statistically significant).
```

Note the Medicare row: because its day-scale CI spans zero, the sentence
says so rather than implying a real effect.

For a non-insurance exposure (e.g. subspecialty), drop the
insurance-specific wording with `exposure_descriptor = NULL`:

``` r

ent_tbl <- data.frame(
  term        = c("(Intercept)", "ent_typeLaryngology"),
  irr         = c(1.00, 1.20),
  ci_lower    = c(NA,   1.02),
  ci_upper    = c(NA,   1.41),
  p_value_fmt = c(NA,   "0.028"),
  stringsAsFactors = FALSE
)
ent_days <- mysterycall_irr_to_days(
  ent_tbl, baseline_mean = 23, exposure_col = "ent_type",
  ref_group = "General", subject = "callers", exposure_descriptor = NULL
)
cat(ent_days$sentences[1])
#> Laryngology callers waited a mean of 4.6 more days compared with General (95% CI +0.5 to +9.4 days; IRR 1.20; p = 0.028).
```

### Descriptive wait-time sentence

Straight from the raw data, no model required:

``` r

set.seed(1)
raw <- data.frame(
  wait_days = c(rpois(60, 12), rpois(60, 16)),
  insurance = rep(c("Private", "Medicaid"), each = 60)
)
wt <- mysterycall_wait_time_sentence(
  raw, outcome_col = "wait_days", group_col = "insurance",
  reference = "Private"
)
cat(wt$sentence)
#> The median wait time across all insurance was 14 business days (IQR: 12–16). Specifically, the median wait time was 15 days (IQR: 13–18) for Medicaid, 13 days (IQR: 10–15) for Private. The p-value for Medicaid vs Private was < 0.001.
```

### Direction words tied to the data sign

For any custom sentence — a change over time, a difference between
groups — let the builder choose the word from the sign so the prose
cannot contradict the number. This is exactly the tool for
subspecialty/workforce framing.

``` r

# A projected annual change in provider supply
slope <- -0.8
sprintf(
  "The maternal-fetal-medicine workforce is %s (%+.1f providers per year).",
  mysterycall_get_change_verb(slope), slope
)
#> [1] "The maternal-fetal-medicine workforce is decreasing (-0.8 providers per year)."

# A between-group wait difference, with custom vocabulary
diff_days <- 4.3
sprintf(
  "Medicaid callers waited %s than commercial-insurance callers (%.1f days).",
  mysterycall_get_direction(diff_days, positive = "longer", negative = "shorter"),
  abs(diff_days)
)
#> [1] "Medicaid callers waited longer than commercial-insurance callers (4.3 days)."
```

Both are vectorized and `NA`-safe, and a `tol` argument defines a
no-change band around zero
(e.g. `mysterycall_get_change_verb(x, tol = 0.5)` calls anything within
±0.5 `"stable"`).

## Assembling the full Results section

Concatenate the pieces into one narrative. Because every clause was
generated from the estimates, editing a number in the model re-flows the
prose correctly.

``` r

results_section <- paste(
  acceptance,
  wait_irr,
  days$paragraph,
  sep = "\n\n"
)
cat(results_section)
#> Medicaid callers were 38% less likely to be offered a new-patient appointment (OR 0.62, 95% CI 0.41-0.94, p=0.024). Medicare callers were 12% less likely to be offered a new-patient appointment (OR 0.88, 95% CI 0.63-1.23, p=0.451).
#> 
#> In multivariable Poisson regression, insurance was significantly associated with time to appointment (see Table X). Compared with commercial insurance, callers presenting as Medicaid had an IRR of 1.28 (95% CI 1.05-1.56; p = 0.014) for time to appointment. Compared with commercial insurance, callers presenting as Medicare had an IRR of 1.04 (95% CI 0.90-1.20; p = 0.590) for time to appointment.
#> 
#> Medicaid-insured callers waited a mean of 5.9 more days compared with commercial insurance (95% CI +1.1 to +11.8 days; IRR 1.28; p = 0.014). Medicare-insured callers waited a mean of 0.8 more days compared with commercial insurance (95% CI -2.1 to +4.2 days; IRR 1.04; p = 0.590) (difference not statistically significant).
```

## Model-diagnostic prose

Two more builders describe the model itself. They take a *fitted* model
object, so they are shown here without evaluation:

``` r

# Variance explained (marginal / conditional R-squared) for a mixed model
cat(mysterycall_r2_sentence(fit))

# Dispersion check for a count model
cat(mysterycall_overdispersion_sentence(fit))
```

## Best practice

- **Never hand-type a direction word.** Feed the estimate to
  [`mysterycall_get_direction()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md)
  /
  [`mysterycall_get_change_verb()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md)
  (or use a builder that does). A sentence that says “increasing” over a
  negative slope is a data-integrity bug, not a typo.
- **Report absolute effects alongside ratios.**
  [`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md)
  gives readers days, with signed CIs that honestly flag null results.
- **Regenerate, don’t edit.** Re-run the builders after any model change
  so the Results text and the tables always agree.

&nbsp;

    #> R version 4.6.1 (2026-06-24)
    #> Platform: x86_64-pc-linux-gnu
    #> Running under: Ubuntu 24.04.4 LTS
    #> 
    #> Matrix products: default
    #> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
    #> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
    #> 
    #> locale:
    #>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
    #>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
    #>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
    #> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
    #> 
    #> time zone: UTC
    #> tzcode source: system (glibc)
    #> 
    #> attached base packages:
    #> [1] stats     graphics  grDevices utils     datasets  methods   base     
    #> 
    #> other attached packages:
    #> [1] mysterycall_1.6.2.9003
    #> 
    #> loaded via a namespace (and not attached):
    #>  [1] gtable_0.3.6       xfun_0.60          bslib_0.11.0       ggplot2_4.0.3     
    #>  [5] htmlwidgets_1.6.4  insight_1.5.2      lattice_0.22-9     tzdb_0.5.0        
    #>  [9] vctrs_0.7.3        tools_4.6.1        Rdpack_2.6.6       generics_0.1.4    
    #> [13] tibble_3.3.1       pkgconfig_2.0.3    Matrix_1.7-5       checkmate_2.3.4   
    #> [17] RColorBrewer_1.1-3 S7_0.2.2           desc_1.4.3         gt_1.3.0          
    #> [21] lifecycle_1.0.5    compiler_4.6.1     farver_2.1.2       stringr_1.6.0     
    #> [25] textshaping_1.0.5  janitor_2.2.1      snakecase_0.11.1   htmltools_0.5.9   
    #> [29] sass_0.4.10        yaml_2.3.12        pillar_1.11.1      pkgdown_2.2.1     
    #> [33] nloptr_2.2.1       jquerylib_0.1.4    MASS_7.3-65        cachem_1.1.0      
    #> [37] reformulas_0.4.4   boot_1.3-32        nlme_3.1-169       npi_0.3.0         
    #> [41] tidyselect_1.2.1   digest_0.6.39      performance_0.17.1 stringi_1.8.7     
    #> [45] dplyr_1.2.1        splines_4.6.1      fastmap_1.2.0      grid_4.6.1        
    #> [49] cli_3.6.6          magrittr_2.0.5     readr_2.2.0        scales_1.4.0      
    #> [53] backports_1.5.1    lubridate_1.9.5    timechange_0.4.0   rmarkdown_2.31    
    #> [57] httr_1.4.8         otel_0.2.0         lme4_2.0-6         ragg_1.5.2        
    #> [61] hms_1.1.4          evaluate_1.0.5     knitr_1.51         rbibutils_2.4.1   
    #> [65] rlang_1.3.0        Rcpp_1.1.2         glue_1.8.1         xml2_1.6.0        
    #> [69] minqa_1.2.8        jsonlite_2.0.0     R6_2.6.1           systemfonts_1.3.2 
    #> [73] fs_2.1.0
