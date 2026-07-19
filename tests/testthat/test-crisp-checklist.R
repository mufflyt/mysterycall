# Tests for mysterycall_crisp_checklist()

test_that("returns a structured checklist with the expected columns", {
  cl <- mysterycall_crisp_checklist()
  expect_s3_class(cl, "mysterycall_crisp_checklist")
  expect_setequal(names(cl), c("section", "item", "recommendation", "reported"))
  expect_gt(nrow(cl), 10L)
  expect_true(all(is.na(cl$reported)))
})

test_that("covers the covert-methodology domains STROBE omits", {
  cl <- mysterycall_crisp_checklist()
  secs <- unique(cl$section)
  expect_true(all(c("Callers", "Detection", "Ethics") %in% secs))
  # something about caller training and detection specifically
  expect_true(any(grepl("training", cl$item, ignore.case = TRUE)))
  expect_true(any(grepl("[Dd]etection", cl$item)))
})

test_that("reported can be pre-filled and must match the item count", {
  n <- nrow(mysterycall_crisp_checklist())
  filled <- mysterycall_crisp_checklist(reported = rep("p.7", n))
  expect_true(all(filled$reported == "p.7"))
  expect_error(mysterycall_crisp_checklist(reported = c("p.1", "p.2")),
               "one per checklist item")
})

test_that("as.data.frame returns a plain data frame", {
  df <- as.data.frame(mysterycall_crisp_checklist())
  expect_s3_class(df, "data.frame")
  expect_false(inherits(df, "mysterycall_crisp_checklist"))
})
