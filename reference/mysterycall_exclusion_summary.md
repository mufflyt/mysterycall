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
[`mysterycall_geographic_map()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_geographic_map.md),
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
#> A total of 240 phone calls were made. Of these, 80 (33.3%) calls were unsuccessful connections, including calls in which the phone was not answered or the caller received a busy signal (n = 40), calls that went to voicemail (n = 30), and calls for which the number reached did not correspond to the expected office or specialty (n = 10). The remaining 160 (66.7%) calls resulted in a successful connection with office staff. Among successfully connected calls, 15 offices required a physician referral before an appointment could be scheduled, 20 offices were not accepting new patients, and 5 calls were placed on hold for more than 5 minutes. After applying all exclusion criteria, 120 (50.0%) calls were included in the final analysis. 
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
#> A total of 240 phone calls were made. Of these, 80 (33.3%) calls were unsuccessful connections, including calls in which the phone was not answered or the caller received a busy signal (n = 40), calls that went to voicemail (n = 30), and calls for which the number reached did not correspond to the expected office or specialty (n = 10). The remaining 160 (66.7%) calls resulted in a successful connection with office staff. Among successfully connected calls, 15 offices required a physician referral before an appointment could be scheduled, 20 offices were not accepting new patients, and 5 calls were placed on hold for more than 5 minutes. After applying all exclusion criteria, 120 (50.0%) calls were included in the final analysis.

## --- deduplicate by provider before counting ------------------------------
df3 <- df
df3$npi <- c(
  seq_len(120L),                  # included (unique)
  rep(121L, 40L),                 # one provider, 40 no-answer attempts
  122L + seq_len(sum(n_each[-c(1L, 2L)]) - 1L)  # remaining
)
#> Error in `$<-.data.frame`(`*tmp*`, npi, value = c(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L, 11L, 12L, 13L, 14L, 15L, 16L, 17L, 18L, 19L, 20L, 21L, 22L, 23L, 24L, 25L, 26L, 27L, 28L, 29L, 30L, 31L, 32L, 33L, 34L, 35L, 36L, 37L, 38L, 39L, 40L, 41L, 42L, 43L, 44L, 45L, 46L, 47L, 48L, 49L, 50L, 51L, 52L, 53L, 54L, 55L, 56L, 57L, 58L, 59L, 60L, 61L, 62L, 63L, 64L, 65L, 66L, 67L, 68L, 69L, 70L, 71L, 72L, 73L, 74L, 75L, 76L, 77L, 78L, 79L, 80L, 81L, 82L, 83L, 84L, 85L, 86L, 87L, 88L, 89L, 90L, 91L, 92L, 93L, 94L, 95L, 96L, 97L, 98L, 99L, 100L, 101L, 102L, 103L, 104L, 105L, 106L, 107L, 108L, 109L, 110L, 111L, 112L, 113L, 114L, 115L, 116L, 117L, 118L, 119L, 120L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 121L, 123L, 124L, 125L, 126L, 127L, 128L, 129L, 130L, 131L, 132L, 133L, 134L, 135L, 136L, 137L, 138L, 139L, 140L, 141L, 142L, 143L, 144L, 145L, 146L, 147L, 148L, 149L, 150L, 151L, 152L, 153L, 154L, 155L, 156L, 157L, 158L, 159L, 160L, 161L, 162L, 163L, 164L, 165L, 166L, 167L, 168L, 169L, 170L, 171L, 172L, 173L, 174L, 175L, 176L, 177L, 178L, 179L, 180L, 181L, 182L, 183L, 184L, 185L, 186L, 187L, 188L, 189L, 190L, 191L, 192L, 193L, 194L, 195L, 196L, 197L, 198L, 199L, 200L, 201L)): replacement has 239 rows, data has 240
# id_col collapses repeated dials to the same NPI
result3 <- mysterycall_exclusion_summary(df3, id_col = "npi")
#> Error: Column 'npi' (id_col) not found in `data`.
result3$total   # unique providers, not raw call rows
#> Error: object 'result3' not found
```
