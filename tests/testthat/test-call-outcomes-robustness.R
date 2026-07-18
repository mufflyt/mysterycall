# Robustness tests for the Move-03 multi-category / multi-response call-outcome
# module (R/call_outcomes.R). Three groups: ADVERSARIAL, SEMANTIC, BVA.
# All expected values were confirmed by running the code, not assumed.
#
# KNOWN DEFECT (documented with FIXME below): duplicate options within a single
# call (e.g. "a;a") inflate `mean_options_per_call` because set-size counts the
# raw parsed vector length, which keeps duplicates. Per-option prevalence counts
# and the co-occurrence diagonal are NOT affected (they dedupe via `%in%` /
# `intersect`), so a call "a;a" reports 1 option in prevalence but 2 in the mean.

# ===================================================================
# ===== ADVERSARIAL =====
# ===================================================================

test_that("[adversarial] empty data.frame errors (min.rows = 1)", {
  expect_error(
    mysterycall_multiresponse_tabulate(data.frame(options = character(0)), "options")
  )
  expect_error(
    mysterycall_outcome_gradient(data.frame(access = character(0)), "access")
  )
  expect_error(
    mysterycall_ordinal_model(data.frame(y = character(0)), "y", "x")
  )
})

test_that("[adversarial] var / group_var absent from data errors", {
  d <- data.frame(options = c("a;b", "a"), stringsAsFactors = FALSE)
  expect_error(mysterycall_multiresponse_tabulate(d, "nope"))
  expect_error(mysterycall_multiresponse_tabulate(d, "options", group_var = "nope"))
  expect_error(mysterycall_outcome_gradient(d, "nope"))
})

test_that("[adversarial] a var that is entirely NA does not crash", {
  d <- data.frame(options = c(NA_character_, NA_character_), stringsAsFactors = FALSE)
  r <- mysterycall_multiresponse_tabulate(d, "options")
  expect_equal(r$summary$n_responding, 0L)
  expect_true(is.na(r$summary$mean_options_per_call))
  expect_true(is.na(r$summary$pct_naming_any))
  expect_equal(nrow(r$prevalence), 0L)
  expect_equal(dim(r$cooccurrence), c(0L, 0L))
})

test_that("[adversarial] options containing the delimiter / regex-special chars", {
  # fixed = TRUE splitting + %in% matching => no regex interpretation.
  d <- data.frame(o = c("a.b;c(d)", "a.b"), stringsAsFactors = FALSE)
  r <- mysterycall_multiresponse_tabulate(d, "o", sort = FALSE)
  expect_setequal(r$prevalence$option, c("a.b", "c(d)"))
  expect_equal(r$prevalence$n[r$prevalence$option == "a.b"], 2L)
  expect_equal(r$prevalence$n[r$prevalence$option == "c(d)"], 1L)
})

test_that("[adversarial] list-column var exercises the .mc_responding list path", {
  d <- data.frame(id = 1:4)
  d$opts <- list(c("a", "b"), NULL, NA, c("b"))
  r <- mysterycall_multiresponse_tabulate(d, "opts")
  # NULL and NA are both non-responding; rows 1 and 4 respond.
  expect_equal(r$summary$n_calls, 4L)
  expect_equal(r$summary$n_responding, 2L)
  expect_equal(r$summary$mean_options_per_call, 1.5)
  expect_equal(r$prevalence$n[r$prevalence$option == "b"], 2L)
  expect_equal(r$prevalence$n[r$prevalence$option == "a"], 1L)
})

test_that("[adversarial] duplicate options 'a;a' within one call dedupe consistently", {
  d <- data.frame(options = "a;a", stringsAsFactors = FALSE)
  r <- mysterycall_multiresponse_tabulate(d, "options")
  # Prevalence count is not double-counted:
  expect_equal(r$prevalence$n, 1L)
  # Co-occurrence diagonal is not double-counted:
  expect_equal(unname(r$cooccurrence["a", "a"]), 1L)
  # mean_options_per_call now counts DISTINCT options, so the duplicate collapses
  # to 1 -- consistent with prevalence and co-occurrence (bug fixed).
  expect_equal(r$summary$mean_options_per_call, 1)
})

