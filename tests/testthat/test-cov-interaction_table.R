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

# ============================================================================
# Test 1: mysterycall_interaction_table happy path
# ============================================================================
test_that("mysterycall_interaction_table happy path with fake fit object", {
  fake_or_table <- data.frame(
    term        = c("(Intercept)",
                    "insuranceMedicaid",
                    "specialtyGYN",
                    "insuranceMedicaid:specialtyGYN",
                    "insuranceMedicaid:specialtyOB"),
    estimate    = c( 0.80, -0.20,  0.15, -0.45,  0.31),
    se          = c( 0.18,  0.14,  0.12,  0.21,  0.19),
    z_value     = c( 4.44, -1.43,  1.25, -2.14,  1.63),
    p_value     = c( 0.001,  0.153,  0.211,  0.032,  0.103),
    p_value_fmt = c("< 0.001", "0.153", "0.211", "0.032", "0.103"),
    or          = c( 2.23,  0.82,  1.16,  0.64,  1.36),
    ci_lower    = c( 1.56,  0.62,  0.92,  0.42,  0.94),
    ci_upper    = c( 3.19,  1.08,  1.46,  0.97,  1.97),
    stringsAsFactors = FALSE
  )
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = fake_or_table,
      n          = 200L,
      n_clusters = 40L,
      formula    = stats::as.formula(
        "offered ~ insurance * specialty + (1 | physician)"
      )
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressWarnings(mysterycall_interaction_table(fake_fit, "insurance", "specialty"))

  expect_s3_class(result, "mysterycall_interaction_table")
  expect_true(is.list(result))
  expect_true(inherits(result$interaction_ors, "tbl_df") || is.data.frame(result$interaction_ors))
  expect_equal(nrow(result$interaction_ors), 2L)
  expect_true("term" %in% names(result$interaction_ors))
  expect_true("or" %in% names(result$interaction_ors))
  expect_true("ci_lower" %in% names(result$interaction_ors))
  expect_true("ci_upper" %in% names(result$interaction_ors))
  expect_true("p_value_fmt" %in% names(result$interaction_ors))
  expect_true(is.na(result$lrt_p))
  expect_equal(result$lrt_p_fmt, "NA")
  expect_true(grepl("interaction between insurance and specialty", result$sentence))
  expect_true(grepl("undetermined", result$sentence))
  expect_equal(result$var1, "insurance")
  expect_equal(result$var2, "specialty")
  expect_equal(result$digits, 2L)
  expect_equal(result$conf_level, 0.95)
})

# ============================================================================
# Test 2: mysterycall_interaction_table respects digits parameter
# ============================================================================
test_that("mysterycall_interaction_table respects digits parameter for rounding", {
  fake_or_table <- data.frame(
    term        = c("insuranceMedicaid:specialtyGYN", "insuranceMedicaid:specialtyOB"),
    or          = c(0.6378, 1.3625),
    ci_lower    = c(0.4234, 0.9401),
    ci_upper    = c(0.9765, 1.9742),
    stringsAsFactors = FALSE
  )
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = fake_or_table,
      n          = 200L,
      n_clusters = 40L,
      formula    = stats::as.formula("offered ~ insurance * specialty + (1 | physician)")
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressWarnings(mysterycall_interaction_table(fake_fit, "insurance", "specialty", digits = 0L))

  expect_equal(result$digits, 0L)
  expect_equal(result$interaction_ors$or[[1]], 1)
  expect_equal(result$interaction_ors$or[[2]], 1)
})

# ============================================================================
# Test 3: mysterycall_interaction_table respects conf_level parameter
# ============================================================================
test_that("mysterycall_interaction_table respects conf_level parameter", {
  fake_or_table <- data.frame(
    term     = "insuranceMedicaid:specialtyGYN",
    or       = 0.64,
    ci_lower = 0.42,
    ci_upper = 0.97,
    stringsAsFactors = FALSE
  )
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = fake_or_table,
      n          = 200L,
      n_clusters = 40L,
      formula    = stats::as.formula("y ~ x")
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressWarnings(mysterycall_interaction_table(fake_fit, "insurance", "specialty", conf_level = 0.99))

  expect_equal(result$conf_level, 0.99)
})

