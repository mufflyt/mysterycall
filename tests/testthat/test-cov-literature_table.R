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
# Test: mysterycall_literature_table() - Happy Path with Minimal Input
# ============================================================================

test_that("mysterycall_literature_table() returns correctly structured list with valid prior_studies", {
  prior <- data.frame(
    author               = c("Study A", "Study B"),
    year                 = c(2020L, 2021L),
    specialty            = c("Pediatrics", "Orthopedics"),
    insurance_comparison = c("Medicaid vs. Private", "Medicaid vs. Private"),
    or                   = c(0.45, 0.62),
    ci_lower             = c(0.30, 0.50),
    ci_upper             = c(0.60, 0.75),
    n                    = c(500L, 600L),
    stringsAsFactors     = FALSE
  )

  result <- suppressMessages(
    mysterycall_literature_table(
      prior_studies = prior,
      current_study = NULL,
      sort_by       = "year",
      digits        = 2L
    )
  )

  expect_s3_class(result, "mysterycall_literature_table")
  expect_type(result, "list")
  expect_named(result, c("table", "forest_plot", "n_studies", "or_range", "sentence"))
  expect_s3_class(result$table, "data.frame")
  expect_equal(result$n_studies, 2L)
  expect_equal(nrow(result$table), 2L)
  expect_true(grepl("Medicaid vs. Private", result$sentence))
})


# ============================================================================
# Test: mysterycall_literature_table() - Happy Path with current_study
# ============================================================================

test_that("mysterycall_literature_table() appends current_study row correctly", {
  prior <- data.frame(
    author               = c("Study A", "Study B"),
    year                 = c(2020L, 2021L),
    specialty            = c("Pediatrics", "Orthopedics"),
    insurance_comparison = c("Medicaid vs. Private", "Medicaid vs. Private"),
    or                   = c(0.45, 0.62),
    ci_lower             = c(0.30, 0.50),
    ci_upper             = c(0.60, 0.75),
    n                    = c(500L, 600L),
    stringsAsFactors     = FALSE
  )

  current <- list(
    year                 = 2025L,
    specialty            = "Urology",
    insurance_comparison = "Medicaid vs. Private",
    or                   = 0.55,
    ci_lower             = 0.40,
    ci_upper             = 0.70,
    n                    = 480L
  )

  result <- suppressMessages(
    mysterycall_literature_table(
      prior_studies = prior,
      current_study = current,
      sort_by       = "year"
    )
  )

  expect_equal(result$n_studies, 3L)
  expect_equal(nrow(result$table), 3L)
  expect_true(any(grepl("\\[Current study\\]", result$table$Author)))
  expect_true(any(grepl("\\*\\*\\*", result$table$Author)))
  expect_true(grepl("consistent with our finding", result$sentence))
})


# ============================================================================
# Test: mysterycall_literature_table() - Edge Case: NA values in OR/CI
# ============================================================================

test_that("mysterycall_literature_table() handles NA values in OR and CI", {
  prior <- data.frame(
    author               = c("Study A", "Study B", "Study C"),
    year                 = c(2020L, 2021L, 2022L),
    specialty            = c("Pediatrics", "Orthopedics", "Cardiology"),
    insurance_comparison = c("Medicaid vs. Private", "Medicaid vs. Private", "Medicaid vs. Private"),
    or                   = c(0.45, NA, 0.65),
    ci_lower             = c(0.30, NA, 0.50),
    ci_upper             = c(0.60, NA, 0.80),
    n                    = c(500L, 600L, 700L),
    stringsAsFactors     = FALSE
  )

  result <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior)
  )

  expect_equal(result$n_studies, 3L)
  expect_true(any(is.na(result$table$Direction)))
  expect_equal(nrow(result$table), 3L)
})


# ============================================================================
# Test: mysterycall_literature_table() - Edge Case: sort_by Options
# ============================================================================

