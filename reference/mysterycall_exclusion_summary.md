# Summarise call-level exclusions into a manuscript-ready paragraph

Automates the computation and prose formatting of an exclusion paragraph
from a mystery-caller dataset that contains a column recording the
outcome (included vs. a reason for exclusion) for each call attempt. The
function mirrors the manual paragraph construction used in ortho
sports-medicine mystery-caller Rmd reports (lines 1033-1081) and
generalises it for any study design.

## Usage

``` r
mysterycall_exclusion_summary(
  data,
  exclusion_col = "reason_for_exclusions",
  inclusion_value = "Able to contact",
  exclusion_categories = c(phone_not_answered =
    "Phone not answered or busy signal on repeat calls", voicemail = "Went to voicemail",
    wrong_number = "Number contacted did not correspond to expected office/specialty",
    referral_required = "Physician referral required before scheduling appointment",
    not_accepting = "Not accepting new patients", on_hold =
    "Greater than 5 minutes on hold"),
  id_col = NULL
)
```

## Arguments

- data:

  data.frame. The **full** dataset including all excluded rows. Must
  have at least one column whose name matches `exclusion_col`.

- exclusion_col:

  Character scalar. Name of the column that holds the outcome or
  reason-for-exclusion value for each call. Default
  `"reason_for_exclusions"`.

- inclusion_value:

  Character scalar. The value in `exclusion_col` that identifies a call
  that was successfully completed and is included in the analysis.
  Default `"Able to contact"`.

- exclusion_categories:

  Named character vector mapping semantic group names to the exact
  string values found in `exclusion_col`. The vector must contain **all
  six** of the following keys (values may be overridden):

  `phone_not_answered`

  :   Unsuccessful: phone not answered / busy signal.

  `voicemail`

  :   Unsuccessful: call went to voicemail.

  `wrong_number`

  :   Unsuccessful: number did not reach the expected office.

  `referral_required`

  :   Reached but excluded: physician referral required.

  `not_accepting`

  :   Reached but excluded: office not accepting new patients.

  `on_hold`

  :   Reached but excluded: caller placed on hold \> 5 minutes.

- id_col:

  Character scalar or `NULL`. When non-`NULL`, `data` is deduplicated by
  this column before all counting so that repeated call attempts to the
  same provider collapse to one record. Default `NULL` (no
  deduplication).

## Value

A list of class `mysterycall_exclusion_summary` containing:

- `total`:

  Integer. Total calls (or unique IDs when `id_col` is non-`NULL`).

- `n_reached`:

  Integer. Calls successfully connected (not in the unreachable group).

- `n_unreachable`:

  Integer. Calls in the unreachable group (phone not answered +
  voicemail + wrong number).

- `pct_reached`:

  Numeric. `n_reached / total * 100`, or `NA` when `total` is zero.

- `n_included`:

  Integer. Calls included in the final analysis (`n_reached` minus
  reached-but-excluded calls).

- `counts`:

  Named integer vector. Count for each of the six canonical
  exclusion-category keys.

- `percentages`:

  Named numeric vector. `counts / total * 100`, or `NA` for each element
  when `total` is zero.

- `paragraph`:

  Character scalar. Full exclusion paragraph ready to paste into a
  manuscript Methods or Results section.

- `table`:

  data.frame. Tabyl-style summary with columns `category` (key name),
  `label` (human-readable value), `n` (integer count), and `pct`
  (numeric percentage of total).

## Details

**Semantic grouping of the six built-in exclusion keys:**

- *Unsuccessful connections* (could not reach anyone):
  `phone_not_answered`, `voicemail`, `wrong_number`.

- *Reached but excluded*: `referral_required`, `not_accepting`,
  `on_hold`.

Calls that match `inclusion_value` are counted as *included*. Any row
that does not match `inclusion_value` or any value in
`exclusion_categories` is silently classified as unrecognised and
contributes to the denominator but not to any named exclusion bucket.

## See also

[`mysterycall_strobe_flow()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_strobe_flow.md),
[`mysterycall_flag_date_outliers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_date_outliers.md)

