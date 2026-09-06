# The point of mysterycall_flow_spec() is that it REFUSES. A renderer draws
# what it is handed, so these tests are mostly about what it will not accept.
# The rendered-label tests follow the technique in test-strobe-logistic-n.R:
# checking the drawn text, not just the computed value, because a diagram can
# compute nine counts correctly and put the wrong one in a box.

AAGL <- function(...) {
  a <- list(
    spine = c("Abstracts parsed" = 1154, "Oral cohort" = 1106, "Evaluated" = 1051),
    exclusions = list("Abstracts parsed" = c("Video presentations" = 48),
                      "Oral cohort" = c("Adjudication unresolved" = 55)),
    splits = list("Evaluated" = c("Published" = 170, "Not published" = 881),
                  "Not published" = c("No qualifying publication" = 839,
                                      "Predates the congress" = 42)))
  do.call(mysterycall_flow_spec, utils::modifyList(a, list(...)))
}

test_that("a flow that closes is accepted and reports that it closes", {
  s <- AAGL()
  expect_s3_class(s, "mysterycall_flow_spec")
  expect_true(s$closed)
  expect_equal(unname(s$spine[["Evaluated"]]), 1051)
})

test_that("a spine step that does not close is refused, and the step is named", {
  expect_error(
    mysterycall_flow_spec(spine = c("Screened" = 100, "Analysed" = 90),
                          exclusions = list("Screened" = c("Ineligible" = 5))),
    "Screened")
  expect_error(
    mysterycall_flow_spec(spine = c("Screened" = 100, "Analysed" = 90),
                          exclusions = list("Screened" = c("Ineligible" = 5))),
    "does not close")
})

test_that("an off-by-one in the middle of a long spine is caught", {
  # The case a reader cannot see: three steps close, the fourth is one out.
  expect_error(
    mysterycall_flow_spec(
      spine = c("A" = 100, "B" = 90, "C" = 80, "D" = 69),
      exclusions = list("A" = c("x" = 10), "B" = c("y" = 10), "C" = c("z" = 10))),
    "C")
})

test_that("multiple exclusion reasons on one step are summed, not taken singly", {
  expect_s3_class(
    mysterycall_flow_spec(spine = c("Screened" = 100, "Enrolled" = 80),
                          exclusions = list("Screened" = c("Ineligible" = 15,
                                                           "Declined" = 5))),
    "mysterycall_flow_spec")
  expect_error(
    mysterycall_flow_spec(spine = c("Screened" = 100, "Enrolled" = 85),
                          exclusions = list("Screened" = c("Ineligible" = 15,
                                                           "Declined" = 5))),
    "does not close")
})

test_that("a split whose parts do not sum to its parent is refused", {
  expect_error(AAGL(splits = list("Evaluated" = c("Published" = 170,
                                                  "Not published" = 880))),
               "does not close")
})

test_that("a nested split is checked against its own parent, not the spine", {
  expect_error(AAGL(splits = list(
    "Evaluated" = c("Published" = 170, "Not published" = 881),
    "Not published" = c("No qualifying publication" = 839,
                        "Predates the congress" = 41))),
    "Not published")
})

test_that("negative, fractional, NA and duplicated counts are all refused", {
  expect_error(mysterycall_flow_spec(c("A" = 10, "B" = -1)), "negative")
  expect_error(mysterycall_flow_spec(c("A" = 10, "B" = 9.5)), "fractional")
  expect_error(mysterycall_flow_spec(c("A" = 10, "B" = NA_real_)), "NA")
  expect_error(mysterycall_flow_spec(stats::setNames(c(10, 10), c("A", "A"))),
               "duplicate")
})

test_that("unnamed input and a one-step spine are refused", {
  expect_error(mysterycall_flow_spec(c(10, 8)), "NAMED")
  expect_error(mysterycall_flow_spec(c("only" = 10)), "at least two")
})

test_that("an exclusion or split naming an unknown box is refused", {
  expect_error(AAGL(exclusions = list("Nowhere" = c("x" = 1))), "not on the spine")
  expect_error(AAGL(splits = list("Nowhere" = c("x" = 1))), "neither a spine step")
})

test_that("assert = FALSE permits a partial diagram but records that", {
  s <- mysterycall_flow_spec(spine = c("Screened" = 100, "Analysed" = 90),
                             exclusions = list("Screened" = c("Ineligible" = 5)),
                             assert = FALSE)
  expect_true(is.na(s$closed))
})

test_that("print() shows the chain and marks whether it closes", {
  out <- paste(utils::capture.output(print(AAGL())), collapse = "\n")
  expect_match(out, "arithmetic closes")
  expect_match(out, "n = 1,051", fixed = TRUE)
  expect_match(out, "Not published", fixed = TRUE)
})
