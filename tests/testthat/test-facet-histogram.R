# Helper
make_hist_df <- function(n = 120, seed = 42) {
  set.seed(seed)
  data.frame(
    days      = c(rpois(n / 2, 5), rpois(n / 2, 10)),
    insurance = rep(c("Medicaid", "BCBS"), each = n / 2),
    stringsAsFactors = FALSE
  )
}

# ── ADVERSARIAL ───────────────────────────────────────────────────────────────

test_that("facet_histogram: missing x_col errors", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  expect_error(
    mysterycall_facet_histogram(df, x_col = "nonexistent", facet_col = "insurance",
                                 output_dir = NA),
    "not found"
  )
})

test_that("facet_histogram: missing facet_col errors", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  expect_error(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "nonexistent",
                                 output_dir = NA),
    "not found"
  )
})

test_that("facet_histogram: non-data-frame input errors", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_facet_histogram(list(days = 1:5), x_col = "days",
                                 facet_col = "insurance", output_dir = NA),
    "data frame"
  )
})

test_that("facet_histogram: all-NA x_col does not crash", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(days = NA_real_, insurance = "BCBS", stringsAsFactors = FALSE)
  p <- suppressMessages(suppressWarnings(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
  ))
  expect_s3_class(p, "ggplot")
})

test_that("facet_histogram: single-row data does not crash", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(days = 3L, insurance = "Medicaid", stringsAsFactors = FALSE)
  p <- suppressMessages(suppressWarnings(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
  ))
  expect_s3_class(p, "ggplot")
})

test_that("facet_histogram: output_dir=NA skips file writing", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  tmp_fn <- file.path(tempdir(), "facet_histogram_skip_check.png")
  if (file.exists(tmp_fn)) file.remove(tmp_fn)
  suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA,
                                 filename = basename(tmp_fn))
  )
  # The file in the tempdir should NOT have been written (output_dir = NA)
  expect_false(file.exists(tmp_fn))
})

test_that("facet_histogram: output_dir writes PNG > 1000 bytes", {
  skip_if_not_installed("ggplot2")
  df  <- make_hist_df()
  tmp <- file.path(tempdir(), "mc_facet_hist_write")
  dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
  suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = tmp, filename = "test_facet.png")
  )
  out <- file.path(tmp, "test_facet.png")
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 1000L)
})

# ── SEMANTIC ──────────────────────────────────────────────────────────────────

test_that("facet_histogram: returns ggplot invisibly", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  p  <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
  )
  expect_s3_class(p, "gg")
  expect_s3_class(p, "ggplot")
})

test_that("facet_histogram: title contains N value", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df(n = 100)
  p  <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
  )
  expect_match(p$labels$title, "100")
})

test_that("facet_histogram: N in title matches manual non-NA count", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df(n = 80)
  df$days[seq_len(7)] <- NA
  expected_n <- sum(!is.na(df$days))
  p <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
  )
  expect_match(p$labels$title, as.character(expected_n))
})

test_that("facet_histogram: custom title overrides default", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  p  <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 title = "My Custom Title", output_dir = NA)
  )
  expect_equal(p$labels$title, "My Custom Title")
})

test_that("facet_histogram: x aesthetic maps to x_col", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  p  <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
  )
  x_map <- rlang::as_label(p$mapping$x)
  expect_true(grepl("days", x_map))
})

test_that("facet_histogram: facet_wrap is on the correct column", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  p  <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
  )
  facet_str <- paste(deparse(p$facet$params$facets), collapse = " ")
  expect_true(grepl("insurance", facet_str))
})

test_that("facet_histogram: show_mean_line=TRUE adds GeomVline layer", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  p  <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 show_mean_line = TRUE, output_dir = NA)
  )
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1L], character(1L))
  expect_true(any(grepl("GeomVline", layer_geoms)))
})

test_that("facet_histogram: show_mean_line=FALSE omits GeomVline layer", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  p  <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 show_mean_line  = FALSE,
                                 show_stats_text = FALSE,
                                 output_dir = NA)
  )
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1L], character(1L))
  expect_false(any(grepl("GeomVline", layer_geoms)))
})

test_that("facet_histogram: show_stats_text=TRUE adds GeomText layer", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  p  <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 show_stats_text = TRUE, output_dir = NA)
  )
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1L], character(1L))
  expect_true(any(grepl("GeomText", layer_geoms)))
})

test_that("facet_histogram: default x_label falls back to x_col", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  p  <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 output_dir = NA)
  )
  expect_equal(p$labels$x, "days")
})

test_that("facet_histogram: custom x_label is applied", {
  skip_if_not_installed("ggplot2")
  df <- make_hist_df()
  p  <- suppressMessages(
    mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
                                 x_label = "Business Days", output_dir = NA)
  )
  expect_equal(p$labels$x, "Business Days")
})
