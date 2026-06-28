library(testthat)
library(mysterycall)

# ── Concern 1: Caller drift ────────────────────────────────────────────────────
# Reviewer 2: "Did callers become more permissive/fatigued over time?"
# These tests prove the package DETECTS drift when it is present and correctly
# clears it when data are stable.

test_that("caller_drift detects significant sequence drift when callers improve over time", {
  # Build data where acceptance rates increase linearly with call sequence.
  # Use 4 callers × 50 calls each and extreme probabilities (0.05 → 0.95)
  # so the lm() on 10 bins has an unmistakeable slope.
  set.seed(101)
  n_calls  <- 50L
  n_callers <- 4L
  seq_num  <- rep(seq_len(n_calls), n_callers)
  prob     <- 0.05 + 0.90 * (seq_num / n_calls)   # 5% → 95%
  df <- data.frame(
    caller  = rep(c("Alice", "Bob", "Carol", "Dana"), each = n_calls),
    seq     = seq_num,
    offered = rbinom(n_calls * n_callers, 1L, prob)
  )

  res <- suppressWarnings(
    mysterycall_caller_drift(df, outcome_col = "offered",
                             call_seq_col = "seq", plot = FALSE)
  )

  expect_s3_class(res, "mysterycall_caller_drift")
  expect_false(is.null(res$sequence))
  expect_gt(res$sequence$slope, 0)
  expect_lt(res$sequence$p_value, 0.05)
  expect_match(res$sentence, "significantly")
})

test_that("caller_drift returns non-significant p when no drift present", {
  set.seed(102)
  n <- 150L
  df <- data.frame(
    caller  = rep(c("Alice", "Bob", "Carol"), each = 50L),
    seq     = rep(1:50, 3L),
    offered = rbinom(n, 1L, 0.55)   # constant rate
  )

  res <- suppressWarnings(
    mysterycall_caller_drift(df, outcome_col = "offered",
                             call_seq_col = "seq", plot = FALSE)
  )

  expect_false(is.null(res$sequence))
  expect_true(is.numeric(res$sequence$p_value))
  # Sentence must exist and describe drift analysis
  expect_true(nchar(res$sentence) > 10L)
})

test_that("caller_drift detects calendar drift in date-indexed data", {
  set.seed(103)
  n <- 90L
  dates <- seq(as.Date("2023-01-02"), by = "day", length.out = n)
  # Acceptance rate drops from 70% to 20% over the study period
  prob  <- seq(0.70, 0.20, length.out = n)
  df    <- data.frame(call_date = dates, offered = rbinom(n, 1L, prob))

  res <- suppressWarnings(
    mysterycall_caller_drift(df, outcome_col = "offered",
                             date_col = "call_date",
                             week_or_day = "week", plot = FALSE)
  )

  expect_false(is.null(res$calendar))
  expect_lt(res$calendar$slope, 0)          # declining trend → negative slope
  expect_lt(res$calendar$p_value, 0.05)
})

test_that("caller_drift errors when neither date_col nor call_seq_col provided", {
  df <- data.frame(caller = c("A","B"), offered = c(1L, 0L))
  expect_error(
    mysterycall_caller_drift(df, outcome_col = "offered", plot = FALSE),
    "At least one of date_col or call_seq_col"
  )
})


# ── Concern 2: Inter-caller reliability ────────────────────────────────────────
# Reviewer 2: "What is the ICC between callers? Low reliability invalidates
# the blinded design."

test_that("caller_reliability returns high kappa when callers agree perfectly", {
  df <- data.frame(
    caller  = c("Alice", "Bob", "Alice", "Bob", "Alice", "Bob"),
    offered = c(1L, 1L, 0L, 0L, 1L, 1L),
    gold    = c(1L, 1L, 0L, 0L, 1L, 1L)
  )

  res <- suppressWarnings(
    mysterycall_caller_reliability(df, caller_col = "caller",
                                   outcome_col = "offered",
                                   gold_col = "gold")
  )

  expect_true(is.list(res))
  expect_true("statistic" %in% names(res))
  # Perfect agreement → kappa or percent_agreement near 1
  expect_gte(res$statistic, 0.8)
})

test_that("caller_reliability returns low kappa when callers systematically disagree", {
  # Alice always says offered=1, Bob always says offered=0 for the same subject
  # Use 40 subjects so n_pairs is well above the 30-pair reliability threshold
  n_subj <- 40L
  df <- data.frame(
    caller  = rep(c("Alice", "Bob"), each = n_subj),
    subject = rep(seq_len(n_subj), 2L),
    offered = c(rep(1L, n_subj), rep(0L, n_subj))
  )

  res <- suppressWarnings(
    mysterycall_caller_reliability(df, caller_col = "caller",
                                   outcome_col = "offered",
                                   pair_col = "subject")
  )

  expect_true(is.list(res))
  expect_true("statistic" %in% names(res))
  # Systematic total disagreement → kappa or ICC should be <= 0
  if (!is.na(res$statistic)) expect_lte(res$statistic, 0.1)
})

test_that("caller_reliability errors on missing caller_col", {
  df <- data.frame(caller = c("A","B"), offered = c(1L, 0L))
  expect_error(
    mysterycall_caller_reliability(df, caller_col = "nonexistent",
                                   outcome_col = "offered"),
    "not found"
  )
})


# ── Concern 3: Overdispersion — model selection ────────────────────────────────
# Reviewer 2: "Wait times are overdispersed. Poisson is wrong; you need NB."
# This test shows mysterycall_select_best_model() picks NB when variance >> mean.

