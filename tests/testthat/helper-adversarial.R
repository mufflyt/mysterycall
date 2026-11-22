# Shared fixtures for the adversarial contract suite.
#
# These live in a helper file, not inside test-adversarial-count-models.R,
# because testthat evaluates each test file in its own environment: a
# function defined at the top level of one test file is not visible to
# another. test-adversarial-wiring.R calls mc_adv_calls() and mc_adv_fit(),
# so both must be defined here to be in scope for every file that uses them.
#
# Synthetic data only: 18 physicians, 10 calls each, Poisson wait times with
# a ~27% Medicaid penalty and a unit exposure column.

mc_adv_calls <- function(seed = 6291L) {
  base::set.seed(seed)
  n_clusters <- 18L
  n_per_cluster <- 10L
  n <- n_clusters * n_per_cluster
  physician <- base::rep(base::sprintf("P%02d", base::seq_len(n_clusters)),
                         each = n_per_cluster)
  insurance <- base::factor(
    base::rep(base::c("Private", "Medicaid"), length.out = n),
    levels = base::c("Private", "Medicaid")
  )
  cluster_effect <- base::rep(
    stats::rnorm(n_clusters, sd = 0.20), each = n_per_cluster
  )
  log_mean <- base::log(12) + 0.24 * (insurance == "Medicaid") +
    cluster_effect
  # rnbinom, not rpois: with Poisson counts and unit exposure the negative
  # binomial dispersion is unidentifiable, glmmTMB returns optimizer code 1
  # with a non-positive-definite Hessian, and every nb assertion in this
  # suite would be validated against standard errors from that broken fit.
  # size = 4 gives mild, identifiable overdispersion.
  base::data.frame(
    wait_days = stats::rnbinom(n, mu = base::exp(log_mean), size = 4),
    insurance = insurance,
    physician = physician,
    exposure = base::rep(1, n),
    stringsAsFactors = FALSE
  )
}

mc_adv_fit <- function(sample_calls, family) {
  fitter <- base::switch(
    family,
    poisson = mysterycall::mysterycall_poisson_model,
    nb = mysterycall::mysterycall_nb_model,
    base::stop("Unknown family", call. = FALSE)
  )
  fitter(
    sample_calls,
    outcome = "wait_days",
    predictors = "insurance",
    random_intercept = "physician",
    offset_col = "exposure"
  )
}

mc_adv_families <- base::c("poisson", "nb")
