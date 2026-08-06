library(testthat)

# mysterycall_run_analysis() used to call the deprecated
# mysterycall_insurance_acceptance_rates() internally, emitting a deprecation
# warning on every run (hundreds across the test suite). It now calls the
# non-deprecated internal worker .mc_insurance_acceptance_rates() with identical
# behaviour. These tests pin that: the workflow is quiet, the public wrapper
# still warns for external callers, and the two paths return the same object.

DF <- data.frame(
  insurance                          = rep(c("Medicaid", "Blue Cross/Blue Shield"), 3),
  reason_for_exclusions              = rep("Able to contact", 6),
  business_days_until_appointment    = c(5, 8, 3, 10, 7, 6),
  phone                              = c("3035550100", "3035550100", "7205550200",
                                         "7205550200", "3035550300", "3035550300"),
  does_the_physician_accept_medicaid = rep("Yes", 6),
  stringsAsFactors = FALSE
)

test_that("run_analysis acceptance_rates step emits no deprecation warning", {
  w <- testthat::capture_warnings(suppressMessages(
    mysterycall_run_analysis(DF, steps = "acceptance_rates", output_dir = NA,
                             verbose = FALSE)
  ))
  expect_false(any(grepl("deprecated", w, ignore.case = TRUE)),
               info = paste("warnings seen:", paste(w, collapse = " | ")))
})

test_that("the internal worker itself does not warn", {
  expect_no_warning(
    mysterycall:::.mc_insurance_acceptance_rates(DF, output_dir = NA)
  )
})

test_that("the public wrapper is still deprecated (warns) for external callers", {
  expect_warning(
    mysterycall_insurance_acceptance_rates(DF, output_dir = NA),
    "deprecated"
  )
})

test_that("worker and deprecated wrapper return identical results", {
  worker <- mysterycall:::.mc_insurance_acceptance_rates(DF, output_dir = NA)
  public <- suppressWarnings(mysterycall_insurance_acceptance_rates(DF, output_dir = NA))
  expect_identical(worker, public)
})
