test_that("returns list of class mysterycall_acceptance_rate_calc", {
  df <- data.frame(
    phone     = paste0("P", 1:6),
    insurance = rep(c("Medicaid", "Private"), each = 3L),
    reason_for_exclusions           = rep("Able to contact", 6L),
    business_days_until_appointment = rep(5L, 6L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_acceptance_rate_calc(df)
  expect_true(inherits(res, "mysterycall_acceptance_rate_calc"))
  expect_true(is.list(res))
})

test_that("table has expected columns: insurance, n_numerator, n_denominator, rate_pct", {
  df <- data.frame(
    phone     = paste0("P", 1:6),
    insurance = rep(c("Medicaid", "Private"), each = 3L),
    reason_for_exclusions           = rep("Able to contact", 6L),
    business_days_until_appointment = rep(5L, 6L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_acceptance_rate_calc(df)
  required <- c("insurance", "n_numerator", "n_denominator", "rate_pct",
                "ci_lower_pct", "ci_upper_pct", "sentence")
  expect_true(all(required %in% names(res$table)))
})

test_that("rate_pct is always in [0, 100]", {
  df <- data.frame(
    phone     = paste0("P", 1:10),
    insurance = rep(c("Medicaid", "Private"), each = 5L),
    reason_for_exclusions = c(
      "Able to contact", "No answer", "Able to contact", "No answer", "Able to contact",
      "Able to contact", "Able to contact", "No answer", "Able to contact", "Able to contact"
    ),
    business_days_until_appointment = c(5L, 0L, 10L, 0L, 3L, 7L, 0L, 5L, 8L, 2L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_acceptance_rate_calc(df)
  rates <- res$table$rate_pct[!is.na(res$table$rate_pct)]
  expect_true(all(rates >= 0 & rates <= 100))
})

test_that("Wilson CI bounds are numeric and lower <= upper", {
  df <- data.frame(
    phone     = paste0("P", 1:6),
    insurance = rep(c("Medicaid", "Private"), each = 3L),
    reason_for_exclusions           = rep("Able to contact", 6L),
    business_days_until_appointment = rep(5L, 6L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_acceptance_rate_calc(df)
  expect_true(is.numeric(res$table$ci_lower_pct))
  expect_true(is.numeric(res$table$ci_upper_pct))
  lo <- res$table$ci_lower_pct[!is.na(res$table$ci_lower_pct)]
  hi <- res$table$ci_upper_pct[!is.na(res$table$ci_upper_pct)]
  expect_true(all(lo <= hi))
})

test_that("sentences element is a character vector with one entry per group", {
  df <- data.frame(
    phone     = paste0("P", 1:6),
    insurance = rep(c("Medicaid", "Private"), each = 3L),
    reason_for_exclusions           = rep("Able to contact", 6L),
    business_days_until_appointment = rep(5L, 6L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_acceptance_rate_calc(df)
  expect_true(is.character(res$sentences))
  expect_equal(length(res$sentences), 2L)
})

test_that("gap_sentence is a single non-NA character when exactly 2 groups", {
  # Give groups different rates so gap is nonzero
  df <- data.frame(
    phone     = paste0("P", 1:10),
    insurance = rep(c("Medicaid", "Private"), each = 5L),
    reason_for_exclusions = c(
      rep("Able to contact", 3L), rep("No answer", 2L),
      rep("Able to contact", 5L)
    ),
    business_days_until_appointment = c(5L, 10L, 3L, 0L, 0L, 7L, 8L, 6L, 4L, 9L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_acceptance_rate_calc(df)
  expect_true(is.character(res$gap_sentence))
  expect_equal(length(res$gap_sentence), 1L)
  expect_false(is.na(res$gap_sentence))
})

test_that("single insurance group: gap_sentence is NA and overall is NULL", {
  df <- data.frame(
    phone     = paste0("P", 1:4),
    insurance = rep("Medicaid", 4L),
    reason_for_exclusions           = c("Able to contact", "Able to contact",
                                        "No answer", "Able to contact"),
    business_days_until_appointment = c(5L, 10L, 0L, 3L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  expect_true(is.na(res$gap_sentence))
  expect_null(res$overall)
  expect_equal(nrow(res$table), 1L)
})

test_that("deduplication by id_col reduces count when same physician appears twice", {
  # P1 appears twice in Medicaid; should count as 1 physician in all tallies
  df <- data.frame(
    phone     = c("P1", "P1", "P2", "P3"),
    insurance = rep("Medicaid", 4L),
    reason_for_exclusions           = rep("Able to contact", 4L),
    business_days_until_appointment = c(5L, 10L, 7L, 3L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  # Distinct IDs: P1, P2, P3 -> n_total = 3 (not 4)
  expect_equal(res$table$n_total, 3L)
  # All contacted and wait > 0 -> n_numerator = 3
  expect_equal(res$table$n_numerator, 3L)
})

test_that("rows with wait_col == 0 are excluded from numerator but kept in denominator", {
  # P1 has wait=0: reachable (denominator) but no appointment (not numerator)
  df <- data.frame(
    phone     = c("P1", "P2", "P3"),
    insurance = rep("Medicaid", 3L),
    reason_for_exclusions           = rep("Able to contact", 3L),
    business_days_until_appointment = c(0L, 5L, 8L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  expect_equal(res$table$n_denominator, 3L)
  expect_equal(res$table$n_numerator, 2L)
  expect_equal(res$table$rate_pct, 2 / 3 * 100)
})

test_that("rows with inclusion_col != inclusion_value are excluded from denominator", {
  # P1: not contacted -> excluded (not in denominator or numerator)
  # P2, P3: contacted with appointments -> in both
  df <- data.frame(
    phone     = c("P1", "P2", "P3"),
    insurance = rep("Medicaid", 3L),
    reason_for_exclusions           = c("No answer", "Able to contact", "Able to contact"),
    business_days_until_appointment = c(0L, 5L, 8L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  expect_equal(res$table$n_total, 3L)
  expect_equal(res$table$n_excluded, 1L)
  expect_equal(res$table$n_denominator, 2L)
  expect_equal(res$table$n_numerator, 2L)
  expect_equal(res$table$rate_pct, 100)
})

test_that("error when insurance_col not in data", {
  df <- data.frame(
    phone        = paste0("P", 1:4),
    ins_type     = rep("Medicaid", 4L),
    reason_for_exclusions           = rep("Able to contact", 4L),
    business_days_until_appointment = rep(5L, 4L),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_acceptance_rate_calc(df, insurance_col = "insurance"),
    "insurance_col 'insurance' not found"
  )
})

test_that("error when id_col not in data", {
  df <- data.frame(
    phone     = paste0("P", 1:4),
    insurance = rep("Medicaid", 4L),
    reason_for_exclusions           = rep("Able to contact", 4L),
    business_days_until_appointment = rep(5L, 4L),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_acceptance_rate_calc(df, id_col = "npi"),
    "id_col 'npi' not found"
  )
})

test_that("print method returns x invisibly and writes sentences to console", {
  df <- data.frame(
    phone     = paste0("P", 1:6),
    insurance = rep(c("Medicaid", "Private"), each = 3L),
    reason_for_exclusions           = rep("Able to contact", 6L),
    business_days_until_appointment = rep(5L, 6L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_acceptance_rate_calc(df)
  out <- capture.output(ret <- print(res))
  expect_identical(ret, res)
  expect_true(length(out) > 0L)
  expect_true(any(grepl("acceptance rate", out, fixed = TRUE)))
})

test_that("medicaid_screen_group restricts the NA-screen to the named group", {
  # Medicaid-only accept field is NA on BCBS rows, as in real data (BUG 28).
  df <- data.frame(
    phone = c("p1", "p2", "p3", "p4"),
    insurance = c("Blue Cross/Blue Shield", "Blue Cross/Blue Shield",
                  "Medicaid", "Medicaid"),
    reason_for_exclusions = rep("Able to contact", 4L),
    business_days_until_appointment = c(5L, 8L, 6L, 4L),
    does_the_physician_accept_medicaid = c(NA, NA, "Yes", "Yes"),
    stringsAsFactors = FALSE
  )
  grp <- c("Medicaid", "Blue Cross/Blue Shield")

  # Default: screen every group -> BCBS numerator wrongly zeroed by the NA field.
  all_screen <- mysterycall_acceptance_rate_calc(
    df, insurance_groups = grp,
    medicaid_accept_col = "does_the_physician_accept_medicaid"
  )
  bcbs_all <- all_screen$table[all_screen$table$insurance ==
                                 "Blue Cross/Blue Shield", ]
  expect_equal(bcbs_all$n_numerator, 0L)

  # Restricted: only Medicaid is screened -> BCBS counts both, matching the
  # legacy mysterycall_insurance_acceptance_rates() behavior.
  med_only <- mysterycall_acceptance_rate_calc(
    df, insurance_groups = grp,
    medicaid_accept_col = "does_the_physician_accept_medicaid",
    medicaid_screen_group = "Medicaid"
  )
  bcbs <- med_only$table[med_only$table$insurance == "Blue Cross/Blue Shield", ]
  med  <- med_only$table[med_only$table$insurance == "Medicaid", ]
  expect_equal(bcbs$n_numerator, 2L)
  expect_equal(bcbs$rate_pct, 100)
  expect_equal(med$n_numerator, 2L)
})

test_that("medicaid_screen_group validates its type", {
  df <- data.frame(
    phone = "p1", insurance = "Medicaid",
    reason_for_exclusions = "Able to contact",
    business_days_until_appointment = 5L,
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_acceptance_rate_calc(df, medicaid_screen_group = 1L),
    "character"
  )
})
