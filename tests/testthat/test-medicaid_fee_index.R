library(testthat)

# ---------------------------------------------------------------------------
# Semantic: the function returns the AUTHORITATIVE KFF 2024 values and the
# output means what the docs claim.
# ---------------------------------------------------------------------------

test_that("known 2024 KFF values are returned exactly", {
  # Spot-check values against the packaged dataset / KFF 2024 All Services.
  expect_equal(mysterycall_medicaid_fee_index("CA"), 0.67)
  expect_equal(mysterycall_medicaid_fee_index("NJ"), 0.61)
  expect_equal(mysterycall_medicaid_fee_index("FL"), 0.64)
  expect_equal(mysterycall_medicaid_fee_index("MT"), 1.32)  # highest
  expect_equal(mysterycall_medicaid_fee_index("RI"), 0.52)  # lowest non-NA
})

test_that("function value equals the dataset value for every state", {
  data(medicaid_fee_index, package = "mysterycall")
  have <- medicaid_fee_index[!is.na(medicaid_fee_index$fee_index), ]
  got  <- mysterycall_medicaid_fee_index(have$state_abb, fallback = NA)
  expect_equal(got, have$fee_index)
})

test_that("output length and order match the input exactly", {
  inp <- c("CA", "NY", "TX", "CA")
  out <- mysterycall_medicaid_fee_index(inp)
  expect_length(out, length(inp))
  expect_equal(out[1], out[4])                 # duplicate CA -> same value
  expect_type(out, "double")
  expect_null(names(out))                       # unnamed per contract
})

test_that("Tennessee is genuinely NA and controllable via fallback", {
  # Default fallback = national average (0.75)
  expect_equal(mysterycall_medicaid_fee_index("TN"), 0.75)
  # fallback = NA preserves the true missingness
  expect_true(is.na(mysterycall_medicaid_fee_index("TN", fallback = NA)))
})

test_that("default fallback equals the dataset national average attribute", {
  data(medicaid_fee_index, package = "mysterycall")
  natl <- attr(medicaid_fee_index, "national_average")
  expect_equal(mysterycall_medicaid_fee_index("ZZ"), natl)
})

# ---------------------------------------------------------------------------
# Adversarial: malformed, hostile, and boundary inputs must not crash or lie.
# ---------------------------------------------------------------------------

test_that("empty input returns empty numeric, not an error", {
  out <- mysterycall_medicaid_fee_index(character(0))
  expect_type(out, "double")
  expect_length(out, 0L)
})

test_that("case- and whitespace-insensitive lookup", {
  expect_equal(mysterycall_medicaid_fee_index(c(" ca ", "Ny", "tX")),
               mysterycall_medicaid_fee_index(c("CA", "NY", "TX")))
})

test_that("invalid / non-state tokens fall back, never error", {
  bad <- c("ZZ", "", "123", "California", "U.S.", "USA", "  ", "C")
  out <- suppressWarnings(mysterycall_medicaid_fee_index(bad))
  expect_length(out, length(bad))
  expect_true(all(out == 0.75))                 # all filled with national avg
})

test_that("NA and factor inputs are coerced, not fatal", {
  expect_equal(mysterycall_medicaid_fee_index(NA, fallback = NA), NA_real_)
  f <- factor(c("CA", "NJ"))
  expect_equal(mysterycall_medicaid_fee_index(f), c(0.67, 0.61))
})

test_that("numeric input is coerced to character (and falls back)", {
  expect_equal(mysterycall_medicaid_fee_index(6, fallback = -1), -1)
})

test_that("fallback is validated", {
  expect_error(mysterycall_medicaid_fee_index("CA", fallback = c(1, 2)),
               "single numeric value or NA")
  expect_error(mysterycall_medicaid_fee_index("CA", fallback = "high"),
               "single numeric value or NA")
})

test_that("custom fallback is applied only where data is absent", {
  out <- mysterycall_medicaid_fee_index(c("CA", "TN", "ZZ"), fallback = -99)
  expect_equal(out, c(0.67, -99, -99))          # real value kept; TN + invalid filled
})

test_that("large vector is handled and never introduces stray NA", {
  big <- rep(c("CA", "NJ", "TN", "ZZ"), 500)
  out <- mysterycall_medicaid_fee_index(big)
  expect_length(out, 2000L)
  expect_false(anyNA(out))                       # default fallback fills TN + ZZ
})

# ---------------------------------------------------------------------------
# Semantic: dataset integrity (medicaid_fee_index + kff_hhi are factual data).
# ---------------------------------------------------------------------------

test_that("medicaid_fee_index dataset is complete and well-formed", {
  data(medicaid_fee_index, package = "mysterycall")
  expect_equal(nrow(medicaid_fee_index), 51L)               # 50 states + DC
  expect_equal(sum(is.na(medicaid_fee_index$fee_index)), 1L) # only Tennessee
  expect_true(is.na(medicaid_fee_index$fee_index[medicaid_fee_index$state_abb == "TN"]))
  expect_false(anyDuplicated(medicaid_fee_index$state_abb) > 0)
  # plausible index range (KFF historically ~0.3-1.5)
  fi <- medicaid_fee_index$fee_index
  expect_true(all(fi >= 0.3 & fi <= 1.5, na.rm = TRUE))
  # at_or_above_medicare must be consistent with the ratio
  ok <- medicaid_fee_index$at_or_above_medicare == (fi >= 1)
  expect_true(all(ok, na.rm = TRUE))
  expect_equal(attr(medicaid_fee_index, "national_average"), 0.75)
})

test_that("kff_hhi dataset is complete and within HHI bounds", {
  data(kff_hhi, package = "mysterycall")
  expect_equal(nrow(kff_hhi), 387L)
  expect_true(all(kff_hhi$hhi >= 0 & kff_hhi$hhi <= 10000))
  expect_false(anyNA(kff_hhi$msa))
  expect_false(anyNA(kff_hhi$hhi))
  # shares are proportions in [0, 1]
  expect_true(all(kff_hhi$largest_system_share >= 0 &
                    kff_hhi$largest_system_share <= 1, na.rm = TRUE))
  # hhi_cat thresholds line up with hhi (DOJ/FTC 1000/1800)
  expect_true(all((kff_hhi$hhi > 1800) == (kff_hhi$hhi_cat == "high"), na.rm = TRUE))
  expect_true(is.ordered(kff_hhi$hhi_cat))
})
