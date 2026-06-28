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

# Test 1: Happy path with installed packages
test_that("mysterycall_check_dependencies returns tibble for installed packages", {
  result <- suppressMessages(mysterycall_check_dependencies(c("base", "utils")))
  expect_s3_class(result, "tbl_df")
  expect_named(result, c("package", "installed", "version", "install_command"))
  expect_equal(nrow(result), 2)
  expect_true(all(result$installed))
  expect_true(all(nzchar(result$version)))
})

# Test 2: Edge case with non-installed package identification
test_that("mysterycall_check_dependencies identifies missing packages", {
  result <- suppressMessages(mysterycall_check_dependencies(
    c("base", "nonexistent_package_xyz123")
  ))
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(result$installed[1])
  expect_false(result$installed[2])
  expect_true(is.na(result$version[2]))
})

# Test 3: Edge case with empty strings filtered out
test_that("mysterycall_check_dependencies filters empty strings", {
  result <- suppressMessages(mysterycall_check_dependencies(c("base", "", "utils")))
  expect_equal(nrow(result), 2)
  expect_equal(result$package, c("base", "utils"))
})

# Test 4: Edge case with duplicates removed
test_that("mysterycall_check_dependencies removes duplicates", {
  result <- suppressMessages(mysterycall_check_dependencies(c("base", "base", "utils", "utils")))
  expect_equal(nrow(result), 2)
  expect_equal(result$package, c("base", "utils"))
})

# Test 5: Bad input - non-character vector (numeric)
test_that("mysterycall_check_dependencies errors on numeric input", {
  expect_error(
    mysterycall_check_dependencies(c(1, 2, 3)),
    "must be a character vector"
  )
})

# Test 6: Bad input - non-character vector (logical)
test_that("mysterycall_check_dependencies errors on logical input", {
  expect_error(
    mysterycall_check_dependencies(c(TRUE, FALSE)),
    "must be a character vector"
  )
})

# Test 7: Bad input - all empty strings
test_that("mysterycall_check_dependencies errors when all packages are empty", {
  expect_error(
    mysterycall_check_dependencies(c("", "")),
    "No packages supplied"
  )
})

# Test 8: quietly parameter suppresses messages
test_that("mysterycall_check_dependencies respects quietly=TRUE", {
  expect_silent(
    mysterycall_check_dependencies(
      c("base", "nonexistent_xyz_pkg_missing"),
      quietly = TRUE
    )
  )
})

# Test 9: quietly=FALSE produces messages for missing packages
test_that("mysterycall_check_dependencies messages with quietly=FALSE", {
  expect_message(
    mysterycall_check_dependencies(
      c("base", "nonexistent_xyz_pkg_missing"),
      quietly = FALSE
    ),
    "Missing"
  )
})

# Test 10: Single package input (installed)
test_that("mysterycall_check_dependencies handles single installed package", {
  result <- suppressMessages(mysterycall_check_dependencies("base"))
  expect_equal(nrow(result), 1)
  expect_equal(result$package, "base")
  expect_true(result$installed)
  expect_false(is.na(result$version))
})

# Test 11: install_command format is correct
test_that("mysterycall_check_dependencies generates correct install command", {
  result <- suppressMessages(mysterycall_check_dependencies("base"))
  expect_match(result$install_command, 'install\\.packages\\("base"\\)')
})

# Test 12: install_command includes missing package names
test_that("mysterycall_check_dependencies install command for missing pkg", {
  result <- suppressMessages(mysterycall_check_dependencies("nonexistent_pkg_xyz"))
  expect_match(result$install_command, 'install\\.packages\\("nonexistent_pkg_xyz"\\)')
})

# Test 13: install parameter with install=FALSE (default behavior)
test_that("mysterycall_check_dependencies install=FALSE does not attempt install", {
  result <- suppressMessages(mysterycall_check_dependencies(
    c("base", "nonexistent_test_pkg"),
    install = FALSE
  ))
  expect_false(result$installed[2])
})

# Test 14: Return structure has all expected columns
test_that("mysterycall_check_dependencies result structure is correct", {
  result <- suppressMessages(mysterycall_check_dependencies("base"))
  expect_true(is.character(result$package))
  expect_true(is.logical(result$installed))
  expect_true(is.character(result$version) || all(is.na(result$version)))
  expect_true(is.character(result$install_command))
})

# Test 15: Multiple installed packages
test_that("mysterycall_check_dependencies handles multiple installed packages", {
  result <- suppressMessages(mysterycall_check_dependencies(c("base", "utils", "stats")))
  expect_equal(nrow(result), 3)
  expect_true(all(result$installed))
})
