# tests/testthat/test-parse-physician-name.R
#
# Unit tests for mysterycall_parse_physician_name(),
# mysterycall_validate_parsed_names(), and mysterycall_format_physician_name().

library(testthat)

# ── helpers ───────────────────────────────────────────────────────────────────

# Minimal tibble matching the output shape of mysterycall_parse_physician_name(),
# for constructing inputs to mysterycall_validate_parsed_names() without going
# through humaniformat.
.make_parsed <- function(first = NA_character_,
                         last  = NA_character_,
                         middle = NA_character_,
                         suffix = NA_character_,
                         title  = NA_character_,
                         confidence = "high",
                         warnings   = NA_character_) {
  tibble::tibble(
    first_name       = first,
    middle_name      = middle,
    last_name        = last,
    suffix           = suffix,
    title            = title,
    parse_confidence = confidence,
    parse_warnings   = warnings
  )
}

# ── 1. Return structure ───────────────────────────────────────────────────────

test_that("parse_physician_name: returns tibble with required columns", {
  result <- mysterycall_parse_physician_name("John Smith")
  expect_s3_class(result, "tbl_df")
  expected_cols <- c("first_name", "middle_name", "last_name", "suffix",
                     "title", "parse_confidence", "parse_warnings")
  expect_true(all(expected_cols %in% names(result)))
})

test_that("parse_physician_name: one row per input element (vectorised)", {
  result <- mysterycall_parse_physician_name(
    c("John Smith", "Jane Doe", NA, "")
  )
  expect_equal(nrow(result), 4L)
})

test_that("parse_physician_name: character(0) → zero-row tibble", {
  result <- mysterycall_parse_physician_name(character(0))
  expect_equal(nrow(result), 0L)
  expect_true("parse_confidence" %in% names(result))
})

# ── 2. Standard name formats ──────────────────────────────────────────────────

test_that("parse_physician_name: 'First Last' → correct fields, high confidence", {
  result <- mysterycall_parse_physician_name("John Smith")
  expect_equal(result$first_name, "John")
  expect_equal(result$last_name,  "Smith")
  expect_equal(result$parse_confidence, "high")
  expect_true(is.na(result$parse_warnings))
})

test_that("parse_physician_name: 'First Last, MD' → suffix='MD', high confidence", {
  result <- mysterycall_parse_physician_name("John Smith, MD")
  expect_equal(result$first_name,  "John")
  expect_equal(result$last_name,   "Smith")
  expect_equal(result$suffix,      "MD")
  expect_equal(result$parse_confidence, "high")
})

test_that("parse_physician_name: 'First Middle Last' → middle name captured", {
  result <- mysterycall_parse_physician_name("John Michael Smith")
  expect_equal(result$first_name,  "John")
  expect_equal(result$middle_name, "Michael")
  expect_equal(result$last_name,   "Smith")
  expect_equal(result$parse_confidence, "high")
})

test_that("parse_physician_name: multiple credentials → full suffix string", {
  result <- mysterycall_parse_physician_name("John Smith, MD, FACOG")
  expect_equal(result$first_name, "John")
  expect_equal(result$last_name,  "Smith")
  expect_true(!is.na(result$suffix))
  expect_true(grepl("MD", result$suffix))
})

# ── 3. Three-part comma format ────────────────────────────────────────────────

test_that("parse_physician_name: 'Last, First, Jr.' → first+last+suffix", {
  result <- mysterycall_parse_physician_name("Smith, John, Jr.")
  expect_equal(result$first_name, "John")
  expect_equal(result$last_name,  "Smith")
  expect_equal(result$suffix,     "Jr.")
  expect_equal(result$parse_confidence, "high")
})

test_that("parse_physician_name: 'Last, First, III' → suffix='III'", {
  result <- mysterycall_parse_physician_name("Williams, Mary, III")
  expect_equal(result$last_name, "Williams")
  expect_equal(result$suffix,    "III")
})

# ── 4. DO credential vs Vietnamese surname disambiguation ─────────────────────

test_that("parse_physician_name: 'First Last DO' → suffix='DO', not last_name", {
  result <- mysterycall_parse_physician_name("Robert Smith DO")
  expect_equal(result$suffix, "DO")
  expect_equal(result$last_name, "Smith")
  expect_equal(result$first_name, "Robert")
})

test_that("parse_physician_name: 'Linda Do' → last_name='Do', no credential suffix", {
  result <- mysterycall_parse_physician_name("Linda Do")
  expect_equal(result$last_name, "Do")
  # 'Do' must NOT be treated as a credential
  expect_true(is.na(result$suffix) || result$suffix != "Do")
  expect_equal(result$parse_confidence, "high")
})

# ── 5. Missing / empty inputs ─────────────────────────────────────────────────

test_that("parse_physician_name: NA → all NA fields, confidence='low'", {
  result <- mysterycall_parse_physician_name(NA_character_)
  expect_true(is.na(result$first_name))
  expect_true(is.na(result$last_name))
  expect_true(is.na(result$middle_name))
  expect_true(is.na(result$suffix))
  expect_equal(result$parse_confidence, "low")
})

