# Adversarial tests for the SSOT-consolidation fixes:
#   * mysterycall_luhn_check now shares mysterynpi::npi_luhn_ok()'s algorithm
#   * .safe_divide is vectorised
#   * physician-name parsing delegates ordering decisions to mysterynpi
#   * state normalisation delegates to mufflyaccess
#   * the three ZIP-5 normalisers share one core
# Each test is written against the failure mode the fix eliminated, not the
# happy path.

library(testthat)

# ── 1. NPI Luhn ───────────────────────────────────────────────────────────────

test_that("adversarial: checksum-passing strings with impossible leading digits are NOT NPIs", {
  # "0103000788" passes the raw Luhn checksum -- the old implementation accepted
  # it. CMS has never issued an NPI beginning with 0, so it cannot be one.
  expect_false(mysterycall:::mysterycall_luhn_check("0103000788"))
  # agreement with the SSOT on a mixed vector, element by element
  v <- c("1962780445", "1234567890", "9876543210", "0103000788", "1396113270")
  expect_equal(
    unname(mysterycall:::mysterycall_luhn_check(v)),
    unname(mysterynpi::npi_luhn_ok(v))
  )
})

test_that("adversarial: single-digit mutation of a valid NPI is always rejected", {
  # Luhn's entire point: EVERY single-digit substitution breaks the checksum.
  # If any mutation passes, the parity of the implementation is wrong.
  valid <- "1234567893"
  for (pos in 1:10) {
    for (d in setdiff(0:9, as.integer(substr(valid, pos, pos)))) {
      mutated <- valid
      substr(mutated, pos, pos) <- as.character(d)
      expect_false(mysterycall:::mysterycall_luhn_check(mutated),
                   info = paste("mutation at pos", pos, "to digit", d, "must fail"))
    }
  }
})

test_that("adversarial: validate_npi and luhn_check can never disagree", {
  df <- data.frame(npi = c("1234567893", "0103000788", "123-456-7893"), stringsAsFactors = FALSE)
  out <- suppressMessages(mysterycall_validate_npi(df))
  # "0103000788" is 10 digits and checksum-valid but leading-digit invalid:
  # both paths must now reject it.
  expect_false("0103000788" %in% out$npi)
  expect_true("1234567893" %in% out$npi)
  expect_equal(nrow(out), 2L)  # the punctuated spelling of the same valid NPI survives
})

test_that("adversarial: luhn edge inputs never error and never return NA", {
  res <- mysterycall:::mysterycall_luhn_check(c(NA, "", " ", "----------", "0000000000", 1e9, "1e+10"))
  expect_true(all(!is.na(res)))
  expect_length(res, 7L)
})

# ── 2. .safe_divide ───────────────────────────────────────────────────────────

test_that("adversarial: vector input no longer errors (the original bug)", {
  expect_no_error(mysterycall:::.safe_divide(c(1, 2, 3), c(1, 0, 2)))
  expect_equal(mysterycall:::.safe_divide(c(1, 2, 3), c(1, 0, 2)), c(1, NA, 1.5))
})

test_that("adversarial: elementwise default and NA handling in long vectors", {
  den <- c(0, NA, 2, 0, 5)
  num <- c(10, 20, 30, 40, 50)
  expect_equal(mysterycall:::.safe_divide(num, den), c(NA, NA, 15, NA, 10))
  expect_equal(mysterycall:::.safe_divide(num, den, default = 0), c(0, 0, 15, 0, 10))
  # scalar-recycled denominator against vector numerator
  expect_equal(mysterycall:::.safe_divide(c(2, 4, 6), 2), c(1, 2, 3))
  # zero-length input stays zero-length
  expect_length(mysterycall:::.safe_divide(numeric(0), numeric(0)), 0L)
  # scalar callers (the join-coverage path) are unchanged
  expect_equal(mysterycall:::.safe_divide(3, 4), 0.75)
  expect_true(is.na(mysterycall:::.safe_divide(3, 0)))
})

# ── 3. physician-name parsing ─────────────────────────────────────────────────

test_that("adversarial: parenthetical nickname never contaminates middle or last name", {
  r <- mysterycall_parse_physician_name("Cynthia (Cindi) A. Smith")
  expect_equal(r$first_name, "Cynthia")
  expect_equal(r$last_name, "Smith")
  expect_false(grepl("Cindi", paste(r$middle_name, r$last_name, collapse = " ")))
})

test_that("adversarial: parenthetical maiden name never becomes the surname", {
  r <- mysterycall_parse_physician_name("Ann M. Barbaccia (Pollack), M.D.")
  expect_equal(r$last_name, "Barbaccia")
  expect_false(grepl("Pollack", paste(r$first_name, r$middle_name, r$last_name, collapse = " ")))
  expect_true(grepl("M.D.", r$suffix))
})

