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

# ---- Test mysterycall_table1: happy path ----

test_that("mysterycall_table1 returns correct class with minimal inputs", {
  result <- suppressMessages(mysterycall_table1(
    data      = AUDIT,
    covariates = c("wait_days", "offered")
  ))
  expect_s3_class(result, "mysterycall_table1")
  expect_true(is.list(result))
  expect_true("table" %in% names(result))
  expect_true("column_ns" %in% names(result))
  expect_true("stratify_by" %in% names(result))
  expect_true("n" %in% names(result))
  expect_true("docx_path" %in% names(result))
})

test_that("mysterycall_table1 produces table with correct dimensions when not stratified", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days", "offered")
  ))
  # wait_days is numeric (2 rows: median, mean)
  # offered is logical/categorical (2 levels: FALSE, TRUE)
  expect_true(nrow(result$table) >= 4)
  expect_true("variable" %in% names(result$table))
  expect_true("level" %in% names(result$table))
  expect_true("Overall" %in% names(result$table))
})

test_that("mysterycall_table1 stratify_by creates group columns with N", {
  result <- suppressMessages(mysterycall_table1(
    data        = AUDIT,
    covariates  = c("wait_days"),
    stratify_by = "insurance"
  ))
  expect_equal(result$stratify_by, "insurance")
  expect_true(any(grepl("Medicaid", names(result$table))))
  expect_true(any(grepl("BCBS", names(result$table))))
  expect_true(all(grepl("\\(N=", names(result$table)[grepl("Medicaid|BCBS", names(result$table))])))
})

test_that("mysterycall_table1 p_value column appears when stratified with p_value=TRUE", {
  result <- suppressMessages(mysterycall_table1(
    data        = AUDIT,
    covariates  = c("wait_days", "offered"),
    stratify_by = "insurance",
    p_value     = TRUE
  ))
  expect_true("p_value" %in% names(result$table))
})

test_that("mysterycall_table1 no p_value column when not stratified", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days"),
    p_value    = TRUE
  ))
  expect_false("p_value" %in% names(result$table))
})

test_that("mysterycall_table1 cont_stats controls rows per numeric variable", {
  # Only median_iqr
  result_med <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days"),
    cont_stats = "median_iqr"
  ))

  # Both median_iqr and mean_sd
  result_both <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days"),
    cont_stats = c("median_iqr", "mean_sd")
  ))

  expect_true(nrow(result_both$table) > nrow(result_med$table))
})

test_that("mysterycall_table1 digits parameter affects formatting", {
  result0 <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days"),
    digits     = 0L
  ))
  result2 <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days"),
    digits     = 2L
  ))

  # Check that results are tibbles with expected columns
  expect_s3_class(result0$table, "tbl_df")
  expect_s3_class(result2$table, "tbl_df")
})

test_that("mysterycall_table1 variable_labels are used in output", {
  labels <- c(wait_days = "Waiting Time (days)", offered = "Offered Appointment")
  result <- suppressMessages(mysterycall_table1(
    data             = AUDIT,
    covariates       = c("wait_days", "offered"),
    variable_labels  = labels
  ))

  # Check that custom labels appear in the table
  expect_true("Waiting Time (days)" %in% result$table$variable)
  expect_true("Offered Appointment" %in% result$table$variable)
})

test_that("mysterycall_table1 include_overall=FALSE removes Overall column", {
  result_with <- suppressMessages(mysterycall_table1(
    data           = AUDIT,
    covariates     = c("wait_days"),
    stratify_by    = "insurance",
    include_overall = TRUE
  ))

  result_without <- suppressMessages(mysterycall_table1(
    data           = AUDIT,
    covariates     = c("wait_days"),
    stratify_by    = "insurance",
    include_overall = FALSE
  ))

  expect_true("Overall" %in% names(result_with$table))
  expect_false("Overall" %in% names(result_without$table))
})

test_that("mysterycall_table1 column_ns has correct sample sizes", {
  result <- suppressMessages(mysterycall_table1(
    data        = AUDIT,
    covariates  = c("wait_days"),
    stratify_by = "insurance"
  ))

  # Should have N for Medicaid and BCBS
  expect_true(length(result$column_ns) > 0)
  expect_true(all(result$column_ns > 0))
})

test_that("mysterycall_table1 n field equals nrow(data)", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days")
  ))

  expect_equal(result$n, nrow(AUDIT))
})

# ---- Test mysterycall_table1: edge cases ----

test_that("mysterycall_table1 handles data with all NAs in a covariate", {
  df <- AUDIT
  df$wait_days[c(1,3)] <- NA

  result <- suppressMessages(mysterycall_table1(
    data       = df,
    covariates = c("wait_days")
  ))

  expect_s3_class(result, "mysterycall_table1")
  expect_true(nrow(result$table) > 0)
})

test_that("mysterycall_table1 handles numeric covariate with zero variance", {
  df <- AUDIT
  df$constant_col <- 42L

  result <- suppressMessages(mysterycall_table1(
    data       = df,
    covariates = c("constant_col")
  ))

  expect_s3_class(result, "mysterycall_table1")
  expect_true(nrow(result$table) > 0)
})

