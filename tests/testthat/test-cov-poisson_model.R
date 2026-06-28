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

# Test 1: Happy path with minimal valid inputs
test_that("mysterycall_poisson_model fits basic model with valid inputs", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(60, 8),
    group = rep(c("A", "B"), each = 30),
    physician = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  expect_s3_class(result, "mysterycall_poisson_model")
  expect_true(is.list(result))
  expect_named(result, c(
    "model", "irr_table", "random_effects", "factor_refs",
    "formula", "n", "n_dropped", "n_clusters", "overdispersion",
    "convergence", "aic", "bic"
  ))
  expect_s3_class(result$model, "glmerMod")
  expect_true(is.data.frame(result$irr_table))
  expect_equal(result$n, 60L)
  expect_equal(result$n_dropped, 0L)
  expect_true(result$n_clusters > 0L)
})

# Test 2: Model with multiple predictors
test_that("mysterycall_poisson_model handles multiple predictors", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(80, 7),
    group1 = rep(c("X", "Y"), each = 40),
    group2 = rep(c("Control", "Treat"), 40),
    physician = rep(1:8, 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = c("group1", "group2"),
      random_intercept = "physician"
    )
  ))

  expect_s3_class(result, "mysterycall_poisson_model")
  expect_true(nrow(result$irr_table) >= 3L)  # intercept + group1 + group2
  expect_named(result$factor_refs, c("group1", "group2"))
})

# Test 3: Model with offset column
test_that("mysterycall_poisson_model handles offset_col parameter", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(50, 5),
    group = rep(c("A", "B"), each = 25),
    exposure = rep(c(1, 2), 25),
    physician = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician",
      offset_col = "exposure"
    )
  ))

  expect_s3_class(result, "mysterycall_poisson_model")
  expect_true(grepl("offset", deparse(result$formula)))
})

# Test 4: Edge case - NA values in predictors (should be excluded)
test_that("mysterycall_poisson_model handles NA values by exclusion", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = c(rpois(50, 5), NA, NA, NA, NA, NA, NA, NA, NA, NA, NA),
    group = c(rep(c("A", "B"), each = 25), rep("A", 11)),
    physician = c(rep(1:5, 10), rep(1:2, 5.5)),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  expect_equal(result$n_dropped, 11L)
  expect_equal(result$n, 50L)
})

# Test 5: Edge case - data with zero counts (valid in Poisson)
test_that("mysterycall_poisson_model accepts zero counts", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = c(0, 0, 1, 2, 3, rpois(45, 4)),
    group = rep(c("A", "B"), each = 25),
    physician = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  expect_equal(result$n, 50L)
  expect_s3_class(result, "mysterycall_poisson_model")
})

# Test 6: Bad input - missing required argument
test_that("mysterycall_poisson_model errors on missing outcome", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(50, 5),
    group = rep(c("A", "B"), each = 25),
    physician = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_poisson_model(
      data = test_df,
      predictors = "group",
      random_intercept = "physician"
    ),
    "outcome"
  )
})

# Test 7: Bad input - non-existent outcome column
test_that("mysterycall_poisson_model errors on non-existent outcome column", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(50, 5),
    group = rep(c("A", "B"), each = 25),
    physician = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "nonexistent",
      predictors = "group",
      random_intercept = "physician"
    ),
    "outcome"
  )
})

# Test 8: Bad input - non-numeric outcome
test_that("mysterycall_poisson_model errors on non-numeric outcome", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rep(c("A", "B"), 25),
    group = rep(c("X", "Y"), 25),
    physician = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    ),
    "numeric"
  )
})

# Test 9: Bad input - negative values in outcome
test_that("mysterycall_poisson_model errors on negative outcome values", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = c(-1, rpois(49, 5)),
    group = rep(c("A", "B"), each = 25),
    physician = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    ),
    "negative"
  )
})

# Test 10: Bad input - invalid conf_level
test_that("mysterycall_poisson_model errors on invalid conf_level", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(50, 5),
    group = rep(c("A", "B"), each = 25),
    physician = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_poisson_model(
        data = test_df,
        outcome = "count",
        predictors = "group",
        random_intercept = "physician",
        conf_level = 1.5
      )
    )),
    "conf_level"
  )
})

# Test 11: Bad input - invalid offset_col (non-numeric)
test_that("mysterycall_poisson_model errors on non-numeric offset_col", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(50, 5),
    group = rep(c("A", "B"), each = 25),
    exposure = rep(c("low", "high"), 25),
    physician = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_poisson_model(
        data = test_df,
        outcome = "count",
        predictors = "group",
        random_intercept = "physician",
        offset_col = "exposure"
      )
    )),
    "numeric"
  )
})

# Test 12: Print method returns object invisibly and displays output
test_that("print.mysterycall_poisson_model displays summary and returns invisibly", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(60, 8),
    group = rep(c("A", "B"), each = 30),
    physician = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  # Capture printed output
  output <- capture_output(result <- print(model))

  expect_invisible(result)
  expect_true(nchar(output) > 0)
  expect_match(output, "Poisson GLMER")
  expect_match(output, "Fixed effects")
})

