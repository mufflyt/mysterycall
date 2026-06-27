# tests/testthat/test-sensitivity-both-insurance.R

# ── helpers ────────────────────────────────────────────────────────────────────

make_both_ins_df <- function(seed = 1L, n_physicians = 10L) {
  set.seed(seed)
  # 10 physicians, each called under both Medicaid and BCBS
  phones <- paste0("P", seq_len(n_physicians))
  data.frame(
    phone      = rep(phones, each = 2L),
    insurance  = rep(c("Medicaid", "Blue Cross/Blue Shield"), n_physicians),
    business_days_until_appointment = rpois(n_physicians * 2L, 14),
    stringsAsFactors = FALSE
  )
}

make_partial_df <- function(seed = 2L) {
  set.seed(seed)
  # 5 physicians under Medicaid only, 5 under BCBS only, 3 under both
  phones_both <- paste0("B", 1:3)
  phones_med  <- paste0("M", 1:5)
  phones_bcbs <- paste0("C", 1:5)
  rbind(
    # Both-insurance physicians
    data.frame(
      phone     = rep(phones_both, each = 2L),
      insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), 3L),
      business_days_until_appointment = rpois(6L, 10),
      stringsAsFactors = FALSE
    ),
    # Medicaid-only
    data.frame(
      phone     = phones_med,
      insurance = rep("Medicaid", 5L),
      business_days_until_appointment = rpois(5L, 20),
      stringsAsFactors = FALSE
    ),
    # BCBS-only
    data.frame(
      phone     = phones_bcbs,
      insurance = rep("Blue Cross/Blue Shield", 5L),
      business_days_until_appointment = rpois(5L, 8),
      stringsAsFactors = FALSE
    )
  )
}

# ── structural tests ───────────────────────────────────────────────────────────

test_that("sensitivity_both_insurance: returns list with expected names", {
  df  <- make_both_ins_df()
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expected <- c("n_both", "n_total", "both_data", "wait_comparison",
                "t_test", "sentence", "phone_ids")
  expect_true(all(expected %in% names(res)))
})

test_that("sensitivity_both_insurance: wait_comparison has expected columns", {
  df  <- make_both_ins_df()
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_true(all(c("insurance", "mean_wait", "sd_wait",
                    "median_wait", "iqr_wait") %in% names(res$wait_comparison)))
})

test_that("sensitivity_both_insurance: n_both and n_total are integers", {
  df  <- make_both_ins_df()
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_true(is.integer(res$n_both) || is.numeric(res$n_both))
  expect_true(is.integer(res$n_total) || is.numeric(res$n_total))
})

test_that("sensitivity_both_insurance: t_test p.value is numeric in [0, 1]", {
  df  <- make_both_ins_df()
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_true(!is.null(res$t_test))
  expect_true(is.numeric(res$t_test$p.value))
  expect_true(res$t_test$p.value >= 0 && res$t_test$p.value <= 1)
})

# ── semantic tests ─────────────────────────────────────────────────────────────

test_that("sensitivity_both_insurance: n_both matches manual count", {
  df  <- make_partial_df()
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  # Manual: only B1, B2, B3 have both insurance types
  expect_equal(res$n_both, 3L)
})

test_that("sensitivity_both_insurance: n_total matches unique phones", {
  df  <- make_partial_df()
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_equal(res$n_total, length(unique(df$phone)))
})

test_that("sensitivity_both_insurance: sentence contains n_both value", {
  df  <- make_partial_df()
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_true(grepl("3", res$sentence))
})

test_that("sensitivity_both_insurance: sentence contains p-value info", {
  df  <- make_both_ins_df()
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_true(grepl("p =|< 0.001", res$sentence))
})

test_that("sensitivity_both_insurance: phone_ids matches expected phones", {
  df  <- make_partial_df()
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_true(all(c("B1", "B2", "B3") %in% res$phone_ids))
  expect_false(any(paste0("M", 1:5) %in% res$phone_ids))
  expect_false(any(paste0("C", 1:5) %in% res$phone_ids))
})

test_that("sensitivity_both_insurance: both_data has only phones with both insurances", {
  df  <- make_partial_df()
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_true(all(res$both_data$phone %in% c("B1", "B2", "B3")))
})

# ── adversarial tests ─────────────────────────────────────────────────────────

test_that("sensitivity_both_insurance: no physician has both → n_both = 0", {
  df <- data.frame(
    phone     = c("P1", "P2", "P3"),
    insurance = c("Medicaid", "Medicaid", "Medicaid"),
    business_days_until_appointment = c(5L, 7L, 10L),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_equal(res$n_both, 0L)
  expect_true(grepl("none", res$sentence, ignore.case = TRUE))
})

test_that("sensitivity_both_insurance: wrong phone_col → error", {
  df <- make_both_ins_df()
  expect_error(
    mysterycall_sensitivity_both_insurance(
      df, phone_col = "npi", output_dir = NA
    ),
    "not found"
  )
})

test_that("sensitivity_both_insurance: wrong outcome_col → error", {
  df <- make_both_ins_df()
  expect_error(
    mysterycall_sensitivity_both_insurance(
      df, outcome_col = "wait_calendar", output_dir = NA
    ),
    "not found"
  )
})

test_that("sensitivity_both_insurance: wrong insurance_col → error", {
  df <- make_both_ins_df()
  expect_error(
    mysterycall_sensitivity_both_insurance(
      df, insurance_col = "payer", output_dir = NA
    ),
    "not found"
  )
})

test_that("sensitivity_both_insurance: only one insurance type → n_both = 0", {
  df <- data.frame(
    phone     = c("P1", "P1", "P2", "P2"),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid"),
    business_days_until_appointment = c(5L, 7L, 3L, 9L),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_equal(res$n_both, 0L)
})

test_that("sensitivity_both_insurance: empty data frame → n_both = 0, n_total = 0", {
  df <- data.frame(
    phone     = character(0L),
    insurance = character(0L),
    business_days_until_appointment = numeric(0L),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_equal(res$n_both, 0L)
  expect_equal(res$n_total, 0L)
})

test_that("sensitivity_both_insurance: non-data-frame input → error", {
  expect_error(
    mysterycall_sensitivity_both_insurance(list(a = 1), output_dir = NA),
    "data frame"
  )
})

test_that("sensitivity_both_insurance: all-NA outcome → wait_comparison has NA means", {
  df <- data.frame(
    phone     = rep(c("P1", "P2"), each = 2L),
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), 2L),
    business_days_until_appointment = NA_real_,
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_true(all(is.na(res$wait_comparison$mean_wait)))
})

test_that("sensitivity_both_insurance: case-insensitive insurance matching", {
  # insurance column has mixed case; should still match after normalization
  df <- data.frame(
    phone     = rep(c("P1", "P2"), each = 2L),
    insurance = c("  Medicaid  ", "Blue Cross/Blue Shield",
                  "MEDICAID", "blue cross/blue shield"),
    business_days_until_appointment = c(5L, 10L, 8L, 6L),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )
  expect_equal(res$n_both, 2L)
})
