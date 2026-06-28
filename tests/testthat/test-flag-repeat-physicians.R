df <- data.frame(
  id_number             = c("A", "A", "A", "B", "B", "C"),
  physician_information = c("Dr Smith", "Dr Smith", "Dr Smith",
                            "Dr Jones", "Dr Jones", "Dr Lee"),
  stringsAsFactors = FALSE
)

test_that("flags physicians above default threshold of 2", {
  res <- suppressMessages(
    mysterycall_flag_repeat_physicians(df, output_dir = NA)
  )
  expect_equal(nrow(res), 1L)
  expect_equal(res$id_number, "A")
  expect_equal(res$n_calls, 3L)
})

test_that("returns zero-row tibble when none exceed threshold", {
  res <- suppressMessages(
    mysterycall_flag_repeat_physicians(df, threshold = 5L, output_dir = NA)
  )
  expect_equal(nrow(res), 0L)
})

test_that("custom threshold works", {
  res <- suppressMessages(
    mysterycall_flag_repeat_physicians(df, threshold = 1L, output_dir = NA)
  )
  expect_equal(nrow(res), 2L)
  expect_true(all(res$n_calls > 1L))
})

test_that("groups by id_col only when name_col = NULL", {
  res <- suppressMessages(
    mysterycall_flag_repeat_physicians(df, name_col = NULL, output_dir = NA)
  )
  expect_false("physician_information" %in% names(res))
  expect_true("n_calls" %in% names(res))
})

test_that("result is sorted descending by n_calls", {
  res <- suppressMessages(
    mysterycall_flag_repeat_physicians(df, threshold = 1L, output_dir = NA)
  )
  expect_true(all(diff(res$n_calls) <= 0))
})

test_that("writes CSV when output_dir is provided", {
  td <- tempfile()
  dir.create(td)
  suppressMessages(
    mysterycall_flag_repeat_physicians(df, output_dir = td,
                                       filename = "test_out.csv")
  )
  expect_true(file.exists(file.path(td, "test_out.csv")))
})

test_that("errors on missing id column", {
  expect_error(
    mysterycall_flag_repeat_physicians(df, id_col = "npi", output_dir = NA),
    "missing"
  )
})

test_that("errors on missing name column", {
  expect_error(
    mysterycall_flag_repeat_physicians(df, name_col = "doctor", output_dir = NA),
    "missing"
  )
})
