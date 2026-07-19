# Logistic Model: Appointment Offered (Yes/No)

## Overview

Mystery-caller studies typically ask two statistical questions:

1.  **Was an appointment offered?** (logistic GLMM, binary outcome)
2.  **How long did patients wait?** (Poisson/NB GLMM, count outcome)

This vignette covers question 1. For question 2, see
[`vignette("statistical-analysis")`](https://mufflyt.github.io/mysterycall/articles/statistical-analysis.md).

------------------------------------------------------------------------

## Step 1 — Load the raw REDCap export

Export your REDCap project as a CSV. The columns expected by default
are:

| Column            | Type      | Description                               |
|-------------------|-----------|-------------------------------------------|
| `calldate1`       | date      | Date the first call was placed            |
| `contacted1`      | 0/1       | Office reached on first call              |
| `contacted2`      | 0/1/99    | Office reached on second call; 99 = N/A   |
| `appdate`         | date      | Appointment date if offered               |
| `exclusions`      | integer   | Exclusion code (see table below)          |
| `initials`        | character | Caller identity (standardized internally) |
| `medicaid_status` | 1–4       | Insurance type for this call              |

``` r

raw <- read.csv("ICVsPOPVsSUI_DATA_2026-06-23_1225.csv",
                stringsAsFactors = FALSE)
dim(raw)  # e.g. 743 rows, 17 columns
```

------------------------------------------------------------------------

## Step 2 — Prepare and filter with `mysterycall_prepare_calls()`

[`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md)
encodes the standard mystery-caller filtering pipeline in a single call:

``` r

prepped <- mysterycall_prepare_calls(raw)
print(prepped)
```

The printed output shows the **filtering waterfall** — how many records
survive each step — plus per-exclusion-code counts and the standardized
caller roster.

### The exclusion codebook

| Code | Meaning | Included in logistic model? |
|----|----|----|
| 0 | Included (office reached, scheduling discussed) | ✅ outcome = 1 if appt offered |
| 1 | Closed medical system (Kaiser/military) | ❌ dropped |
| 2 | \>5 minutes on hold | ❌ dropped |
| 3 | Wrong number or wrong specialty | ❌ dropped |
| 5 | Phone not answered / busy signal | ❌ dropped |
| 6 | Physician’s personal phone | ❌ dropped |
| 7 | Referral required before scheduling | ✅ outcome = 0 |
| 8 | Went to voicemail | ❌ dropped |
| 9 | Not accepting new patients | ✅ outcome = 0 |
| 10 | Must see midlevel first | ✅ outcome = 0 |
| NA | Not yet reviewed | ⚠️ Warning issued; review before analysis |

Codes 7, 9, and 10 represent **offices that were reached but declined to
schedule**. They contribute information about access barriers and are
included in the logistic model with outcome = 0 (no appointment
offered). All other non-zero codes are true operational failures (wrong
number, voicemail, etc.) where the office’s actual access posture is
unknown, so they are dropped.

### Two output datasets

`$logistic_data` — all records where the office was **reached** and the
outcome (appointment offered: yes/no) can be determined:

``` r

nrow(prepped$logistic_data)  # office reached, appt_offered column ready
table(prepped$logistic_data$appt_offered)
```

`$waittime_data` — subset where an appointment date was recorded (use
with
[`mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_auto_model.md)):

``` r

nrow(prepped$waittime_data)
summary(prepped$waittime_data$calendar_days)
```

### Reviewing NA exclusion codes

If data entry is still in progress, some records will have `NA`
exclusion codes. The default `na_exclusions = "warn"` keeps them but
flags them:

``` r

# Inspect before analysis
prepped$na_exclusion_records[, c("record_id", "calldate1", "initials")]
```

Once reviewed, re-run with `na_exclusions = "drop"` to exclude them, or
code them in REDCap and re-export.

------------------------------------------------------------------------

## Step 3 — Recode covariates

### Insurance type

`medicaid_status` uses REDCap codes 1–4. Create a clean factor for
modeling:

``` r

d <- prepped$logistic_data
d$insurance <- factor(
  d$medicaid_status,
  levels = c(1, 2, 3, 4),
  labels = c("Medicaid", "Refuses Medicaid", "BCBS", "Unknown")
)

# Keep only BCBS (control) vs Medicaid comparison; drop "Refuses" and "Unknown"
d_model <- d[d$insurance %in% c("Medicaid", "BCBS"), ]
d_model$insurance <- droplevels(d_model$insurance)
```

> **Note:** BCBS calls serve as the insurance-type **control** arm (code
> 3). Medicaid calls are the exposure arm (code 1). Calls coded 2
> (“refuses Medicaid”) are a secondary outcome, not a comparison group
> for the primary logistic model.

