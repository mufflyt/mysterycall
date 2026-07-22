library(testthat)

# strobe_flow()'s logistic box must equal nrow(prepared$logistic_data)
# ({0,7,9,10} reached), not the exclusion-code-0 count -- matching the
# prepare_calls() pipeline it is built from.

strobe_text <- function(p) {
  out <- character(0)
  for (L in p$layers) {
    lab <- L$aes_params[["label"]]
    if (is.null(lab)) lab <- tryCatch(L$data[["label"]], error = function(e) NULL)
    if (!is.null(lab)) out <- c(out, as.character(lab))
  }
  out
}

test_that("logistic box reflects {0,7,9,10}, not code-0 only", {
  skip_if_not_installed("ggplot2")

  raw <- data.frame(
    calldate1  = rep("2026-02-02", 5),
    contacted1 = rep(1, 5),
    contacted2 = rep(99, 5),
    # 3 code-0 with an appointment date, 2 code-9 (not accepting) with none
    appdate    = c("2026-02-05", "2026-02-06", "2026-02-09", "", ""),
    exclusions = c(0, 0, 0, 9, 9),
    initials   = c("a", "b", "c", "d", "e"),
    stringsAsFactors = FALSE
  )
  prepared <- suppressWarnings(suppressMessages(mysterycall_prepare_calls(raw)))

  # sanity: logistic set is 5 (0+9 reached), wait-time set is 3 (code 0 + appt)
  expect_equal(nrow(prepared$logistic_data), 5L)
  expect_equal(nrow(prepared$waittime_data), 3L)

  p <- suppressWarnings(suppressMessages(mysterycall_strobe_flow(prepared = prepared)))
  labs <- strobe_text(p)

  analytic <- labs[grepl("Analytic sample", labs)]
  logistic <- labs[grepl("Logistic analysis", labs)]
  waittime <- labs[grepl("Wait-time analysis", labs)]

  # logistic/analytic boxes = 5 (the {0,9} reached set), NOT 3 (code-0 only)
  expect_true(any(grepl("n = 5", analytic)))
  expect_true(any(grepl("n = 5", logistic)))
  expect_false(any(grepl("n = 3", logistic)))
  # wait-time box = 3
  expect_true(any(grepl("n = 3", waittime)))
})
