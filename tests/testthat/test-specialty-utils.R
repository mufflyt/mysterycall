# ── mysterycall_parse_certification_subspecialty ──────────────────────────────

test_that("parse_cert: neurotology detected", {
  expect_equal(
    mysterycall_parse_certification_subspecialty("Otolaryngology + Neurotology"),
    "Otology/Neurotology"
  )
})

test_that("parse_cert: pediatric detected", {
  expect_equal(
    mysterycall_parse_certification_subspecialty("Otolaryngology + Pediatric Otolaryngology"),
    "Pediatric Otolaryngology"
  )
})

test_that("parse_cert: sleep medicine detected", {
  expect_equal(
    mysterycall_parse_certification_subspecialty("Otolaryngology + Sleep Medicine"),
    "Sleep Medicine"
  )
})

test_that("parse_cert: facial plastic detected", {
  expect_equal(
    mysterycall_parse_certification_subspecialty("Otolaryngology + Facial Plastic Surgery"),
    "Facial Plastic Surgery"
  )
})

test_that("parse_cert: base cert only → NA by default", {
  expect_true(is.na(
    mysterycall_parse_certification_subspecialty("Otolaryngology - Head & Neck Surgery")
  ))
})

test_that("parse_cert: custom default returned when no match", {
  res <- mysterycall_parse_certification_subspecialty("General ENT", default = "General")
  expect_equal(res, "General")
})

test_that("parse_cert: NA input → default NA", {
  expect_true(is.na(mysterycall_parse_certification_subspecialty(NA_character_)))
})

test_that("parse_cert: vectorized", {
  certs <- c("Neurotology", "Pediatric", NA, "Head & Neck")
  res   <- mysterycall_parse_certification_subspecialty(certs)
  expect_length(res, 4L)
  expect_equal(res[[1L]], "Otology/Neurotology")
  expect_equal(res[[2L]], "Pediatric Otolaryngology")
  expect_true(is.na(res[[3L]]))
  expect_true(is.na(res[[4L]]))
})

# ── mysterycall:::mysterycall_extract_physician_name ────────────────────────────────────────

test_that("extract_physician_name: 'First Last MD' → 'Dr. Last'", {
  expect_equal(mysterycall:::mysterycall_extract_physician_name("John Smith MD"), "Dr. Smith")
})

test_that("extract_physician_name: 'Dr. First Last' → 'Dr. Last'", {
  expect_equal(mysterycall:::mysterycall_extract_physician_name("Dr. Jane Doe"), "Dr. Doe")
})

test_that("extract_physician_name: 'Last, First' format", {
  expect_equal(mysterycall:::mysterycall_extract_physician_name("JONES, Robert"), "Dr. JONES")
})

test_that("extract_physician_name: multiple credentials stripped", {
  expect_equal(
    mysterycall:::mysterycall_extract_physician_name("Mary Williams, MD, FACS"),
    "Dr. Williams"
  )
})

test_that("extract_physician_name: format='last' returns surname only", {
  expect_equal(mysterycall:::mysterycall_extract_physician_name("John Smith MD", format = "last"), "Smith")
})

test_that("extract_physician_name: format='full_clean' strips creds+title", {
  res <- mysterycall:::mysterycall_extract_physician_name("Dr. John Smith, MD", format = "full_clean")
  expect_false(grepl("MD", res))
  expect_false(grepl("Dr\\.", res))
})

test_that("extract_physician_name: NA → NA", {
  expect_true(is.na(mysterycall:::mysterycall_extract_physician_name(NA_character_)))
})

test_that("extract_physician_name: vectorized", {
  nms <- c("John Smith MD", "Dr. Jane Doe, PhD", NA)
  res <- mysterycall:::mysterycall_extract_physician_name(nms)
  expect_length(res, 3L)
  expect_equal(res[[1L]], "Dr. Smith")
  expect_equal(res[[2L]], "Dr. Doe")
  expect_true(is.na(res[[3L]]))
})
