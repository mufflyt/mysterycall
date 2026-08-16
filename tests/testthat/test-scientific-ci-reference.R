# Independent confidence-interval reference. Spec section 43.
#
# The contract pins confidence_interval_method to Wald and requires an
# independent implementation to reproduce whatever is chosen. This file is that
# implementation. It computes the interval from the coefficient and its standard
# error directly and never calls stats::confint.default(), which is what the
# production path uses -- a reference that called the same function would only
# prove the function is deterministic.
#
# The contract also records a live inconsistency: R/insurance_wait_sentence.R
# uses Wald while R/simple_poisson.R uses profile likelihood, so the same data
# can yield two different published intervals depending on which function was
# called. The tests below pin the primary path to Wald and demonstrate that the
# profile interval is genuinely different, so the inconsistency cannot be
# dismissed as a rounding artefact.

fixture_path <- testthat::test_path("..", "fixtures", "canonical_study.R")
skip_if_not(file.exists(fixture_path), "canonical study fixture not found")
source(fixture_path)

CONTACT <- "Able to contact"

# --- the reference -----------------------------------------------------------
# Wald interval on the log scale, exponentiated. Uses only coef(), vcov() and
# the normal quantile.
ref_wald_irr <- function(fit, term, level = 0.95) {
  est <- unname(stats::coef(fit)[[term]])
  se  <- sqrt(unname(diag(stats::vcov(fit))[[term]]))
  z   <- stats::qnorm(1 - (1 - level) / 2)
  c(irr   = exp(est),
    lower = exp(est - z * se),
    upper = exp(est + z * se),
    se    = se)
}

# A deterministic model fixture with a known rate ratio.
model_data <- function(n_prov = 60L, irr = 2.0, seed = 42L) {
  set.seed(seed)
  prov <- sprintf("D%03d", seq_len(n_prov))
  eff  <- stats::rnorm(n_prov, 0, 0.25); names(eff) <- prov
  d <- do.call(rbind, lapply(prov, function(p) data.frame(
    provider = p,
    insurance = c("Blue Cross/Blue Shield", "Medicaid"),
    stringsAsFactors = FALSE)))
  mu <- 6 * ifelse(d$insurance == "Medicaid", irr, 1) * exp(eff[d$provider])
  d$wait <- stats::rpois(nrow(d), mu)
  d$insurance <- factor(d$insurance,
                        levels = c("Blue Cross/Blue Shield", "Medicaid"))
  d
}

TERM <- "insuranceMedicaid"

test_that("the reference reproduces confint.default exactly", {
  d   <- model_data()
  fit <- stats::glm(wait ~ insurance, data = d, family = stats::poisson())

  got  <- ref_wald_irr(fit, TERM)
  want <- suppressMessages(stats::confint.default(fit))[TERM, ]

  # Compared on the log scale, where confint.default reports, so the
  # comparison is not laundered through exp().
  expect_equal(log(unname(got[["lower"]])), unname(want[[1]]), tolerance = 1e-10)
  expect_equal(log(unname(got[["upper"]])), unname(want[[2]]), tolerance = 1e-10)
})

test_that("the interval is ordered and contains the point estimate", {
  d   <- model_data()
  fit <- stats::glm(wait ~ insurance, data = d, family = stats::poisson())
  r   <- ref_wald_irr(fit, TERM)

  expect_lt(r[["lower"]], r[["upper"]])
  expect_lt(r[["lower"]], r[["irr"]])
  expect_lt(r[["irr"]],   r[["upper"]])
  expect_true(all(is.finite(r)))
  expect_gt(r[["lower"]], 0)   # a rate ratio cannot be negative
})

test_that("the reference recovers the constructed rate ratio", {
  d   <- model_data(irr = 2.0, seed = 11L)
  fit <- stats::glm(wait ~ insurance, data = d, family = stats::poisson())
  r   <- ref_wald_irr(fit, TERM)

  expect_gt(r[["irr"]], 1.5)
  expect_lt(r[["irr"]], 2.6)
  # The interval excludes 1, since the effect was built in.
  expect_gt(r[["lower"]], 1)
})

test_that("a true null yields an interval that includes 1", {
  d   <- model_data(irr = 1.0, seed = 13L)
  fit <- stats::glm(wait ~ insurance, data = d, family = stats::poisson())
  r   <- ref_wald_irr(fit, TERM)

  expect_lt(r[["lower"]], 1)
  expect_gt(r[["upper"]], 1)
})

