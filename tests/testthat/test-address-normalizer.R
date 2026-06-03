skip_if_not_installed("stringr")
skip_if_not_installed("dplyr")
skip_if_not_installed("tidyr")

# ── mysterycall_ascii_norm ────────────────────────────────────────────────────

test_that("ascii_norm: collapses internal whitespace", {
  expect_equal(
    mysterycall:::mysterycall_ascii_norm("456   Oak    Avenue"),
    "456 Oak Avenue"
  )
})

test_that("ascii_norm: replaces non-ASCII with space", {
  expect_equal(
    mysterycall:::mysterycall_ascii_norm("Cafe\u00e9 Street"),
    "Cafe Street"
  )
})

test_that("ascii_norm: trims edge whitespace", {
  expect_equal(mysterycall:::mysterycall_ascii_norm("  hello  "), "hello")
})

# ── mysterycall_caps ──────────────────────────────────────────────────────────

test_that("caps: returns uppercase", {
  expect_equal(mysterycall:::mysterycall_caps("123 main street"), "123 MAIN STREET")
})

test_that("caps: also normalizes whitespace", {
  expect_equal(mysterycall:::mysterycall_caps("  ab   cd  "), "AB CD")
})

# ── mysterycall_is_po_box ─────────────────────────────────────────────────────

test_that("is_po_box: matches PO BOX", {
  expect_true(mysterycall:::mysterycall_is_po_box("PO Box 12345"))
})

test_that("is_po_box: matches P O BOX with spaces", {
  expect_true(mysterycall:::mysterycall_is_po_box("P O Box 99"))
})

test_that("is_po_box: matches POST OFFICE BOX spelled out", {
  expect_true(mysterycall:::mysterycall_is_po_box("Post Office Box 77"))
})

test_that("is_po_box: rejects regular street address", {
  expect_false(mysterycall:::mysterycall_is_po_box("123 Main Street"))
})

test_that("is_po_box: vectorized", {
  expect_equal(
    mysterycall:::mysterycall_is_po_box(c("PO Box 1", "123 Main", "P O BOX 5")),
    c(TRUE, FALSE, TRUE)
  )
})

# ── mysterycall_has_street_number ─────────────────────────────────────────────

test_that("has_street_number: detects leading digits", {
  expect_true(mysterycall:::mysterycall_has_street_number("123 Main Street"))
})

test_that("has_street_number: rejects no leading digit", {
  expect_false(mysterycall:::mysterycall_has_street_number("University Medical Center"))
})

test_that("has_street_number: handles leading whitespace", {
  expect_true(mysterycall:::mysterycall_has_street_number("  42 Oak"))
})

# ── mysterycall_normalize_state ───────────────────────────────────────────────

test_that("normalize_state: full name to code", {
  expect_equal(mysterycall:::mysterycall_normalize_state("California"), "CA")
})

test_that("normalize_state: two-letter passes through", {
  expect_equal(mysterycall:::mysterycall_normalize_state("NY"), "NY")
})

test_that("normalize_state: vectorized mixed inputs", {
  expect_equal(
    mysterycall:::mysterycall_normalize_state(c("Texas", "FL", "new york")),
    c("TX", "FL", "NY")
  )
})

test_that("normalize_state: handles DC and territories", {
  expect_equal(
    mysterycall:::mysterycall_normalize_state(c("District of Columbia", "Puerto Rico")),
    c("DC", "PR")
  )
})

# ── mysterycall_normalize_directionals ────────────────────────────────────────

test_that("normalize_directionals: NORTH -> N", {
  expect_match(
    mysterycall:::mysterycall_normalize_directionals("123 North Main Street"),
    "\\bN\\b"
  )
})

test_that("normalize_directionals: NORTHEAST -> NE", {
  expect_match(
    mysterycall:::mysterycall_normalize_directionals("456 Northeast Oak Avenue"),
    "\\bNE\\b"
  )
})

test_that("normalize_directionals: abbreviation with period is normalized", {
  out <- mysterycall:::mysterycall_normalize_directionals("123 N. Main")
  expect_false(grepl("\\bN\\.\\b", out))
})

# ── mysterycall_normalize_suffix ──────────────────────────────────────────────

test_that("normalize_suffix: STREET -> ST", {
  expect_match(
    mysterycall:::mysterycall_normalize_suffix("123 Main Street"),
    "\\bST\\b"
  )
})

test_that("normalize_suffix: BOULEVARD -> BLVD", {
  expect_match(
    mysterycall:::mysterycall_normalize_suffix("456 Sunset Boulevard"),
    "\\bBLVD\\b"
  )
})

test_that("normalize_suffix: AVENUE -> AVE", {
  expect_match(
    mysterycall:::mysterycall_normalize_suffix("789 Oak Avenue"),
    "\\bAVE\\b"
  )
})

# ── mysterycall_normalize_units ───────────────────────────────────────────────

test_that("normalize_units: SUITE -> STE in addr1", {
  out <- mysterycall:::mysterycall_normalize_units("123 Main St Suite 100", NA_character_)
  expect_match(out$addr1, "\\bSTE\\b")
  expect_true(is.na(out$addr2))
})

