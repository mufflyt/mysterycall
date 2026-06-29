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
# mysterycall_check_generalist_presence tests
# ============================================================================

test_that("check_generalist_presence returns correct structure with valid inputs (happy path)", {
  df <- data.frame(
    city      = c("Denver","Denver","Denver","Austin","Austin"),
    state     = c("CO","CO","CO","TX","TX"),
    specialty = c("General","Neurotology","Pediatric","Neurotology","General"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_check_generalist_presence(df, c("city","state"), "specialty", "General")
  )

  # Check return type and structure
  expect_s3_class(result, "data.frame")
  expect_named(result, c("location", "n_subspecialists", "n_generalists", "generalist_needed"))
  expect_type(result$location, "character")
  expect_type(result$n_subspecialists, "integer")
  expect_type(result$n_generalists, "integer")
  expect_type(result$generalist_needed, "logical")

  # Check content: Denver has 2 subspecialists and 1 generalist
  # (location is normalized to lowercase with ", " separator)
  expect_true("denver, co" %in% result$location)
  denver_row <- result[result$location == "denver, co", ]
  expect_equal(denver_row$n_subspecialists, 2L)
  expect_equal(denver_row$n_generalists, 1L)
  expect_false(denver_row$generalist_needed)
})

test_that("check_generalist_presence flags locations missing generalists", {
  df <- data.frame(
    city      = c("Denver","Denver","Austin","Austin"),
    state     = c("CO","CO","TX","TX"),
    specialty = c("Neurotology","Pediatric","Otology","Laryngology"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_check_generalist_presence(df, c("city","state"), "specialty", "General")
  )

  # Both locations should be flagged as needing generalists
  expect_equal(nrow(result), 2L)
  expect_true(all(result$generalist_needed))

  # Check counts
  expect_equal(result$n_generalists, c(0L, 0L))
  expect_equal(result$n_subspecialists, c(2L, 2L))
})

test_that("check_generalist_presence returns empty dataframe when no subspecialists exist", {
  df <- data.frame(
    city      = c("Denver","Denver","Austin"),
    state     = c("CO","CO","TX"),
    specialty = c("General","General","General"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_check_generalist_presence(df, c("city","state"), "specialty", "General")
  )

  # No subspecialists, so should return empty df with correct structure
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_named(result, c("location", "n_subspecialists", "n_generalists", "generalist_needed"))
})

test_that("check_generalist_presence normalizes location columns to lowercase", {
  df <- data.frame(
    city      = c("DENVER","Denver","denver"),
    state     = c("CO","CO","CO"),
    specialty = c("Neurotology","Pediatric","Otology"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_check_generalist_presence(df, c("city","state"), "specialty", "General")
  )

  # All three should be treated as the same location (case-insensitive)
  expect_equal(nrow(result), 1L)
  expect_equal(result$location, "denver, co")
  expect_equal(result$n_subspecialists, 3L)
})

test_that("check_generalist_presence handles zero-row input correctly", {
  df <- data.frame(
    city      = character(0),
    state     = character(0),
    specialty = character(0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_check_generalist_presence(df, c("city","state"), "specialty", "General")
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_named(result, c("location", "n_subspecialists", "n_generalists", "generalist_needed"))
})

test_that("check_generalist_presence stops when data is not a data frame", {
  expect_error(
    mysterycall_check_generalist_presence(
      list(city = "Denver"), c("city", "state"), "specialty", "General"
    ),
    "must be a data frame"
  )

  expect_error(
    mysterycall_check_generalist_presence(
      c("a", "b", "c"), c("city", "state"), "specialty", "General"
    ),
    "must be a data frame"
  )
})

test_that("check_generalist_presence stops when required columns are missing", {
  df <- data.frame(
    city      = c("Denver","Austin"),
    specialty = c("General","Neurotology"),
    stringsAsFactors = FALSE
  )

  # Missing 'state' column
  expect_error(
    mysterycall_check_generalist_presence(df, c("city","state"), "specialty", "General"),
    "Columns not found in"
  )

  # Missing 'specialty' column
  expect_error(
    mysterycall_check_generalist_presence(df, c("city"), "specialty_type", "General"),
    "Columns not found in"
  )
})

test_that("check_generalist_presence handles NA values in specialty column", {
  df <- data.frame(
    city      = c("Denver","Denver","Denver","Austin"),
    state     = c("CO","CO","CO","TX"),
    specialty = c("General","Neurotology",NA,"General"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_check_generalist_presence(df, c("city","state"), "specialty", "General")
  )

  # Denver has 1 subspecialist (NA is neither specialist nor generalist)
  expect_equal(nrow(result), 1L)
  expect_equal(result$location, "denver, co")
  expect_equal(result$n_subspecialists, 1L)
  expect_equal(result$n_generalists, 1L)
})

test_that("check_generalist_presence orders results by generalist_needed descending", {
  df <- data.frame(
    city      = c("Denver","Denver","Austin","Austin","Boston"),
    state     = c("CO","CO","TX","TX","MA"),
    specialty = c("Neurotology","Pediatric","General","Otology","General"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_check_generalist_presence(df, c("city","state"), "specialty", "General")
  )

  # Denver (needs generalist) should come before Austin (has generalist)
  expect_true(result$generalist_needed[1])
  expect_false(result$generalist_needed[2])

  # Verify the ordering
  expect_equal(sum(result$generalist_needed), 1L)
})

test_that("check_generalist_presence handles single location column", {
  df <- data.frame(
    city      = c("Denver","Denver","Austin","Austin"),
    specialty = c("Neurotology","Pediatric","Otology","Laryngology"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_check_generalist_presence(df, "city", "specialty", "General")
  )

  expect_equal(nrow(result), 2L)
  expect_true(all(result$generalist_needed))
  expect_true(all(result$location %in% c("denver", "austin")))
})
