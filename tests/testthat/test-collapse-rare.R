# ── mysterycall:::mysterycall_collapse_rare ─────────────────────────────────────────────────

test_that("collapse_rare: replaces rare levels with Other", {
  x   <- c(rep("Oto", 80), rep("Urology", 30), rep("Derm", 5))
  res <- mysterycall:::mysterycall_collapse_rare(x, threshold = 10)
  expect_false("Derm" %in% res)
  expect_true("Other" %in% res)
  expect_true("Oto" %in% res)
})

test_that("collapse_rare: levels at threshold are kept", {
  x   <- c(rep("A", 10), rep("B", 9))
  res <- mysterycall:::mysterycall_collapse_rare(x, threshold = 10)
  expect_true("A" %in% res)
  expect_false("B" %in% res)
})

test_that("collapse_rare: returns character when given character", {
  x   <- c(rep("A", 60), rep("B", 5))
  res <- mysterycall:::mysterycall_collapse_rare(x, threshold = 10)
  expect_type(res, "character")
})

test_that("collapse_rare: returns factor when given factor", {
  x   <- factor(c(rep("A", 60), rep("B", 5)))
  res <- mysterycall:::mysterycall_collapse_rare(x, threshold = 10)
  expect_s3_class(res, "factor")
})

test_that("collapse_rare: factor levels updated correctly", {
  x   <- factor(c(rep("A", 60), rep("B", 5), rep("C", 40)))
  res <- mysterycall:::mysterycall_collapse_rare(x, threshold = 10)
  expect_true("Other" %in% levels(res))
  expect_false("B" %in% levels(res))
})

test_that("collapse_rare: custom other_label", {
  x   <- c(rep("A", 60), rep("B", 3))
  res <- mysterycall:::mysterycall_collapse_rare(x, threshold = 10, other_label = "Rare")
  expect_true("Rare" %in% res)
  expect_false("Other" %in% res)
})

test_that("collapse_rare: all levels rare → all become Other", {
  x   <- c("A", "B", "C")
  res <- mysterycall:::mysterycall_collapse_rare(x, threshold = 5)
  expect_true(all(res == "Other"))
})

test_that("collapse_rare: no rare levels → unchanged values", {
  x   <- c(rep("A", 60), rep("B", 60))
  res <- mysterycall:::mysterycall_collapse_rare(x, threshold = 10)
  expect_equal(sort(unique(res)), c("A", "B"))
})

test_that("collapse_rare: non-character/factor input errors", {
  expect_error(mysterycall:::mysterycall_collapse_rare(1:10), "character or factor")
})

test_that("collapse_rare: invalid threshold errors", {
  expect_error(mysterycall:::mysterycall_collapse_rare(c("a", "b"), threshold = 0), "positive")
})

test_that("collapse_rare: preserves length", {
  x   <- c(rep("A", 60), rep("B", 5))
  res <- mysterycall:::mysterycall_collapse_rare(x, threshold = 10)
  expect_length(res, length(x))
})

# Regression (BUG 24): no phantom empty "Other" level when nothing collapses.
test_that("collapse_rare: does not add an empty Other level when nothing is collapsed", {
  x   <- factor(c(rep("A", 10), rep("B", 20)))
  res <- mysterycall:::mysterycall_collapse_rare(x, threshold = 5)
  expect_s3_class(res, "factor")
  expect_false("Other" %in% levels(res))
  expect_equal(sort(levels(res)), c("A", "B"))
})

test_that("collapse_rare: adds Other level only when a level is collapsed", {
  x   <- factor(c(rep("A", 10), rep("B", 20), rep("C", 2)))
  res <- mysterycall:::mysterycall_collapse_rare(x, threshold = 5)
  expect_true("Other" %in% levels(res))
  expect_false("C" %in% levels(res))
})