test_that("[adversarial] classify with an empty mapping list errors (min.len = 1)", {
  expect_error(mysterycall_classify_call_outcome("anything", mapping = list()))
})

test_that("[adversarial] classify: earlier default-order pattern wins on double match", {
  # "referral" (referral_required) precedes "records" (records_required).
  expect_equal(
    as.character(mysterycall_classify_call_outcome("needs a referral and records")),
    "referral_required"
  )
  # "voicemail" (not_reached) precedes "call back" (gatekeeping_no_info).
  expect_equal(
    as.character(mysterycall_classify_call_outcome("left voicemail, told to call back")),
    "not_reached"
  )
})

test_that("[adversarial] ordinal_model with a predictor absent from data errors", {
  df <- data.frame(access = factor(c("a", "b", "a", "b")), x = c(1, 2, 3, 4))
  expect_error(mysterycall_ordinal_model(df, "access", "nope"))
})

test_that("[adversarial] outcome_gradient: a level absent from the data gives an n=0 row", {
  df <- data.frame(access = c("phone", "phone", "in_person"), stringsAsFactors = FALSE)
  g <- mysterycall_outcome_gradient(df, "access",
                                    levels = c("phone", "in_person", "never_seen"))
  row <- g[g$level == "never_seen", ]
  expect_equal(row$n, 0L)
  expect_equal(row$proportion, 0)
  expect_equal(row$ci_lower, 0)          # Wilson lower bound for 0/n is 0
  expect_false(is.na(row$ci_upper))      # upper bound is a real number, not NA
})

# ===================================================================
# ===== SEMANTIC =====
# ===================================================================

test_that("[semantic] prevalence n = responding calls naming option = co-occurrence diagonal", {
  d <- data.frame(o = c("a;b", "a;b", "a", "b;c"), stringsAsFactors = FALSE)
  r <- mysterycall_multiresponse_tabulate(d, "o", sort = FALSE)
  # a named by calls 1,2,3 => 3; b by 1,2,4 => 3; c by 4 => 1.
  expect_equal(r$prevalence$n[r$prevalence$option == "a"], 3L)
  expect_equal(r$prevalence$n[r$prevalence$option == "b"], 3L)
  expect_equal(r$prevalence$n[r$prevalence$option == "c"], 1L)
  # diagonal equals prevalence n, in matching option order
  diag_counts <- diag(r$cooccurrence)[r$prevalence$option]
  expect_equal(unname(diag_counts), r$prevalence$n)
})

test_that("[semantic] co-occurrence is symmetric; off-diagonal = calls naming BOTH", {
  d <- data.frame(o = c("a;b", "a;b", "a", "b;c"), stringsAsFactors = FALSE)
  r <- mysterycall_multiresponse_tabulate(d, "o", sort = FALSE)
  co <- r$cooccurrence
  expect_equal(co, t(co))                       # symmetric
  expect_equal(unname(co["a", "b"]), 2L)        # calls 1,2 name both a & b
  expect_equal(unname(co["b", "c"]), 1L)        # call 4 names both b & c
  expect_equal(unname(co["a", "c"]), 0L)        # no call names both a & c
})

test_that("[semantic] mean_options_per_call = mean set-size over responding calls", {
  d <- data.frame(o = c("a;b;c", "a", ""), stringsAsFactors = FALSE)
  r <- mysterycall_multiresponse_tabulate(d, "o")
  # set sizes: 3, 1, 0 over 3 responding calls => mean = 4/3 = 1.33
  expect_equal(r$summary$n_responding, 3L)
  expect_equal(r$summary$mean_options_per_call, round(4 / 3, 2))
})

