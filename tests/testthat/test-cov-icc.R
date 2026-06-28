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

# mysterycall_icc requires a mysterycall_poisson_model (GLMM with random effect)
set.seed(1)
GLMM_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid", "BCBS"), each = 40L),
  physician = rep(paste0("Dr", 1:20), each = 4L),
  stringsAsFactors = FALSE
)

# ============================================================================
# mysterycall_icc tests
# ============================================================================

test_that("mysterycall_icc: happy path returns mysterycall_icc object", {
  skip_if_not_installed("lme4")
  set.seed(203)
  mod <- suppressMessages(mysterycall_poisson_model(GLMM_DF, "days", "insurance", "physician"))
  result <- suppressMessages(mysterycall_icc(mod))
  expect_s3_class(result, "mysterycall_icc")
  expect_true("icc" %in% names(result))
  expect_true("sigma2_u" %in% names(result))
  expect_true("method" %in% names(result))
  expect_true(is.numeric(result$icc))
  expect_true(result$icc >= 0 && result$icc <= 1)
})

test_that("mysterycall_icc: bootstrap CI with n_boot > 0", {
  skip_if_not_installed("lme4")
  set.seed(203)
  mod <- suppressMessages(mysterycall_poisson_model(GLMM_DF, "days", "insurance", "physician"))
  set.seed(100)
  result <- suppressMessages(mysterycall_icc(mod, n_boot = 50L, seed = 100))
  expect_true(result$n_boot == 50L)
  expect_true(is.numeric(result$ci))
  expect_true(length(result$ci) == 2L)
})

test_that("mysterycall_icc: rejects wrong class for model_result", {
  skip_if_not_installed("lme4")
  expect_error(mysterycall_icc("not a model"), "mysterycall_poisson_model")
})

test_that("mysterycall_icc: rejects invalid conf_level", {
  skip_if_not_installed("lme4")
  set.seed(203)
  mod <- suppressMessages(mysterycall_poisson_model(GLMM_DF, "days", "insurance", "physician"))
  expect_error(mysterycall_icc(mod, conf_level = 2), "must be a single number")
  expect_error(mysterycall_icc(mod, conf_level = 0), "must be a single number")
  expect_error(mysterycall_icc(mod, conf_level = 1), "must be a single number")
})

test_that("mysterycall_icc: n_boot converted to integer", {
  skip_if_not_installed("lme4")
  set.seed(203)
  mod <- suppressMessages(mysterycall_poisson_model(GLMM_DF, "days", "insurance", "physician"))
  result <- suppressMessages(mysterycall_icc(mod, n_boot = 0L))
  expect_true(result$n_boot == 0L)
  expect_true(is.na(result$ci[1]))
})

# ============================================================================
# print.mysterycall_icc tests
# ============================================================================

test_that("print.mysterycall_icc: outputs ICC header and values", {
  skip_if_not_installed("lme4")
  set.seed(203)
  mod <- suppressMessages(mysterycall_poisson_model(GLMM_DF, "days", "insurance", "physician"))
  result <- suppressMessages(mysterycall_icc(mod))
  expect_output(suppressMessages(print(result)), "Intraclass Correlation")
  expect_output(suppressMessages(print(result)), "ICC")
})

# ============================================================================
# mysterycall_icc_sentence tests
# ============================================================================

test_that("mysterycall_icc_sentence: happy path returns formatted character", {
  fake_icc <- structure(
    list(
      icc = 0.18,
      sigma2_u = 0.72,
      method = "latent_variable_poisson",
      ci = c(NA, NA),
      n_boot = 0L,
      interpretation = "ICC = 0.18: 18.0% ...",
      model_class = "mysterycall_poisson_model"
    ),
    class = "mysterycall_icc"
  )
  result <- mysterycall_icc_sentence(fake_icc)
  expect_type(result, "character")
  expect_true(grepl("0.180", result))
  expect_true(grepl("18.0%", result))
  expect_true(grepl("multilevel model", result))
})

