# tests/testthat/test-validate-phone.R
#
# Unit tests for mysterycall_validate_phone()
# Covers: NANP structural rules, state-mismatch detection, vectorisation,
#         input validation, and custom NANP path.

library(testthat)

# ── helpers ───────────────────────────────────────────────────────────────────

# Minimal NANP CSV written to a temp file so tests run without the installed
# package data directory.
.write_nanp_csv <- function(path = tempfile(fileext = ".csv")) {
  writeLines(
    c("area_code,state",
      "303,CO", "720,CO", "719,CO",  # Colorado
      "212,NY", "646,NY",             # New York
      "312,IL",                        # Illinois
      "713,TX", "214,TX",             # Texas
      "800,toll-free",                 # toll-free (not state-specific)
      "900,premium"),                  # premium
    path
  )
  path
}

nanp_path <- .write_nanp_csv()

# Convenience wrapper so each test does not repeat `nanp_path`.
vp <- function(phone_str, practice_state = NULL) {
  mysterycall_validate_phone(phone_str,
                              practice_state = practice_state,
                              nanp_path      = nanp_path)
}

# ── 1. Return structure ───────────────────────────────────────────────────────

test_that("validate_phone: returns data frame with required columns", {
  result <- vp("(303) 555-1234")
  expect_s3_class(result, "data.frame")
  expect_true(all(c("phone_e164_valid", "phone_npa", "phone_state_from_npa",
                     "phone_area_code_matches_state", "phone_validity_flag") %in%
                    names(result)))
})

test_that("validate_phone: one row per input element (vectorised)", {
  phones <- c("(303) 555-1234", "212-555-0001", NA, "bad")
  result <- vp(phones)
  expect_equal(nrow(result), 4L)
})

# ── 2. Valid numbers ──────────────────────────────────────────────────────────

test_that("validate_phone: standard format '(NPA) NXX-XXXX' is valid", {
  result <- vp("(303) 555-1234")
  expect_true(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "valid")
  expect_equal(result$phone_npa, "303")
})

test_that("validate_phone: hyphen format 'NPA-NXX-XXXX' is valid", {
  result <- vp("303-555-1234")
  expect_true(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "valid")
})

test_that("validate_phone: dot format 'NPA.NXX.XXXX' is valid", {
  result <- vp("303.555.1234")
  expect_true(result$phone_e164_valid)
})

test_that("validate_phone: bare 10 digits is valid", {
  result <- vp("3035551234")
  expect_true(result$phone_e164_valid)
  expect_equal(result$phone_npa, "303")
})

test_that("validate_phone: '1' country-code prefix is stripped correctly", {
  result <- vp("13035551234")
  expect_true(result$phone_e164_valid)
  expect_equal(result$phone_npa, "303")
})

test_that("validate_phone: '+1' international prefix is stripped correctly", {
  result <- vp("+13035551234")
  expect_true(result$phone_e164_valid)
})

# ── 3. Missing / empty inputs ─────────────────────────────────────────────────

test_that("validate_phone: NA input → flag 'missing'", {
  result <- vp(NA_character_)
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "missing")
  expect_true(is.na(result$phone_npa))
})

test_that("validate_phone: empty string → flag 'missing'", {
  result <- vp("")
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "missing")
})

test_that("validate_phone: whitespace-only → flag 'missing'", {
  result <- vp("   ")
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "missing")
})

# ── 4. Format failures ────────────────────────────────────────────────────────

test_that("validate_phone: 7-digit local number → invalid_format", {
  result <- vp("555-1234")
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "invalid_format")
})

test_that("validate_phone: 9-digit number → invalid_format", {
  result <- vp("303555123")
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "invalid_format")
})

test_that("validate_phone: 11-digit non-+1 number → invalid_format", {
  result <- vp("23035551234")   # leading 2, not country code 1
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "invalid_format")
})

test_that("validate_phone: letters-only string → invalid_format", {
  result <- vp("CALL-NOW")
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "invalid_format")
})

# ── 5. NANP structural rule violations ───────────────────────────────────────

test_that("validate_phone: NPA first digit 0 → invalid_format (NPA rule)", {
  result <- vp("0235551234")   # NPA = 023 → first digit 0 violates NANP
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "invalid_format")
})

test_that("validate_phone: NPA first digit 1 → invalid_format (NPA rule)", {
  result <- vp("1235551234")   # After stripping country code '1', NPA = 235 ✓
  # But "1235551234" as raw 10 digits has NPA = 123 which starts with 1 — invalid
  # Note: leading 1 is treated as country code only when followed by 10 digits
  # so "1235551234" (10 digits) has NPA=123 (first digit 1 = invalid)
  expect_false(result$phone_e164_valid)
})

test_that("validate_phone: NXX = N11 (911) → invalid_format", {
  result <- vp("3039111234")   # NXX = 911 is a service code
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "invalid_format")
})

test_that("validate_phone: NXX = 411 → invalid_format", {
  result <- vp("3034111234")
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "invalid_format")
})

test_that("validate_phone: NXX = 211 → invalid_format", {
  result <- vp("3032111234")
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "invalid_format")
})

test_that("validate_phone: NXX first digit 0 → invalid_format", {
  result <- vp("3030001234")   # NXX = 000 → first digit 0
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "invalid_format")
})