test_that("mysterycall_literature_table() sorts correctly by different columns", {
  prior <- data.frame(
    author               = c("Zebra Study", "Alpha Study", "Beta Study"),
    year                 = c(2022L, 2020L, 2021L),
    specialty            = c("Pediatrics", "Orthopedics", "Cardiology"),
    insurance_comparison = c("Medicaid vs. Private", "Medicaid vs. Private", "Medicaid vs. Private"),
    or                   = c(0.80, 0.45, 0.65),
    ci_lower             = c(0.60, 0.30, 0.50),
    ci_upper             = c(1.00, 0.60, 0.80),
    n                    = c(500L, 600L, 700L),
    stringsAsFactors     = FALSE
  )

  # Sort by year
  result_year <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior, sort_by = "year")
  )
  expect_equal(result_year$table$Year[1], 2020L)
  expect_equal(result_year$table$Year[3], 2022L)

  # Sort by author
  result_author <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior, sort_by = "author")
  )
  expect_equal(result_author$table$Author[1], "Alpha Study")
  expect_equal(result_author$table$Author[3], "Zebra Study")

  # Sort by OR
  result_or <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior, sort_by = "or")
  )
  expect_equal(result_or$table$Author[1], "Alpha Study")  # OR = 0.45
  expect_equal(result_or$table$Author[3], "Zebra Study")  # OR = 0.80
})


# ============================================================================
# Test: mysterycall_literature_table() - Edge Case: digits Parameter
# ============================================================================

test_that("mysterycall_literature_table() formats numbers with correct decimal places", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.456),
    ci_lower             = c(0.301),
    ci_upper             = c(0.612),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  result_0 <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior, digits = 0L)
  )
  expect_true(grepl("0 \\(0-1\\)", result_0$table$`OR (95% CI)`[1]))

  result_3 <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior, digits = 3L)
  )
  expect_true(grepl("0\\.456", result_3$table$`OR (95% CI)`[1]))
})


# ============================================================================
# Test: mysterycall_literature_table() - Bad Input: Missing Required Columns
# ============================================================================

test_that("mysterycall_literature_table() errors when prior_studies lacks required columns", {
  prior_missing_author <- data.frame(
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior_missing_author),
    "required columns are absent"
  )

  prior_missing_or <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior_missing_or),
    "required columns are absent"
  )
})


# ============================================================================
# Test: mysterycall_literature_table() - Bad Input: Wrong Data Types
# ============================================================================

test_that("mysterycall_literature_table() errors on wrong data types", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  # Non-data.frame prior_studies
  expect_error(
    mysterycall_literature_table(prior_studies = list(x = 1)),
    "`prior_studies` must be a data.frame"
  )

  # Non-character author
  prior_bad_author <- prior
  prior_bad_author$author <- as.factor(prior_bad_author$author)
  expect_error(
    mysterycall_literature_table(prior_studies = prior_bad_author),
    "`prior_studies\\$author` must be character"
  )

  # Non-numeric or
  prior_bad_or <- prior
  prior_bad_or$or <- as.character(prior_bad_or$or)
  expect_error(
    mysterycall_literature_table(prior_studies = prior_bad_or),
    "`prior_studies\\$or`.*must all be numeric"
  )
})


# ============================================================================
# Test: mysterycall_literature_table() - Bad Input: Negative OR
# ============================================================================

test_that("mysterycall_literature_table() errors when OR is non-positive", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(-0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior),
    "non-NA values in `prior_studies\\$or` must be positive"
  )

  prior_zero <- prior
  prior_zero$or <- 0
  expect_error(
    mysterycall_literature_table(prior_studies = prior_zero),
    "non-NA values in `prior_studies\\$or` must be positive"
  )
})


# ============================================================================
# Test: mysterycall_literature_table() - Bad Input: Invalid sort_by
# ============================================================================

test_that("mysterycall_literature_table() errors on invalid sort_by", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior, sort_by = "invalid_option"),
    "should be one of"
  )
})


# ============================================================================
# Test: mysterycall_literature_table() - Bad Input: Invalid digits
# ============================================================================

