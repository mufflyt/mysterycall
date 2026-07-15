# Tests for mysterycall_literature_table()
#
# Covers:
#   1.  Returns list of class mysterycall_literature_table
#   2.  $table is a data.frame with required columns
#   3.  n_studies equals nrow(prior_studies) when current_study is NULL
#   4.  n_studies equals nrow(prior_studies) + 1 when current_study supplied
#   5.  $sentence is a character scalar
#   6.  $or_range is character containing "-"
#   7.  sort_by="year" produces rows in ascending year order
#   8.  sort_by="or" produces rows in ascending OR order
#   9.  current study Author cell ends with "***" when highlight_current=TRUE
#  10.  current study Author cell has no "***" when highlight_current=FALSE
#  11.  Direction="Disparity detected" when CI excludes 1
#  12.  Direction="Favors equity" when CI includes 1 and OR in [0.80, 1.25]
#  13.  Direction="NS" when CI includes 1 but OR outside [0.80, 1.25]
#  14.  Error when prior_studies missing required columns
#  15.  Error when prior_studies is not a data.frame
#  16.  $forest_plot is NULL when include_forest=FALSE
#  17.  Optional columns (setting, notes) appear in $table when supplied
#  18.  Optional columns absent from $table when not supplied

library(testthat)

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

make_prior <- function(with_optional = FALSE) {
  df <- data.frame(
    author               = c("Bisgaier & Rhodes 2011", "Lowe et al. 2012",
                              "Kugelmass 2016", "Saloner et al. 2015"),
    year                 = c(2011L, 2012L, 2016L, 2015L),
    specialty            = c("Pediatrics", "Orthopedics",
                              "Psychiatry", "Primary Care"),
    insurance_comparison = rep("Medicaid vs. Private", 4L),
    or                   = c(0.38, 0.61, 0.45, 0.87),
    ci_lower             = c(0.22, 0.44, 0.31, 0.72),
    ci_upper             = c(0.65, 0.85, 0.66, 1.05),
    n                    = c(1612L, 800L, 360L, 1560L),
    stringsAsFactors     = FALSE
  )
  if (with_optional) {
    df$setting <- c("Urban", "Rural", "Urban", "Suburban")
    df$notes   <- c("RCT", "Observational", "RCT", "Survey")
  }
  df
}

make_current <- function() {
  list(
    author               = "Acosta & Mufflyt",
    year                 = 2025L,
    specialty            = "Urogynecology",
    insurance_comparison = "Medicaid vs. Private",
    or                   = 0.62,
    ci_lower             = 0.41,
    ci_upper             = 0.94,
    n                    = 480L
  )
}

# ---------------------------------------------------------------------------
# 1. Returns list of class mysterycall_literature_table
# ---------------------------------------------------------------------------

test_that("returns object of class mysterycall_literature_table", {
  result <- mysterycall_literature_table(make_prior())
  expect_s3_class(result, "mysterycall_literature_table")
  expect_type(result, "list")
})

# ---------------------------------------------------------------------------
# 2. $table is a data.frame with required columns
# ---------------------------------------------------------------------------

test_that("$table is a data.frame with all required display columns", {
  result        <- mysterycall_literature_table(make_prior())
  expected_cols <- c("Author", "Year", "Specialty", "Comparison",
                     "N", "OR (95% CI)", "Direction")
  expect_true(is.data.frame(result$table))
  expect_true(all(expected_cols %in% names(result$table)),
              info = paste("Missing:", paste(setdiff(expected_cols, names(result$table)),
                                             collapse = ", ")))
})

# ---------------------------------------------------------------------------
# 3. n_studies equals nrow(prior_studies) when current_study is NULL
# ---------------------------------------------------------------------------

test_that("n_studies equals nrow(prior_studies) when current_study is NULL", {
  prior  <- make_prior()
  result <- mysterycall_literature_table(prior)
  expect_equal(result$n_studies, nrow(prior))
})

# ---------------------------------------------------------------------------
# 4. n_studies is nrow(prior_studies) + 1 when current_study is provided
# ---------------------------------------------------------------------------

