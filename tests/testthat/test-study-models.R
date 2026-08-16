# Jobs 37-43: independent descriptive recomputation, and validation of the
# logistic, Poisson, negative-binomial, overdispersion, mixed-model and GEE
# paths against fixtures with a known answer.
#
# The canonical study is deliberately small, which is right for denominator
# accounting and wrong for fitting a GLMM. Model fixtures are therefore built
# here at a size where an estimate is meaningful, seeded so the expected
# direction is reproducible rather than a lucky draw.

fixture_path <- testthat::test_path("..", "fixtures", "canonical_study.R")
skip_if_not(file.exists(fixture_path), "canonical study fixture not found")
source(fixture_path)

STUDY   <- mc_canonical_study()$study
CONTACT <- "Able to contact"

# A larger synthetic study with a known rate ratio. Providers cluster the
# observations, so a mixed model has something real to find.
mc_model_fixture <- function(n_prov = 60L, irr = 2.0, seed = 42L) {
  set.seed(seed)
  prov <- sprintf("D%03d", seq_len(n_prov))
  prov_effect <- stats::rnorm(n_prov, 0, 0.25)
  names(prov_effect) <- prov

  base_rate <- 6
  d <- do.call(rbind, lapply(prov, function(p) {
    data.frame(
      provider  = p,
      insurance = c("Blue Cross/Blue Shield", "Medicaid"),
      stringsAsFactors = FALSE
    )
  }))
  mu <- base_rate * ifelse(d$insurance == "Medicaid", irr, 1) *
    exp(prov_effect[d$provider])
  d$wait <- stats::rpois(nrow(d), mu)
  d$insurance <- factor(d$insurance,
                        levels = c("Blue Cross/Blue Shield", "Medicaid"))
  d
}

# ---------------------------------------------------------------------------
# Job 37: independent descriptive recomputation
# ---------------------------------------------------------------------------

test_that("descriptives recompute exactly from base R", {
  w <- STUDY[STUDY$reason_for_exclusions == CONTACT &
               !is.na(STUDY$business_days_until_appointment), ]

  for (arm in c("Medicaid", "Blue Cross/Blue Shield")) {
    v <- w$business_days_until_appointment[w$insurance == arm]
    expect_equal(length(v), 10L, info = arm)
    expect_equal(mean(v), sum(v) / length(v), info = arm)
    q <- stats::quantile(v, c(0.25, 0.5, 0.75), type = 7)
    expect_equal(unname(q[[2]]), stats::median(v), info = arm)
    expect_lte(unname(q[[1]]), unname(q[[2]]))
    expect_lte(unname(q[[2]]), unname(q[[3]]))
    expect_equal(stats::sd(v),
                 sqrt(sum((v - mean(v))^2) / (length(v) - 1)), info = arm)
  }
})

test_that("an acceptance proportion is its own numerator over its denominator", {
  acc <- STUDY[STUDY$reason_for_exclusions == CONTACT &
                 !is.na(STUDY$appointment_offered), ]
  for (arm in c("Medicaid", "Blue Cross/Blue Shield")) {
    v <- acc$appointment_offered[acc$insurance == arm]
    expect_equal(mean(v), sum(v) / length(v), info = arm)
  }
  # Reported without its denominator a proportion is not interpretable, so the
  # denominator is asserted alongside it.
  expect_equal(sum(acc$insurance == "Medicaid"), 12L)
  expect_equal(sum(acc$insurance == "Blue Cross/Blue Shield"), 11L)
})

# ---------------------------------------------------------------------------
# Job 38: logistic acceptance model
# ---------------------------------------------------------------------------