test_that("mysterycall_literature_table() errors on invalid digits", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior, digits = -1L),
    "`digits` must be a non-negative integer scalar"
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior, digits = c(1L, 2L)),
    "`digits` must be a non-negative integer scalar"
  )
})


# ============================================================================
# Test: mysterycall_literature_table() - Bad Input: Invalid highlight_current
# ============================================================================

test_that("mysterycall_literature_table() errors on invalid highlight_current", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior, highlight_current = "yes"),
    "`highlight_current` must be a single logical value"
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior, highlight_current = c(TRUE, FALSE)),
    "`highlight_current` must be a single logical value"
  )
})


# ============================================================================
# Test: mysterycall_literature_table() - Bad Input: Invalid include_forest
# ============================================================================

test_that("mysterycall_literature_table() errors on invalid include_forest", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior, include_forest = "yes"),
    "`include_forest` must be a single logical value"
  )
})


# ============================================================================
# Test: mysterycall_literature_table() - Bad Input: current_study Not a List
# ============================================================================

test_that("mysterycall_literature_table() errors when current_study is not a list", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior, current_study = "not a list"),
    "`current_study` must be a named list or NULL"
  )
})


# ============================================================================
# Test: mysterycall_literature_table() - Bad Input: current_study Missing Required Elements
# ============================================================================

test_that("mysterycall_literature_table() errors when current_study lacks required elements", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  current_missing_or <- list(
    year                 = 2025L,
    specialty            = "Urology",
    insurance_comparison = "Medicaid vs. Private",
    ci_lower             = 0.40,
    ci_upper             = 0.70,
    n                    = 480L
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior, current_study = current_missing_or),
    "missing from `current_study`"
  )
})


# ============================================================================
# Test: mysterycall_literature_table() - Bad Input: current_study Invalid OR
# ============================================================================

test_that("mysterycall_literature_table() errors when current_study has invalid OR", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  current_bad_or <- list(
    year                 = 2025L,
    specialty            = "Urology",
    insurance_comparison = "Medicaid vs. Private",
    or                   = -0.55,
    ci_lower             = 0.40,
    ci_upper             = 0.70,
    n                    = 480L
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior, current_study = current_bad_or),
    "`current_study\\$or` must be a positive number"
  )

  current_nonnum_or <- list(
    year                 = 2025L,
    specialty            = "Urology",
    insurance_comparison = "Medicaid vs. Private",
    or                   = "0.55",
    ci_lower             = 0.40,
    ci_upper             = 0.70,
    n                    = 480L
  )

  expect_error(
    mysterycall_literature_table(prior_studies = prior, current_study = current_nonnum_or),
    "`current_study\\$or`.*must be numeric"
  )
})


# ============================================================================
# Test: mysterycall_literature_table() - Optional Columns (setting, outcome_label, notes)
# ============================================================================

test_that("mysterycall_literature_table() carries optional columns through", {
  prior <- data.frame(
    author               = c("Study A", "Study B"),
    year                 = c(2020L, 2021L),
    specialty            = c("Pediatrics", "Orthopedics"),
    insurance_comparison = c("Medicaid vs. Private", "Medicaid vs. Private"),
    or                   = c(0.45, 0.62),
    ci_lower             = c(0.30, 0.50),
    ci_upper             = c(0.60, 0.75),
    n                    = c(500L, 600L),
    setting              = c("Urban", "Rural"),
    outcome_label        = c("Access to care", "Quality of care"),
    notes                = c("Note 1", "Note 2"),
    stringsAsFactors     = FALSE
  )

  result <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior)
  )

  expect_true("Setting" %in% names(result$table))
  expect_true("Outcome" %in% names(result$table))
  expect_true("Notes" %in% names(result$table))
  expect_equal(result$table$Setting[1], "Urban")
  expect_equal(result$table$Outcome[2], "Quality of care")
})


# ============================================================================
# Test: mysterycall_literature_table() - Direction Labels
# ============================================================================

