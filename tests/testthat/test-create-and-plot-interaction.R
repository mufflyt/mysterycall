skip_if_not_installed("lme4")
skip_if_not_installed("ggplot2")
skip_if_not_installed("dplyr")

make_interaction_df <- function(n = 200) {
  set.seed(1978)
  df <- data.frame(
    wait        = rpois(n, lambda = 14),
    insurance   = sample(c("BCBS", "Medicaid"), n, replace = TRUE),
    gender      = sample(c("Male", "Female"), n, replace = TRUE),
    city        = sample(paste0("city_", 1:6), n, replace = TRUE),
    stringsAsFactors = FALSE
  )
  df
}

write_test_rds <- function(df) {
  p <- tempfile(fileext = ".rds")
  saveRDS(df, p)
  p
}

test_that("plot_interaction: returns model + plot data and writes PNG", {
  df    <- make_interaction_df()
  rds   <- write_test_rds(df)
  outd  <- tempfile("intplot_")
  res <- suppressMessages(suppressWarnings(suppressMessages(
    mysterycall_plot_interaction(
      data_path             = rds,
      response_variable     = "wait",
      variable_of_interest  = "insurance",
      interaction_variable  = "gender",
      random_intercept      = "city",
      output_path           = outd
    )
  )))
  expect_named(res, c("model", "effects_plot_data"))
  expect_s4_class(res$model, "glmerMod")
  expect_s3_class(res$effects_plot_data, "data.frame")
  expect_true("mean_pred" %in% names(res$effects_plot_data))
  png_files <- list.files(outd, pattern = "\\.png$", full.names = TRUE)
  expect_true(length(png_files) >= 1L)
})

test_that("plot_interaction: rejects missing required column", {
  df    <- make_interaction_df()
  df$wait <- NULL
  rds   <- write_test_rds(df)
  outd  <- tempfile("intplot_")
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_plot_interaction(
        data_path             = rds,
        response_variable     = "wait",
        variable_of_interest  = "insurance",
        interaction_variable  = "gender",
        random_intercept      = "city",
        output_path           = outd
      )
    )),
    "wait"
  )
})

test_that("plot_interaction: rejects non-data.frame RDS contents", {
  rds <- tempfile(fileext = ".rds")
  saveRDS(list(a = 1), rds)
  outd <- tempfile("intplot_")
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_plot_interaction(
        data_path             = rds,
        response_variable     = "wait",
        variable_of_interest  = "insurance",
        interaction_variable  = "gender",
        random_intercept      = "city",
        output_path           = outd
      )
    )),
    "data\\.frame"
  )
})
