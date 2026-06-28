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


test_that("mysterycall_flowchart returns grViz object with valid minimal inputs", {
  skip_if_not_installed("DiagrammeR")

  result <- suppressMessages(suppressWarnings(mysterycall_flowchart(
    steps = c("Step 1" = "100", "Step 2" = "50")
  )))

  expect_s3_class(result, "grViz")
  expect_s3_class(result, "htmlwidget")
})


test_that("mysterycall_flowchart accepts exclusions, title, and custom parameters", {
  skip_if_not_installed("DiagrammeR")

  result <- suppressMessages(suppressWarnings(mysterycall_flowchart(
    steps = c(
      "Initial Cohort" = "671",
      "Functioning Phone" = "501",
      "Final Analysis" = "432"
    ),
    exclusions = c(
      "Functioning Phone" = "170 excluded: no functioning phone",
      "Final Analysis" = "69 excluded: incomplete data"
    ),
    title = "Inclusion/Exclusion Flowchart",
    node_width = 4.0,
    font_size = 12L
  )))

  expect_s3_class(result, "grViz")
})


test_that("mysterycall_flowchart works with single step", {
  skip_if_not_installed("DiagrammeR")

  result <- suppressMessages(suppressWarnings(mysterycall_flowchart(
    steps = c("All Providers" = "1000")
  )))

  expect_s3_class(result, "grViz")
})


test_that("mysterycall_flowchart rejects unnamed steps vector", {
  skip_if_not_installed("DiagrammeR")

  expect_error(
    mysterycall_flowchart(steps = c("100", "50")),
    "named character vector"
  )
})


test_that("mysterycall_flowchart rejects exclusions with non-matching step names", {
  skip_if_not_installed("DiagrammeR")

  expect_error(
    mysterycall_flowchart(
      steps = c("Step A" = "100", "Step B" = "50"),
      exclusions = c("Step C" = "30 excluded: reason")
    ),
    "do not match any step"
  )
})


test_that("mysterycall_flowchart rejects empty steps vector", {
  skip_if_not_installed("DiagrammeR")

  expect_error(
    mysterycall_flowchart(steps = c()),
    "at least one entry"
  )
})


test_that("mysterycall_flowchart rejects NULL steps", {
  skip_if_not_installed("DiagrammeR")

  expect_error(
    mysterycall_flowchart(steps = NULL),
    "named character vector"
  )
})


test_that("mysterycall_flowchart accepts NULL exclusions and title", {
  skip_if_not_installed("DiagrammeR")

  result <- suppressMessages(suppressWarnings(mysterycall_flowchart(
    steps = c("Start" = "100", "End" = "75"),
    exclusions = NULL,
    title = NULL
  )))

  expect_s3_class(result, "grViz")
})