# ============================================================================
# Test 4: mysterycall_interaction_table errors on wrong fit class
# ============================================================================
test_that("mysterycall_interaction_table errors on wrong fit class", {
  expect_error(
    mysterycall_interaction_table(list(foo = "bar"), "insurance", "specialty"),
    "must be a mysterycall_logistic_model"
  )

  expect_error(
    mysterycall_interaction_table(data.frame(x = 1), "insurance", "specialty"),
    "must be a mysterycall_logistic_model"
  )
})

# ============================================================================
# Test 5: mysterycall_interaction_table errors on invalid var1
# ============================================================================
test_that("mysterycall_interaction_table errors on invalid var1", {
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = data.frame(term = "test", or = 1, ci_lower = 0.5, ci_upper = 2),
      n          = 100L,
      n_clusters = 20L,
      formula    = stats::as.formula("y ~ x")
    ),
    class = "mysterycall_logistic_model"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, "", "specialty"),
    "var1.*non-empty character"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, NULL, "specialty"),
    "var1.*non-empty character"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, c("insurance", "other"), "specialty"),
    "var1.*non-empty character"
  )
})

# ============================================================================
# Test 6: mysterycall_interaction_table errors on invalid var2
# ============================================================================
test_that("mysterycall_interaction_table errors on invalid var2", {
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = data.frame(term = "test", or = 1, ci_lower = 0.5, ci_upper = 2),
      n          = 100L,
      n_clusters = 20L,
      formula    = stats::as.formula("y ~ x")
    ),
    class = "mysterycall_logistic_model"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, "insurance", ""),
    "var2.*non-empty character"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, "insurance", NULL),
    "var2.*non-empty character"
  )
})

# ============================================================================
# Test 7: mysterycall_interaction_table errors when no interaction rows found
# ============================================================================
test_that("mysterycall_interaction_table errors when no interaction rows found", {
  fake_or_table <- data.frame(
    term        = c("(Intercept)", "insuranceMedicaid", "specialtyGYN"),
    or          = c(2.23, 0.82, 1.16),
    ci_lower    = c(1.56, 0.62, 0.92),
    ci_upper    = c(3.19, 1.08, 1.46),
    stringsAsFactors = FALSE
  )
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = fake_or_table,
      n          = 200L,
      n_clusters = 40L,
      formula    = stats::as.formula("offered ~ insurance + specialty + (1 | physician)")
    ),
    class = "mysterycall_logistic_model"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, "insurance", "specialty"),
    "No interaction rows found"
  )
})

# ============================================================================
# Test 8: mysterycall_interaction_table errors on invalid conf_level
# ============================================================================
test_that("mysterycall_interaction_table errors on invalid conf_level", {
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = data.frame(
        term     = "insuranceMedicaid:specialtyGYN",
        or       = 0.64,
        ci_lower = 0.42,
        ci_upper = 0.97
      ),
      n          = 100L,
      n_clusters = 20L,
      formula    = stats::as.formula("y ~ x")
    ),
    class = "mysterycall_logistic_model"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, "insurance", "specialty", conf_level = 0),
    "conf_level.*strictly between 0 and 1"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, "insurance", "specialty", conf_level = 1),
    "conf_level.*strictly between 0 and 1"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, "insurance", "specialty", conf_level = 1.5),
    "conf_level.*strictly between 0 and 1"
  )
})

# ============================================================================
# Test 9: mysterycall_interaction_table errors on invalid digits
# ============================================================================
test_that("mysterycall_interaction_table errors on invalid digits", {
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = data.frame(
        term     = "insuranceMedicaid:specialtyGYN",
        or       = 0.64,
        ci_lower = 0.42,
        ci_upper = 0.97
      ),
      n          = 100L,
      n_clusters = 20L,
      formula    = stats::as.formula("y ~ x")
    ),
    class = "mysterycall_logistic_model"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, "insurance", "specialty", digits = -1L),
    "digits.*non-negative integer"
  )
})

# ============================================================================
# Test 10: mysterycall_interaction_table errors when or_table missing
# ============================================================================
test_that("mysterycall_interaction_table errors when or_table missing", {
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = NULL,
      n          = 100L,
      n_clusters = 20L,
      formula    = stats::as.formula("y ~ x")
    ),
    class = "mysterycall_logistic_model"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, "insurance", "specialty"),
    "or_table.*missing"
  )
})

