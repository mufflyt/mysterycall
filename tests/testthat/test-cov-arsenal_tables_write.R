library(testthat)
library(mysterycall)


# ---------------------------------------------------------------------------
# Tests for mysterycall_write_arsenal_table
# ---------------------------------------------------------------------------

test_that("mysterycall_write_arsenal_table errors when object is not a data frame", {
  expect_error(
    mysterycall_write_arsenal_table(object = "not_a_df", filename = "test"),
    "must be a data frame"
  )
  expect_error(
    mysterycall_write_arsenal_table(object = list(a = 1, b = 2), filename = "test"),
    "must be a data frame"
  )
  expect_error(
    mysterycall_write_arsenal_table(object = 42L, filename = "test"),
    "must be a data frame"
  )
})


test_that("mysterycall_write_arsenal_table errors when filename is not a character string", {
  df <- data.frame(x = 1:3, y = c("a", "b", "c"), stringsAsFactors = FALSE)
  expect_error(
    mysterycall_write_arsenal_table(df, filename = 123),
    "must be a character string"
  )
  expect_error(
    mysterycall_write_arsenal_table(df, filename = TRUE),
    "must be a character string"
  )
})


test_that("mysterycall_write_arsenal_table writes a .docx file for a valid arsenal tableby summary", {
  skip_if_not_installed("arsenal")

  df <- data.frame(
    group    = c("A", "A", "B", "B"),
    age      = c(25, 30, 35, 40),
    stringsAsFactors = FALSE
  )
  tbl         <- arsenal::tableby(group ~ age, data = df)
  tbl_summary <- as.data.frame(summary(tbl, text = TRUE))

  tmp_dir <- tempfile("arsenal_write_test_")
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    mysterycall_write_arsenal_table(tbl_summary, "happy_table", output_dir = tmp_dir)
  )

  expect_true(file.exists(file.path(tmp_dir, "happy_table.docx")))
})


test_that("mysterycall_write_arsenal_table creates output_dir when it does not exist", {
  skip_if_not_installed("arsenal")

  df <- data.frame(
    grp  = c("X", "X", "Y", "Y"),
    val  = c(1.1, 2.2, 3.3, 4.4),
    stringsAsFactors = FALSE
  )
  tbl         <- arsenal::tableby(grp ~ val, data = df)
  tbl_summary <- as.data.frame(summary(tbl, text = TRUE))

  new_dir <- file.path(tempfile("arsenal_newdir_"), "subdir")
  on.exit(unlink(dirname(new_dir), recursive = TRUE), add = TRUE)

  # Directory does not yet exist — function must create it
  expect_false(dir.exists(new_dir))

  suppressMessages(
    mysterycall_write_arsenal_table(tbl_summary, "newdir_table", output_dir = new_dir)
  )

  expect_true(dir.exists(new_dir))
  expect_true(file.exists(file.path(new_dir, "newdir_table.docx")))
})


test_that("mysterycall_write_arsenal_table wraps arsenal errors with a descriptive message", {
  skip_if_not_installed("arsenal")

  # A zero-row data frame is a valid data.frame but arsenal::write2word may
  # fail on degenerate input; the function should re-throw with its own message.
  empty_df <- data.frame(x = integer(0), label = character(0),
                         stringsAsFactors = FALSE)

  tmp_dir <- tempfile("arsenal_empty_")
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  result <- tryCatch(
    suppressMessages(
      mysterycall_write_arsenal_table(empty_df, "empty_table", output_dir = tmp_dir)
    ),
    error = function(e) e
  )

  # Either the write succeeds (NULL return) or the re-thrown error message
  # contains "Error occurred while writing" (not the raw arsenal message).
  if (inherits(result, "error")) {
    expect_match(conditionMessage(result), "Error occurred while writing")
  } else {
    expect_null(result)
  }
})