test_that("adversarial: generational suffix captured with and without comma, case preserved", {
  expect_equal(mysterycall_parse_physician_name("Smith, John, Jr.")$suffix, "Jr.")
  expect_equal(mysterycall_parse_physician_name("Robert Brown Jr.")$suffix, "Jr.")
  expect_equal(mysterycall_parse_physician_name("Robert Brown III")$suffix, "III")
  # ...and never leaks into the name fields
  r <- mysterycall_parse_physician_name("Robert Brown Jr.")
  expect_equal(r$last_name, "Brown")
  expect_false(grepl("Jr", paste(r$first_name, r$middle_name, r$last_name, collapse = " ")))
})

test_that("adversarial: agreements with mysterynpi parse_person on structure", {
  x <- c("Smith, John, Jr.", "Ann M. Barbaccia (Pollack), M.D.",
         "Maria de la Cruz-Garcia", "Cynthia (Cindi) A. Smith")
  mc <- mysterycall_parse_physician_name(x)
  np <- mysterynpi::parse_person(x)
  # mysterynpi uppercases through name_key(); compare case-insensitively.
  expect_equal(toupper(mc$last_name), np$last)
  expect_equal(toupper(mc$first_name), np$first)
})

test_that("adversarial: Vietnamese 'Do' surname still beats the DO credential", {
  expect_equal(mysterycall_parse_physician_name("Linda Do")$last_name, "Do")
  expect_equal(mysterycall_parse_physician_name("Robert Smith DO")$suffix, "DO")
  expect_equal(mysterycall_parse_physician_name("Robert Smith DO")$last_name, "Smith")
})

test_that("adversarial: NA/empty/garbage inputs never error and never fabricate names", {
  r <- mysterycall_parse_physician_name(c(NA_character_, "", "   ", "12345", "---"))
  expect_equal(nrow(r), 5L)
  expect_true(all(is.na(r$first_name[1:3])))
  expect_equal(r$parse_confidence[1], "low")
})

# ── 4. state normalisation ────────────────────────────────────────────────────

test_that("adversarial: DC and Puerto Rico no longer pass through unconverted", {
  expect_equal(mysterycall:::.mc_state_to_abbr("District of Columbia"), "DC")
  expect_equal(mysterycall:::.mc_state_to_abbr("Puerto Rico"), "PR")
  expect_equal(mysterycall:::.mc_state_to_abbr("PR"), "PR")
  expect_equal(mysterycall:::.mc_state_to_abbr("DC"), "DC")
})

test_that("adversarial: unrecognised states are NA, never passthrough false-matches", {
  expect_true(is.na(mysterycall:::.mc_state_to_abbr("ZZ")))
  expect_true(is.na(mysterycall:::.mc_state_to_abbr("Not A State")))
  expect_true(is.na(mysterycall:::.mc_state_to_abbr(NA_character_)))
  # agreement with the SSOT across a mixed vector
  x <- c("Colorado", "co", "CO", "Texas", "puerto rico", "zz", NA)
  expect_equal(unname(mysterycall:::.mc_state_to_abbr(x)),
               unname(mufflyaccess::standardize_state_name(x, output = "abbr")))
})

# ── 5. ZIP-5 consolidation ────────────────────────────────────────────────────

test_that("adversarial: all three normalisers agree on the dropped-leading-zero cases", {
  z <- c("7001", "07001", "7001-1234", "80203-1234", "03110", "90210")
  a <- mysterycall_clean_zip(z)
  b <- mysterycall:::mysterycall_extract_zip5(z)
  cc <- mysterycall:::mysterycall_normalize_zip5(z)
  expect_equal(unname(a), unname(b))
  expect_equal(unname(b), unname(cc))
  expect_equal(unname(a), c("07001", "07001", "07001", "80203", "03110", "90210"))
})

test_that("adversarial: ZIP+4 can never cross the 5/4 boundary when the leading zero dropped", {
  # "7001-1234" concatenated naively is "70011234" whose first five digits are
  # "70011" -- the corruption this family of fixes exists to prevent.
  expect_equal(mysterycall_clean_zip("7001-1234"), "07001")
  expect_equal(mysterycall:::mysterycall_extract_zip5("7001-1234"), "07001")
  expect_false(mysterycall_clean_zip("7001-1234") == "70011")
})

test_that("adversarial: documented min-digit contracts survive consolidation", {
  # extract_zip5 alone treats 1-2 digit fragments as not-a-ZIP
  expect_true(is.na(mysterycall:::mysterycall_extract_zip5("80")))
  # clean_zip pads even a single digit (documented, test-enshrined)
  expect_equal(mysterycall_clean_zip("1"), "00001")
  # garbage is NA everywhere
  for (fun in list(mysterycall_clean_zip,
                   mysterycall:::mysterycall_extract_zip5,
                   mysterycall:::mysterycall_normalize_zip5)) {
    expect_true(is.na(fun("no zip here")))
    expect_true(is.na(fun(NA_character_)))
  }
  # multi-ZIP splitting remains clean_zip's alone, and takes the FIRST zip
  expect_equal(mysterycall_clean_zip("03110, 03756"), "03110")
})
