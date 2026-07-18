# Robustness tests for the Move-01 guideline-concordance engine (R/concordance.R)
#
# Three clearly-labelled groups:
#   ADVERSARIAL - hostile / malformed inputs; must error cleanly or degrade
#                 gracefully rather than crash or silently corrupt.
#   SEMANTIC    - the numbers the engine reports must equal hand computations.
#   BVA         - boundary-value analysis of denominators, CIs, dates, weights.
#
# Every expectation below was confirmed by RUNNING the code, not assumed.

# A small Wilson score interval, duplicated here so SEMANTIC tests check the
# engine against an independent implementation (matches .mc_wilson_ci()).
wilson_ref <- function(x, n, conf_level = 0.95) {
  if (is.na(n) || n == 0) return(c(NA_real_, NA_real_))
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  phat <- x / n
  denom <- 1 + z^2 / n
  centre <- (phat + z^2 / (2 * n)) / denom
  half <- (z * sqrt(phat * (1 - phat) / n + z^2 / (4 * n^2))) / denom
  c(max(0, centre - half), min(1, centre + half))
}


# ===== ADVERSARIAL =====

test_that("[adversarial] empty data.frame is rejected (min.rows = 1)", {
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  expect_error(
    mysterycall_score_concordance(data.frame(x = logical(0)), rub, output_dir = NA),
    "at least 1 row"
  )
})

test_that("[adversarial] a rubric item absent from the data errors", {
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  expect_error(
    mysterycall_score_concordance(data.frame(y = c(TRUE, FALSE)), rub, output_dir = NA),
    "missing elements \\{'x'\\}"
  )
})

test_that("[adversarial] reference_match with NA reference_col fails at construction", {
  expect_error(
    mysterycall_concordance_rubric("endpoint", type = "reference_match"),
    "reference_col"
  )
})

test_that("[adversarial] duplicate item ids are rejected", {
  expect_error(
    mysterycall_concordance_rubric(c("a", "a")),
    "duplicated"
  )
})

test_that("[adversarial] garbage values in a binary column coerce to NA, not crash", {
  # "yes","true" -> TRUE ; "no" -> FALSE ; "banana","???" -> NA (not applicable)
  calls <- data.frame(x = c("yes", "banana", "no", "???", "true"),
                      stringsAsFactors = FALSE)
  rub <- mysterycall_concordance_rubric("x", type = "binary", correct = TRUE)
  res <- mysterycall_score_concordance(calls, rub, output_dir = NA)
  ir <- res$item_rates
  expect_equal(ir$n_applicable, 3L)   # yes / no / true coded; banana, ??? dropped
  expect_equal(ir$n_concordant, 2L)   # yes, true concordant with TRUE
  expect_equal(ir$rate, round(2 / 3, 3))
})

test_that("[adversarial] a non-rubric object as `rubric` errors", {
  expect_error(
    mysterycall_score_concordance(data.frame(x = TRUE), list(1), output_dir = NA),
    "must come from mysterycall_concordance_rubric"
  )
})

test_that("[adversarial] the prose builder errors on an unknown item", {
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  res <- mysterycall_score_concordance(data.frame(x = c(TRUE, FALSE)), rub,
                                       output_dir = NA)
  expect_error(
    mysterycall_concordance_sentence(res, item = "not_an_item"),
    "not found"
  )
})

test_that("[adversarial] evidence_tier options with regex-special chars match literally", {
  # Splitting is fixed = TRUE, so '+', '.', '|' are treated as literal text.
  tiers <- data.frame(
    option = c("a+b", "c.d", "e|f"),
    tier   = c("concordant", "nonconcordant", "concordant"),
    stringsAsFactors = FALSE
  )
  calls <- data.frame(opts = c("a+b", "c.d", "e|f", ""), stringsAsFactors = FALSE)
  rub <- mysterycall_concordance_rubric("opts", type = "evidence_tier",
                                        tier_lookup = tiers)
  ir <- mysterycall_score_concordance(calls, rub, output_dir = NA)$item_rates
  expect_equal(ir$n_applicable, 3L)   # empty string is not applicable
  expect_equal(ir$n_concordant, 2L)   # a+b and e|f concordant; c.d not
})

