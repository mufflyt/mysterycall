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
# mysterycall_parse_physician_name()
# ============================================================================

test_that("mysterycall_parse_physician_name happy path: basic names", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name("John Smith")
  ))
  expect_s3_class(result, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(result), 1L)
  expect_named(result, c("first_name", "middle_name", "last_name", "suffix",
                         "title", "parse_confidence", "parse_warnings"))
  expect_equal(result$first_name[[1L]], "John")
  expect_equal(result$last_name[[1L]], "Smith")
  expect_equal(result$parse_confidence[[1L]], "high")
})

test_that("mysterycall_parse_physician_name happy path: complex formats", {
  names <- c(
    "Dr. John Michael Smith, MD, FACOG",
    "Maria de la Cruz",
    "Smith, John, Jr."
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(names)
  ))
  expect_equal(nrow(result), 3L)
  expect_equal(result$first_name[[1L]], "John")
  expect_equal(result$last_name[[1L]], "Smith")
  expect_equal(result$middle_name[[1L]], "Michael")
  expect_true(!is.na(result$suffix[[1L]]))
  expect_equal(result$first_name[[2L]], "Maria")
  expect_equal(result$last_name[[3L]], "Smith")
})

test_that("mysterycall_parse_physician_name happy path: remove_titles parameter", {
  name <- "Dr. John Smith"
  with_titles <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(name, remove_titles = FALSE)
  ))
  without_titles <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(name, remove_titles = TRUE)
  ))
  expect_equal(nrow(with_titles), 1L)
  expect_equal(nrow(without_titles), 1L)
  expect_equal(without_titles$first_name[[1L]], "John")
})

test_that("mysterycall_parse_physician_name edge case: NA and empty inputs", {
  names <- c("John Smith", NA_character_, "", "  ")
  result <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(names)
  ))
  expect_equal(nrow(result), 4L)
  expect_true(!is.na(result$first_name[[1L]]))
  expect_true(is.na(result$first_name[[2L]]))
  expect_true(is.na(result$first_name[[3L]]))
  expect_true(is.na(result$first_name[[4L]]))
  expect_equal(result$parse_confidence[[2L]], "low")
  expect_equal(result$parse_warnings[[2L]], "parsing_failed")
})

test_that("mysterycall_parse_physician_name edge case: single-word names", {
  names <- c("Madonna", "Prince")
  result <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(names)
  ))
  expect_equal(nrow(result), 2L)
  expect_equal(result$parse_confidence[[1L]], "medium")
  expect_equal(result$parse_warnings[[1L]], "single_word_name")
})

test_that("mysterycall_parse_physician_name edge case: DO credential vs Vietnamese surname", {
  names <- c("Linda Do", "Robert Smith DO")
  result <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(names)
  ))
  expect_equal(result$last_name[[1L]], "Do")
  expect_true(is.na(result$suffix[[1L]]))
  expect_equal(result$last_name[[2L]], "Smith")
  expect_equal(result$suffix[[2L]], "DO")
})

test_that("mysterycall_parse_physician_name bad input: non-character type", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_parse_physician_name(123)
    )),
    "must be a character vector"
  )
})

test_that("mysterycall_parse_physician_name bad input: invalid remove_titles", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_parse_physician_name("John Smith", remove_titles = "yes")
    )),
    "must be TRUE or FALSE"
  )
})

test_that("mysterycall_parse_physician_name bad input: remove_titles NA", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_parse_physician_name("John Smith", remove_titles = NA)
    )),
    "must be TRUE or FALSE"
  )
})

test_that("mysterycall_parse_physician_name happy path: empty vector", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(character(0))
  ))
  expect_s3_class(result, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(result), 0L)
})

# ============================================================================
# mysterycall_validate_parsed_names()
# ============================================================================

test_that("mysterycall_validate_parsed_names happy path: valid input", {
  parsed <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(c("John Smith", "MD", "Linda Do"))
  ))
  result <- suppressMessages(suppressWarnings(
    mysterycall_validate_parsed_names(parsed)
  ))
  expect_s3_class(result, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(result), 3L)
  expect_named(result, c("first_name", "middle_name", "last_name", "suffix",
                         "title", "parse_confidence", "parse_warnings",
                         "has_first", "has_last", "has_middle",
                         "valid_first", "valid_last", "is_valid",
                         "last_is_credential", "last_is_suffix", "last_too_short",
                         "middle_has_particle", "quality_issue"))
  expect_true(result$is_valid[[1L]])
  expect_false(result$is_valid[[2L]])
  expect_true(result$is_valid[[3L]])
})

test_that("mysterycall_validate_parsed_names happy path: require_first parameter", {
  parsed <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(c("John Smith", "Smith"))
  ))
  with_require <- suppressMessages(suppressWarnings(
    mysterycall_validate_parsed_names(parsed, require_first = TRUE)
  ))
  without_require <- suppressMessages(suppressWarnings(
    mysterycall_validate_parsed_names(parsed, require_first = FALSE)
  ))
  expect_true(with_require$is_valid[[1L]])
  expect_false(with_require$is_valid[[2L]])
  expect_true(without_require$is_valid[[1L]])
  expect_true(without_require$is_valid[[2L]])
})