# ============================================================================
# Test 11: mysterycall_interaction_table errors when required columns missing
# ============================================================================
test_that("mysterycall_interaction_table errors when required columns missing", {
  fake_or_table <- data.frame(
    term = "insuranceMedicaid:specialtyGYN",
    or   = 0.64
  )
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = fake_or_table,
      n          = 100L,
      n_clusters = 20L,
      formula    = stats::as.formula("y ~ x")
    ),
    class = "mysterycall_logistic_model"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, "insurance", "specialty"),
    "missing required column"
  )
})

# ============================================================================
# Test 12: mysterycall_interaction_table errors when term column missing
# ============================================================================
test_that("mysterycall_interaction_table errors when term column missing from or_table", {
  fake_or_table <- data.frame(
    or       = 0.64,
    ci_lower = 0.42,
    ci_upper = 0.97
  )
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = fake_or_table,
      n          = 100L,
      n_clusters = 20L,
      formula    = stats::as.formula("y ~ x")
    ),
    class = "mysterycall_logistic_model"
  )

  expect_error(
    mysterycall_interaction_table(fake_fit, "insurance", "specialty"),
    "has no 'term' column"
  )
})

# ============================================================================
# Test 13: mysterycall_interaction_table with p_value column (instead of p_value_fmt)
# ============================================================================
test_that("mysterycall_interaction_table formats p_value column when p_value_fmt missing", {
  fake_or_table <- data.frame(
    term     = c("insuranceMedicaid:specialtyGYN", "insuranceMedicaid:specialtyOB"),
    p_value  = c(0.032, 0.001),
    or       = c(0.64, 1.36),
    ci_lower = c(0.42, 0.94),
    ci_upper = c(0.97, 1.97),
    stringsAsFactors = FALSE
  )
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = fake_or_table,
      n          = 200L,
      n_clusters = 40L,
      formula    = stats::as.formula("offered ~ insurance * specialty + (1 | physician)")
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressWarnings(mysterycall_interaction_table(fake_fit, "insurance", "specialty"))

  expect_s3_class(result, "mysterycall_interaction_table")
  expect_equal(nrow(result$interaction_ors), 2L)
  expect_true("p_value_fmt" %in% names(result$interaction_ors))
})

# ============================================================================
# Test 14: print.mysterycall_interaction_table method
# ============================================================================
test_that("print.mysterycall_interaction_table prints without error", {
  fake_or_table <- data.frame(
    term        = c("insuranceMedicaid:specialtyGYN", "insuranceMedicaid:specialtyOB"),
    estimate    = c(-0.45, 0.31),
    se          = c(0.21, 0.19),
    z_value     = c(-2.14, 1.63),
    p_value     = c(0.032, 0.103),
    p_value_fmt = c("0.032", "0.103"),
    or          = c(0.64, 1.36),
    ci_lower    = c(0.42, 0.94),
    ci_upper    = c(0.97, 1.97),
    stringsAsFactors = FALSE
  )
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = fake_or_table,
      n          = 200L,
      n_clusters = 40L,
      formula    = stats::as.formula("offered ~ insurance * specialty + (1 | physician)")
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressWarnings(mysterycall_interaction_table(fake_fit, "insurance", "specialty"))

  # Capture output and verify it prints
  output <- capture.output(suppressWarnings(print(result)))
  expect_true(length(output) > 0)
  expect_true(any(grepl("Interaction table", output)))
  expect_true(any(grepl("odds ratios", output)))
  expect_true(any(grepl("LRT p-value", output)))
})

# ============================================================================
# Test 15: mysterycall_interaction_table returns invisible in print
# ============================================================================
test_that("print.mysterycall_interaction_table returns invisible", {
  fake_or_table <- data.frame(
    term        = c("insuranceMedicaid:specialtyGYN"),
    or          = c(0.64),
    ci_lower    = c(0.42),
    ci_upper    = c(0.97),
    p_value_fmt = c("0.032"),
    stringsAsFactors = FALSE
  )
  fake_fit <- structure(
    list(
      model      = NULL,
      or_table   = fake_or_table,
      n          = 200L,
      n_clusters = 40L,
      formula    = stats::as.formula("offered ~ insurance * specialty + (1 | physician)")
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressWarnings(mysterycall_interaction_table(fake_fit, "insurance", "specialty"))

  invisible_result <- suppressWarnings(print(result))
  expect_equal(invisible_result, result)
})
