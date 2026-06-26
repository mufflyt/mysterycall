# pkgload::load_all() was removed — it replaced the namespace object and broke
# with_mocked_bindings() in subsequent test files. devtools::test() already
# calls load_all() before running tests.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
.fake_poi_null <- function() {
  structure(
    list(
      irr_table = data.frame(term="ins", irr=1.2, ci_lower=1.0,
                             ci_upper=1.4, p_value=0.04, stringsAsFactors=FALSE),
      overdispersion = 1.2, model = NULL
    ),
    class = "mysterycall_poisson_model"
  )
}

.fake_nb_null <- function() {
  structure(
    list(
      irr_table = data.frame(term="ins", irr=1.2, ci_lower=1.0,
                             ci_upper=1.4, p_value=0.04, stringsAsFactors=FALSE),
      overdispersion = 2.5, theta = 1.5, model = NULL
    ),
    class = "mysterycall_nb_model"
  )
}

.fake_icc_obj <- function(val = 0.18) {
  structure(
    list(icc=val, sigma2_u=0.30, method="latent_variable_poisson",
         ci=c(NA_real_, NA_real_), n_boot=0L,
         interpretation=paste0("ICC = ", val, ": ..."),
         model_class="mysterycall_poisson_model"),
    class = "mysterycall_icc"
  )
}

.make_fit_data <- function(seed = 42) {
  set.seed(seed)
  data.frame(
    wait = rpois(60, 20),
    ins  = rep(c("Medicaid", "BCBS"), 30),
    phys = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Block 1: mysterycall_icc() — class and NULL-model guards
# ---------------------------------------------------------------------------

test_that("plain list input triggers class error", {
  expect_error(mysterycall_icc(list(x = 1)), "mysterycall_poisson_model")
})

test_that("numeric input triggers class error", {
  expect_error(mysterycall_icc(42), "mysterycall_poisson_model")
})

test_that("character input triggers class error", {
  expect_error(mysterycall_icc("model"), "mysterycall_poisson_model")
})

test_that("Poisson object with NULL model triggers Refit error", {
  expect_error(mysterycall_icc(.fake_poi_null()), "Refit")
})

test_that("NB object with NULL model triggers Refit error", {
  expect_error(mysterycall_icc(.fake_nb_null()), "Refit")
})

# ---------------------------------------------------------------------------
# Block 2: mysterycall_icc() — negative control with real fits
# ---------------------------------------------------------------------------

test_that("returns class mysterycall_icc from real Poisson fit", {
  skip_if_not_installed("lme4")
  df  <- .make_fit_data()
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")))
  res <- suppressWarnings(mysterycall_icc(fit))
  expect_s3_class(res, "mysterycall_icc")
})

test_that("$icc is numeric in [0, 1]", {
  skip_if_not_installed("lme4")
  df  <- .make_fit_data()
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")))
  res <- suppressWarnings(mysterycall_icc(fit))
  expect_true(is.numeric(res$icc))
  expect_true(res$icc >= 0 && res$icc <= 1)
})

test_that("$sigma2_u is numeric and non-negative", {
  skip_if_not_installed("lme4")
  df  <- .make_fit_data()
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")))
  res <- suppressWarnings(mysterycall_icc(fit))
  expect_true(is.numeric(res$sigma2_u) && res$sigma2_u >= 0)
})

test_that("$method is latent_variable_poisson for Poisson fit", {
  skip_if_not_installed("lme4")
  df  <- .make_fit_data()
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")))
  res <- suppressWarnings(mysterycall_icc(fit))
  expect_equal(res$method, "latent_variable_poisson")
})

test_that("n_boot = 0 produces NA CI of length 2", {
  skip_if_not_installed("lme4")
  df  <- .make_fit_data()
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")))
  res <- suppressWarnings(mysterycall_icc(fit, n_boot = 0L))
  expect_length(res$ci, 2L)
  expect_true(all(is.na(res$ci)))
})

test_that("$interpretation is a non-empty string", {
  skip_if_not_installed("lme4")
  df  <- .make_fit_data()
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")))
  res <- suppressWarnings(mysterycall_icc(fit))
  expect_type(res$interpretation, "character")
  expect_gt(nchar(res$interpretation), 0L)
})

test_that("$model_class mentions poisson", {
  skip_if_not_installed("lme4")
  df  <- .make_fit_data()
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")))
  res <- suppressWarnings(mysterycall_icc(fit))
  expect_true(grepl("poisson", res$model_class, ignore.case = TRUE))
})

test_that("conf_level = 0 rejected after valid model", {
  skip_if_not_installed("lme4")
  df  <- .make_fit_data()
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")))
  expect_error(mysterycall_icc(fit, conf_level = 0),   regexp = "0.*1|conf_level")
})

test_that("conf_level = 1 rejected after valid model", {
  skip_if_not_installed("lme4")
  df  <- .make_fit_data()
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")))
  expect_error(mysterycall_icc(fit, conf_level = 1),   regexp = "0.*1|conf_level")
})

test_that("conf_level = 'high' rejected after valid model", {
  skip_if_not_installed("lme4")
  df  <- .make_fit_data()
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")))
  expect_error(mysterycall_icc(fit, conf_level = "high"), regexp = "0.*1|conf_level|numeric")
})

test_that("iid data with no physician clustering yields ICC < 0.5", {
  skip_if_not_installed("lme4")
  set.seed(7)
  df_iid <- data.frame(
    wait = rpois(60, 20),
    ins  = rep(c("A", "B"), 30),
    phys = paste0("D", 1:60),  # each physician has exactly 1 observation → no clustering
    stringsAsFactors = FALSE
  )
  fit_iid <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df_iid, "wait", "ins", "phys")))
  res_iid <- suppressWarnings(mysterycall_icc(fit_iid))
  expect_true(res_iid$icc < 0.5)
})

