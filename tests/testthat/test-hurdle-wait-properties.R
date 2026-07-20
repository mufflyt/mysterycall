# Property-based test suite for mysterycall_hurdle_wait().
#
# Organised by the property class each group enforces:
#   Invariant   - domain rules that must ALWAYS hold (ORs/IRRs > 0, CI ordering)
#   Cardinality - relationships between entities (n_count vs n_hurdle, term sets)
#   Idempotency - the same call twice returns identical tables
#   Snapshot    - the output *schema* is frozen against silent format drift
#   Boundary    - the poisson and fixed-effects-only branches (BVA edges live in
#                 test-hurdle-wait-bva.R; these cover the remaining branches)
#   Temporal    - the wait values fed to the count part make logical sense
#   Statistical - a known simulated signal is recovered in the right direction
#   Mutation    - the invariant checks actually reject broken results
#   Metamorphic - row order and level relabelling preserve the fit
#
# Every expectation was confirmed by RUNNING the code, not assumed.

# Clear signal: Medicaid is harder to obtain (lower odds) and waits longer
# (higher rate). Both parts therefore have a recoverable, opposite-signed effect.
make_hw_data <- function(seed = 42, n = 160) {
  set.seed(seed)
  d <- data.frame(
    practice  = rep(sprintf("p%03d", seq_len(n)), each = 2),
    insurance = rep(c("Commercial", "Medicaid"), n),
    stringsAsFactors = FALSE)
  med <- d$insurance == "Medicaid"
  d$obtained  <- rbinom(nrow(d), 1, plogis(1.2 - 1.0 * med))
  d$wait_days <- ifelse(d$obtained == 1,
                        rnbinom(nrow(d), mu = ifelse(med, 24, 12), size = 3), NA)
  d
}

# Shared invariant checker -- reused by the Invariant group (to assert it passes
# on real output) and the Mutation group (to assert it fails on broken output).
hw_invariants_hold <- function(res) {
  ok <- inherits(res, "mysterycall_hurdle_wait")
  for (p in list(res$hurdle, res$count)) {
    ok <- ok && !anyNA(p$estimate) && all(p$estimate > 0)          # ORs/IRRs > 0
    ok <- ok && all(p$conf_low  <= p$estimate + 1e-9)              # low <= est
    ok <- ok && all(p$conf_high >= p$estimate - 1e-9)              # est <= high
    ok <- ok && all(p$conf_low  <= p$conf_high)                    # low <= high
    ok <- ok && !anyNA(p$p_value) && all(p$p_value >= 0 & p$p_value <= 1)
  }
  ok && res$n_count <= res$n_hurdle
}

# ---- Invariant ---------------------------------------------------------------

test_that("Invariant: estimates positive, CIs ordered, p in [0,1], n_count<=n_hurdle", {
  skip_if_not_installed("glmmTMB")
  res <- mysterycall_hurdle_wait(make_hw_data(), "obtained", "wait_days",
                                 "insurance", random_intercept = "practice")
  expect_true(hw_invariants_hold(res))
  # both parts always carry an intercept term
  expect_true("(Intercept)" %in% res$hurdle$term)
  expect_true("(Intercept)" %in% res$count$term)
})

# ---- Cardinality -------------------------------------------------------------

test_that("Cardinality: n_count equals the obtained, non-missing, positive-wait subset", {
  skip_if_not_installed("glmmTMB")
  d <- make_hw_data()
  res <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                 random_intercept = "practice")
  expect_equal(res$n_hurdle, nrow(d))
  expect_equal(res$n_count,
               sum(d$obtained == 1 & !is.na(d$wait_days) & d$wait_days > 0))
})

test_that("Cardinality: both parts share the same fixed-effect term set", {
  skip_if_not_installed("glmmTMB")
  res <- mysterycall_hurdle_wait(make_hw_data(), "obtained", "wait_days",
                                 "insurance", random_intercept = "practice")
  # identical design on both sides -> identical (Intercept + one level) terms
  expect_setequal(res$hurdle$term, res$count$term)
  # the random intercept never leaks into the fixed-effect table
  expect_false(any(grepl("practice", res$hurdle$term)))
  expect_false(any(grepl("practice", res$count$term)))
})

