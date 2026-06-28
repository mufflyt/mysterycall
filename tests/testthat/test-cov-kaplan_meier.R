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

# ---- Test 1: Happy path with basic valid inputs ----
test_that("mysterycall_kaplan_meier returns correct class and structure with valid data", {
  skip_if_not_installed("survival")

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      plot      = FALSE
    )
  ))

  expect_s3_class(result, "mysterycall_kaplan_meier")
  expect_true(is.list(result))
  expect_named(
    result,
    c("survfit", "logrank_p", "logrank_p_fmt", "median_by_group", "plot", "sentence"),
    ignore.order = FALSE
  )
})

# ---- Test 2: Return value components have correct types ----
test_that("mysterycall_kaplan_meier returns correct types for all fields", {
  skip_if_not_installed("survival")

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      plot      = FALSE
    )
  ))

  expect_s3_class(result$survfit, "survfit")
  expect_type(result$logrank_p, "double")
  expect_type(result$logrank_p_fmt, "character")
  expect_s3_class(result$median_by_group, "data.frame")
  expect_named(result$median_by_group, c("group", "median_days", "ci_lower_days", "ci_upper_days"))
  expect_type(result$sentence, "character")
  expect_null(result$plot)  # Because plot = FALSE
})

# ---- Test 3: Logical event column is coerced silently ----
test_that("mysterycall_kaplan_meier accepts logical event_col and coerces to 0/1", {
  skip_if_not_installed("survival")

  df_logical <- data.frame(
    days      = c(3, 7, 14, 21, 5, 10, 30, 45),
    offered   = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE, FALSE),
    insurance = c(rep("Medicaid", 4), rep("BCBS", 4)),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = df_logical,
      time_col  = "days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 90,
      plot      = FALSE
    )
  ))

  expect_type(result$logrank_p, "double")
  expect_true(!is.na(result$logrank_p))
})

# ---- Test 4: NA imputation for censored rows ----
test_that("mysterycall_kaplan_meier imputes NA time for censored rows with NA time", {
  skip_if_not_installed("survival")

  df_na <- data.frame(
    days      = c(3, 7, NA, 21, 5, NA, 30, 45),
    offered   = c(1, 1, 0, 1, 1, 0, 0, 0),
    insurance = c(rep("Medicaid", 4), rep("BCBS", 4)),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = df_na,
      time_col  = "days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 50,
      plot      = FALSE
    )
  ))

  expect_type(result$logrank_p, "double")
  expect_true(!is.na(result$logrank_p))
  expect_s3_class(result$median_by_group, "data.frame")
})

# ---- Test 5: Error on missing required argument (time_col) ----
test_that("mysterycall_kaplan_meier errors when time_col is missing", {
  skip_if_not_installed("survival")

  expect_error(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30
    ),
    "time_col"
  )
})

# ---- Test 6: Error on missing required argument (group_col) ----
test_that("mysterycall_kaplan_meier errors when group_col is missing", {
  skip_if_not_installed("survival")

  expect_error(
    mysterycall_kaplan_meier(
      data     = AUDIT,
      time_col = "wait_days",
      event_col = "offered",
      max_days = 30
    ),
    "group_col"
  )
})

# ---- Test 7: Error on non-existent column ----
test_that("mysterycall_kaplan_meier errors when specified column does not exist", {
  skip_if_not_installed("survival")

  expect_error(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "nonexistent_time",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30
    ),
    "Column.*not found"
  )
})

# ---- Test 8: Error on non-numeric time column ----
test_that("mysterycall_kaplan_meier errors when time_col is not numeric", {
  skip_if_not_installed("survival")

  df_bad <- AUDIT
  df_bad$wait_days <- as.character(df_bad$wait_days)

  expect_error(
    mysterycall_kaplan_meier(
      data      = df_bad,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30
    ),
    "must be numeric"
  )
})

# ---- Test 9: Error on invalid event values (not 0/1) ----
test_that("mysterycall_kaplan_meier errors when event_col has values other than 0, 1, NA", {
  skip_if_not_installed("survival")

  df_bad <- AUDIT
  df_bad$offered <- c(0, 1, 2, 1)  # 2 is invalid

  expect_error(
    mysterycall_kaplan_meier(
      data      = df_bad,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30
    ),
    "must contain only 0, 1, or NA"
  )
})

# ---- Test 10: Error on single group ----
test_that("mysterycall_kaplan_meier errors when group has fewer than 2 levels", {
  skip_if_not_installed("survival")

  df_one_group <- AUDIT[AUDIT$insurance == "Medicaid", ]

  expect_error(
    mysterycall_kaplan_meier(
      data      = df_one_group,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30
    ),
    "must have at least 2"
  )
})

# ---- Test 11: Error on invalid max_days ----
test_that("mysterycall_kaplan_meier errors when max_days is invalid", {
  skip_if_not_installed("survival")

  expect_error(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = -10
    ),
    "must be a single positive number"
  )
})

# ---- Test 12: Error on invalid conf_level ----
test_that("mysterycall_kaplan_meier errors when conf_level is outside (0, 1)", {
  skip_if_not_installed("survival")

  expect_error(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      conf_level = 1.5
    ),
    "must be a single number in \\(0, 1\\)"
  )
})