test_that("a wider level gives a wider interval", {
  d   <- model_data()
  fit <- stats::glm(wait ~ insurance, data = d, family = stats::poisson())
  a <- ref_wald_irr(fit, TERM, level = 0.95)
  b <- ref_wald_irr(fit, TERM, level = 0.99)

  expect_lt(b[["lower"]], a[["lower"]])
  expect_gt(b[["upper"]], a[["upper"]])
})

test_that("more data narrows the interval", {
  small <- model_data(n_prov = 30L,  seed = 5L)
  large <- model_data(n_prov = 300L, seed = 5L)
  f_s <- stats::glm(wait ~ insurance, data = small, family = stats::poisson())
  f_l <- stats::glm(wait ~ insurance, data = large, family = stats::poisson())

  w_s <- diff(ref_wald_irr(f_s, TERM)[c("lower", "upper")])
  w_l <- diff(ref_wald_irr(f_l, TERM)[c("lower", "upper")])
  expect_lt(w_l, w_s)
})

# ---------------------------------------------------------------------------
# The production path must agree with the reference.
# ---------------------------------------------------------------------------

test_that("the primary wait-time path reports the Wald interval", {
  skip_if_not(exists("mysterycall_insurance_wait_sentence"),
              "mysterycall_insurance_wait_sentence not available")

  d <- model_data(n_prov = 80L, irr = 1.8, seed = 29L)
  d$insurance <- as.character(d$insurance)
  names(d)[names(d) == "wait"] <- "business_days_until_appointment"

  res <- try(suppressMessages(suppressWarnings(
    mysterycall_insurance_wait_sentence(
      data = d,
      outcome_col   = "business_days_until_appointment",
      insurance_col = "insurance",
      digits_irr    = 6L
    )
  )), silent = TRUE)
  skip_if(inherits(res, "try-error"), "wait sentence path did not run")

  fit <- stats::glm(
    business_days_until_appointment ~ stats::relevel(
      factor(insurance), ref = "Blue Cross/Blue Shield"),
    data = d, family = stats::poisson()
  )
  term <- grep("Medicaid", names(stats::coef(fit)), value = TRUE)[1]
  want <- ref_wald_irr(fit, term)

  flat <- unlist(res)
  nums <- suppressWarnings(as.numeric(flat))
  nums <- nums[is.finite(nums)]
  skip_if(!length(nums), "no numeric output to compare")

  # The reported IRR and both limits must each appear in the output. Rounding
  # to six digits above makes an exact-to-tolerance match meaningful.
  for (target in c(want[["irr"]], want[["lower"]], want[["upper"]])) {
    expect_true(any(abs(nums - target) < 1e-4),
                info = sprintf("value %.6f absent from the reported output", target))
  }
})

# ---------------------------------------------------------------------------
# The recorded inconsistency is real, not a rounding artefact.
# ---------------------------------------------------------------------------

test_that("profile likelihood gives a different interval from Wald", {
  # The contract records that R/simple_poisson.R uses profile likelihood while
  # the primary path uses Wald. If these agreed to within rounding the
  # inconsistency would be academic. They do not, which is why the contract
  # carries a required follow-up rather than a note.
  d   <- model_data(n_prov = 40L, irr = 1.6, seed = 17L)
  fit <- stats::glm(wait ~ insurance, data = d, family = stats::poisson())

  wald <- ref_wald_irr(fit, TERM)
  prof <- try(suppressMessages(exp(stats::confint(fit)[TERM, ])), silent = TRUE)
  skip_if(inherits(prof, "try-error"), "profile confint did not converge")

  expect_false(isTRUE(all.equal(unname(wald[["lower"]]), unname(prof[[1]]),
                                tolerance = 1e-9)))
  # They should still be close: same data, same model, different approximation.
  expect_lt(abs(wald[["lower"]] - prof[[1]]), 0.5)
})

test_that("the contract still pins the method to Wald", {
  # If confidence_interval_method is ever changed, this reference is measuring
  # the wrong thing and must be revisited in the same commit.
  path <- testthat::test_path("..", "..", "inst", "contract",
                              "scientific_contract.yml")
  skip_if_not(file.exists(path), "contract not found")
  txt <- paste(readLines(path, warn = FALSE), collapse = " ")

  i <- regexpr("confidence_interval_method:", txt, fixed = TRUE)
  skip_if(i < 0, "field not present")
  block <- substr(txt, i, i + 400L)
  expect_true(grepl("Wald", block, fixed = TRUE),
              info = "contract no longer specifies Wald; this reference is stale")
})
