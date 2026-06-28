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

# ==============================================================================
# mysterycall_assert_unique_keys
# ==============================================================================

test_that("assert_unique_keys: happy path with unique keys", {
  df <- data.frame(
    npi = c("A", "B", "C"),
    value = c(1L, 2L, 3L),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_assert_unique_keys(df, "npi"))
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 3L)
  expect_equal(names(result), c("npi", "value"))
})

test_that("assert_unique_keys: returns invisibly", {
  df <- data.frame(npi = c("A", "B"), stringsAsFactors = FALSE)
  result <- mysterycall_assert_unique_keys(df, "npi")
  expect_identical(result, df)
})

test_that("assert_unique_keys: dedupe=TRUE silently removes duplicates", {
  df <- data.frame(
    npi = c("A", "B", "A", "C"),
    value = c(1L, 2L, 3L, 4L),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_assert_unique_keys(df, "npi", dedupe = TRUE))
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 3L)
  expect_equal(result$npi, c("A", "B", "C"))
  expect_equal(result$value, c(1L, 2L, 4L))
})

test_that("assert_unique_keys: dedupe=FALSE errors on duplicates", {
  df <- data.frame(
    npi = c("A", "B", "A"),
    value = c(1L, 2L, 3L),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_assert_unique_keys(df, "npi", dedupe = FALSE),
    "expected unique key"
  )
})

test_that("assert_unique_keys: composite keys", {
  df <- data.frame(
    npi = c("A", "A", "B"),
    wave = c(1L, 2L, 1L),
    value = c(1L, 2L, 3L),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_assert_unique_keys(df, c("npi", "wave")))
  expect_equal(nrow(result), 3L)
})

test_that("assert_unique_keys: error on missing key column", {
  df <- data.frame(npi = c("A", "B"), stringsAsFactors = FALSE)
  expect_error(
    mysterycall_assert_unique_keys(df, "missing_col"),
    "Key column(s) not found"
  )
})

test_that("assert_unique_keys: error when .data is not a data frame", {
  expect_error(
    mysterycall_assert_unique_keys(list(a = 1), "a"),
    "must be a data frame"
  )
})

test_that("assert_unique_keys: error when key_cols is empty", {
  df <- data.frame(npi = c("A", "B"), stringsAsFactors = FALSE)
  expect_error(
    mysterycall_assert_unique_keys(df, character(0)),
    "non-empty character vector"
  )
})

test_that("assert_unique_keys: zero rows returns invisibly", {
  df <- data.frame(npi = character(0), stringsAsFactors = FALSE)
  result <- suppressMessages(mysterycall_assert_unique_keys(df, "npi"))
  expect_equal(nrow(result), 0L)
})

# ==============================================================================
# mysterycall_safe_left_join
# ==============================================================================

test_that("safe_left_join: happy path with high coverage", {
  left <- data.frame(
    npi = c("1", "2", "3"),
    val_left = c(10L, 20L, 30L),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1", "2", "3"),
    val_right = c(100L, 200L, 300L),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_safe_left_join(
      left, right, by = "npi",
      label_left = "left",
      label_right = "right",
      min_coverage = 0.98,
      write_report = FALSE
    )
  )
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 3L)
  expect_equal(ncol(result), 3L)
  expect_true("val_right" %in% names(result))
})

test_that("safe_left_join: partial coverage with lower threshold", {
  left <- data.frame(
    npi = c("1", "2", "3"),
    val_left = c(10L, 20L, 30L),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1", "2"),
    val_right = c(100L, 200L),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_safe_left_join(
      left, right, by = "npi",
      min_coverage = 0.50,
      write_report = FALSE
    )
  )
  expect_equal(nrow(result), 3L)
  expect_equal(sum(!is.na(result$val_right)), 2L)
})