test_that("[adversarial] an option that itself contains the delimiter is split apart", {
  # A lookup option literally "a;b" can never match, because a call value "a;b"
  # is split on ';' into tokens "a" and "b". Documents current tokenisation.
  tiers <- data.frame(option = "a;b", tier = "concordant", stringsAsFactors = FALSE)
  calls <- data.frame(opts = c("a;b", "a"), stringsAsFactors = FALSE)
  rub <- mysterycall_concordance_rubric("opts", type = "evidence_tier",
                                        tier_lookup = tiers)
  ir <- mysterycall_score_concordance(calls, rub, output_dir = NA)$item_rates
  expect_equal(ir$n_applicable, 2L)
  expect_equal(ir$n_concordant, 0L)   # neither row matches the "a;b" option
})

test_that("[adversarial] kappa rejects mismatched-shape rater frames", {
  # With unequal row counts and no call_id_col the two raters cannot be aligned,
  # so the function now errors up front instead of silently recycling the shorter
  # column and returning a nonsense n (bug fixed).
  r1 <- data.frame(a = c(TRUE, TRUE, FALSE))
  r2 <- data.frame(a = c(TRUE, FALSE))
  rub <- mysterycall_concordance_rubric("a", type = "expected_present")
  expect_error(
    mysterycall_concordance_kappa(r1, r2, rub),
    "same number of rows"
  )
  # But differing row counts ARE allowed when a key aligns them.
  k1 <- data.frame(id = c(1, 2, 3), a = c(TRUE, TRUE, FALSE))
  k2 <- data.frame(id = c(3, 2, 1, 4), a = c(FALSE, TRUE, TRUE, FALSE))
  k <- mysterycall_concordance_kappa(k1, k2, rub, call_id_col = "id")
  expect_equal(k$n, 3L)                 # aligned on the 3 shared ids
  expect_equal(k$pct_agree, 1)          # all three agree once aligned
})


# ===== SEMANTIC =====

test_that("[semantic] item rate equals n_concordant / n_applicable", {
  calls <- data.frame(x = c(TRUE, TRUE, FALSE, NA, TRUE))  # 3 of 4 applicable
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  ir <- mysterycall_score_concordance(calls, rub, output_dir = NA)$item_rates
  expect_equal(ir$n_applicable, 4L)
  expect_equal(ir$n_concordant, 3L)
  expect_equal(ir$rate, round(ir$n_concordant / ir$n_applicable, 3))
})

test_that("[semantic] Wilson CI brackets the estimate and matches a hand computation", {
  calls <- data.frame(x = c(TRUE, TRUE, FALSE, NA, TRUE))  # x = 3, n = 4
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  ir <- mysterycall_score_concordance(calls, rub, conf_level = 0.95,
                                      output_dir = NA)$item_rates
  ref <- wilson_ref(3, 4, 0.95)
  expect_equal(ir$ci_lower, round(ref[1], 3))
  expect_equal(ir$ci_upper, round(ref[2], 3))
  expect_lt(ir$ci_lower, ir$rate)
  expect_gt(ir$ci_upper, ir$rate)
})

test_that("[semantic] composite per-call score_pct equals the hand value", {
  calls <- data.frame(
    a = c(TRUE, FALSE),
    b = c(TRUE, NA),        # row 2: b not applicable
    c = c(FALSE, TRUE)
  )
  rub <- mysterycall_concordance_rubric(c("a", "b", "c"), type = "binary")
  cs <- mysterycall_score_concordance(calls, rub, output_dir = NA)$call_scores
  # row 1: 2 concordant of 3 -> 66.7 ; row 2: 1 of 2 (b dropped) -> 50
  expect_equal(cs$n_applicable, c(3L, 2L))
  expect_equal(cs$n_concordant, c(2L, 1L))
  expect_equal(cs$score_pct, c(round(100 * 2 / 3, 1), 50))
})

test_that("[semantic] na_policy switches the denominator exactly as specified", {
  calls <- data.frame(x = c(TRUE, FALSE, NA, NA))
  na_drop <- mysterycall_score_concordance(
    calls, mysterycall_concordance_rubric("x", na_policy = "not_applicable"),
    output_dir = NA)$item_rates
  na_wrong <- mysterycall_score_concordance(
    calls, mysterycall_concordance_rubric("x", na_policy = "incorrect"),
    output_dir = NA)$item_rates
  expect_equal(na_drop$n_applicable, 2L)   # the two NAs dropped
  expect_equal(na_drop$n_concordant, 1L)
  expect_equal(na_wrong$n_applicable, 4L)  # full denominator
  expect_equal(na_wrong$n_concordant, 1L)  # NAs count as non-concordant
})

