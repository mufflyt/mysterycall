# tests/testthat/test-scenario-summary.R

# ── helpers ────────────────────────────────────────────────────────────────────

make_scenario_df <- function(seed = 1L) {
  set.seed(seed)
  data.frame(
    scenario = sample(
      c("HIP scenario", "SHOULDER scenario", "KNEE scenario"),
      size = 30L, replace = TRUE,
      prob = c(0.5, 0.3, 0.2)
    ),
    status = sample(
      c("Able to contact", "Not reachable"),
      size = 30L, replace = TRUE,
      prob = c(0.8, 0.2)
    ),
    stringsAsFactors = FALSE
  )
}

sl <- c(
  hip      = "HIP scenario",
  shoulder = "SHOULDER scenario",
  knee     = "KNEE scenario"
)

# ── structural tests ───────────────────────────────────────────────────────────

test_that("scenario_summary: returns list with expected names", {
  df  <- make_scenario_df()
  res <- suppressMessages(mysterycall_scenario_summary(df, output_dir = NA))
  expect_true(is.list(res))
  expect_true(all(c("counts", "total", "sentence", "contact_counts") %in% names(res)))
})

test_that("scenario_summary: counts has columns scenario, count, percent", {
  df  <- make_scenario_df()
  res <- suppressMessages(mysterycall_scenario_summary(df, output_dir = NA))
  expect_true(all(c("scenario", "count", "percent") %in% names(res$counts)))
})

test_that("scenario_summary: percent sums to 100 (within rounding tolerance)", {
  df  <- make_scenario_df()
  res <- suppressMessages(mysterycall_scenario_summary(df, output_dir = NA))
  expect_lt(abs(sum(res$counts$percent) - 100), 0.5)
})

test_that("scenario_summary: total equals nrow(data)", {
  df  <- make_scenario_df()
  res <- suppressMessages(mysterycall_scenario_summary(df, output_dir = NA))
  expect_equal(res$total, nrow(df))
})

test_that("scenario_summary: contact_counts is NULL when contact_col not supplied", {
  df  <- make_scenario_df()
  res <- suppressMessages(mysterycall_scenario_summary(df, output_dir = NA))
  expect_null(res$contact_counts)
})

# ── semantic tests (with scenario_levels) ─────────────────────────────────────

test_that("scenario_summary: sentence with scenario_levels contains correct total", {
  set.seed(99L)
  df <- data.frame(
    scenario = c(
      rep("HIP scenario",      12L),
      rep("SHOULDER scenario",  7L),
      rep("KNEE scenario",      6L)
    ),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_scenario_summary(df, scenario_levels = sl, output_dir = NA)
  )
  expect_true(grepl("25", res$sentence))
  expect_true(grepl("12", res$sentence))
  expect_true(grepl("7",  res$sentence))
  expect_true(grepl("6",  res$sentence))
})

test_that("scenario_summary: sentence with scenario_levels uses level names", {
  df <- data.frame(
    scenario = c("HIP scenario", "SHOULDER scenario", "KNEE scenario"),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_scenario_summary(df, scenario_levels = sl, output_dir = NA)
  )
  expect_true(grepl("hip",      res$sentence))
  expect_true(grepl("shoulder", res$sentence))
  expect_true(grepl("knee",     res$sentence))
})

test_that("scenario_summary: generic sentence when scenario_levels = NULL", {
  df <- data.frame(
    scenario = c("A", "A", "B"),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_scenario_summary(df, output_dir = NA)
  )
  expect_true(grepl("3", res$sentence))
  expect_true(grepl("2", res$sentence))  # scenarios A and B
})

# ── adversarial tests ─────────────────────────────────────────────────────────

test_that("scenario_summary: missing scenario_col → error", {
  df <- data.frame(x = 1:3)
  expect_error(
    mysterycall_scenario_summary(df, scenario_col = "scenario", output_dir = NA),
    "missing"
  )
})

test_that("scenario_summary: non-data-frame → error", {
  expect_error(
    mysterycall_scenario_summary(list(a = 1), output_dir = NA),
    "data.frame"
  )
})

test_that("scenario_summary: empty data → zero total", {
  df <- data.frame(
    scenario = character(0L),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_scenario_summary(df, output_dir = NA)
  )
  expect_equal(res$total, 0L)
  expect_true(grepl("0", res$sentence))
})

test_that("scenario_summary: scenario_levels with level not in data → 0 count, no error", {
  df <- data.frame(
    scenario = c("HIP scenario", "HIP scenario"),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_scenario_summary(
      df,
      scenario_levels = sl,
      output_dir = NA
    )
  )
  # Should not error; counts for missing levels are 0
  expect_true(grepl("0", res$sentence))
})

test_that("scenario_summary: contact_col with all excluded → 0-row contact_counts", {
  df <- data.frame(
    scenario = c("A", "B", "C"),
    status   = c("Not reachable", "Not reachable", "Not reachable"),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_scenario_summary(
      df, contact_col = "status", contact_value = "Able to contact",
      output_dir = NA
    )
  )
  expect_equal(nrow(res$contact_counts), 0L)
})

test_that("scenario_summary: contact_col with some contacted → correct contact_counts", {
  df <- data.frame(
    scenario = c("A", "A", "B", "B"),
    status   = c("Able to contact", "Not reachable", "Able to contact", "Able to contact"),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_scenario_summary(
      df, contact_col = "status", contact_value = "Able to contact",
      output_dir = NA
    )
  )
  expect_equal(sum(res$contact_counts$count), 3L)
  b_row <- res$contact_counts[res$contact_counts$scenario == "B", ]
  expect_equal(b_row$count, 2L)
})

test_that("scenario_summary: single row data works", {
  df <- data.frame(scenario = "HIP scenario", stringsAsFactors = FALSE)
  res <- suppressMessages(
    mysterycall_scenario_summary(df, output_dir = NA)
  )
  expect_equal(res$total, 1L)
  expect_equal(res$counts$percent, 100)
})

test_that("scenario_summary: unnamed scenario_levels → error", {
  df <- data.frame(scenario = "HIP scenario", stringsAsFactors = FALSE)
  expect_error(
    mysterycall_scenario_summary(
      df, scenario_levels = c("HIP scenario", "KNEE scenario"),
      output_dir = NA
    ),
    "named"
  )
})

test_that("scenario_summary: counts are arranged descending by count", {
  df <- data.frame(
    scenario = c(rep("A", 10L), rep("B", 3L), rep("C", 7L)),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_scenario_summary(df, output_dir = NA)
  )
  expect_true(all(diff(res$counts$count) <= 0))
})