### Caller (random effect hygiene)

Caller names are standardized to title case by
[`mysterycall_prepare_calls()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_prepare_calls.md).
Verify the `caller` column before modeling:

``` r

table(d_model$caller)
# Should show 3–5 named callers, not dozens of duplicates with case typos
```

------------------------------------------------------------------------

## Step 4 — Fit the logistic GLMM

``` r

fit_log <- mysterycall_logistic_model(
  data             = d_model,
  outcome          = "appt_offered",
  predictors       = c("insurance", "practice_type", "region"),
  random_intercept = "npi"   # physician random intercept
)
print(fit_log)
```

The model uses `lme4::glmer(..., family = binomial(link = "logit"))`.
The `$or_table` contains odds ratios (OR) with 95% Wald confidence
intervals:

``` r

fit_log$or_table
```

| term              | or   | ci_lower | ci_upper | p_value_fmt |
|-------------------|------|----------|----------|-------------|
| insuranceMedicaid | 0.38 | 0.21     | 0.68     | P \< .001   |
| …                 |      |          |          |             |

------------------------------------------------------------------------

## Step 5 — Forest plot

``` r

mysterycall_forest_plot(
  fit_log,
  x_label = "Odds Ratio (95% CI)",
  title    = "Odds of Appointment Being Offered",
  subtitle = "Random intercept: physician (NPI)"
)
```

Because `fit_log` is a `mysterycall_logistic_model` object,
[`mysterycall_forest_plot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_forest_plot.md)
automatically switches the x-axis label to “Odds Ratio (95% CI)” and
reads from `$or_table` rather than `$irr_table`.

------------------------------------------------------------------------

## Step 6 — Interpret the ICC

The physician-level ICC from the logistic model tells you how much of
the variation in scheduling is explained by the physician (vs. insurance
type or other patient/call factors):

``` r

fit_log$random_effects
# $var_physician  — variance of physician random intercept on logit scale
# Latent ICC = var_physician / (var_physician + pi^2/3)
```

A high ICC (\> 0.10) means physician practice matters as much as or more
than insurance type — a meaningful finding for access research.

------------------------------------------------------------------------

## Full pipeline in \< 20 lines

``` r

library(mysterycall)

raw     <- read.csv("ICVsPOPVsSUI_DATA_2026-06-23_1225.csv",
                    stringsAsFactors = FALSE)
prepped <- mysterycall_prepare_calls(raw, na_exclusions = "drop")

d <- prepped$logistic_data
d$insurance <- factor(d$medicaid_status,
                      levels = 1:4,
                      labels = c("Medicaid","Refuses","BCBS","Unknown"))
d <- d[d$insurance %in% c("Medicaid", "BCBS"), ]
d$insurance <- droplevels(d$insurance)

fit <- mysterycall_logistic_model(
  data             = d,
  outcome          = "appt_offered",
  predictors       = "insurance",
  random_intercept = "npi"
)
print(fit)
mysterycall_forest_plot(fit, x_label = "Odds Ratio (95% CI)")
```

------------------------------------------------------------------------

## Downstream: wait-time model

If you also want to model **how long** patients waited (among those who
got appointments), use `$waittime_data` directly:

``` r

wt <- prepped$waittime_data

fit_wt <- mysterycall_auto_model(
  data             = wt,
  outcome          = "calendar_days",
  predictors       = "insurance",
  random_intercept = "npi"
)
print(fit_wt)
```

[`mysterycall_auto_model()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_auto_model.md)
selects Poisson or negative-binomial GLMM automatically based on
overdispersion and also fits an LMM for clinical day-scale
interpretation.

------------------------------------------------------------------------

## Frequently asked questions

**Why are voicemail (code 8) and no-answer (code 5) excluded?** These
calls provide no information about whether the office would schedule an
appointment — the caller never spoke to anyone. Including them as
outcome = 0 would conflate “office refuses Medicaid” with “office was
closed that afternoon,” biasing the OR toward appearing less
discriminatory.

**Should I include both BCBS and Medicaid calls from the same
physician?** Yes — that is precisely the study design. The physician
random intercept accounts for within-physician correlation, so each
physician contributes two correlated observations (one per insurance
type) without inflating your effective sample size.

**My ICC is very high (\> 0.30). Is that a problem?** No — it means
physician-level factors explain a lot of the outcome, which is a
substantive finding. The random intercept still corrects for it so your
fixed effects (insurance, region, etc.) are estimated correctly.

**What if `lme4` fails to converge?** Try `nAGQ = 0L` (the default) for
faster approximate integration, or reduce the number of predictors. For
small datasets (\< 100 observations), the physician random intercept may
be unidentifiable — report a plain logistic regression instead and note
the limitation.
