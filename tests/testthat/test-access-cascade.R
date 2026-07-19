# Tests for mysterycall_access_cascade() + mysterycall_cascade_stage()

make_cascade_data <- function() {
  data.frame(
    office_answered     = c(TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE),
    new_patient_status  = c("Accepting", "Accepting", "Not accepting: full",
                            "Accepting", NA, "Accepting", "Not accepting: insurance",
                            "Accepting"),
    sees_complaint      = c("Yes", "Yes", "No", "Yes", NA, "Yes", "No", "Yes"),
    appointment_offered = c(TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE),
    appointment_outcome = c("With sampled physician", "No appointment offered",
                            "No appointment offered", "With different physician",
                            "No appointment offered", "With sampled physician",
                            "No appointment offered", "With sampled physician"),
    stringsAsFactors = FALSE
  )
}

test_that("basic cascade counts, denominators, and percentages are correct", {
  d <- make_cascade_data()
  res <- mysterycall_access_cascade(d, list(
    mysterycall_cascade_stage("Reached office", "office_answered", TRUE),
    mysterycall_cascade_stage("Accepting", "new_patient_status", "Accepting"),
    mysterycall_cascade_stage("Offered", "appointment_offered", TRUE)
  ))
  expect_s3_class(res, "mysterycall_access_cascade")
  expect_equal(res$n_total, 8L)
  expect_equal(res$table$n, c(7L, 5L, 4L))
  expect_true(all(res$table$denominator == 8))
  expect_equal(res$table$pct, c(7, 5, 4) / 8 * 100)
})

test_that("NA never counts as a hit", {
  d <- make_cascade_data()
  # office_answered has one FALSE and no NA -> 7 hits; sees_complaint has 2 NA
  res <- mysterycall_access_cascade(d, list(
    mysterycall_cascade_stage("Sees complaint", "sees_complaint", "Yes")
  ))
  expect_equal(res$table$n, 5L)   # five "Yes", two "No", one NA-driven miss
})

test_that("denominator = 'previous' produces a strict nested funnel", {
  d <- make_cascade_data()
  res <- mysterycall_access_cascade(d, list(
    mysterycall_cascade_stage("Reached office", "office_answered", TRUE),
    mysterycall_cascade_stage("Offered", "appointment_offered", TRUE,
                              denominator = "previous")
  ))
  expect_equal(res$table$denominator, c(8, 7))
  expect_equal(res$table$pct[2], 4 / 7 * 100)
})

test_that("a by-name denominator references an earlier stage's hit count", {
  d <- make_cascade_data()
  res <- mysterycall_access_cascade(d, list(
    mysterycall_cascade_stage("Offered", "appointment_offered", TRUE),
    mysterycall_cascade_stage("With sampled MD", "appointment_outcome",
                              "With sampled physician",
                              denominator = "Offered", group = "Whom")
  ))
  expect_equal(res$table$denominator, c(8, 4))  # 4 offered
  expect_equal(res$table$n, c(4L, 3L))          # 3 with sampled physician
})

test_that("a numeric denominator is used verbatim", {
  d <- make_cascade_data()
  res <- mysterycall_access_cascade(d, list(
    mysterycall_cascade_stage("Accepting", "new_patient_status", "Accepting",
                              denominator = 100)
  ))
  expect_equal(res$table$denominator, 100)
  expect_equal(res$table$pct, 5)
})

test_that("a success predicate function is honoured", {
  d <- make_cascade_data()
  res <- mysterycall_access_cascade(d, list(
    mysterycall_cascade_stage(
      "Any not-accepting", "new_patient_status",
      success = function(x) grepl("^Not accepting", x))
  ))
  expect_equal(res$table$n, 2L)
})

test_that("Wilson CI columns are present, ordered, and in [0, 100]", {
  d <- make_cascade_data()
  res <- mysterycall_access_cascade(d, list(
    mysterycall_cascade_stage("Offered", "appointment_offered", TRUE)
  ))
  expect_true(all(c("ci_lower", "ci_upper") %in% names(res$table)))
  expect_true(res$table$ci_lower <= res$table$pct)
  expect_true(res$table$ci_upper >= res$table$pct)
  expect_true(res$table$ci_lower >= 0 && res$table$ci_upper <= 100)
})

test_that("raw-list stages are accepted (no constructor)", {
  d <- make_cascade_data()
  res <- mysterycall_access_cascade(d, list(
    list(label = "Offered", column = "appointment_offered", success = TRUE)
  ))
  expect_equal(res$table$n, 4L)
})

test_that("duplicate stage labels error", {
  d <- make_cascade_data()
  expect_error(
    mysterycall_access_cascade(d, list(
      mysterycall_cascade_stage("X", "office_answered", TRUE),
      mysterycall_cascade_stage("X", "appointment_offered", TRUE)
    )),
    "unique"
  )
})

test_that("a missing column errors with the stage name", {
  d <- make_cascade_data()
  expect_error(
    mysterycall_access_cascade(d, list(
      mysterycall_cascade_stage("Bad", "nope", TRUE)
    )),
    "not in `data`"
  )
})

test_that("'previous' on the first stage errors", {
  d <- make_cascade_data()
  expect_error(
    mysterycall_access_cascade(d, list(
      mysterycall_cascade_stage("First", "office_answered", TRUE,
                                denominator = "previous")
    )),
    "first"
  )
})

test_that("an unknown by-name denominator errors", {
  d <- make_cascade_data()
  expect_error(
    mysterycall_access_cascade(d, list(
      mysterycall_cascade_stage("A", "office_answered", TRUE,
                                denominator = "Nonexistent")
    )),
    "does not name an earlier stage"
  )
})

test_that("as.data.frame returns the table and CSV export works", {
  d <- make_cascade_data()
  dir <- withr::local_tempdir()
  res <- mysterycall_access_cascade(
    d, list(mysterycall_cascade_stage("Offered", "appointment_offered", TRUE)),
    output_dir = dir, filename = "cascade.csv")
  df <- as.data.frame(res)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 1L)
  expect_true(file.exists(file.path(dir, "cascade.csv")))
})

test_that("plot = TRUE attaches a ggplot", {
  skip_if_not_installed("ggplot2")
  d <- make_cascade_data()
  res <- mysterycall_access_cascade(
    d, list(mysterycall_cascade_stage("Offered", "appointment_offered", TRUE)),
    plot = TRUE)
  expect_s3_class(res$plot, "ggplot")
})