test_that("[semantic] reference_match concordance equals row-wise equality", {
  calls <- data.frame(
    endpoint = c("referral", "self_care", "referral", "referral"),
    expected = c("referral", "referral", "referral", "self_care"),
    stringsAsFactors = FALSE
  )
  hand <- sum(calls$endpoint == calls$expected)  # rows 1 and 3 -> 2
  rub <- mysterycall_concordance_rubric("endpoint", type = "reference_match",
                                        reference_col = "expected")
  ir <- mysterycall_score_concordance(calls, rub, output_dir = NA)$item_rates
  expect_equal(ir$n_applicable, 4L)
  expect_equal(ir$n_concordant, hand)
  expect_equal(ir$rate, round(hand / 4, 3))
})

test_that("[semantic] date-versioned evidence tier picks the right side of a cutover", {
  tiers <- data.frame(
    option = c("ibuprofen", "ibuprofen"),
    tier   = c("concordant", "nonconcordant"),
    effective_from = as.Date(c("2020-01-01", "2024-08-01")),
    effective_to   = as.Date(c("2024-07-31", NA)),
    stringsAsFactors = FALSE
  )
  calls <- data.frame(
    opts = c("ibuprofen", "ibuprofen"),
    call_date = as.Date(c("2023-01-01", "2025-01-01")),
    stringsAsFactors = FALSE
  )
  rub <- mysterycall_concordance_rubric("opts", type = "evidence_tier",
                                        tier_lookup = tiers)
  cs <- mysterycall_score_concordance(calls, rub, date_col = "call_date",
                                      output_dir = NA)$call_scores
  expect_equal(cs$score_pct[1], 100)   # concordant under the pre-2024 guideline
  expect_equal(cs$score_pct[2], 0)     # nonconcordant under the 2024 guideline
})

test_that("[semantic] kappa matches a hand-computed Cohen's kappa; pct_agree = fraction equal", {
  a <- c(TRUE, TRUE, FALSE, TRUE, FALSE)
  b <- c(TRUE, FALSE, FALSE, TRUE, FALSE)
  po <- mean(a == b)
  cats <- union(unique(a), unique(b))
  pe <- sum(vapply(cats, function(k) mean(a == k) * mean(b == k), numeric(1)))
  kappa_hand <- (po - pe) / (1 - pe)
  rub <- mysterycall_concordance_rubric("a", type = "expected_present")
  k <- mysterycall_concordance_kappa(data.frame(a = a), data.frame(a = b), rub)
  expect_equal(k$n, 5L)
  expect_equal(k$pct_agree, round(po, 3))       # 0.8
  expect_equal(k$kappa, round(kappa_hand, 3))   # 0.615
})

test_that("[semantic] by_group mean_score_pct equals mean of that group's call scores", {
  calls <- data.frame(x = c(TRUE, FALSE, TRUE, TRUE), g = c("A", "A", "B", "B"))
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  res <- mysterycall_score_concordance(calls, rub, group_col = "g", output_dir = NA)
  cs <- res$call_scores
  a_mean <- mean(cs$score_pct[calls$g == "A"])
  b_mean <- mean(cs$score_pct[calls$g == "B"])
  bg <- res$by_group
  expect_equal(bg$mean_score_pct[bg$group == "A"], round(a_mean, 1))  # 50
  expect_equal(bg$mean_score_pct[bg$group == "B"], round(b_mean, 1))  # 100
})


# ===== BVA =====

test_that("[BVA] a single call produces a coherent overall summary", {
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  res <- mysterycall_score_concordance(data.frame(x = TRUE), rub, output_dir = NA)
  expect_equal(res$overall$n_calls, 1L)
  expect_equal(res$overall$mean_score_pct, 100)
  expect_true(is.na(res$overall$sd_score_pct))     # sd of one value is NA
  expect_equal(nrow(res$call_scores), 1L)
})

test_that("[BVA] a single-item rubric scores end to end", {
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  res <- mysterycall_score_concordance(data.frame(x = FALSE), rub, output_dir = NA)
  expect_equal(nrow(res$item_rates), 1L)
  expect_equal(res$call_scores$score_pct, 0)
})

