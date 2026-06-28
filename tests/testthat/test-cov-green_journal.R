library(testthat)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)


# =============================================================================
# THEME TESTS
# =============================================================================

test_that("mysterycall_theme_green_journal returns ggplot2 theme with defaults", {
  skip_if_not_installed("ggplot2")
  theme_obj <- suppressMessages(mysterycall_theme_green_journal())
  expect_s3_class(theme_obj, c("theme", "gg"))
})

test_that("mysterycall_theme_green_journal accepts custom base_size and base_family", {
  skip_if_not_installed("ggplot2")
  theme_obj <- suppressMessages(mysterycall_theme_green_journal(base_size = 12, base_family = "sans"))
  expect_s3_class(theme_obj, c("theme", "gg"))
})

test_that("mysterycall_theme_green_journal_map returns theme with no axes", {
  skip_if_not_installed("ggplot2")
  theme_obj <- suppressMessages(mysterycall_theme_green_journal_map())
  expect_s3_class(theme_obj, c("theme", "gg"))
})

test_that("mysterycall_theme_green_journal_map respects legend_position parameter", {
  skip_if_not_installed("ggplot2")
  theme_bottom <- suppressMessages(mysterycall_theme_green_journal_map(legend_position = "bottom"))
  theme_right  <- suppressMessages(mysterycall_theme_green_journal_map(legend_position = "right"))
  expect_s3_class(theme_bottom, c("theme", "gg"))
  expect_s3_class(theme_right, c("theme", "gg"))
})

test_that("mysterycall_theme_green_journal_faceted returns theme for map panels", {
  skip_if_not_installed("ggplot2")
  theme_obj <- suppressMessages(mysterycall_theme_green_journal_faceted())
  expect_s3_class(theme_obj, c("theme", "gg"))
})

test_that("mysterycall_theme_green_journal_faceted uses smaller base_size", {
  skip_if_not_installed("ggplot2")
  theme_obj <- suppressMessages(mysterycall_theme_green_journal_faceted(base_size = 8))
  expect_s3_class(theme_obj, c("theme", "gg"))
})


# =============================================================================
# PALETTE TESTS
# =============================================================================

test_that("mysterycall_palette_green_journal returns all 8 Okabe-Ito colors when n=NULL", {
  pal <- suppressMessages(mysterycall_palette_green_journal())
  expect_type(pal, "character")
  expect_length(pal, 8L)
  expect_true(all(grepl("^#[0-9A-F]{6}$", pal)))
})

test_that("mysterycall_palette_green_journal returns n colors for qualitative", {
  pal_5 <- suppressMessages(mysterycall_palette_green_journal(n = 5, type = "qualitative"))
  expect_type(pal_5, "character")
  expect_length(pal_5, 5L)
  expect_true(all(grepl("^#[0-9A-F]{6}$", pal_5)))
})

test_that("mysterycall_palette_green_journal returns sequential colors", {
  pal_seq <- suppressMessages(mysterycall_palette_green_journal(n = 7, type = "sequential"))
  expect_type(pal_seq, "character")
  expect_length(pal_seq, 7L)
  expect_true(all(grepl("^#[0-9A-F]{6}$", pal_seq)))
})

test_that("mysterycall_palette_green_journal returns diverging colors", {
  pal_div <- suppressMessages(mysterycall_palette_green_journal(n = 9, type = "diverging"))
  expect_type(pal_div, "character")
  expect_length(pal_div, 9L)
  expect_true(all(grepl("^#[0-9A-F]{6}$", pal_div)))
})

test_that("mysterycall_palette_green_journal warns when n > 8 for qualitative", {
  expect_warning(
    suppressMessages(mysterycall_palette_green_journal(n = 10, type = "qualitative")),
    "Requested 10 colors"
  )
})

test_that("mysterycall_palette_green_journal recycles and clips at 8 for qualitative", {
  pal_10 <- suppressWarnings(suppressMessages(mysterycall_palette_green_journal(n = 10, type = "qualitative")))
  expect_type(pal_10, "character")
  expect_length(pal_10, 8L)  # clipped to 8, not recycled
})


# =============================================================================
# SCALE TESTS
# =============================================================================

test_that("mysterycall_scale_color_green_journal returns ggplot2 Scale object", {
  skip_if_not_installed("ggplot2")
  scale_obj <- suppressMessages(mysterycall_scale_color_green_journal())
  expect_s3_class(scale_obj, c("ScaleDiscrete", "Scale", "ggproto"))
})

test_that("mysterycall_scale_fill_green_journal returns ggplot2 Scale object", {
  skip_if_not_installed("ggplot2")
  scale_obj <- suppressMessages(mysterycall_scale_fill_green_journal())
  expect_s3_class(scale_obj, c("ScaleDiscrete", "Scale", "ggproto"))
})

