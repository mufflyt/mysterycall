library(testthat)
library(mysterycall)

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

# Test 1: Happy path - basic fixed-effects formula
test_that("mysterycall_create_formula returns formula object with valid data, no random effect", {
  df <- data.frame(
    days = c(5, 10, 15),
    age = c(30, 40, 50),
    name = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_create_formula(df, "days"))

  expect_s3_class(result, "formula")
  expect_equal(class(result), "formula")
  formula_str <- deparse(result)
  expect_true(grepl("days", formula_str))
  expect_true(grepl("age", formula_str))
  expect_true(grepl("name", formula_str))
  expect_false(grepl("\\(1 \\|", formula_str))
})

# Test 2: Happy path - formula with random effect
test_that("mysterycall_create_formula includes random effect when specified", {
  df <- data.frame(
    days = c(5, 10, 15, 20),
    age = c(30, 40, 50, 60),
    physician = c("A", "B", "A", "B"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_create_formula(df, "days", random_effect = "physician"))

  expect_s3_class(result, "formula")
  formula_str <- deparse(result)
  expect_true(grepl("physician", formula_str))
  expect_true(grepl("\\(1 \\|", formula_str))
  expect_true(grepl("age", formula_str))
})

# Test 3: Edge case - multiple predictor variables
test_that("mysterycall_create_formula handles multiple predictor variables", {
  df <- data.frame(
    outcome = c(1, 2, 3, 4),
    pred1 = c(10, 20, 30, 40),
    pred2 = c(100, 200, 300, 400),
    pred3 = c(1000, 2000, 3000, 4000),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_create_formula(df, "outcome"))

  expect_s3_class(result, "formula")
  formula_str <- deparse(result)
  expect_true(grepl("pred1", formula_str))
  expect_true(grepl("pred2", formula_str))
  expect_true(grepl("pred3", formula_str))
})

# Test 4: Edge case - response and random effect are only columns besides predictors
test_that("mysterycall_create_formula works with minimal data structure", {
  df <- data.frame(
    response = c(5, 10, 15),
    predictor = c(1, 2, 3),
    grouping = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_create_formula(df, "response", random_effect = "grouping"))

  expect_s3_class(result, "formula")
  formula_str <- deparse(result)
  expect_true(grepl("response", formula_str))
  expect_true(grepl("predictor", formula_str))
  expect_true(grepl("grouping", formula_str))
})

# Test 5: Error case - data is not a data frame
test_that("mysterycall_create_formula errors when data is not a data frame", {
  expect_error(
    suppressMessages(mysterycall_create_formula(list(x = 1), "x")),
    "`data` must be a data frame"
  )
})

# Test 6: Error case - response variable not in data
test_that("mysterycall_create_formula errors when response_var not in data", {
  df <- data.frame(a = c(1, 2), b = c(3, 4), stringsAsFactors = FALSE)
  expect_error(
    suppressMessages(mysterycall_create_formula(df, "nonexistent"))
  )
})

# Test 7: Error case - random effect variable not in data
test_that("mysterycall_create_formula errors when random_effect not in data", {
  df <- data.frame(a = c(1, 2), b = c(3, 4), stringsAsFactors = FALSE)
  expect_error(
    suppressMessages(mysterycall_create_formula(df, "a", random_effect = "missing"))
  )
})

# Test 8: Error case - no predictors left after excluding response and random effect
test_that("mysterycall_create_formula errors when no predictors remain", {
  df <- data.frame(
    response = c(1, 2, 3),
    grouping = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_create_formula(df, "response", random_effect = "grouping")),
    "No predictor variables remain after excluding response_var and random_effect"
  )
})

# Test 9: Valid formula can be used with glm()
test_that("mysterycall_create_formula output works with stats::glm", {
  set.seed(42)
  df <- data.frame(
    count = rpois(30, 5),
    group = factor(rep(c("A", "B", "C"), 10)),
    value = rnorm(30),
    stringsAsFactors = FALSE
  )
  formula_obj <- suppressMessages(mysterycall_create_formula(df, "count"))

  expect_no_error(
    suppressMessages(glm(formula_obj, data = df, family = poisson()))
  )
})