test_that("Cardinality: as.data.frame stacks the two parts exactly", {
  skip_if_not_installed("glmmTMB")
  res <- mysterycall_hurdle_wait(make_hw_data(), "obtained", "wait_days",
                                 "insurance")
  df <- as.data.frame(res)
  expect_equal(nrow(df), nrow(res$hurdle) + nrow(res$count))
  expect_equal(sum(df$part == "hurdle"), nrow(res$hurdle))
  expect_equal(sum(df$part == "count"),  nrow(res$count))
  expect_setequal(unique(df$part), c("hurdle", "count"))
})

# ---- Idempotency -------------------------------------------------------------

test_that("Idempotency: the same call twice returns identical tables", {
  skip_if_not_installed("glmmTMB")
  d <- make_hw_data()
  a <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                               random_intercept = "practice")
  b <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                               random_intercept = "practice")
  expect_equal(a$hurdle, b$hurdle)
  expect_equal(a$count, b$count)
  expect_equal(a$n_hurdle, b$n_hurdle)
  expect_equal(a$n_count, b$n_count)
  # the derived data frame is likewise stable across repeated extraction
  expect_equal(as.data.frame(a), as.data.frame(b))
})

# ---- Snapshot ----------------------------------------------------------------

test_that("Snapshot: the output schema is frozen", {
  skip_if_not_installed("glmmTMB")
  res <- mysterycall_hurdle_wait(make_hw_data(), "obtained", "wait_days",
                                 "insurance", random_intercept = "practice")
  df <- as.data.frame(res)
  # only deterministic, format-level facts are snapshotted -- never the fitted
  # numbers, which legitimately move with glmmTMB/TMB versions.
  expect_snapshot({
    cat("class:        ", paste(class(res), collapse = ", "), "\n")
    cat("names:        ", paste(names(res), collapse = ", "), "\n")
    cat("hurdle cols:  ", paste(names(res$hurdle), collapse = ", "), "\n")
    cat("count cols:   ", paste(names(res$count), collapse = ", "), "\n")
    cat("hurdle terms: ", paste(sort(res$hurdle$term), collapse = ", "), "\n")
    cat("count terms:  ", paste(sort(res$count$term), collapse = ", "), "\n")
    cat("count_family: ", res$count_family, "\n")
    cat("truncated:    ", res$truncated, "\n")
    cat("adf cols:     ", paste(names(df), collapse = ", "), "\n")
    cat("adf parts:    ", paste(unique(as.character(df$part)), collapse = ", "), "\n")
  })
})

# ---- Boundary (branches not covered by the BVA file) -------------------------

test_that("Boundary: the poisson count family is honoured and still returns IRRs", {
  skip_if_not_installed("glmmTMB")
  res <- mysterycall_hurdle_wait(make_hw_data(), "obtained", "wait_days",
                                 "insurance", count_family = "poisson")
  expect_equal(res$count_family, "poisson")
  expect_true(all(res$count$estimate > 0))
  expect_s3_class(res$count_model, "glmmTMB")
})

test_that("Boundary: untruncated poisson count family fits (stats::poisson branch)", {
  skip_if_not_installed("glmmTMB")
  # exercises the count_family="poisson" + truncate_zero=FALSE switch arm, which
  # must use stats::poisson() (glmmTMB does not export a `poisson` object).
  res <- mysterycall_hurdle_wait(make_hw_data(), "obtained", "wait_days",
                                 "insurance", count_family = "poisson",
                                 truncate_zero = FALSE)
  expect_equal(res$count_family, "poisson")
  expect_false(res$truncated)
  expect_true(hw_invariants_hold(res))
  expect_s3_class(res$count_model, "glmmTMB")
})

test_that("Boundary: fixed-effects-only (random_intercept = NULL) fits both parts", {
  skip_if_not_installed("glmmTMB")
  res <- mysterycall_hurdle_wait(make_hw_data(), "obtained", "wait_days",
                                 "insurance", random_intercept = NULL)
  expect_true(hw_invariants_hold(res))
  # with no RE requested, the fitted formula carries no bar term
  expect_false(grepl("\\|", deparse(stats::formula(res$count_model))[1]))
})

# ---- Temporal consistency ----------------------------------------------------

