# ── mysterycall_classify_practice_setting ────────────────────────────────────

test_that("practice_setting: university name → Academic", {
  expect_equal(
    mysterycall_classify_practice_setting("University of Colorado Medical Center"),
    "Academic"
  )
})

test_that("practice_setting: children's hospital → Academic", {
  expect_equal(
    mysterycall_classify_practice_setting("Children's Hospital of Denver"),
    "Academic"
  )
})

test_that("practice_setting: Mayo Clinic → Academic", {
  expect_equal(mysterycall_classify_practice_setting("Mayo Clinic"), "Academic")
})

test_that("practice_setting: VA medical → Government", {
  expect_equal(
    mysterycall_classify_practice_setting("VA Medical Center Denver"),
    "Government"
  )
})

test_that("practice_setting: Veterans affairs → Government", {
  expect_equal(
    mysterycall_classify_practice_setting("Veterans Affairs Medical Center"),
    "Government"
  )
})

test_that("practice_setting: military hospital → Government", {
  expect_equal(
    mysterycall_classify_practice_setting("Military Family Medicine Clinic"),
    "Government"
  )
})

test_that("practice_setting: private LLC → Private Practice", {
  expect_equal(
    mysterycall_classify_practice_setting("Denver ENT Associates LLC"),
    "Private Practice"
  )
})

test_that("practice_setting: non-empty non-matching → Private Practice", {
  expect_equal(
    mysterycall_classify_practice_setting("Suburban Ear Nose Throat"),
    "Private Practice"
  )
})

test_that("practice_setting: NA → Unknown", {
  expect_equal(mysterycall_classify_practice_setting(NA_character_), "Unknown")
})

test_that("practice_setting: empty string → Unknown", {
  expect_equal(mysterycall_classify_practice_setting(""), "Unknown")
})

test_that("practice_setting: whitespace-only → Unknown", {
  expect_equal(mysterycall_classify_practice_setting("   "), "Unknown")
})

test_that("practice_setting: custom na_label", {
  expect_equal(
    mysterycall_classify_practice_setting(NA_character_, na_label = "Missing"),
    "Missing"
  )
})

test_that("practice_setting: vectorized — returns correct length", {
  inputs <- c("University Hospital", "VA Medical", "Denver ENT LLC", NA)
  res    <- mysterycall_classify_practice_setting(inputs)
  expect_length(res, 4L)
  expect_equal(res, c("Academic", "Government", "Private Practice", "Unknown"))
})

test_that("practice_setting: Government takes priority over Academic", {
  # Walter Reed is an Army (government) facility even though it mentions medical center
  res <- mysterycall_classify_practice_setting("Walter Reed Army Medical Center University Teaching Hospital")
  expect_equal(res, "Government")
})

test_that("practice_setting: non-character input errors", {
  expect_error(mysterycall_classify_practice_setting(123), "character")
})

test_that("practice_setting: custom academic_patterns override", {
  res <- mysterycall_classify_practice_setting(
    "Muffly Specialty Clinic",
    academic_patterns = c("muffly")
  )
  expect_equal(res, "Academic")
})

test_that("mysterycall_academic_patterns: returns character vector", {
  ap <- mysterycall_academic_patterns()
  expect_true(is.character(ap))
  expect_gt(length(ap), 5L)
})

test_that("mysterycall_government_patterns: returns character vector", {
  gp <- mysterycall_government_patterns()
  expect_true(is.character(gp))
  expect_gt(length(gp), 3L)
})

# ── BUG 32 regression: unanchored government/academic substrings ─────────────

test_that("classify_setting: 'Nova Southeastern Medical Center' not Government (va in nova)", {
  expect_equal(
    mysterycall_classify_practice_setting("Nova Southeastern Medical Center"),
    "Academic"
  )
})

test_that("classify_setting: 'Pennsylvania ENT Associates' not Academic (penn substring)", {
  expect_equal(
    mysterycall_classify_practice_setting("Pennsylvania ENT Associates"),
    "Private Practice"
  )
})

test_that("classify_setting: 'Tuscaloosa' not Academic (usc substring)", {
  expect_equal(
    mysterycall_classify_practice_setting("DCH Tuscaloosa Otolaryngology"),
    "Private Practice"
  )
})

test_that("classify_setting: genuine VA facilities still Government", {
  expect_equal(
    mysterycall_classify_practice_setting("VA Medical Center Denver"),
    "Government"
  )
  expect_equal(
    mysterycall_classify_practice_setting("Veterans Affairs Outpatient Clinic"),
    "Government"
  )
})

test_that("classify_setting: genuine Penn academic name still Academic", {
  expect_equal(
    mysterycall_classify_practice_setting("Penn Medicine University City"),
    "Academic"
  )
})
