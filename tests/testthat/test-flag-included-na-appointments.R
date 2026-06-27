df <- data.frame(
  physician_information           = c("Dr A", "Dr B", "Dr C", "Dr D"),
  id_number                       = c("001", "002", "003", "004"),
  notes                           = rep(NA_character_, 4),
  reason_for_exclusions           = c("Able to contact", "Able to contact",
                                      "Not available",   "Not available"),
  business_days_until_appointment = c(NA_integer_, 5L, NA_integer_, 3L),
  stringsAsFactors = FALSE
)

test_that("flags included records with NA wait time", {
  res <- suppressMessages(
    mysterycall_flag_included_na_appointments(df, output_dir = NA)
  )
  # Only Dr A: included but NA wait time
  expect_equal(nrow(res), 1L)
  expect_equal(res$physician_information, "Dr A")
})

test_that("does not flag included records with a valid wait time", {
  res <- suppressMessages(
    mysterycall_flag_included_na_appointments(df, output_dir = NA)
  )
  expect_false("Dr B" %in% res$physician_information)
})

test_that("does not flag excluded records with NA wait time", {
  res <- suppressMessages(
    mysterycall_flag_included_na_appointments(df, output_dir = NA)
  )
  expect_false("Dr C" %in% res$physician_information)
})

test_that("returns zero-row result when no flags", {
  clean <- data.frame(
    reason_for_exclusions           = c("Able to contact", "Not available"),
    business_days_until_appointment = c(5L, NA_integer_),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_flag_included_na_appointments(clean, output_dir = NA)
  )
  expect_equal(nrow(res), 0L)
})

test_that("custom contact_value works", {
  df2 <- df
  df2$reason_for_exclusions <- gsub("Able to contact", "Success",
                                    df2$reason_for_exclusions)
  res <- suppressMessages(
    mysterycall_flag_included_na_appointments(df2,
                                              contact_value = "Success",
                                              output_dir = NA)
  )
  expect_equal(nrow(res), 1L)
})

test_that("writes CSV when output_dir is supplied", {
  td <- tempfile(); dir.create(td)
  suppressMessages(
    mysterycall_flag_included_na_appointments(df, output_dir = td,
                                              filename = "test_na.csv")
  )
  expect_true(file.exists(file.path(td, "test_na.csv")))
})

test_that("errors on missing columns", {
  expect_error(
    mysterycall_flag_included_na_appointments(df, days_col = "missing",
                                              output_dir = NA),
    "not found"
  )
  expect_error(
    mysterycall_flag_included_na_appointments(df, exclusion_col = "missing",
                                              output_dir = NA),
    "not found"
  )
})
