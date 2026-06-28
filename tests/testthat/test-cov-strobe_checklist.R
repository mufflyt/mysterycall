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

# Helper: Create a fake mysterycall_poisson_model with configurable fields
make_fake_poisson <- function(
  has_ci = TRUE,
  has_pvals = TRUE,
  has_overdispersion = TRUE,
  has_random = FALSE,
  has_n_dropped = TRUE
) {
  irr_tbl <- data.frame(
    term      = c("(Intercept)", "insuranceMedicaid"),
    irr       = c(1.00, 1.28),
    ci_lower  = if (has_ci) c(NA, 1.05) else c(NA, NA),
    ci_upper  = if (has_ci) c(NA, 1.56) else c(NA, NA),
    p_value   = if (has_pvals) c(NA, 0.014) else c(NA, NA),
    stringsAsFactors = FALSE
  )

  model_obj <- if (has_random) {
    structure(list(), class = "glmerMod")
  } else {
    NULL
  }

  structure(
    list(
      irr_table     = irr_tbl,
      overdispersion = if (has_overdispersion) 1.3 else NA,
      n_dropped     = if (has_n_dropped) 4L else NA,
      power         = NULL,
      sample_size   = NULL,
      model         = model_obj
    ),
    class = "mysterycall_poisson_model"
  )
}

# Helper: Create a fake mysterycall_nb_model
make_fake_nb <- function(
  has_ci = TRUE,
  has_pvals = TRUE,
  has_n_dropped = TRUE
) {
  irr_tbl <- data.frame(
    term      = c("(Intercept)", "insuranceMedicaid"),
    irr       = c(1.00, 1.28),
    ci_lower  = if (has_ci) c(NA, 1.05) else c(NA, NA),
    ci_upper  = if (has_ci) c(NA, 1.56) else c(NA, NA),
    p_value   = if (has_pvals) c(NA, 0.014) else c(NA, NA),
    stringsAsFactors = FALSE
  )

  structure(
    list(
      irr_table     = irr_tbl,
      overdispersion = 1.5,
      n_dropped     = if (has_n_dropped) 2L else NA,
      power         = NULL,
      sample_size   = NULL,
      model         = NULL
    ),
    class = "mysterycall_nb_model"
  )
}

# ============================================================================
# Test 1: Happy path - basic Poisson model with all fields
# ============================================================================

test_that("mysterycall_strobe_checklist: Poisson model returns 16-row data.frame", {
  set.seed(1)

  mod <- make_fake_poisson(
    has_ci = TRUE,
    has_pvals = TRUE,
    has_overdispersion = TRUE,
    has_n_dropped = TRUE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod)
  ))

  # Check return type and class
  expect_s3_class(result, c("mysterycall_strobe_checklist", "data.frame"))
  expect_equal(nrow(result), 16L)
  expect_equal(ncol(result), 5L)

  # Check columns exist
  expected_cols <- c("Item", "Category", "Description", "Status", "Detail")
  expect_equal(names(result), expected_cols)

  # Check Item sequence
  expect_equal(result$Item, 1L:16L)

  # Check Status values are valid
  expect_true(all(result$Status %in% c("PASS", "WARN", "FAIL")))
})

# ============================================================================
# Test 2: Happy path - NB model with all parameters enabled
# ============================================================================

test_that("mysterycall_strobe_checklist: NB model with all params TRUE", {
  set.seed(2)

  mod <- make_fake_nb(has_ci = TRUE, has_pvals = TRUE, has_n_dropped = TRUE)
  # Add power field for item 6 to pass
  mod$power <- 0.85

  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(
      mod,
      data = AUDIT,
      sensitivity_run = TRUE,
      has_flow_diagram = TRUE,
      irr_reported = TRUE,
      overdispersion_reported = TRUE
    )
  ))

  expect_s3_class(result, "mysterycall_strobe_checklist")
  expect_equal(nrow(result), 16L)

  # Items that should PASS with NB + all flags true
  pass_items <- result$Item[result$Status == "PASS"]
  expected_pass <- c(6L, 7L, 9L, 10L, 12L, 14L, 15L)
  expect_true(all(expected_pass %in% pass_items))
})

# ============================================================================
# Test 3: Edge case - minimal model with NAs (all-NA fields)
# ============================================================================

