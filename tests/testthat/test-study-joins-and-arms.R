# Jobs 23, 25, 26: safe-join conservation, insurance-arm coding, arm balance.
#
# A join that expands rows is the classic way a denominator grows without
# anyone deciding it should. The package ships a safe-join subsystem whose
# whole purpose is to make that an assertion rather than an observation, so
# these tests exercise it against a right-hand table that is deliberately not
# unique.

fixture_path <- testthat::test_path("..", "fixtures", "canonical_study.R")
skip_if_not(file.exists(fixture_path), "canonical study fixture not found")
source(fixture_path)

S         <- mc_canonical_study()
STUDY     <- S$study
PROVIDERS <- S$providers

ARM_MCD  <- "Medicaid"
ARM_BCBS <- "Blue Cross/Blue Shield"

# ---------------------------------------------------------------------------
# Job 23: safe-join conservation
# ---------------------------------------------------------------------------

test_that("a row-preserving join preserves rows exactly", {
  left  <- STUDY[, c("id_number", "insurance", "business_days_until_appointment")]
  right <- PROVIDERS[, c("provider_id", "academic")]
  names(right)[1] <- "id_number"

  before <- nrow(left)
  out <- mysterycall_safe_left_join(
    left, right, by = "id_number", expect_unique_right = TRUE
  )
  expect_equal(nrow(out), before)
  expect_true("academic" %in% names(out))
})

test_that("a non-unique right side is refused rather than silently expanding", {
  # This is the failure the subsystem exists for: joining against a table with
  # duplicate keys multiplies rows, and every downstream count is then wrong
  # while nothing has errored.
  left  <- STUDY[, c("id_number", "insurance")]
  right <- rbind(
    PROVIDERS[, c("provider_id", "academic")],
    PROVIDERS[1, c("provider_id", "academic")]      # duplicate key
  )
  names(right)[1] <- "id_number"

  expect_error(
    mysterycall_safe_left_join(left, right, by = "id_number",
                               expect_unique_right = TRUE)
  )
})

test_that("an expanding join is allowed only when explicitly permitted", {
  left  <- STUDY[, c("id_number", "insurance")]
  right <- rbind(
    PROVIDERS[, c("provider_id", "academic")],
    PROVIDERS[1, c("provider_id", "academic")]
  )
  names(right)[1] <- "id_number"

  out <- mysterycall_safe_left_join(left, right, by = "id_number",
                                    expect_unique_right = FALSE)
  # Permitted, and the expansion is real: P01's two calls each match two
  # right-hand rows. The point is that opting in was required.
  expect_gt(nrow(out), nrow(left))
})

test_that("a join that loses coverage is refused by default", {
  # Dropping P16 from the right side leaves 31 of 33 rows matched, 93.9%, which
  # is below the subsystem's default floor. It errors rather than handing back
  # a frame full of quiet NAs -- the stricter and more useful behaviour, since
  # silent NAs propagate into a model as dropped observations.
  left  <- STUDY[, c("id_number", "insurance")]
  right <- PROVIDERS[PROVIDERS$provider_id != "P16",
                     c("provider_id", "academic")]
  names(right)[1] <- "id_number"

  expect_error(
    mysterycall_safe_left_join(left, right, by = "id_number",
                               expect_unique_right = TRUE),
    "coverage"
  )
})

test_that("incomplete coverage is allowed only when the floor is lowered", {
  left  <- STUDY[, c("id_number", "insurance")]
  right <- PROVIDERS[PROVIDERS$provider_id != "P16",
                     c("provider_id", "academic")]
  names(right)[1] <- "id_number"

  out <- mysterycall_safe_left_join(left, right, by = "id_number",
                                    expect_unique_right = TRUE,
                                    min_coverage = 0.5)
  expect_equal(nrow(out), nrow(left))
  # Having opted in, the unmatched rows carry NA and are countable.
  expect_equal(sum(is.na(out$academic)), sum(STUDY$id_number == "P16"))
})

# ---------------------------------------------------------------------------
# Job 25: insurance-arm coding
# ---------------------------------------------------------------------------

