test_that("returns invisible character scalar containing the file path", {
  skip_if_not_installed("openxlsx")
  out_dir <- withr::local_tempdir()
  out_file <- file.path(out_dir, "supp.xlsx")

  tbl <- data.frame(x = 1:3, label = letters[1:3], stringsAsFactors = FALSE)
  result <- mysterycall_supplemental_tables(
    extra_tables = list(Demo = tbl),
    file         = out_file,
    overwrite    = FALSE
  )

  expect_type(result, "character")
  expect_length(result, 1L)
  expect_true(nchar(result) > 0L)
})

test_that("return value is invisible", {
  skip_if_not_installed("openxlsx")
  out_dir  <- withr::local_tempdir()
  out_file <- file.path(out_dir, "supp_inv.xlsx")
  tbl      <- data.frame(a = 1, stringsAsFactors = FALSE)

  vis <- withVisible(
    mysterycall_supplemental_tables(
      extra_tables = list(Sheet1 = tbl),
      file         = out_file
    )
  )

  expect_false(vis$visible)
})

test_that("creates the file at the specified path", {
  skip_if_not_installed("openxlsx")
  out_dir  <- withr::local_tempdir()
  out_file <- file.path(out_dir, "created.xlsx")

  tbl <- data.frame(v = c(10, 20), stringsAsFactors = FALSE)
  mysterycall_supplemental_tables(
    extra_tables = list(Numbers = tbl),
    file         = out_file
  )

  expect_true(file.exists(out_file))
})

test_that("errors when all inputs are NULL and extra_tables is empty", {
  expect_error(
    mysterycall_supplemental_tables(
      logistic_fit = NULL,
      poisson_fit  = NULL,
      lmm_fit      = NULL,
      extra_tables = list(),
      file         = tempfile(fileext = ".xlsx")
    ),
    regexp = "At least one"
  )
})

test_that("errors when file already exists and overwrite = FALSE", {
  skip_if_not_installed("openxlsx")
  out_dir  <- withr::local_tempdir()
  out_file <- file.path(out_dir, "exist.xlsx")

  tbl <- data.frame(q = 1L, stringsAsFactors = FALSE)
  mysterycall_supplemental_tables(
    extra_tables = list(T1 = tbl),
    file         = out_file,
    overwrite    = FALSE
  )

  expect_error(
    mysterycall_supplemental_tables(
      extra_tables = list(T1 = tbl),
      file         = out_file,
      overwrite    = FALSE
    ),
    regexp = "already exists"
  )
})

test_that("overwrite = TRUE replaces an existing file without error", {
  skip_if_not_installed("openxlsx")
  out_dir  <- withr::local_tempdir()
  out_file <- file.path(out_dir, "overwrite_me.xlsx")

  tbl <- data.frame(n = 1:5, stringsAsFactors = FALSE)
  mysterycall_supplemental_tables(
    extra_tables = list(Wave1 = tbl),
    file         = out_file,
    overwrite    = FALSE
  )

  expect_no_error(
    mysterycall_supplemental_tables(
      extra_tables = list(Wave2 = tbl),
      file         = out_file,
      overwrite    = TRUE
    )
  )
  expect_true(file.exists(out_file))
})

test_that("works with only logistic_fit supplied", {
  skip_if_not_installed("openxlsx")
  out_dir  <- withr::local_tempdir()
  out_file <- file.path(out_dir, "logistic_only.xlsx")

  or_tbl <- data.frame(
    term         = c("(Intercept)", "insuranceMedicaid"),
    estimate     = c(-0.45, 0.82),
    se           = c(0.30, 0.25),
    z_value      = c(-1.50, 3.28),
    or           = c(0.64, 2.27),
    ci_lower     = c(0.35, 1.38),
    ci_upper     = c(1.15, 3.74),
    p_value_fmt  = c("0.133", "0.001"),
    stringsAsFactors = FALSE
  )

  fake_logistic <- structure(
    list(
      or_table  = or_tbl,
      aic       = 98.4,
      bic       = 104.1,
      n         = 76L,
      n_dropped = 4L
    ),
    class = "mysterycall_logistic_model"
  )

  result <- mysterycall_supplemental_tables(
    logistic_fit = fake_logistic,
    file         = out_file
  )

  expect_true(file.exists(result))
})