test_that("[BVA] an all-TRUE item has rate 1 and a Wilson upper clamped at 1", {
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  ir <- mysterycall_score_concordance(data.frame(x = c(TRUE, TRUE, TRUE)), rub,
                                      output_dir = NA)$item_rates
  expect_equal(ir$rate, 1)
  expect_equal(ir$ci_upper, 1)          # clamped
  expect_lt(ir$ci_lower, 1)
})

test_that("[BVA] an all-FALSE item has rate 0 and a Wilson lower clamped at 0", {
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  ir <- mysterycall_score_concordance(data.frame(x = c(FALSE, FALSE, FALSE)), rub,
                                      output_dir = NA)$item_rates
  expect_equal(ir$rate, 0)
  expect_equal(ir$ci_lower, 0)          # clamped
  expect_gt(ir$ci_upper, 0)
})

test_that("[BVA] an all-NA item: not_applicable drops it; incorrect fills the denominator", {
  calls <- data.frame(x = as.logical(c(NA, NA, NA)))
  drop <- mysterycall_score_concordance(
    calls, mysterycall_concordance_rubric("x", na_policy = "not_applicable"),
    output_dir = NA)
  wrong <- mysterycall_score_concordance(
    calls, mysterycall_concordance_rubric("x", na_policy = "incorrect"),
    output_dir = NA)$item_rates
  # not_applicable: nothing applicable -> rate and Wilson are NA
  expect_equal(drop$item_rates$n_applicable, 0L)
  expect_true(is.na(drop$item_rates$rate))
  expect_true(is.na(drop$item_rates$ci_lower))
  expect_true(is.na(drop$item_rates$ci_upper))
  expect_true(is.nan(drop$overall$mean_score_pct))  # no scorable calls
  # incorrect: full denominator, zero concordant
  expect_equal(wrong$n_applicable, 3L)
  expect_equal(wrong$n_concordant, 0L)
  expect_equal(wrong$rate, 0)
})

test_that("[BVA] conf_level is accepted at its 0.5 and 0.999 bounds and rejected below", {
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  d <- data.frame(x = c(TRUE, FALSE))
  lo <- mysterycall_score_concordance(d, rub, conf_level = 0.5, output_dir = NA)$item_rates
  hi <- mysterycall_score_concordance(d, rub, conf_level = 0.999, output_dir = NA)$item_rates
  # wider confidence -> wider interval
  expect_lt(hi$ci_lower, lo$ci_lower)
  expect_gt(hi$ci_upper, lo$ci_upper)
  expect_error(
    mysterycall_score_concordance(d, rub, conf_level = 0.4, output_dir = NA),
    "0.5"
  )
})

test_that("[BVA] dates exactly on effective_from and effective_to are in force (inclusive)", {
  tiers <- data.frame(
    option = "ibuprofen", tier = "concordant",
    effective_from = as.Date("2024-01-01"),
    effective_to   = as.Date("2024-12-31"),
    stringsAsFactors = FALSE
  )
  calls <- data.frame(
    opts = rep("ibuprofen", 4),
    d = as.Date(c("2023-12-31", "2024-01-01", "2024-12-31", "2025-01-01")),
    stringsAsFactors = FALSE
  )
  rub <- mysterycall_concordance_rubric("opts", type = "evidence_tier",
                                        tier_lookup = tiers)
  cs <- mysterycall_score_concordance(calls, rub, date_col = "d",
                                      output_dir = NA)$call_scores
  # day before window: not in force -> 0 ; both boundaries inclusive -> 100 ;
  # day after window: not in force -> 0
  expect_equal(cs$score_pct, c(0, 100, 100, 0))
})

test_that("[BVA] a tiny positive weight is accepted and does not distort a single-item score", {
  rub <- mysterycall_concordance_rubric("x", type = "binary",
                                        weight = .Machine$double.eps)
  res <- mysterycall_score_concordance(data.frame(x = c(TRUE, FALSE, TRUE)), rub,
                                       output_dir = NA)
  # single item: the weight cancels, so weighted_pct == score_pct per call
  expect_equal(res$call_scores$weighted_pct, res$call_scores$score_pct)
  # weight of exactly 0 is out of range
  expect_error(mysterycall_concordance_rubric("x", weight = 0), "weight")
})