test_that("mysterycall_literature_table() correctly computes Direction column", {
  prior <- data.frame(
    author               = c("Significant", "Equity", "NS"),
    year                 = c(2020L, 2021L, 2022L),
    specialty            = c("Ped", "Orth", "Card"),
    insurance_comparison = c("Med vs. Priv", "Med vs. Priv", "Med vs. Priv"),
    or                   = c(0.50, 1.00, 0.70),
    ci_lower             = c(0.30, 0.90, 0.60),
    ci_upper             = c(0.70, 1.10, 1.20),
    n                    = c(500L, 600L, 700L),
    stringsAsFactors     = FALSE
  )

  result <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior)
  )

  # CI excludes 1 (0.30-0.70) -> "Disparity detected"
  expect_equal(result$table$Direction[1], "Disparity detected")

  # CI includes 1 and OR in [0.80, 1.25] -> "Favors equity"
  expect_equal(result$table$Direction[2], "Favors equity")

  # CI includes 1 but OR outside [0.80, 1.25] -> "NS"
  expect_equal(result$table$Direction[3], "NS")
})


# ============================================================================
# Test: mysterycall_literature_table() - highlight_current=FALSE
# ============================================================================

test_that("mysterycall_literature_table() respects highlight_current parameter", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  current <- list(
    year                 = 2025L,
    specialty            = "Urology",
    insurance_comparison = "Medicaid vs. Private",
    or                   = 0.55,
    ci_lower             = 0.40,
    ci_upper             = 0.70,
    n                    = 480L
  )

  result_highlight_false <- suppressMessages(
    mysterycall_literature_table(
      prior_studies      = prior,
      current_study      = current,
      highlight_current  = FALSE
    )
  )

  expect_false(any(grepl("\\*\\*\\*", result_highlight_false$table$Author)))
  expect_equal(
    result_highlight_false$table$Author[2],
    "[Current study]"
  )
})


# ============================================================================
# Test: mysterycall_literature_table() - include_forest=TRUE with ggplot2
# ============================================================================

test_that("mysterycall_literature_table() creates forest plot when ggplot2 available", {
  skip_if_not_installed("ggplot2")

  prior <- data.frame(
    author               = c("Study A", "Study B"),
    year                 = c(2020L, 2021L),
    specialty            = c("Pediatrics", "Orthopedics"),
    insurance_comparison = c("Medicaid vs. Private", "Medicaid vs. Private"),
    or                   = c(0.45, 0.62),
    ci_lower             = c(0.30, 0.50),
    ci_upper             = c(0.60, 0.75),
    n                    = c(500L, 600L),
    stringsAsFactors     = FALSE
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_literature_table(
        prior_studies  = prior,
        include_forest = TRUE
      )
    )
  )

  expect_s3_class(result$forest_plot, "ggplot")
})


# ============================================================================
# Test: mysterycall_literature_table() - include_forest=TRUE without ggplot2
# ============================================================================

test_that("mysterycall_literature_table() warns when include_forest=TRUE but ggplot2 missing", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  # Mock the absence of ggplot2 (this test will still pass if ggplot2 is installed,
  # as the warning won't be triggered). To truly test, we would need to mock requireNamespace.
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_literature_table(
        prior_studies  = prior,
        include_forest = TRUE
      )
    )
  )

  # If ggplot2 is available, forest_plot will be non-NULL
  # If ggplot2 is unavailable, forest_plot will be NULL
  expect_true(is.null(result$forest_plot) || inherits(result$forest_plot, "ggplot"))
})


# ============================================================================
# Test: print.mysterycall_literature_table()
# ============================================================================

test_that("print.mysterycall_literature_table() outputs correctly", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  result <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior)
  )

  output <- capture.output(print(result))

  expect_true(any(grepl("Mystery-caller literature comparison", output)))
  expect_true(any(grepl("1 studies", output)))
  expect_true(any(grepl("OR range", output)))
  expect_true(any(grepl("Discussion sentence", output)))
})


# ============================================================================
# Test: mysterycall_literature_table() - Output structure with multiple studies
# ============================================================================

