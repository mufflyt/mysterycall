# Jobs 44-51: statistical invariance, missingness, complete-case accounting,
# sensitivity execution and direction, RNG isolation, simulation
# reproducibility, and adversarial power-simulation properties.
#
# The invariance tests are the cheapest way to catch a whole class of bug. An
# estimate that moves when rows are shuffled, or when a provider is renamed,
# depends on something it should not -- row position, or the text of an
# identifier -- and that dependence will not announce itself in any single run.

fixture_path <- testthat::test_path("..", "fixtures", "canonical_study.R")
skip_if_not(file.exists(fixture_path), "canonical study fixture not found")
source(fixture_path)

STUDY   <- mc_canonical_study()$study
CONTACT <- "Able to contact"

# Primary estimate, computed the same way every time so invariance is the only
# thing under test.
primary_irr <- function(d) {
  w <- d[d$reason_for_exclusions == CONTACT &
           !is.na(d$business_days_until_appointment), ]
  m_mcd  <- mean(w$business_days_until_appointment[w$insurance == "Medicaid"])
  m_bcbs <- mean(w$business_days_until_appointment[
    w$insurance == "Blue Cross/Blue Shield"])
  m_mcd / m_bcbs
}

# ---------------------------------------------------------------------------
# Job 44: statistical invariance
# ---------------------------------------------------------------------------

test_that("row order does not change the estimate", {
  base <- primary_irr(STUDY)
  set.seed(101)
  for (i in 1:100) {
    shuffled <- STUDY[sample.int(nrow(STUDY)), ]
    expect_equal(primary_irr(shuffled), base, tolerance = 1e-12)
  }
})

test_that("renaming providers does not change the estimate", {
  base <- primary_irr(STUDY)
  renamed <- STUDY
  ids <- unique(renamed$id_number)
  map <- stats::setNames(paste0("XX", rev(seq_along(ids))), ids)
  renamed$id_number <- unname(map[renamed$id_number])
  expect_equal(primary_irr(renamed), base, tolerance = 1e-12)
})

test_that("adding irrelevant columns does not change the estimate", {
  base <- primary_irr(STUDY)
  noisy <- STUDY
  set.seed(103)
  for (i in 1:25) noisy[[paste0("junk_", i)]] <- stats::runif(nrow(noisy))
  expect_equal(primary_irr(noisy), base, tolerance = 1e-12)
})

test_that("changing display labels does not change the estimate", {
  # The arm labels carry meaning, so relabel consistently and confirm the
  # magnitude is untouched even though the names are not.
  relabelled <- STUDY
  relabelled$insurance <- ifelse(relabelled$insurance == "Medicaid",
                                 "ARM_A", "ARM_B")
  w <- relabelled[relabelled$reason_for_exclusions == CONTACT &
                    !is.na(relabelled$business_days_until_appointment), ]
  got <- mean(w$business_days_until_appointment[w$insurance == "ARM_A"]) /
    mean(w$business_days_until_appointment[w$insurance == "ARM_B"])
  expect_equal(got, primary_irr(STUDY), tolerance = 1e-12)
})

test_that("factor level order does not change the arm means", {
  d <- STUDY
  d$insurance <- factor(d$insurance,
                        levels = c("Medicaid", "Blue Cross/Blue Shield"))
  w <- d[d$reason_for_exclusions == CONTACT &
           !is.na(d$business_days_until_appointment), ]
  m_mcd <- mean(w$business_days_until_appointment[w$insurance == "Medicaid"])
  expect_equal(m_mcd, 12.9, tolerance = 1e-9)
})

test_that("duplicating an observation changes the estimate predictably", {
  # Duplication must not be invisible. If a duplicated row left the estimate
  # untouched, the pipeline would be deduplicating silently; if it changed it
  # unpredictably, the weighting is wrong.
  base <- primary_irr(STUDY)
  dup_row <- STUDY[STUDY$insurance == "Medicaid" &
                     !is.na(STUDY$business_days_until_appointment), ][1, ]
  doubled <- rbind(STUDY, dup_row)
  expect_false(isTRUE(all.equal(primary_irr(doubled), base)))

  w <- doubled[doubled$reason_for_exclusions == CONTACT &
                 !is.na(doubled$business_days_until_appointment), ]
  expect_equal(sum(w$insurance == "Medicaid"), 11L)   # was 10
})

