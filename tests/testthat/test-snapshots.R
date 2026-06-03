test_that("mysterycall_standard_labels() output is stable", {
  expect_snapshot(mysterycall_standard_labels())
})

test_that("mysterycall_standard_palette() primary palette is stable", {
  expect_snapshot(mysterycall_standard_palette("primary"))
})

test_that("mysterycall_standard_palette() sequential palette is stable", {
  expect_snapshot(mysterycall_standard_palette("sequential"))
})

test_that("mysterycall_standard_palette() diverging palette is stable", {
  expect_snapshot(mysterycall_standard_palette("diverging"))
})

test_that("mysterycall_quality_tier() tier boundaries are stable", {
  expect_snapshot({
    mysterycall_quality_tier(1.0)
    mysterycall_quality_tier(0.9)
    mysterycall_quality_tier(0.89)
    mysterycall_quality_tier(0.75)
    mysterycall_quality_tier(0.74)
    mysterycall_quality_tier(0.0)
  })
})

test_that("mysterycall:::mysterycall_check_data_completeness() summary structure is stable", {
  df <- tibble::tibble(id = 1:5, value = c(1, NA, 3, NA, 5))
  result <- mysterycall:::mysterycall_check_data_completeness(df, required = c("id", "value"))
  expect_snapshot(result$summary)
  expect_snapshot(result$quality)
})