test_that("works with only extra_tables supplied", {
  skip_if_not_installed("openxlsx")
  out_dir  <- withr::local_tempdir()
  out_file <- file.path(out_dir, "extra_only.xlsx")

  demo <- data.frame(
    Group   = c("Medicaid", "BCBS"),
    n       = c(40L, 40L),
    offered = c(28L, 35L),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_supplemental_tables(
    extra_tables = list(Demographics = demo),
    file         = out_file
  )

  expect_type(result, "character")
  expect_true(file.exists(result))
})

test_that("works with extra_tables containing multiple data.frames", {
  skip_if_not_installed("openxlsx")
  out_dir  <- withr::local_tempdir()
  out_file <- file.path(out_dir, "multi_extra.xlsx")

  df1 <- data.frame(x = 1:3, stringsAsFactors = FALSE)
  df2 <- data.frame(y = letters[1:4], stringsAsFactors = FALSE)
  df3 <- data.frame(z = c(TRUE, FALSE), stringsAsFactors = FALSE)

  result <- mysterycall_supplemental_tables(
    extra_tables = list(TableA = df1, TableB = df2, TableC = df3),
    file         = out_file
  )

  expect_true(file.exists(result))
  wb <- openxlsx::loadWorkbook(result)
  sheet_names <- openxlsx::sheets(wb)
  expect_true(all(c("TableA", "TableB", "TableC") %in% sheet_names))
})

test_that(".xlsx extension is appended automatically when absent from file path", {
  skip_if_not_installed("openxlsx")
  out_dir      <- withr::local_tempdir()
  no_ext_path  <- file.path(out_dir, "output_no_ext")

  tbl <- data.frame(col = "val", stringsAsFactors = FALSE)
  result <- mysterycall_supplemental_tables(
    extra_tables = list(S1 = tbl),
    file         = no_ext_path
  )

  expect_true(grepl("\\.xlsx$", result, ignore.case = TRUE))
  expect_true(file.exists(result))
})

test_that("errors when logistic_fit has wrong class", {
  expect_error(
    mysterycall_supplemental_tables(
      logistic_fit = list(or_table = data.frame()),
      file         = tempfile(fileext = ".xlsx")
    ),
    regexp = "mysterycall_logistic_model"
  )
})

test_that("errors when extra_tables contains an unnamed element", {
  expect_error(
    mysterycall_supplemental_tables(
      extra_tables = list(data.frame(a = 1)),
      file         = tempfile(fileext = ".xlsx")
    ),
    regexp = "non-empty name"
  )
})

test_that("works with lmm_fit that has a gmr_table", {
  skip_if_not_installed("openxlsx")
  out_dir  <- withr::local_tempdir()
  out_file <- file.path(out_dir, "lmm_gmr.xlsx")

  coef_tbl <- data.frame(
    term        = c("(Intercept)", "insuranceMedicaid"),
    estimate    = c(2.10, 0.55),
    se          = c(0.20, 0.18),
    t_value     = c(10.5, 3.06),
    df          = c(74.2, 71.8),
    ci_lower    = c(1.70, 0.19),
    ci_upper    = c(2.50, 0.91),
    p_value_fmt = c("<0.001", "0.003"),
    stringsAsFactors = FALSE
  )

  gmr_tbl <- data.frame(
    term        = "insuranceMedicaid",
    GMR         = 1.73,
    GMR_lo      = 1.21,
    GMR_hi      = 2.48,
    p_value_fmt = "0.003",
    stringsAsFactors = FALSE
  )

  fake_lmm <- structure(
    list(
      coef_table = coef_tbl,
      gmr_table  = gmr_tbl,
      aic        = 210.3,
      bic        = 218.7,
      n          = 80L,
      n_dropped  = 0L
    ),
    class = "mysterycall_lmm"
  )

  result <- mysterycall_supplemental_tables(
    lmm_fit = fake_lmm,
    file    = out_file
  )

  expect_true(file.exists(result))
  wb <- openxlsx::loadWorkbook(result)
  expect_true("LMM Coefs" %in% openxlsx::sheets(wb))
  expect_true("LMM GMR"   %in% openxlsx::sheets(wb))
})
