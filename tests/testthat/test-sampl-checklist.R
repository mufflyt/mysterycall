# Tests for mysterycall_sampl_checklist()

test_that("returns a structured checklist with the expected columns", {
  cl <- mysterycall_sampl_checklist()
  expect_s3_class(cl, "mysterycall_sampl_checklist")
  expect_setequal(names(cl), c("section", "item", "recommendation", "reported"))
  expect_gt(nrow(cl), 20L)
  expect_true(all(is.na(cl$reported)))
})

test_that("covers the number-reporting domains STROBE and CRiSP omit", {
  cl <- mysterycall_sampl_checklist()
  secs <- unique(cl$section)
  expect_true(all(c("General", "Hypothesis tests", "Regression") %in% secs))
  # the items the guideline is usually cited for
  expect_true(any(grepl("confidence interval", cl$recommendation, fixed = TRUE)))
  expect_true(any(grepl("exact values", cl$item, fixed = TRUE)))
  expect_true(any(grepl("[Dd]enominator", cl$item)))
  expect_true(any(grepl("'to' rather than a hyphen", cl$recommendation, fixed = TRUE)))
})

test_that("reported can be pre-filled and must match the item count", {
  n <- nrow(mysterycall_sampl_checklist())
  filled <- mysterycall_sampl_checklist(reported = rep("p.7", n))
  expect_true(all(filled$reported == "p.7"))
  expect_error(mysterycall_sampl_checklist(reported = c("p.1", "p.2")),
               "one per checklist item")
})

test_that("print returns its input invisibly and names the instrument", {
  cl <- mysterycall_sampl_checklist()
  expect_output(print(cl), "SAMPL statistical-reporting checklist: 27 items")
  expect_invisible(print(cl))
})

test_that("as.data.frame returns a plain data frame", {
  df <- as.data.frame(mysterycall_sampl_checklist())
  expect_s3_class(df, "data.frame")
  expect_false(inherits(df, "mysterycall_sampl_checklist"))
})