# ---------------------------------------------------------------------------
# Block 3: mysterycall_icc_sentence() adversarial + negative control
# ---------------------------------------------------------------------------

test_that("plain list triggers error", {
  expect_error(mysterycall_icc_sentence(list(icc = 0.2)))
})

test_that("numeric input triggers error", {
  expect_error(mysterycall_icc_sentence(42))
})

test_that("valid object returns length-1 character", {
  s <- mysterycall_icc_sentence(.fake_icc_obj(0.18))
  expect_type(s, "character")
  expect_length(s, 1L)
})

test_that("sentence contains the ICC percentage value", {
  s <- mysterycall_icc_sentence(.fake_icc_obj(0.18))
  expect_true(grepl("18|0.18", s))
})

test_that("sentence mentions intraclass correlation or clustering", {
  s <- mysterycall_icc_sentence(.fake_icc_obj(0.18))
  expect_true(grepl("intraclass|correlation|clustering", s, ignore.case = TRUE))
})

# ---------------------------------------------------------------------------
# Block 4: mysterycall_predicted_means() adversarial
# ---------------------------------------------------------------------------

test_that("string model triggers class error", {
  expect_error(
    mysterycall_predicted_means("model", "ins"),
    "mysterycall_poisson_model"
  )
})

test_that("plain list triggers class error", {
  expect_error(
    mysterycall_predicted_means(list(x = 1), "ins"),
    "mysterycall_poisson_model"
  )
})

test_that("Poisson object with NULL model triggers Refit error", {
  expect_error(
    mysterycall_predicted_means(.fake_poi_null(), "ins"),
    "Refit"
  )
})

test_that("NB object with NULL model triggers Refit error", {
  expect_error(
    mysterycall_predicted_means(.fake_nb_null(), "ins"),
    "Refit"
  )
})

test_that("group_col and conf_level guards fire on valid fit", {
  skip_if_not_installed("lme4")
  df  <- .make_fit_data()
  fit <- suppressWarnings(suppressMessages(
    mysterycall_poisson_model(df, "wait", "ins", "phys")))
  expect_error(
    mysterycall_predicted_means(fit, c("ins", "phys")),
    regexp = "single|scalar|character|group_col"
  )
  expect_error(
    mysterycall_predicted_means(fit, 123),
    regexp = "single|scalar|character|group_col"
  )
  expect_error(
    mysterycall_predicted_means(fit, "ins", conf_level = 0),
    regexp = "0.*1|conf_level"
  )
  expect_error(
    mysterycall_predicted_means(fit, "ins", conf_level = 2),
    regexp = "0.*1|conf_level"
  )
})
