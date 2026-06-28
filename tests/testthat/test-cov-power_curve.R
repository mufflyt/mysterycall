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


test_that("mysterycall_power_curve() happy path: returns invisible object", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")

  set.seed(1)
  result <- suppressMessages(
    mysterycall_power_curve(
      n_range    = c(20, 30),
      irr_values = c(0.70, 0.80),
      n_sim      = 50L,
      plot       = FALSE
    )
  )

  expect_s3_class(result, "mysterycall_power_curve")
  expect_true(is.list(result))
})


test_that("mysterycall_power_curve() returns correct structure", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")

  set.seed(42)
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_power_curve(
        n_range    = c(20, 30),
        irr_values = c(0.70, 0.80),
        n_sim      = 50L,
        plot       = FALSE
      )
    )
  )

  expect_s3_class(result, "mysterycall_power_curve")
  expect_named(result, c("plot", "data", "min_n", "params"))
  expect_s3_class(result$plot, "ggplot")
  expect_true(is.data.frame(result$data))
  expect_named(
    result$data,
    c("n_physicians", "irr_label", "irr", "power", "ci_lower", "ci_upper")
  )
  expect_true(is.numeric(result$min_n))
  expect_true(is.list(result$params))
})


test_that("mysterycall_power_curve() errors on invalid n_range", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")

  expect_error(
    suppressMessages(
      mysterycall_power_curve(
        n_range    = numeric(0),
        irr_values = c(0.70, 0.80),
        n_sim      = 50L
      )
    ),
    "n_range.*must be"
  )

  expect_error(
    suppressMessages(
      mysterycall_power_curve(
        n_range    = c(20, 1),
        irr_values = c(0.70, 0.80),
        n_sim      = 50L
      )
    ),
    "n_range.*>= 2"
  )
})


test_that("mysterycall_power_curve() errors on invalid irr_values", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")

  expect_error(
    suppressMessages(
      mysterycall_power_curve(
        n_range    = c(20, 30),
        irr_values = numeric(0),
        n_sim      = 50L
      )
    ),
    "irr_values.*must be"
  )

  expect_error(
    suppressMessages(
      mysterycall_power_curve(
        n_range    = c(20, 30),
        irr_values = c(0, 0.70),
        n_sim      = 50L
      )
    ),
    "irr_values.*positive"
  )
})


test_that("mysterycall_power_curve() errors on invalid target_power", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")

  expect_error(
    suppressMessages(
      mysterycall_power_curve(
        n_range      = c(20, 30),
        irr_values   = c(0.70, 0.80),
        target_power = 0,
        n_sim        = 50L
      )
    ),
    "target_power.*in \\(0, 1\\)"
  )

  expect_error(
    suppressMessages(
      mysterycall_power_curve(
        n_range      = c(20, 30),
        irr_values   = c(0.70, 0.80),
        target_power = 1,
        n_sim        = 50L
      )
    ),
    "target_power.*in \\(0, 1\\)"
  )
})


test_that("mysterycall_power_curve() stores parameters correctly", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")

  set.seed(2)
  n_range <- c(20, 30, 40)
  irr_values <- c(0.70, 0.80)
  calls_pp <- 3L
  theta_val <- 1.5

  result <- suppressMessages(
    mysterycall_power_curve(
      n_range             = n_range,
      irr_values          = irr_values,
      calls_per_physician = calls_pp,
      theta               = theta_val,
      n_sim               = 50L,
      plot                = FALSE
    )
  )

  expect_equal(result$params$n_range, n_range)
  expect_equal(result$params$irr_values, irr_values)
  expect_equal(result$params$calls_per_physician, calls_pp)
  expect_equal(result$params$theta, theta_val)
})


test_that("mysterycall_power_curve() computes data frame with correct dimensions", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")

  set.seed(3)
  n_range <- c(20, 30, 40)
  irr_values <- c(0.75, 0.85)

  result <- suppressMessages(
    mysterycall_power_curve(
      n_range    = n_range,
      irr_values = irr_values,
      n_sim      = 50L,
      plot       = FALSE
    )
  )

  # Should have one row per (n, irr) combination
  expect_equal(nrow(result$data), length(n_range) * length(irr_values))
  expect_true(all(!is.na(result$data$power)))
  expect_true(all(result$data$power >= 0 & result$data$power <= 1))
})


test_that("mysterycall_power_curve() min_n reflects target_power threshold", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")

  set.seed(4)
  result <- suppressMessages(
    mysterycall_power_curve(
      n_range      = c(20, 30, 40),
      irr_values   = c(0.75),
      target_power = 0.70,
      n_sim        = 50L,
      plot         = FALSE
    )
  )

  # min_n should be NA or a valid n from n_range
  if (!is.na(result$min_n[1])) {
    expect_true(result$min_n[1] %in% c(20, 30, 40))
  }
})


test_that("print.mysterycall_power_curve() displays min_n table", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")

  set.seed(5)
  result <- suppressMessages(
    mysterycall_power_curve(
      n_range    = c(20, 30),
      irr_values = c(0.75, 0.80),
      n_sim      = 50L,
      plot       = FALSE
    )
  )

  output <- capture.output(suppressMessages(print(result)))
  expect_true(any(grepl("Power Curve", output)))
  expect_true(any(grepl("Target power", output)))
  expect_true(any(grepl("IRR = ", output)))
})
