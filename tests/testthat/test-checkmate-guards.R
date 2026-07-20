# Input-validation guards added across several exported helpers.
# Each test drives the checkmate assertion, confirming bad input is rejected
# up front rather than failing deep inside the computation.

test_that("mysterycall_format_pct guards x and digits", {
  expect_error(mysterycall_format_pct("not numeric"))
  expect_error(mysterycall_format_pct(0.5, digits = -1))   # negative count
  expect_error(mysterycall_format_pct(0.5, digits = 1.5))  # non-integer
  expect_equal(mysterycall_format_pct(0.5, digits = 0), "50%")  # 0 is valid
})

test_that("mysterycall_max_table / min_table require a logical scalar mult", {
  expect_error(mysterycall_max_table(c("a", "a", "b"), mult = "yes"))
  expect_error(mysterycall_max_table(c("a", "a", "b"), mult = NA))
  expect_error(mysterycall_min_table(c("a", "a", "b"), mult = c(TRUE, FALSE)))
  expect_equal(mysterycall_max_table(c("a", "a", "b")), "a")  # still works
})

test_that("mysterycall_remove_constants requires a data frame", {
  expect_error(mysterycall_remove_constants(1:10))
  expect_error(mysterycall_remove_constants(list(a = 1)))
})

test_that("mysterycall_table_percentages guards data frame and column name", {
  d <- data.frame(g = c("a", "a", "b"), stringsAsFactors = FALSE)
  expect_error(mysterycall_table_percentages(1:3, "g"))          # not a df
  expect_error(mysterycall_table_percentages(d, "no_such_col"))  # missing col
})

test_that("mysterycall_table_proportion requires a data frame", {
  expect_error(mysterycall_table_proportion("nope", x))
})

test_that("mysterycall_not_contacted_states guards inputs", {
  d <- data.frame(state = c("Colorado", "Texas"), stringsAsFactors = FALSE)
  expect_error(mysterycall_not_contacted_states("not a df"))
  expect_error(mysterycall_not_contacted_states(d, all_states = 1:3))  # not char
})

test_that("mysterycall_parse_certification_subspecialty guards default", {
  expect_error(mysterycall_parse_certification_subspecialty("x", default = 1))
  expect_error(
    mysterycall_parse_certification_subspecialty("x", default = c("a", "b")))
})

test_that("mysterycall_assess_data_quality guards data and required_columns", {
  expect_error(mysterycall_assess_data_quality("not a df"))
  expect_error(mysterycall_assess_data_quality(data.frame(first = 1),
                                               required_columns = 1:2))
})

test_that("mysterycall_estimate_resources requires a single non-negative count", {
  expect_error(mysterycall_estimate_resources(-1))
  expect_error(mysterycall_estimate_resources(1.5))
  expect_error(mysterycall_estimate_resources(c(1, 2)))
})

test_that("mysterycall_bootstrap_predictor_stability guards its arguments", {
  d <- data.frame(y = rbinom(30, 1, 0.5), x = rnorm(30))
  expect_error(  # not a data frame
    mysterycall_bootstrap_predictor_stability("nope", "y", "x"))
  expect_error(  # predictor column absent
    mysterycall_bootstrap_predictor_stability(d, "y", "not_a_col"))
  expect_error(  # n_boot must be a positive count
    mysterycall_bootstrap_predictor_stability(d, "y", "x", n_boot = 0))
  expect_error(  # p_threshold out of [0, 1]
    mysterycall_bootstrap_predictor_stability(d, "y", "x", p_threshold = 1.5))
  expect_error(  # unsupported family
    mysterycall_bootstrap_predictor_stability(d, "y", "x", family = "gaussian"))
})