test_that("Temporal: waits entering the count part are non-negative integers", {
  skip_if_not_installed("glmmTMB")
  d <- make_hw_data()

  trunc <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                   truncate_zero = TRUE)
  w_trunc <- trunc$count_model$frame[["wait_days"]]
  expect_false(anyNA(w_trunc))                  # no not-obtained NA leaks in
  expect_true(all(w_trunc == round(w_trunc)))   # day counts, not fractions
  expect_true(all(w_trunc > 0))                 # zero-truncation respected

  keep <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                  truncate_zero = FALSE)
  w_keep <- keep$count_model$frame[["wait_days"]]
  expect_true(all(w_keep >= 0))                 # untruncated: same-day allowed
  expect_false(anyNA(w_keep))
})

# ---- Statistical validation --------------------------------------------------

test_that("Statistical: the simulated signal is recovered in the right direction", {
  skip_if_not_installed("glmmTMB")
  # large, clean sample so the recovered signs are stable
  d <- make_hw_data(seed = 7, n = 400)
  res <- mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
                                 random_intercept = "practice")

  or_med  <- res$hurdle$estimate[res$hurdle$term == "insuranceMedicaid"]
  irr_med <- res$count$estimate[res$count$term == "insuranceMedicaid"]
  # Medicaid: lower odds of obtaining an appointment (OR < 1)...
  expect_lt(or_med, 1)
  # ...and, once obtained, a longer wait (IRR > 1)
  expect_gt(irr_med, 1)

  # the hurdle intercept maps back to the baseline (Commercial) obtainment rate
  baseline_p <- plogis(log(res$hurdle$estimate[res$hurdle$term == "(Intercept)"]))
  emp_p <- mean(d$obtained[d$insurance == "Commercial"] == 1)
  expect_equal(unname(baseline_p), emp_p, tolerance = 0.1)
})

# ---- Mutation (do the invariant checks have teeth?) --------------------------

test_that("Mutation: hw_invariants_hold rejects deliberately broken results", {
  skip_if_not_installed("glmmTMB")
  res <- mysterycall_hurdle_wait(make_hw_data(), "obtained", "wait_days",
                                 "insurance", random_intercept = "practice")
  expect_true(hw_invariants_hold(res))               # baseline: valid

  neg <- res; neg$count$estimate[1] <- -1            # a non-positive IRR
  expect_false(hw_invariants_hold(neg))

  swap <- res                                        # CI bounds inverted
  swap$hurdle$conf_low[1]  <- res$hurdle$conf_high[1] + 1
  expect_false(hw_invariants_hold(swap))

  badp <- res; badp$hurdle$p_value[1] <- 1.5         # p-value out of [0,1]
  expect_false(hw_invariants_hold(badp))

  bign <- res; bign$n_count <- res$n_hurdle + 1L     # more counts than samples
  expect_false(hw_invariants_hold(bign))
})

# ---- Metamorphic (transformations that must preserve the fit) ----------------

test_that("Metamorphic: row order does not change the fit", {
  skip_if_not_installed("glmmTMB")
  d <- make_hw_data()
  set.seed(99); shuffled <- d[sample(nrow(d)), , drop = FALSE]
  # fixed-effects-only so the comparison is numerically exact
  a <- mysterycall_hurdle_wait(d,        "obtained", "wait_days", "insurance")
  b <- mysterycall_hurdle_wait(shuffled, "obtained", "wait_days", "insurance")
  expect_equal(a$hurdle$estimate, b$hurdle$estimate, tolerance = 1e-5)
  expect_equal(a$count$estimate,  b$count$estimate,  tolerance = 1e-5)
  expect_equal(a$n_count, b$n_count)
})

test_that("Metamorphic: relabelling factor levels preserves the estimates", {
  skip_if_not_installed("glmmTMB")
  d <- make_hw_data()
  d2 <- d
  # order-preserving relabel (grpA < grpB keeps Commercial as the reference)
  d2$insurance <- ifelse(d$insurance == "Commercial", "grpA", "grpB")
  a <- mysterycall_hurdle_wait(d,  "obtained", "wait_days", "insurance")
  b <- mysterycall_hurdle_wait(d2, "obtained", "wait_days", "insurance")
  # term labels change (insuranceMedicaid -> insurancegrpB) but values do not
  expect_equal(sort(a$hurdle$estimate), sort(b$hurdle$estimate),
               tolerance = 1e-5, ignore_attr = TRUE)
  expect_equal(sort(a$count$estimate), sort(b$count$estimate),
               tolerance = 1e-5, ignore_attr = TRUE)
})
