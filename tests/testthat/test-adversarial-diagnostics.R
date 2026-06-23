# Adversarial and negative-control tests for:
#   - mysterycall_plot_residuals()
#   - mysterycall_check_zero_inflation()

# ── plot_residuals: bad inputs ─────────────────────────────────────────────────

test_that("plot_residuals: rejects NULL model", {
  expect_error(
    mysterycall_plot_residuals(NULL),
    regexp = "must be a"
  )
})

test_that("plot_residuals: rejects data frame (wrong class)", {
  expect_error(
    mysterycall_plot_residuals(mtcars),
    regexp = "must be a"
  )
})

test_that("plot_residuals: rejects character string", {
  expect_error(
    mysterycall_plot_residuals("glm"),
    regexp = "must be a"
  )
})

test_that("plot_residuals: rejects plain list without model class", {
  expect_error(
    mysterycall_plot_residuals(list(a = 1, b = 2)),
    regexp = "must be a"
  )
})

test_that("plot_residuals: rejects numeric vector", {
  expect_error(
    mysterycall_plot_residuals(1:10),
    regexp = "must be a"
  )
})

test_that("plot_residuals: rejects environment object", {
  expect_error(
    mysterycall_plot_residuals(new.env()),
    regexp = "must be a"
  )
})

# ── plot_residuals: Pearson path (use_dharma = FALSE) ─────────────────────────

test_that("plot_residuals: use_dharma=FALSE returns 3-element named list", {
  skip_if_not_installed("ggplot2")
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  result <- mysterycall_plot_residuals(m, use_dharma = FALSE)
  expect_type(result, "list")
  expect_equal(length(result), 3L)
  expect_named(result, c("residuals_vs_fitted", "qq", "scale_location"))
})

test_that("plot_residuals: use_dharma=FALSE list elements are ggplot objects", {
  skip_if_not_installed("ggplot2")
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  result <- mysterycall_plot_residuals(m, use_dharma = FALSE)
  expect_s3_class(result$residuals_vs_fitted, "ggplot")
  expect_s3_class(result$qq, "ggplot")
  expect_s3_class(result$scale_location, "ggplot")
})

test_that("plot_residuals: accepts bare lm object with use_dharma=FALSE", {
  skip_if_not_installed("ggplot2")
  m <- lm(mpg ~ wt, data = mtcars)
  result <- mysterycall_plot_residuals(m, use_dharma = FALSE)
  expect_type(result, "list")
  expect_equal(length(result), 3L)
})

test_that("plot_residuals: accepts bare glm (gaussian family) with use_dharma=FALSE", {
  skip_if_not_installed("ggplot2")
  m <- glm(mpg ~ wt + cyl, data = mtcars, family = gaussian())
  result <- mysterycall_plot_residuals(m, use_dharma = FALSE)
  expect_s3_class(result$qq, "ggplot")
})

# Negative control: a model with perfectly collinear predictors still returns plots
# (glm will warn but not error — plot_residuals should not add its own error)
test_that("plot_residuals: degenerate glm (rank-deficient) still returns plots", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(y = c(1, 2, 3, 4), x = c(1, 2, 3, 4), z = c(2, 4, 6, 8))
  m  <- suppressWarnings(glm(y ~ x + z, data = df, family = poisson()))
  result <- suppressWarnings(mysterycall_plot_residuals(m, use_dharma = FALSE))
  expect_type(result, "list")
})

# ── check_zero_inflation: bad inputs ──────────────────────────────────────────

test_that("check_zero_inflation: rejects NULL", {
  skip_if_not_installed("DHARMa")
  expect_error(
    mysterycall_check_zero_inflation(NULL),
    regexp = "must be a"
  )
})

test_that("check_zero_inflation: rejects data frame", {
  skip_if_not_installed("DHARMa")
  expect_error(
    mysterycall_check_zero_inflation(mtcars),
    regexp = "must be a"
  )
})

