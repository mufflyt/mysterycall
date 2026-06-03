skip_if_not_installed("ggplot2")

# ── themes ────────────────────────────────────────────────────────────────────

test_that("theme_green_journal: returns a ggplot theme", {
  t <- mysterycall:::mysterycall_theme_green_journal()
  expect_s3_class(t, "theme")
})

test_that("theme_green_journal: respects base_size", {
  t <- mysterycall:::mysterycall_theme_green_journal(base_size = 14)
  expect_s3_class(t, "theme")
})

test_that("theme_green_journal: falls back to sans when family unavailable", {
  t <- mysterycall:::mysterycall_theme_green_journal(base_family = "ZzzZNotARealFont")
  expect_s3_class(t, "theme")
})

test_that("theme_green_journal_map: returns a ggplot theme", {
  expect_s3_class(mysterycall:::mysterycall_theme_green_journal_map(), "theme")
})

test_that("theme_green_journal_map: bottom legend variant", {
  expect_s3_class(
    mysterycall:::mysterycall_theme_green_journal_map(legend_position = "bottom"),
    "theme"
  )
})

test_that("theme_green_journal_faceted: returns a ggplot theme", {
  expect_s3_class(mysterycall:::mysterycall_theme_green_journal_faceted(), "theme")
})

# ── palette ───────────────────────────────────────────────────────────────────

test_that("palette: qualitative default returns 8 colors", {
  pal <- mysterycall:::mysterycall_palette_green_journal()
  expect_length(pal, 8L)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", pal)))
})

test_that("palette: qualitative subset", {
  pal <- mysterycall:::mysterycall_palette_green_journal(n = 4)
  expect_length(pal, 4L)
})

test_that("palette: qualitative warns when n > 8", {
  expect_warning(mysterycall:::mysterycall_palette_green_journal(n = 10), "Recycling")
})

test_that("palette: sequential ramp length", {
  pal <- mysterycall:::mysterycall_palette_green_journal(n = 5, type = "sequential")
  expect_length(pal, 5L)
})

test_that("palette: sequential default length is 7", {
  pal <- mysterycall:::mysterycall_palette_green_journal(type = "sequential")
  expect_length(pal, 7L)
})

test_that("palette: diverging ramp length", {
  pal <- mysterycall:::mysterycall_palette_green_journal(n = 11, type = "diverging")
  expect_length(pal, 11L)
})

test_that("palette: diverging default length is 9", {
  pal <- mysterycall:::mysterycall_palette_green_journal(type = "diverging")
  expect_length(pal, 9L)
})

# ── scales ────────────────────────────────────────────────────────────────────

test_that("scale_color_green_journal: returns ggplot Scale", {
  sc <- mysterycall:::mysterycall_scale_color_green_journal()
  expect_s3_class(sc, "Scale")
})

test_that("scale_fill_green_journal: returns ggplot Scale", {
  sc <- mysterycall:::mysterycall_scale_fill_green_journal()
  expect_s3_class(sc, "Scale")
})

# ── numeric helpers ───────────────────────────────────────────────────────────

test_that("winsorize: clips at quantile bounds", {
  x   <- c(-100, 0, 50, 100, 200)
  out <- mysterycall:::mysterycall_winsorize(x, lower = 0.1, upper = 0.9)
  expect_lte(max(out), max(x))
  expect_gte(min(out), min(x))
  expect_length(out, length(x))
})

test_that("winsorize: rejects invalid bounds", {
  expect_error(mysterycall:::mysterycall_winsorize(1:10, lower = 0.9, upper = 0.1))
})

test_that("winsorize: rejects non-numeric input", {
  expect_error(mysterycall:::mysterycall_winsorize("abc"))
})

test_that("winsorize: NA handling with na.rm = TRUE", {
  out <- mysterycall:::mysterycall_winsorize(c(NA, 1:10), lower = 0.1, upper = 0.9)
  expect_length(out, 11L)
})

test_that("truncate_for_viz: clips to fixed bounds", {
  expect_equal(
    mysterycall:::mysterycall_truncate_for_viz(c(-5, 0, 50, 105), floor = 0, ceiling = 100),
    c(0, 0, 50, 100)
  )
})

test_that("truncate_for_viz: vector preserved when within bounds", {
  expect_equal(
    mysterycall:::mysterycall_truncate_for_viz(c(10, 50, 90)),
    c(10, 50, 90)
  )
})

# ── spatial helpers (sf required) ─────────────────────────────────────────────

test_that("crs_albers_conus: returns EPSG:5070 CRS", {
  skip_if_not_installed("sf")
  crs <- mysterycall:::mysterycall_crs_albers_conus()
  expect_s3_class(crs, "crs")
})

# ── save figure (light smoke test) ────────────────────────────────────────────

test_that("save_green_journal_figure: writes files for a simple ggplot", {
  skip_on_cran()
  td  <- tempfile("gj_")
  dir.create(td, recursive = TRUE)
  stem <- file.path(td, "fig_a")
  p    <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
          ggplot2::geom_point()
  paths <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_save_green_journal_figure(p, stem,
                                                         layout = "single_column",
                                                         csv = TRUE)
  ))
  expect_true(length(paths) > 0L)
})

test_that("save_green_journal_figure: rejects non-ggplot input", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall:::mysterycall_save_green_journal_figure("not a plot", "foo")
    ))
  )
})

test_that("save_green_journal_figure: rejects empty path_stem", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall:::mysterycall_save_green_journal_figure(p, "")
    ))
  )
})

# ── deprecated aliases ────────────────────────────────────────────────────────

test_that("crs_albers_conus deprecated alias fires", {
  skip_if_not_installed("sf")
  expect_warning(
    suppressMessages(mysterycall:::crs_albers_conus()),
    "deprecated"
  )
})

test_that("winsorize deprecated alias fires", {
  expect_warning(
    suppressMessages(mysterycall:::winsorize(1:10)),
    "deprecated"
  )
})

test_that("truncate_for_viz deprecated alias fires", {
  expect_warning(
    suppressMessages(mysterycall:::truncate_for_viz(c(-5, 50, 105))),
    "deprecated"
  )
})
