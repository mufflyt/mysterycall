# Snapshot tests for prose-generating functions
#
# Each test locks in the exact sentence/paragraph wording so that unintended
# changes during refactors are caught immediately.
#
# First run  -> records snapshots (all PASS with "Added N snapshots")
# Second run -> compares to recorded snapshots (PASS when stable)

# ── Fixed simulated dataset ───────────────────────────────────────────────────
# Created once at the top level so every test uses the same object.

set.seed(42)
n <- 60
sim_data <- data.frame(
  id_number = sprintf("%03d", rep(1:30, each = 2)),
  phone     = rep(sprintf("555-%04d", 1:30), each = 2),
  insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), 30),
  business_days = c(rpois(30, 14), rpois(30, 10)),
  reason_for_exclusions = sample(
    c("Able to contact", "Physician not available"), 60,
    replace = TRUE, prob = c(0.8, 0.2)
  ),
  gender   = sample(c("Male", "Female"), 60, replace = TRUE),
  scenario = sample(
    c("HIP scenario", "SHOULDER scenario", "KNEE scenario"), 60,
    replace = TRUE
  ),
  does_the_physician_accept_medicaid = sample(
    c("Yes they accept Medicaid", "No",
      "NA as this was a Blue Cross/Blue Shield call."),
    60, replace = TRUE
  ),
  stringsAsFactors = FALSE
)

# ── mysterycall_descriptive_stats ─────────────────────────────────────────────

test_that("mysterycall_descriptive_stats sentence snapshot", {
  result <- suppressMessages(
    mysterycall_descriptive_stats(sim_data, "business_days")
  )
  expect_snapshot(result$sentence)
})

# ── mysterycall_distribution_summary ─────────────────────────────────────────

test_that("mysterycall_distribution_summary sentence snapshot", {
  result <- suppressMessages(
    mysterycall_distribution_summary(sim_data, "insurance")
  )
  expect_snapshot(result$sentence)
})

test_that("mysterycall_distribution_summary scenario column sentence snapshot", {
  result <- suppressMessages(
    mysterycall_distribution_summary(sim_data, "scenario")
  )
  expect_snapshot(result$sentence)
})

# ── mysterycall_demographics_sentence ────────────────────────────────────────

test_that("mysterycall_demographics_sentence sentence snapshot", {
  result <- suppressMessages(
    mysterycall_demographics_sentence(
      sim_data,
      subspecialty_col = NULL,
      credential_col   = NULL
    )
  )
  # returns the sentence directly (character scalar)
  expect_snapshot(result)
})

# ── mysterycall_wait_time_sentence ────────────────────────────────────────────

test_that("mysterycall_wait_time_sentence sentence snapshot", {
  result <- suppressMessages(
    mysterycall_wait_time_sentence(
      sim_data,
      outcome_col = "business_days",
      group_col   = "insurance"
    )
  )
  expect_snapshot(result$sentence)
})

# ── mysterycall_insurance_wait_sentence ───────────────────────────────────────

test_that("mysterycall_insurance_wait_sentence sentence snapshot", {
  result <- suppressMessages(
    mysterycall_insurance_wait_sentence(
      sim_data,
      outcome_col = "business_days"
    )
  )
  expect_snapshot(result$sentence)
})

# ── mysterycall_scenario_summary ──────────────────────────────────────────────

test_that("mysterycall_scenario_summary sentence snapshot (generic levels)", {
  result <- suppressMessages(
    mysterycall_scenario_summary(
      sim_data,
      output_dir = NA
    )
  )
  expect_snapshot(result$sentence)
})

test_that("mysterycall_scenario_summary sentence snapshot (named levels)", {
  result <- suppressMessages(
    mysterycall_scenario_summary(
      sim_data,
      scenario_levels = c(
        hip      = "HIP scenario",
        shoulder = "SHOULDER scenario",
        knee     = "KNEE scenario"
      ),
      output_dir = NA
    )
  )
  expect_snapshot(result$sentence)
})

# ── mysterycall_sensitivity_both_insurance ────────────────────────────────────

test_that("mysterycall_sensitivity_both_insurance sentence snapshot", {
  result <- suppressMessages(
    mysterycall_sensitivity_both_insurance(
      sim_data,
      outcome_col = "business_days",
      output_dir  = NA
    )
  )
  expect_snapshot(result$sentence)
})

# ── mysterycall_overdispersion_sentence ───────────────────────────────────────

test_that("mysterycall_overdispersion_sentence sentence snapshot", {
  m_glm <- glm(
    business_days ~ insurance,
    data   = sim_data,
    family = poisson
  )
  result <- mysterycall_overdispersion_sentence(m_glm)
  expect_snapshot(result$sentence)
})

# ── mysterycall_r2_sentence ───────────────────────────────────────────────────

test_that("mysterycall_r2_sentence sentence snapshot", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  m_lmer <- lme4::lmer(
    business_days ~ insurance + (1 | id_number),
    data = sim_data,
    REML = TRUE
  )
  result <- suppressMessages(mysterycall_r2_sentence(m_lmer))
  expect_snapshot(result$sentence)
})

# ── mysterycall_random_effect_variance ────────────────────────────────────────

test_that("mysterycall_random_effect_variance sentence snapshot", {
  skip_if_not_installed("lme4")
  m_lmer <- lme4::lmer(
    business_days ~ insurance + (1 | id_number),
    data = sim_data,
    REML = TRUE
  )
  result <- suppressMessages(mysterycall_random_effect_variance(m_lmer))
  expect_snapshot(result$sentence)
})

# ── mysterycall_sample_demographics ──────────────────────────────────────────

test_that("mysterycall_sample_demographics summary_sentence snapshot", {
  # sample_demographics requires a state column; add one deterministically
  set.seed(42)
  state_data        <- sim_data
  state_data$state  <- rep(
    c("Colorado", "Texas", "California", "Florida", "New York",
      "Ohio", "Georgia", "Illinois", "Michigan", "Virginia"),
    6
  )
  result <- suppressMessages(
    mysterycall_sample_demographics(
      state_data,
      output_dir = NA
    )
  )
  expect_snapshot(result$summary_sentence)
})
