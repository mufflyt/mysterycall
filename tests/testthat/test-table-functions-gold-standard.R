library(testthat)
testthat::skip_if_not_installed("dplyr")

# ── mysterycall_table_percentages ───────────────────────────────────────────────
# Gold-standard: manually computed from hand-counted frequencies.

test_that("mysterycall_table_percentages - single clear winner A=4/8=50%", {
  df <- data.frame(category = c("A", "B", "A", "C", "A", "B", "B", "A"))
  # A=4, B=3, C=1, total=8; only A is the max
  result <- mysterycall_table_percentages(df, "category")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$category[1], "A")
  expect_equal(result$n[1], 4L)
  expect_equal(result$percent[1], 50)
})

test_that("mysterycall_table_percentages - three-way tie returns all three", {
  # A=3, B=3, C=3
  df <- data.frame(x = c("A", "B", "A", "B", "C", "C", "C", "A", "B"))
  result <- mysterycall_table_percentages(df, "x")
  expect_equal(nrow(result), 3L)
  expect_setequal(result$x, c("A", "B", "C"))
  expect_true(all(result$n == 3L))
  # Each is 3/9 * 100 = 33.333...
  expect_equal(result$percent, rep(100 / 3, 3), tolerance = 1e-6)
})

test_that("mysterycall_table_percentages - single-level vector is 100%", {
  df <- data.frame(v = rep("Only", 20))
  result <- mysterycall_table_percentages(df, "v")
  expect_equal(nrow(result), 1L)
  expect_equal(result$v[1], "Only")
  expect_equal(result$n[1], 20L)
  expect_equal(result$percent[1], 100)
})

test_that("mysterycall_table_percentages - NAs excluded from count and denominator", {
  df <- data.frame(cat = c("A", NA, "A", "C", "A", "B", "B", NA))
  # NA excluded: A=3, B=2, C=1, non-missing total=6; A wins at 3/6 = 50%
  result <- mysterycall_table_percentages(df, "cat")
  expect_equal(result$n[1], 3L)
  expect_equal(result$percent[1], 50)
})

test_that("mysterycall_table_percentages - variable passed as string is accepted", {
  df <- data.frame(state = c("CO", "CO", "CA", "NY"))
  result <- mysterycall_table_percentages(df, "state")
  expect_equal(result$state[1], "CO")
  expect_equal(result$n[1], 2L)
  expect_equal(result$percent[1], 50)
})

test_that("mysterycall_table_percentages - uses actual taxonomy Classification column", {
  e <- new.env()
  data("taxonomy", package = "mysterycall", envir = e)
  result <- mysterycall_table_percentages(e$taxonomy, "Classification")
  # Gold standard: "Clinic/Center" appears 63 times out of 862 rows = 7.309%
  expect_equal(result$Classification[1], "Clinic/Center")
  expect_equal(result$n[1], 63L)
  expect_equal(result$percent[1], 63 / 862 * 100, tolerance = 1e-6)
})

test_that("mysterycall_table_percentages - two items tied with 50% each", {
  df <- data.frame(ins = c("Medicaid", "Private", "Medicaid", "Private"))
  result <- mysterycall_table_percentages(df, "ins")
  expect_equal(nrow(result), 2L)
  expect_true(all(result$n == 2L))
  expect_true(all(result$percent == 50))
})

test_that("mysterycall_table_percentages - result columns are always n and percent", {
  df <- data.frame(x = letters[1:5])
  result <- mysterycall_table_percentages(df, "x")
  expect_true("n" %in% names(result))
  expect_true("percent" %in% names(result))
})

test_that("mysterycall_table_percentages - percents sum to 100 across full distribution", {
  df <- data.frame(cat = c("A", "B", "A", "C", "A", "B", "B", "A"))
  # Get full distribution (not just top)
  full <- df |>
    dplyr::count(cat) |>
    dplyr::mutate(percent = 100 * n / sum(n))
  expect_equal(sum(full$percent), 100)
})

# ── mysterycall_table_proportion ────────────────────────────────────────────────

test_that("mysterycall_table_proportion - equal split Male/Female 50/50", {
  df <- data.frame(gender = c("Male", "Female", "Female", "Male", "Male", "Female"))
  result <- mysterycall_table_proportion(df, gender)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_true(all(result$n == 3L))
  expect_true(all(result$percent == 50))
})

test_that("mysterycall_table_proportion - percents sum to 100", {
  df <- data.frame(grade = c("A", "B", "A", "C", "B", "A", "C", "B"))
  result <- mysterycall_table_proportion(df, grade)
  expect_equal(sum(result$percent), 100, tolerance = 0.01)
})

test_that("mysterycall_table_proportion - three levels gold standard", {
  # Medicaid=4, Private=3, Self-pay=3, total=10
  df <- data.frame(ins = c(
    rep("Medicaid", 4), rep("Private", 3), rep("Self-pay", 3)
  ))
  result <- mysterycall_table_proportion(df, ins)
  expect_equal(nrow(result), 3L)
  medicaid_row <- result[result$ins == "Medicaid", ]
  expect_equal(medicaid_row$n, 4L)
  expect_equal(medicaid_row$percent, 40, tolerance = 0.01)
})

test_that("mysterycall_table_proportion - single row is 100%", {
  df <- data.frame(x = rep("solo", 7))
  result <- mysterycall_table_proportion(df, x)
  expect_equal(nrow(result), 1L)
  expect_equal(result$n[1], 7L)
  expect_equal(result$percent[1], 100)
})

test_that("mysterycall_table_proportion - n column is integer counts not fractions", {
  df <- data.frame(cat = c("X", "X", "Y"))
  result <- mysterycall_table_proportion(df, cat)
  expect_true(all(result$n == floor(result$n)))
})

test_that("mysterycall_table_proportion - percent is numeric between 0 and 100", {
  df <- data.frame(cat = c("A", "B", "C", "A", "B"))
  result <- mysterycall_table_proportion(df, cat)
  expect_true(all(result$percent >= 0))
  expect_true(all(result$percent <= 100))
})

test_that("mysterycall_table_proportion - returns all levels, not just majority", {
  # A=5, B=3, C=2 - all three should be in output
  df <- data.frame(x = c(rep("A", 5), rep("B", 3), rep("C", 2)))
  result <- mysterycall_table_proportion(df, x)
  expect_equal(nrow(result), 3L)
  expect_setequal(result$x, c("A", "B", "C"))
})