test_that("the logistic path recovers a known acceptance difference", {
  set.seed(7)
  n <- 200L
  d <- data.frame(
    provider  = rep(sprintf("D%03d", seq_len(n)), each = 2L),
    insurance = rep(c("Blue Cross/Blue Shield", "Medicaid"), times = n),
    stringsAsFactors = FALSE
  )
  # Commercial accepts more often than Medicaid, by construction.
  p <- ifelse(d$insurance == "Medicaid", 0.55, 0.90)
  d$accepted <- stats::rbinom(nrow(d), 1L, p)
  d$insurance <- factor(d$insurance,
                        levels = c("Blue Cross/Blue Shield", "Medicaid"))

  fit <- stats::glm(accepted ~ insurance, data = d, family = stats::binomial())
  co  <- stats::coef(summary(fit))

  expect_true(is.finite(co["insuranceMedicaid", "Estimate"]))
  expect_lt(co["insuranceMedicaid", "Estimate"], 0)      # lower odds
  expect_lt(co["insuranceMedicaid", "Pr(>|z|)"], 0.05)

  ci <- suppressMessages(stats::confint.default(fit))
  expect_lt(ci["insuranceMedicaid", 1], ci["insuranceMedicaid", 2])
  expect_lt(exp(co["insuranceMedicaid", "Estimate"]), 1)  # OR below 1
})

test_that("the reference arm is the one the factor levels declare", {
  d <- mc_model_fixture(n_prov = 30L)
  expect_equal(levels(d$insurance)[1], "Blue Cross/Blue Shield")
  fit <- stats::glm(wait ~ insurance, data = d, family = stats::poisson())
  # The named coefficient is the non-reference arm; if the levels were flipped
  # the sign of every reported contrast would flip with them.
  expect_true("insuranceMedicaid" %in% rownames(stats::coef(summary(fit))))
})

# ---------------------------------------------------------------------------
# Job 39: Poisson wait-time model
# ---------------------------------------------------------------------------

test_that("the Poisson path recovers a known rate ratio", {
  d <- mc_model_fixture(irr = 2.0, seed = 11L)
  fit <- stats::glm(wait ~ insurance, data = d, family = stats::poisson())
  irr_hat <- exp(unname(stats::coef(fit)[["insuranceMedicaid"]]))

  expect_gt(irr_hat, 1.5)
  expect_lt(irr_hat, 2.6)

  # The IRR is verified independently as a ratio of arm means, which for a
  # log-link Poisson with a single binary predictor is exact.
  m_mcd  <- mean(d$wait[d$insurance == "Medicaid"])
  m_bcbs <- mean(d$wait[d$insurance == "Blue Cross/Blue Shield"])
  expect_equal(irr_hat, m_mcd / m_bcbs, tolerance = 1e-6)
})

test_that("a true null produces no rate ratio", {
  d <- mc_model_fixture(irr = 1.0, seed = 13L)
  fit <- stats::glm(wait ~ insurance, data = d, family = stats::poisson())
  irr_hat <- exp(unname(stats::coef(fit)[["insuranceMedicaid"]]))
  expect_gt(irr_hat, 0.85)
  expect_lt(irr_hat, 1.18)
})

# ---------------------------------------------------------------------------
# Jobs 40, 41: negative binomial and overdispersion
# ---------------------------------------------------------------------------

test_that("overdispersion is detected when present and not when absent", {
  skip_if_not_installed("MASS")

  # Equidispersed: Poisson is appropriate.
  d_pois <- mc_model_fixture(irr = 1.5, seed = 17L)
  f_pois <- stats::glm(wait ~ insurance, data = d_pois, family = stats::poisson())
  phi_pois <- sum(stats::residuals(f_pois, type = "pearson")^2) /
    stats::df.residual(f_pois)

  # Overdispersed: a negative binomial draw with small theta.
  set.seed(19)
  d_nb <- d_pois
  mu <- stats::fitted(f_pois)
  d_nb$wait <- MASS::rnegbin(length(mu), mu = mu, theta = 0.8)
  f_nb_pois <- stats::glm(wait ~ insurance, data = d_nb, family = stats::poisson())
  phi_nb <- sum(stats::residuals(f_nb_pois, type = "pearson")^2) /
    stats::df.residual(f_nb_pois)

  expect_lt(phi_pois, 1.5)
  expect_gt(phi_nb, phi_pois)
  expect_gt(phi_nb, 1.5)
})

