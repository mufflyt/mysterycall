# Tests for the small-sample categorical toolkit (R/categorical.R)

test_that("test_categorical uses chi-squared when cells are ample", {
  df <- data.frame(
    offered = c(rep("yes", 30), rep("no", 10), rep("yes", 18), rep("no", 22)),
    payer   = c(rep("commercial", 40), rep("medicaid", 40))
  )
  res <- mysterycall_test_categorical(df, "offered", "payer")
  expect_s3_class(res, "mysterycall_categorical_test")
  expect_match(res$method, "chi-squared")
  expect_equal(res$df, 1)
  expect_equal(res$n, 80L)
  expect_true(res$p_value < 0.05)
  expect_true(res$cramers_v > 0 && res$cramers_v <= 1)
  expect_true(res$effect_size %in% c("negligible", "small", "medium", "large"))
})

test_that("test_categorical falls back to Fisher on sparse cells", {
  df <- data.frame(
    outcome = c("rare", "common", "common", "common", "common", "common"),
    grp     = c("a", "a", "a", "b", "b", "b")
  )
  res <- mysterycall_test_categorical(df, "outcome", "grp")
  expect_match(res$method, "Fisher")
  expect_true(is.na(res$statistic))
  expect_true(res$min_expected < 5)
})

test_that("method = 'chisq' and 'fisher' force the choice", {
  df <- data.frame(
    outcome = c("rare", rep("common", 5)),
    grp     = c("a", "a", "a", "b", "b", "b")
  )
  expect_match(mysterycall_test_categorical(df, "outcome", "grp", method = "chisq")$method,
               "chi-squared")
  expect_match(mysterycall_test_categorical(df, "outcome", "grp", method = "fisher")$method,
               "Fisher")
})

test_that("Yates' correction toggles for 2x2", {
  df <- data.frame(
    offered = c(rep("yes", 30), rep("no", 10), rep("yes", 18), rep("no", 22)),
    payer   = c(rep("commercial", 40), rep("medicaid", 40))
  )
  with_c <- mysterycall_test_categorical(df, "offered", "payer", correct = TRUE)
  no_c   <- mysterycall_test_categorical(df, "offered", "payer", correct = FALSE)
  expect_match(with_c$method, "Yates")
  expect_false(grepl("Yates", no_c$method))
  # Yates lowers the statistic
  expect_true(with_c$statistic < no_c$statistic)
})

test_that("post-hoc pairwise proportions are BH-adjusted for a binary outcome", {
  df <- data.frame(
    offered = c(rep("yes", 38), rep("no", 2),   # group A ~95%
                rep("yes", 20), rep("no", 20),   # group B ~50%
                rep("yes", 8),  rep("no", 32)),  # group C ~20%
    grp = rep(c("A", "B", "C"), each = 40)
  )
  res <- mysterycall_test_categorical(df, "offered", "grp", posthoc = TRUE)
  expect_false(is.null(res$posthoc))
  expect_equal(nrow(res$posthoc), 3L)              # 3 pairwise comparisons
  expect_true(all(c("p_value", "p_adj") %in% names(res$posthoc)))
  expect_true(all(res$posthoc$p_adj >= res$posthoc$p_value))
})

test_that("cmh_test conditions on a matching stratum and returns a common OR", {
  set.seed(42)
  clinic  <- rep(paste0("c", 1:30), each = 2)
  persona <- rep(c("adult", "teen"), times = 30)
  offered <- rbinom(60, 1, ifelse(persona == "teen", 0.5, 0.85))
  df <- data.frame(clinic, persona,
                   offered = ifelse(offered == 1, "yes", "no"))
  res <- mysterycall_cmh_test(df, "offered", "persona", "clinic")
  expect_s3_class(res, "mysterycall_cmh_test")
  expect_equal(res$n_strata, 30L)
  expect_false(is.na(res$estimate))               # 2x2xK -> common OR present
  expect_length(res$conf_int, 2)
})

test_that("prevalence_ci returns Wilson and exact intervals", {
  df <- data.frame(
    staff = c(rep("pharmacist", 55), rep("technician", 30), rep("other", 15))
  )
  w <- mysterycall_prevalence_ci(df, "staff", method = "wilson")
  expect_s3_class(w, "tbl_df")
  expect_setequal(w$category, c("pharmacist", "technician", "other"))
  ph <- w[w$category == "pharmacist", ]
  expect_equal(ph$n, 55L)
  expect_equal(ph$proportion, 0.55)
  expect_true(ph$ci_lower < 0.55 && ph$ci_upper > 0.55)

  cp <- mysterycall_prevalence_ci(df, "staff", method = "clopper-pearson")
  expect_equal(cp$method[1], "clopper-pearson")
})

test_that("prevalence_ci supports a grouping variable", {
  df <- data.frame(
    outcome = c("yes", "no", "yes", "yes", "no", "no"),
    region  = c("A", "A", "A", "B", "B", "B")
  )
  g <- mysterycall_prevalence_ci(df, "outcome", group_var = "region")
  expect_true("group" %in% names(g))
  expect_setequal(unique(g$group), c("A", "B"))
})

test_that("compare_ranks runs Mann-Whitney for two groups", {
  set.seed(1)
  df <- data.frame(
    price = c(rexp(25, 1 / 20), rexp(25, 1 / 40)),
    payer = rep(c("A", "B"), each = 25)
  )
  res <- mysterycall_compare_ranks(df, "price", "payer")
  expect_s3_class(res, "mysterycall_rank_comparison")
  expect_match(res$method, "Mann-Whitney")
  expect_equal(nrow(res$group_summary), 2L)
  expect_true(res$effect_size >= 0)
})

test_that("compare_ranks runs Kruskal-Wallis for 3+ groups", {
  set.seed(2)
  df <- data.frame(
    wait = c(rpois(20, 5), rpois(20, 12), rpois(20, 20)),
    grp  = rep(c("A", "B", "C"), each = 20)
  )
  res <- mysterycall_compare_ranks(df, "wait", "grp")
  expect_match(res$method, "Kruskal-Wallis")
  expect_equal(res$df, 2)
  expect_equal(res$effect_type, "epsilon-squared")
  expect_true(res$p_value < 0.05)
})

test_that("print methods emit readable summaries", {
  df <- data.frame(
    offered = c(rep("yes", 30), rep("no", 10), rep("yes", 18), rep("no", 22)),
    payer   = c(rep("commercial", 40), rep("medicaid", 40))
  )
  expect_output(print(mysterycall_test_categorical(df, "offered", "payer")),
                "categorical_test")
  rc <- mysterycall_compare_ranks(
    data.frame(y = c(1, 2, 3, 8, 9, 10), g = rep(c("a", "b"), each = 3)), "y", "g")
  expect_output(print(rc), "rank_comparison")
  expect_s3_class(as.data.frame(rc), "data.frame")
})
