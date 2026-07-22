library(testthat)

# ─────────────────────────────────────────────────────────────────────────────
# Decision: a REACHED office that declined counts in the acceptance-rate
# denominator. denominator = reached = total - unreachable, so
# acceptance_rate_calc()'s denominator must equal exclusion_summary()'s
# n_reached, and a "Not accepting new patients" office must NOT be deleted
# from the denominator (which previously inflated the rate to 100%).
# ─────────────────────────────────────────────────────────────────────────────

recon_df <- function() {
  data.frame(
    phone     = c("p1", "p2", "p3", "p4"),
    insurance = rep("Medicaid", 4),
    reason_for_exclusions = c(
      "Able to contact",              # reached + accepted
      "Able to contact",              # reached + accepted
      "Not accepting new patients",   # reached, declined -> in denominator
      "Went to voicemail"             # unreachable -> excluded
    ),
    business_days_until_appointment = c(10, 5, NA, NA),
    stringsAsFactors = FALSE
  )
}

test_that("not-accepting offices stay in the denominator (rate is 2/3, not 2/2)", {
  skip_if_not_installed("dplyr")
  res <- suppressWarnings(suppressMessages(
    mysterycall_acceptance_rate_calc(recon_df(), insurance_groups = "Medicaid")
  ))
  row <- res$table[res$table$insurance == "Medicaid", ]
  expect_equal(row$n_numerator, 2)
  expect_equal(row$n_denominator, 3)          # was 2 before the fix
  expect_equal(round(row$rate_pct, 1), 66.7)  # was 100.0 before the fix
})

test_that("acceptance_rate_calc denominator == exclusion_summary n_reached", {
  skip_if_not_installed("dplyr")
  df <- recon_df()
  ar <- suppressWarnings(suppressMessages(
    mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  ))
  es <- suppressWarnings(suppressMessages(
    mysterycall_exclusion_summary(df, id_col = "phone")
  ))
  ar_denom <- ar$table$n_denominator[ar$table$insurance == "Medicaid"]
  expect_equal(ar_denom, es$n_reached)        # one shared definition of "reached"
})

test_that("a genuinely-unreachable reason (e.g. 'No answer') stays excluded", {
  skip_if_not_installed("dplyr")
  # 'No answer' is non-contact and NOT a reached-but-declined reason -> excluded,
  # exactly as before. Only the three reached-but-declined reasons move into the
  # denominator; the fix is minimal, not a blanket denominator change.
  df <- data.frame(
    phone     = c("p1", "p2", "p3"),
    insurance = rep("Medicaid", 3),
    reason_for_exclusions = c("Able to contact", "Able to contact", "No answer"),
    business_days_until_appointment = c(5, 8, NA),
    stringsAsFactors = FALSE
  )
  res <- suppressWarnings(suppressMessages(
    mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  ))
  row <- res$table[res$table$insurance == "Medicaid", ]
  expect_equal(row$n_excluded, 1)      # p3 'No answer' still excluded
  expect_equal(row$n_denominator, 2)
})

test_that("reached_declined_reasons is the shared source", {
  expect_length(mysterycall_reached_declined_reasons(), 3)
  expect_true("Not accepting new patients" %in% mysterycall_reached_declined_reasons())
})
