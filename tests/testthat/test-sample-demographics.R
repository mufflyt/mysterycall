df <- data.frame(
  id_number = paste0("P", 1:6),
  phone     = paste0("555-000", 1:6),
  state     = c("Colorado", "Texas", "Colorado", "Florida", "Texas", "Georgia"),
  insurance = c("Medicaid", "Medicaid", "Blue Cross/Blue Shield",
                "Blue Cross/Blue Shield", "Medicaid", "Blue Cross/Blue Shield"),
  stringsAsFactors = FALSE
)

custom_states <- c("Colorado", "Texas", "Florida", "Georgia", "Nevada")

test_that("unique_physicians_count equals nrow(data)", {
  res <- suppressMessages(
    mysterycall_sample_demographics(df, output_dir = NA)
  )
  expect_equal(res$unique_physicians_count, 6L)
  expect_equal(res$total_calls, 6L)
})

test_that("excluded_states are states not in data", {
  res <- suppressMessages(
    mysterycall_sample_demographics(df, all_states = custom_states,
                                    output_dir = NA)
  )
  expect_true("Nevada" %in% res$excluded_states)
  expect_false("Colorado" %in% res$excluded_states)
})

test_that("num_included_states is correct", {
  res <- suppressMessages(
    mysterycall_sample_demographics(df, all_states = custom_states,
                                    output_dir = NA)
  )
  expect_equal(res$num_included_states, 4L)  # all 5 minus Nevada
})

test_that("excluded_states_series ends with 'and' for multiple states", {
  missing_states <- c("Alpha", "Beta", "Gamma")
  states_all <- c(unique(df$state), missing_states)
  res <- suppressMessages(
    mysterycall_sample_demographics(df, all_states = states_all,
                                    output_dir = NA)
  )
  expect_true(grepl(" and ", res$excluded_states_series))
})

test_that("excluded_states_series is a single name when only one excluded", {
  states_all <- c(unique(df$state), "Wyoming")
  res <- suppressMessages(
    mysterycall_sample_demographics(df, all_states = states_all,
                                    output_dir = NA)
  )
  expect_equal(res$excluded_states_series, "Wyoming")
})

test_that("excluded_states_series is 'No states were excluded.' when all covered", {
  res <- suppressMessages(
    mysterycall_sample_demographics(df, all_states = unique(df$state),
                                    output_dir = NA)
  )
  expect_equal(res$excluded_states_series, "No states were excluded.")
})

test_that("summary_sentence is a non-empty character scalar", {
  res <- suppressMessages(
    mysterycall_sample_demographics(df, all_states = custom_states,
                                    output_dir = NA)
  )
  expect_type(res$summary_sentence, "character")
  expect_true(nchar(res$summary_sentence) > 0L)
  expect_true(grepl("calls", res$summary_sentence))
})

test_that("count_by_insurance is a named integer vector", {
  res <- suppressMessages(
    mysterycall_sample_demographics(df, output_dir = NA)
  )
  expect_type(res$count_by_insurance, "integer")
  expect_true("Medicaid" %in% names(res$count_by_insurance))
})

test_that("errors on missing required columns", {
  expect_error(
    mysterycall_sample_demographics(df, id_col = "npi", output_dir = NA),
    "missing"
  )
  expect_error(
    mysterycall_sample_demographics(df, state_col = "region", output_dir = NA),
    "missing"
  )
})

test_that("writes CSV when output_dir supplied", {
  td <- tempfile(); dir.create(td)
  suppressMessages(
    mysterycall_sample_demographics(df, output_dir = td, filename = "demo.csv")
  )
  expect_true(file.exists(file.path(td, "demo.csv")))
})