test_that("mysterycall_validate_parsed_names happy path: require_last parameter", {
  parsed <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(c("John Smith", "John"))
  ))
  with_require <- suppressMessages(suppressWarnings(
    mysterycall_validate_parsed_names(parsed, require_last = TRUE)
  ))
  without_require <- suppressMessages(suppressWarnings(
    mysterycall_validate_parsed_names(parsed, require_last = FALSE)
  ))
  expect_true(with_require$is_valid[[1L]])
  expect_false(with_require$is_valid[[2L]])
  expect_true(without_require$is_valid[[1L]])
  expect_true(without_require$is_valid[[2L]])
})

test_that("mysterycall_validate_parsed_names edge case: quality issues detected", {
  parsed <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(c("John Smith", "MD", "Jr", "Jan van der Berg"))
  ))
  result <- suppressMessages(suppressWarnings(
    mysterycall_validate_parsed_names(parsed)
  ))
  expect_true(is.na(result$quality_issue[[1L]]))
  expect_equal(result$quality_issue[[2L]], "last_name_is_credential")
  expect_equal(result$quality_issue[[3L]], "last_name_is_suffix")
  expect_equal(result$quality_issue[[4L]], "name_particle_in_middle")
})

test_that("mysterycall_validate_parsed_names edge case: short surnames excluded", {
  parsed <- suppressMessages(suppressWarnings(
    mysterycall_parse_physician_name(c("John Do", "Jane Li", "Bob Wu", "Tom Ng"))
  ))
  result <- suppressMessages(suppressWarnings(
    mysterycall_validate_parsed_names(parsed)
  ))
  expect_false(result$last_too_short[[1L]])
  expect_false(result$last_too_short[[2L]])
  expect_false(result$last_too_short[[3L]])
  expect_false(result$last_too_short[[4L]])
})

test_that("mysterycall_validate_parsed_names bad input: non-dataframe", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_validate_parsed_names("not a dataframe")
    )),
    "must be a data frame"
  )
})

test_that("mysterycall_validate_parsed_names bad input: missing required columns", {
  bad_df <- data.frame(
    first_name = "John",
    last_name = "Smith",
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_validate_parsed_names(bad_df)
    )),
    "Missing columns"
  )
})

# ============================================================================
# mysterycall_format_physician_name()
# ============================================================================

test_that("mysterycall_format_physician_name happy path: last_first format", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_format_physician_name(
      first_name = "John",
      last_name = "Smith",
      middle_name = "A.",
      suffix = "MD"
    )
  ))
  expect_type(result, "character")
  expect_equal(result, "Smith, John A., MD")
})

test_that("mysterycall_format_physician_name happy path: first_last format", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_format_physician_name(
      first_name = "Maria",
      last_name = "de la Cruz",
      format = "first_last"
    )
  ))
  expect_equal(result, "Maria de la Cruz")
})

test_that("mysterycall_format_physician_name happy path: formal format", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_format_physician_name(
      first_name = "John",
      last_name = "Smith",
      suffix = "MD",
      format = "formal"
    )
  ))
  expect_equal(result, "Smith, John, MD")
})

test_that("mysterycall_format_physician_name happy path: include_suffix FALSE", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_format_physician_name(
      first_name = "John",
      last_name = "Smith",
      suffix = "MD",
      include_suffix = FALSE
    )
  ))
  expect_equal(result, "Smith, John")
})

test_that("mysterycall_format_physician_name happy path: vectorized input", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_format_physician_name(
      first_name = c("John", "Maria"),
      last_name = c("Smith", "Garcia"),
      middle_name = c("A.", NA)
    )
  ))
  expect_equal(length(result), 2L)
  expect_equal(result[[1L]], "Smith, John A.")
  expect_equal(result[[2L]], "Garcia, Maria")
})

test_that("mysterycall_format_physician_name edge case: NA/empty components", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_format_physician_name(
      first_name = c("John", NA, ""),
      last_name = c("Smith", "Jones", "Brown")
    )
  ))
  expect_equal(length(result), 3L)
  expect_equal(result[[1L]], "Smith, John")
  expect_equal(result[[2L]], "Jones")
  expect_equal(result[[3L]], "Brown")
})

test_that("mysterycall_format_physician_name edge case: empty vectors", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_format_physician_name(
      first_name = character(0),
      last_name = character(0)
    )
  ))
  expect_equal(length(result), 0L)
})

test_that("mysterycall_format_physician_name bad input: invalid format", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_format_physician_name(
        first_name = "John",
        last_name = "Smith",
        format = "invalid"
      )
    )),
    'must be "last_first", "first_last", or "formal"'
  )
})

test_that("mysterycall_format_physician_name edge case: all NA suffix included", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_format_physician_name(
      first_name = "John",
      last_name = "Smith",
      suffix = NA,
      include_suffix = TRUE
    )
  ))
  expect_equal(result, "Smith, John")
})

# ============================================================================
# mysterycall_test_name_parser()
# ============================================================================

test_that("mysterycall_test_name_parser happy path: returns invisible tibble", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_test_name_parser()
  ))
  expect_s3_class(result, c("tbl_df", "tbl", "data.frame"))
  expect_true(nrow(result) >= 10L)
  expect_true("is_valid" %in% names(result))
})

test_that("mysterycall_test_name_parser detects valid parses", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_test_name_parser()
  ))
  n_valid <- sum(result$is_valid, na.rm = TRUE)
  expect_true(n_valid > 0L)
})

test_that("mysterycall_test_name_parser detects quality issues", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_test_name_parser()
  ))
  has_issues <- sum(!is.na(result$quality_issue), na.rm = TRUE)
  expect_true(has_issues > 0L)
})
