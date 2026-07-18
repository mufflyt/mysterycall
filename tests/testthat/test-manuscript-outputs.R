# Tests for the manuscript-output improvements:
#  1. multi_model_table cell_layout (Table S7 pipe-table fix)
#  2. kaplan_meier ylab (plain-language Y-axis)
#  3. forest_plot / irr_plot show_significance_legend
#  4. mysterycall_region_labels (AAO-HNS state labels)

# helper: pull a scale's `name` for a given aesthetic off a ggplot
.get_scale_name <- function(p, aes) {
  for (s in p$scales$scales) if (any(s$aesthetics == aes)) return(s$name)
  NULL
}

# ---- 1. multi_model_table cell_layout ---------------------------------------

test_that("cell_layout controls the estimate/p-value separator", {
  skip_if_not_installed("lme4")
  make_pois <- function(seed) {
    set.seed(seed)
    df <- data.frame(
      y = rpois(80, 4),
      x = factor(sample(c("a", "b"), 80, TRUE)),
      g = factor(sample(letters[1:6], 80, TRUE))
    )
    mysterycall_poisson_model(df, outcome = "y", predictors = "x",
                              random_intercept = "g")
  }
  models <- list(m1 = make_pois(1), m2 = make_pois(2))

  stacked <- mysterycall_multi_model_table(models, cell_layout = "stacked")
  inline  <- mysterycall_multi_model_table(models, cell_layout = "inline")

  data_cells <- function(tb) {
    v <- unlist(tb_body <- tb[, -1, drop = FALSE], use.names = FALSE)
    v[grepl("p=", v, fixed = TRUE)]
  }
  sc <- data_cells(stacked)
  ic <- data_cells(inline)

  expect_true(any(grepl("\n", sc, fixed = TRUE)))          # stacked has newline
  expect_false(any(grepl("\n", ic, fixed = TRUE)))         # inline has none
  expect_true(all(grepl(", p=", ic, fixed = TRUE)))        # inline uses ", p="
})

test_that("cell_layout rejects an unknown value", {
  expect_error(
    mysterycall_multi_model_table(list(a = 1, b = 2), cell_layout = "nope"),
    "should be one of"
  )
})

# ---- 2. kaplan_meier ylab ---------------------------------------------------

test_that("kaplan_meier ylab overrides the y-axis label", {
  skip_if_not_installed("survival")
  skip_if_not_installed("ggplot2")
  set.seed(3)
  d <- data.frame(
    days      = c(rpois(20, 8), rpois(20, 18)),
    offered   = rbinom(40, 1, 0.7),
    insurance = rep(c("Commercial", "Medicaid"), each = 20)
  )
  res <- mysterycall_kaplan_meier(
    d, time_col = "days", event_col = "offered", group_col = "insurance",
    ylab = "Callers awaiting care (%)", risk_table = FALSE
  )
  expect_false(is.null(res$plot))
  expect_identical(.get_scale_name(res$plot, "y"), "Callers awaiting care (%)")
})

test_that("kaplan_meier default y-axis label is plain language (no 'Probability')", {
  skip_if_not_installed("survival")
  skip_if_not_installed("ggplot2")
  set.seed(4)
  d <- data.frame(
    days      = c(rpois(20, 8), rpois(20, 18)),
    offered   = rbinom(40, 1, 0.7),
    insurance = rep(c("A", "B"), each = 20)
  )
  res <- mysterycall_kaplan_meier(d, time_col = "days", group_col = "insurance",
                                  risk_table = FALSE)
  expect_match(.get_scale_name(res$plot, "y"), "awaiting")
})

# ---- 3. forest_plot / irr_plot show_significance_legend ---------------------

fp_df <- data.frame(
  term     = c("A", "B", "C"),
  irr      = c(1.20, 0.80, 1.50),
  ci_lower = c(1.05, 0.60, 1.10),
  ci_upper = c(1.40, 1.05, 2.00),
  p_value  = c(0.01, 0.30, 0.02),
  stringsAsFactors = FALSE
)

test_that("forest_plot hides the significance legend by default and shows it on request", {
  skip_if_not_installed("ggplot2")
  p_off <- suppressMessages(mysterycall_forest_plot(fp_df))
  p_on  <- suppressMessages(mysterycall_forest_plot(fp_df, show_significance_legend = TRUE))
  expect_identical(p_off$theme$legend.position, "none")
  expect_identical(p_on$theme$legend.position, "top")
})

test_that("irr_plot legend toggles and adds a colour scale only when shown", {
  skip_if_not_installed("ggplot2")
  p_off <- mysterycall_irr_plot(fp_df)
  p_on  <- mysterycall_irr_plot(fp_df, show_significance_legend = TRUE)
  expect_identical(p_off$theme$legend.position, "none")
  expect_identical(p_on$theme$legend.position, "top")
  # a colour scale is present only when the legend is shown
  has_colour <- function(p) any(vapply(p$scales$scales,
                                        function(s) any(s$aesthetics == "colour"),
                                        logical(1)))
  expect_false(has_colour(p_off))
  expect_true(has_colour(p_on))
})

# ---- 4. mysterycall_region_labels -------------------------------------------

test_that("region_labels returns 50 states with AAO-HNS regions and centroids", {
  labs <- mysterycall_region_labels(system = "aao_hns")
  expect_s3_class(labs, "data.frame")
  expect_equal(nrow(labs), 50L)
  expect_setequal(names(labs), c("state", "abbr", "region", "lon", "lat", "label"))
  expect_true(all(is.finite(labs$lon)) && all(is.finite(labs$lat)))
  expect_true(all(nzchar(labs$region)))
  # default label column mirrors region
  expect_identical(labs$label, labs$region)
})

test_that("region_labels label = 'abbr' exposes the state code, and systems differ", {
  aao <- mysterycall_region_labels(system = "aao_hns", label = "abbr")
  expect_identical(aao$label, aao$abbr)
  census <- mysterycall_region_labels(system = "census")
  # the two systems assign different region vocabularies
  expect_false(identical(sort(unique(aao$region)), sort(unique(census$region))))
})

test_that("region_labels rejects an unknown system", {
  expect_error(mysterycall_region_labels(system = "nope"), "should be one of")
})
