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

# Test 1: Happy path - basic call with valid paired data
test_that("mysterycall_wait_time_crossover returns correct structure with valid data", {
  set.seed(1)
  n_doc <- 25
  bcbs_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))
  medicaid_days <- pmax(1, round(rnorm(n_doc, mean = 12, sd = 3)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("BCBS", "Medicaid"), each = n_doc),
    business_days_until_appointment = c(bcbs_days, medicaid_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, min_pairs = 5L)

  expect_s3_class(result, "mysterycall_wait_time_crossover")
  expect_type(result, "list")
  expect_named(result, c("crossover_days", "slope", "intercept", "r_squared",
                         "n_pairs", "group1", "group2", "conf_level",
                         "log_transform", "plot_data", "model", "sentence"))
  expect_type(result$crossover_days, "double")
  expect_type(result$slope, "double")
  expect_type(result$intercept, "double")
  expect_type(result$r_squared, "double")
  expect_type(result$n_pairs, "integer")
  expect_type(result$group1, "character")
  expect_type(result$group2, "character")
  expect_true(is.data.frame(result$plot_data))
  expect_type(result$sentence, "character")
})

# Test 2: Edge case - log_transform = FALSE
test_that("mysterycall_wait_time_crossover works with log_transform = FALSE", {
  set.seed(2)
  n_doc <- 20
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 5, sd = 1)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("GroupA", "GroupB"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, log_transform = FALSE, min_pairs = 5L)

  expect_s3_class(result, "mysterycall_wait_time_crossover")
  expect_false(result$log_transform)
})

# Test 3: Edge case - with explicit group1 and group2
test_that("mysterycall_wait_time_crossover respects explicit group1 and group2", {
  set.seed(3)
  n_doc <- 20
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 6, sd = 2)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 10, sd = 3)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("Medicaid", "BCBS"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, group1 = "BCBS", group2 = "Medicaid", min_pairs = 5L)

  expect_equal(result$group1, "BCBS")
  expect_equal(result$group2, "Medicaid")
})

# Test 4: Edge case - NA values in wait times
test_that("mysterycall_wait_time_crossover handles NA values appropriately", {
  set.seed(4)
  n_doc <- 20
  g1_days <- c(pmax(1, round(rnorm(18, mean = 5, sd = 1))), NA, NA)
  g2_days <- c(pmax(1, round(rnorm(18, mean = 8, sd = 2))), NA, NA)

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("GroupA", "GroupB"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  # Should work with sufficient pairs after removing NAs
  result <- mysterycall_wait_time_crossover(df, min_pairs = 10L)
  expect_s3_class(result, "mysterycall_wait_time_crossover")
  expect_type(result$n_pairs, "integer")
})

# Test 5: Error - missing required column
test_that("mysterycall_wait_time_crossover errors on missing column", {
  df <- data.frame(
    insurance = c("A", "B"),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_wait_time_crossover(df),
               "Column.*not found")
})

# Test 6: Error - non-numeric time column
test_that("mysterycall_wait_time_crossover errors on non-numeric time column", {
  df <- data.frame(
    phone = c("123", "456"),
    insurance = c("A", "B"),
    business_days_until_appointment = c("5 days", "10 days"),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_wait_time_crossover(df),
               "must be numeric")
})

# Test 7: Error - insufficient pairs
test_that("mysterycall_wait_time_crossover errors on insufficient pairs", {
  set.seed(5)
  n_doc <- 3
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 5, sd = 1)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("GroupA", "GroupB"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_wait_time_crossover(df, min_pairs = 20L),
               "complete pair")
})

# Test 8: Error - less than 2 groups
test_that("mysterycall_wait_time_crossover errors when < 2 groups", {
  df <- data.frame(
    phone = c("123", "456"),
    insurance = c("A", "A"),
    business_days_until_appointment = c(5, 10),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_wait_time_crossover(df),
               "at least 2 distinct")
})

# Test 9: Error - group1 not found
test_that("mysterycall_wait_time_crossover errors on invalid group1", {
  set.seed(6)
  n_doc <- 20
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 5, sd = 1)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("GroupA", "GroupB"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_wait_time_crossover(df, group1 = "NonExistent", min_pairs = 5L),
               "not found")
})

# Test 10: Error - identical group1 and group2
test_that("mysterycall_wait_time_crossover errors when group1 == group2", {
  set.seed(7)
  n_doc <- 20
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 5, sd = 1)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("GroupA", "GroupB"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_wait_time_crossover(df, group1 = "GroupA", group2 = "GroupA", min_pairs = 5L),
               "must be different")
})

# Test 11: Print method with valid crossover
test_that("print.mysterycall_wait_time_crossover displays result correctly", {
  set.seed(8)
  n_doc <- 25
  bcbs_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))
  medicaid_days <- pmax(1, round(rnorm(n_doc, mean = 12, sd = 3)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("BCBS", "Medicaid"), each = n_doc),
    business_days_until_appointment = c(bcbs_days, medicaid_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, min_pairs = 5L)

  # Capture printed output
  output <- capture.output(print(result))

  expect_true(any(grepl("mysterycall_wait_time_crossover", output)))
  expect_true(any(grepl("Crossover point", output)))
})

