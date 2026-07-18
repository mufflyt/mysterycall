# Robustness tests for the Move-02 small-sample categorical toolkit
# (R/categorical.R): mysterycall_test_categorical, mysterycall_cmh_test,
# mysterycall_prevalence_ci, mysterycall_compare_ranks.
#
# Tests are grouped ADVERSARIAL / SEMANTIC / BVA and were written against the
# code's ACTUAL, empirically-confirmed behaviour (never assumed).

# Helper: expand a labelled count matrix into a long data frame with columns
# `r` (rows) and `c` (cols), suitable for table(data$r, data$c).
mk_df <- function(tab) {
  rn <- rownames(tab); cn <- colnames(tab)
  do.call(rbind, lapply(seq_len(nrow(tab)), function(i) {
    do.call(rbind, lapply(seq_len(ncol(tab)), function(j) {
      if (tab[i, j] == 0) return(NULL)
      data.frame(
        r = rep(rn[i], tab[i, j]),
        c = rep(cn[j], tab[i, j]),
        stringsAsFactors = FALSE
      )
    }))
  }))
}


# ===== ADVERSARIAL =====

test_that("[adversarial] a variable with only one observed level errors 'at least two'", {
  df <- data.frame(r = rep("a", 10), c = rep(c("x", "y"), 5))
  expect_error(
    mysterycall_test_categorical(df, "r", "c"),
    "at least two"
  )
})

test_that("[adversarial] an empty data frame is rejected by the input assertions", {
  de <- data.frame(r = character(0), c = character(0))
  expect_error(
    mysterycall_test_categorical(de, "r", "c"),
    "at least 1 row"
  )
})

test_that("[adversarial] a row_var/col_var absent from the data errors", {
  df <- mk_df(matrix(c(10, 10, 10, 10), 2,
                     dimnames = list(c("a", "b"), c("x", "y"))))
  expect_error(
    mysterycall_test_categorical(df, "nope", "c"),
    "Names must include"
  )
  expect_error(
    mysterycall_test_categorical(df, "r", "absent"),
    "Names must include"
  )
})

test_that("[adversarial] a perfectly independent table gives chi2=0, V=0, p=1", {
  # 10/10/10/10 is exactly proportional -> zero association
  df <- mk_df(matrix(c(10, 10, 10, 10), 2,
                     dimnames = list(c("a", "b"), c("x", "y"))))
  res <- mysterycall_test_categorical(df, "r", "c",
                                      method = "chisq", correct = FALSE)
  expect_equal(res$statistic, 0)
  expect_equal(res$cramers_v, 0)
  expect_equal(res$p_value, 1)
  expect_equal(res$effect_size, "negligible")
})

test_that("[adversarial] a sparse table forces the Fisher fallback under auto", {
  # min expected < 5 -> auto switches to an exact test
  df <- mk_df(matrix(c(4, 5, 5, 6), 2,
                     dimnames = list(c("a", "b"), c("x", "y"))))
  res <- suppressWarnings(
    mysterycall_test_categorical(df, "r", "c", method = "auto")
  )
  expect_match(res$method, "Fisher")
  expect_true(is.na(res$statistic))
  expect_true(is.na(res$df))
})

test_that("[adversarial] a large sparse r x c table triggers the simulated FFH fallback without crashing", {
  set.seed(7)
  big <- matrix(sample(1:5, 8 * 8, replace = TRUE), 8, 8,
                dimnames = list(paste0("r", 1:8), paste0("c", 1:8)))
  dfb <- mk_df(big)
  res <- suppressWarnings(
    mysterycall_test_categorical(dfb, "r", "c", method = "fisher")
  )
  expect_match(res$method, "Fisher")
  expect_match(res$method, "simulated")
  expect_true(is.numeric(res$p_value) && res$p_value >= 0 && res$p_value <= 1)
})

