# Tests for mysterycall_gee

gee_df <- function() {
  set.seed(42)
  data.frame(
    practice = rep(1:40, each = 2),
    scenario = rep(c("Straight couple", "Lesbian couple"), 40),
    accepted = rbinom(80, 1, rep(c(0.85, 0.55), 40)),
    stringsAsFactors = FALSE
  )
}

test_that("gee returns the documented structure", {
  skip_if_not_installed("geepack")
  res <- mysterycall_gee(gee_df(), "accepted", "scenario", "practice",
                         reference = c(scenario = "Straight couple"))
  expect_s3_class(res, "mysterycall_gee")
  expect_named(res, c("model", "or_table", "corstr", "n", "n_clusters",
                      "separated"))
  expect_s3_class(res$model, "geeglm")
  expect_equal(res$n, 80L)
  expect_equal(res$n_clusters, 40L)
  expect_true(all(c("term", "estimate", "se", "or", "ci_lower", "ci_upper") %in%
                    names(res$or_table)))
})

test_that("OR equals exp(estimate) and CI brackets it", {
  skip_if_not_installed("geepack")
  res <- mysterycall_gee(gee_df(), "accepted", "scenario", "practice")
  expect_equal(res$or_table$or, exp(res$or_table$estimate), tolerance = 1e-8)
  expect_true(all(res$or_table$ci_lower <= res$or_table$or))
  expect_true(all(res$or_table$or <= res$or_table$ci_upper))
})

test_that("reference releveling controls the sign of the scenario effect", {
  skip_if_not_installed("geepack")
  # Lesbian couple has lower acceptance, so vs Straight (ref) the log-OR is < 0
  res <- mysterycall_gee(gee_df(), "accepted", "scenario", "practice",
                         reference = c(scenario = "Straight couple"))
  row <- res$or_table[grepl("Lesbian", res$or_table$term), ]
  expect_lt(row$estimate, 0)
})

test_that("positive_values maps non-logical outcomes", {
  skip_if_not_installed("geepack")
  d <- gee_df()
  d$accepted <- ifelse(d$accepted == 1, "Yes", "No")
  res <- mysterycall_gee(d, "accepted", "scenario", "practice",
                         positive_values = "Yes")
  expect_equal(res$n, 80L)
})

test_that("bad inputs error via checkmate", {
  expect_error(mysterycall_gee(gee_df(), "nope", "scenario", "practice"))
  expect_error(mysterycall_gee(gee_df(), "accepted", "scenario", "nope"))
})
