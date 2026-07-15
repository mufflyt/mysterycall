# ── mysterycall_impute_age ────────────────────────────────────────────────────

test_that("impute_age: grad_year 1995, ref 2026 → 58", {
  expect_equal(mysterycall_impute_age(1995, ref_year = 2026L), 58L)
})

test_that("impute_age: grad_year 2000, ref 2026, offset 27 → 53", {
  expect_equal(mysterycall_impute_age(2000, ref_year = 2026L), 53L)
})

test_that("impute_age: NA grad_year → NA", {
  expect_true(is.na(mysterycall_impute_age(NA_integer_, ref_year = 2026L)))
})

test_that("impute_age: vectorized", {
  res <- mysterycall_impute_age(c(1980, 1995, 2010, NA), ref_year = 2026L)
  expect_equal(res, c(73L, 58L, 43L, NA_integer_))
})

test_that("impute_age: future graduation year set to NA (with message)", {
  # grad_year 2030 > ref_year 2026: the physician has not graduated, so the
  # age is NA via the future-grad guard (a message, not the min_age warning).
  expect_message(
    res <- mysterycall_impute_age(2030L, ref_year = 2026L, age_offset = 27L),
    "exceed ref_year"
  )
  expect_true(is.na(res))
})

test_that("impute_age: implausible age > max_age set to NA with warning", {
  expect_warning(
    res <- mysterycall_impute_age(1900L, ref_year = 2026L, age_offset = 27L),
    "implausible|outside"
  )
  expect_true(is.na(res))
})

test_that("impute_age: custom offset", {
  expect_equal(mysterycall_impute_age(1995L, ref_year = 2026L, age_offset = 30L), 61L)
})

test_that("impute_age: non-numeric grad_year errors", {
  expect_error(mysterycall_impute_age("1995"), "numeric")
})

test_that("impute_age: ref_year < 1900 errors", {
  expect_error(mysterycall_impute_age(1995, ref_year = 1800), "1900")
})

test_that("impute_age: returns integer vector", {
  res <- mysterycall_impute_age(c(1990, 2000), ref_year = 2026L)
  expect_type(res, "integer")
})

# ── mysterycall_age_category ──────────────────────────────────────────────────

test_that("age_category: 28 → '<30'", {
  expect_equal(mysterycall_age_category(28), "<30")
})

test_that("age_category: 30 → '30-39'", {
  expect_equal(mysterycall_age_category(30), "30-39")
})

test_that("age_category: 39 → '30-39'", {
  expect_equal(mysterycall_age_category(39), "30-39")
})

test_that("age_category: 40 → '40-49'", {
  expect_equal(mysterycall_age_category(40), "40-49")
})

test_that("age_category: 70 → '70+'", {
  expect_equal(mysterycall_age_category(70), "70+")
})

test_that("age_category: 85 → '70+'", {
  expect_equal(mysterycall_age_category(85), "70+")
})

test_that("age_category: NA → 'Unknown'", {
  expect_equal(mysterycall_age_category(NA_real_), "Unknown")
})

test_that("age_category: vectorized", {
  res <- mysterycall_age_category(c(28, 35, 47, 55, 63, 72, NA))
  expect_equal(res, c("<30", "30-39", "40-49", "50-59", "60-69", "70+", "Unknown"))
})

test_that("age_category: as_factor returns ordered factor", {
  res <- mysterycall_age_category(c(35, 55, NA), as_factor = TRUE)
  expect_s3_class(res, "factor")
  expect_true(is.ordered(res))
})

test_that("age_category: factor levels include na_label", {
  res <- mysterycall_age_category(c(35, NA), as_factor = TRUE)
  expect_true("Unknown" %in% levels(res))
})

test_that("age_category: custom breaks", {
  res <- mysterycall_age_category(c(25, 50, 75), breaks = c(50))
  # 25 < 50 → "<50"; 50 is AT the boundary → "50+"; 75 > 50 → "50+"
  expect_equal(res, c("<50", "50+", "50+"))
})

test_that("age_category: custom labels", {
  res <- mysterycall_age_category(c(25, 50),
                                   breaks = c(30, 40, 50, 60, 70),
                                   labels = c("A","B","C","D","E","F"))
  expect_equal(res, c("A", "D"))
})

test_that("age_category: wrong labels length errors", {
  expect_error(
    mysterycall_age_category(30, breaks = c(30, 60), labels = c("X", "Y")),
    "length 3"
  )
})

test_that("age_category: non-numeric age errors", {
  expect_error(mysterycall_age_category("35"), "numeric")
})

test_that("age_category: unsorted breaks errors", {
  expect_error(mysterycall_age_category(30, breaks = c(60, 30)), "increasing")
})
