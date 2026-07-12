library(testthat)

test_that("mysterycall_add_medicaid_expansion adds static status by name and abbreviation", {
  d <- data.frame(state = c("Texas", "CA", "california", "SD"),
                  stringsAsFactors = FALSE)
  out <- mysterycall_add_medicaid_expansion(d)
  expect_true(all(c("expanded", "expansion_date", "expansion_status") %in% names(out)))
  expect_false(out$expanded[1])                 # Texas
  expect_true(out$expanded[2])                  # CA (abbrev)
  expect_true(out$expanded[3])                  # california (case-insensitive name)
  expect_equal(out$expansion_status[1], "Not Expanded")
})

test_that("as-of-date flag handles states adopting mid-window (NC, SD)", {
  d <- data.frame(
    state     = c("North Carolina", "SD", "SD"),
    call_date = as.Date(c("2023-05-01", "2023-05-01", "2023-09-01")),
    stringsAsFactors = FALSE
  )
  out <- mysterycall_add_medicaid_expansion(d, date_col = "call_date")
  expect_true("expanded_at_date" %in% names(out))
  expect_false(out$expanded_at_date[1])   # NC impl 2023-12-01, call 2023-05 -> not yet
  expect_false(out$expanded_at_date[2])   # SD impl 2023-07-01, call 2023-05 -> not yet
  expect_true(out$expanded_at_date[3])    # SD, call 2023-09 -> expanded
  # Current status is still expanded for all three
  expect_true(all(out$expanded))
})

test_that("unmatched states warn and yield NA", {
  d <- data.frame(state = c("Puerto Rico", "Texas"), stringsAsFactors = FALSE)
  expect_warning(out <- mysterycall_add_medicaid_expansion(d), "did not match")
  expect_true(is.na(out$expanded[1]))
  expect_false(out$expanded[2])
})

test_that("prefix renames added columns", {
  d <- data.frame(state = "CA", stringsAsFactors = FALSE)
  out <- mysterycall_add_medicaid_expansion(d, prefix = "mx_")
  expect_true(all(c("mx_expanded", "mx_expansion_date", "mx_expansion_status") %in% names(out)))
})

test_that("input validation", {
  expect_error(mysterycall_add_medicaid_expansion(1L), "must be a data frame")
  expect_error(mysterycall_add_medicaid_expansion(data.frame(x = 1), state_col = "nope"),
               "not found")
  expect_error(mysterycall_add_medicaid_expansion(data.frame(state = "CA"), date_col = "nope"),
               "not found")
})
