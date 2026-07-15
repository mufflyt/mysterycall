library(testthat)

# Regression tests for the wave-1 source audit fixes (BUGS.md bugs 5-21) that
# were applied directly (agent-authored tests cover bugs 22-47).

# --- BUG 15: numeric ZIP with a leading zero must not become NA ---------------
test_that("normalize_zip5 left-pads numeric ZIPs (leading zero preserved)", {
  expect_equal(mysterycall:::mysterycall_normalize_zip5(7001), "07001")
  expect_equal(mysterycall:::mysterycall_normalize_zip5(90210), "90210")
  expect_equal(mysterycall:::mysterycall_normalize_zip5("80111-1234"), "80111")
  expect_true(is.na(mysterycall:::mysterycall_normalize_zip5("abc")))
})

# --- BUG 19: ZIP+4 with a dropped leading zero must not grab a +4 digit -------
test_that("extract_zip5 strips the +4 suffix before taking 5 digits", {
  expect_equal(mysterycall:::mysterycall_extract_zip5("7001-1234"), "07001")
  expect_equal(mysterycall:::mysterycall_extract_zip5("80203-1234"), "80203")
  expect_equal(mysterycall:::mysterycall_extract_zip5("00501"), "00501")
  expect_equal(mysterycall:::mysterycall_extract_zip5("07001-1234"), "07001")
})

# --- BUG 20: a graduation year after the reference year yields NA age ---------
test_that("impute_age returns NA for future graduation years", {
  expect_true(is.na(suppressMessages(
    mysterycall_impute_age(2027, ref_year = 2026)
  )))
  # a normal past grad year still resolves
  expect_equal(
    suppressWarnings(mysterycall_impute_age(2000, ref_year = 2026, age_offset = 27L)),
    53L
  )
})

# --- BUG 17: default gt column label typo fixed -------------------------------
test_that("irr_table default outcome_label is 'IRR (95% CI)'", {
  expect_equal(formals(mysterycall_irr_table)$outcome_label, "IRR (95% CI)")
})

# --- BUG 13: intro only claims significance when a level clears alpha ---------
test_that("write_results_paragraph gates the significance claim on the data", {
  ns <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    irr      = c(1.0, 1.05), ci_lower = c(NA, 0.90), ci_upper = c(NA, 1.22),
    p_value  = c(NA, 0.40), stringsAsFactors = FALSE
  )
  expect_match(
    mysterycall_write_results_paragraph(ns, "BCBS", "insurance"),
    "was not significantly associated"
  )

  sig <- ns
  sig$p_value <- c(NA, 0.001)
  sig$ci_lower <- c(NA, 1.10)
  out_sig <- mysterycall_write_results_paragraph(sig, "BCBS", "insurance")
  expect_match(out_sig, "was significantly associated")
  expect_false(grepl("was not significantly", out_sig))
})
