library(testthat)

# ---------------------------------------------------------------------------
# Input validation (no network required).
# ---------------------------------------------------------------------------

test_that("year is validated before any API call", {
  expect_error(
    mysterycall_get_acs_female_insurance("key", "08", "031", year = 1990),
    "2012-2023"
  )
  expect_error(
    mysterycall_get_acs_female_insurance("key", "08", "031", year = "2022"),
    "2012-2023"
  )
})

# ---------------------------------------------------------------------------
# Live semantic check: the shares are REAL and mean what the docs claim.
# Skipped off-CRAN / offline / without a key so CI stays green.
# ---------------------------------------------------------------------------

has_census <- function() {
  nzchar(Sys.getenv("CENSUS_API_KEY")) &&
    requireNamespace("tidycensus", quietly = TRUE)
}

test_that("female shares are built from real sex-by-coverage tables", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not(has_census(), "CENSUS_API_KEY / tidycensus not available")

  df <- mysterycall_get_acs_female_insurance(
    Sys.getenv("CENSUS_API_KEY"), "08", "031", year = 2022
  )

  # One row per Denver County tract, expected coverage columns present.
  expect_gt(nrow(df), 100)
  expect_true(all(c("Total_Females", "Pct_Female_Private", "Pct_Female_Public",
                    "Pct_Female_Medicaid", "Pct_Female_Medicare",
                    "Pct_Female_Uninsured") %in% names(df)))

  # Every share is a genuine percentage of the female population.
  pct <- df[, grep("^Pct_Female", names(df))]
  expect_true(all(vapply(pct, function(x) all(x >= 0 & x <= 100, na.rm = TRUE),
                         logical(1))))

  # Uninsured column is NOT all-NA (the old S2701 version always returned NA).
  expect_false(all(is.na(df$Pct_Female_Uninsured)))

  # Insured (private OR public, but they overlap) never exceeds a sane ceiling;
  # insured + uninsured must be internally consistent, so uninsured stays low.
  expect_lt(stats::median(df$Pct_Female_Uninsured, na.rm = TRUE), 40)

  # Medicaid and Medicare come from the C-series tables and are non-trivial.
  expect_gt(stats::median(df$Pct_Female_Medicaid, na.rm = TRUE), 0)
  expect_gt(stats::median(df$Pct_Female_Medicare, na.rm = TRUE), 0)

  # MOEs are propagated (present and non-negative).
  expect_true("N_Female_Medicaid_moe" %in% names(df))
  expect_true(all(df$N_Female_Medicaid_moe >= 0, na.rm = TRUE))
})
