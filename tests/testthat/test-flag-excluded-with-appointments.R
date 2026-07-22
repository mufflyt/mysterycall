df <- data.frame(
  physician_information           = c("Dr A", "Dr B", "Dr C", "Dr D"),
  id_number                       = c("004", "002", "003", "001"),
  notes                           = rep(NA_character_, 4),
  reason_for_exclusions           = c("Not available", "Able to contact",
                                      "Not available", "Not available"),
  business_days_until_appointment = c(5L, 3L, 0L, NA_integer_),
  stringsAsFactors = FALSE
)

test_that("flags excluded records with a recorded wait (days >= 0, incl. same-day)", {
  res <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(df, output_dir = NA)
  )
  # Dr A (days=5) and Dr C (days=0, same-day) are excluded with a recorded wait
  expect_equal(nrow(res), 2L)
  expect_setequal(res$physician_information, c("Dr A", "Dr C"))
})

test_that("flags a same-day (days == 0) excluded record", {
  # A same-day appointment logged against an excluded reason is a discrepancy,
  # consistent with the same-day=0 convention and flag_exclusion_discrepancy (>=0).
  res <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(df, output_dir = NA)
  )
  expect_true("Dr C" %in% res$physician_information)
})

test_that("does not flag included records even with days > 0", {
  res <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(df, output_dir = NA)
  )
  expect_false("Dr B" %in% res$physician_information)
})

test_that("does not flag NA wait times", {
  res <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(df, output_dir = NA)
  )
  expect_false("Dr D" %in% res$physician_information)
})

test_that("returns zero-row result invisibly when no flags", {
  clean <- data.frame(
    reason_for_exclusions           = c("Able to contact", "Able to contact"),
    business_days_until_appointment = c(5L, 3L),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(clean, output_dir = NA)
  )
  expect_equal(nrow(res), 0L)
})

test_that("result sorted descending by id_number", {
  df2 <- rbind(df, data.frame(
    physician_information           = "Dr E",
    id_number                       = "010",
    notes                           = NA_character_,
    reason_for_exclusions           = "No answer",
    business_days_until_appointment = 7L,
    stringsAsFactors = FALSE
  ))
  res <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(df2, output_dir = NA)
  )
  if (nrow(res) >= 2L)
    expect_true(all(diff(as.integer(res$id_number)) <= 0))
})

test_that("writes CSV when output_dir is supplied", {
  td <- tempfile(); dir.create(td)
  suppressMessages(
    mysterycall_flag_excluded_with_appointments(df, output_dir = td,
                                                filename = "test_excl.csv")
  )
  expect_true(file.exists(file.path(td, "test_excl.csv")))
})

test_that("errors on missing days_col", {
  expect_error(
    mysterycall_flag_excluded_with_appointments(df, days_col = "missing",
                                                output_dir = NA),
    "not found"
  )
})

test_that("errors on missing exclusion_col", {
  expect_error(
    mysterycall_flag_excluded_with_appointments(df, exclusion_col = "missing",
                                                output_dir = NA),
    "not found"
  )
})
