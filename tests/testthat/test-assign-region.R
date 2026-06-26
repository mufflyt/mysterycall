# ── mysterycall_assign_region ─────────────────────────────────────────────────

# ── ACOG system ───────────────────────────────────────────────────────────────

test_that("assign_region ACOG: Colorado → District VIII", {
  expect_equal(mysterycall_assign_region("Colorado", "acog"), "District VIII")
})

test_that("assign_region ACOG: 2-letter code CO → District VIII", {
  expect_equal(mysterycall_assign_region("CO", "acog"), "District VIII")
})

test_that("assign_region ACOG: case-insensitive full name", {
  expect_equal(mysterycall_assign_region("colorado", "acog"), "District VIII")
})

test_that("assign_region ACOG: New York → District II", {
  expect_equal(mysterycall_assign_region("NY", "acog"), "District II")
})

test_that("assign_region ACOG: Texas → District XI", {
  expect_equal(mysterycall_assign_region("TX", "acog"), "District XI")
})

test_that("assign_region ACOG: California → District IX", {
  expect_equal(mysterycall_assign_region("CA", "acog"), "District IX")
})

test_that("assign_region ACOG: NA → Unknown", {
  expect_equal(mysterycall_assign_region(NA_character_, "acog"), "Unknown")
})

test_that("assign_region ACOG: unrecognized state → Unknown", {
  expect_equal(mysterycall_assign_region("Narnia", "acog"), "Unknown")
})

test_that("assign_region ACOG: vectorized", {
  states <- c("CO", "NY", "TX", NA)
  res    <- mysterycall_assign_region(states, "acog")
  expect_length(res, 4L)
  expect_equal(res[[4L]], "Unknown")
})

# ── AAO-HNS system ────────────────────────────────────────────────────────────

test_that("assign_region AAO-HNS: Colorado → District 7", {
  expect_equal(mysterycall_assign_region("CO", "aao_hns"), "District 7")
})

test_that("assign_region AAO-HNS: New York → District 2", {
  expect_equal(mysterycall_assign_region("NY", "aao_hns"), "District 2")
})

test_that("assign_region AAO-HNS: Alabama → District 4", {
  expect_equal(mysterycall_assign_region("AL", "aao_hns"), "District 4")
})

test_that("assign_region AAO-HNS: Oregon → District 8", {
  expect_equal(mysterycall_assign_region("OR", "aao_hns"), "District 8")
})

test_that("assign_region AAO-HNS: NA → Unknown", {
  expect_equal(mysterycall_assign_region(NA_character_, "aao_hns"), "Unknown")
})

# ── Census system ─────────────────────────────────────────────────────────────

test_that("assign_region Census: Colorado → West", {
  expect_equal(mysterycall_assign_region("CO", "census"), "West")
})

test_that("assign_region Census: New York → Northeast", {
  expect_equal(mysterycall_assign_region("NY", "census"), "Northeast")
})

test_that("assign_region Census: Texas → South", {
  expect_equal(mysterycall_assign_region("TX", "census"), "South")
})

test_that("assign_region Census: Ohio → Midwest", {
  expect_equal(mysterycall_assign_region("OH", "census"), "Midwest")
})

test_that("assign_region Census: Florida → South", {
  expect_equal(mysterycall_assign_region("FL", "census"), "South")
})

# ── Cross-cutting ─────────────────────────────────────────────────────────────

test_that("assign_region: mixed format vector works", {
  res <- mysterycall_assign_region(c("CO", "Texas", "new york"), "census")
  expect_equal(res, c("West", "South", "Northeast"))
})

test_that("assign_region: custom na_label", {
  expect_equal(
    mysterycall_assign_region(NA_character_, "acog", na_label = "No district"),
    "No district"
  )
})

test_that("assign_region: non-character state errors", {
  expect_error(mysterycall_assign_region(42, "acog"), "character")
})

test_that("assign_region: invalid system arg errors", {
  expect_error(mysterycall_assign_region("CO", "bad"))
  expect_error(mysterycall_assign_region("CO", "unknown_system"))
})

test_that("assign_region: all 50 state abbreviations resolve in census", {
  abbrs <- names(.mc_state_abbr)
  abbrs <- abbrs[!abbrs %in% c("PR", "VI", "GU")]  # territories not in census map
  res   <- mysterycall_assign_region(abbrs, "census")
  expect_true(all(res %in% c("Northeast", "Midwest", "South", "West")))
})