Other reporting:
[`mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_abstract_numbers.md),
[`mysterycall_direction_words`](https://mufflyt.github.io/mysterycall/reference/mysterycall_direction_words.md),
[`mysterycall_irr_to_days()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_irr_to_days.md),
[`mysterycall_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_results_paragraph.md),
[`mysterycall_session_snapshot()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_session_snapshot.md),
[`mysterycall_supplemental_tables()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_supplemental_tables.md),
[`mysterycall_write_results_paragraph()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_write_results_paragraph.md),
[`print.mysterycall_abstract_numbers()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_abstract_numbers.md),
[`print.mysterycall_irr_days()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_irr_days.md),
[`print.mysterycall_snapshot()`](https://mufflyt.github.io/mysterycall/reference/print.mysterycall_snapshot.md)

## Examples

``` r
## --- minimal runnable example (base R only) -------------------------------
reasons <- c(
  "Able to contact",
  "Phone not answered or busy signal on repeat calls",
  "Went to voicemail",
  "Number contacted did not correspond to expected office/specialty",
  "Physician referral required before scheduling appointment",
  "Not accepting new patients",
  "Greater than 5 minutes on hold"
)
n_each <- c(120L, 40L, 30L, 10L, 15L, 20L, 5L)

df <- data.frame(
  call_id               = seq_len(sum(n_each)),
  reason_for_exclusions = rep(reasons, n_each),
  stringsAsFactors      = FALSE
)

result <- mysterycall_exclusion_summary(df)
print(result)       # prints the prose paragraph
#> A total of 240 phone calls were made. Of these, 80 (33.3%) calls were unsuccessful connections, including calls in which the phone was not answered or the caller received a busy signal (n = 40), calls that went to voicemail (n = 30), and calls for which the number reached did not correspond to the expected office or specialty (n = 10). The remaining 160 (66.7%) calls resulted in a successful connection with office staff. Among successfully connected calls, 15 offices required a physician referral before an appointment could be scheduled, 20 offices were not accepting new patients, and 5 calls were placed on hold for more than 5 minutes. After applying all exclusion criteria, 120 (50.0%) calls were included in the final analysis. 
result$table        # tabyl-style counts
#>             category
#> 1           included
#> 2 phone_not_answered
#> 3          voicemail
#> 4       wrong_number
#> 5  referral_required
#> 6      not_accepting
#> 7            on_hold
#>                                                              label   n
#> 1                                             Included in analysis 120
#> 2                Phone not answered or busy signal on repeat calls  40
#> 3                                                Went to voicemail  30
#> 4 Number contacted did not correspond to expected office/specialty  10
#> 5        Physician referral required before scheduling appointment  15
#> 6                                       Not accepting new patients  20
#> 7                                   Greater than 5 minutes on hold   5
#>         pct
#> 1 50.000000
#> 2 16.666667
#> 3 12.500000
#> 4  4.166667
#> 5  6.250000
#> 6  8.333333
#> 7  2.083333

## --- custom exclusion values (different study coding scheme) --------------
df2 <- df
names(df2)[2] <- "call_outcome"
result2 <- mysterycall_exclusion_summary(
  data          = df2,
  exclusion_col = "call_outcome",
  inclusion_value = "Able to contact",
  exclusion_categories = c(
    phone_not_answered = "Phone not answered or busy signal on repeat calls",
    voicemail          = "Went to voicemail",
    wrong_number       = "Number contacted did not correspond to expected office/specialty",
    referral_required  = "Physician referral required before scheduling appointment",
    not_accepting      = "Not accepting new patients",
    on_hold            = "Greater than 5 minutes on hold"
  )
)
cat(result2$paragraph)
#> A total of 240 phone calls were made. Of these, 80 (33.3%) calls were unsuccessful connections, including calls in which the phone was not answered or the caller received a busy signal (n = 40), calls that went to voicemail (n = 30), and calls for which the number reached did not correspond to the expected office or specialty (n = 10). The remaining 160 (66.7%) calls resulted in a successful connection with office staff. Among successfully connected calls, 15 offices required a physician referral before an appointment could be scheduled, 20 offices were not accepting new patients, and 5 calls were placed on hold for more than 5 minutes. After applying all exclusion criteria, 120 (50.0%) calls were included in the final analysis.

## --- deduplicate by provider before counting ------------------------------
df3 <- df
df3$npi <- c(
  seq_len(120L),                  # included (unique)
  rep(121L, 40L),                 # one provider, 40 no-answer attempts
  seq_len(sum(n_each[-c(1L, 2L)])) + 121L  # remaining unique providers
)
# id_col collapses repeated dials to the same NPI
result3 <- mysterycall_exclusion_summary(df3, id_col = "npi")
result3$total   # unique providers, not raw call rows
#> [1] 201
```