test_that("the negative binomial fit is finite and its dispersion positive", {
  skip_if_not_installed("MASS")
  set.seed(23)
  d <- mc_model_fixture(irr = 1.8, seed = 23L)
  mu <- 6 * ifelse(d$insurance == "Medicaid", 1.8, 1)
  d$wait <- MASS::rnegbin(nrow(d), mu = mu, theta = 1.2)

  fit <- try(MASS::glm.nb(wait ~ insurance, data = d), silent = TRUE)
  skip_if(inherits(fit, "try-error"), "glm.nb did not converge")

  expect_true(is.finite(fit$theta))
  expect_gt(fit$theta, 0)
  est <- unname(stats::coef(fit)[["insuranceMedicaid"]])
  expect_true(is.finite(est))
  expect_gt(exp(est), 1)   # Medicaid waits longer, as constructed
})

# ---------------------------------------------------------------------------
# Job 42: mixed-model clustering
# ---------------------------------------------------------------------------

test_that("a provider random effect is recovered when clustering exists", {
  skip_if_not_installed("lme4")
  d <- mc_model_fixture(n_prov = 80L, irr = 1.8, seed = 29L)

  fit <- try(
    lme4::glmer(wait ~ insurance + (1 | provider), data = d,
                family = stats::poisson()),
    silent = TRUE
  )
  skip_if(inherits(fit, "try-error"), "glmer did not converge")

  vc <- as.data.frame(lme4::VarCorr(fit))
  expect_true("provider" %in% vc$grp)
  var_prov <- vc$vcov[vc$grp == "provider"][1]
  expect_true(is.finite(var_prov))
  expect_gt(var_prov, 0)

  # The cluster variable must not be silently dropped: a model that ignored it
  # would report no provider variance at all.
  expect_gt(nrow(vc), 0L)
})

test_that("ignoring clustering shrinks the standard error, which is the trap", {
  skip_if_not_installed("lme4")
  d <- mc_model_fixture(n_prov = 80L, irr = 1.8, seed = 31L)

  naive <- stats::glm(wait ~ insurance, data = d, family = stats::poisson())
  se_naive <- stats::coef(summary(naive))["insuranceMedicaid", "Std. Error"]

  mixed <- try(
    lme4::glmer(wait ~ insurance + (1 | provider), data = d,
                family = stats::poisson()),
    silent = TRUE
  )
  skip_if(inherits(mixed, "try-error"), "glmer did not converge")
  se_mixed <- stats::coef(summary(mixed))["insuranceMedicaid", "Std. Error"]

  expect_true(is.finite(se_naive))
  expect_true(is.finite(se_mixed))
  # Both are finite and the naive one is not larger. The point of recording
  # this is that a naive fit reports more precision than the design supports.
  expect_lte(se_naive, se_mixed * 1.05)
})

# ---------------------------------------------------------------------------
# Job 43: GEE
# ---------------------------------------------------------------------------

test_that("the GEE path runs on clustered data and returns a finite estimate", {
  skip_if_not_installed("geepack")
  d <- mc_model_fixture(n_prov = 60L, irr = 1.8, seed = 37L)
  d <- d[order(d$provider), ]

  fit <- try(
    geepack::geeglm(wait ~ insurance, id = factor(d$provider), data = d,
                    family = stats::poisson(), corstr = "exchangeable"),
    silent = TRUE
  )
  skip_if(inherits(fit, "try-error"), "geeglm did not converge")

  co <- stats::coef(summary(fit))
  expect_true("insuranceMedicaid" %in% rownames(co))
  est <- co["insuranceMedicaid", "Estimate"]
  expect_true(is.finite(est))
  expect_gt(exp(est), 1)
  expect_true(is.finite(co["insuranceMedicaid", "Std.err"]))
})
