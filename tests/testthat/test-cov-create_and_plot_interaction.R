library(testthat)
library(mysterycall)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a minimal in-memory data frame suitable for mysterycall_plot_interaction
make_interaction_df <- function(n_per_cell = 10L) {
  set.seed(121)
  insurance <- rep(c("Medicaid", "BCBS"), each = n_per_cell * 2L)
  gender    <- rep(rep(c("Female", "Male"), each = n_per_cell), 2L)
  city      <- sample(paste0("City", 1:5), length(insurance), replace = TRUE)
  days      <- rpois(length(insurance), lambda = ifelse(insurance == "Medicaid", 8, 5))
  data.frame(
    business_days_until_appointment = days,
    insurance                       = insurance,
    gender                          = gender,
    city                            = city,
    stringsAsFactors                = FALSE
  )
}

# Write the fixture to a temp RDS and return its path
fixture_rds <- function(...) {
  df  <- make_interaction_df(...)
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df, tmp)
  tmp
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test_that("mysterycall_plot_interaction returns a named list on valid input", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("ggplot2")

  rds_path    <- fixture_rds()
  on.exit(unlink(rds_path), add = TRUE)
  out_dir     <- tempfile()
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_interaction(
      data_path            = rds_path,
      response_variable    = "business_days_until_appointment",
      variable_of_interest = "insurance",
      interaction_variable = "gender",
      random_intercept     = "city",
      output_path          = out_dir,
      resolution           = 72L
    )
  ))

  expect_type(result, "list")
  expect_named(result, c("model", "effects_plot_data"))
})

test_that("mysterycall_plot_interaction model slot is a glmerMod object", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("ggplot2")

  rds_path <- fixture_rds()
  on.exit(unlink(rds_path), add = TRUE)
  out_dir  <- tempfile()
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_interaction(
      data_path            = rds_path,
      response_variable    = "business_days_until_appointment",
      variable_of_interest = "insurance",
      interaction_variable = "gender",
      random_intercept     = "city",
      output_path          = out_dir,
      resolution           = 72L
    )
  ))

  expect_s4_class(result$model, "glmerMod")
})

test_that("mysterycall_plot_interaction effects_plot_data has expected columns and rows", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("ggplot2")

  rds_path <- fixture_rds()
  on.exit(unlink(rds_path), add = TRUE)
  out_dir  <- tempfile()
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_interaction(
      data_path            = rds_path,
      response_variable    = "business_days_until_appointment",
      variable_of_interest = "insurance",
      interaction_variable = "gender",
      random_intercept     = "city",
      output_path          = out_dir,
      resolution           = 72L
    )
  ))

  epd <- result$effects_plot_data
  expect_true(is.data.frame(epd))
  # 2 levels of gender x 2 levels of insurance = 4 rows
  expect_equal(nrow(epd), 4L)
  expect_true("mean_pred" %in% names(epd))
  expect_true(all(is.finite(epd$mean_pred)))
})

test_that("mysterycall_plot_interaction errors when required columns are missing", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("ggplot2")

  df  <- make_interaction_df()
  df  <- df[, setdiff(names(df), "gender")]   # remove the interaction column
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df, tmp)
  on.exit(unlink(tmp), add = TRUE)
  out_dir <- tempfile()
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_plot_interaction(
        data_path            = tmp,
        response_variable    = "business_days_until_appointment",
        variable_of_interest = "insurance",
        interaction_variable = "gender",      # column does not exist now
        random_intercept     = "city",
        output_path          = out_dir
      )
    )),
    regexp = "gender"
  )
})

test_that("mysterycall_plot_interaction errors when data_path does not exist", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("ggplot2")

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_plot_interaction(
        data_path            = "/nonexistent/path/data.rds",
        response_variable    = "business_days_until_appointment",
        variable_of_interest = "insurance",
        interaction_variable = "gender",
        random_intercept     = "city",
        output_path          = tempdir()
      )
    ))
  )
})