test_that("[semantic] classify default-order precedence is exactly as specified", {
  # insurance_verification_required precedes referral_required
  expect_equal(
    as.character(mysterycall_classify_call_outcome("need insurance verification then a referral")),
    "insurance_verification_required"
  )
  # not_reached precedes declined ("unavailable" is in both, "voicemail" only in not_reached)
  expect_equal(
    as.character(mysterycall_classify_call_outcome("voicemail says appointment unavailable")),
    "not_reached"
  )
  # declined precedes appointment_offered ("not accept" vs "accepted")
  expect_equal(
    as.character(mysterycall_classify_call_outcome("will not accept, but accepted note")),
    "declined"
  )
  # levels are mapping order followed by 'other'
  f <- mysterycall_classify_call_outcome("qqzz no match here")
  expect_equal(as.character(f), "other")
  expect_equal(tail(levels(f), 1), "other")
})

test_that("[semantic] outcome_gradient proportions = n/total; cumulative reaches 1 when levels cover all", {
  df <- data.frame(access = c("phone", "phone", "in_person", "must_establish", "phone"),
                   stringsAsFactors = FALSE)
  g <- mysterycall_outcome_gradient(df, "access",
                                    levels = c("phone", "in_person", "must_establish"))
  expect_equal(g$proportion, round(g$n / g$total, 3))
  expect_equal(g$cumulative_prop, round(cumsum(g$n) / g$total[1], 3))
  expect_equal(tail(g$cumulative_prop, 1), 1)
})

test_that("[semantic] ordinal_model OR>1 for a predictor pushing toward higher tiers; no intercept rows", {
  skip_if_not_installed("MASS")
  set.seed(1)
  n <- 200
  med <- rbinom(n, 1, 0.5)
  lin <- 2 * med + rnorm(n)
  acc <- cut(lin, breaks = quantile(lin, c(0, .33, .66, 1)),
             labels = c("phone", "in_person", "must_establish"), include.lowest = TRUE)
  df <- data.frame(
    access = factor(acc, levels = c("phone", "in_person", "must_establish"), ordered = TRUE),
    medicaid = med
  )
  m <- mysterycall_ordinal_model(df, "access", "medicaid")
  expect_equal(m$term, "medicaid")            # only the predictor, no cutpoints
  expect_true(m$or > 1)                        # strong positive gradient
  expect_true(m$ci_lower > 1)                  # CI excludes 1
})

# ===================================================================
# ===== BVA (boundary-value analysis) =====
# ===================================================================

test_that("[BVA] single call (n = 1)", {
  d <- data.frame(o = "a;b", stringsAsFactors = FALSE)
  r <- mysterycall_multiresponse_tabulate(d, "o")
  expect_equal(r$summary$n_calls, 1L)
  expect_equal(r$summary$n_responding, 1L)
  expect_equal(r$summary$mean_options_per_call, 2)
  expect_equal(unname(diag(r$cooccurrence)), c(1L, 1L))
})

test_that("[BVA] a responding call with '' (zero options) is in denominator but names nothing", {
  d <- data.frame(o = c("a", ""), stringsAsFactors = FALSE)
  r <- mysterycall_multiresponse_tabulate(d, "o")
  expect_equal(r$summary$n_responding, 2L)              # empty string responds
  expect_equal(r$prevalence$total, 2L)                  # denominator counts it
  expect_equal(r$prevalence$n[r$prevalence$option == "a"], 1L)
  expect_equal(r$prevalence$prevalence[r$prevalence$option == "a"], 0.5)
  expect_equal(r$summary$pct_naming_any, 0.5)
})

test_that("[BVA] exactly one distinct option across all calls => 1x1 co-occurrence", {
  d <- data.frame(o = c("a", "a", "a"), stringsAsFactors = FALSE)
  r <- mysterycall_multiresponse_tabulate(d, "o")
  expect_equal(dim(r$cooccurrence), c(1L, 1L))
  expect_equal(unname(r$cooccurrence["a", "a"]), 3L)
})

