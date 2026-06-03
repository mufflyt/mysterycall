# Tests for mysterycall_check_dependencies

test_that("check_dependencies: returns a data frame with required columns", {
  res <- mysterycall_check_dependencies("stats", quietly = TRUE)
  expect_s3_class(res, "data.frame")
  expect_true(all(c("package", "installed", "version", "install_command") %in% names(res)))
  expect_equal(nrow(res), 1L)
})

test_that("check_dependencies: detects installed package", {
  res <- mysterycall_check_dependencies("stats", quietly = TRUE)
  expect_true(res$installed[[1L]])
  expect_false(is.na(res$version[[1L]]))
})

test_that("check_dependencies: detects missing package", {
  res <- suppressMessages(
    mysterycall_check_dependencies("nonexistent_package_xyz_123", quietly = TRUE)
  )
  expect_false(res$installed[[1L]])
  expect_true(is.na(res$version[[1L]]))
})

test_that("check_dependencies: install_command is shell-runnable string", {
  res <- mysterycall_check_dependencies("stats", quietly = TRUE)
  expect_match(res$install_command[[1L]], "install\\.packages")
  expect_match(res$install_command[[1L]], "stats")
})

test_that("check_dependencies: emits message for missing packages when not quiet", {
  expect_message(
    mysterycall_check_dependencies("nonexistent_package_xyz_123", quietly = FALSE),
    "Missing"
  )
})

test_that("check_dependencies: dedupes input", {
  res <- mysterycall_check_dependencies(c("stats", "stats", "utils"), quietly = TRUE)
  expect_equal(nrow(res), 2L)
})

test_that("check_dependencies: drops empty strings", {
  res <- mysterycall_check_dependencies(c("stats", ""), quietly = TRUE)
  expect_equal(nrow(res), 1L)
})

test_that("check_dependencies: errors on non-character input", {
  expect_error(mysterycall_check_dependencies(123), "character vector")
})

test_that("check_dependencies: errors on empty input", {
  expect_error(mysterycall_check_dependencies(character(0)), "No packages")
})

test_that("check_dependencies: errors on all-empty-string input", {
  expect_error(mysterycall_check_dependencies(c("", "")), "No packages")
})

test_that("check_dependencies: handles vector of multiple installed packages", {
  res <- mysterycall_check_dependencies(c("stats", "utils", "tools"), quietly = TRUE)
  expect_equal(nrow(res), 3L)
  expect_true(all(res$installed))
})