test_that("validate_phone: NXX first digit 1 → invalid_format", {
  result <- vp("3031001234")   # NXX = 100 → first digit 1
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "invalid_format")
})

# ── 6. Area code lookup ───────────────────────────────────────────────────────

test_that("validate_phone: known area code → phone_state_from_npa populated", {
  result <- vp("(303) 555-1234")
  expect_equal(result$phone_state_from_npa, "CO")
})

test_that("validate_phone: unknown area code → flag 'unknown_area_code'", {
  # NPA 999 is not a real area code and not in our mini lookup
  result <- vp("9995551234")
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "unknown_area_code")
  expect_true(is.na(result$phone_state_from_npa))
})

# ── 7. State mismatch ─────────────────────────────────────────────────────────

test_that("validate_phone: matching state → flag 'valid'", {
  result <- vp("(303) 555-1234", practice_state = "CO")
  expect_true(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "valid")
  expect_true(result$phone_area_code_matches_state)
})

test_that("validate_phone: mismatched state → flag 'area_code_state_mismatch'", {
  # 303 is Colorado, but practice_state is New York
  result <- vp("(303) 555-1234", practice_state = "NY")
  expect_false(result$phone_e164_valid)
  expect_equal(result$phone_validity_flag, "area_code_state_mismatch")
  expect_false(result$phone_area_code_matches_state)
})

test_that("validate_phone: no practice_state → phone_area_code_matches_state is NA", {
  result <- vp("(303) 555-1234", practice_state = NULL)
  expect_true(is.na(result$phone_area_code_matches_state))
})

test_that("validate_phone: practice_state recycled for vectorised input", {
  phones <- c("3035551234", "2125550001")   # CO area code, NY area code
  result <- vp(phones, practice_state = "CO")
  expect_equal(nrow(result), 2L)
  expect_true(result$phone_area_code_matches_state[1])    # 303 matches CO
  expect_false(result$phone_area_code_matches_state[2])   # 212 does not match CO
})

# ── 8. Vectorised batch behaviour ─────────────────────────────────────────────

test_that("validate_phone: mixed valid/invalid batch returns correct flags", {
  phones <- c(
    "(720) 555-0101",   # valid CO
    "555-1234",         # invalid_format (7 digits)
    NA,                 # missing
    "9995551234"        # unknown_area_code
  )
  result <- vp(phones)
  expect_equal(result$phone_validity_flag,
               c("valid", "invalid_format", "missing", "unknown_area_code"))
  expect_equal(result$phone_e164_valid, c(TRUE, FALSE, FALSE, FALSE))
})

test_that("validate_phone: all-valid batch → all TRUE", {
  phones <- c("3035551234", "7205550001", "2125550123")
  result <- vp(phones)
  expect_true(all(result$phone_e164_valid))
})

# ── 9. Toll-free / premium ────────────────────────────────────────────────────

test_that("validate_phone: 800 toll-free number is structurally valid", {
  result <- vp("8005551234")
  expect_true(result$phone_e164_valid)
  expect_equal(result$phone_npa, "800")
  # state should be "toll-free" from our mini lookup
  expect_equal(result$phone_state_from_npa, "toll-free")
})

# ── 10. Edge: single-element character(0) ────────────────────────────────────

test_that("validate_phone: character(0) returns zero-row data frame", {
  result <- vp(character(0))
  expect_equal(nrow(result), 0L)
  expect_true("phone_validity_flag" %in% names(result))
})

# ── 11. Custom nanp_path ──────────────────────────────────────────────────────

test_that("validate_phone: custom nanp_path is honoured", {
  custom <- tempfile(fileext = ".csv")
  writeLines(c("area_code,state", "555,TEST"), custom)
  result <- mysterycall_validate_phone("5555550101", nanp_path = custom)
  expect_equal(result$phone_state_from_npa, "TEST")
})

test_that("validate_phone: bad nanp_path raises informative error", {
  expect_error(
    mysterycall_validate_phone("3035551234", nanp_path = "/no/such/file.csv"),
    "NANP area-code lookup not found"
  )
})

# ── 12. US territory primary area codes (regression: BUG 35) ──────────────────

# The bundled NANP lookup must include US territory PRIMARY area codes
# (787 Puerto Rico, 671 Guam, 340 US Virgin Islands), not only the PR overlay
# 939.  A valid number in one of these codes must validate against the shipped
# CSV rather than being flagged as an unknown area code.
test_that("validate_phone: 787 (Puerto Rico primary) validates against shipped CSV", {
  result <- mysterycall_validate_phone("(787) 555-1234", practice_state = "PR")
  expect_equal(result$phone_state_from_npa, "PR")
  expect_equal(result$phone_validity_flag, "valid")
  expect_true(result$phone_e164_valid)
})

test_that("validate_phone: 671 (Guam) and 340 (USVI) resolve to their territories", {
  guam <- mysterycall_validate_phone("(671) 555-1234", practice_state = "GU")
  expect_equal(guam$phone_state_from_npa, "GU")
  expect_equal(guam$phone_validity_flag, "valid")

  usvi <- mysterycall_validate_phone("(340) 555-1234", practice_state = "VI")
  expect_equal(usvi$phone_state_from_npa, "VI")
  expect_equal(usvi$phone_validity_flag, "valid")
})
