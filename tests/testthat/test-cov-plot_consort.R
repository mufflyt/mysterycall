library(testthat)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)

test_that("mysterycall_plot_inclexcl returns grViz object with minimal inputs", {
  skip_if_not_installed("DiagrammeR")
  counts <- c(Identified = 100, Screened = 80, Enrolled = 60)
  result <- suppressMessages(suppressWarnings(mysterycall_plot_inclexcl(counts)))
  expect_s3_class(result, "grViz")
})

test_that("mysterycall_plot_inclexcl accepts all optional parameters", {
  skip_if_not_installed("DiagrammeR")
  counts <- c(Identified = 100, Screened = 80, Enrolled = 60, Analyzed = 60)
  exclusions <- list(
    Identified = "20 excluded: no phone",
    Screened = "20 excluded: not accepting"
  )
  subspecialty_breakdown <- c(General = 40, Pediatric = 20)
  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_inclexcl(
      counts = counts,
      exclusions = exclusions,
      subspecialty_breakdown = subspecialty_breakdown,
      title = "Test Study",
      node_width = 2.5,
      font_size = 12L
    )
  ))
  expect_s3_class(result, "grViz")
})

test_that("mysterycall_plot_inclexcl rejects non-numeric counts", {
  skip_if_not_installed("DiagrammeR")
  counts <- c(a = "100", b = "80")
  expect_error(mysterycall_plot_inclexcl(counts))
})

test_that("mysterycall_plot_inclexcl rejects unnamed counts", {
  skip_if_not_installed("DiagrammeR")
  counts <- c(100, 80, 60)
  expect_error(mysterycall_plot_inclexcl(counts))
})

test_that("mysterycall_plot_inclexcl rejects counts with fewer than 2 elements", {
  skip_if_not_installed("DiagrammeR")
  counts <- c(Identified = 100)
  expect_error(mysterycall_plot_inclexcl(counts))
})

test_that("mysterycall_plot_inclexcl rejects non-list exclusions", {
  skip_if_not_installed("DiagrammeR")
  counts <- c(Identified = 100, Screened = 80)
  exclusions <- c("Identified" = "10 excluded")
  expect_error(mysterycall_plot_inclexcl(counts, exclusions))
})

test_that("mysterycall_plot_inclexcl rejects exclusions with invalid phase names", {
  skip_if_not_installed("DiagrammeR")
  counts <- c(Identified = 100, Screened = 80)
  exclusions <- list(BadPhase = "10 excluded")
  expect_error(mysterycall_plot_inclexcl(counts, exclusions))
})

test_that("mysterycall_plot_inclexcl handles edge case with 2 phases and no exclusions", {
  skip_if_not_installed("DiagrammeR")
  counts <- c(A = 100, B = 50)
  result <- suppressMessages(suppressWarnings(mysterycall_plot_inclexcl(counts)))
  expect_s3_class(result, "grViz")
})

test_that("mysterycall_plot_inclexcl handles single exclusion", {
  skip_if_not_installed("DiagrammeR")
  counts <- c(Identified = 100, Screened = 80, Enrolled = 60)
  exclusions <- list(Screened = "20 excluded")
  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_inclexcl(counts, exclusions)
  ))
  expect_s3_class(result, "grViz")
})

test_that("mysterycall_plot_inclexcl handles special characters in labels", {
  skip_if_not_installed("DiagrammeR")
  counts <- c('Phase "A"' = 100, 'Phase "B"' = 80)
  result <- suppressMessages(suppressWarnings(mysterycall_plot_inclexcl(counts)))
  expect_s3_class(result, "grViz")
})

test_that("mysterycall_plot_inclexcl handles large numbers with proper formatting", {
  skip_if_not_installed("DiagrammeR")
  counts <- c(Identified = 10000, Screened = 8000, Enrolled = 6000)
  result <- suppressMessages(suppressWarnings(mysterycall_plot_inclexcl(counts)))
  expect_s3_class(result, "grViz")
})
