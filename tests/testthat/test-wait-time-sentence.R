make_wts_data <- function(seed = 1) {
  set.seed(seed)
  data.frame(
    scenario = rep(c("BCBS", "Medicaid", "Self-Pay"), each = 15),
    business_days_until_appointment = c(
      rpois(15, 7), rpois(15, 14), rpois(15, 21)
    ),
    stringsAsFactors = FALSE
  )
}

test_that("returns a named list with required elements", {
  df  <- make_wts_data()
  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, group_col = "scenario")
  )
  expect_type(res, "list")
  expect_true(all(c("sentence", "overall_stats", "group_stats", "p_values") %in%
                    names(res)))
})

test_that("sentence is a non-empty character scalar", {
  df  <- make_wts_data()
  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, group_col = "scenario")
  )
  expect_type(res$sentence, "character")
  expect_gt(nchar(res$sentence), 0L)
})

test_that("sentence contains correct overall median", {
  df <- data.frame(
    scenario = rep(c("A", "B"), each = 5),
    business_days_until_appointment = c(2, 4, 6, 8, 10, 12, 14, 16, 18, 20),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, group_col = "scenario", digits_median = 0)
  )
  expected_overall <- round(median(c(2, 4, 6, 8, 10, 12, 14, 16, 18, 20)), 0)
  expect_match(res$sentence, as.character(expected_overall))
})

test_that("sentence contains correct per-group medians", {
  df <- data.frame(
    group = c(rep("X", 4), rep("Y", 4)),
    days  = c(10, 10, 10, 10, 20, 20, 20, 20),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, outcome_col = "days",
                                   group_col = "group", digits_median = 0)
  )
  expect_match(res$sentence, "10")
  expect_match(res$sentence, "20")
})

test_that("overall_stats has correct structure", {
  df  <- make_wts_data()
  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, group_col = "scenario")
  )
  expect_true(all(c("median", "q1", "q3") %in% names(res$overall_stats)))
})

test_that("group_stats tibble has correct columns", {
  df  <- make_wts_data()
  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, group_col = "scenario")
  )
  expect_s3_class(res$group_stats, "data.frame")
  expect_true("median_days" %in% names(res$group_stats))
})

test_that("p_values named by non-reference levels", {
  df  <- make_wts_data()
  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, group_col = "scenario",
                                   reference = "BCBS")
  )
  pnames <- names(res$p_values)
  expect_false("BCBS" %in% pnames)
  expect_true("Medicaid" %in% pnames || "Self-Pay" %in% pnames)
})

test_that("p-values sentence clause appears in output", {
  df  <- make_wts_data()
  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, group_col = "scenario",
                                   reference = "BCBS")
  )
  expect_match(res$sentence, "p-value")
})

test_that("error on missing outcome column", {
  df <- data.frame(group = "A", wrong = 1, stringsAsFactors = FALSE)
  expect_error(
    mysterycall_wait_time_sentence(df, outcome_col = "days",
                                   group_col = "group"),
    "not found"
  )
})

test_that("error on missing group column", {
  df <- data.frame(days = 1:5, stringsAsFactors = FALSE)
  expect_error(
    mysterycall_wait_time_sentence(df, outcome_col = "days",
                                   group_col = "grp"),
    "not found"
  )
})

test_that("error on non-data-frame input", {
  expect_error(
    mysterycall_wait_time_sentence(list(a = 1), group_col = "a"),
    "`data` must be a data frame"
  )
})

test_that("single-level group skips p-value clause gracefully", {
  df <- data.frame(
    grp  = rep("Only", 5),
    days = c(1, 2, 3, 4, 5),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, outcome_col = "days",
                                   group_col = "grp")
  )
  # p_values should be empty
  expect_length(res$p_values, 0L)
})

test_that("filter_positive changes the overall median", {
  df <- data.frame(
    grp  = rep(c("A", "B"), 5),
    days = c(0, 0, 5, 10, 15, 20, 25, 30, 35, 40),
    stringsAsFactors = FALSE
  )
  res_all <- suppressMessages(
    mysterycall_wait_time_sentence(df, outcome_col = "days",
                                   group_col = "grp", filter_positive = FALSE)
  )
  res_pos <- suppressMessages(
    mysterycall_wait_time_sentence(df, outcome_col = "days",
                                   group_col = "grp", filter_positive = TRUE)
  )
  expect_gt(res_pos$overall_stats$median, res_all$overall_stats$median)
})

test_that("custom reference level is used", {
  df <- data.frame(
    arm  = rep(c("Control", "Treatment"), each = 10),
    days = c(rpois(10, 5), rpois(10, 10)),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, outcome_col = "days",
                                   group_col = "arm",
                                   reference = "Control")
  )
  expect_match(res$sentence, "vs Control")
})

test_that("error on invalid reference level", {
  df <- data.frame(
    grp  = rep(c("A", "B"), 5),
    days = 1:10,
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_wait_time_sentence(df, outcome_col = "days",
                                   group_col = "grp", reference = "Z"),
    "not found"
  )
})