test_that("parse_physician_name: empty string → all NA fields, confidence='low'", {
  result <- mysterycall_parse_physician_name("")
  expect_true(is.na(result$first_name))
  expect_true(is.na(result$last_name))
  expect_equal(result$parse_confidence, "low")
})

test_that("parse_physician_name: whitespace-only → all NA fields, confidence='low'", {
  result <- mysterycall_parse_physician_name("   ")
  expect_true(is.na(result$first_name))
  expect_true(is.na(result$last_name))
  expect_equal(result$parse_confidence, "low")
})

# ── 6. Confidence scoring rules ───────────────────────────────────────────────

test_that("parse_physician_name: both names present → confidence='high'", {
  result <- mysterycall_parse_physician_name("Alice Johnson")
  expect_equal(result$parse_confidence, "high")
})

test_that("parse_physician_name: parse_confidence is always one of the three values", {
  inputs <- c("John Smith", NA_character_, "")
  result <- mysterycall_parse_physician_name(inputs)
  expect_true(all(result$parse_confidence %in% c("high", "medium", "low")))
})

# ── 7. Vectorised batch behaviour ─────────────────────────────────────────────

test_that("parse_physician_name: mixed valid/NA batch returns correct row count", {
  inputs <- c("John Smith", "Jane Doe, MD", NA_character_, "")
  result <- mysterycall_parse_physician_name(inputs)
  expect_equal(nrow(result), 4L)
  # First two have valid names
  expect_equal(result$parse_confidence[1], "high")
  expect_equal(result$parse_confidence[2], "high")
  # Last two are bad input
  expect_equal(result$parse_confidence[3], "low")
  expect_equal(result$parse_confidence[4], "low")
})

test_that("parse_physician_name: NA rows have NA in all name columns", {
  inputs <- c("John Smith", NA_character_)
  result <- mysterycall_parse_physician_name(inputs)
  expect_false(is.na(result$first_name[1]))
  expect_true(is.na(result$first_name[2]))
  expect_true(is.na(result$last_name[2]))
})

# ── 8. remove_titles parameter ────────────────────────────────────────────────

test_that("parse_physician_name: remove_titles=TRUE → title column is NA", {
  result <- mysterycall_parse_physician_name("Dr. John Smith", remove_titles = TRUE)
  expect_true(is.na(result$title))
})

test_that("parse_physician_name: remove_titles=NA → error", {
  expect_error(
    mysterycall_parse_physician_name("John Smith", remove_titles = NA),
    "`remove_titles` must be TRUE or FALSE"
  )
})

# ── 9. Input validation errors ────────────────────────────────────────────────

test_that("parse_physician_name: numeric input → informative error", {
  expect_error(
    mysterycall_parse_physician_name(12345),
    "`physician_name` must be a character vector"
  )
})

# ── 10. mysterycall_validate_parsed_names ─────────────────────────────────────

test_that("validate_parsed_names: valid first+last → is_valid=TRUE", {
  parsed   <- .make_parsed(first = "John", last = "Smith")
  result   <- mysterycall_validate_parsed_names(parsed)
  expect_true(result$is_valid)
  expect_true(result$has_first)
  expect_true(result$has_last)
  expect_false(result$has_middle)
  expect_true(is.na(result$quality_issue))
})

test_that("validate_parsed_names: missing last_name, require_last=TRUE → is_valid=FALSE", {
  parsed <- .make_parsed(first = "John", last = NA_character_,
                         confidence = "medium", warnings = "single_word_name")
  result <- mysterycall_validate_parsed_names(parsed, require_last = TRUE)
  expect_false(result$is_valid)
  expect_false(result$has_last)
})

test_that("validate_parsed_names: missing first_name, require_first=FALSE → is_valid=TRUE", {
  parsed <- .make_parsed(first = NA_character_, last = "Smith",
                         confidence = "medium", warnings = "single_word_name")
  result <- mysterycall_validate_parsed_names(parsed,
                                              require_first = FALSE,
                                              require_last  = TRUE)
  expect_true(result$is_valid)
})

test_that("validate_parsed_names: last_name='MD' → last_is_credential=TRUE", {
  parsed <- .make_parsed(first = "John", last = "MD")
  result <- mysterycall_validate_parsed_names(parsed)
  expect_true(result$last_is_credential)
  expect_equal(result$quality_issue, "last_name_is_credential")
})

test_that("validate_parsed_names: last_name='Jr' → last_is_suffix=TRUE", {
  parsed <- .make_parsed(first = "John", last = "Jr")
  result <- mysterycall_validate_parsed_names(parsed)
  expect_true(result$last_is_suffix)
  expect_equal(result$quality_issue, "last_name_is_suffix")
})

test_that("validate_parsed_names: middle_name='de' → middle_has_particle=TRUE", {
  parsed <- .make_parsed(first = "Maria", last = "Cruz", middle = "de")
  result <- mysterycall_validate_parsed_names(parsed)
  expect_true(result$middle_has_particle)
  expect_equal(result$quality_issue, "name_particle_in_middle")
})

