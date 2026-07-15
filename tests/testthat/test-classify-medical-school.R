# ── mysterycall_classify_medical_school ──────────────────────────────────────

test_that("classify_school: US allopathic → US_MD", {
  expect_equal(
    mysterycall_classify_medical_school("University of Colorado School of Medicine"),
    "US_MD"
  )
})

test_that("classify_school: Harvard → US_MD", {
  expect_equal(
    mysterycall_classify_medical_school("Harvard Medical School"),
    "US_MD"
  )
})

test_that("classify_school: osteopathic school → US_DO", {
  expect_equal(
    mysterycall_classify_medical_school("Philadelphia College of Osteopathic Medicine"),
    "US_DO"
  )
})

test_that("classify_school: 'Osteopathic' in name → US_DO", {
  expect_equal(
    mysterycall_classify_medical_school("Midwestern University Chicago College of Osteopathic Medicine"),
    "US_DO"
  )
})

test_that("classify_school: TOURO → US_DO (Touro College of Osteopathic Medicine)", {
  expect_equal(
    mysterycall_classify_medical_school("Touro College of Osteopathic Medicine"),
    "US_DO"
  )
})

test_that("classify_school: Canadian school → CAN_MD", {
  expect_equal(
    mysterycall_classify_medical_school("McGill University Faculty of Medicine"),
    "CAN_MD"
  )
})

test_that("classify_school: University of Toronto → CAN_MD", {
  expect_equal(
    mysterycall_classify_medical_school("University of Toronto Faculty of Medicine"),
    "CAN_MD"
  )
})

test_that("classify_school: Ross University → IMG", {
  expect_equal(
    mysterycall_classify_medical_school("Ross University School of Medicine"),
    "IMG"
  )
})

test_that("classify_school: Caribbean school → IMG", {
  expect_equal(
    mysterycall_classify_medical_school("American University of the Caribbean School of Medicine"),
    "IMG"
  )
})

test_that("classify_school: India → IMG", {
  expect_equal(
    mysterycall_classify_medical_school("All India Institute of Medical Sciences"),
    "IMG"
  )
})

test_that("classify_school: Universidad (Spanish) → IMG", {
  expect_equal(
    mysterycall_classify_medical_school("Universidad Nacional Autonoma de Mexico"),
    "IMG"
  )
})

test_that("classify_school: NA → Unknown", {
  expect_equal(mysterycall_classify_medical_school(NA_character_), "Unknown")
})

test_that("classify_school: empty string → Unknown", {
  expect_equal(mysterycall_classify_medical_school(""), "Unknown")
})

test_that("classify_school: vectorized — correct length and values", {
  schools <- c(
    "University of Colorado School of Medicine",
    "Philadelphia College of Osteopathic Medicine",
    "McGill University Faculty of Medicine",
    "Ross University School of Medicine",
    NA
  )
  res <- mysterycall_classify_medical_school(schools)
  expect_equal(res, c("US_MD", "US_DO", "CAN_MD", "IMG", "Unknown"))
})

test_that("classify_school: DO priority over CAN_MD", {
  # Canadian osteopathic programs don't really exist, but test priority logic
  res <- mysterycall_classify_medical_school("Ontario College of Osteopathic Medicine")
  expect_equal(res, "US_DO")   # DO pattern fires first
})

test_that("classify_school: non-character errors", {
  expect_error(mysterycall_classify_medical_school(123), "character")
})

test_that("classify_school: custom na_label", {
  expect_equal(
    mysterycall_classify_medical_school(NA_character_, na_label = "No data"),
    "No data"
  )
})

# ── BUG 31 regression: country substrings must not match US school names ──────

test_that("classify_school: 'Indiana University' is not IMG (india substring)", {
  expect_false(grepl("\\bindia\\b", "Indiana University School of Medicine", perl = TRUE))
  expect_equal(
    mysterycall_classify_medical_school("Indiana University School of Medicine"),
    "US_MD"
  )
})

test_that("classify_school: 'University of New Mexico' is not IMG (mexico substring)", {
  expect_equal(
    mysterycall_classify_medical_school("University of New Mexico School of Medicine"),
    "US_MD"
  )
})

test_that("classify_school: 'Western University of Health Sciences' (US DO) not CAN_MD", {
  expect_equal(
    mysterycall_classify_medical_school(
      "Western University of Health Sciences College of Osteopathic Medicine"
    ),
    "US_DO"
  )
})

test_that("classify_school: genuine country matches still classify as IMG", {
  expect_equal(
    mysterycall_classify_medical_school("Universidad Autonoma de Guadalajara Mexico"),
    "IMG"
  )
  expect_equal(
    mysterycall_classify_medical_school("Ross University School of Medicine"),
    "IMG"
  )
})

test_that("classify_school: genuine Canadian 'Western University' still CAN_MD", {
  expect_equal(
    mysterycall_classify_medical_school("Western University Schulich School of Medicine"),
    "CAN_MD"
  )
})
