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

test_that("mysterycall_scenario_summary returns correct structure with valid data", {
  df <- data.frame(
    scenario = c("HIP", "HIP", "SHOULDER", "KNEE", "HIP"),
    status = rep("Able to contact", 5L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(df, output_dir = NA)
  )

  expect_type(result, "list")
  expect_named(result, c("counts", "total", "sentence", "contact_counts"))
  expect_s3_class(result$counts, "tbl_df")
  expect_true(is.integer(result$total))
  expect_true(is.character(result$sentence))
  expect_null(result$contact_counts)
})

test_that("mysterycall_scenario_summary counts scenarios correctly and orders by count desc", {
  df <- data.frame(
    scenario = c("HIP", "HIP", "SHOULDER", "KNEE", "HIP"),
    status = rep("Able to contact", 5L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(df, output_dir = NA)
  )

  expect_equal(result$total, 5L)
  expect_equal(nrow(result$counts), 3L)
  expect_equal(names(result$counts), c("scenario", "count", "percent"))

  # Should be ordered by count descending
  expect_equal(result$counts$count, c(3L, 1L, 1L))
  expect_equal(result$counts$scenario[1L], "HIP")

  # Check percentages
  expect_equal(result$counts$percent, c(60.0, 20.0, 20.0))
})

test_that("mysterycall_scenario_summary builds generic sentence when scenario_levels is NULL", {
  df <- data.frame(
    scenario = c("HIP", "HIP", "SHOULDER"),
    status = rep("Able to contact", 3L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(df, scenario_levels = NULL, output_dir = NA)
  )

  # Generic sentence format: "There were N calls across K scenarios: ..."
  expect_true(grepl("^There were", result$sentence))
  expect_true(grepl("calls", result$sentence))
  expect_true(grepl("scenarios", result$sentence))
  expect_true(grepl("HIP", result$sentence))
})

test_that("mysterycall_scenario_summary builds named-template sentence with scenario_levels", {
  df <- data.frame(
    scenario = c("HIP scenario", "HIP scenario", "SHOULDER scenario", "KNEE scenario"),
    status = rep("Able to contact", 4L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(
      df,
      scenario_levels = c(
        hip = "HIP scenario",
        shoulder = "SHOULDER scenario",
        knee = "KNEE scenario"
      ),
      output_dir = NA
    )
  )

  # Named-template uses sports-medicine phrasing
  expect_true(grepl("sports medicine orthopedists", result$sentence))
  expect_true(grepl("calls", result$sentence))
})

test_that("mysterycall_scenario_summary handles zero-row data frame", {
  df <- data.frame(
    scenario = character(0L),
    status = character(0L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(df, output_dir = NA)
  )

  expect_equal(result$total, 0L)
  expect_equal(nrow(result$counts), 0L)
  expect_equal(result$sentence, "There were 0 calls across 0 scenarios.")
})

test_that("mysterycall_scenario_summary filters by contact status when contact_col provided", {
  df <- data.frame(
    scenario = c("HIP", "HIP", "SHOULDER", "KNEE", "HIP"),
    status = c("Able to contact", "Unable to contact", "Able to contact",
               "Able to contact", "Able to contact"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(
      df,
      contact_col = "status",
      contact_value = "Able to contact",
      output_dir = NA
    )
  )

  # contact_counts should exclude the "Unable to contact" row
  expect_s3_class(result$contact_counts, "tbl_df")
  expect_equal(nrow(result$contact_counts), 3L)
  expect_equal(result$contact_counts$count, c(2L, 1L, 1L))

  # total should still reflect full data (5 rows)
  expect_equal(result$total, 5L)
})

test_that("mysterycall_scenario_summary returns empty tibble when no contact matches", {
  df <- data.frame(
    scenario = c("HIP", "HIP", "SHOULDER"),
    status = c("Unable", "Unable", "Unable"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(
      df,
      contact_col = "status",
      contact_value = "Able to contact",
      output_dir = NA
    )
  )

  expect_s3_class(result$contact_counts, "tbl_df")
  expect_equal(nrow(result$contact_counts), 0L)
  expect_equal(names(result$contact_counts), c("scenario", "count", "percent"))
})

test_that("mysterycall_scenario_summary handles NA values in contact_col", {
  df <- data.frame(
    scenario = c("HIP", "HIP", "SHOULDER", "KNEE"),
    status = c("Able to contact", NA, "Able to contact", "Unable"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(
      df,
      contact_col = "status",
      contact_value = "Able to contact",
      output_dir = NA
    )
  )

  # Should exclude NA rows and "Unable" rows
  expect_equal(nrow(result$contact_counts), 2L)
  expect_equal(sum(result$contact_counts$count), 2L)
})

test_that("mysterycall_scenario_summary errors when scenario_col missing from data", {
  df <- data.frame(
    not_scenario = c("HIP", "SHOULDER"),
    status = c("Able to contact", "Able to contact"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_scenario_summary(df, scenario_col = "scenario", output_dir = NA),
    "must.include"
  )
})

test_that("mysterycall_scenario_summary errors when contact_col missing from data", {
  df <- data.frame(
    scenario = c("HIP", "SHOULDER"),
    status = c("Able to contact", "Able to contact"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_scenario_summary(
      df,
      contact_col = "missing_col",
      output_dir = NA
    ),
    "must.include"
  )
})

test_that("mysterycall_scenario_summary errors on unnamed character vector for scenario_levels", {
  df <- data.frame(
    scenario = c("HIP", "SHOULDER"),
    status = c("Able to contact", "Able to contact"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_scenario_summary(
      df,
      scenario_levels = c("HIP", "SHOULDER"),
      output_dir = NA
    ),
    "must be a named character vector"
  )
})

test_that("mysterycall_scenario_summary errors when data is not a data frame", {
  expect_error(
    mysterycall_scenario_summary(
      list(scenario = "HIP"),
      output_dir = NA
    ),
    "data.frame"
  )
})

test_that("mysterycall_scenario_summary errors when scenario_col is not a string", {
  df <- data.frame(
    scenario = c("HIP", "SHOULDER"),
    status = c("Able to contact", "Able to contact"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_scenario_summary(
      df,
      scenario_col = 123,
      output_dir = NA
    ),
    "string"
  )
})

test_that("mysterycall_scenario_summary handles single scenario", {
  df <- data.frame(
    scenario = c("HIP", "HIP", "HIP"),
    status = rep("Able to contact", 3L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(df, output_dir = NA)
  )

  expect_equal(result$total, 3L)
  expect_equal(nrow(result$counts), 1L)
  expect_equal(result$counts$scenario, "HIP")
  expect_equal(result$counts$percent, 100.0)
})

test_that("mysterycall_scenario_summary respects custom scenario_col name", {
  df <- data.frame(
    custom_scenario = c("A", "A", "B"),
    status = rep("Able to contact", 3L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(
      df,
      scenario_col = "custom_scenario",
      output_dir = NA
    )
  )

  expect_equal(result$counts$scenario, c("A", "B"))
  expect_equal(result$counts$count, c(2L, 1L))
})

test_that("mysterycall_scenario_summary respects custom contact value", {
  df <- data.frame(
    scenario = c("HIP", "HIP", "SHOULDER"),
    status = c("YES", "NO", "YES"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(
      df,
      contact_col = "status",
      contact_value = "YES",
      output_dir = NA
    )
  )

  expect_equal(nrow(result$contact_counts), 2L)
  expect_equal(sum(result$contact_counts$count), 2L)
})

test_that("mysterycall_scenario_summary sentence handles two scenarios", {
  df <- data.frame(
    scenario = c("hip scenario", "shoulder scenario"),
    status = rep("Able to contact", 2L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(
      df,
      scenario_levels = c(hip = "hip scenario", shoulder = "shoulder scenario"),
      output_dir = NA
    )
  )

  # Two-item template should use " and "
  expect_true(grepl(" and ", result$sentence))
})

test_that("mysterycall_scenario_summary sentence handles three or more scenarios", {
  df <- data.frame(
    scenario = c("hip", "shoulder", "knee", "ankle"),
    status = rep("Able to contact", 4L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_scenario_summary(
      df,
      scenario_levels = c(
        hip = "hip", shoulder = "shoulder",
        knee = "knee", ankle = "ankle"
      ),
      output_dir = NA
    )
  )

  # Three+ items should use oxford-comma style
  expect_true(grepl(", and ", result$sentence))
})
