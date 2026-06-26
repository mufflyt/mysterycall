# test-mysterycall:::mysterycall_remove_constants-invariants.R
#
# Tests mysterycall:::mysterycall_remove_constants() against invariants, gold-standard cases,
# boundary conditions, and metamorphic properties.
#
# Testing tenets satisfied:
#   - Gold-standard manually-verified values (exact column preservation)
#   - Enforce domain invariants (no varying column ever removed)
#   - Idempotency (calling twice gives same result)
#   - Boundary conditions (all constant, no constant)
#   - Metamorphic relations (adding constant column and removing gives original)
#   - Silent failure detection (all-NA column treated as constant)
#   - Property-based: 50 random data frames, invariant never broken

library(testthat)

# ---------------------------------------------------------------------------
# Helper: suppress the messages from mysterycall:::mysterycall_remove_constants
# ---------------------------------------------------------------------------
quiet_rcv <- function(df) suppressMessages(mysterycall:::mysterycall_remove_constants(df))

# ---------------------------------------------------------------------------
# 1. Gold standard: exact column preservation
# ---------------------------------------------------------------------------

test_that("mysterycall:::mysterycall_remove_constants removes exactly the constant column and keeps varying columns", {
  df <- data.frame(
    varying1  = c(1, 2, 3),
    constant  = c(5, 5, 5),
    varying2  = c("a", "b", "c"),
    stringsAsFactors = FALSE
  )
  result <- quiet_rcv(df)
  expect_equal(sort(names(result)), sort(c("varying1", "varying2")))
  expect_equal(ncol(result), 2L)
})

test_that("mysterycall:::mysterycall_remove_constants preserves exact column names of varying columns", {
  df <- data.frame(
    alpha   = 1:5,
    bravo   = rep("x", 5),
    charlie = c(10, 20, 30, 40, 50),
    stringsAsFactors = FALSE
  )
  result <- quiet_rcv(df)
  expect_setequal(names(result), c("alpha", "charlie"))
})

# ---------------------------------------------------------------------------
# 2. Invariant: no non-constant column ever removed (property test, 50 DFs)
# ---------------------------------------------------------------------------

test_that("no varying column is ever removed across 50 random data frames", {
  set.seed(2024)
  for (i in seq_len(50)) {
    n_rows    <- sample(3:20, 1)
    n_vary    <- sample(1:5, 1)
    n_const   <- sample(0:3, 1)

    vary_list  <- lapply(seq_len(n_vary),  function(j) sample(1:100, n_rows, replace = FALSE)[1:n_rows])
    const_list <- lapply(seq_len(n_const), function(j) rep(sample(1:10, 1), n_rows))

    all_cols <- c(vary_list, const_list)
    col_names <- paste0("col", seq_along(all_cols))
    df <- as.data.frame(setNames(all_cols, col_names))

    varying_names  <- col_names[seq_len(n_vary)]
    result <- quiet_rcv(df)

    missing_varying <- setdiff(varying_names, names(result))
    expect_equal(length(missing_varying), 0L,
                 label = paste("Iteration", i, ": varying column(s) removed:", paste(missing_varying, collapse = ", ")))
  }
})

# ---------------------------------------------------------------------------
# 3. Invariant: output ncol <= input ncol always
# ---------------------------------------------------------------------------

test_that("output ncol is always <= input ncol", {
  set.seed(7)
  for (i in seq_len(20)) {
    n <- sample(2:10, 1)
    df <- as.data.frame(replicate(n, sample(c(1, 1, 2), 5, replace = TRUE)))
    result <- quiet_rcv(df)
    expect_lte(ncol(result), ncol(df),
               label = paste("Iteration", i))
  }
})

# ---------------------------------------------------------------------------
# 4. Invariant: output nrow always equals input nrow
# ---------------------------------------------------------------------------

test_that("output nrow always equals input nrow", {
  df <- data.frame(a = 1:10, b = rep(0, 10), c = 1:10)
  result <- quiet_rcv(df)
  expect_equal(nrow(result), nrow(df))
})

