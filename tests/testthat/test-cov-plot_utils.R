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

# Test that ggplot2 is available
skip_if_not_installed("ggplot2")

test_that("mysterycall_save_plot returns path invisibly with valid ggplot", {
  skip_if_not_installed("ggplot2")

  tmp_dir <- tempdir()
  tmp_path <- file.path(tmp_dir, "test_plot_1.png")

  p <- suppressMessages(
    ggplot2::ggplot(mtcars, ggplot2::aes(x = wt, y = mpg)) +
      ggplot2::geom_point()
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_save_plot(p, tmp_path)
    )
  )

  expect_identical(result, tmp_path)
  expect_type(result, "character")
  expect_length(result, 1L)
})

test_that("mysterycall_save_plot creates output directory if missing", {
  skip_if_not_installed("ggplot2")

  tmp_base <- file.path(tempdir(), "mysterycall_test_plots")
  # Clean up if it exists
  if (dir.exists(tmp_base)) {
    unlink(tmp_base, recursive = TRUE)
  }

  tmp_path <- file.path(tmp_base, "subdir", "test_plot_2.png")

  p <- suppressMessages(
    ggplot2::ggplot(mtcars, ggplot2::aes(x = wt, y = mpg)) +
      ggplot2::geom_point()
  )

  suppressMessages(
    suppressWarnings(
      mysterycall_save_plot(p, tmp_path)
    )
  )

  expect_true(dir.exists(dirname(tmp_path)))

  # Cleanup
  unlink(tmp_base, recursive = TRUE)
})

test_that("mysterycall_save_plot errors on non-ggplot object", {
  skip_if_not_installed("ggplot2")

  tmp_path <- file.path(tempdir(), "test_bad_plot.png")

  expect_error(
    mysterycall_save_plot(list(data = mtcars), tmp_path),
    "`plot` must be a ggplot object"
  )

  expect_error(
    mysterycall_save_plot(mtcars, tmp_path),
    "`plot` must be a ggplot object"
  )
})

test_that("mysterycall_save_plot errors on invalid path", {
  skip_if_not_installed("ggplot2")

  p <- suppressMessages(
    ggplot2::ggplot(mtcars, ggplot2::aes(x = wt, y = mpg)) +
      ggplot2::geom_point()
  )

  # Empty string
  expect_error(
    mysterycall_save_plot(p, ""),
    "`path` must be a non-empty character scalar"
  )

  # Non-character
  expect_error(
    mysterycall_save_plot(p, 123),
    "`path` must be a non-empty character scalar"
  )

  # Multiple values
  expect_error(
    mysterycall_save_plot(p, c("a.png", "b.png")),
    "`path` must be a non-empty character scalar"
  )
})

test_that("mysterycall_save_plot accepts custom width, height, dpi, bg", {
  skip_if_not_installed("ggplot2")

  tmp_path <- file.path(tempdir(), "test_plot_custom.pdf")

  p <- suppressMessages(
    ggplot2::ggplot(mtcars, ggplot2::aes(x = wt, y = mpg)) +
      ggplot2::geom_point()
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_save_plot(
        p,
        tmp_path,
        width = 10,
        height = 8,
        dpi = 150L,
        bg = "gray90"
      )
    )
  )

  expect_identical(result, tmp_path)
  expect_type(result, "character")
})
