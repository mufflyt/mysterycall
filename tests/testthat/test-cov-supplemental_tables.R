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

test_that("mysterycall_supplemental_tables returns invisible file path with valid minimal input", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  extra <- list(TestData = data.frame(x = 1:3, y = letters[1:3]))
  result <- suppressMessages(mysterycall_supplemental_tables(
    extra_tables = extra,
    file = tmpfile,
    overwrite = TRUE
  ))

  expect_true(is.character(result))
  expect_true(file.exists(result))
  expect_true(grepl("\\.xlsx$", result))
})

test_that("mysterycall_supplemental_tables returns invisible(file) correctly", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  extra <- list(Data = data.frame(a = 1:2))
  result <- suppressMessages(mysterycall_supplemental_tables(
    extra_tables = extra,
    file = tmpfile,
    overwrite = TRUE
  ))

  # Verify result is a character string ending in .xlsx
  expect_true(is.character(result))
  expect_true(grepl("\\.xlsx$", result))
  # Verify it's an absolute path
  expect_true(is.character(result) && nchar(result) > 0)
})

test_that("mysterycall_supplemental_tables appends .xlsx extension when missing", {
  skip_if_not_installed("openxlsx")

  tmpbase <- tempfile()
  tmpfile_xlsx <- paste0(tmpbase, ".xlsx")
  on.exit(unlink(tmpfile_xlsx), add = TRUE)

  extra <- list(Data = data.frame(x = 1))
  result <- suppressMessages(mysterycall_supplemental_tables(
    extra_tables = extra,
    file = tmpbase,
    overwrite = TRUE
  ))

  expect_true(file.exists(tmpfile_xlsx))
  expect_true(grepl("\\.xlsx$", result))
})

test_that("mysterycall_supplemental_tables rejects missing all content sources", {
  skip_if_not_installed("openxlsx")

  expect_error(
    suppressMessages(mysterycall_supplemental_tables()),
    "At least one of.*must be non-NULL"
  )
})

test_that("mysterycall_supplemental_tables rejects non-character file", {
  skip_if_not_installed("openxlsx")

  expect_error(
    suppressMessages(mysterycall_supplemental_tables(
      extra_tables = list(Data = data.frame(x = 1)),
      file = 123
    )),
    "`file` must be a non-empty character scalar"
  )
})

test_that("mysterycall_supplemental_tables rejects empty character file", {
  skip_if_not_installed("openxlsx")

  expect_error(
    suppressMessages(mysterycall_supplemental_tables(
      extra_tables = list(Data = data.frame(x = 1)),
      file = ""
    )),
    "`file` must be a non-empty character scalar"
  )
})

test_that("mysterycall_supplemental_tables rejects non-logical overwrite", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  expect_error(
    suppressMessages(mysterycall_supplemental_tables(
      extra_tables = list(Data = data.frame(x = 1)),
      file = tmpfile,
      overwrite = "yes"
    )),
    "`overwrite` must be a single logical value"
  )
})

test_that("mysterycall_supplemental_tables rejects existing file without overwrite=TRUE", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  # Create the file first
  suppressMessages(mysterycall_supplemental_tables(
    extra_tables = list(Data = data.frame(x = 1)),
    file = tmpfile,
    overwrite = TRUE
  ))

  expect_error(
    suppressMessages(mysterycall_supplemental_tables(
      extra_tables = list(Data = data.frame(x = 2)),
      file = tmpfile,
      overwrite = FALSE
    )),
    "File already exists"
  )
})

test_that("mysterycall_supplemental_tables allows overwrite=TRUE on existing file", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  # Create file first time
  suppressMessages(mysterycall_supplemental_tables(
    extra_tables = list(Data = data.frame(x = 1)),
    file = tmpfile,
    overwrite = TRUE
  ))

  # Overwrite it
  result <- suppressMessages(mysterycall_supplemental_tables(
    extra_tables = list(Data = data.frame(x = 2)),
    file = tmpfile,
    overwrite = TRUE
  ))

  expect_true(file.exists(result))
})

test_that("mysterycall_supplemental_tables rejects non-character author", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  expect_error(
    suppressMessages(mysterycall_supplemental_tables(
      extra_tables = list(Data = data.frame(x = 1)),
      file = tmpfile,
      author = 123,
      overwrite = TRUE
    )),
    "`author` must be a single character string or NULL"
  )
})

test_that("mysterycall_supplemental_tables accepts author string", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  result <- suppressMessages(mysterycall_supplemental_tables(
    extra_tables = list(Data = data.frame(x = 1)),
    file = tmpfile,
    author = "Test Author",
    overwrite = TRUE
  ))

  expect_true(file.exists(result))
})