test_that("safe_left_join: coverage below threshold raises error", {
  left <- data.frame(
    npi = c("1", "2", "3"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(
      mysterycall_safe_left_join(
        left, right, by = "npi",
        min_coverage = 0.50,
        write_report = FALSE
      )
    ),
    "coverage.*below.*threshold"
  )
})

test_that("safe_left_join: error on non-data.frame left", {
  expect_error(
    mysterycall_safe_left_join(
      list(a = 1), data.frame(a = 1),
      by = "a", write_report = FALSE
    ),
    "`left` must be a data frame"
  )
})

test_that("safe_left_join: error on non-data.frame right", {
  expect_error(
    mysterycall_safe_left_join(
      data.frame(a = 1), list(a = 1),
      by = "a", write_report = FALSE
    ),
    "`right` must be a data frame"
  )
})

test_that("safe_left_join: error when by is NULL", {
  expect_error(
    mysterycall_safe_left_join(
      data.frame(a = 1), data.frame(a = 1),
      by = NULL, write_report = FALSE
    ),
    "`by` is required"
  )
})

test_that("safe_left_join: error when by is empty character vector", {
  expect_error(
    mysterycall_safe_left_join(
      data.frame(a = 1), data.frame(a = 1),
      by = character(0), write_report = FALSE
    ),
    "`by` is required"
  )
})

test_that("safe_left_join: named by vector", {
  left <- data.frame(
    npi = c("1", "2"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    provider_id = c("1", "2"),
    specialty = c("OB", "GYN"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_safe_left_join(
      left, right, by = c("npi" = "provider_id"),
      min_coverage = 0.98,
      write_report = FALSE
    )
  )
  expect_equal(nrow(result), 2L)
  expect_true("specialty" %in% names(result))
})

test_that("safe_left_join: error on duplicate right keys", {
  left <- data.frame(npi = c("1", "2"), stringsAsFactors = FALSE)
  right <- data.frame(
    npi = c("1", "1", "2"),
    specialty = c("OB", "GYN", "RE"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(
      mysterycall_safe_left_join(
        left, right, by = "npi",
        expect_unique_right = TRUE,
        write_report = FALSE
      )
    ),
    "duplicate"
  )
})

test_that("safe_left_join: many-to-one allowed when expect_unique_right=TRUE", {
  left <- data.frame(
    npi = c("1", "1", "2"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1", "2"),
    specialty = c("OB", "GYN"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_safe_left_join(
      left, right, by = "npi",
      expect_unique_right = TRUE,
      min_coverage = 0.98,
      write_report = FALSE
    )
  )
  expect_equal(nrow(result), 3L)
})

test_that("safe_left_join: suffix handling", {
  left <- data.frame(
    npi = c("1", "2"),
    col = c("L1", "L2"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1", "2"),
    col = c("R1", "R2"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_safe_left_join(
      left, right, by = "npi",
      suffix = c("_left", "_right"),
      min_coverage = 0.98,
      write_report = FALSE
    )
  )
  expect_true("col_left" %in% names(result))
  expect_true("col_right" %in% names(result))
})

test_that("safe_left_join: zero rows in left", {
  left <- data.frame(npi = character(0), stringsAsFactors = FALSE)
  right <- data.frame(npi = c("1", "2"), stringsAsFactors = FALSE)
  result <- suppressMessages(
    mysterycall_safe_left_join(
      left, right, by = "npi",
      write_report = FALSE
    )
  )
  expect_equal(nrow(result), 0L)
})

# ==============================================================================
# mysterycall_safe_inner_join
# ==============================================================================

test_that("safe_inner_join: happy path", {
  left <- data.frame(
    npi = c("1", "2", "3"),
    val = c(10L, 20L, 30L),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1", "2"),
    specialty = c("OB", "GYN"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_safe_inner_join(
      left, right, by = "npi",
      label_left = "left",
      label_right = "right",
      min_coverage = 0.50,
      write_report = FALSE
    )
  )
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 2L)
  expect_true("specialty" %in% names(result))
})

test_that("safe_inner_join: error when coverage below threshold", {
  left <- data.frame(
    npi = c("1", "2", "3"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(
      mysterycall_safe_inner_join(
        left, right, by = "npi",
        min_coverage = 0.50,
        write_report = FALSE
      )
    ),
    "coverage.*below.*threshold"
  )
})

test_that("safe_inner_join: error on non-data.frame left", {
  expect_error(
    mysterycall_safe_inner_join(
      list(a = 1), data.frame(a = 1),
      by = "a", write_report = FALSE
    ),
    "`left` must be a data frame"
  )
})

test_that("safe_inner_join: error on non-data.frame right", {
  expect_error(
    mysterycall_safe_inner_join(
      data.frame(a = 1), list(a = 1),
      by = "a", write_report = FALSE
    ),
    "`right` must be a data frame"
  )
})

test_that("safe_inner_join: error when by is NULL", {
  expect_error(
    mysterycall_safe_inner_join(
      data.frame(a = 1), data.frame(a = 1),
      by = NULL, write_report = FALSE
    ),
    "`by` is required"
  )
})

test_that("safe_inner_join: expect_unique_both=TRUE checks both sides", {
  left <- data.frame(
    npi = c("1", "1", "2"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1", "2"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(
      mysterycall_safe_inner_join(
        left, right, by = "npi",
        expect_unique_both = TRUE,
        min_coverage = 0.50,
        write_report = FALSE
      )
    ),
    "duplicate"
  )
})

test_that("safe_inner_join: expect_unique_both=FALSE allows duplicates", {
  left <- data.frame(
    npi = c("1", "1", "2"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1", "2"),
    specialty = c("OB", "GYN"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_safe_inner_join(
        left, right, by = "npi",
        expect_unique_both = FALSE,
        min_coverage = 0.50,
        write_report = FALSE
      )
    )
  )
  expect_equal(nrow(result), 3L)
})

test_that("safe_inner_join: zero rows in left triggers warning", {
  left <- data.frame(npi = character(0), stringsAsFactors = FALSE)
  right <- data.frame(npi = c("1", "2"), stringsAsFactors = FALSE)
  result <- suppressWarnings(
    suppressMessages(
      mysterycall_safe_inner_join(
        left, right, by = "npi",
        write_report = FALSE
      )
    )
  )
  expect_equal(nrow(result), 0L)
})

# ==============================================================================
# mysterycall_safe_semi_join
# ==============================================================================

test_that("safe_semi_join: happy path filters to matches only", {
  left <- data.frame(
    npi = c("1", "2", "3", "4"),
    val = c(10L, 20L, 30L, 40L),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1", "3"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_safe_semi_join(
      left, right, by = "npi",
      label_left = "left",
      label_right = "right",
      min_coverage = 0.25,
      write_report = FALSE
    )
  )
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 2L)
  expect_equal(result$npi, c("1", "3"))
  expect_equal(names(result), names(left))
})

test_that("safe_semi_join: error when keep-rate below threshold", {
  left <- data.frame(
    npi = c("1", "2", "3", "4"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(
      mysterycall_safe_semi_join(
        left, right, by = "npi",
        min_coverage = 0.50,
        write_report = FALSE
      )
    ),
    "kept.*below"
  )
})

test_that("safe_semi_join: error on non-data.frame", {
  expect_error(
    mysterycall_safe_semi_join(
      list(a = 1), data.frame(a = 1),
      by = "a", write_report = FALSE
    ),
    "`left` must be a data frame"
  )
})

test_that("safe_semi_join: error when by is NULL", {
  expect_error(
    mysterycall_safe_semi_join(
      data.frame(a = 1), data.frame(a = 1),
      by = NULL, write_report = FALSE
    ),
    "`by` is required"
  )
})

test_that("safe_semi_join: no matches returns empty result", {
  left <- data.frame(
    npi = c("1", "2"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("99"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(
      mysterycall_safe_semi_join(
        left, right, by = "npi",
        min_coverage = 0.50,
        write_report = FALSE
      )
    ),
    "kept.*below"
  )
})

test_that("safe_semi_join: low min_coverage allows few matches", {
  left <- data.frame(
    npi = c("1", "2", "3"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_safe_semi_join(
      left, right, by = "npi",
      min_coverage = 0.10,
      write_report = FALSE
    )
  )
  expect_equal(nrow(result), 1L)
})

test_that("safe_semi_join: zero rows in left triggers warning", {
  left <- data.frame(npi = character(0), stringsAsFactors = FALSE)
  right <- data.frame(npi = c("1", "2"), stringsAsFactors = FALSE)
  result <- suppressWarnings(
    suppressMessages(
      mysterycall_safe_semi_join(
        left, right, by = "npi",
        write_report = FALSE
      )
    )
  )
  expect_equal(nrow(result), 0L)
})

# ==============================================================================
# mysterycall_safe_anti_join
# ==============================================================================

test_that("safe_anti_join: happy path returns unmatched rows", {
  left <- data.frame(
    npi = c("1", "2", "3", "4"),
    val = c(10L, 20L, 30L, 40L),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("2", "4"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_safe_anti_join(
      left, right, by = "npi",
      label_left = "left",
      label_right = "right",
      max_matched = 0.60,
      write_report = FALSE
    )
  )
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 2L)
  expect_equal(result$npi, c("1", "3"))
})

test_that("safe_anti_join: error when exclusion exceeds max_matched", {
  left <- data.frame(
    npi = c("1", "2", "3"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1", "2"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(
      mysterycall_safe_anti_join(
        left, right, by = "npi",
        max_matched = 0.40,
        write_report = FALSE
      )
    ),
    "exceeds max_matched"
  )
})

test_that("safe_anti_join: error on non-data.frame", {
  expect_error(
    mysterycall_safe_anti_join(
      list(a = 1), data.frame(a = 1),
      by = "a", write_report = FALSE
    ),
    "`left` must be a data frame"
  )
})

test_that("safe_anti_join: error when by is NULL", {
  expect_error(
    mysterycall_safe_anti_join(
      data.frame(a = 1), data.frame(a = 1),
      by = NULL, write_report = FALSE
    ),
    "`by` is required"
  )
})

test_that("safe_anti_join: max_matched=1.0 allows all exclusions", {
  left <- data.frame(
    npi = c("1", "2", "3"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1", "2", "3"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_safe_anti_join(
      left, right, by = "npi",
      max_matched = 1.0,
      write_report = FALSE
    )
  )
  expect_equal(nrow(result), 0L)
})

test_that("safe_anti_join: no exclusions within threshold", {
  left <- data.frame(
    npi = c("1", "2", "3"),
    stringsAsFactors = FALSE
  )
  right <- data.frame(
    npi = c("1"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_safe_anti_join(
      left, right, by = "npi",
      max_matched = 0.50,
      write_report = FALSE
    )
  )
  expect_equal(nrow(result), 2L)
  expect_equal(result$npi, c("2", "3"))
})

test_that("safe_anti_join: invalid max_matched raises error", {
  left <- data.frame(npi = c("1", "2"), stringsAsFactors = FALSE)
  right <- data.frame(npi = c("3"), stringsAsFactors = FALSE)
  expect_error(
    suppressMessages(
      mysterycall_safe_anti_join(
        left, right, by = "npi",
        max_matched = 1.5,
        write_report = FALSE
      )
    ),
    "must be a single number in \\[0, 1\\]"
  )
})

test_that("safe_anti_join: zero rows in left triggers warning", {
  left <- data.frame(npi = character(0), stringsAsFactors = FALSE)
  right <- data.frame(npi = c("1", "2"), stringsAsFactors = FALSE)
  result <- suppressWarnings(
    suppressMessages(
      mysterycall_safe_anti_join(
        left, right, by = "npi",
        write_report = FALSE
      )
    )
  )
  expect_equal(nrow(result), 0L)
})
