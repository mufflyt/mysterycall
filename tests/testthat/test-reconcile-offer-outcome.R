# Tests for mysterycall_reconcile_offer_outcome()

recon_data <- function() {
  data.frame(
    record_id           = 1:6,
    appointment_offered = c(FALSE, TRUE, TRUE, FALSE, TRUE, FALSE),
    appointment_outcome = c("With sampled physician",   # understated
                            "No appointment offered",    # overstated
                            "With sampled physician",    # concordant TRUE
                            "No appointment offered",    # concordant FALSE
                            "With different physician",  # not in either set -> ignore
                            "Referred elsewhere"),       # not in either set -> ignore
    wait_days_business  = c(10, 5, 8, NA, 3, NA),
    appointment_date    = c("2026-02-01", "2026-01-15", "2026-03-01", NA,
                            "2026-02-20", NA),
    stringsAsFactors = FALSE
  )
}

off  <- "With sampled physician"
noff <- "No appointment offered"

test_that("flag action detects both discordance directions without mutating data", {
  d <- recon_data()
  res <- mysterycall_reconcile_offer_outcome(
    d, "appointment_offered", "appointment_outcome",
    offered_values = off, not_offered_values = noff,
    id_col = "record_id")
  expect_s3_class(res, "mysterycall_offer_reconciliation")
  expect_equal(res$n_understated, 1L)
  expect_equal(res$n_overstated, 1L)
  expect_equal(nrow(res$discordant), 2L)
  # data unchanged under flag
  expect_identical(res$data, d)
  expect_setequal(res$discordant$record_id, c(1L, 2L))
  expect_setequal(res$discordant$direction,
                  c("flag_understates", "flag_overstates"))
})

test_that("fix flips both directions and clears dependent cols on overstated rows", {
  d <- recon_data()
  res <- mysterycall_reconcile_offer_outcome(
    d, "appointment_offered", "appointment_outcome",
    offered_values = off, not_offered_values = noff,
    dependent_cols = c("wait_days_business", "appointment_date"),
    action = "fix", id_col = "record_id")
  out <- res$data
  # row 1 understated -> now TRUE
  expect_true(out$appointment_offered[1])
  # row 2 overstated -> now FALSE, dependent cols cleared
  expect_false(out$appointment_offered[2])
  expect_true(is.na(out$wait_days_business[2]))
  expect_true(is.na(out$appointment_date[2]))
  # concordant / ignored rows untouched
  expect_true(out$appointment_offered[3])
  expect_false(out$appointment_offered[4])
  expect_equal(out$wait_days_business[5], 3)   # different physician untouched
})

test_that("character flag columns keep their type after a fix", {
  d <- recon_data()
  d$appointment_offered <- as.character(d$appointment_offered)  # "TRUE"/"FALSE"
  res <- mysterycall_reconcile_offer_outcome(
    d, "appointment_offered", "appointment_outcome",
    offered_values = off, not_offered_values = noff, action = "fix")
  expect_type(res$data$appointment_offered, "character")
  expect_identical(res$data$appointment_offered[1], "TRUE")
  expect_identical(res$data$appointment_offered[2], "FALSE")
})

test_that("clear_value = '' blanks character dependent columns", {
  d <- recon_data()
  d$appointment_date <- as.character(d$appointment_date)
  res <- mysterycall_reconcile_offer_outcome(
    d, "appointment_offered", "appointment_outcome",
    offered_values = off, not_offered_values = noff,
    dependent_cols = "appointment_date", action = "fix", clear_value = "")
  expect_identical(res$data$appointment_date[2], "")
})

test_that("no discordance yields empty report and unchanged data", {
  d <- data.frame(
    appointment_offered = c(TRUE, FALSE),
    appointment_outcome = c(off, noff),
    stringsAsFactors = FALSE)
  res <- mysterycall_reconcile_offer_outcome(
    d, "appointment_offered", "appointment_outcome",
    offered_values = off, not_offered_values = noff, action = "fix")
  expect_equal(nrow(res$discordant), 0L)
  expect_identical(res$data, d)
})

test_that("overlapping offered/not_offered value sets error", {
  d <- recon_data()
  expect_error(
    mysterycall_reconcile_offer_outcome(
      d, "appointment_offered", "appointment_outcome",
      offered_values = c(off, noff), not_offered_values = noff),
    "overlap"
  )
})

test_that("NA outcomes are ignored", {
  d <- recon_data()
  d$appointment_outcome[1] <- NA
  res <- mysterycall_reconcile_offer_outcome(
    d, "appointment_offered", "appointment_outcome",
    offered_values = off, not_offered_values = noff)
  expect_equal(res$n_understated, 0L)  # the one understated row is now NA
})

test_that("as.data.frame returns the discordance report", {
  d <- recon_data()
  res <- mysterycall_reconcile_offer_outcome(
    d, "appointment_offered", "appointment_outcome",
    offered_values = off, not_offered_values = noff)
  df <- as.data.frame(res)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2L)
})