test_that("normalize_units: APARTMENT in addr2", {
  out <- mysterycall:::mysterycall_normalize_units("123 Main", "Apartment 4B")
  expect_match(out$addr2, "\\bAPT\\b")
})

test_that("normalize_units: FLOOR -> FL", {
  out <- mysterycall:::mysterycall_normalize_units("123 Main Floor 2", NA_character_)
  expect_match(out$addr1, "\\bFL\\b")
})

# ── mysterycall_normalize_zip5 ────────────────────────────────────────────────

test_that("normalize_zip5: ZIP+4 -> 5 digits", {
  expect_equal(mysterycall:::mysterycall_normalize_zip5("80111-1234"), "80111")
})

test_that("normalize_zip5: numeric input", {
  expect_equal(mysterycall:::mysterycall_normalize_zip5(90210), "90210")
})

test_that("normalize_zip5: NULL returns NA_character_", {
  expect_true(is.na(mysterycall:::mysterycall_normalize_zip5(NULL)))
})

test_that("normalize_zip5: length-0 returns character(0)", {
  expect_identical(mysterycall:::mysterycall_normalize_zip5(character(0)), character(0))
})

test_that("normalize_zip5: malformed input returns NA", {
  expect_true(is.na(mysterycall:::mysterycall_normalize_zip5("nope")))
})

test_that("normalize_zip5: vectorized", {
  expect_equal(
    mysterycall:::mysterycall_normalize_zip5(c("80111-1234", "90210", "abc")),
    c("80111", "90210", NA_character_)
  )
})

# ── mysterycall_strip_suite ───────────────────────────────────────────────────

test_that("strip_suite: removes STE", {
  expect_false(grepl(
    "STE|SUITE",
    mysterycall:::mysterycall_strip_suite("123 Main St Suite 100")
  ))
})

test_that("strip_suite: removes APT", {
  out <- mysterycall:::mysterycall_strip_suite("456 Oak Ave APT 4B")
  expect_false(grepl("APT", out))
})

# ── mysterycall_normalize_address_df ──────────────────────────────────────────

test_that("normalize_address_df: adds derived columns", {
  df <- data.frame(
    practice_address1 = c("123 North Main Street Suite 100", "456 Oak Avenue"),
    practice_address2 = c(NA_character_, "Apartment 4B"),
    practice_city     = c("Denver", "Los Angeles"),
    practice_state    = c("Colorado", "CA"),
    practice_zip      = c("80111-1234", "90210"),
    stringsAsFactors  = FALSE
  )
  out <- mysterycall_normalize_address_df(df)
  expect_s3_class(out, "data.frame")
  expect_true(all(c("address1_norm", "address2_norm", "address1_no_unit",
                    "is_po_box", "has_num") %in% names(out)))
  expect_equal(out$practice_state, c("CO", "CA"))
  expect_equal(out$practice_zip,   c("80111", "90210"))
})

test_that("normalize_address_df: missing required column errors", {
  df <- data.frame(practice_city = "Denver", practice_state = "CO", practice_zip = "80111")
  expect_error(mysterycall_normalize_address_df(df), "Missing")
})

test_that("normalize_address_df: works when addr2 column absent", {
  df <- data.frame(
    practice_address1 = "123 Main Street",
    practice_city     = "Denver",
    practice_state    = "CO",
    practice_zip      = "80111",
    stringsAsFactors  = FALSE
  )
  out <- mysterycall_normalize_address_df(df)
  expect_s3_class(out, "data.frame")
  expect_true("address1_norm" %in% names(out))
})

# ── deprecated aliases ────────────────────────────────────────────────────────

test_that("ascii_norm deprecated alias fires", {
  expect_warning(mysterycall:::ascii_norm("foo"), "deprecated")
})

test_that("caps deprecated alias fires", {
  expect_warning(mysterycall:::caps("foo"), "deprecated")
})

test_that("is_po_box deprecated alias fires", {
  expect_warning(mysterycall:::is_po_box("PO Box 1"), "deprecated")
})

test_that("normalize_state deprecated alias fires", {
  expect_warning(mysterycall:::normalize_state("CA"), "deprecated")
})

test_that("normalize_zip5 deprecated alias fires", {
  expect_warning(mysterycall:::normalize_zip5("80111"), "deprecated")
})

test_that("normalize_suffix deprecated alias fires", {
  expect_warning(mysterycall:::normalize_suffix("Main Street"), "deprecated")
})

test_that("normalize_directionals deprecated alias fires", {
  expect_warning(mysterycall:::normalize_directionals("North Main"), "deprecated")
})

test_that("normalize_units deprecated alias fires", {
  expect_warning(mysterycall:::normalize_units("123 Suite 1", NA_character_), "deprecated")
})

test_that("strip_suite deprecated alias fires", {
  expect_warning(mysterycall:::strip_suite("123 Main Suite 1"), "deprecated")
})

test_that("has_street_number deprecated alias fires", {
  expect_warning(mysterycall:::has_street_number("123 Main"), "deprecated")
})
