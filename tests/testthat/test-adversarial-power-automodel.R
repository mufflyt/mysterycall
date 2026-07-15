# Adversarial and negative-control tests for:
#   mysterycall_nb_power()   — R/nb_power.R
#   mysterycall_auto_model() — R/auto_model.R

# ── nb_power: input validation ─────────────────────────────────────────────

test_that("nb_power: rejects n_physicians = 1 (too few clusters)", {
  skip_if_not_installed("glmmTMB")
  expect_error(mysterycall_nb_power(n_physicians = 1L, n_sim = 10L))
})

test_that("nb_power: rejects irr = 0", {
  skip_if_not_installed("glmmTMB")
  expect_error(mysterycall_nb_power(n_physicians = 10L, irr = 0, n_sim = 10L))
})

test_that("nb_power: rejects irr < 0", {
  skip_if_not_installed("glmmTMB")
  expect_error(mysterycall_nb_power(n_physicians = 10L, irr = -0.5, n_sim = 10L))
})

test_that("nb_power: rejects theta = 0", {
  skip_if_not_installed("glmmTMB")
  expect_error(mysterycall_nb_power(n_physicians = 10L, theta = 0, n_sim = 10L))
})

test_that("nb_power: rejects theta < 0", {
  skip_if_not_installed("glmmTMB")
  expect_error(mysterycall_nb_power(n_physicians = 10L, theta = -1, n_sim = 10L))
})

test_that("nb_power: rejects alpha = 0", {
  skip_if_not_installed("glmmTMB")
  expect_error(mysterycall_nb_power(n_physicians = 10L, alpha = 0, n_sim = 10L))
})

test_that("nb_power: rejects alpha = 1", {
  skip_if_not_installed("glmmTMB")
  expect_error(mysterycall_nb_power(n_physicians = 10L, alpha = 1, n_sim = 10L))
})

test_that("nb_power: rejects n_sim < 10", {
  skip_if_not_installed("glmmTMB")
  expect_error(mysterycall_nb_power(n_physicians = 10L, n_sim = 5L))
})

test_that("nb_power: rejects baseline_mean = 0", {
  skip_if_not_installed("glmmTMB")
  expect_error(mysterycall_nb_power(n_physicians = 10L, baseline_mean = 0, n_sim = 10L))
})

test_that("nb_power: rejects baseline_mean < 0", {
  skip_if_not_installed("glmmTMB")
  expect_error(mysterycall_nb_power(n_physicians = 10L, baseline_mean = -5, n_sim = 10L))
})

test_that("nb_power: rejects sigma_u < 0", {
  skip_if_not_installed("glmmTMB")
  expect_error(mysterycall_nb_power(n_physicians = 10L, sigma_u = -0.1, n_sim = 10L))
})

# ── nb_power: return-value shape ───────────────────────────────────────────

test_that("nb_power: returns class mysterycall_nb_power", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(suppressMessages(
    mysterycall_nb_power(n_physicians = 5L, irr = 0.75, n_sim = 20L, seed = 1L)
  ))
  expect_s3_class(result, "mysterycall_nb_power")
})

test_that("nb_power: power is numeric in [0, 1]", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(suppressMessages(
    mysterycall_nb_power(n_physicians = 5L, irr = 0.75, n_sim = 20L, seed = 1L)
  ))
  expect_true(is.numeric(result$power))
  expect_true(result$power >= 0 && result$power <= 1)
})

test_that("nb_power: ci has length 2 with ci[1] <= ci[2]", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(suppressMessages(
    mysterycall_nb_power(n_physicians = 5L, irr = 0.75, n_sim = 20L, seed = 1L)
  ))
  expect_length(result$ci, 2L)
  expect_true(result$ci[1] <= result$ci[2])
})

test_that("nb_power: ci values are in [0, 1]", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(suppressMessages(
    mysterycall_nb_power(n_physicians = 5L, irr = 0.75, n_sim = 20L, seed = 1L)
  ))
  expect_true(all(result$ci >= 0 & result$ci <= 1))
})

test_that("nb_power: total_n = n_physicians * calls_per_physician (paired)", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(suppressMessages(
    mysterycall_nb_power(n_physicians = 8L, calls_per_physician = 3L,
                         irr = 0.75, n_sim = 10L, seed = 1L)
  ))
  expect_equal(result$total_n, 8L * 3L)
})

test_that("nb_power: seed produces identical results on two calls", {
  skip_if_not_installed("glmmTMB")
  r1 <- suppressWarnings(suppressMessages(
    mysterycall_nb_power(n_physicians = 5L, irr = 0.75, n_sim = 15L, seed = 99L)
  ))
  r2 <- suppressWarnings(suppressMessages(
    mysterycall_nb_power(n_physicians = 5L, irr = 0.75, n_sim = 15L, seed = 99L)
  ))
  expect_equal(r1$power, r2$power)
})

test_that("nb_power: print method runs without error", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(suppressMessages(
    mysterycall_nb_power(n_physicians = 5L, irr = 0.75, n_sim = 10L, seed = 1L)
  ))
  expect_output(print(result), regexp = "Power")
})

# ── nb_power: statistical monotonicity ────────────────────────────────────