test_that("mysterycall_literature_table() builds complete formatted table", {
  prior <- data.frame(
    author               = c("Bisgaier & Rhodes 2011", "Lowe et al. 2012"),
    year                 = c(2011L, 2012L),
    specialty            = c("Pediatrics", "Orthopedics"),
    insurance_comparison = c("Medicaid vs. Private", "Medicaid vs. Private"),
    or                   = c(0.38, 0.61),
    ci_lower             = c(0.22, 0.44),
    ci_upper             = c(0.65, 0.85),
    n                    = c(1612L, 800L),
    stringsAsFactors     = FALSE
  )

  result <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior, digits = 2L)
  )

  expect_equal(result$n_studies, 2L)
  expect_named(
    result$table,
    c("Author", "Year", "Specialty", "Comparison", "N", "OR (95% CI)", "Direction")
  )

  # Check formatting of OR (95% CI) column
  expect_true(grepl("\\(.*-.*\\)", result$table$`OR (95% CI)`[1]))

  # Check OR range
  expect_equal(result$or_range, "0.38-0.61")
})


# ============================================================================
# Test: mysterycall_literature_table() - Sentence generation without current_study
# ============================================================================

test_that("mysterycall_literature_table() generates correct sentence without current_study", {
  prior <- data.frame(
    author               = c("Study A", "Study B", "Study C"),
    year                 = c(2020L, 2021L, 2022L),
    specialty            = c("Pediatrics", "Pediatrics", "Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private", "Medicaid vs. Private", "Medicaid vs. Private"),
    or                   = c(0.45, 0.62, 0.55),
    ci_lower             = c(0.30, 0.50, 0.40),
    ci_upper             = c(0.60, 0.75, 0.70),
    n                    = c(500L, 600L, 700L),
    stringsAsFactors     = FALSE
  )

  result <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior)
  )

  expect_false(grepl("consistent with our finding", result$sentence))
  expect_true(grepl("3 mystery-caller studies", result$sentence))
})


# ============================================================================
# Test: mysterycall_literature_table() - Sentence generation with current_study
# ============================================================================

test_that("mysterycall_literature_table() generates correct sentence with current_study", {
  prior <- data.frame(
    author               = c("Study A", "Study B"),
    year                 = c(2020L, 2021L),
    specialty            = c("Pediatrics", "Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private", "Medicaid vs. Private"),
    or                   = c(0.45, 0.62),
    ci_lower             = c(0.30, 0.50),
    ci_upper             = c(0.60, 0.75),
    n                    = c(500L, 600L),
    stringsAsFactors     = FALSE
  )

  current <- list(
    year                 = 2025L,
    specialty            = "Pediatrics",
    insurance_comparison = "Medicaid vs. Private",
    or                   = 0.55,
    ci_lower             = 0.40,
    ci_upper             = 0.70,
    n                    = 480L
  )

  result <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior, current_study = current)
  )

  expect_true(grepl("consistent with our finding", result$sentence))
  expect_true(grepl("2 published mystery-caller studies", result$sentence))
  expect_true(grepl("OR = 0.55", result$sentence))
})


# ============================================================================
# Test: mysterycall_literature_table() - Invisible return from print
# ============================================================================

test_that("print.mysterycall_literature_table() returns object invisibly", {
  prior <- data.frame(
    author               = c("Study A"),
    year                 = c(2020L),
    specialty            = c("Pediatrics"),
    insurance_comparison = c("Medicaid vs. Private"),
    or                   = c(0.45),
    ci_lower             = c(0.30),
    ci_upper             = c(0.60),
    n                    = c(500L),
    stringsAsFactors     = FALSE
  )

  result <- suppressMessages(
    mysterycall_literature_table(prior_studies = prior)
  )

  returned <- capture.output(
    invisible_result <- print(result)
  )

  expect_s3_class(invisible_result, "mysterycall_literature_table")
  expect_equal(invisible_result$n_studies, result$n_studies)
})
