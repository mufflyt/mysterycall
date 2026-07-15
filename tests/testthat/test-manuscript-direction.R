library(testthat)

test_that("get_direction maps sign to the default comparison words", {
  expect_equal(
    mysterycall_get_direction(c(2.4, -1.1, 0)),
    c("higher", "lower", "no different")
  )
})

test_that("get_change_verb maps sign to the default trend words", {
  expect_equal(
    mysterycall_get_change_verb(c(3.2, -0.4, 0)),
    c("increasing", "decreasing", "stable")
  )
})

test_that("words are configurable but stay tied to the sign", {
  expect_equal(
    mysterycall_get_direction(c(5, -5), positive = "up", negative = "down"),
    c("up", "down")
  )
  expect_equal(
    mysterycall_get_change_verb(-2, increasing = "growing", decreasing = "shrinking"),
    "shrinking"
  )
})

test_that("NA input yields NA_character_ and length is preserved", {
  out <- mysterycall_get_change_verb(c(1, NA, -1))
  expect_equal(out, c("increasing", NA, "decreasing"))
  expect_length(out, 3L)
})

test_that("tol defines a no-change band around zero", {
  expect_equal(
    mysterycall_get_change_verb(c(0.3, -0.3, 1.0), tol = 0.5),
    c("stable", "stable", "increasing")
  )
})

test_that("invalid tol and non-scalar words error", {
  expect_error(mysterycall_get_direction(1, tol = -1), "non-negative")
  expect_error(mysterycall_get_direction(1, positive = c("a", "b")),
               "single non-NA character")
})

test_that("empty input returns empty character", {
  expect_equal(mysterycall_get_change_verb(numeric(0)), character(0))
})
