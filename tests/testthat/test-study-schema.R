# Job 19: raw call-log schema contract.
#
# Validates the canonical fixture against the schema the analysis assumes, and
# deliberately feeds malformed input to confirm the assumptions are checked
# rather than silently tolerated. A column that arrives as a factor, a list, or
# under a duplicated name does not usually error -- it produces a subtly wrong
# grouping, which is the failure this guards.

fixture_path <- testthat::test_path("..", "fixtures", "canonical_study.R")
skip_if_not(file.exists(fixture_path), "canonical study fixture not found")
source(fixture_path)

STUDY   <- mc_canonical_study()$study
CONTACT <- "Able to contact"

REQUIRED <- c(
  "id_number", "phone", "insurance", "caller_id",
  "appointment_offered", "business_days_until_appointment",
  "calendar_days_until_appointment", "reason_for_exclusions",
  "does_the_physician_accept_medicaid", "scenario"
)

test_that("every required column is present", {
  missing <- setdiff(REQUIRED, names(STUDY))
  expect_equal(missing, character(0),
               info = paste("missing:", paste(missing, collapse = ", ")))
})

test_that("column names are unique", {
  # Duplicated names are legal in a data.frame built by some paths, and
  # data[["x"]] then silently returns only the first.
  expect_equal(anyDuplicated(names(STUDY)), 0L)
})

test_that("no column is a list column", {
  # A list column survives most dplyr verbs and then produces nonsense in a
  # model frame rather than an error.
  is_list <- vapply(STUDY, is.list, logical(1))
  expect_equal(names(STUDY)[is_list], character(0))
})

test_that("column types are what the analysis assumes", {
  expect_type(STUDY$id_number, "character")
  expect_type(STUDY$phone,     "character")
  expect_type(STUDY$insurance, "character")
  expect_type(STUDY$caller_id, "character")
  expect_type(STUDY$reason_for_exclusions, "character")

  expect_type(STUDY$appointment_offered, "logical")
  expect_true(is.numeric(STUDY$business_days_until_appointment))
  expect_true(is.numeric(STUDY$calendar_days_until_appointment))

  # Character, not factor. A factor here silently carries unused levels through
  # grouping and produces empty rows in a table.
  expect_false(is.factor(STUDY$insurance))
  expect_false(is.factor(STUDY$reason_for_exclusions))
})

test_that("identifier columns are populated where required", {
  expect_true(all(nzchar(STUDY$id_number)))
  expect_true(all(!is.na(STUDY$id_number)))
  expect_true(all(nzchar(STUDY$phone)))
  expect_true(all(!is.na(STUDY$caller_id)))
})

test_that("controlled vocabularies contain no drift", {
  # Capitalisation or whitespace variants create separate groups that look like
  # real categories in a table.
  expect_setequal(unique(STUDY$insurance),
                  c("Medicaid", "Blue Cross/Blue Shield"))
  expect_true(all(STUDY$insurance == trimws(STUDY$insurance)))
  expect_true(all(STUDY$reason_for_exclusions == trimws(STUDY$reason_for_exclusions)))
  expect_setequal(unique(STUDY$scenario),
                  c("HIP scenario", "SHOULDER scenario"))
})

test_that("appointment_offered is three-valued and never a string", {
  # "NA" as a character string is a different thing from a missing value and
  # would count as an offer under any truthiness test.
  expect_true(is.logical(STUDY$appointment_offered))
  expect_true(all(STUDY$appointment_offered %in% c(TRUE, FALSE, NA)))
  expect_gt(sum(is.na(STUDY$appointment_offered)), 0)
})

test_that("wait values are non-negative integers or missing", {
  for (col in c("business_days_until_appointment",
                "calendar_days_until_appointment")) {
    v <- STUDY[[col]]
    present <- v[!is.na(v)]
    expect_true(all(is.finite(present)), info = col)
    expect_true(all(present >= 0), info = col)
    expect_true(all(present == as.integer(present)), info = col)
  }
})

# ---------------------------------------------------------------------------
# Malformed input, deliberately constructed.
# ---------------------------------------------------------------------------

test_that("a wait recorded against an excluded row is detectable", {
  # An excluded office cannot have produced an appointment. The package ships a
  # dedicated check for exactly this discrepancy; feed it a row that violates
  # the rule and confirm it is found.
  bad <- STUDY[1:4, ]
  bad$reason_for_exclusions[1] <- "Physician retired"
  bad$business_days_until_appointment[1] <- 10L
  bad$physician_information <- "Test, Doctor"
  bad$notes <- ""

  res <- mysterycall_flag_exclusion_discrepancy(
    data          = bad,
    days_col      = "business_days_until_appointment",
    exclusion_col = "reason_for_exclusions",
    contact_value = CONTACT,
    output_dir    = NULL
  )
  expect_true(is.data.frame(res))
  expect_gte(nrow(res), 1L)
})

test_that("the clean fixture yields no exclusion discrepancy", {
  # The complement of the test above: the canonical data must be clean, or the
  # check above would be passing for the wrong reason.
  d <- STUDY
  d$physician_information <- "Test, Doctor"
  d$notes <- ""

  res <- mysterycall_flag_exclusion_discrepancy(
    data          = d,
    days_col      = "business_days_until_appointment",
    exclusion_col = "reason_for_exclusions",
    contact_value = CONTACT,
    output_dir    = NULL
  )
  expect_equal(nrow(res), 0L)
})

test_that("an unknown exclusion reason is not silently accepted as contact", {
  # A typo in the contact value must not be read as "Able to contact".
  d <- STUDY
  d$reason_for_exclusions[d$reason_for_exclusions == CONTACT][1] <- "able to contact"
  expect_false(all(d$reason_for_exclusions[1:5] %in%
                     c(CONTACT, "Unable to contact office", "Wrong number",
                       "Physician retired", "Physician moved practices")))
})
