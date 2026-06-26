test_that("namespace exports documented helpers without blanket-exporting internals", {
  exports <- getNamespaceExports("mysterycall")

  expect_true("mysterycall_screen_interactions" %in% exports)
  expect_true("mysterycall_select_best_model" %in% exports)
  expect_true("mysterycall_marginal_effects" %in% exports)

  expect_false("mysterycall_cache_dir" %in% exports)
  expect_false("mysterycall_spinner_start" %in% exports)
  expect_false("mysterycall_check_api_response" %in% exports)
})