test_that("validate_parsed_names: returns added columns", {
  parsed <- .make_parsed(first = "John", last = "Smith")
  result <- mysterycall_validate_parsed_names(parsed)
  added <- c("has_first", "has_last", "has_middle", "valid_first",
             "valid_last", "is_valid", "last_is_credential",
             "last_is_suffix", "last_too_short",
             "middle_has_particle", "quality_issue")
  expect_true(all(added %in% names(result)))
})

test_that("validate_parsed_names: non-data-frame input → informative error", {
  expect_error(
    mysterycall_validate_parsed_names("not a data frame"),
    "must be a data frame"
  )
})

test_that("validate_parsed_names: missing required columns → informative error", {
  bad_df <- data.frame(first_name = "John", stringsAsFactors = FALSE)
  expect_error(
    mysterycall_validate_parsed_names(bad_df),
    "Missing columns"
  )
})

test_that("validate_parsed_names: vectorised over multiple rows", {
  parsed <- tibble::tibble(
    first_name       = c("John",  NA),
    last_name        = c("Smith", NA),
    middle_name      = c(NA,      NA),
    suffix           = c(NA,      NA),
    title            = c(NA,      NA),
    parse_confidence = c("high",  "low"),
    parse_warnings   = c(NA,      "parsing_failed")
  )
  result <- mysterycall_validate_parsed_names(parsed)
  expect_equal(nrow(result), 2L)
  expect_true(result$is_valid[1])
  expect_false(result$is_valid[2])
})

# ── 11. mysterycall_format_physician_name ─────────────────────────────────────

test_that("format_physician_name: default last_first format", {
  result <- mysterycall_format_physician_name("John", "Smith")
  expect_equal(result, "Smith, John")
})

test_that("format_physician_name: last_first with suffix", {
  result <- mysterycall_format_physician_name("John", "Smith", suffix = "MD")
  expect_equal(result, "Smith, John, MD")
})

test_that("format_physician_name: last_first with middle name and suffix", {
  result <- mysterycall_format_physician_name("John", "Smith",
                                              middle_name = "A.",
                                              suffix      = "MD")
  expect_equal(result, "Smith, John A., MD")
})

test_that("format_physician_name: first_last format", {
  result <- mysterycall_format_physician_name("John", "Smith",
                                              format = "first_last")
  expect_equal(result, "John Smith")
})

test_that("format_physician_name: first_last with suffix", {
  result <- mysterycall_format_physician_name("John", "Smith",
                                              suffix = "MD",
                                              format = "first_last")
  expect_equal(result, "John Smith, MD")
})

test_that("format_physician_name: include_suffix=FALSE omits suffix", {
  result <- mysterycall_format_physician_name("John", "Smith",
                                              suffix         = "MD",
                                              include_suffix = FALSE)
  expect_equal(result, "Smith, John")
})

test_that("format_physician_name: NA middle name is silently omitted", {
  result <- mysterycall_format_physician_name("John", "Smith",
                                              middle_name = NA_character_)
  expect_equal(result, "Smith, John")
})

test_that("format_physician_name: character(0) inputs → character(0)", {
  result <- mysterycall_format_physician_name(character(0), character(0))
  expect_equal(result, character(0))
})

test_that("format_physician_name: invalid format string → informative error", {
  expect_error(
    mysterycall_format_physician_name("John", "Smith", format = "bad_format"),
    'must be "last_first", "first_last", or "formal"'
  )
})

test_that("format_physician_name: vectorised over multiple inputs", {
  first  <- c("John", "Maria")
  last   <- c("Smith", "Cruz")
  suffix <- c("MD",   NA)
  result <- mysterycall_format_physician_name(first, last, suffix = suffix)
  expect_equal(length(result), 2L)
  expect_equal(result[1], "Smith, John, MD")
  expect_equal(result[2], "Cruz, Maria")
})

# ── BUG 33 regression: "Last, First" format parsed correctly ────────────────

test_that("parse_physician_name: 'Last, First' -> first/last (not suffix)", {
  result <- mysterycall_parse_physician_name("Smith, John")
  expect_equal(result$first_name, "John")
  expect_equal(result$last_name,  "Smith")
  expect_true(is.na(result$suffix))
  expect_equal(result$parse_confidence, "high")
})

test_that("parse_physician_name: 'Last, First, MD' -> first/last with credential suffix", {
  result <- mysterycall_parse_physician_name("Garcia, Robert, MD")
  expect_equal(result$first_name, "Robert")
  expect_equal(result$last_name,  "Garcia")
  expect_equal(result$suffix,     "MD")
})

test_that("parse_physician_name: 'First Last, MD' still treats MD as suffix", {
  result <- mysterycall_parse_physician_name("Mary Johnson, MD")
  expect_equal(result$first_name, "Mary")
  expect_equal(result$last_name,  "Johnson")
  expect_equal(result$suffix,     "MD")
})

test_that("parse_physician_name: 'First Last, MD, FACOG' keeps multi-credential suffix", {
  result <- mysterycall_parse_physician_name("John Smith, MD, FACOG")
  expect_equal(result$first_name, "John")
  expect_equal(result$last_name,  "Smith")
  expect_equal(result$suffix,     "MD, FACOG")
})
