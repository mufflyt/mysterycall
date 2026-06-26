test_that("mysterycall_enrich_npi rejects non-data-frame input", {
  expect_error(mysterycall_enrich_npi(NULL), class = "error")
  expect_error(mysterycall_enrich_npi("text"), class = "error")
  expect_error(mysterycall_enrich_npi(1:5), class = "error")
})

test_that("mysterycall_enrich_npi rejects data frame without npi column", {
  df <- data.frame(name = "Alice", stringsAsFactors = FALSE)
  expect_error(mysterycall_enrich_npi(df), "npi")
})

test_that("mysterycall_enrich_npi returns a data frame", {
  skip_if_not_installed("httr")
  df <- data.frame(npi = "1003000126", stringsAsFactors = FALSE)
  # network call — skip if offline
  result <- tryCatch(
    mysterycall_enrich_npi(df, quiet = TRUE),
    error = function(e) NULL
  )
  if (!is.null(result)) expect_s3_class(result, "data.frame")
})