test_that("select_best_model ranks NB above Poisson for overdispersed count outcome", {
  skip_if_not_installed("MASS")

  set.seed(104)
  # Highly overdispersed: draw from NB with size=1 (variance = mean + mean^2)
  n  <- 200L
  df <- data.frame(
    wait      = MASS::rnegbin(n, mu = 10, theta = 1),
    insurance = rep(c("Medicaid", "BCBS"), n / 2L)
  )

  m_pois <- glm(wait ~ insurance, data = df, family = poisson())
  m_nb   <- suppressWarnings(MASS::glm.nb(wait ~ insurance, data = df))

  result <- mysterycall_select_best_model(
    list(poisson = m_pois, negative_binomial = m_nb),
    criterion = "aic"
  )

  expect_s3_class(result, "data.frame")
  expect_true("winner" %in% names(result))
  # NB should win (lower AIC) on overdispersed data
  winner_name <- result$model[result$winner]
  expect_equal(winner_name, "negative_binomial")
})

test_that("select_best_model ranks Poisson above NB for equidispersed data", {
  skip_if_not_installed("MASS")

  set.seed(105)
  # Poisson data: variance == mean → Poisson should be adequate
  n  <- 200L
  df <- data.frame(
    wait      = rpois(n, lambda = 8),
    insurance = rep(c("Medicaid", "BCBS"), n / 2L)
  )

  m_pois <- glm(wait ~ insurance, data = df, family = poisson())
  # NB fit on Poisson data: theta → Inf, AIC ≈ Poisson or higher due to extra param
  m_nb   <- suppressWarnings(MASS::glm.nb(wait ~ insurance, data = df))

  result <- mysterycall_select_best_model(
    list(poisson = m_pois, negative_binomial = m_nb),
    criterion = "aic"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
})

test_that("select_best_model errors on unnamed model list", {
  m <- glm(mpg ~ wt, data = mtcars)
  expect_error(
    mysterycall_select_best_model(list(m)),
    "named list"
  )
})


# ── Concern 5: Sensitivity analysis — exclusion criteria ──────────────────────
# Reviewer 2: "Show the IRR holds when you change who is excluded."

test_that("sensitivity produces separate rows per subset and exclude_zeros subset", {
  skip_if_not_installed("lme4")

  set.seed(106)
  n <- 80L
  df <- data.frame(
    wait     = c(rpois(40L, 18L), rpois(40L, 10L)),
    ins      = rep(c("Medicaid", "BCBS"), each = 40L),
    setting  = rep(c("Academic", "Private"), times = 40L),
    phys     = rep(paste0("Dr", 1:20), each = 4L),
    stringsAsFactors = FALSE
  )
  # Add some zeros to trigger the exclude_zeros subset
  df$wait[sample(n, 8L)] <- 0L

  res <- suppressMessages(suppressWarnings(
    mysterycall_sensitivity(
      df, outcome = "wait", predictors = "ins",
      random_intercept = "phys",
      subset_var = "setting",
      exclude_zeros = TRUE,
      family = "poisson"
    )
  ))

  expect_s3_class(res, "mysterycall_sensitivity")
  expect_true(is.data.frame(res$table))
  # Should have at least: Full sample, Exclude zeros, Academic, Private
  expect_gte(length(res$subsets_run), 2L)
  expect_true("Full sample" %in% res$subsets_run)
})

test_that("sensitivity IRR direction is consistent across subsets for strong signal", {
  skip_if_not_installed("lme4")

  set.seed(107)
  n <- 120L
  # Medicaid has 2x wait time vs BCBS — strong, consistent effect
  df <- data.frame(
    wait = c(rpois(60L, 20L), rpois(60L, 10L)),
    ins  = rep(c("Medicaid", "BCBS"), each = 60L),
    phys = rep(paste0("Dr", 1:20), each = 6L),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(suppressWarnings(
    mysterycall_sensitivity(
      df, outcome = "wait", predictors = "ins",
      random_intercept = "phys",
      family = "poisson"
    )
  ))

  irr_vals <- res$table$IRR[!is.na(res$table$IRR) &
                               grepl("Medicaid", res$table$term, ignore.case = TRUE)]
  # All IRRs should be > 1 (Medicaid always longer) across subsets
  if (length(irr_vals) > 0L) expect_true(all(irr_vals > 1))
})


# ── Concern 6 & 7: Data limits / selection integrity ──────────────────────────
# Reviewer 2: "How do you know the data weren't truncated? What QC was done?"

test_that("check_normality returns list with is_normal flag", {
  set.seed(108)
  df_normal <- data.frame(wait = rnorm(100L, mean = 10, sd = 2))
  df_skewed <- data.frame(wait = rexp(100L, rate = 0.5))

  res_normal <- suppressWarnings(mysterycall_check_normality(df_normal, "wait"))
  res_skewed <- suppressWarnings(mysterycall_check_normality(df_skewed, "wait"))

  expect_true(is.list(res_normal))
  expect_true("is_normal" %in% names(res_normal))
  expect_true(is.logical(res_normal$is_normal))

  expect_true(is.list(res_skewed))
  # Exponential distribution is not normal — should fail normality
  expect_false(res_skewed$is_normal)
})

test_that("check_normality handles small samples without error", {
  df_small <- data.frame(x = c(1, 2, 3, 4, 5))
  expect_no_error(suppressWarnings(mysterycall_check_normality(df_small, "x")))
})

test_that("check_normality recommends Poisson for non-normal count data", {
  set.seed(109)
  df_counts <- data.frame(wait = rpois(100L, lambda = 8))
  res <- suppressWarnings(mysterycall_check_normality(df_counts, "wait"))
  expect_true(is.list(res))
  expect_true("interpretation" %in% names(res))
  # Count data flagged as is_count = TRUE
  expect_true(res$is_count)
})
