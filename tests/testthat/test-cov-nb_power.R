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

test_that("mysterycall_nb_power: happy path with minimal defaults", {
  skip_if_not_installed("glmmTMB")
  set.seed(1)

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(n_physicians = 10L, n_sim = 100L)
  ))

  expect_s3_class(result, "mysterycall_nb_power")
  expect_type(result, "list")
  expect_named(result, c("power", "n_physicians", "total_n", "irr", "theta", "alpha", "n_sim", "ci"))
})

test_that("mysterycall_nb_power: returns correct types and values", {
  skip_if_not_installed("glmmTMB")
  set.seed(2)

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(
      n_physicians = 10L,
      calls_per_physician = 2L,
      irr = 0.75,
      theta = 2.0,
      baseline_mean = 21,
      sigma_u = 0.3,
      alpha = 0.05,
      n_sim = 100L,
      seed = 42L
    )
  ))

  expect_type(result$power, "double")
  expect_true(result$power >= 0 && result$power <= 1)
  expect_equal(result$n_physicians, 10L)
  expect_equal(result$total_n, 40L)
  expect_equal(result$irr, 0.75)
  expect_equal(result$theta, 2.0)
  expect_equal(result$alpha, 0.05)
  expect_equal(result$n_sim, 100L)
  expect_type(result$ci, "double")
  expect_length(result$ci, 2)
  expect_true(result$ci[1] >= 0 && result$ci[1] <= 1)
  expect_true(result$ci[2] >= 0 && result$ci[2] <= 1)
  expect_true(result$ci[1] <= result$ci[2])
})

test_that("mysterycall_nb_power: custom calls_per_physician parameter", {
  skip_if_not_installed("glmmTMB")
  set.seed(3)

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(
      n_physicians = 15L,
      calls_per_physician = 3L,
      n_sim = 100L
    )
  ))

  expect_equal(result$n_physicians, 15L)
  expect_equal(result$total_n, 90L)
})

test_that("mysterycall_nb_power: custom parameters (effect size, theta, alpha)", {
  skip_if_not_installed("glmmTMB")
  set.seed(4)

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(
      n_physicians = 20L,
      irr = 0.5,
      theta = 5.0,
      baseline_mean = 28,
      sigma_u = 0.5,
      alpha = 0.01,
      n_sim = 100L
    )
  ))

  expect_equal(result$n_physicians, 20L)
  expect_equal(result$irr, 0.5)
  expect_equal(result$theta, 5.0)
  expect_equal(result$alpha, 0.01)
})

test_that("mysterycall_nb_power: edge case with minimum valid n_physicians", {
  skip_if_not_installed("glmmTMB")
  set.seed(5)

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(n_physicians = 2L, n_sim = 50L)
  ))

  expect_s3_class(result, "mysterycall_nb_power")
  expect_equal(result$n_physicians, 2L)
  expect_true(result$power >= 0 && result$power <= 1)
})

test_that("mysterycall_nb_power: edge case with high theta (Poisson limit)", {
  skip_if_not_installed("glmmTMB")
  set.seed(6)

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(n_physicians = 10L, theta = 100, n_sim = 50L)
  ))

  expect_equal(result$theta, 100)
  expect_true(result$power >= 0 && result$power <= 1)
})

test_that("mysterycall_nb_power: edge case with sigma_u = 0 (no random intercept)", {
  skip_if_not_installed("glmmTMB")
  set.seed(7)

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(n_physicians = 10L, sigma_u = 0, n_sim = 50L)
  ))

  expect_true(result$power >= 0 && result$power <= 1)
})

test_that("mysterycall_nb_power: reproducible with seed", {
  skip_if_not_installed("glmmTMB")

  result1 <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(n_physicians = 10L, n_sim = 100L, seed = 999L)
  ))

  result2 <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(n_physicians = 10L, n_sim = 100L, seed = 999L)
  ))

  expect_equal(result1$power, result2$power)
  expect_equal(result1$ci, result2$ci)
})

test_that("mysterycall_nb_power: seed = NULL produces valid output", {
  skip_if_not_installed("glmmTMB")
  set.seed(8)

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(n_physicians = 10L, n_sim = 50L, seed = NULL)
  ))

  expect_s3_class(result, "mysterycall_nb_power")
  expect_true(result$power >= 0 && result$power <= 1)
})

