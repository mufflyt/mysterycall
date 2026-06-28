library(testthat)
library(mysterycall)

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
# Test 1: Happy path - basic correct call with Poisson model
# ============================================================================

test_that("mysterycall_strobe_checklist() returns 16-row data frame with Poisson model", {
  set.seed(1)

  irr_tbl <- data.frame(
    term      = c("(Intercept)", "insuranceMedicaid"),
    irr       = c(1.00, 1.28),
    ci_lower  = c(NA,   1.05),
    ci_upper  = c(NA,   1.56),
    p_value   = c(NA,   0.014),
    stringsAsFactors = FALSE
  )

  fake_model <- structure(
    list(
      irr_table     = irr_tbl,
      overdispersion = 1.3,
      n_dropped     = 4L,
      model         = NULL
    ),
    class = "mysterycall_poisson_model"
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(fake_model)
  ))

  # Check output structure
  expect_s3_class(result, c("mysterycall_strobe_checklist", "data.frame"))
  expect_equal(nrow(result), 16L)
  expect_true(all(c("Item", "Category", "Description", "Status", "Detail") %in% names(result)))

  # Check that Item column contains 1-16
  expect_equal(result$Item, 1L:16L)

  # Check Status column contains only PASS, WARN, FAIL
  expect_true(all(result$Status %in% c("PASS", "WARN", "FAIL")))
})


# ============================================================================
# Test 2: Happy path - NB model with all flags enabled
# ============================================================================

test_that("mysterycall_strobe_checklist() correctly evaluates NB model with all flags TRUE", {
  set.seed(2)

  irr_tbl <- data.frame(
    term      = c("(Intercept)", "insuranceMedicaid", "waveWave2"),
    irr       = c(1.00, 1.28, 0.95),
    ci_lower  = c(NA,   1.05, 0.80),
    ci_upper  = c(NA,   1.56, 1.15),
    p_value   = c(NA,   0.014, 0.621),
    stringsAsFactors = FALSE
  )

  fake_model <- structure(
    list(
      irr_table     = irr_tbl,
      overdispersion = 1.15,
      n_dropped     = 2L,
      power         = 0.85,
      sample_size   = 100L,
      model         = NULL
    ),
    class = "mysterycall_nb_model"
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(
      fake_model,
      sensitivity_run   = TRUE,
      has_flow_diagram  = TRUE,
      irr_reported      = TRUE,
      overdispersion_reported = TRUE
    )
  ))

  expect_s3_class(result, c("mysterycall_strobe_checklist", "data.frame"))
  expect_equal(nrow(result), 16L)

  # Check that at least items 6, 7, 9, 10, 12, 14, 15 should be PASS
  pass_items <- result$Item[result$Status == "PASS"]
  expect_true(all(c(6L, 7L, 9L, 10L, 12L, 14L, 15L) %in% pass_items))
})


# ============================================================================
# Test 3: Edge case - model with minimal/NA fields
# ============================================================================

test_that("mysterycall_strobe_checklist() handles minimal model with NAs gracefully", {
  set.seed(3)

  # Model with missing fields
  fake_model <- structure(
    list(
      irr_table     = NULL,
      overdispersion = NA,
      n_dropped     = NA,
      model         = NULL
    ),
    class = "mysterycall_poisson_model"
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(fake_model)
  ))

  expect_s3_class(result, c("mysterycall_strobe_checklist", "data.frame"))
  expect_equal(nrow(result), 16L)

  # Items 12 should be FAIL (no CI)
  item_12_status <- result$Status[result$Item == 12L]
  expect_equal(item_12_status, "FAIL")

  # Items 6, 11, 13, 14 should be WARN (no data)
  warn_items <- result$Item[result$Status == "WARN"]
  expect_true(all(c(6L, 11L, 13L, 14L) %in% warn_items))
})


# ============================================================================
# Test 4: Error path - invalid model class
# ============================================================================

test_that("mysterycall_strobe_checklist() errors on invalid model class", {
  set.seed(4)

  # Not a mysterycall model object
  bad_model <- list(irr_table = data.frame(), overdispersion = 1.0)

  expect_error(
    mysterycall_strobe_checklist(bad_model),
    "must be a `mysterycall_poisson_model` or `mysterycall_nb_model`",
    fixed = TRUE
  )
})


# ============================================================================
# Test 5: Edge case - model with NB and overdispersion override
# ============================================================================

test_that("mysterycall_strobe_checklist() respects overdispersion_reported override", {
  set.seed(5)

  # NB model without overdispersion field, but overdispersion_reported=TRUE
  fake_model <- structure(
    list(
      irr_table     = data.frame(
        term      = c("(Intercept)", "insuranceMedicaid"),
        irr       = c(1.0, 1.28),
        ci_lower  = c(NA, 1.05),
        ci_upper  = c(NA, 1.56),
        p_value   = c(NA, 0.014)
      ),
      overdispersion = NA,
      n_dropped     = 0L,
      model         = NULL
    ),
    class = "mysterycall_nb_model"
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(
      fake_model,
      overdispersion_reported = TRUE
    )
  ))

  expect_s3_class(result, c("mysterycall_strobe_checklist", "data.frame"))

  # Item 9 should be PASS (NB model) and item 14 should be PASS (overdispersion_reported=TRUE)
  item_9_status <- result$Status[result$Item == 9L]
  item_14_status <- result$Status[result$Item == 14L]
  expect_equal(item_9_status, "PASS")
  expect_equal(item_14_status, "PASS")
})


# ============================================================================
# Test 6: Print method
# ============================================================================

test_that("print method for mysterycall_strobe_checklist works without error", {
  set.seed(6)

  irr_tbl <- data.frame(
    term      = c("(Intercept)", "insuranceMedicaid"),
    irr       = c(1.00, 1.28),
    ci_lower  = c(NA,   1.05),
    ci_upper  = c(NA,   1.56),
    p_value   = c(NA,   0.014),
    stringsAsFactors = FALSE
  )

  fake_model <- structure(
    list(
      irr_table     = irr_tbl,
      overdispersion = 1.3,
      n_dropped     = 4L,
      model         = NULL
    ),
    class = "mysterycall_poisson_model"
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(fake_model)
  ))

  # Print should not error and should return the object invisibly
  expect_invisible(
    suppressWarnings(print(result))
  )
})