test_that("mysterycall_icc_sentence: includes bootstrap CI when n_boot > 0", {
  fake_icc <- structure(
    list(
      icc = 0.25,
      sigma2_u = 0.82,
      method = "latent_variable_poisson",
      ci = c(0.15, 0.35),
      n_boot = 100L,
      interpretation = "ICC = 0.25: 25.0% ...",
      model_class = "mysterycall_poisson_model"
    ),
    class = "mysterycall_icc"
  )
  result <- mysterycall_icc_sentence(fake_icc)
  expect_type(result, "character")
  expect_true(grepl("bootstrap CI", result))
  expect_true(grepl("0.150", result))
  expect_true(grepl("0.350", result))
})

test_that("mysterycall_icc_sentence: rejects wrong class", {
  expect_error(mysterycall_icc_sentence(list(icc = 0.5)), "mysterycall_icc")
})

# ============================================================================
# mysterycall_icc_report tests
# ============================================================================

test_that("mysterycall_icc_report: happy path returns mysterycall_icc_report object", {
  set.seed(42)
  df <- data.frame(
    caller_id = rep(c("Alice", "Bob", "Carol"), each = 20),
    offered = c(rbinom(20, 1, 0.70), rbinom(20, 1, 0.65), rbinom(20, 1, 0.68)),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_icc_report(df))
  expect_s3_class(result, "mysterycall_icc_report")
  expect_true("icc" %in% names(result))
  expect_true("kappa" %in% names(result))
  expect_true("ci" %in% names(result))
  expect_true("n_callers" %in% names(result))
  expect_true("sentence" %in% names(result))
  expect_true(is.numeric(result$icc))
  expect_true(result$icc >= 0 && result$icc <= 1)
})

test_that("mysterycall_icc_report: with group_col stratification", {
  set.seed(42)
  df <- data.frame(
    caller_id = rep(c("Alice", "Bob", "Carol"), each = 20),
    offered = c(rbinom(20, 1, 0.70), rbinom(20, 1, 0.65), rbinom(20, 1, 0.68)),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_icc_report(df, group_col = "insurance"))
  expect_true(!is.null(result$group_results))
  expect_true(is.list(result$group_results))
  expect_true(length(result$group_results) > 0L)
})

test_that("mysterycall_icc_report: missing outcome_col raises error", {
  df <- data.frame(caller_id = c("A", "B"), x = c(1, 0))
  expect_error(mysterycall_icc_report(df, outcome_col = "missing_col"), "not found")
})

test_that("mysterycall_icc_report: requires at least 2 callers", {
  set.seed(50)
  df <- data.frame(
    caller_id = rep("Alice", 10),
    offered = rbinom(10, 1, 0.5),
    stringsAsFactors = FALSE
  )
  expect_error(mysterycall_icc_report(df), "At least 2 distinct")
})

test_that("mysterycall_icc_report: invalid conf_level raises error", {
  set.seed(42)
  df <- data.frame(
    caller_id = rep(c("Alice", "Bob"), each = 10),
    offered = rbinom(20, 1, 0.5),
    stringsAsFactors = FALSE
  )
  expect_error(mysterycall_icc_report(df, conf_level = 1.5), "must be a single number")
  expect_error(mysterycall_icc_report(df, conf_level = 0), "must be a single number")
})

# ============================================================================
# print.mysterycall_icc_report tests
# ============================================================================

test_that("print.mysterycall_icc_report: outputs STROBE header and summary", {
  set.seed(42)
  df <- data.frame(
    caller_id = rep(c("Alice", "Bob"), each = 10),
    offered = c(rep(1, 10), rep(0, 10)),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_icc_report(df))
  expect_output(suppressMessages(print(result)), "Inter-Rater")
  expect_output(suppressMessages(print(result)), "STROBE")
})
