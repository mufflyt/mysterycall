library(testthat)
library(mysterycall)


# Tests for %>% (pipe operator re-exported from dplyr)

test_that("%>% pipes a value through a single function", {
  result <- suppressMessages(suppressWarnings(
    c(3, 1, 4, 1, 5) %>% sum()
  ))
  expect_equal(result, 14)
})

test_that("%>% chains multiple functions correctly", {
  result <- suppressMessages(suppressWarnings(
    c(10, 20, 30, NA) %>% na.omit() %>% mean()
  ))
  expect_equal(result, 20)
})

test_that("%>% handles NA-only vector without error", {
  result <- suppressMessages(suppressWarnings(
    as.numeric(c(NA, NA, NA)) %>% na.omit()
  ))
  expect_equal(length(result), 0L)
})

test_that("%>% handles an empty numeric vector", {
  result <- suppressMessages(suppressWarnings(
    numeric(0) %>% sum()
  ))
  expect_equal(result, 0)
})

test_that("%>% propagates errors from downstream functions", {
  expect_error(
    suppressMessages(suppressWarnings(
      "not_a_number" %>% log()
    ))
  )
})
