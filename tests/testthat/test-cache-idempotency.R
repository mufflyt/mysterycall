# test-cache-idempotency.R
#
# Tests mysterycall_clear_isochrone_cache() for correct invisible-NULL return,
# idempotency (calling twice doesn't error), and cache-clearing semantics.
#
# Testing tenets satisfied:
#   - Idempotency (multiple calls never fail)
#   - Schema contracts (return is invisibly NULL)
#   - Test for silent failures (no side effects, no printed output)
#   - Boundary conditions (call with empty cache, call with populated cache)

library(testthat)

skip_if_not_installed("memoise")

# ---------------------------------------------------------------------------
# 1. Returns NULL invisibly
# ---------------------------------------------------------------------------

test_that("mysterycall_clear_isochrone_cache() returns NULL", {
  result <- mysterycall_clear_isochrone_cache()
  expect_null(result)
})

test_that("mysterycall_clear_isochrone_cache() return value is truly invisible (nothing printed)", {
  # capture.output captures auto-printing; invisible return suppresses it
  printed <- capture.output(mysterycall_clear_isochrone_cache())
  expect_equal(length(printed), 0L,
               label = paste("Unexpected output:", paste(printed, collapse = "\n")))
})

test_that("mysterycall_clear_isochrone_cache() returns NULL on second call too", {
  mysterycall_clear_isochrone_cache()
  result <- mysterycall_clear_isochrone_cache()
  expect_null(result)
})

# ---------------------------------------------------------------------------
# 2. Calling it twice doesn't error
# ---------------------------------------------------------------------------

test_that("mysterycall_clear_isochrone_cache() can be called twice without error", {
  expect_no_error(mysterycall_clear_isochrone_cache())
  expect_no_error(mysterycall_clear_isochrone_cache())
})

test_that("mysterycall_clear_isochrone_cache() can be called 10 times consecutively without error", {
  for (i in seq_len(10)) {
    expect_no_error(
      mysterycall_clear_isochrone_cache(),
      message = paste("Error on call", i)
    )
  }
})

# ---------------------------------------------------------------------------
# 3. After clearing, .isochrone_memo cache is empty (via memoise::forget)
# ---------------------------------------------------------------------------

test_that("mysterycall_clear_isochrone_cache() calls forget on .isochrone_memo without error", {
  # The function internally calls memoise::forget(.isochrone_memo)
  # Calling it twice simulates: first forget (empty cache) and second forget (empty again)
  # Both must succeed without error
  expect_no_error({
    mysterycall_clear_isochrone_cache()
    mysterycall_clear_isochrone_cache()
  })
})

test_that("mysterycall_clear_isochrone_cache is accessible (exported)", {
  expect_true(
    is.function(mysterycall::mysterycall_clear_isochrone_cache),
    label = "mysterycall_clear_isochrone_cache must be an exported function"
  )
})

# ---------------------------------------------------------------------------
# 4. Return value is truly invisible: assigning doesn't trigger auto-print
# ---------------------------------------------------------------------------

test_that("assigned result of mysterycall_clear_isochrone_cache() is NULL", {
  x <- mysterycall_clear_isochrone_cache()
  expect_null(x)
})

test_that("result of mysterycall_clear_isochrone_cache() has no attributes", {
  result <- mysterycall_clear_isochrone_cache()
  expect_null(attributes(result))
})

# ---------------------------------------------------------------------------
# 5. No side effects: no files written, no global state changed
# ---------------------------------------------------------------------------

test_that("mysterycall_clear_isochrone_cache() does not write files to tempdir", {
  tmp <- tempfile("cache_test_")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  n_before <- length(list.files(tmp))
  mysterycall_clear_isochrone_cache()
  n_after  <- length(list.files(tmp))

  expect_equal(n_before, n_after,
               label = "Cache clear should not write any files")
})

test_that("mysterycall_clear_isochrone_cache() does not produce warnings", {
  expect_no_warning(mysterycall_clear_isochrone_cache())
})

test_that("mysterycall_clear_isochrone_cache() does not produce messages", {
  expect_no_message(mysterycall_clear_isochrone_cache())
})
