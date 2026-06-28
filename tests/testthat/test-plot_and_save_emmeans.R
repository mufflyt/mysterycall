library(testthat)
testthat::skip_if_not_installed("ggplot2")
testthat::skip_if_not_installed("emmeans")
testthat::skip_if_not_installed("dplyr")
suppressWarnings(library(ggplot2))
suppressWarnings(library(emmeans))
suppressWarnings(library(dplyr))

message("Testing mysterycall_plot_emmeans function")

# Setup a basic model for testing
data(mtcars)
test_model <- lm(mpg ~ cyl + gear, data = mtcars)

# Test for input validation
test_that("input validation works correctly", {
  expect_error(mysterycall_plot_emmeans("not a model", "cyl", "cyl", output_dir = tempdir()),
               "model_object must be a valid model class object")
  expect_error(mysterycall_plot_emmeans(test_model, list("cyl"), "cyl", output_dir = tempdir()),
               "specs must be a single character string")
  expect_error(mysterycall_plot_emmeans(test_model, "cyl", 123, output_dir = tempdir()),
               "variable_of_interest must be a single character string")
  expect_error(mysterycall_plot_emmeans(test_model, "cyl", "cyl", output_dir = "nonexistent/directory"),
               "Output directory does not exist")
})

# Test for correct output structure
test_that("function returns correct output structure", {
  result <- mysterycall_plot_emmeans(test_model, "cyl", "cyl", output_dir = tempdir())
  expect_true("data.frame" %in% class(result$data))
  expect_true("gg" %in% class(result$plot))
})

# Test for plot file creation
test_that("function creates a plot file", {
  output_dir <- tempfile("emmeans_plot_test_")
  dir.create(output_dir)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)
  mysterycall_plot_emmeans(test_model, "cyl", "cyl", output_dir = output_dir)
  plot_files <- list.files(output_dir, pattern = "png$", full.names = TRUE)
  expect_true(length(plot_files) >= 1L)
  expect_true(file.exists(plot_files[1]))
})

# Test error handling from emmeans
test_that("function handles emmeans errors correctly with nonexistent spec", {
  expect_error(
    mysterycall_plot_emmeans(test_model, "nonexistent_variable", "nonexistent_variable", output_dir = tempdir()),
    "Error in calculating emmeans"
  )
})