test_that("[adversarial] NA values in the crosstab vars are dropped by table()", {
  dna <- data.frame(
    r = c("a", "a", "b", "b", NA, "a"),
    c = c("x", "y", "x", "y", "x", NA),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_test_categorical(dna, "r", "c", method = "fisher")
  # only the 4 complete (r, c) rows contribute to the table
  expect_equal(res$n, 4L)
  expect_equal(sum(res$table), 4L)
})

test_that("[adversarial] compare_ranks with one group entirely NA errors 'at least two non-missing'", {
  drna <- data.frame(
    price = c(rexp(10, 1 / 20), rep(NA_real_, 10)),
    payer = rep(c("A", "B"), each = 10)
  )
  expect_error(
    mysterycall_compare_ranks(drna, "price", "payer"),
    "at least two non-missing"
  )
})

test_that("[adversarial] compare_ranks accepts numeric (non-character) group labels", {
  set.seed(3)
  drn <- data.frame(
    price = c(rexp(10, 1 / 20), rexp(10, 1 / 35)),
    payer = rep(c(1, 2), each = 10)
  )
  res <- suppressWarnings(mysterycall_compare_ranks(drn, "price", "payer"))
  expect_s3_class(res, "mysterycall_rank_comparison")
  expect_setequal(res$group_summary$group, c("1", "2"))
})


# ===== SEMANTIC =====

test_that("[semantic] chisq statistic/df/p_value match stats::chisq.test exactly", {
  df <- mk_df(matrix(c(20, 10, 12, 18), 2,
                     dimnames = list(c("a", "b"), c("x", "y"))))
  tab <- table(df$r, df$c)

  res_y <- mysterycall_test_categorical(df, "r", "c",
                                        method = "chisq", correct = TRUE)
  cs_y <- stats::chisq.test(tab, correct = TRUE)
  expect_equal(res_y$statistic, unname(cs_y$statistic))
  expect_equal(res_y$df, unname(cs_y$parameter))
  expect_equal(res_y$p_value, cs_y$p.value)

  res_n <- mysterycall_test_categorical(df, "r", "c",
                                        method = "chisq", correct = FALSE)
  cs_n <- stats::chisq.test(tab, correct = FALSE)
  expect_equal(res_n$statistic, unname(cs_n$statistic))
  expect_equal(res_n$p_value, cs_n$p.value)
})

test_that("[semantic] Fisher p_value matches stats::fisher.test", {
  df <- mk_df(matrix(c(2, 8, 7, 3), 2,
                     dimnames = list(c("a", "b"), c("x", "y"))))
  res <- mysterycall_test_categorical(df, "r", "c", method = "fisher")
  expect_equal(res$p_value, stats::fisher.test(table(df$r, df$c))$p.value)
})

test_that("[semantic] Cramer's V matches the hand formula sqrt(chi2/(n*(k-1)))", {
  df <- mk_df(matrix(c(20, 10, 12, 18), 2,
                     dimnames = list(c("a", "b"), c("x", "y"))))
  tab <- table(df$r, df$c)
  chi2 <- unname(stats::chisq.test(tab, correct = FALSE)$statistic)
  n <- sum(tab)
  k <- min(dim(tab))
  v_hand <- round(sqrt(chi2 / (n * (k - 1))), 3)
  res <- mysterycall_test_categorical(df, "r", "c",
                                      method = "chisq", correct = FALSE)
  expect_equal(res$cramers_v, v_hand)
})

test_that("[semantic] cmh_test statistic/p_value/estimate/conf_int match mantelhaen.test", {
  set.seed(1)
  clinic  <- rep(paste0("c", 1:20), each = 2)
  persona <- rep(c("adult", "teen"), times = 20)
  off     <- rbinom(40, 1, ifelse(persona == "teen", 0.55, 0.8))
  df <- data.frame(clinic, persona,
                   offered = ifelse(off == 1, "yes", "no"))
  res <- mysterycall_cmh_test(df, "offered", "persona", "clinic")

  tab <- table(df$offered, df$persona, df$clinic)
  ht <- stats::mantelhaen.test(tab, correct = TRUE,
                               conf.level = 0.95, exact = FALSE)
  expect_equal(res$statistic, unname(ht$statistic))
  expect_equal(res$p_value, ht$p.value)
  expect_equal(res$estimate, unname(ht$estimate))
  expect_equal(res$conf_int, as.numeric(ht$conf.int))
})

test_that("[semantic] prevalence proportions sum to 1 and n sums to total", {
  dp <- data.frame(staff = c(rep("pharmacist", 55),
                             rep("technician", 30),
                             rep("other", 15)))
  pv <- mysterycall_prevalence_ci(dp, "staff")
  expect_equal(sum(pv$proportion), 1)
  expect_equal(sum(pv$n), 100L)
  expect_true(all(pv$total == 100L))
})

test_that("[semantic] Clopper-Pearson matches binom.test and Wilson matches the hand formula", {
  dp <- data.frame(x = c(rep("a", 30), rep("b", 70)))

  pcp <- mysterycall_prevalence_ci(dp, "x", method = "clopper-pearson")
  bt <- stats::binom.test(30, 100)$conf.int
  expect_equal(pcp$ci_lower[pcp$category == "a"], round(bt[1], 3))
  expect_equal(pcp$ci_upper[pcp$category == "a"], round(bt[2], 3))

  pw <- mysterycall_prevalence_ci(dp, "x", method = "wilson")
  z <- stats::qnorm(0.975); x <- 30; tot <- 100; ph <- x / tot
  den <- 1 + z^2 / tot
  ctr <- (ph + z^2 / (2 * tot)) / den
  hf  <- (z * sqrt(ph * (1 - ph) / tot + z^2 / (4 * tot^2))) / den
  expect_equal(pw$ci_lower[pw$category == "a"], round(max(0, ctr - hf), 3))
  expect_equal(pw$ci_upper[pw$category == "a"], round(min(1, ctr + hf), 3))
})

test_that("[semantic] compare_ranks matches wilcox.test (2 groups) and kruskal.test (3+ groups)", {
  set.seed(2)
  dr <- data.frame(price = c(rexp(20, 1 / 20), rexp(20, 1 / 35)),
                   payer = rep(c("A", "B"), each = 20))
  cr <- suppressWarnings(mysterycall_compare_ranks(dr, "price", "payer"))
  wt <- suppressWarnings(stats::wilcox.test(price ~ payer, data = dr, exact = FALSE))
  expect_equal(cr$statistic, unname(wt$statistic))
  expect_equal(cr$p_value, wt$p.value)
  expect_equal(cr$effect_type, "r (Z/sqrt(N))")

  dr3 <- data.frame(
    price = c(rexp(15, 1 / 20), rexp(15, 1 / 30), rexp(15, 1 / 40)),
    payer = rep(c("A", "B", "C"), each = 15)
  )
  cr3 <- mysterycall_compare_ranks(dr3, "price", "payer")
  kt <- stats::kruskal.test(price ~ payer, data = dr3)
  expect_equal(cr3$statistic, unname(kt$statistic))
  expect_equal(cr3$p_value, kt$p.value)
  expect_equal(cr3$effect_type, "epsilon-squared")
})

test_that("[semantic] epsilon-squared equals H/((n^2-1)/(n+1))", {
  dr3 <- data.frame(
    price = c(rexp(15, 1 / 20), rexp(15, 1 / 30), rexp(15, 1 / 40)),
    payer = rep(c("A", "B", "C"), each = 15)
  )
  cr3 <- mysterycall_compare_ranks(dr3, "price", "payer")
  kt <- stats::kruskal.test(price ~ payer, data = dr3)
  n <- cr3$n
  eps <- round(as.numeric(kt$statistic) / ((n^2 - 1) / (n + 1)), 3)
  expect_equal(cr3$effect_size, eps)
})


# ===== BVA (boundary-value analysis) =====

test_that("[BVA] min_expected: exactly 5 chooses chi-squared (condition is strict <)", {
  # balanced 5/5/5/5 -> every expected cell == 5 exactly
  df <- mk_df(matrix(c(5, 5, 5, 5), 2,
                     dimnames = list(c("a", "b"), c("x", "y"))))
  res <- mysterycall_test_categorical(df, "r", "c", method = "auto")
  expect_equal(res$min_expected, 5)
  expect_match(res$method, "chi-squared")
})

test_that("[BVA] min_expected: just under 5 switches auto to Fisher", {
  df <- mk_df(matrix(c(4, 5, 5, 6), 2,
                     dimnames = list(c("a", "b"), c("x", "y"))))
  res <- suppressWarnings(
    mysterycall_test_categorical(df, "r", "c", method = "auto")
  )
  expect_true(res$min_expected < 5)
  expect_match(res$method, "Fisher")
})

test_that("[BVA] 2x2 reports df=1 and 2x3 reports df=2", {
  d22 <- mk_df(matrix(c(20, 10, 12, 18), 2,
                      dimnames = list(c("a", "b"), c("x", "y"))))
  r22 <- mysterycall_test_categorical(d22, "r", "c", method = "chisq")
  expect_equal(r22$df, 1)

  d23 <- mk_df(matrix(c(10, 5, 8, 7, 6, 9), 2,
                      dimnames = list(c("a", "b"), c("x", "y", "z"))))
  r23 <- mysterycall_test_categorical(d23, "r", "c", method = "chisq")
  expect_equal(r23$df, 2)
})

test_that("[BVA] Yates correction lowers the 2x2 statistic vs correct=FALSE", {
  df <- mk_df(matrix(c(20, 10, 12, 18), 2,
                     dimnames = list(c("a", "b"), c("x", "y"))))
  ry <- mysterycall_test_categorical(df, "r", "c",
                                     method = "chisq", correct = TRUE)
  rn <- mysterycall_test_categorical(df, "r", "c",
                                     method = "chisq", correct = FALSE)
  expect_lt(ry$statistic, rn$statistic)
  expect_match(ry$method, "Yates")
})

test_that("[BVA] posthoc produces exactly one comparison (2-level) vs three (3-level)", {
  d2 <- data.frame(
    out = c(rep("yes", 30), rep("no", 10), rep("yes", 12), rep("no", 28)),
    grp = rep(c("A", "B"), each = 40)
  )
  p2 <- mysterycall_test_categorical(d2, "out", "grp", posthoc = TRUE)
  expect_equal(nrow(p2$posthoc), 1L)

  d3 <- data.frame(
    out = c(rep("yes", 30), rep("no", 10),
            rep("yes", 10), rep("no", 30),
            rep("yes", 20), rep("no", 20)),
    grp = rep(c("A", "B", "C"), each = 40)
  )
  p3 <- mysterycall_test_categorical(d3, "out", "grp", posthoc = TRUE)
  expect_equal(nrow(p3$posthoc), 3L)
})

test_that("[BVA] prevalence proportion at 1 clamps CI upper to 1 and stays within [0,1]", {
  d1 <- data.frame(x = rep("yes", 20))
  p1 <- mysterycall_prevalence_ci(d1, "x")
  expect_equal(p1$proportion, 1)
  expect_equal(p1$ci_upper, 1)
  expect_gte(p1$ci_lower, 0)

  # a rare category clamps the lower bound to 0 under the (unbounded) Wald method
  dr <- data.frame(x = c("rare", rep("common", 99)))
  pw <- mysterycall_prevalence_ci(dr, "x", method = "wald")
  expect_true(all(pw$ci_lower >= 0))
  expect_true(all(pw$ci_upper <= 1))
})

test_that("[BVA] conf_level at the 0.5 and 0.999 boundaries both work and order the width", {
  dp <- data.frame(x = c(rep("a", 30), rep("b", 70)))
  p50  <- mysterycall_prevalence_ci(dp, "x", conf_level = 0.5)
  p999 <- mysterycall_prevalence_ci(dp, "x", conf_level = 0.999)
  w50  <- p50$ci_upper[1]  - p50$ci_lower[1]
  w999 <- p999$ci_upper[1] - p999$ci_lower[1]
  expect_lt(w50, w999)
})

test_that("[BVA] CMH with a single stratum errors with a friendly message", {
  # A single-stratum CMH is degenerate; the wrapper now rejects it up front and
  # points to the two-way test, instead of leaking mantelhaen.test's raw error.
  df <- data.frame(
    offered = rep(c("yes", "no"), 20),
    persona = rep(c("adult", "teen"), each = 20),
    clinic  = "only_one"
  )
  expect_error(
    mysterycall_cmh_test(df, "offered", "persona", "clinic"),
    "at least two strata"
  )
})

test_that("[BVA] compare_ranks at exactly 2 groups uses Mann-Whitney; exactly 3 uses Kruskal-Wallis", {
  set.seed(4)
  d2 <- data.frame(y = c(rexp(15, 1 / 10), rexp(15, 1 / 15)),
                   g = rep(c("A", "B"), each = 15))
  r2 <- suppressWarnings(mysterycall_compare_ranks(d2, "y", "g"))
  expect_match(r2$method, "Mann-Whitney")
  expect_true(is.na(r2$df))

  d3 <- data.frame(y = c(rexp(10, 1 / 10), rexp(10, 1 / 15), rexp(10, 1 / 20)),
                   g = rep(c("A", "B", "C"), each = 10))
  r3 <- mysterycall_compare_ranks(d3, "y", "g")
  expect_equal(r3$method, "Kruskal-Wallis")
  expect_equal(r3$df, 2)
})

test_that("[BVA] heavy ties in the ranked outcome still match wilcox.test", {
  dt <- data.frame(
    y = c(rep(1, 10), rep(2, 10), rep(1, 8), rep(2, 12)),
    g = rep(c("A", "B"), each = 20)
  )
  rt <- suppressWarnings(mysterycall_compare_ranks(dt, "y", "g"))
  wt <- suppressWarnings(stats::wilcox.test(y ~ g, data = dt, exact = FALSE))
  expect_equal(rt$statistic, unname(wt$statistic))
  expect_equal(rt$p_value, wt$p.value)
})