test_that("mysterycall_strobe_checklist: minimal/NA model returns WARN/FAIL appropriately", {
  set.seed(3)

  mod <- make_fake_poisson(
    has_ci = FALSE,
    has_pvals = FALSE,
    has_overdispersion = FALSE,
    has_n_dropped = FALSE
  )
  mod$irr_table <- NULL  # Also remove irr_table

  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod)
  ))

  expect_s3_class(result, "mysterycall_strobe_checklist")
  expect_equal(nrow(result), 16L)

  # Item 12 (IRR with CI) should be FAIL when no irr_table
  item_12 <- result[result$Item == 12L, ]
  expect_equal(item_12$Status, "FAIL")

  # Item 11 (missing data reported) should be WARN
  item_11 <- result[result$Item == 11L, ]
  expect_equal(item_11$Status, "WARN")
})

# ============================================================================
# Test 4: Bad input - wrong model class
# ============================================================================

test_that("mysterycall_strobe_checklist: errors on non-mysterycall object", {
  set.seed(4)

  bad_model <- list(irr_table = data.frame())
  class(bad_model) <- "glm"

  expect_error(
    mysterycall_strobe_checklist(bad_model),
    "must be a `mysterycall_poisson_model` or `mysterycall_nb_model`"
  )
})

# ============================================================================
# Test 5: Parameter override - irr_reported
# ============================================================================

test_that("mysterycall_strobe_checklist: irr_reported override changes item 12", {
  set.seed(5)

  mod <- make_fake_poisson(has_ci = FALSE)  # No CI columns

  # Without override, item 12 should FAIL
  result_no_override <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod)
  ))
  item_12_no <- result_no_override[result_no_override$Item == 12L, ]
  expect_equal(item_12_no$Status, "FAIL")

  # With override=TRUE, item 12 should PASS
  result_with <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod, irr_reported = TRUE)
  ))
  item_12_yes <- result_with[result_with$Item == 12L, ]
  expect_equal(item_12_yes$Status, "PASS")
})

# ============================================================================
# Test 6: Parameter override - overdispersion_reported
# ============================================================================

test_that("mysterycall_strobe_checklist: overdispersion_reported changes item 9/14", {
  set.seed(6)

  # Poisson model (not NB) without overdispersion field
  mod <- make_fake_poisson(has_overdispersion = FALSE)

  result_no_override <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod)
  ))
  item_9_no <- result_no_override[result_no_override$Item == 9L, ]
  item_14_no <- result_no_override[result_no_override$Item == 14L, ]
  expect_equal(item_9_no$Status, "WARN")
  expect_equal(item_14_no$Status, "WARN")

  result_with <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod, overdispersion_reported = TRUE)
  ))
  item_9_yes <- result_with[result_with$Item == 9L, ]
  item_14_yes <- result_with[result_with$Item == 14L, ]
  expect_equal(item_9_yes$Status, "PASS")
  expect_equal(item_14_yes$Status, "PASS")
})

# ============================================================================
# Test 7: Parameter toggle - sensitivity_run
# ============================================================================

test_that("mysterycall_strobe_checklist: sensitivity_run toggles item 15", {
  set.seed(7)

  mod <- make_fake_poisson()

  result_false <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod, sensitivity_run = FALSE)
  ))
  item_15_false <- result_false[result_false$Item == 15L, ]
  expect_equal(item_15_false$Status, "WARN")

  result_true <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod, sensitivity_run = TRUE)
  ))
  item_15_true <- result_true[result_true$Item == 15L, ]
  expect_equal(item_15_true$Status, "PASS")
})

# ============================================================================
# Test 8: Parameter toggle - has_flow_diagram
# ============================================================================

test_that("mysterycall_strobe_checklist: has_flow_diagram toggles item 10", {
  set.seed(8)

  mod <- make_fake_poisson()

  result_false <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod, has_flow_diagram = FALSE)
  ))
  item_10_false <- result_false[result_false$Item == 10L, ]
  expect_equal(item_10_false$Status, "WARN")

  result_true <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod, has_flow_diagram = TRUE)
  ))
  item_10_true <- result_true[result_true$Item == 10L, ]
  expect_equal(item_10_true$Status, "PASS")
})

# ============================================================================
# Test 9: CI and p-value detection
# ============================================================================