test_that("only the two study arms appear, with no variants", {
  expect_setequal(unique(STUDY$insurance), c(ARM_MCD, ARM_BCBS))
})

test_that("arm labels have no whitespace or capitalisation drift", {
  arms <- unique(STUDY$insurance)
  expect_true(all(arms == trimws(arms)))
  # Case variants would produce a third and fourth group in every table.
  expect_equal(length(unique(tolower(arms))), length(arms))
  expect_true(all(nzchar(arms)))
  expect_false(any(is.na(STUDY$insurance)))
})

test_that("arm is character, never numeric coding", {
  # A numerically coded arm silently becomes a continuous predictor in a model
  # formula and the coefficient then means something entirely different.
  expect_type(STUDY$insurance, "character")
  expect_true(all(is.na(suppressWarnings(as.numeric(unique(STUDY$insurance))))))
})

test_that("no Blue Cross call carries a substantive Medicaid acceptance answer", {
  # A Blue Cross call cannot establish whether the practice accepts Medicaid.
  # "Unclear" and NA are legitimate on either arm -- P11's outcome was never
  # resolved -- but an affirmative or negative Medicaid answer on a Blue Cross
  # row would mean the arms had been crossed somewhere upstream.
  bcbs <- STUDY[STUDY$insurance == ARM_BCBS, ]
  answers <- bcbs$does_the_physician_accept_medicaid
  answers <- answers[!is.na(answers)]

  substantive <- c("Yes they accept Medicaid", "No")
  offending <- intersect(unique(answers), substantive)
  expect_equal(offending, character(0),
               info = paste("substantive Medicaid answers on BCBS rows:",
                            paste(offending, collapse = " | ")))
})

test_that("the Medicaid arm carries the substantive answers", {
  # The complement, so the test above is not passing merely because the column
  # is empty on that arm.
  mcd <- STUDY[STUDY$insurance == ARM_MCD, ]
  answers <- mcd$does_the_physician_accept_medicaid
  expect_true(any(answers %in% c("Yes they accept Medicaid", "No")))
})

# ---------------------------------------------------------------------------
# Job 26: arm balance and crossover
# ---------------------------------------------------------------------------

test_that("arm counts match the fixture's construction", {
  tab <- table(STUDY$insurance)
  expect_equal(unname(tab[[ARM_MCD]]),  17L)
  expect_equal(unname(tab[[ARM_BCBS]]), 16L)
})

test_that("exactly one provider is missing an arm, and it is the intended one", {
  by_provider <- table(STUDY$id_number, STUDY$insurance)
  missing_arm <- rownames(by_provider)[by_provider[, ARM_BCBS] == 0L |
                                         by_provider[, ARM_MCD] == 0L]
  expect_equal(missing_arm, "P14")

  # A provider silently missing an arm breaks a matched comparison without
  # breaking the model, so the count is frozen rather than merely reported.
  expect_equal(length(missing_arm), 1L)
})

test_that("the multi-location provider has both arms at both locations", {
  p04 <- STUDY[STUDY$id_number == "P04", ]
  expect_equal(nrow(p04), 4L)
  per_location <- table(p04$phone, p04$insurance)
  expect_true(all(per_location == 1L))
})

test_that("a matched-pair denominator counts pairs, not calls", {
  # Providers contributing both arms form the matched set. P04 contributes two
  # matched pairs, one per location, which is why the pair count is not simply
  # the provider count.
  key <- unique(STUDY[, c("id_number", "phone", "insurance")])
  wide <- table(paste(key$id_number, key$phone), key$insurance)
  complete_pairs <- sum(wide[, ARM_MCD] > 0L & wide[, ARM_BCBS] > 0L)

  expect_equal(complete_pairs, 16L)   # 17 locations, minus P14's single arm
  expect_lt(complete_pairs, nrow(STUDY))
})

test_that("arm assignment is balanced across callers", {
  # Both callers must work both arms, or a caller effect is confounded with the
  # exposure and cannot be separated from it afterwards.
  tab <- table(STUDY$caller_id, STUDY$insurance)
  expect_true(all(tab > 0L),
              info = paste("caller-by-arm cells:",
                           paste(as.vector(tab), collapse = ", ")))
})