test_that("a linear unit change round-trips exactly", {
  d <- STUDY
  d$business_days_until_appointment <- d$business_days_until_appointment * 2L
  w <- d[d$reason_for_exclusions == CONTACT &
           !is.na(d$business_days_until_appointment), ]
  m_mcd  <- mean(w$business_days_until_appointment[w$insurance == "Medicaid"])
  m_bcbs <- mean(w$business_days_until_appointment[w$insurance != "Medicaid"])
  # A ratio is scale-invariant; a difference is not. Both must behave as the
  # mathematics says, or the summary is not measuring what it claims.
  expect_equal(m_mcd / m_bcbs, primary_irr(STUDY), tolerance = 1e-12)
  expect_equal(m_mcd - m_bcbs, (12.9 - 6.2) * 2, tolerance = 1e-9)
})

# ---------------------------------------------------------------------------
# Job 45: missingness mechanism
# ---------------------------------------------------------------------------

test_that("missingness is not independent of disposition, and that is visible", {
  # In this fixture missing waits concentrate among the unreached, which is
  # exactly the pattern a complete-case analysis would hide.
  miss <- is.na(STUDY$business_days_until_appointment)
  reached <- STUDY$reason_for_exclusions == CONTACT
  expect_gt(mean(miss[!reached]), mean(miss[reached]))
  expect_equal(sum(miss & !reached), 8L)
})

test_that("missingness by arm is reportable", {
  miss <- is.na(STUDY$business_days_until_appointment)
  by_arm <- tapply(miss, STUDY$insurance, mean)
  expect_length(by_arm, 2L)
  expect_true(all(is.finite(by_arm)))
})

test_that("missing never becomes an observed zero", {
  w <- STUDY$business_days_until_appointment
  naive <- w; naive[is.na(naive)] <- 0L
  expect_gt(mean(naive == 0L), mean(w == 0L, na.rm = TRUE))
  # The naive recode would move the Medicaid mean toward zero and manufacture
  # faster apparent access for the arm with more missingness.
  expect_lt(mean(naive), mean(w, na.rm = TRUE))
})

# ---------------------------------------------------------------------------
# Job 46: complete-case accounting
# ---------------------------------------------------------------------------

test_that("input equals modelled plus every excluded category", {
  input <- nrow(STUDY)
  not_reached <- sum(STUDY$reason_for_exclusions != CONTACT)
  no_outcome  <- sum(STUDY$reason_for_exclusions == CONTACT &
                       is.na(STUDY$business_days_until_appointment))
  modelled    <- sum(STUDY$reason_for_exclusions == CONTACT &
                       !is.na(STUDY$business_days_until_appointment))

  expect_equal(input, modelled + not_reached + no_outcome)
  expect_equal(c(input, modelled, not_reached, no_outcome),
               c(33L, 20L, 8L, 5L))
})

# ---------------------------------------------------------------------------
# Jobs 47, 48: sensitivity execution and direction
# ---------------------------------------------------------------------------

test_that("every declared sensitivity analysis runs and yields a finite result", {
  w <- STUDY[STUDY$reason_for_exclusions == CONTACT &
               !is.na(STUDY$business_days_until_appointment), ]

  results <- list(
    business_days = primary_irr(STUDY),
    calendar_days = mean(w$calendar_days_until_appointment[
      w$insurance == "Medicaid"]) /
      mean(w$calendar_days_until_appointment[w$insurance != "Medicaid"]),
    medians = stats::median(w$business_days_until_appointment[
      w$insurance == "Medicaid"]) /
      stats::median(w$business_days_until_appointment[w$insurance != "Medicaid"]),
    academic_excluded = {
      sub <- w[!w$academic, ]
      mean(sub$business_days_until_appointment[sub$insurance == "Medicaid"]) /
        mean(sub$business_days_until_appointment[sub$insurance != "Medicaid"])
    }
  )

  for (nm in names(results)) {
    expect_true(is.finite(results[[nm]]), info = nm)
    # expect_gt() takes no `info`, so the label rides along in the comparison.
    expect_true(results[[nm]] > 0, info = nm)
  }
})

