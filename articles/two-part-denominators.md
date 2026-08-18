# The Two-Part Model and the Denominator Trap

## Access is two questions, not one

“How long is the wait?” is only half of an access study. An office that
never offers an appointment has a wait of neither zero nor infinity; it
has no wait at all, and folding it in either direction misstates the
finding.

The two-part (hurdle) structure keeps the questions separate:

1.  **Offer stage.** Was an appointment offered? Binary, over everyone
    who was called.
2.  **Wait stage.** Among appointments offered, how long? Count, over
    offers only.

Reported together they answer the question a patient actually has.
Reported as a single mean wait, they can move in opposite directions and
cancel: an arm that refuses more patients can post a *shorter* mean
wait, because the refusals never enter the average.

## The trap

Here is the part that is easy to miss and expensive to get wrong.

Mystery-caller protocols carry an exclusion vocabulary: wrong number,
voicemail, closed system, retired. These are legitimate. The trap is
that such vocabularies often quietly include categories that are
**outcomes rather than exclusions** – “not accepting new patients”,
“requires a referral first”, “would not schedule without records”.

Those are refusals. If the protocol codes them as exclusions, they are
removed from the cohort, and the offer stage loses almost all of its
variation.

``` r

calls <- data.frame(
  call_id = sprintf("C%02d", 1:20),
  reason  = c(rep("Able to contact", 12),
              rep("Not accepting new patients", 4),   # outcome, coded as exclusion
              rep("Wrong number listed", 2),          # genuine exclusion
              rep("Went to voicemail", 2)),           # genuine exclusion
  stringsAsFactors = FALSE
)
calls$offered <- calls$reason == "Able to contact"

protocol_eligible <- calls$reason == "Able to contact"
all_called        <- rep(TRUE, nrow(calls))

data.frame(
  denominator = c("source (everyone called)", "protocol-eligible only"),
  n           = c(sum(all_called), sum(protocol_eligible)),
  offered     = c(sum(calls$offered[all_called]), sum(calls$offered[protocol_eligible])),
  offer_rate  = c(round(100 * mean(calls$offered[all_called]), 1),
                  round(100 * mean(calls$offered[protocol_eligible]), 1))
)
#>                denominator  n offered offer_rate
#> 1 source (everyone called) 20      12         60
#> 2   protocol-eligible only 12      12        100
```

On the eligible cohort the offer rate is 100 percent. There is nothing
left to model: every office that survived the exclusion criteria offered
an appointment, because *not offering one was itself an exclusion
criterion*. Fit a logistic model there and it will fail to converge, or
converge on nothing, and the natural reading is “no disparity in access”
when the truth is that the question was never asked.

The four “not accepting new patients” calls are the finding. They belong
in the denominator.

## Choosing each denominator deliberately

``` r

# Stage 1: offer. Everyone called who could in principle have been offered
# something -- genuine unreachables (wrong number, voicemail) removed, refusals
# retained, because a refusal is an outcome.
genuine_exclusion <- calls$reason %in% c("Wrong number listed", "Went to voicemail")
offer_denominator <- !genuine_exclusion

# Stage 2: wait. Offers only.
wait_denominator <- calls$offered

data.frame(
  stage = c("offer", "wait"),
  denominator_n = c(sum(offer_denominator), sum(wait_denominator)),
  definition = c("called, minus unreachable-by-construction",
                 "appointments offered")
)
#>   stage denominator_n                                definition
#> 1 offer            16 called, minus unreachable-by-construction
#> 2  wait            12                      appointments offered
```

Stated as a rule: **an exclusion removes calls where the question could
not be asked; an outcome records the answer when it was.** Wrong number
means the office was never reached, so no access question was posed.
“Not accepting new patients” means the office was reached and said no.

## Reporting both stages

``` r

offer_rate <- mean(calls$offered[offer_denominator])
sprintf("Offer stage: %d of %d calls (%.0f%%) yielded an appointment.",
        sum(calls$offered[offer_denominator]), sum(offer_denominator), 100 * offer_rate)
#> [1] "Offer stage: 12 of 16 calls (75%) yielded an appointment."
```

A wait-time result quoted without its offer rate is not interpretable,
because the reader cannot tell whether a short wait reflects good access
or heavy attrition upstream. Report the pair, always, and report the
denominator of each.

[`mysterycall_hurdle_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hurdle_wait.md)
fits both stages together and keeps the denominators distinct;
[`mysterycall_twopart_power()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_twopart_power.md)
does power for the same structure, which matters because the two stages
have very different effective sample sizes.

## Diagnosing the trap in an existing study

Three checks, cheap to run, that catch this before modelling:

``` r

diagnose <- function(reason, offered, eligible) {
  data.frame(
    check = c("offer-stage variation within eligible cohort",
              "exclusion categories that read as outcomes",
              "share of calls removed before the offer stage"),
    value = c(
      sprintf("%.0f%% offered", 100 * mean(offered[eligible])),
      paste(intersect(unique(reason),
                      c("Not accepting new patients", "Requires referral",
                        "Would not schedule without records")), collapse = "; "),
      sprintf("%.0f%%", 100 * mean(!eligible))
    )
  )
}
diagnose(calls$reason, calls$offered, protocol_eligible)
#>                                           check                      value
#> 1  offer-stage variation within eligible cohort               100% offered
#> 2    exclusion categories that read as outcomes Not accepting new patients
#> 3 share of calls removed before the offer stage                        40%
```

If the first row is at or near 100 percent, the offer stage has been
absorbed by the exclusion criteria and the denominator needs revisiting
before any model is fit. If the second row is non-empty, you have found
where.

## Where this fits

- [`mysterycall_hurdle_wait()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_hurdle_wait.md)
  for the joint model, and the `logistic-model` and
  `linear-mixed-models` vignettes for each stage on its own.
- The `cohort-provenance` vignette for keeping the source, eligible and
  analytic populations as separate objects, which is what makes the
  offer denominator recoverable at all.
- [`mysterycall_access_cascade()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_access_cascade.md)
  for reporting the stages as a cascade when there are more than two.