test_that("nb_power: irr=1 gives power near alpha (null hypothesis)", {
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(suppressMessages(
    mysterycall_nb_power(n_physicians = 20L, irr = 1.0, n_sim = 200L, seed = 42L)
  ))
  # Under the null, power should be near alpha (0.05); allow generous range
  expect_true(result$power <= 0.20)
})

test_that("nb_power: larger n gives higher or equal power than smaller n", {
  skip_if_not_installed("glmmTMB")
  r_small <- suppressWarnings(suppressMessages(
    mysterycall_nb_power(n_physicians = 5L,  irr = 0.5, n_sim = 100L, seed = 1L)
  ))
  r_large <- suppressWarnings(suppressMessages(
    mysterycall_nb_power(n_physicians = 50L, irr = 0.5, n_sim = 100L, seed = 1L)
  ))
  expect_true(r_large$power >= r_small$power)
})

# ── auto_model: input validation ───────────────────────────────────────────

test_that("auto_model: rejects NULL data", {
  skip_if_not_installed("lme4")
  expect_error(
    suppressMessages(mysterycall_auto_model(NULL, "wait", "ins", "phys")),
    class = "error"
  )
})

test_that("auto_model: rejects non-data-frame input", {
  skip_if_not_installed("lme4")
  expect_error(
    suppressMessages(mysterycall_auto_model(list(a = 1), "wait", "ins", "phys")),
    class = "error"
  )
})

test_that("auto_model: rejects missing outcome column", {
  skip_if_not_installed("lme4")
  df <- data.frame(
    wait = rpois(30, 15), ins = rep(c("A", "B"), 15),
    phys = rep(paste0("D", 1:5), 6), stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "no_such_col", "ins", "phys")),
    class = "error"
  )
})

test_that("auto_model: rejects missing predictor column", {
  skip_if_not_installed("lme4")
  df <- data.frame(
    wait = rpois(30, 15), ins = rep(c("A", "B"), 15),
    phys = rep(paste0("D", 1:5), 6), stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "wait", "no_col", "phys")),
    class = "error"
  )
})

test_that("auto_model: rejects missing random_intercept column", {
  skip_if_not_installed("lme4")
  df <- data.frame(
    wait = rpois(30, 15), ins = rep(c("A", "B"), 15),
    phys = rep(paste0("D", 1:5), 6), stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "wait", "ins", "no_phys")),
    class = "error"
  )
})

test_that("auto_model: rejects negative outcome values", {
  skip_if_not_installed("lme4")
  df <- data.frame(
    wait = c(-1L, rpois(29, 15)), ins = rep(c("A", "B"), 15),
    phys = rep(paste0("D", 1:5), 6), stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_auto_model(df, "wait", "ins", "phys")),
    class = "error"
  )
})

# ── auto_model: return-value guarantees ────────────────────────────────────

make_auto_df <- function(seed = 7L) {
  set.seed(seed)
  data.frame(
    wait = rpois(60, 15),
    ins  = rep(c("A", "B"), 30),
    phys = rep(paste0("D", 1:10), each = 6),
    stringsAsFactors = FALSE
  )
}

test_that("auto_model: $selection is always attached", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_auto_df(7L), "wait", "ins", "phys")
  ))
  expect_false(is.null(result$selection))
  expect_true("poisson_phi"  %in% names(result$selection))
  expect_true("model_chosen" %in% names(result$selection))
  expect_true("reason"       %in% names(result$selection))
})

test_that("auto_model: poisson_phi is a non-negative numeric", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_auto_df(8L), "wait", "ins", "phys")
  ))
  expect_true(is.numeric(result$selection$poisson_phi))
  expect_true(result$selection$poisson_phi >= 0)
})

test_that("auto_model: model_chosen is one of the two valid strings", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_auto_df(9L), "wait", "ins", "phys")
  ))
  expect_true(result$selection$model_chosen %in% c("poisson", "negative_binomial"))
})

test_that("auto_model: result inherits from a recognized model class", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_auto_df(10L), "wait", "ins", "phys")
  ))
  expect_true(
    inherits(result, "mysterycall_poisson_model") ||
      inherits(result, "mysterycall_nb_model")
  )
})

# ── auto_model: threshold boundary behaviour ───────────────────────────────

test_that("auto_model: phi_threshold=Inf always returns Poisson", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_auto_df(11L), "wait", "ins", "phys",
                           phi_threshold = Inf)
  ))
  expect_equal(result$selection$model_chosen, "poisson")
  expect_s3_class(result, "mysterycall_poisson_model")
})

test_that("auto_model: phi_threshold=0 always attempts NB (phi will be > 0)", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("glmmTMB")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_auto_df(12L), "wait", "ins", "phys",
                           phi_threshold = 0)
  ))
  # phi > 0 always, so NB should be attempted; model_chosen must be NB
  expect_equal(result$selection$model_chosen, "negative_binomial")
  expect_s3_class(result, "mysterycall_nb_model")
})

test_that("auto_model: $irr_table present regardless of which model chosen", {
  skip_if_not_installed("lme4")
  result <- suppressWarnings(suppressMessages(
    mysterycall_auto_model(make_auto_df(13L), "wait", "ins", "phys")
  ))
  expect_true(!is.null(result$irr_table))
  expect_s3_class(result$irr_table, "data.frame")
  expect_true(nrow(result$irr_table) > 0L)
})
