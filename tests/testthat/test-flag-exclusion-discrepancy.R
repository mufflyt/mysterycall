df <- data.frame(
  physician_information           = c("Dr A", "Dr B", "Dr C", "Dr D"),
  id_number                       = c("001", "002", "003", "004"),
  notes                           = c("Called twice", NA, "Left VM", "OK"),
  reason_for_exclusions           = c("Physician not available",
                                      "Able to contact",
                                      "Number disconnected",
                                      "Able to contact"),
  business_days_until_appointment = c(5, 3, 0, 7),
  stringsAsFactors = FALSE
)

test_that("flags records with exclusions and valid wait time", {
  res <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df, output_dir = NA)
  )
  # Dr A (5 days, excluded) and Dr C (0 days, excluded) should be flagged
  expect_equal(nrow(res), 2L)
  expect_true(all(res$reason_for_exclusions != "Able to contact"))
  expect_true(all(res$business_days_until_appointment >= 0))
})

test_that("returns zero-row tibble when no discrepancies", {
  clean <- data.frame(
    reason_for_exclusions           = c("Able to contact", "Able to contact"),
    business_days_until_appointment = c(3, 5),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(clean, output_dir = NA)
  )
  expect_equal(nrow(res), 0L)
})

test_that("respects custom contact_value", {
  df2 <- df
  df2$reason_for_exclusions[df2$reason_for_exclusions == "Able to contact"] <- "Success"
  res <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df2, contact_value = "Success",
                                           output_dir = NA)
  )
  expect_equal(nrow(res), 2L)
})

test_that("respects min_days threshold", {
  res <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df, min_days = 3, output_dir = NA)
  )
  # Only Dr A has days >= 3 AND is excluded
  expect_equal(nrow(res), 1L)
  expect_equal(res$id_number, "001")
})

test_that("result sorted descending by id_number", {
  res <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df, output_dir = NA)
  )
  expect_true(res$id_number[1] > res$id_number[2])
})

test_that("writes CSV when output_dir is supplied", {
  td <- tempfile()
  dir.create(td)
  suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df, output_dir = td,
                                           filename = "disc_test.csv")
  )
  expect_true(file.exists(file.path(td, "disc_test.csv")))
})

test_that("errors on missing columns", {
  expect_error(
    mysterycall_flag_exclusion_discrepancy(df, days_col = "missing",
                                           output_dir = NA),
    "not found"
  )
  expect_error(
    mysterycall_flag_exclusion_discrepancy(df, exclusion_col = "missing",
                                           output_dir = NA),
    "not found"
  )
})