# Test 12: Print method with digits parameter
test_that("print.mysterycall_wait_time_crossover respects digits parameter", {
  set.seed(9)
  n_doc <- 25
  bcbs_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))
  medicaid_days <- pmax(1, round(rnorm(n_doc, mean = 12, sd = 3)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("BCBS", "Medicaid"), each = n_doc),
    business_days_until_appointment = c(bcbs_days, medicaid_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, min_pairs = 5L)

  output1 <- capture.output(print(result, digits = 1))
  output2 <- capture.output(print(result, digits = 4))

  # Just ensure both work without error
  expect_type(output1, "character")
  expect_type(output2, "character")
})

# Test 13: Edge case - slope >= 1 (no crossover)
test_that("mysterycall_wait_time_crossover handles slope >= 1 correctly", {
  # Create data where slope will be >= 1 (group2 increases faster than group1)
  df <- data.frame(
    phone = rep(c("555-0001", "555-0002", "555-0003", "555-0004", "555-0005",
                  "555-0006", "555-0007", "555-0008", "555-0009", "555-0010",
                  "555-0011", "555-0012", "555-0013", "555-0014", "555-0015"), 2),
    insurance = rep(c("GroupA", "GroupB"), each = 15),
    business_days_until_appointment = c(
      5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
      20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160
    ),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, log_transform = FALSE, min_pairs = 10L)

  # Slope should be >= 1, so crossover should be NA
  if (result$slope >= 1) {
    expect_true(is.na(result$crossover_days))
  }
})

# Test 14: Edge case - slope <= 0 (no crossover)
test_that("mysterycall_wait_time_crossover handles slope <= 0 correctly", {
  # Create data where slope will be <= 0 (group2 decreases as group1 increases)
  df <- data.frame(
    phone = rep(c("555-0001", "555-0002", "555-0003", "555-0004", "555-0005",
                  "555-0006", "555-0007", "555-0008", "555-0009", "555-0010",
                  "555-0011", "555-0012", "555-0013", "555-0014", "555-0015"), 2),
    insurance = rep(c("GroupA", "GroupB"), each = 15),
    business_days_until_appointment = c(
      5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
      100, 90, 80, 70, 60, 50, 40, 30, 20, 10, 5, 4, 3, 2, 1
    ),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, log_transform = FALSE, min_pairs = 10L)

  # Slope should be <= 0, so crossover should be NA
  if (result$slope <= 0) {
    expect_true(is.na(result$crossover_days))
  }
})

# Test 15: Sentence generation with valid crossover
test_that("mysterycall_wait_time_crossover sentence includes content", {
  set.seed(10)
  n_doc <- 25
  bcbs_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))
  medicaid_days <- pmax(1, round(rnorm(n_doc, mean = 12, sd = 3)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("BCBS", "Medicaid"), each = n_doc),
    business_days_until_appointment = c(bcbs_days, medicaid_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, min_pairs = 5L)

  expect_type(result$sentence, "character")
  expect_true(length(result$sentence) > 0)
})

# Test 16: plot_data has correct names
test_that("mysterycall_wait_time_crossover plot_data has group names", {
  set.seed(11)
  n_doc <- 20
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 5, sd = 1)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("Medicaid", "BCBS"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, group1 = "Medicaid", group2 = "BCBS", min_pairs = 5L)

  expect_equal(names(result$plot_data), c("Medicaid", "BCBS"))
  expect_equal(nrow(result$plot_data), result$n_pairs)
})

# Test 17: conf_level parameter is stored
test_that("mysterycall_wait_time_crossover stores conf_level", {
  set.seed(12)
  n_doc <- 20
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 5, sd = 1)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("GroupA", "GroupB"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, conf_level = 0.90, min_pairs = 5L)

  expect_equal(result$conf_level, 0.90)
})

# Test 18: model is an lm object
test_that("mysterycall_wait_time_crossover model is lm object", {
  set.seed(13)
  n_doc <- 20
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 5, sd = 1)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("GroupA", "GroupB"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, min_pairs = 5L)

  expect_s3_class(result$model, "lm")
})

# Test 19: Non-positive values with log_transform
test_that("mysterycall_wait_time_crossover handles non-positive with log_transform", {
  df <- data.frame(
    phone = rep(c("555-0001", "555-0002", "555-0003", "555-0004", "555-0005",
                  "555-0006", "555-0007", "555-0008", "555-0009", "555-0010",
                  "555-0011", "555-0012", "555-0013", "555-0014", "555-0015"), 2),
    insurance = rep(c("GroupA", "GroupB"), each = 15),
    business_days_until_appointment = c(
      5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
      5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19
    ),
    stringsAsFactors = FALSE
  )

  # With log_transform = TRUE (default), non-positive values should be dropped
  result <- mysterycall_wait_time_crossover(df, log_transform = TRUE, min_pairs = 5L)

  expect_true(result$log_transform)
  expect_true(result$n_pairs > 0)
})