test_that("output nrow equals input nrow for various sizes", {
  set.seed(3)
  for (n in c(1, 2, 5, 20, 100)) {
    df <- data.frame(x = seq_len(n), constant = rep(42, n))
    result <- quiet_rcv(df)
    expect_equal(nrow(result), n,
                 label = paste("nrow check for n =", n))
  }
})

# ---------------------------------------------------------------------------
# 5. Idempotency: mysterycall:::mysterycall_remove_constants(mysterycall:::mysterycall_remove_constants(df)) == mysterycall:::mysterycall_remove_constants(df)
# ---------------------------------------------------------------------------

test_that("mysterycall:::mysterycall_remove_constants is idempotent", {
  df <- data.frame(
    varying  = 1:5,
    constant = rep("z", 5),
    varying2 = c(10, 20, 30, 40, 50),
    stringsAsFactors = FALSE
  )
  once  <- quiet_rcv(df)
  twice <- quiet_rcv(once)
  expect_equal(once, twice)
})

test_that("idempotency holds when all columns vary", {
  df <- data.frame(a = 1:5, b = 6:10, c = 11:15)
  once  <- quiet_rcv(df)
  twice <- quiet_rcv(once)
  expect_equal(once, twice)
})

# ---------------------------------------------------------------------------
# 6. Domain constraint: all-NA column treated as constant (only 1 unique value: NA)
# ---------------------------------------------------------------------------

test_that("all-NA column is treated as constant and removed", {
  df <- data.frame(
    varying = 1:4,
    all_na  = c(NA_real_, NA_real_, NA_real_, NA_real_)
  )
  result <- quiet_rcv(df)
  expect_false("all_na" %in% names(result),
               label = "all-NA column should be removed as constant")
  expect_true("varying" %in% names(result))
})

# ---------------------------------------------------------------------------
# 7. Boundary: all columns constant → 0 columns, same number of rows
# ---------------------------------------------------------------------------

test_that("all-constant data frame returns 0-column result with same row count", {
  df <- data.frame(a = rep(1, 3), b = rep("x", 3), c = rep(TRUE, 3),
                   stringsAsFactors = FALSE)
  result <- quiet_rcv(df)
  expect_equal(ncol(result), 0L)
  expect_equal(nrow(result), nrow(df))
})

# ---------------------------------------------------------------------------
# 8. Boundary: no columns constant → output identical to input
# ---------------------------------------------------------------------------

test_that("data frame with no constant columns is returned unchanged", {
  df <- data.frame(a = 1:5, b = 6:10, c = c("p", "q", "r", "s", "t"),
                   stringsAsFactors = FALSE)
  result <- quiet_rcv(df)
  expect_equal(result, df)
})

# ---------------------------------------------------------------------------
# 9. Metamorphic: adding constant column and removing gives original ncol - 1
# ---------------------------------------------------------------------------

test_that("adding a constant column and removing it yields ncol == original ncol", {
  df_original <- data.frame(a = 1:5, b = 6:10)
  df_augmented <- cbind(df_original, new_const = rep(99, 5))

  result <- quiet_rcv(df_augmented)

  # Original had 2 cols; augmented had 3; result should have 2 (constant removed)
  expect_equal(ncol(result), ncol(df_original))
  expect_setequal(names(result), names(df_original))
})

# ---------------------------------------------------------------------------
# 10. Single-row edge case: every column of a single row is technically "constant"
# ---------------------------------------------------------------------------

test_that("single-row data frame: all columns treated as constant, 0 columns remain", {
  df <- data.frame(a = 5, b = "hello", c = TRUE, stringsAsFactors = FALSE)
  result <- quiet_rcv(df)
  # With 1 row, every column has exactly 1 unique value → all are constant
  expect_equal(ncol(result), 0L)
  expect_equal(nrow(result), 1L)
})