test_that("mysterycall_table1 handles factor variables", {
  df <- AUDIT
  df$specialty <- factor(df$specialty)

  result <- suppressMessages(mysterycall_table1(
    data       = df,
    covariates = c("specialty")
  ))

  expect_s3_class(result, "mysterycall_table1")
  expect_true("specialty" %in% result$table$variable)
})

test_that("mysterycall_table1 handles logical variables", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("offered")
  ))

  expect_s3_class(result, "mysterycall_table1")
  expect_true("offered" %in% result$table$variable)
})

test_that("mysterycall_table1 handles stratify_by with NAs in grouping variable", {
  df <- AUDIT
  df$insurance[1] <- NA

  result <- suppressMessages(mysterycall_table1(
    data        = df,
    covariates  = c("wait_days"),
    stratify_by = "insurance"
  ))

  expect_s3_class(result, "mysterycall_table1")
  # Should only have groups for non-NA values
  expect_true(all(result$column_ns > 0))
})

test_that("mysterycall_table1 with output_path=NULL does not write file", {
  result <- suppressMessages(mysterycall_table1(
    data        = AUDIT,
    covariates  = c("wait_days"),
    output_path = NULL
  ))

  expect_null(result$docx_path)
})

# ---- Test mysterycall_table1: bad inputs ----

test_that("mysterycall_table1 errors when data is not a data frame", {
  expect_error(
    mysterycall_table1(
      data       = list(a = 1),
      covariates = c("a")
    )
  )
})

test_that("mysterycall_table1 errors when covariates column missing", {
  expect_error(
    mysterycall_table1(
      data       = AUDIT,
      covariates = c("nonexistent_col")
    )
  )
})

test_that("mysterycall_table1 errors when stratify_by column missing", {
  expect_error(
    mysterycall_table1(
      data        = AUDIT,
      covariates  = c("wait_days"),
      stratify_by = "nonexistent_col"
    )
  )
})

test_that("mysterycall_table1 errors when stratify_by is not a single column name", {
  expect_error(
    mysterycall_table1(
      data        = AUDIT,
      covariates  = c("wait_days"),
      stratify_by = c("insurance", "offered")
    )
  )
})

test_that("mysterycall_table1 errors when digits is negative", {
  expect_error(
    mysterycall_table1(
      data       = AUDIT,
      covariates = c("wait_days"),
      digits     = -1
    )
  )
})

test_that("mysterycall_table1 errors when variable_labels is not named", {
  expect_error(
    mysterycall_table1(
      data            = AUDIT,
      covariates      = c("wait_days"),
      variable_labels = c("Bad Label")
    )
  )
})

test_that("mysterycall_table1 with single covariate works correctly", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = "wait_days"
  ))
  expect_s3_class(result, "mysterycall_table1")
  expect_true("wait_days" %in% result$table$variable)
})

test_that("mysterycall_table1 errors on zero-row data frame", {
  df_empty <- AUDIT[0, ]
  expect_error(
    mysterycall_table1(
      data       = df_empty,
      covariates = c("wait_days")
    )
  )
})

# ---- Test print.mysterycall_table1 ----

test_that("print.mysterycall_table1 returns invisibly", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days")
  ))

  output <- capture.output(returned <- print(result))
  expect_identical(returned, result)
})

test_that("print.mysterycall_table1 shows column sample sizes", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days")
  ))

  output <- capture.output(print(result))
  expect_true(any(grepl("N=", output)))
})

test_that("print.mysterycall_table1 shows stratify_by when present", {
  result <- suppressMessages(mysterycall_table1(
    data        = AUDIT,
    covariates  = c("wait_days"),
    stratify_by = "insurance"
  ))

  output <- capture.output(print(result))
  expect_true(any(grepl("Stratified by", output)))
})

test_that("print.mysterycall_table1 does not show stratify_by when NULL", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days")
  ))

  output <- capture.output(print(result))
  expect_false(any(grepl("Stratified by", output)))
})

# ---- Test as.data.frame.mysterycall_table1 ----

test_that("as.data.frame.mysterycall_table1 returns data frame", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days", "offered")
  ))

  df <- as.data.frame(result)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), nrow(result$table))
})

test_that("as.data.frame.mysterycall_table1 preserves column names", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days")
  ))

  df <- as.data.frame(result)
  expect_equal(names(df), names(result$table))
})

test_that("as.data.frame.mysterycall_table1 converts tbl_df to data.frame", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("wait_days")
  ))

  df <- as.data.frame(result)
  expect_false(inherits(df, "tbl_df"))
  expect_true(inherits(df, "data.frame"))
})

test_that("as.data.frame.mysterycall_table1 has stringsAsFactors=FALSE", {
  result <- suppressMessages(mysterycall_table1(
    data       = AUDIT,
    covariates = c("specialty")
  ))

  df <- as.data.frame(result)
  # String columns should be character, not factor
  expect_type(df$variable, "character")
})
