# Tests for mysterycall_clean_zip

test_that("takes first ZIP, pads leading zero, strips ZIP+4", {
  expect_equal(
    mysterycall_clean_zip(c("03110, 03756", 3110, "12345-6789", "", NA)),
    c("03110", "03110", "12345", NA, NA)
  )
})

test_that("numeric input with lost leading zero is repadded", {
  expect_equal(mysterycall_clean_zip(8031), "08031")
})

test_that("nine-digit ZIP+4 without a dash keeps the first five", {
  expect_equal(mysterycall_clean_zip("123456789"), "12345")
})

test_that("no digits returns NA", {
  expect_true(is.na(mysterycall_clean_zip("no zip")))
})

test_that("length preserved and always five chars when non-NA", {
  out <- mysterycall_clean_zip(c("1", "12345", "0603"))
  expect_length(out, 3L)
  expect_true(all(nchar(out) == 5L))
})
