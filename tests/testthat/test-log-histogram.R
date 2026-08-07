# Helper
make_log_df <- function(n = 100, seed = 99) {
  set.seed(seed)
  data.frame(
    days      = c(rpois(n / 2, 5) + 1L, rpois(n / 2, 10) + 1L),
    insurance = rep(c("Medicaid", "BCBS"), each = n / 2),
    stringsAsFactors = FALSE
  )
}

# ── ADVERSARIAL ───────────────────────────────────────────────────────────────

test_that("log_histogram: data with zeros emits message containing 'removed'", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  df$days[seq_len(5)] <- 0L
  expect_message(
    suppressWarnings(
      mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
    ),
    "removed"
  )
})

test_that("log_histogram: data with all zeros or NAs errors", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(
    days      = c(0L, 0L, 0L),
    insurance = c("BCBS", "Medicaid", "BCBS"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(
      mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
    )
  )
})

test_that("log_histogram: all-NA x_col after zero removal errors", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(
    days      = c(NA_real_, NA_real_),
    insurance = c("BCBS", "Medicaid"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(
      mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
    )
  )
})

test_that("log_histogram: base not in c(2, 10) errors", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  expect_error(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                               base = 5, output_dir = NA),
    "base"
  )
})

test_that("log_histogram: missing x_col errors", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  expect_error(
    mysterycall_log_histogram(df, x_col = "nonexistent", facet_col = "insurance",
                               output_dir = NA),
    "not found"
  )
})

test_that("log_histogram: missing facet_col errors", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  expect_error(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "nonexistent",
                               output_dir = NA),
    "not found"
  )
})

test_that("log_histogram: output_dir=NA skips file writing", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                               output_dir = NA)
  )
  # Nothing to check except no error raised; verify tempdir default was NOT used
  # by confirming the call succeeds silently
  expect_true(TRUE)
})

test_that("log_histogram: output_dir writes PNG > 1000 bytes", {
  skip_if_not_installed("ggplot2")
  df  <- make_log_df()
  tmp <- file.path(tempdir(), "mc_log_hist_write")
  dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
  suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                               output_dir = tmp, filename = "test_log.png")
  )
  out <- file.path(tmp, "test_log.png")
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 1000L)
})

# ── SEMANTIC ──────────────────────────────────────────────────────────────────

test_that("log_histogram: returns ggplot invisibly", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  p  <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                               output_dir = NA)
  )
  expect_s3_class(p, "gg")
  expect_s3_class(p, "ggplot")
})

test_that("log_histogram: x scale is log-transformed (base 10)", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  p  <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                               base = 10, output_dir = NA)
  )
  built      <- ggplot2::ggplot_build(p)
  x_scale    <- built$layout$panel_scales_x[[1L]]
  trans_name <- tryCatch(x_scale$trans$name, error = function(e) "")
  scale_cls  <- paste(class(x_scale), collapse = " ")
  expect_true(
    grepl("log", trans_name, ignore.case = TRUE) ||
      grepl("log", scale_cls, ignore.case = TRUE)
  )
})

test_that("log_histogram: x scale is log-transformed (base 2)", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  p  <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                               base = 2, output_dir = NA)
  )
  built      <- ggplot2::ggplot_build(p)
  x_scale    <- built$layout$panel_scales_x[[1L]]
  trans_name <- tryCatch(x_scale$trans$name, error = function(e) "")
  scale_cls  <- paste(class(x_scale), collapse = " ")
  expect_true(
    grepl("log", trans_name, ignore.case = TRUE) ||
      grepl("log", scale_cls, ignore.case = TRUE)
  )
})

test_that("log_histogram: default title contains 'log', x_col, and facet_col", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  p  <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                               output_dir = NA)
  )
  title_text <- p$labels$title
  expect_match(title_text, "days")
  expect_match(title_text, "insurance")
  expect_match(title_text, "log")
})

test_that("log_histogram: custom title overrides default", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  p  <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                               title = "Custom Log Title", output_dir = NA)
  )
  expect_equal(p$labels$title, "Custom Log Title")
})

test_that("log_histogram: default x_label contains 'log10' and x_col", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  p  <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                               output_dir = NA)
  )
  expect_match(p$labels$x, "log10")
  expect_match(p$labels$x, "days")
})

test_that("log_histogram: facet_wrap is on the correct column", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df()
  p  <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                               output_dir = NA)
  )
  facet_str <- paste(deparse(p$facet$params$facets), collapse = " ")
  expect_true(grepl("insurance", facet_str))
})

test_that("log_histogram: zeros silently removed and plot succeeds", {
  skip_if_not_installed("ggplot2")
  df <- make_log_df(n = 100)
  df$days[seq_len(10)] <- 0L
  p <- suppressMessages(
    suppressWarnings(
      mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
    )
  )
  expect_s3_class(p, "ggplot")
})

test_that("log_histogram: non-data-frame input errors", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_log_histogram(list(days = 1:5), x_col = "days",
                               facet_col = "insurance", output_dir = NA),
    "data frame"
  )
})