test_that("mysterycall_strobe_checklist: detects CI/p-val from irr_table columns", {
  set.seed(9)

  mod_all <- make_fake_poisson(has_ci = TRUE, has_pvals = TRUE)
  result_all <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod_all)
  ))
  item_12_all <- result_all[result_all$Item == 12L, ]
  item_13_all <- result_all[result_all$Item == 13L, ]
  expect_equal(item_12_all$Status, "PASS")
  expect_equal(item_13_all$Status, "PASS")

  # Without CI
  mod_no_ci <- make_fake_poisson(has_ci = FALSE, has_pvals = TRUE)
  result_no_ci <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod_no_ci)
  ))
  item_12_no_ci <- result_no_ci[result_no_ci$Item == 12L, ]
  expect_equal(item_12_no_ci$Status, "FAIL")

  # Without p-vals
  mod_no_pval <- make_fake_poisson(has_ci = TRUE, has_pvals = FALSE)
  result_no_pval <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod_no_pval)
  ))
  item_13_no_pval <- result_no_pval[result_no_pval$Item == 13L, ]
  expect_equal(item_13_no_pval$Status, "WARN")
})

# ============================================================================
# Test 10: Model type detection (item 7)
# ============================================================================

test_that("mysterycall_strobe_checklist: detects model class correctly (item 7)", {
  set.seed(10)

  poisson_mod <- make_fake_poisson()
  result_poisson <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(poisson_mod)
  ))
  item_7_pois <- result_poisson[result_poisson$Item == 7L, ]
  expect_equal(item_7_pois$Status, "PASS")
  expect_true(grepl("mysterycall_poisson_model", item_7_pois$Detail))

  nb_mod <- make_fake_nb()
  result_nb <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(nb_mod)
  ))
  item_7_nb <- result_nb[result_nb$Item == 7L, ]
  expect_equal(item_7_nb$Status, "PASS")
  expect_true(grepl("mysterycall_nb_model", item_7_nb$Detail))
})

# ============================================================================
# Test 11: NB model auto-passes item 9
# ============================================================================

test_that("mysterycall_strobe_checklist: NB model always passes item 9", {
  set.seed(11)

  nb_mod <- make_fake_nb()
  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(nb_mod)
  ))
  item_9 <- result[result$Item == 9L, ]
  expect_equal(item_9$Status, "PASS")
  expect_true(grepl("Negative binomial", item_9$Detail))
})

# ============================================================================
# Test 12: n_dropped detection (item 11)
# ============================================================================

test_that("mysterycall_strobe_checklist: detects n_dropped (item 11)", {
  set.seed(12)

  mod_with <- make_fake_poisson(has_n_dropped = TRUE)
  result_with <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod_with)
  ))
  item_11_with <- result_with[result_with$Item == 11L, ]
  expect_equal(item_11_with$Status, "PASS")
  expect_true(grepl("n_dropped = 4", item_11_with$Detail))

  mod_without <- make_fake_poisson(has_n_dropped = FALSE)
  result_without <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod_without)
  ))
  item_11_without <- result_without[result_without$Item == 11L, ]
  expect_equal(item_11_without$Status, "WARN")
})

# ============================================================================
# Test 13: print method - basic functionality
# ============================================================================

test_that("print.mysterycall_strobe_checklist: returns invisible, prints header", {
  set.seed(13)

  mod <- make_fake_poisson()
  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod)
  ))

  output <- capture.output(suppressWarnings(print(result)))

  # Should have header
  expect_true(any(grepl("STROBE Checklist", output)))
  # Should have summary line
  expect_true(any(grepl("Summary:", output)))
  # Should be long enough for 16 items
  expect_true(length(output) > 20L)
})

# ============================================================================
# Test 14: print method - summary counts
# ============================================================================

test_that("print.mysterycall_strobe_checklist: summary counts match Status column", {
  set.seed(14)

  mod <- make_fake_poisson(
    has_ci = TRUE,
    has_pvals = TRUE,
    has_overdispersion = TRUE,
    has_n_dropped = TRUE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(
      mod,
      sensitivity_run = TRUE,
      has_flow_diagram = TRUE
    )
  ))

  output <- capture.output(suppressWarnings(print(result)))
  summary_line <- grep("Summary:", output, value = TRUE)[1L]

  n_pass <- sum(result$Status == "PASS")
  n_warn <- sum(result$Status == "WARN")
  n_fail <- sum(result$Status == "FAIL")

  expect_true(grepl(sprintf("%d PASS", n_pass), summary_line))
  expect_true(grepl(sprintf("%d WARN", n_warn), summary_line))
  expect_true(grepl(sprintf("%d FAIL", n_fail), summary_line))
})

# ============================================================================
# Test 15: print method - invisibility
# ============================================================================

test_that("print.mysterycall_strobe_checklist: returns invisible object", {
  set.seed(15)

  mod <- make_fake_poisson()
  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_checklist(mod)
  ))

  # Capture output and check invisible return
  output_result <- suppressWarnings(print(result))
  expect_identical(output_result, result)
})
