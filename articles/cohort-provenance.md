# Cohort Provenance: Three Populations, One Study

## Why “the cohort” is three objects, not one

Ask what n is for a mystery-caller study and you will get three
defensible answers. All three are needed, and collapsing them is how a
study loses the ability to explain itself.

| population | what it is | what it is for |
|----|----|----|
| **source denominator** | every call placed | the flow diagram, the offer-stage model, provenance |
| **eligible** | calls that met the protocol’s inclusion criteria | eligibility-conditioned descriptives |
| **analytic** | eligible calls with an observable outcome | the wait-time model |

The temptation is to keep only the last one, because it is the one the
model runs on. That is the mistake. Once the first two are gone you can
no longer say how many offices were approached, what fraction were
reachable, or whether the records that dropped out differ from the ones
that stayed. Reviewers ask all three questions and a single frozen data
set answers none of them.

## A worked cohort

``` r

set.seed(1)
n <- 40
calls <- data.frame(
  call_id  = sprintf("C%02d", seq_len(n)),
  clinic   = sprintf("Clinic %02d", seq_len(n)),
  contacted = c(rep("Yes", 26), rep("No", 14)),
  reason   = c(rep("Able to contact", 26),
               rep("Went to voicemail", 6),
               rep("Wrong number listed", 4),
               rep("Closed medical system", 4)),
  stringsAsFactors = FALSE
)
# only contacted offices can produce an appointment; not all of them do
calls$appointment_date <- as.Date(NA)
got <- c(rep(TRUE, 21), rep(FALSE, 5))
calls$appointment_date[calls$contacted == "Yes"][got] <-
  as.Date("2019-07-15") + sample(0:60, sum(got), replace = TRUE)
str(calls, give.attr = FALSE)
#> 'data.frame':    40 obs. of  5 variables:
#>  $ call_id         : chr  "C01" "C02" "C03" "C04" ...
#>  $ clinic          : chr  "Clinic 01" "Clinic 02" "Clinic 03" "Clinic 04" ...
#>  $ contacted       : chr  "Yes" "Yes" "Yes" "Yes" ...
#>  $ reason          : chr  "Able to contact" "Able to contact" "Able to contact" "Able to contact" ...
#>  $ appointment_date: Date, format: "2019-09-09" "2019-07-18" ...
```

Eligibility is decided by the protocol’s exclusion criteria, **not** by
whether an appointment happened. This is the single most important rule
in this vignette: if you let the outcome decide eligibility, populations
2 and 3 become the same object and the offer stage disappears.

``` r

calls$eligible <- calls$reason == "Able to contact"

pop <- data.frame(
  population = c("source denominator", "eligible", "analytic (wait)"),
  n = c(nrow(calls),
        sum(calls$eligible),
        sum(calls$eligible & !is.na(calls$appointment_date))),
  appointment_obtained = c(sum(!is.na(calls$appointment_date)),
                           sum(calls$eligible & !is.na(calls$appointment_date)),
                           sum(calls$eligible & !is.na(calls$appointment_date)))
)
pop$pct_of_source <- round(100 * pop$n / nrow(calls), 1)
pop
#>           population  n appointment_obtained pct_of_source
#> 1 source denominator 40                   21         100.0
#> 2           eligible 26                   21          65.0
#> 3    analytic (wait) 21                   21          52.5
```

Note what the offer rate looks like in each: **52.5%** of all calls
obtained an appointment, but within the eligible cohort the figure is
far higher, because the exclusion criteria have already removed most of
the calls that could not produce one. That gap is not a nuisance. It is
the reason the offer-stage model belongs on the source denominator, and
it is covered in the two-part-denominators vignette.

## Auditing the attrition

Every record that leaves the cohort should leave for a stated reason.
The cheapest useful audit is a table of who is dropped at each step and
why.

``` r

attrition <- as.data.frame(table(reason = calls$reason[!calls$eligible]))
names(attrition)[2] <- "n_dropped"
attrition$documented <- TRUE
attrition
#>                  reason n_dropped documented
#> 1 Closed medical system         4       TRUE
#> 2     Went to voicemail         6       TRUE
#> 3   Wrong number listed         4       TRUE
```

