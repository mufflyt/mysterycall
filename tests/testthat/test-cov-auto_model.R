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


# ---- mysterycall_auto_model: Happy path ----

test_that("mysterycall_auto_model: basic call with include_lmm=TRUE returns auto_model object", {
  skip_if_not_installed("lme4")

  set.seed(200)
  test_data <- COUNT_DF
  test_data$physician <- rep(paste0("Dr_", 1:8), length.out = nrow(COUNT_DF))

  result <- suppressMessages(mysterycall_auto_model(
    test_data,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "physician",
    include_lmm = TRUE
  ))

  expect_s3_class(result, "mysterycall_auto_model")
  expect_true(!is.null(result$selection))
  expect_named(result$selection, c("poisson_phi", "model_chosen", "reason",
                                   "lmm", "lmm_shapiro_p", "lmm_defensible",
                                   "lmm_recommendation", "recommendation"))
  expect_true(result$selection$model_chosen %in% c("poisson", "negative_binomial"))
  expect_true(is.numeric(result$selection$poisson_phi))
})


test_that("mysterycall_auto_model: include_lmm=FALSE skips LMM fitting", {
  skip_if_not_installed("lme4")

  set.seed(201)
  test_data <- COUNT_DF
  test_data$physician <- rep(paste0("Dr_", 1:8), length.out = nrow(COUNT_DF))

  result <- suppressMessages(mysterycall_auto_model(
    test_data,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "physician",
    include_lmm = FALSE
  ))

  expect_s3_class(result, "mysterycall_auto_model")
  expect_null(result$selection$lmm)
  expect_true(is.na(result$selection$lmm_shapiro_p))
  expect_match(result$selection$lmm_recommendation, "LMM not attempted")
})


test_that("mysterycall_auto_model: selection structure contains valid recommendation text", {
  skip_if_not_installed("lme4")

  set.seed(202)
  test_data <- COUNT_DF
  test_data$physician <- rep(paste0("Dr_", 1:8), length.out = nrow(COUNT_DF))

  result <- suppressMessages(mysterycall_auto_model(
    test_data,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "physician"
  ))

  expect_true(is.character(result$selection$reason))
  expect_true(nchar(result$selection$reason) > 0)
  expect_true(is.character(result$selection$recommendation))
  expect_true(nchar(result$selection$recommendation) > 0)
  expect_true(any(grepl("PRIMARY MODEL", result$selection$recommendation)))
})


# ---- mysterycall_auto_model: Edge cases ----

test_that("mysterycall_auto_model: handles small outcome range (< 30 days)", {
  skip_if_not_installed("lme4")

  set.seed(203)
  test_data <- data.frame(
    days      = c(1L, 2L, 1L, 3L, 2L, 1L, 2L, 3L),
    insurance = rep(c("Medicaid", "BCBS"), 4L),
    physician = rep(paste0("Dr_", 1:2), each = 4L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_auto_model(
    test_data,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "physician",
    include_lmm = TRUE
  ))

  expect_s3_class(result, "mysterycall_auto_model")
  if (!is.null(result$selection$lmm)) {
    # If LMM fitted, it should be flagged as not defensible due to small range
    expect_false(isTRUE(result$selection$lmm_defensible))
  }
})


test_that("mysterycall_auto_model: handles data with NA values in outcome", {
  skip_if_not_installed("lme4")

  set.seed(204)
  test_data <- COUNT_DF
  test_data$physician <- rep(paste0("Dr_", 1:8), length.out = nrow(COUNT_DF))
  test_data$days[5L] <- NA_integer_

  result <- suppressMessages(mysterycall_auto_model(
    test_data,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "physician",
    include_lmm = FALSE
  ))

  expect_s3_class(result, "mysterycall_auto_model")
  expect_true(!is.null(result$selection))
})


# ---- mysterycall_auto_model: Bad input errors ----

test_that("mysterycall_auto_model: error when outcome column does not exist", {
  skip_if_not_installed("lme4")

  set.seed(205)
  test_data <- COUNT_DF
  test_data$physician <- rep(paste0("Dr_", 1:8), length.out = nrow(COUNT_DF))

  expect_error(
    suppressMessages(mysterycall_auto_model(
      test_data,
      outcome = "nonexistent_column",
      predictors = "insurance",
      random_intercept = "physician"
    )),
    class = "error"
  )
})


test_that("mysterycall_auto_model: error when random_intercept column does not exist", {
  skip_if_not_installed("lme4")

  set.seed(206)
  test_data <- COUNT_DF
  test_data$physician <- rep(paste0("Dr_", 1:8), length.out = nrow(COUNT_DF))

  expect_error(
    suppressMessages(mysterycall_auto_model(
      test_data,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "nonexistent_column"
    )),
    class = "error"
  )
})


test_that("mysterycall_auto_model: error when predictor column does not exist", {
  skip_if_not_installed("lme4")

  set.seed(207)
  test_data <- COUNT_DF
  test_data$physician <- rep(paste0("Dr_", 1:8), length.out = nrow(COUNT_DF))

  expect_error(
    suppressMessages(mysterycall_auto_model(
      test_data,
      outcome = "days",
      predictors = "nonexistent_column",
      random_intercept = "physician"
    )),
    class = "error"
  )
})


# ---- mysterycall_auto_model: Parameter variations ----

test_that("mysterycall_auto_model: respects phi_threshold parameter", {
  skip_if_not_installed("lme4")

  set.seed(208)
  test_data <- COUNT_DF
  test_data$physician <- rep(paste0("Dr_", 1:8), length.out = nrow(COUNT_DF))

  result_low <- suppressMessages(mysterycall_auto_model(
    test_data,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "physician",
    phi_threshold = 0.5,
    include_lmm = FALSE
  ))

  result_high <- suppressMessages(mysterycall_auto_model(
    test_data,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "physician",
    phi_threshold = 5.0,
    include_lmm = FALSE
  ))

  # Both should be valid results
  expect_s3_class(result_low, "mysterycall_auto_model")
  expect_s3_class(result_high, "mysterycall_auto_model")

  # The actual model selected may differ based on phi threshold
  # Just verify the selection metadata is present
  expect_true(!is.null(result_low$selection))
  expect_true(!is.null(result_high$selection))
})


# ---- print.mysterycall_auto_model ----

test_that("print.mysterycall_auto_model: outputs selection metadata to console", {
  skip_if_not_installed("lme4")

  set.seed(209)
  test_data <- COUNT_DF
  test_data$physician <- rep(paste0("Dr_", 1:8), length.out = nrow(COUNT_DF))

  result <- suppressMessages(mysterycall_auto_model(
    test_data,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "physician",
    include_lmm = FALSE
  ))

  output <- capture.output(suppressMessages(print(result)))

  expect_true(any(grepl("Auto-Model Selection", output)))
  expect_true(any(grepl("Count model", output)))
  expect_true(any(grepl("Recommendation", output)))
})


test_that("print.mysterycall_auto_model: displays LMM info when include_lmm=TRUE", {
  skip_if_not_installed("lme4")

  set.seed(210)
  test_data <- COUNT_DF
  test_data$physician <- rep(paste0("Dr_", 1:8), length.out = nrow(COUNT_DF))

  result <- suppressMessages(mysterycall_auto_model(
    test_data,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "physician",
    include_lmm = TRUE
  ))

  output <- capture.output(suppressMessages(print(result)))

  expect_true(any(grepl("Auto-Model Selection", output)))
  # With include_lmm=TRUE, LMM info should be displayed if it fitted
  if (!is.null(result$selection$lmm)) {
    expect_true(any(grepl("LMM|Shapiro", output)))
  }
})