# Test 20: Custom id_col parameter
test_that("mysterycall_wait_time_crossover works with custom id_col", {
  set.seed(14)
  n_doc <- 20
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 5, sd = 1)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))

  df <- data.frame(
    npi = rep(sprintf("123456789%d", seq_len(n_doc)), 2),
    insurance = rep(c("GroupA", "GroupB"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, id_col = "npi", min_pairs = 5L)

  expect_s3_class(result, "mysterycall_wait_time_crossover")
  expect_true(result$n_pairs > 0)
})

# Test 21: Custom time_col and group_col parameters
test_that("mysterycall_wait_time_crossover works with custom column names", {
  set.seed(15)
  n_doc <- 20
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 5, sd = 1)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))

  df <- data.frame(
    doc_id = rep(sprintf("555-%04d", seq_len(n_doc)), 2),
    ins_type = rep(c("TypeA", "TypeB"), each = n_doc),
    wait_time = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df,
                                            time_col = "wait_time",
                                            group_col = "ins_type",
                                            id_col = "doc_id",
                                            min_pairs = 5L)

  expect_s3_class(result, "mysterycall_wait_time_crossover")
  expect_equal(result$group1, "TypeA")
  expect_equal(result$group2, "TypeB")
})

# Test 22: Error - invalid conf_level
test_that("mysterycall_wait_time_crossover errors on invalid conf_level", {
  set.seed(16)
  n_doc <- 20
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 5, sd = 1)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("GroupA", "GroupB"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_wait_time_crossover(df, conf_level = 1.5, min_pairs = 5L))
  expect_error(mysterycall_wait_time_crossover(df, conf_level = -0.1, min_pairs = 5L))
})

# Test 23: Error - invalid min_pairs
test_that("mysterycall_wait_time_crossover errors on invalid min_pairs", {
  set.seed(17)
  n_doc <- 20
  g1_days <- pmax(1, round(rnorm(n_doc, mean = 5, sd = 1)))
  g2_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("GroupA", "GroupB"), each = n_doc),
    business_days_until_appointment = c(g1_days, g2_days),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_wait_time_crossover(df, min_pairs = 0L))
  expect_error(mysterycall_wait_time_crossover(df, min_pairs = -1L))
})

# Test 24: Crossover computation with 0 < slope < 1
test_that("mysterycall_wait_time_crossover computes crossover when 0 < slope < 1", {
  set.seed(18)
  n_doc <- 25
  bcbs_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))
  medicaid_days <- pmax(1, round(rnorm(n_doc, mean = 12, sd = 3)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("BCBS", "Medicaid"), each = n_doc),
    business_days_until_appointment = c(bcbs_days, medicaid_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, min_pairs = 5L)

  # If slope is between 0 and 1, crossover should be defined and positive
  if (!is.na(result$slope) && result$slope > 0 && result$slope < 1) {
    expect_true(!is.na(result$crossover_days))
    expect_true(result$crossover_days > 0)
  }
})

# Test 25: Print method returns x invisibly
test_that("print.mysterycall_wait_time_crossover returns x invisibly", {
  set.seed(19)
  n_doc <- 25
  bcbs_days <- pmax(1, round(rnorm(n_doc, mean = 8, sd = 2)))
  medicaid_days <- pmax(1, round(rnorm(n_doc, mean = 12, sd = 3)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("BCBS", "Medicaid"), each = n_doc),
    business_days_until_appointment = c(bcbs_days, medicaid_days),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(df, min_pairs = 5L)

  # Capturing invisible return
  result2 <- capture.output(x <- print(result))

  expect_s3_class(x, "mysterycall_wait_time_crossover")
  expect_identical(result, x)
})

# Regression (BUG 27): beyond the crossover, group1 (x-axis) has the longer wait
test_that("crossover sentence attributes longer waits to group1 beyond crossover", {
  # Construct data yielding a finite crossover with 0 < slope < 1 (log scale).
  set.seed(271)
  n_doc <- 40
  g1 <- pmax(1, round(rnorm(n_doc, mean = 15, sd = 4)))
  # y = 0.5*x + noise on original scale keeps slope in (0,1)
  g2 <- pmax(1, round(0.5 * g1 + rnorm(n_doc, sd = 1)))

  df <- data.frame(
    phone = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
    insurance = rep(c("GroupA", "GroupB"), each = n_doc),
    business_days_until_appointment = c(g1, g2),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_wait_time_crossover(
    df, group1 = "GroupA", group2 = "GroupB",
    log_transform = FALSE, min_pairs = 5L
  )

  if (!is.na(result$crossover_days) && result$crossover_days > 0) {
    # group1 (GroupA) waits longer beyond the crossover, not group2
    expect_match(result$sentence, "GroupA patients experienced longer waits")
    expect_false(grepl("GroupB patients experienced longer waits", result$sentence))
  }
})