An empty `reason` at this point is the thing to look for. A record that
disappears with no recorded justification is not an exclusion, it is a
leak, and it should be labelled `UNEXPLAINED` rather than quietly folded
into a category that sounds plausible.

``` r

calls$disposition <- ifelse(
  calls$eligible, "Included",
  ifelse(nzchar(calls$reason) & !is.na(calls$reason),
         paste0("Excluded: ", calls$reason),
         "UNEXPLAINED")
)
table(grepl("^UNEXPLAINED", calls$disposition))
#> 
#> FALSE 
#>    40
```

## When derived files disagree

Studies accumulate derivatives: a cleaned workbook, an enriched export,
a re-coded copy someone made for a conference abstract. These drift, and
they drift in both directions, so neither file is automatically “the
newer one that must be right”.

The rule that keeps this honest is: **adjudicate from the raw fields,
never by preferring the later file.**

``` r

adjudicate <- function(raw_appointment, raw_contacted, label_a, label_b) {
  agree <- !is.na(label_a) & !is.na(label_b) & label_a == label_b
  ifelse(
    agree, label_a,
    # raw evidence outranks either label
    ifelse(!is.na(raw_appointment), "Included (raw: appointment exists)",
    ifelse(!is.na(raw_contacted) & raw_contacted == "No", "Excluded (raw: not contacted)",
           ifelse(!is.na(label_a), label_a, label_b)))
  )
}

demo <- data.frame(
  call_id  = c("C01", "C02", "C03"),
  label_a  = c("Included", "Excluded", "Included"),
  label_b  = c("Included", "Included", "Excluded"),
  raw_appt = as.Date(c("2019-07-15", "2019-07-20", NA)),
  raw_contact = c("Yes", "Yes", "No")
)
demo$canonical <- adjudicate(demo$raw_appt, demo$raw_contact, demo$label_a, demo$label_b)
demo[, c("call_id", "label_a", "label_b", "canonical")]
#>   call_id  label_a  label_b                          canonical
#> 1     C01 Included Included                           Included
#> 2     C02 Excluded Included Included (raw: appointment exists)
#> 3     C03 Included Excluded      Excluded (raw: not contacted)
```

The middle row is the interesting one. One file says excluded, the other
says included, and the raw data contains an appointment date, which
settles it: an office that gave an appointment was reached, whatever a
downstream file was later re-coded to say. The third row settles the
other way for the same kind of reason.

Record the evidence alongside the verdict. A cohort where every disputed
record carries the sentence that decided it can be defended; one that
carries only the verdict cannot.

## Freezing the result

Once the three populations are settled, pin them. Nesting is the
invariant worth asserting, because a violation means an object has been
rebuilt inconsistently:

``` r

stopifnot(
  pop$n[3] <= pop$n[2],   # analytic subset of eligible
  pop$n[2] <= pop$n[1]    # eligible subset of source
)
"cohort nesting holds"
#> [1] "cohort nesting holds"
```

Checks worth running before anything is modelled:

- no wait time on a record with no appointment date
- no negative wait
- no uncontacted office carrying an outcome
- one source record never becomes several analytic rows
- every exclusion has a documented reason
- nothing left unadjudicated

[`mysterycall_guard_contaminated_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_guard_contaminated_wait.md)
covers the first and third of these as a hard failure; see the
guarding-contaminated-outcomes vignette.

## Where this fits

- [`mysterycall_reconcile_inclusion()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_reconcile_inclusion.md)
  crosswalks integer exclusion codes to the label strings a protocol
  uses, which is usually where two derived files begin to disagree.
- [`mysterycall_flag_repeat_physicians()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_repeat_physicians.md)
  and
  [`mysterycall_flag_near_duplicate_keys()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_flag_near_duplicate_keys.md)
  catch one source record becoming several analytic rows.
- The `data-cleaning` vignette covers the cleaning steps that precede
  this; this vignette is about what to keep once cleaning is done.
