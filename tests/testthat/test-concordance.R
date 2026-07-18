# Tests for the guideline-concordance scoring engine (R/concordance.R)

test_that("rubric constructor validates and normalises items", {
  rub <- mysterycall_concordance_rubric(
    item = c("a", "b"),
    type = c("binary", "expected_present"),
    correct = list(FALSE, TRUE)
  )
  expect_s3_class(rub, "mysterycall_rubric")
  expect_equal(nrow(rub$items), 2L)
  # expected_present forces correct = TRUE
  expect_true(rub$items$correct[[2]])
  # label defaults to item
  expect_equal(rub$items$label, c("a", "b"))

  expect_error(
    mysterycall_concordance_rubric(c("a", "a")),        # non-unique
    "duplicated"
  )
  expect_error(
    mysterycall_concordance_rubric("a", type = "nope"), # bad type
    "type"
  )
  expect_error(
    mysterycall_concordance_rubric("a", type = "reference_match"),
    "reference_col"
  )
})

test_that("binary scoring computes item rates and Wilson CIs", {
  calls <- data.frame(
    x = c(TRUE, TRUE, FALSE, NA, TRUE),   # 3 concordant of 4 applicable (NA dropped)
    y = c(TRUE, TRUE, TRUE, TRUE, TRUE)
  )
  rub <- mysterycall_concordance_rubric(c("x", "y"), type = "binary", correct = TRUE)
  res <- mysterycall_score_concordance(calls, rub, output_dir = NA)

  expect_s3_class(res, "mysterycall_concordance")
  xr <- res$item_rates[res$item_rates$item == "x", ]
  expect_equal(xr$n_applicable, 4L)   # NA excluded from denominator
  expect_equal(xr$n_concordant, 3L)
  expect_equal(xr$rate, 0.75)
  expect_true(xr$ci_lower < 0.75 && xr$ci_upper > 0.75)

  yr <- res$item_rates[res$item_rates$item == "y", ]
  expect_equal(yr$rate, 1)
})

test_that("na_policy = 'incorrect' keeps NA in the denominator as non-concordant", {
  calls <- data.frame(x = c(TRUE, FALSE, NA, NA))
  rub <- mysterycall_concordance_rubric("x", type = "binary", na_policy = "incorrect")
  res <- mysterycall_score_concordance(calls, rub, output_dir = NA)
  xr <- res$item_rates
  expect_equal(xr$n_applicable, 4L)   # all rows count
  expect_equal(xr$n_concordant, 1L)   # only the TRUE
})

test_that("composite call score divides concordant by applicable", {
  calls <- data.frame(
    a = c(TRUE, FALSE),
    b = c(TRUE, NA),      # row 2: b not applicable
    c = c(FALSE, TRUE)
  )
  rub <- mysterycall_concordance_rubric(c("a", "b", "c"), type = "binary")
  res <- mysterycall_score_concordance(calls, rub, output_dir = NA)
  cs <- res$call_scores
  # row 1: 2 of 3 concordant -> 66.7%
  expect_equal(cs$n_applicable[1], 3L)
  expect_equal(cs$n_concordant[1], 2L)
  expect_equal(cs$score_pct[1], 66.7)
  # row 2: b dropped -> 1 of 2 concordant -> 50%
  expect_equal(cs$n_applicable[2], 2L)
  expect_equal(cs$score_pct[2], 50)
})

test_that("reference_match scores against a per-row gold standard", {
  calls <- data.frame(
    endpoint = c("referral", "self_care", "referral", "referral"),
    expected = c("referral", "referral", "referral", "self_care")
  )
  rub <- mysterycall_concordance_rubric(
    "endpoint", type = "reference_match", reference_col = "expected"
  )
  res <- mysterycall_score_concordance(calls, rub, output_dir = NA)
  ir <- res$item_rates
  expect_equal(ir$n_applicable, 4L)
  expect_equal(ir$n_concordant, 2L)   # rows 1 and 3 match
  expect_equal(ir$rate, 0.5)
})

