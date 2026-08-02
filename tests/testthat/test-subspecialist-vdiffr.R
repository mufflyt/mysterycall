library(testthat)

# Visual regression tests. These render each figure and compare it against a
# committed SVG baseline under _snaps/. They are skipped on CRAN and when vdiffr
# (or its rendering stack) is unavailable, so they act as local/CI regression
# protection without becoming a portability liability. Baselines are created on
# the first run with `testthat::snapshot_accept()` / vdiffr's manager.
skip_if_not_installed("vdiffr")
skip_if_not_installed("ggplot2")

FEM_POP <- c(`2013` = 160000000, `2018` = 165000000, `2023` = 168000000)
COUNTS <- data.frame(
  subspecialty = rep(c("Gynecologic Oncology", "Urogynecology"), each = 3),
  year         = rep(c(2013L, 2018L, 2023L), times = 2),
  count        = c(1900, 2200, 2600, 900, 1400, 2100),
  stringsAsFactors = FALSE
)

test_that("trend figure is visually stable", {
  skip_on_cran()
  p <- suppressWarnings(mysterycall_subspecialist_trend(
    COUNTS, population = FEM_POP,
    caption = NA                       # keep baseline free of timestamps
  ))
  vdiffr::expect_doppelganger("subspecialist-trend", p)
})

test_that("trend figure with CI band is visually stable", {
  skip_on_cran()
  p <- suppressWarnings(mysterycall_subspecialist_trend(
    COUNTS, population = FEM_POP, conf_level = 0.95, caption = NA
  ))
  vdiffr::expect_doppelganger("subspecialist-trend-ci", p)
})

test_that("infographic is visually stable", {
  skip_on_cran()
  p <- suppressWarnings(mysterycall_subspecialist_infographic(
    subspecialty = c("Gynecologic Oncology", "Urogynecology"),
    start = c(1.19, 0.56),
    end   = c(1.55, 1.24),
    caption = NA                       # avoid the auto source/date caption
  ))
  vdiffr::expect_doppelganger("subspecialist-infographic", p)
})
