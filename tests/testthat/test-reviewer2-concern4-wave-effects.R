library(testthat)
library(mysterycall)

# ── Concern 4: Wave effects / temporal confounding ────────────────────────────
#
# Reviewer 2: "Your calls were made in two waves. What if Medicaid calls all
# happened in Wave 1 and BCBS in Wave 2, when wait times were systemically
# different? The insurance effect you report is really a time effect."
#
# These tests show compare_waves() exposes imbalanced wave × insurance designs
# and correctly flags a significant wave effect when one exists.

test_that("compare_waves detects significant wave difference for proportion outcome", {
  # Wave 1 acceptance rate = 70%, Wave 2 = 30% — strong temporal shift
  set.seed(201)
  df <- data.frame(
    wave    = rep(c(1L, 2L), each = 60L),
    offered = c(rbinom(60L, 1L, 0.70), rbinom(60L, 1L, 0.30))
  )

  res <- suppressWarnings(
    mysterycall_compare_waves(df, wave_col = "wave", outcome_col = "offered")
  )

  expect_s3_class(res, "data.frame")
  expect_true("p_vs_ref" %in% names(res))
  # Wave 2 vs Wave 1 should be significantly different (p < 0.05)
  p_wave2 <- res$p_vs_ref[res$wave == 2L]
  expect_lt(p_wave2, 0.05)
})

test_that("compare_waves finds no significant wave difference when rates are equal", {
  set.seed(202)
  df <- data.frame(
    wave    = rep(c(1L, 2L), each = 60L),
    offered = rbinom(120L, 1L, 0.55)   # same rate both waves
  )

  res <- suppressWarnings(
    mysterycall_compare_waves(df, wave_col = "wave", outcome_col = "offered")
  )

  p_wave2 <- res$p_vs_ref[res$wave == 2L]
  # Should NOT be significant — no real wave effect
  expect_true(is.na(p_wave2) || p_wave2 > 0.05)
})

test_that("compare_waves stratified by insurance exposes confounded wave x insurance design", {
  # The dangerous scenario: Medicaid calls concentrated in Wave 1 (higher
  # acceptance); BCBS calls concentrated in Wave 2 (lower acceptance).
  # Overall Medicaid > BCBS looks like an insurance effect but is really a
  # wave effect. compare_waves() with group_col = "insurance" makes this
  # visible by showing BOTH groups decline from Wave 1 to Wave 2.
  set.seed(203)
  df <- data.frame(
    wave      = c(rep(1L, 80L), rep(2L, 80L)),
    insurance = c(rep("Medicaid", 60L), rep("BCBS", 20L),   # imbalanced in Wave 1
                  rep("Medicaid", 20L), rep("BCBS", 60L)),  # imbalanced in Wave 2
    offered   = c(
      rbinom(60L, 1L, 0.70),  # Medicaid Wave 1 — high acceptance
      rbinom(20L, 1L, 0.70),  # BCBS Wave 1 — same high acceptance
      rbinom(20L, 1L, 0.30),  # Medicaid Wave 2 — low acceptance
      rbinom(60L, 1L, 0.30)   # BCBS Wave 2 — same low acceptance
    )
  )

  res <- suppressWarnings(
    mysterycall_compare_waves(df, wave_col = "wave", outcome_col = "offered",
                              group_col = "insurance")
  )

  expect_s3_class(res, "data.frame")
  expect_true("group" %in% names(res))

  # Both insurance groups should show Wave 2 < Wave 1 (wave effect, not insurance)
  med_wave2 <- res$rate[res$group == "Medicaid" & res$wave == 2L]
  med_wave1 <- res$rate[res$group == "Medicaid" & res$wave == 1L]
  bbs_wave2 <- res$rate[res$group == "BCBS"     & res$wave == 2L]
  bbs_wave1 <- res$rate[res$group == "BCBS"     & res$wave == 1L]

  expect_lt(med_wave2, med_wave1)  # Medicaid drops wave 1→2
  expect_lt(bbs_wave2, bbs_wave1)  # BCBS drops wave 1→2
  # This pattern is the signature of a wave effect, not an insurance effect
})

test_that("compare_waves returns correct structure for continuous outcome", {
  set.seed(204)
  df <- data.frame(
    wave     = rep(c("pre", "post"), each = 50L),
    wait_days = c(rpois(50L, 14L), rpois(50L, 7L))
  )

  res <- suppressWarnings(
    mysterycall_compare_waves(df, wave_col = "wave", outcome_col = "wait_days",
                              type = "continuous")
  )

  expect_true(all(c("mean", "median", "sd", "p_vs_ref") %in% names(res)))
  # post wave should have lower mean wait (ref = "post" alphabetically comes first,
  # so "pre" is tested against "post")
  expect_equal(nrow(res), 2L)
})

test_that("compare_waves errors when fewer than 2 waves present", {
  df <- data.frame(wave = rep(1L, 10L), offered = rbinom(10L, 1L, 0.5))
  expect_error(
    mysterycall_compare_waves(df, "wave", "offered"),
    "At least 2 unique waves"
  )
})

test_that("compare_waves errors on missing wave_col", {
  df <- data.frame(wave = c(1L, 2L), offered = c(1L, 0L))
  expect_error(
    mysterycall_compare_waves(df, "nonexistent_col", "offered"),
    "not found"
  )
})
