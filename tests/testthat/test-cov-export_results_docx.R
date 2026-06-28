library(testthat)
library(mysterycall)

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


test_that("export_results_docx happy path with minimal inputs", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")

  simple_table <- data.frame(
    Term = c("A", "B"),
    Value = c(1.23, 4.56),
    stringsAsFactors = FALSE
  )

  output_file <- tempfile(fileext = ".docx")

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_export_results_docx(simple_table, output_path = output_file)
    )
  )

  expect_true(file.exists(output_file))
  expect_identical(result, output_file)
  unlink(output_file)
})


test_that("export_results_docx returns output_path invisibly", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")

  simple_table <- data.frame(
    Term = c("Control", "Treatment"),
    IRR = c("1.00", "1.45"),
    stringsAsFactors = FALSE
  )

  output_file <- tempfile(fileext = ".docx")

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_export_results_docx(simple_table, output_path = output_file)
    )
  )

  expect_is(result, "character")
  expect_equal(length(result), 1L)
  expect_equal(result, output_file)
  unlink(output_file)
})


test_that("export_results_docx with title, paragraph, and author", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")

  simple_table <- data.frame(
    Predictor = c("X1", "X2"),
    Effect = c(0.12, -0.05),
    stringsAsFactors = FALSE
  )

  output_file <- tempfile(fileext = ".docx")

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_export_results_docx(
        simple_table,
        title = "Table 1: Main Results",
        paragraph = "This table shows the main findings.",
        author = "Jane Doe",
        output_path = output_file
      )
    )
  )

  expect_true(file.exists(output_file))
  expect_identical(result, output_file)
  unlink(output_file)
})


test_that("export_results_docx with bold_significant and significant_rows attribute", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")

  simple_table <- data.frame(
    Term = c("Medicaid", "Uninsured", "Other"),
    IRR = c("1.28", "0.81", "1.05"),
    `p-value` = c("0.014", "0.134", "0.502"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  attr(simple_table, "significant_rows") <- c(1L)

  output_file <- tempfile(fileext = ".docx")

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_export_results_docx(
        simple_table,
        bold_significant = TRUE,
        output_path = output_file
      )
    )
  )

  expect_true(file.exists(output_file))
  expect_identical(result, output_file)
  unlink(output_file)
})


test_that("export_results_docx errors when table is not a data frame", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")

  output_file <- tempfile(fileext = ".docx")

  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_export_results_docx(
          c(1, 2, 3),
          output_path = output_file
        )
      )
    ),
    "`table` must be a data frame"
  )
})


test_that("export_results_docx warns for non-.docx extension", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")

  simple_table <- data.frame(x = 1:2, stringsAsFactors = FALSE)
  output_file <- tempfile(fileext = ".txt")

  expect_warning(
    suppressMessages(
      mysterycall_export_results_docx(
        simple_table,
        output_path = output_file
      )
    ),
    "does not end in '.docx'"
  )

  unlink(output_file, force = TRUE)
})


test_that("export_results_docx skips when officer not installed", {
  skip_if_installed("officer")

  simple_table <- data.frame(x = 1:2, stringsAsFactors = FALSE)
  output_file <- tempfile(fileext = ".docx")

  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_export_results_docx(
          simple_table,
          output_path = output_file
        )
      )
    ),
    "Package 'officer' is required"
  )
})


test_that("export_results_docx skips when flextable not installed", {
  skip_if_installed("flextable")

  simple_table <- data.frame(x = 1:2, stringsAsFactors = FALSE)
  output_file <- tempfile(fileext = ".docx")

  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_export_results_docx(
          simple_table,
          output_path = output_file
        )
      )
    ),
    "Package 'flextable' is required"
  )
})