test_that("check_zero_inflation: rejects plain list", {
  skip_if_not_installed("DHARMa")
  expect_error(
    mysterycall_check_zero_inflation(list(x = 1)),
    regexp = "must be a"
  )
})

test_that("check_zero_inflation: rejects character string", {
  skip_if_not_installed("DHARMa")
  expect_error(
    mysterycall_check_zero_inflation("glm"),
    regexp = "must be a"
  )
})

test_that("check_zero_inflation: rejects numeric vector", {
  skip_if_not_installed("DHARMa")
  expect_error(
    mysterycall_check_zero_inflation(1:50),
    regexp = "must be a"
  )
})

# ── check_zero_inflation: valid inputs ────────────────────────────────────────

test_that("check_zero_inflation: accepts bare glm, returns object with p.value", {
  skip_if_not_installed("DHARMa")
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  result <- suppressMessages(
    mysterycall_check_zero_inflation(m, n_sim = 50L, plot = FALSE)
  )
  expect_false(is.null(result))
  expect_true("p.value" %in% names(result))
})

test_that("check_zero_inflation: p.value is numeric in [0, 1]", {
  skip_if_not_installed("DHARMa")
  m <- glm(am ~ wt, data = mtcars, family = poisson())
  result <- suppressMessages(
    mysterycall_check_zero_inflation(m, n_sim = 50L, plot = FALSE)
  )
  expect_true(is.numeric(result$p.value))
  expect_gte(result$p.value, 0)
  expect_lte(result$p.value, 1)
})

test_that("check_zero_inflation: result has statistic field", {
  skip_if_not_installed("DHARMa")
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  result <- suppressMessages(
    mysterycall_check_zero_inflation(m, n_sim = 50L, plot = FALSE)
  )
  expect_true("statistic" %in% names(result))
  expect_true(is.numeric(result$statistic))
})

test_that("check_zero_inflation: return value is invisible (called for message side-effect)", {
  skip_if_not_installed("DHARMa")
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  # withVisible() detects invisibility
  vis <- withVisible(suppressMessages(
    mysterycall_check_zero_inflation(m, n_sim = 50L, plot = FALSE)
  ))
  expect_false(vis$visible)
})

# ── Negative control: no zero-inflation in high-mean Poisson data ─────────────

test_that("check_zero_inflation: does not throw on clean Poisson data (high mean)", {
  skip_if_not_installed("DHARMa")
  set.seed(99)
  df <- data.frame(y = rpois(200, 20), x = rnorm(200))
  m  <- glm(y ~ x, data = df, family = poisson())
  result <- suppressMessages(
    mysterycall_check_zero_inflation(m, n_sim = 100L, plot = FALSE)
  )
  expect_true(is.numeric(result$p.value))
  # High-mean Poisson generates almost no zeros; test should not error
  # We don't assert p > 0.05 (Monte Carlo varies) but confirm it ran cleanly
})

# ── Negative control: messages fire as expected ───────────────────────────────

test_that("check_zero_inflation: emits a message (verdict line)", {
  skip_if_not_installed("DHARMa")
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  expect_message(
    mysterycall_check_zero_inflation(m, n_sim = 50L, plot = FALSE),
    regexp = "(zero-inflation|Zero-inflation|p = )"
  )
})

# ── plot_residuals: wrapper objects unwrapped correctly ───────────────────────

test_that("plot_residuals: mysterycall_poisson_model wrapper uses $model", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("ggplot2")
  set.seed(1)
  df <- data.frame(
    wait = rpois(40, 15),
    ins  = rep(c("A", "B"), 20),
    phys = rep(paste0("D", 1:8), 5),
    stringsAsFactors = FALSE
  )
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))
  result <- mysterycall_plot_residuals(fit, use_dharma = FALSE)
  expect_named(result, c("residuals_vs_fitted", "qq", "scale_location"))
})
