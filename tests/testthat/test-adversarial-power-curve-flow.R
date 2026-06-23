suppressPackageStartupMessages(
  pkgload::load_all("/Users/tylermuffly/mysterycall", quiet = TRUE)
)

# ---------------------------------------------------------------------------
# Block 1: mysterycall_power_curve() — adversarial
# ---------------------------------------------------------------------------

test_that("n_range with negative value errors", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_power_curve(n_range = c(-5, 10), irr_values = 0.75,
                            n_sim = 10L, plot = FALSE),
    regexp = "n_range"
  )
})

test_that("n_range = c(0, 20) errors (0 < 2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_power_curve(n_range = c(0, 20), irr_values = 0.75,
                            n_sim = 10L, plot = FALSE),
    regexp = "n_range"
  )
})

test_that("n_range = c(1, 20) errors (1 < 2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_power_curve(n_range = c(1, 20), irr_values = 0.75,
                            n_sim = 10L, plot = FALSE),
    regexp = "n_range"
  )
})

test_that("n_range = character(0) errors", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_power_curve(n_range = character(0), irr_values = 0.75,
                            n_sim = 10L, plot = FALSE),
    regexp = "n_range"
  )
})

test_that("irr_values = 0 errors", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0,
                            n_sim = 10L, plot = FALSE),
    regexp = "irr_values"
  )
})

test_that("irr_values = -0.5 errors", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = -0.5,
                            n_sim = 10L, plot = FALSE),
    regexp = "irr_values"
  )
})

test_that("irr_values = character(0) errors", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = character(0),
                            n_sim = 10L, plot = FALSE)
  )
})

test_that("target_power = 0 errors", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.75,
                            target_power = 0, n_sim = 10L, plot = FALSE),
    regexp = "target_power"
  )
})

test_that("target_power = 1 errors", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.75,
                            target_power = 1, n_sim = 10L, plot = FALSE),
    regexp = "target_power"
  )
})

test_that("target_power = 1.5 errors", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.75,
                            target_power = 1.5, n_sim = 10L, plot = FALSE),
    regexp = "target_power"
  )
})

test_that("target_power = 'high' errors", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.75,
                            target_power = "high", n_sim = 10L, plot = FALSE),
    regexp = "target_power"
  )
})

# ---------------------------------------------------------------------------
# Block 2: mysterycall_power_curve() — negative control
# ---------------------------------------------------------------------------

test_that("power_curve returns correct class and structure", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  pc <- suppressMessages(
    mysterycall_power_curve(
      n_range    = c(20L, 40L),
      irr_values = c(0.70),
      n_sim      = 50L,
      plot       = FALSE
    )
  )
  expect_s3_class(pc, "mysterycall_power_curve")
})

test_that("power_curve $data is a data frame", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  pc <- suppressMessages(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.70,
                            n_sim = 50L, plot = FALSE)
  )
  expect_true(is.data.frame(pc$data))
})

test_that("power_curve $data has required columns", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  pc <- suppressMessages(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.70,
                            n_sim = 50L, plot = FALSE)
  )
  expect_true(all(c("n_physicians", "irr", "power", "ci_lower", "ci_upper") %in%
                    names(pc$data)))
})

test_that("power_curve nrow(data) == length(n_range) * length(irr_values)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  pc <- suppressMessages(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.70,
                            n_sim = 50L, plot = FALSE)
  )
  expect_equal(nrow(pc$data), 2L)
})

test_that("all power values in [0, 1]", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  pc <- suppressMessages(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.70,
                            n_sim = 50L, plot = FALSE)
  )
  expect_true(all(pc$data$power >= 0 & pc$data$power <= 1))
})

test_that("all ci_lower values in [0, 1]", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  pc <- suppressMessages(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.70,
                            n_sim = 50L, plot = FALSE)
  )
  expect_true(all(pc$data$ci_lower >= 0 & pc$data$ci_lower <= 1))
})

test_that("all ci_upper values in [0, 1]", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  pc <- suppressMessages(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.70,
                            n_sim = 50L, plot = FALSE)
  )
  expect_true(all(pc$data$ci_upper >= 0 & pc$data$ci_upper <= 1))
})

