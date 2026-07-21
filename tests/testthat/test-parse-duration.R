# Tests for mysterycall_parse_duration

test_that("parses minute and second tokens, summing when both present", {
  x <- c("1.5min", "1min 45 sec", "30sec", "2.75min, 30sec", "2min")
  s <- mysterycall_parse_duration(x, output_unit = "seconds")
  expect_equal(s, c(90, 105, 30, 195, 120))
})

test_that("output_unit converts to minutes", {
  expect_equal(mysterycall_parse_duration("1min 45 sec", output_unit = "minutes"),
               105 / 60)
})

test_that("bare number honors default_unit", {
  expect_equal(mysterycall_parse_duration("3", default_unit = "minutes"), 180)
  expect_equal(mysterycall_parse_duration("3", default_unit = "seconds"), 3)
})

test_that("'O' parses to zero; blanks and junk to NA", {
  expect_equal(mysterycall_parse_duration(c("O", "0")), c(0, 0))
  expect_true(all(is.na(mysterycall_parse_duration(c("", NA, "abc")))))
})

test_that("decimals in either token are handled", {
  expect_equal(mysterycall_parse_duration("2.5min"), 150)
})

test_that("length is preserved", {
  x <- c("1min", "bad", NA, "30sec")
  expect_length(mysterycall_parse_duration(x), 4L)
})