test_that("n_studies is nrow(prior_studies) + 1 when current_study is supplied", {
  prior   <- make_prior()
  result  <- mysterycall_literature_table(prior, current_study = make_current())
  expect_equal(result$n_studies, nrow(prior) + 1L)
})

# ---------------------------------------------------------------------------
# 5. $sentence is a character scalar
# ---------------------------------------------------------------------------

test_that("$sentence is a character scalar of length 1", {
  result <- mysterycall_literature_table(make_prior())
  expect_type(result$sentence, "character")
  expect_length(result$sentence, 1L)
})

test_that("$sentence includes current study OR when current_study is supplied", {
  result <- mysterycall_literature_table(make_prior(), current_study = make_current())
  expect_match(result$sentence, "OR =", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# 6. $or_range is character containing "-"
# ---------------------------------------------------------------------------

test_that("$or_range is a character scalar containing '-'", {
  result <- mysterycall_literature_table(make_prior())
  expect_type(result$or_range, "character")
  expect_length(result$or_range, 1L)
  expect_match(result$or_range, "-", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# 7. sort_by="year" produces rows in ascending year order
# ---------------------------------------------------------------------------

test_that("sort_by='year' returns rows with Year in non-decreasing order", {
  result <- mysterycall_literature_table(make_prior(), sort_by = "year")
  years  <- result$table$Year
  expect_equal(years, sort(years))
})

# ---------------------------------------------------------------------------
# 8. sort_by="or" produces rows in ascending OR order
# ---------------------------------------------------------------------------

test_that("sort_by='or' returns rows with OR in non-decreasing order", {
  result  <- mysterycall_literature_table(make_prior(), sort_by = "or")
  # Parse the leading numeric value from strings like "0.38 (0.22-0.65)"
  or_vals <- as.numeric(sub("^([0-9.]+).*", "\\1", result$table[["OR (95% CI)"]]))
  expect_equal(or_vals, sort(or_vals))
})

# ---------------------------------------------------------------------------
# 9. Current study Author cell ends with "***" when highlight_current=TRUE
# ---------------------------------------------------------------------------

test_that("current study Author ends with '***' when highlight_current=TRUE", {
  result <- mysterycall_literature_table(
    make_prior(),
    current_study     = make_current(),
    highlight_current = TRUE
  )
  current_rows <- result$table$Author[grepl("[Current study]", result$table$Author,
                                            fixed = TRUE)]
  expect_length(current_rows, 1L)
  expect_match(current_rows, "\\*\\*\\*$")
})

# ---------------------------------------------------------------------------
# 10. Current study Author cell has no "***" when highlight_current=FALSE
# ---------------------------------------------------------------------------

test_that("current study Author has no '***' when highlight_current=FALSE", {
  result <- mysterycall_literature_table(
    make_prior(),
    current_study     = make_current(),
    highlight_current = FALSE
  )
  current_rows <- result$table$Author[grepl("[Current study]", result$table$Author,
                                            fixed = TRUE)]
  expect_length(current_rows, 1L)
  expect_false(grepl("***", current_rows, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# 11. Direction="Disparity detected" when CI excludes 1
# ---------------------------------------------------------------------------

test_that("Direction is 'Disparity detected' when CI excludes 1", {
  # Bisgaier: CI = (0.22, 0.65) — entirely below 1, sig = TRUE
  result       <- mysterycall_literature_table(make_prior(), sort_by = "author")
  bisgaier_row <- result$table[result$table$Author == "Bisgaier & Rhodes 2011", ]
  expect_equal(bisgaier_row$Direction, "Disparity detected")
})

# ---------------------------------------------------------------------------
# 12. Direction="Favors equity" when CI includes 1 and OR in [0.80, 1.25]
# ---------------------------------------------------------------------------

test_that("Direction is 'Favors equity' when CI includes 1 and OR in [0.80, 1.25]", {
  # Saloner: CI = (0.72, 1.05) — includes 1; OR = 0.87 in [0.80, 1.25]
  result      <- mysterycall_literature_table(make_prior(), sort_by = "author")
  saloner_row <- result$table[result$table$Author == "Saloner et al. 2015", ]
  expect_equal(saloner_row$Direction, "Favors equity")
})

# ---------------------------------------------------------------------------
# 13. Direction="NS" when CI includes 1 but OR outside [0.80, 1.25]
# ---------------------------------------------------------------------------

test_that("Direction is 'NS' when CI includes 1 but OR outside [0.80, 1.25]", {
  # OR = 1.5, CI = (0.9, 2.5): includes 1, but 1.5 > 1.25 -> "NS"
  ns_prior <- data.frame(
    author               = "NS Study 2020",
    year                 = 2020L,
    specialty            = "Cardiology",
    insurance_comparison = "Medicaid vs. Private",
    or                   = 1.5,
    ci_lower             = 0.9,
    ci_upper             = 2.5,
    n                    = 500L,
    stringsAsFactors     = FALSE
  )
  result <- mysterycall_literature_table(ns_prior)
  expect_equal(result$table$Direction, "NS")
})

# ---------------------------------------------------------------------------
# 14. Error when prior_studies is missing required columns
# ---------------------------------------------------------------------------

test_that("errors when prior_studies is missing required columns", {
  bad_df <- data.frame(author = "A", year = 2020L, stringsAsFactors = FALSE)
  expect_error(
    mysterycall_literature_table(bad_df),
    regexp = "required columns are absent"
  )
})

# ---------------------------------------------------------------------------
# 15. Error when prior_studies is not a data.frame
# ---------------------------------------------------------------------------

test_that("errors when prior_studies is not a data.frame", {
  expect_error(
    mysterycall_literature_table(list(author = "A")),
    regexp = "must be a data\\.frame"
  )
})

# ---------------------------------------------------------------------------
# 16. $forest_plot is NULL when include_forest=FALSE
# ---------------------------------------------------------------------------

test_that("$forest_plot is NULL when include_forest=FALSE", {
  result <- mysterycall_literature_table(make_prior(), include_forest = FALSE)
  expect_null(result$forest_plot)
})

test_that("$forest_plot is NULL with current_study when include_forest=FALSE", {
  result <- mysterycall_literature_table(
    make_prior(),
    current_study  = make_current(),
    include_forest = FALSE
  )
  expect_null(result$forest_plot)
})

# ---------------------------------------------------------------------------
# 17. Optional columns appear in $table when supplied in prior_studies
# ---------------------------------------------------------------------------

test_that("Setting and Notes columns present in $table when supplied", {
  result <- mysterycall_literature_table(make_prior(with_optional = TRUE))
  expect_true("Setting" %in% names(result$table))
  expect_true("Notes"   %in% names(result$table))
  expect_equal(nrow(result$table), 4L)
})

# ---------------------------------------------------------------------------
# 18. Optional columns absent from $table when not supplied
# ---------------------------------------------------------------------------

test_that("Setting, Notes, Outcome absent from $table when not in prior_studies", {
  result <- mysterycall_literature_table(make_prior(with_optional = FALSE))
  expect_false("Setting" %in% names(result$table))
  expect_false("Notes"   %in% names(result$table))
  expect_false("Outcome" %in% names(result$table))
})

# ---------------------------------------------------------------------------
# Regression (BUG 37): $or_range describes PRIOR studies only, excluding the
# current-study row, since the sentence reads "N published studies ... ranged
# from {or_range}".
# ---------------------------------------------------------------------------

test_that("or_range excludes the current-study row", {
  prior   <- make_prior()  # prior ORs: 0.38, 0.61, 0.45, 0.87 -> range 0.38-0.87
  current <- make_current()
  current$or       <- 0.10   # extreme value OUTSIDE the prior range
  current$ci_lower <- 0.05
  current$ci_upper <- 0.20

  res <- mysterycall_literature_table(prior, current_study = current)
  expect_equal(res$or_range, "0.38-0.87")
  expect_false(grepl("0.10", res$or_range, fixed = TRUE))
})

test_that("or_range spans all rows when current_study is NULL", {
  prior <- make_prior()
  res   <- mysterycall_literature_table(prior, current_study = NULL)
  expect_equal(res$or_range, "0.38-0.87")
})