test_that("evidence_tier scores named options against a lookup", {
  tiers <- data.frame(
    option = c("lidocaine", "naproxen", "ibuprofen", "misoprostol"),
    tier   = c("concordant", "concordant", "nonconcordant", "nonconcordant"),
    stringsAsFactors = FALSE
  )
  calls <- data.frame(
    opts = c("ibuprofen", "lidocaine;ibuprofen", "", "misoprostol"),
    stringsAsFactors = FALSE
  )
  rub <- mysterycall_concordance_rubric(
    "opts", type = "evidence_tier", tier_lookup = tiers
  )
  res <- mysterycall_score_concordance(calls, rub, output_dir = NA)
  ir <- res$item_rates
  # applicable = named >=1 option: rows 1,2,4 (row 3 empty -> n/a)
  expect_equal(ir$n_applicable, 3L)
  # concordant = named >=1 concordant option: only row 2
  expect_equal(ir$n_concordant, 1L)
})

test_that("date-versioned evidence tiers pick the lookup in force", {
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
  rub <- mysterycall_concordance_rubric(
    "opts", type = "evidence_tier", tier_lookup = tiers
  )
  res <- mysterycall_score_concordance(calls, rub, date_col = "call_date",
                                       output_dir = NA)
  cs <- res$call_scores
  expect_equal(cs$score_pct[1], 100)  # concordant under the 2023 guideline
  expect_equal(cs$score_pct[2], 0)    # nonconcordant under the 2024 guideline
})

test_that("group summary is produced for a disparities breakdown", {
  calls <- data.frame(
    x = c(TRUE, FALSE, TRUE, TRUE),
    g = c("A", "A", "B", "B")
  )
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  res <- mysterycall_score_concordance(calls, rub, group_col = "g", output_dir = NA)
  expect_false(is.null(res$by_group))
  expect_setequal(res$by_group$group, c("A", "B"))
  b <- res$by_group[res$by_group$group == "B", ]
  expect_equal(b$mean_score_pct, 100)
})

test_that("per-item kappa is computed across two raters", {
  r1 <- data.frame(a = c(TRUE, TRUE, FALSE, TRUE, FALSE))
  r2 <- data.frame(a = c(TRUE, FALSE, FALSE, TRUE, FALSE))
  rub <- mysterycall_concordance_rubric("a", type = "expected_present")
  k <- mysterycall_concordance_kappa(r1, r2, rub)
  expect_equal(k$item, "a")
  expect_equal(k$n, 5L)
  expect_equal(k$pct_agree, 0.8)          # 4 of 5 agree
  expect_true(k$kappa > 0 && k$kappa <= 1)
})

test_that("prose builder emits numbers-locked sentences", {
  calls <- data.frame(advised_window = c(TRUE, TRUE, FALSE, NA, TRUE))
  rub <- mysterycall_concordance_rubric("advised_window", type = "binary",
                                        label = "Advised on windows")
  res <- mysterycall_score_concordance(calls, rub, output_dir = NA)

  item_sen <- mysterycall_concordance_sentence(res, item = "advised_window",
                                               subject = "pharmacies")
  expect_match(item_sen, "75.0%")
  expect_match(item_sen, "n = 4")

  overall_sen <- mysterycall_concordance_sentence(res, subject = "pharmacies")
  expect_match(overall_sen, "pharmacies")

  expect_error(
    mysterycall_concordance_sentence(res, item = "nope"),
    "not found"
  )
})

test_that("print and as.data.frame methods work", {
  calls <- data.frame(x = c(TRUE, FALSE, TRUE))
  rub <- mysterycall_concordance_rubric("x", type = "binary")
  res <- mysterycall_score_concordance(calls, rub, output_dir = NA)
  expect_output(print(res), "mysterycall_concordance")
  expect_output(print(rub), "mysterycall_rubric")
  df <- as.data.frame(res)
  expect_s3_class(df, "data.frame")
  expect_true("rate" %in% names(df))
})
