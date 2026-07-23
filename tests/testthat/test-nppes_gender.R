test_that("normalize_sex maps M/F and words to Male/Female, else NA", {
  expect_equal(
    mysterycall:::.mc_normalize_sex(c("M", "F", "male", "Female", "MALE", "f")),
    c("Male", "Female", "Male", "Female", "Male", "Female")
  )
  expect_equal(
    mysterycall:::.mc_normalize_sex(c("U", "", NA, "X", "unknown")),
    rep(NA_character_, 5L)
  )
})

test_that("nppes_gender errors on non-NPI input types", {
  expect_error(mysterycall_nppes_gender(list(1, 2)))
})

test_that("nppes_gender returns one row per unique NPI (offline structure)", {
  # No network: an invalid NPI resolves to NA without hitting the API.
  skip_if_not_installed("npi")
  out <- mysterycall_nppes_gender(c("0000000000", "0000000000"))
  expect_equal(nrow(out), 1L)                       # de-duplicated
  expect_named(out, c("npi", "gender", "gender_source"))
  expect_true(is.na(out$gender))                    # invalid NPI -> NA
})

test_that("nppes_gender reads real registry sex", {
  testthat::skip_on_cran()
  skip_if_not_installed("npi")
  testthat::skip_if_offline("nppes.cms.hhs.gov")
  out <- mysterycall_nppes_gender(c("1710933130", "1033299938"))
  expect_equal(nrow(out), 2L)
  expect_true(all(out$gender %in% c("Male", "Female", NA)))
  expect_true(all(out$gender_source[!is.na(out$gender)] == "NPPES"))
})