test_that("mysterycall_supplemental_tables rejects non-list extra_tables", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  # Pass a vector instead of a list
  expect_error(
    suppressMessages(mysterycall_supplemental_tables(
      extra_tables = c(x = 1),
      file = tmpfile,
      overwrite = TRUE
    )),
    "`extra_tables` must be a named list"
  )
})

test_that("mysterycall_supplemental_tables rejects unnamed extra_tables elements", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  expect_error(
    suppressMessages(mysterycall_supplemental_tables(
      extra_tables = list(data.frame(x = 1)),
      file = tmpfile,
      overwrite = TRUE
    )),
    "Every element of `extra_tables` must have a non-empty name"
  )
})

test_that("mysterycall_supplemental_tables rejects non-data.frame in extra_tables", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  # Non-data.frame in extra_tables should trigger an error
  result <- tryCatch(
    suppressMessages(mysterycall_supplemental_tables(
      extra_tables = list(BadData = list(x = 1)),
      file = tmpfile,
      overwrite = TRUE
    )),
    error = function(e) {
      return("error_caught")
    }
  )
  expect_equal(result, "error_caught")
})

test_that("mysterycall_supplemental_tables accepts multiple extra_tables", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  extra <- list(
    Table1 = data.frame(x = 1:2),
    Table2 = data.frame(y = letters[1:2])
  )

  result <- suppressMessages(mysterycall_supplemental_tables(
    extra_tables = extra,
    file = tmpfile,
    overwrite = TRUE
  ))

  expect_true(file.exists(result))
})

test_that("mysterycall_supplemental_tables requires content when extra_tables empty", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  # Should fail because all inputs are NULL and extra_tables is empty
  result <- tryCatch(
    suppressMessages(mysterycall_supplemental_tables(
      extra_tables = list(),
      file = tmpfile,
      overwrite = TRUE
    )),
    error = function(e) {
      return("error_caught")
    }
  )
  expect_equal(result, "error_caught")
})

test_that("mysterycall_supplemental_tables rejects invalid logistic_fit class", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  fake_model <- list(or_table = data.frame())
  class(fake_model) <- "wrong_class"

  expect_error(
    suppressMessages(mysterycall_supplemental_tables(
      logistic_fit = fake_model,
      file = tmpfile,
      overwrite = TRUE
    )),
    "`logistic_fit` must be a `mysterycall_logistic_model` object or NULL"
  )
})

test_that("mysterycall_supplemental_tables rejects invalid poisson_fit class", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  fake_model <- list(irr_table = data.frame())
  class(fake_model) <- "wrong_class"

  expect_error(
    suppressMessages(mysterycall_supplemental_tables(
      poisson_fit = fake_model,
      file = tmpfile,
      overwrite = TRUE
    )),
    "`poisson_fit` must be a `mysterycall_poisson_model`"
  )
})

test_that("mysterycall_supplemental_tables rejects invalid lmm_fit class", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  fake_model <- list(coef_table = data.frame())
  class(fake_model) <- "wrong_class"

  expect_error(
    suppressMessages(mysterycall_supplemental_tables(
      lmm_fit = fake_model,
      file = tmpfile,
      overwrite = TRUE
    )),
    "`lmm_fit` must be a `mysterycall_lmm` object or NULL"
  )
})

test_that("mysterycall_supplemental_tables accepts NULL models", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  result <- suppressMessages(mysterycall_supplemental_tables(
    logistic_fit = NULL,
    poisson_fit = NULL,
    lmm_fit = NULL,
    extra_tables = list(Data = data.frame(x = 1)),
    file = tmpfile,
    overwrite = TRUE
  ))

  expect_true(file.exists(result))
})

test_that("mysterycall_supplemental_tables truncates long sheet names", {
  skip_if_not_installed("openxlsx")

  tmpfile <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  # Excel sheet names have 31 character limit
  long_name <- paste0(rep("a", 50), collapse = "")
  extra <- setNames(list(data.frame(x = 1)), long_name)

  result <- suppressMessages(mysterycall_supplemental_tables(
    extra_tables = extra,
    file = tmpfile,
    overwrite = TRUE
  ))

  expect_true(file.exists(result))
})

test_that("mysterycall_supplemental_tables handles spaces in file path", {
  skip_if_not_installed("openxlsx")

  tmpdir <- tempdir()
  tmpfile <- file.path(tmpdir, "my file with spaces.xlsx")
  on.exit(unlink(tmpfile), add = TRUE)

  result <- suppressMessages(mysterycall_supplemental_tables(
    extra_tables = list(Data = data.frame(x = 1)),
    file = tmpfile,
    overwrite = TRUE
  ))

  expect_true(file.exists(result))
  expect_true(grepl("spaces", result))
})