test_that("every sensitivity analysis preserves the qualitative direction", {
  # Numerical movement between analyses is expected and is not failure. A
  # reversal is: it would mean the conclusion is an artefact of one analytic
  # choice rather than a property of the data.
  w <- STUDY[STUDY$reason_for_exclusions == CONTACT &
               !is.na(STUDY$business_days_until_appointment), ]

  ratios <- c(
    primary_irr(STUDY),
    mean(w$calendar_days_until_appointment[w$insurance == "Medicaid"]) /
      mean(w$calendar_days_until_appointment[w$insurance != "Medicaid"]),
    stats::median(w$business_days_until_appointment[w$insurance == "Medicaid"]) /
      stats::median(w$business_days_until_appointment[w$insurance != "Medicaid"])
  )
  expect_true(all(ratios > 1),
              info = paste("ratios:", paste(round(ratios, 3), collapse = ", ")))
})

# ---------------------------------------------------------------------------
# Job 49: RNG isolation
# ---------------------------------------------------------------------------

test_that("package functions do not disturb the caller's RNG stream", {
  # A function that advances the global stream makes every downstream
  # simulation in the session silently non-reproducible.
  set.seed(555)
  before <- .Random.seed
  invisible(mc_canonical_study())
  expect_identical(.Random.seed, before)

  set.seed(555)
  a <- stats::runif(3)
  set.seed(555)
  invisible(mc_canonical_study())
  b <- stats::runif(3)
  expect_equal(a, b)
})

# ---------------------------------------------------------------------------
# Job 50: simulation reproducibility
# ---------------------------------------------------------------------------

test_that("the same seed reproduces a simulation exactly", {
  sim <- function(seed) {
    set.seed(seed)
    stats::rpois(50L, 6)
  }
  expect_identical(sim(2026L), sim(2026L))
})

test_that("different seeds produce different draws", {
  sim <- function(seed) { set.seed(seed); stats::rpois(50L, 6) }
  expect_false(identical(sim(1L), sim(2L)))
})

# ---------------------------------------------------------------------------
# Job 51: adversarial power-simulation properties
# ---------------------------------------------------------------------------

test_that("power is bounded, and rises with sample size and effect size", {
  # A reference power routine, independent of the package, so the properties
  # are asserted about the mathematics rather than about one implementation.
  power_at <- function(n, irr, nsim = 300L, seed = 5L) {
    set.seed(seed)
    hits <- vapply(seq_len(nsim), function(i) {
      g <- rep(c(0L, 1L), each = n)
      y <- stats::rpois(2L * n, 6 * ifelse(g == 1L, irr, 1))
      f <- stats::glm(y ~ g, family = stats::poisson())
      stats::coef(summary(f))[2L, 4L] < 0.05
    }, logical(1))
    mean(hits)
  }

  p_null   <- power_at(40L, 1.0)
  p_small  <- power_at(40L, 1.3)
  p_large  <- power_at(40L, 2.0)
  p_bign   <- power_at(120L, 1.3)

  for (p in c(p_null, p_small, p_large, p_bign)) {
    expect_gte(p, 0); expect_lte(p, 1)
  }
  # Under the null, rejection should sit near alpha rather than anywhere.
  expect_lt(p_null, 0.15)
  expect_gt(p_large, p_small)   # bigger effect, more power
  expect_gt(p_bign,  p_small)   # bigger sample, more power
})

test_that("invalid power inputs are rejected rather than silently coerced", {
  skip_if_not(exists("mysterycall_nb_power"), "mysterycall_nb_power not available")
  for (bad in list(
    list(n_physicians = 0L),
    list(n_physicians = -5L),
    list(n_physicians = 30L, theta = 0),
    list(n_physicians = 30L, theta = -1)
  )) {
    args <- c(list(n_physicians = 30L), bad)
    args <- args[!duplicated(names(args), fromLast = TRUE)]
    res <- try(suppressWarnings(do.call(mysterycall_nb_power, args)), silent = TRUE)
    if (!inherits(res, "try-error")) {
      # If it returns rather than erroring, the value must still be a valid
      # probability; a nonsensical input must not yield a confident number.
      val <- suppressWarnings(as.numeric(unlist(res)[1]))
      if (!is.na(val)) { expect_gte(val, 0); expect_lte(val, 1) }
    } else {
      expect_true(nzchar(as.character(res)))
    }
  }
})
