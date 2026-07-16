test_that("returns a list of class mysterycall_kaplan_meier", {
  skip_if_not_installed("survival")
  df <- data.frame(
    days      = c(3, 7, 14, 21, 90, 5, 10, 30, 90, 90),
    offered   = c(1,  1,  1,  1,  0, 1,  1,  1,  0,  0),
    insurance = rep(c("Medicaid", "BCBS"), each = 5),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_kaplan_meier(
    data = df, time_col = "days", event_col = "offered",
    group_col = "insurance", plot = FALSE
  )
  expect_s3_class(result, "mysterycall_kaplan_meier")
  expect_type(result, "list")
})

test_that("logrank_p is numeric in [0, 1]", {
  skip_if_not_installed("survival")
  df <- data.frame(
    days      = c(3, 7, 14, 21, 90, 5, 10, 30, 90, 90),
    offered   = c(1,  1,  1,  1,  0, 1,  1,  1,  0,  0),
    insurance = rep(c("Medicaid", "BCBS"), each = 5),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_kaplan_meier(
    data = df, time_col = "days", event_col = "offered",
    group_col = "insurance", plot = FALSE
  )
  expect_type(result$logrank_p, "double")
  expect_true(result$logrank_p >= 0 && result$logrank_p <= 1)
})

test_that("logrank_p_fmt is a character string", {
  skip_if_not_installed("survival")
  df <- data.frame(
    days      = c(3, 7, 14, 21, 90, 5, 10, 30, 90, 90),
    offered   = c(1,  1,  1,  1,  0, 1,  1,  1,  0,  0),
    insurance = rep(c("Medicaid", "BCBS"), each = 5),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_kaplan_meier(
    data = df, time_col = "days", event_col = "offered",
    group_col = "insurance", plot = FALSE
  )
  expect_type(result$logrank_p_fmt, "character")
  expect_length(result$logrank_p_fmt, 1L)
  expect_match(result$logrank_p_fmt, "^p")
})

test_that("median_by_group is a data.frame with a group column", {
  skip_if_not_installed("survival")
  df <- data.frame(
    days      = c(3, 7, 14, 21, 90, 5, 10, 30, 90, 90),
    offered   = c(1,  1,  1,  1,  0, 1,  1,  1,  0,  0),
    insurance = rep(c("Medicaid", "BCBS"), each = 5),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_kaplan_meier(
    data = df, time_col = "days", event_col = "offered",
    group_col = "insurance", plot = FALSE
  )
  mbg <- result$median_by_group
  expect_s3_class(mbg, "data.frame")
  expect_true("group" %in% names(mbg))
  expect_true("median_days" %in% names(mbg))
})

test_that("sentence is a character string containing 'days'", {
  skip_if_not_installed("survival")
  df <- data.frame(
    days      = c(3, 7, 14, 21, 90, 5, 10, 30, 90, 90),
    offered   = c(1,  1,  1,  1,  0, 1,  1,  1,  0,  0),
    insurance = rep(c("Medicaid", "BCBS"), each = 5),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_kaplan_meier(
    data = df, time_col = "days", event_col = "offered",
    group_col = "insurance", plot = FALSE
  )
  expect_type(result$sentence, "character")
  expect_length(result$sentence, 1L)
  expect_match(result$sentence, "days", ignore.case = TRUE)
})

test_that("plot is NULL when plot = FALSE", {
  skip_if_not_installed("survival")
  df <- data.frame(
    days      = c(3, 7, 14, 21, 90, 5, 10, 30, 90, 90),
    offered   = c(1,  1,  1,  1,  0, 1,  1,  1,  0,  0),
    insurance = rep(c("Medicaid", "BCBS"), each = 5),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_kaplan_meier(
    data = df, time_col = "days", event_col = "offered",
    group_col = "insurance", plot = FALSE
  )
  expect_null(result$plot)
})

test_that("errors when time_col is not in data", {
  skip_if_not_installed("survival")
  df <- data.frame(
    days      = c(3, 7, 14, 21, 90, 5, 10, 30, 90, 90),
    offered   = c(1,  1,  1,  1,  0, 1,  1,  1,  0,  0),
    insurance = rep(c("Medicaid", "BCBS"), each = 5),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_kaplan_meier(
      data = df, time_col = "nonexistent_col", event_col = "offered",
      group_col = "insurance", plot = FALSE
    ),
    regexp = "nonexistent_col"
  )
})

test_that("errors when group_col is not in data", {
  skip_if_not_installed("survival")
  df <- data.frame(
    days      = c(3, 7, 14, 21, 90, 5, 10, 30, 90, 90),
    offered   = c(1,  1,  1,  1,  0, 1,  1,  1,  0,  0),
    insurance = rep(c("Medicaid", "BCBS"), each = 5),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_kaplan_meier(
      data = df, time_col = "days", event_col = "offered",
      group_col = "missing_group", plot = FALSE
    ),
    regexp = "missing_group"
  )
})

test_that("negative time values are clamped to zero without error", {
  skip_if_not_installed("survival")
  # The function uses pmax(0, ...) so negative times become 0; no error raised
  df <- data.frame(
    days      = c(-5, 7, 14, 21, 90, -3, 10, 30, 90, 90),
    offered   = c( 1, 1,  1,  1,  0,  0,  1,  1,  0,  0),
    insurance = rep(c("Medicaid", "BCBS"), each = 5),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_kaplan_meier(
    data = df, time_col = "days", event_col = "offered",
    group_col = "insurance", plot = FALSE
  )
  expect_s3_class(result, "mysterycall_kaplan_meier")
  # All times in the survfit object must be >= 0
  expect_true(all(result$survfit$time >= 0))
})

test_that("NA times are imputed to max_days for censored rows", {
  skip_if_not_installed("survival")
  # Rows with event = 0 (censored) and NA time should be treated as max_days
  df <- data.frame(
    days      = c(3, 7, 14, NA,  NA, 5, 10, 30, NA, NA),
    offered   = c(1, 1,  1,  0,   0, 1,  1,  1,  0,  0),
    insurance = rep(c("Medicaid", "BCBS"), each = 5),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_kaplan_meier(
    data = df, time_col = "days", event_col = "offered",
    group_col = "insurance", max_days = 90, plot = FALSE
  )
  expect_s3_class(result, "mysterycall_kaplan_meier")
  # The maximum time observed in the survfit should be at most max_days = 90
  expect_true(max(result$survfit$time) <= 90)
  # Sentence should still be valid
  expect_type(result$sentence, "character")
})

test_that("works with exactly two groups", {
  skip_if_not_installed("survival")
  df <- data.frame(
    wait_days = c(10, 20, 30, 45, 90, 8, 15, 25, 60, 90),
    appt      = c( 1,  1,  1,  1,  0, 1,  1,  0,  1,  0),
    payer     = rep(c("Private", "Medicaid"), each = 5),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_kaplan_meier(
    data = df, time_col = "wait_days", event_col = "appt",
    group_col = "payer", plot = FALSE
  )
  expect_s3_class(result, "mysterycall_kaplan_meier")
  expect_equal(nrow(result$median_by_group), 2L)
  grp_levels <- sort(result$median_by_group$group)
  expect_equal(grp_levels, sort(c("Private", "Medicaid")))
})


test_that("kaplan_meier drops empty factor levels (no phantom strata / -N labels)", {
  skip_if_not_installed("survival")
  set.seed(3)
  n  <- 120
  g  <- sample(c("A", "B", "C"), n, replace = TRUE)
  df <- data.frame(
    # a 4th factor level with zero observations must not create a phantom stratum
    grp       = factor(g, levels = c("A", "B", "Empty", "C")),
    wait_days = pmin(round(rexp(n, 1 / 20)), 90),
    appt      = rbinom(n, 1, 0.6)
  )
  result <- mysterycall_kaplan_meier(
    data = df, time_col = "wait_days", event_col = "appt",
    group_col = "grp", plot = FALSE
  )
  expect_equal(nrow(result$median_by_group), 3L)                  # A, B, C only
  expect_setequal(result$median_by_group$group, c("A", "B", "C"))
  expect_equal(length(result$survfit$strata), 3L)
})

test_that("kaplan_meier legend_title defaults to a prettified group_col and validates", {
  skip_if_not_installed("survival")
  skip_if_not_installed("ggplot2")
  df <- data.frame(
    wait_days = c(3, 7, 14, 21, 90, 5, 10, 30, 90, 90),
    appt      = c(1, 1, 1, 1, 0, 1, 1, 1, 0, 0),
    sub_type  = rep(c("x", "y"), each = 5),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_kaplan_meier(
    data = df, time_col = "wait_days", event_col = "appt",
    group_col = "sub_type", risk_table = FALSE
  )
  # default legend title is the prettified column name, not the raw "sub_type"
  gg <- if (inherits(res$plot, "patchwork")) res$plot[[1]] else res$plot
  expect_equal(gg$labels$colour, "Sub Type")

  expect_error(
    mysterycall_kaplan_meier(
      data = df, time_col = "wait_days", event_col = "appt",
      group_col = "sub_type", legend_title = c("a", "b"), plot = FALSE
    ),
    "single character string"
  )
})