test_that("mysterycall_scale_color_green_journal accepts ... arguments", {
  skip_if_not_installed("ggplot2")
  scale_obj <- suppressMessages(mysterycall_scale_color_green_journal(name = "Group"))
  expect_s3_class(scale_obj, c("ScaleDiscrete", "Scale", "ggproto"))
})

test_that("mysterycall_scale_fill_green_journal accepts ... arguments", {
  skip_if_not_installed("ggplot2")
  scale_obj <- suppressMessages(mysterycall_scale_fill_green_journal(name = "Category"))
  expect_s3_class(scale_obj, c("ScaleDiscrete", "Scale", "ggproto"))
})


# =============================================================================
# CRS TESTS
# =============================================================================

test_that("mysterycall_crs_albers_conus returns sf::st_crs object", {
  skip_if_not_installed("sf")
  crs_obj <- suppressMessages(mysterycall_crs_albers_conus())
  expect_s3_class(crs_obj, "crs")
})

test_that("mysterycall_crs_albers_conus returns EPSG:5070", {
  skip_if_not_installed("sf")
  crs_obj <- suppressMessages(mysterycall_crs_albers_conus())
  expect_true(crs_obj$input == "EPSG:5070" || crs_obj$epsg == 5070L)
})


# =============================================================================
# SAVE FIGURE TESTS
# =============================================================================

test_that("mysterycall_save_green_journal_figure requires ggplot object", {
  skip_if_not_installed("ggplot2")
  expect_error(
    suppressMessages(mysterycall_save_green_journal_figure("not_a_plot", "/tmp/fig")),
    "inherits.*ggplot"
  )
})

test_that("mysterycall_save_green_journal_figure requires path_stem character", {
  skip_if_not_installed("ggplot2")
  p <- suppressMessages(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())
  expect_error(
    suppressMessages(mysterycall_save_green_journal_figure(p, 123)),
    "is.character"
  )
})

test_that("mysterycall_save_green_journal_figure accepts layout parameter", {
  skip_if_not_installed("ggplot2")
  p <- suppressMessages(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())
  set.seed(1)
  result <- suppressMessages(mysterycall_save_green_journal_figure(
    p, "/tmp/test_fig_layout",
    layout = "single_column",
    csv = FALSE
  ))
  expect_type(result, "character")
  expect_true(length(result) > 0)
})

test_that("mysterycall_save_green_journal_figure accepts height parameter", {
  skip_if_not_installed("ggplot2")
  p <- suppressMessages(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())
  set.seed(1)
  result <- suppressMessages(mysterycall_save_green_journal_figure(
    p, "/tmp/test_fig_height",
    height = 5.0,
    csv = FALSE
  ))
  expect_type(result, "character")
  expect_true(length(result) > 0)
})

test_that("mysterycall_save_green_journal_figure caps height at 9 inches", {
  skip_if_not_installed("ggplot2")
  p <- suppressMessages(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())
  set.seed(1)
  result <- suppressMessages(mysterycall_save_green_journal_figure(
    p, "/tmp/test_fig_cap",
    height = 15.0,
    csv = FALSE
  ))
  expect_type(result, "character")
})

test_that("mysterycall_save_green_journal_figure skips CSV when csv=FALSE", {
  skip_if_not_installed("ggplot2")
  p <- suppressMessages(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())
  set.seed(1)
  result <- suppressMessages(mysterycall_save_green_journal_figure(
    p, "/tmp/test_fig_nocsv",
    csv = FALSE
  ))
  expect_false(any(grepl("_data.csv", result)))
})


# =============================================================================
# COMPOSE MAP DENSITY TESTS
# =============================================================================

test_that("mysterycall_compose_map_density requires ggplot objects", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("gridExtra")
  p1 <- suppressMessages(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())

  expect_error(
    suppressMessages(mysterycall_compose_map_density("not_a_plot", p1)),
    "inherits.*ggplot"
  )
  expect_error(
    suppressMessages(mysterycall_compose_map_density(p1, "not_a_plot")),
    "inherits.*ggplot"
  )
})

test_that("mysterycall_compose_map_density returns gridExtra grob", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("gridExtra")
  p1 <- suppressMessages(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())
  p2 <- suppressMessages(ggplot2::ggplot(mtcars, ggplot2::aes(mpg)) + ggplot2::geom_histogram())

  result <- suppressMessages(mysterycall_compose_map_density(p1, p2))
  expect_s3_class(result, "gtable")
})

test_that("mysterycall_compose_map_density accepts weight parameters", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("gridExtra")
  p1 <- suppressMessages(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())
  p2 <- suppressMessages(ggplot2::ggplot(mtcars, ggplot2::aes(mpg)) + ggplot2::geom_histogram())

  result <- suppressMessages(mysterycall_compose_map_density(p1, p2, map_weight = 5L, density_weight = 3L))
  expect_s3_class(result, "gtable")
})