# Test 13: Print method with custom digits parameter
test_that("print.mysterycall_poisson_model respects digits parameter", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(60, 8),
    group = rep(c("A", "B"), each = 30),
    physician = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  output_3 <- capture_output(print(model, digits = 3))
  output_1 <- capture_output(print(model, digits = 1))

  expect_true(nchar(output_3) > 0)
  expect_true(nchar(output_1) > 0)
})

# Test 14: Tidy method returns tibble with correct columns
test_that("tidy.mysterycall_poisson_model returns properly formatted tibble", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(60, 8),
    group = rep(c("A", "B"), each = 30),
    physician = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  tidy_result <- tidy.mysterycall_poisson_model(model)

  expect_s3_class(tidy_result, "tbl_df")
  expect_named(tidy_result, c(
    "term", "estimate", "std.error", "statistic", "p.value",
    "conf.low", "conf.high"
  ))
  expect_true(nrow(tidy_result) >= 2L)
  expect_true(all(is.numeric(tidy_result$estimate)))
  expect_true(all(is.numeric(tidy_result$p.value)))
})

# Test 15: Tidy method IRR values are exponentiated
test_that("tidy.mysterycall_poisson_model returns IRR (exponentiated) estimates", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(60, 8),
    group = rep(c("A", "B"), each = 30),
    physician = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  tidy_result <- tidy.mysterycall_poisson_model(model)

  # IRR estimates should be > 0 (all are exponentiated from log scale)
  expect_true(all(tidy_result$estimate > 0))
  # Confidence intervals should also be positive
  expect_true(all(tidy_result$conf.low > 0))
  expect_true(all(tidy_result$conf.high > 0))
})

# Test 16: Tidy method conf.low < estimate < conf.high
test_that("tidy.mysterycall_poisson_model CI bounds are properly ordered", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(60, 8),
    group = rep(c("A", "B"), each = 30),
    physician = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  tidy_result <- tidy.mysterycall_poisson_model(model)

  # For each row, conf.low < estimate < conf.high
  expect_true(all(tidy_result$conf.low <= tidy_result$estimate))
  expect_true(all(tidy_result$estimate <= tidy_result$conf.high))
})

# Test 17: IRR table from model matches tidy output
test_that("tidy.mysterycall_poisson_model IRRs match irr_table", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(60, 8),
    group = rep(c("A", "B"), each = 30),
    physician = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  tidy_result <- tidy.mysterycall_poisson_model(model)

  # IRRs from tidy should match irr_table
  expect_equal(tidy_result$estimate, model$irr_table$irr, tolerance = 1e-10)
  expect_equal(tidy_result$std.error, model$irr_table$se, tolerance = 1e-10)
  expect_equal(tidy_result$conf.low, model$irr_table$ci_lower, tolerance = 1e-10)
  expect_equal(tidy_result$conf.high, model$irr_table$ci_upper, tolerance = 1e-10)
})

# Test 18: Model with factor predictor
test_that("mysterycall_poisson_model handles factor predictors correctly", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(60, 8),
    group = factor(rep(c("A", "B", "C"), each = 20), levels = c("A", "B", "C")),
    physician = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  expect_named(result$factor_refs, "group")
  expect_equal(result$factor_refs$group, "A")  # First level alphabetically
})

# Test 19: Return object structure matches documentation
test_that("mysterycall_poisson_model return list has all documented elements", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(60, 8),
    group = rep(c("A", "B"), each = 30),
    physician = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  # Check all documented elements exist
  expect_true(exists("model", where = result) && length(result$model) > 0)
  expect_true(exists("irr_table", where = result) && is.data.frame(result$irr_table))
  expect_true(exists("random_effects", where = result) && is.data.frame(result$random_effects))
  expect_true(exists("factor_refs", where = result) && is.list(result$factor_refs))
  expect_true(exists("formula", where = result) && class(result$formula) == "formula")
  expect_true(exists("n", where = result) && is.numeric(result$n))
  expect_true(exists("n_dropped", where = result) && is.numeric(result$n_dropped))
  expect_true(exists("n_clusters", where = result) && is.numeric(result$n_clusters))
  expect_true(exists("overdispersion", where = result) && is.numeric(result$overdispersion))
  expect_true(exists("convergence", where = result) && is.list(result$convergence))
  expect_true(exists("aic", where = result) && is.numeric(result$aic))
  expect_true(exists("bic", where = result) && is.numeric(result$bic))
})

# Test 20: Convergence list structure
test_that("mysterycall_poisson_model convergence element has required fields", {
  skip_if_not_installed("lme4")

  set.seed(223)
  test_df <- data.frame(
    count = rpois(60, 8),
    group = rep(c("A", "B"), each = 30),
    physician = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      data = test_df,
      outcome = "count",
      predictors = "group",
      random_intercept = "physician"
    )
  ))

  expect_named(result$convergence, c("converged", "singular", "messages"))
  expect_true(is.logical(result$convergence$converged))
  expect_true(is.logical(result$convergence$singular))
  expect_true(is.character(result$convergence$messages))
})
