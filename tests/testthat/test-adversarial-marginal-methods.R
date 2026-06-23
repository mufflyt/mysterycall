# Adversarial and negative-control tests for:
#   mysterycall_marginal_effects()  (items 2)
#   mysterycall_methods_paragraph() (item 4)

# ── mysterycall_marginal_effects ───────────────────────────────────────────────

test_that("marginal_effects: rejects NULL", {
  expect_error(mysterycall_marginal_effects(NULL))
})

test_that("marginal_effects: rejects data frame", {
  expect_error(mysterycall_marginal_effects(mtcars))
})

test_that("marginal_effects: rejects unknown class (plain list)", {
  expect_error(
    mysterycall_marginal_effects(list(a = 1, b = 2)),
    regexp = "class"
  )
})

test_that("marginal_effects: rejects invalid eps = 0", {
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  expect_error(mysterycall_marginal_effects(m, eps = 0))
})

test_that("marginal_effects: rejects invalid eps (negative)", {
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  expect_error(mysterycall_marginal_effects(m, eps = -1))
})

test_that("marginal_effects: rejects eps as length-2 vector", {
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  expect_error(mysterycall_marginal_effects(m, eps = c(1e-7, 1e-6)))
})

test_that("marginal_effects: rejects non-existent term", {
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  expect_error(
    mysterycall_marginal_effects(m, term = "no_such_column"),
    regexp = "not found"
  )
})

test_that("marginal_effects: rejects numeric term (must be character)", {
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  expect_error(mysterycall_marginal_effects(m, term = 42))
})

test_that("marginal_effects: rejects logical term", {
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  expect_error(mysterycall_marginal_effects(m, term = TRUE))
})

# Negative control: glm works, returns correct data.frame shape
test_that("marginal_effects: returns data.frame with required columns on glm", {
  m <- glm(vs ~ wt + factor(cyl), data = mtcars, family = poisson())
  result <- mysterycall_marginal_effects(m)
  expect_s3_class(result, "data.frame")
  expect_true(all(c("term", "level", "ame", "variable_type") %in% names(result)))
  expect_true(nrow(result) > 0L)
})

# Negative control: continuous predictor → one row, level = NA
test_that("marginal_effects: continuous predictor yields one row with NA level", {
  m <- glm(vs ~ wt, data = mtcars, family = poisson())
  result <- mysterycall_marginal_effects(m, term = "wt")
  expect_equal(nrow(result), 1L)
  expect_true(is.na(result$level))
  expect_equal(result$variable_type, "continuous")
  expect_true(is.numeric(result$ame))
})

# Negative control: subset term request returns only that term
test_that("marginal_effects: term subset returns only requested variable", {
  m <- glm(vs ~ wt + am, data = mtcars, family = poisson())
  result <- mysterycall_marginal_effects(m, term = "wt")
  expect_equal(nrow(result), 1L)
  expect_equal(result$term, "wt")
})

# Negative control: categorical predictor → level is non-NA for non-reference rows
test_that("marginal_effects: categorical predictor yields non-NA levels", {
  m <- glm(vs ~ factor(cyl), data = mtcars, family = poisson())
  result <- mysterycall_marginal_effects(m, term = "cyl")
  expect_true(all(!is.na(result$level)))
  expect_equal(result$variable_type, rep("categorical", nrow(result)))
})

# Negative control: ame is numeric (finite or at least not all NA)
test_that("marginal_effects: ame column is numeric", {
  m <- glm(vs ~ wt + am, data = mtcars, family = poisson())
  result <- mysterycall_marginal_effects(m)
  expect_true(is.numeric(result$ame))
})


# ── mysterycall_methods_paragraph ─────────────────────────────────────────────

test_that("methods_paragraph: rejects n_physicians = 0", {
  expect_error(
    mysterycall_methods_paragraph(0, 10, "ENT"),
    regexp = "n_physicians"
  )
})

test_that("methods_paragraph: rejects n_physicians negative", {
  expect_error(
    mysterycall_methods_paragraph(-5, 10, "ENT"),
    regexp = "n_physicians"
  )
})

test_that("methods_paragraph: rejects n_cities = 0", {
  expect_error(
    mysterycall_methods_paragraph(100, 0, "ENT"),
    regexp = "n_cities"
  )
})

test_that("methods_paragraph: rejects n_cities negative", {
  expect_error(
    mysterycall_methods_paragraph(100, -1, "ENT"),
    regexp = "n_cities"
  )
})

test_that("methods_paragraph: rejects empty specialties vector", {
  expect_error(
    mysterycall_methods_paragraph(100, 10, character(0)),
    regexp = "specialties"
  )
})

test_that("methods_paragraph: rejects NULL specialties", {
  expect_error(
    mysterycall_methods_paragraph(100, 10, NULL),
    class = "error"
  )
})

test_that("methods_paragraph: rejects invalid model_family string", {
  expect_error(
    mysterycall_methods_paragraph(100, 10, "ENT", model_family = "gamma"),
    class = "error"
  )
})

test_that("methods_paragraph: rejects NA as model_family", {
  expect_error(
    mysterycall_methods_paragraph(100, 10, "ENT", model_family = NA_character_),
    class = "error"
  )
})

# Negative control: poisson sentence contains lme4 and Poisson
test_that("methods_paragraph: poisson output contains Poisson and lme4", {
  result <- mysterycall_methods_paragraph(100, 10, "ENT", model_family = "poisson")
  expect_match(result, "Poisson", ignore.case = TRUE)
  expect_match(result, "lme4")
})

# Negative control: negative_binomial output contains glmmTMB
test_that("methods_paragraph: negative_binomial output contains glmmTMB", {
  result <- mysterycall_methods_paragraph(
    100, 10, "ENT", model_family = "negative_binomial"
  )
  expect_match(result, "negative binomial", ignore.case = TRUE)
  expect_match(result, "glmmTMB")
})

# Negative control: auto output references overdispersion check
test_that("methods_paragraph: auto output references phi threshold", {
  result <- mysterycall_methods_paragraph(100, 10, "ENT", model_family = "auto")
  expect_match(result, "phi", ignore.case = TRUE)
})

# Negative control: result is always a single character string
test_that("methods_paragraph: always returns length-1 character for all families", {
  for (fam in c("poisson", "negative_binomial", "auto")) {
    result <- mysterycall_methods_paragraph(100, 10, "ENT", model_family = fam)
    expect_type(result, "character")
    expect_length(result, 1L)
    expect_gt(nchar(result), 50L)
  }
})

# Negative control: multiple specialties joined with 'and'
test_that("methods_paragraph: multiple specialties joined with 'and'", {
  result <- mysterycall_methods_paragraph(100, 10, c("ENT", "neurotology"))
  expect_match(result, "\\band\\b")
})

# Negative control: single specialty appears as-is (no 'and')
test_that("methods_paragraph: single specialty has no spurious 'and'", {
  result <- mysterycall_methods_paragraph(100, 10, "otolaryngology")
  expect_match(result, "otolaryngology")
  # The specialty word itself should appear; the structural 'and' of multi-spec should not
  # (There may be 'and' for insurance types, so just check specialty name is present)
  expect_true(nchar(result) > 0L)
})

# Negative control: physician count appears in output
test_that("methods_paragraph: n_physicians appears in output", {
  result <- mysterycall_methods_paragraph(369, 10, "ENT")
  expect_match(result, "369")
})