test_that("$min_n is a named numeric vector with correct length", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  pc <- suppressMessages(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.70,
                            n_sim = 50L, plot = FALSE)
  )
  expect_true(is.numeric(pc$min_n))
  expect_equal(length(pc$min_n), 1L)
})

test_that("names($min_n) contains 'IRR = 0.7'", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  pc <- suppressMessages(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.70,
                            n_sim = 50L, plot = FALSE)
  )
  expect_true(any(grepl("0.7", names(pc$min_n))))
})

test_that("$params$n_sim matches input", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  pc <- suppressMessages(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.70,
                            n_sim = 50L, plot = FALSE)
  )
  expect_equal(pc$params$n_sim, 50L)
})

test_that("$plot is a ggplot object", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("ggplot2")
  pc <- suppressMessages(
    mysterycall_power_curve(n_range = c(20L, 40L), irr_values = 0.70,
                            n_sim = 50L, plot = FALSE)
  )
  expect_true(inherits(pc$plot, "ggplot"))
})

# ---------------------------------------------------------------------------
# Block 3: mysterycall_flow_diagram() — adversarial
# ---------------------------------------------------------------------------

test_that("n_identified = 0 errors", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_flow_diagram(n_identified = 0, n_analysed = 0),
    regexp = "n_identified"
  )
})

test_that("n_identified = -100 errors", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_flow_diagram(n_identified = -100, n_analysed = 80),
    regexp = "n_identified"
  )
})

test_that("n_identified = 'all' errors", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_flow_diagram(n_identified = "all", n_analysed = 80),
    regexp = "n_identified"
  )
})

test_that("n_identified = c(100, 200) errors (not scalar)", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_flow_diagram(n_identified = c(100, 200), n_analysed = 80)
  )
})

test_that("n_analysed = 0 errors", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_flow_diagram(n_identified = 100, n_analysed = 0),
    regexp = "n_analysed"
  )
})

test_that("n_analysed = -1 errors", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_flow_diagram(n_identified = 100, n_analysed = -1),
    regexp = "n_analysed"
  )
})

test_that("n_analysed > n_identified errors", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_flow_diagram(n_identified = 500, n_analysed = 600),
    regexp = "cannot exceed"
  )
})

test_that("n_analysed = 'many' errors", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_flow_diagram(n_identified = 100, n_analysed = "many"),
    regexp = "n_analysed"
  )
})

# ---------------------------------------------------------------------------
# Block 4: mysterycall_flow_diagram() — negative control
# ---------------------------------------------------------------------------

test_that("basic call returns a ggplot object", {
  skip_if_not_installed("ggplot2")
  p <- mysterycall_flow_diagram(n_identified = 500, n_analysed = 369)
  expect_true(inherits(p, "gg"))
})

test_that("with n_contacted no error", {
  skip_if_not_installed("ggplot2")
  p2 <- mysterycall_flow_diagram(n_identified = 500, n_contacted = 450,
                                  n_analysed = 369)
  expect_true(inherits(p2, "gg"))
})

test_that("with n_excluded_contact no error", {
  skip_if_not_installed("ggplot2")
  p3 <- mysterycall_flow_diagram(n_identified = 500, n_contacted = 450,
                                  n_excluded_contact = 50, n_analysed = 369)
  expect_true(inherits(p3, "gg"))
})

test_that("with all optional args populated no error", {
  skip_if_not_installed("ggplot2")
  p4 <- mysterycall_flow_diagram(
    n_identified        = 500,
    n_contacted         = 450,
    n_excluded_contact  = 50,
    n_completed         = 420,
    n_excluded_complete = 30,
    n_analysed          = 369
  )
  expect_true(inherits(p4, "gg"))
})

test_that("n_analysed == n_identified (no exclusions) no error", {
  skip_if_not_installed("ggplot2")
  p5 <- mysterycall_flow_diagram(n_identified = 369, n_analysed = 369)
  expect_true(inherits(p5, "gg"))
})

test_that("output_path writes a file", {
  skip_if_not_installed("ggplot2")
  tmp <- tempfile(fileext = ".png")
  suppressMessages(
    mysterycall_flow_diagram(n_identified = 100, n_analysed = 80,
                             output_path = tmp)
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})
