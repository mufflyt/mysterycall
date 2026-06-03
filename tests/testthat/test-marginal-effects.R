# Tests for mysterycall:::mysterycall_marginal_effects()
# Uses mtcars with a simple Poisson GLM to avoid lme4 dependency for most tests.

m_glm <- glm(vs ~ wt + factor(cyl), data = mtcars, family = poisson())

# -- 1. Returns a data.frame ---------------------------------------------------
test_that("marginal_effects: returns a data.frame", {
  result <- mysterycall:::mysterycall_marginal_effects(m_glm)
  expect_s3_class(result, "data.frame")
})

# -- 2. Has the required columns -----------------------------------------------
test_that("marginal_effects: has columns term, level, ame, variable_type", {
  result <- mysterycall:::mysterycall_marginal_effects(m_glm)
  expect_true(all(c("term", "level", "ame", "variable_type") %in% names(result)))
})

# -- 3. term = NULL returns a row per predictor (wt + two factor levels) -------
test_that("marginal_effects: term = NULL returns rows for all predictors", {
  result <- mysterycall:::mysterycall_marginal_effects(m_glm)
  # wt -> 1 row (continuous); cyl has 3 levels so 2 non-reference rows
  expect_gte(nrow(result), 3L)
  expect_true("wt"  %in% result$term)
  expect_true("cyl" %in% result$term)
})

# -- 4. term = "wt" returns only the wt row ------------------------------------
test_that("marginal_effects: term = 'wt' returns a single row for wt", {
  result <- mysterycall:::mysterycall_marginal_effects(m_glm, term = "wt")
  expect_equal(nrow(result), 1L)
  expect_equal(result$term, "wt")
})

# -- 5. term = "cyl" returns multiple rows (one per non-reference level) -------
test_that("marginal_effects: term = 'cyl' returns multiple rows", {
  result <- mysterycall:::mysterycall_marginal_effects(m_glm, term = "cyl")
  # mtcars cyl has levels 4, 6, 8 -- reference is 4, so 2 non-ref rows
  expect_gte(nrow(result), 2L)
  expect_true(all(result$term == "cyl"))
})

# -- 6. AME for continuous predictor is numeric --------------------------------
test_that("marginal_effects: AME for continuous predictor is numeric", {
  result <- mysterycall:::mysterycall_marginal_effects(m_glm, term = "wt")
  expect_true(is.numeric(result$ame))
  expect_false(is.na(result$ame))
})

# -- 7. AME for factor predictor is numeric ------------------------------------
test_that("marginal_effects: AME for factor predictor is numeric", {
  result <- mysterycall:::mysterycall_marginal_effects(m_glm, term = "cyl")
  expect_true(is.numeric(result$ame))
  expect_false(any(is.na(result$ame)))
})

# -- 8. Accepts mysterycall_poisson_model input --------------------------------
test_that("marginal_effects: accepts mysterycall_poisson_model input", {
  skip_if_not_installed("lme4")
  set.seed(42)
  df <- data.frame(
    y   = rpois(40L, 5L),
    x   = rnorm(40L),
    grp = rep(paste0("g", 1:8), each = 5L),
    stringsAsFactors = FALSE
  )
  pm <- suppressWarnings(
    mysterycall_poisson_model(df, "y", "x", "grp")
  )
  result <- mysterycall:::mysterycall_marginal_effects(pm, term = "x")
  expect_s3_class(result, "data.frame")
  expect_true("ame" %in% names(result))
})

# -- 9. Errors on non-model input ----------------------------------------------
test_that("marginal_effects: errors on non-model input", {
  expect_error(
    mysterycall:::mysterycall_marginal_effects(list(a = 1, b = 2)),
    "glm|glmerMod|mysterycall_poisson_model"
  )
  expect_error(
    mysterycall:::mysterycall_marginal_effects("not a model"),
    "glm|glmerMod|mysterycall_poisson_model"
  )
  expect_error(
    mysterycall:::mysterycall_marginal_effects(42L),
    "glm|glmerMod|mysterycall_poisson_model"
  )
})

# -- 10. variable_type is "continuous" or "categorical" ------------------------
test_that("marginal_effects: variable_type is 'continuous' or 'categorical'", {
  result <- mysterycall:::mysterycall_marginal_effects(m_glm)
  valid  <- c("continuous", "categorical")
  expect_true(all(result$variable_type %in% valid))
  # wt should be continuous; cyl should be categorical
  expect_equal(
    unique(result$variable_type[result$term == "wt"]),
    "continuous"
  )
  expect_equal(
    unique(result$variable_type[result$term == "cyl"]),
    "categorical"
  )
})

# -- 11. Errors on invalid term ------------------------------------------------
test_that("marginal_effects: errors when term is not in the model", {
  expect_error(
    mysterycall:::mysterycall_marginal_effects(m_glm, term = "no_such_var"),
    "not found"
  )
})

# -- 12. Errors when eps is non-positive ----------------------------------------
test_that("marginal_effects: errors when eps is <= 0", {
  expect_error(
    mysterycall:::mysterycall_marginal_effects(m_glm, term = "wt", eps = 0),
    "eps"
  )
  expect_error(
    mysterycall:::mysterycall_marginal_effects(m_glm, term = "wt", eps = -1),
    "eps"
  )
})