test_that("[BVA] conf_level at boundaries 0.5 and 0.999", {
  d <- data.frame(o = c("a;b", "a"), stringsAsFactors = FALSE)
  r50 <- mysterycall_multiresponse_tabulate(d, "o", conf_level = 0.5)
  r999 <- mysterycall_multiresponse_tabulate(d, "o", conf_level = 0.999)
  # wider CI at higher confidence
  w50 <- r50$prevalence$ci_upper - r50$prevalence$ci_lower
  w999 <- r999$prevalence$ci_upper - r999$prevalence$ci_lower
  expect_true(all(w999 >= w50))
  # just outside the boundaries must error
  expect_error(mysterycall_multiresponse_tabulate(d, "o", conf_level = 0.4999))
  expect_error(mysterycall_multiresponse_tabulate(d, "o", conf_level = 0.9999))
})

test_that("[BVA] outcome_gradient with levels NOT covering every observed value (sums < 1)", {
  df <- data.frame(access = c("phone", "in_person", "must_establish", "phone"),
                   stringsAsFactors = FALSE)
  # omit must_establish from levels
  g <- mysterycall_outcome_gradient(df, "access", levels = c("phone", "in_person"))
  expect_lt(sum(g$proportion), 1)                       # uncounted value
  expect_lt(tail(g$cumulative_prop, 1), 1)              # final cumulative < 1
  expect_equal(g$total[1], 4L)                          # denominator still all non-NA rows
})

test_that("[BVA] ordinal outcome with exactly 2 levels vs 3+ levels", {
  skip_if_not_installed("MASS")
  set.seed(7)
  n <- 160
  x <- rnorm(n)
  # 2-level (binary) outcome: the wrapper now rejects it with a friendly message
  # pointing to logistic regression, instead of leaking MASS::polr's raw error.
  y2 <- factor(ifelse(x + rnorm(n) > 0, "hi", "lo"), levels = c("lo", "hi"), ordered = TRUE)
  df2 <- data.frame(y = y2, x = x)
  expect_error(mysterycall_ordinal_model(df2, "y", "x"), "3\\+ levels")
  # 3-level outcome
  y3 <- cut(x + rnorm(n), breaks = quantile(x + rnorm(n), c(0, .33, .66, 1)),
            labels = c("a", "b", "c"), include.lowest = TRUE)
  df3 <- data.frame(y = factor(y3, levels = c("a", "b", "c"), ordered = TRUE), x = x)
  m3 <- mysterycall_ordinal_model(df3, "y", "x")
  expect_equal(nrow(m3), 1L)                            # still one predictor row
})

test_that("[BVA] single predictor vs the boundary (predictors min.len = 1)", {
  skip_if_not_installed("MASS")
  set.seed(3)
  n <- 120
  x <- rnorm(n)
  z <- rnorm(n)
  y <- factor(cut(x + z + rnorm(n), breaks = 3, labels = c("a", "b", "c")), ordered = TRUE)
  df <- data.frame(y = y, x = x, z = z)
  m1 <- mysterycall_ordinal_model(df, "y", "x")
  expect_equal(nrow(m1), 1L)
  m2 <- mysterycall_ordinal_model(df, "y", c("x", "z"))
  expect_equal(nrow(m2), 2L)
  expect_setequal(m2$term, c("x", "z"))
  # zero predictors is below the boundary -> error
  expect_error(mysterycall_ordinal_model(df, "y", character(0)))
})

test_that("[BVA] pct_naming_any at 0 (all responding named nothing) and at 1", {
  # all responding calls named nothing
  d0 <- data.frame(o = c("", ""), stringsAsFactors = FALSE)
  r0 <- mysterycall_multiresponse_tabulate(d0, "o")
  expect_equal(r0$summary$pct_naming_any, 0)
  expect_equal(r0$summary$n_responding, 2L)
  expect_equal(nrow(r0$prevalence), 0L)                # no options named
  # all responding calls named something
  d1 <- data.frame(o = c("a", "b"), stringsAsFactors = FALSE)
  r1 <- mysterycall_multiresponse_tabulate(d1, "o")
  expect_equal(r1$summary$pct_naming_any, 1)
})