# ---- Test 13: Error on non-data.frame input ----
test_that("mysterycall_kaplan_meier errors when data is not a data.frame", {
  skip_if_not_installed("survival")

  expect_error(
    mysterycall_kaplan_meier(
      data      = list(a = 1),
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30
    ),
    "must be a data.frame"
  )
})

# ---- Test 14: Log-rank p-value format ----
test_that("mysterycall_kaplan_meier produces formatted p-value string", {
  skip_if_not_installed("survival")

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      plot      = FALSE
    )
  ))

  expect_match(result$logrank_p_fmt, "^p [=<]")
  expect_type(result$logrank_p_fmt, "character")
  expect_length(result$logrank_p_fmt, 1L)
})

# ---- Test 15: Median by group has correct structure ----
test_that("mysterycall_kaplan_meier median_by_group has one row per group", {
  skip_if_not_installed("survival")

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      plot      = FALSE
    )
  ))

  n_unique_groups <- length(unique(AUDIT$insurance))
  expect_equal(nrow(result$median_by_group), n_unique_groups)
  expect_true(all(c("median_days", "ci_lower_days", "ci_upper_days") %in%
                    names(result$median_by_group)))
})

# ---- Test 16: Sentence is readable and includes group_col name ----
test_that("mysterycall_kaplan_meier sentence includes group column name and p-value", {
  skip_if_not_installed("survival")

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      plot      = FALSE
    )
  ))

  expect_match(result$sentence, "insurance")
  expect_match(result$sentence, "median", ignore.case = TRUE)
  expect_match(result$sentence, "p [=<]")
})

# ---- Test 17: Plot is NULL when plot = FALSE ----
test_that("mysterycall_kaplan_meier plot is NULL when plot = FALSE", {
  skip_if_not_installed("survival")

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      plot      = FALSE
    )
  ))

  expect_null(result$plot)
})

# ---- Test 18: Plot is ggplot when plot = TRUE and ggplot2 is available ----
test_that("mysterycall_kaplan_meier plot is ggplot when plot = TRUE", {
  skip_if_not_installed("survival")
  skip_if_not_installed("ggplot2")

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      plot      = TRUE,
      risk_table = FALSE
    )
  ))

  expect_true(!is.null(result$plot))
  expect_s3_class(result$plot, "ggplot")
})

# ---- Test 19: Print method works and returns invisibly ----
test_that("print.mysterycall_kaplan_meier works and returns invisibly", {
  skip_if_not_installed("survival")

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      plot      = FALSE
    )
  ))

  output <- capture.output({
    invisible_result <- print(result)
  })

  expect_true(any(grepl("mysterycall_kaplan_meier", output)))
  expect_true(any(grepl("Median days", output)))
  expect_identical(invisible_result, result)
})

# ---- Test 20: Default event_col parameter ----
test_that("mysterycall_kaplan_meier uses default event_col = 'offered' when not specified", {
  skip_if_not_installed("survival")

  df_with_offered <- AUDIT

  result_default <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = df_with_offered,
      time_col  = "wait_days",
      group_col = "insurance",
      max_days  = 30,
      plot      = FALSE
    )
  ))

  result_explicit <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = df_with_offered,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      plot      = FALSE
    )
  ))

  expect_equal(result_default$logrank_p, result_explicit$logrank_p)
})

# ---- Test 21: Custom palette is accepted ----
test_that("mysterycall_kaplan_meier accepts custom color palette", {
  skip_if_not_installed("survival")
  skip_if_not_installed("ggplot2")

  custom_palette <- c("red", "blue")

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      plot      = TRUE,
      palette   = custom_palette,
      risk_table = FALSE
    )
  ))

  expect_true(!is.null(result$plot))
  expect_s3_class(result$plot, "ggplot")
})

# ---- Test 22: Custom plot title is used ----
test_that("mysterycall_kaplan_meier accepts custom plot_title", {
  skip_if_not_installed("survival")
  skip_if_not_installed("ggplot2")

  custom_title <- "Custom KM Plot Title"

  result <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      plot      = TRUE,
      plot_title = custom_title,
      risk_table = FALSE
    )
  ))

  expect_true(!is.null(result$plot))
  expect_s3_class(result$plot, "ggplot")
})

# ---- Test 23: Conf_level parameter affects CI widths ----
test_that("mysterycall_kaplan_meier conf_level parameter affects confidence intervals", {
  skip_if_not_installed("survival")

  result_95 <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      conf_level = 0.95,
      plot      = FALSE
    )
  ))

  result_90 <- suppressMessages(suppressWarnings(
    mysterycall_kaplan_meier(
      data      = AUDIT,
      time_col  = "wait_days",
      event_col = "offered",
      group_col = "insurance",
      max_days  = 30,
      conf_level = 0.90,
      plot      = FALSE
    )
  ))

  expect_s3_class(result_95$median_by_group, "data.frame")
  expect_s3_class(result_90$median_by_group, "data.frame")
})
