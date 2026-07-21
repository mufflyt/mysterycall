# Tests for mysterycall_scenario_coverage

cov_df <- function() {
  data.frame(
    practice = c(1, 1, 1, 2, 2, 3),
    scenario = c("Straight", "Lesbian", "Single mother",
                 "Straight", "Lesbian", "Straight"),
    stringsAsFactors = FALSE
  )
}

test_that("coverage counts triads, dyads, singletons correctly", {
  res <- mysterycall_scenario_coverage(cov_df(), "practice", "scenario")
  expect_s3_class(res, "mysterycall_scenario_coverage")
  expect_equal(res$summary$n_clusters, 3L)
  expect_equal(res$summary$n_complete, 1L)   # practice 1
  expect_equal(res$summary$n_partial, 1L)    # practice 2
  expect_equal(res$summary$n_singleton, 1L)  # practice 3
})

test_that("missing-by-scenario counts are right", {
  res <- mysterycall_scenario_coverage(cov_df(), "practice", "scenario")
  # Straight: all 3 have it -> 0 missing; Lesbian: p3 missing -> 1;
  # Single mother: p2,p3 missing -> 2
  expect_equal(res$summary$n_missing_Straight, 0L)
  expect_equal(res$summary$n_missing_Lesbian, 1L)
  expect_equal(res$summary$`n_missing_Single mother`, 2L)
})

test_that("per-cluster table has one row per cluster and n_scenarios", {
  res <- mysterycall_scenario_coverage(cov_df(), "practice", "scenario")
  expect_equal(nrow(res$coverage), 3L)
  expect_equal(res$coverage$n_scenarios[res$coverage$id == 1], 3L)
  expect_equal(res$coverage$n_scenarios[res$coverage$id == 3], 1L)
  expect_s3_class(as.data.frame(res), "data.frame")
})

test_that("explicit `scenarios` reports levels absent from data as fully missing", {
  res <- mysterycall_scenario_coverage(
    cov_df(), "practice", "scenario",
    scenarios = c("Straight", "Lesbian", "Single mother", "Divorced")
  )
  expect_equal(res$summary$n_missing_Divorced, 3L)
  expect_equal(res$summary$n_complete, 0L)  # nobody has all four
})

test_that("bad column names error via checkmate", {
  expect_error(mysterycall_scenario_coverage(cov_df(), "nope", "scenario"))
  expect_error(mysterycall_scenario_coverage(cov_df(), "practice", "nope"))
})
