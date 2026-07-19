# Tests for the within-practice paired analyses

# A tiny hand-checkable paired acceptance dataset (long form).
# practice: 1..6, two scenarios A and B.
#   p1: A=1 B=0  (discordant, favor A)
#   p2: A=1 B=0  (discordant, favor A)
#   p3: A=0 B=1  (discordant, favor B)
#   p4: A=1 B=1  (concordant)
#   p5: A=0 B=0  (concordant)
#   p6: A=1 B=0  (discordant, favor A)
acc_long <- function() {
  data.frame(
    practice = rep(1:6, each = 2),
    scenario = rep(c("A", "B"), 6),
    accepted = c(1,0, 1,0, 0,1, 1,1, 0,0, 1,0),
    stringsAsFactors = FALSE
  )
}

test_that("McNemar discordant counts and exact p match a hand calculation", {
  res <- mysterycall_paired_acceptance_mcnemar(acc_long(), "practice",
                                               "scenario", "accepted")
  expect_s3_class(res, "mysterycall_paired_mcnemar")
  r <- res$table[res$table$contrast == "A vs B", ]
  expect_equal(r$n_paired, 6L)
  expect_equal(r$discordant, 4L)          # p1,p2,p3,p6
  expect_equal(r$disc_favor_a, 3L)        # p1,p2,p6
  expect_equal(r$disc_favor_b, 1L)        # p3
  expect_equal(r$concordant, 2L)          # p4,p5
  # exact McNemar p = binom.test(min(3,1)=1, 4, 0.5)
  expect_equal(r$mcnemar_p, binom.test(1, 4)$p.value, tolerance = 1e-9)
  expect_equal(r$odds_ratio, 3)           # 3/1
})

test_that("McNemar exact p matches base mcnemar.test(correct=FALSE) is NOT assumed; exact via binom.test", {
  res <- mysterycall_paired_acceptance_mcnemar(acc_long(), "practice",
                                               "scenario", "accepted")
  r <- res$table[1, ]
  # the reported p is the exact binomial test on discordant pairs
  expect_true(r$mcnemar_p >= 0 && r$mcnemar_p <= 1)
})

test_that("MDE odds ratio is finite and > 1 for a reasonable discordant count", {
  set.seed(1)
  d <- data.frame(
    practice = rep(1:60, each = 2),
    scenario = rep(c("A", "B"), 60),
    accepted = rbinom(120, 1, rep(c(0.8, 0.5), 60)))
  res <- mysterycall_paired_acceptance_mcnemar(d, "practice", "scenario",
                                               "accepted")
  expect_true(is.finite(res$table$mde_or_power))
  expect_gt(res$table$mde_or_power, 1)
})

test_that("only practices called under both scenarios contribute", {
  d <- acc_long()
  # drop practice 6's B row -> p6 no longer paired
  d <- d[!(d$practice == 6 & d$scenario == "B"), ]
  res <- mysterycall_paired_acceptance_mcnemar(d, "practice", "scenario",
                                               "accepted")
  r <- res$table[1, ]
  expect_equal(r$n_paired, 5L)            # p1..p5
  expect_equal(r$disc_favor_a, 2L)        # p1,p2 only now
})

test_that("duplicate (id, scenario) rows error", {
  d <- rbind(acc_long(), data.frame(practice = 1, scenario = "A", accepted = 1))
  expect_error(
    mysterycall_paired_acceptance_mcnemar(d, "practice", "scenario", "accepted"),
    "more than one row"
  )
})

test_that("three scenarios produce all three pairwise contrasts by default", {
  set.seed(3)
  d <- data.frame(
    practice = rep(1:20, each = 3),
    scenario = rep(c("A", "B", "C"), 20),
    accepted = rbinom(60, 1, 0.6))
  res <- mysterycall_paired_acceptance_mcnemar(d, "practice", "scenario",
                                               "accepted")
  expect_equal(nrow(res$table), 3L)
  expect_setequal(res$table$contrast, c("A vs B", "A vs C", "B vs C"))
})

# ---- paired wait ------------------------------------------------------------

wait_long <- function() {
  data.frame(
    practice = rep(1:5, each = 2),
    scenario = rep(c("A", "B"), 5),
    wait = c(10,15, 8,20, 12,14, 5,25, 9,11),   # B - A diffs: 5,12,2,20,2
    stringsAsFactors = FALSE
  )
}

test_that("paired wait mean difference and t-test match base R", {
  res <- mysterycall_paired_wait_within_practice(wait_long(), "practice",
                                                 "scenario", "wait")
  expect_s3_class(res, "mysterycall_paired_wait")
  r <- res$table[1, ]
  a <- c(10, 8, 12, 5, 9); b <- c(15, 20, 14, 25, 11)   # A, B by practice
  expect_equal(r$n_paired, 5L)
  expect_equal(r$mean_diff_days, mean(a - b), tolerance = 1e-9)
  expect_equal(r$paired_t_p, t.test(a, b, paired = TRUE)$p.value, tolerance = 1e-9)
  expect_equal(r$wilcoxon_p,
               suppressWarnings(wilcox.test(a, b, paired = TRUE)$p.value),
               tolerance = 1e-9)
})

test_that("paired wait CI matches t.test conf.int", {
  res <- mysterycall_paired_wait_within_practice(wait_long(), "practice",
                                                 "scenario", "wait")
  a <- c(10, 8, 12, 5, 9); b <- c(15, 20, 14, 25, 11)
  ci <- t.test(a, b, paired = TRUE)$conf.int
  expect_equal(res$table$ci_lower[1], ci[1], tolerance = 1e-9)
  expect_equal(res$table$ci_upper[1], ci[2], tolerance = 1e-9)
})

test_that("paired wait MDE in days is positive when there is spread", {
  res <- mysterycall_paired_wait_within_practice(wait_long(), "practice",
                                                 "scenario", "wait")
  expect_true(is.finite(res$table$mde_days_power) &&
                res$table$mde_days_power > 0)
})

test_that("only fully paired practices count for wait", {
  d <- wait_long()
  d$wait[d$practice == 3 & d$scenario == "B"] <- NA   # break pair 3
  res <- mysterycall_paired_wait_within_practice(d, "practice", "scenario",
                                                 "wait")
  expect_equal(res$table$n_paired[1], 4L)
})

test_that("CSV export works for both", {
  dir <- withr::local_tempdir()
  mysterycall_paired_acceptance_mcnemar(acc_long(), "practice", "scenario",
                                        "accepted", output_dir = dir,
                                        filename = "mcnemar.csv")
  mysterycall_paired_wait_within_practice(wait_long(), "practice", "scenario",
                                          "wait", output_dir = dir,
                                          filename = "wait.csv")
  expect_true(file.exists(file.path(dir, "mcnemar.csv")))
  expect_true(file.exists(file.path(dir, "wait.csv")))
})

test_that("as.data.frame returns the tables", {
  expect_s3_class(as.data.frame(
    mysterycall_paired_acceptance_mcnemar(acc_long(), "practice", "scenario",
                                          "accepted")), "data.frame")
  expect_s3_class(as.data.frame(
    mysterycall_paired_wait_within_practice(wait_long(), "practice", "scenario",
                                            "wait")), "data.frame")
})