test_that("mysterycall_nb_power: error on n_physicians < 2", {
  skip_if_not_installed("glmmTMB")

  expect_error(mysterycall_nb_power(n_physicians = 1L, n_sim = 50L))
  expect_error(mysterycall_nb_power(n_physicians = 0L, n_sim = 50L))
  expect_error(mysterycall_nb_power(n_physicians = -5L, n_sim = 50L))
})

test_that("mysterycall_nb_power: error on non-numeric n_physicians", {
  skip_if_not_installed("glmmTMB")

  expect_error(mysterycall_nb_power(n_physicians = "ten", n_sim = 50L))
  expect_error(mysterycall_nb_power(n_physicians = NULL, n_sim = 50L))
})

test_that("mysterycall_nb_power: error on irr <= 0", {
  skip_if_not_installed("glmmTMB")

  expect_error(mysterycall_nb_power(n_physicians = 10L, irr = 0, n_sim = 50L))
  expect_error(mysterycall_nb_power(n_physicians = 10L, irr = -0.5, n_sim = 50L))
})

test_that("mysterycall_nb_power: error on theta <= 0", {
  skip_if_not_installed("glmmTMB")

  expect_error(mysterycall_nb_power(n_physicians = 10L, theta = 0, n_sim = 50L))
  expect_error(mysterycall_nb_power(n_physicians = 10L, theta = -1, n_sim = 50L))
})

test_that("mysterycall_nb_power: error on baseline_mean <= 0", {
  skip_if_not_installed("glmmTMB")

  expect_error(mysterycall_nb_power(n_physicians = 10L, baseline_mean = 0, n_sim = 50L))
  expect_error(mysterycall_nb_power(n_physicians = 10L, baseline_mean = -5, n_sim = 50L))
})

test_that("mysterycall_nb_power: error on sigma_u < 0", {
  skip_if_not_installed("glmmTMB")

  expect_error(mysterycall_nb_power(n_physicians = 10L, sigma_u = -0.1, n_sim = 50L))
})

test_that("mysterycall_nb_power: error on alpha out of bounds", {
  skip_if_not_installed("glmmTMB")

  expect_error(mysterycall_nb_power(n_physicians = 10L, alpha = 0, n_sim = 50L))
  expect_error(mysterycall_nb_power(n_physicians = 10L, alpha = 1, n_sim = 50L))
  expect_error(mysterycall_nb_power(n_physicians = 10L, alpha = 1.5, n_sim = 50L))
})

test_that("mysterycall_nb_power: error on n_sim < 10", {
  skip_if_not_installed("glmmTMB")

  expect_error(mysterycall_nb_power(n_physicians = 10L, n_sim = 5L))
  expect_error(mysterycall_nb_power(n_physicians = 10L, n_sim = 0L))
})

test_that("mysterycall_nb_power: CI bounds are mathematically valid", {
  skip_if_not_installed("glmmTMB")
  set.seed(9)

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(n_physicians = 15L, n_sim = 200L)
  ))

  expect_true(result$ci[1] >= 0)
  expect_true(result$ci[2] <= 1)
  expect_true(result$ci[1] <= result$power)
  expect_true(result$ci[2] >= result$power)
  expect_true(result$ci[1] <= result$ci[2])
})

test_that("print.mysterycall_nb_power: displays output correctly", {
  skip_if_not_installed("glmmTMB")
  set.seed(10)

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(
      n_physicians = 20L,
      irr = 0.8,
      n_sim = 100L
    )
  ))

  output <- suppressWarnings(capture.output({
    print(result)
  }))

  expect_true(length(output) > 0)
  expect_match(output[1], "NB Power Analysis")
  output_str <- paste(output, collapse = " ")
  expect_match(output_str, "20")
  expect_match(output_str, "0.80")
  expect_match(output_str, "simulations")
})

test_that("print.mysterycall_nb_power: formats CI and power percentages", {
  skip_if_not_installed("glmmTMB")
  set.seed(11)

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(n_physicians = 10L, n_sim = 100L)
  ))

  output <- suppressWarnings(capture.output({
    print(result)
  }))

  output_str <- paste(output, collapse = " ")
  expect_match(output_str, "%")
})

test_that("mysterycall_nb_power: larger effect size should yield higher power", {
  skip_if_not_installed("glmmTMB")
  set.seed(12)

  result_small <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(
      n_physicians = 15L,
      irr = 0.95,
      n_sim = 150L
    )
  ))

  set.seed(12)
  result_large <- suppressMessages(suppressWarnings(
    mysterycall_nb_power(
      n_physicians = 15L,
      irr = 0.5,
      n_sim = 150L
    )
  ))

  expect_true(result_large$power >= result_small$power)
})
