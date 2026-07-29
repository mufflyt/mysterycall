library(testthat)

# annotate() stores its label as a column in the layer's data frame.
.infographic_labels <- function(p) {
  out <- character(0)
  for (l in p$layers) {
    d <- l$data
    if (is.data.frame(d) && "label" %in% names(d))
      out <- c(out, as.character(d$label))
  }
  out
}

test_that("returns a ggplot with the four ABOG panels by default", {
  skip_if_not_installed("ggplot2")
  p <- suppressWarnings(mysterycall_subspecialist_infographic(
    start = c(1.20, 0.95, 0.80, 0.40),
    end   = c(1.35, 1.02, 0.88, 0.61)
  ))
  expect_s3_class(p, "ggplot")
})

test_that("percent change is derived from the values, not typed", {
  skip_if_not_installed("ggplot2")
  # +12.5% from 0.80 -> 0.90; -20.0% from 1.00 -> 0.80
  p <- suppressWarnings(mysterycall_subspecialist_infographic(
    subspecialty = c("A", "B"),
    start        = c(0.80, 1.00),
    end          = c(0.90, 0.80)
  ))
  labels <- .infographic_labels(p)
  expect_true(any(grepl("+12.5%", labels, fixed = TRUE)))
  expect_true(any(grepl("-20.0%", labels, fixed = TRUE)))
})

test_that("accepts a data frame and honours custom column names", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(
    ss  = c("Gynecologic Oncology", "Urogynecology"),
    y18 = c(1.2, 0.4),
    y23 = c(1.35, 0.61)
  )
  p <- suppressWarnings(mysterycall_subspecialist_infographic(
    data = df, subspecialty_col = "ss", start_col = "y18", end_col = "y23"
  ))
  expect_s3_class(p, "ggplot")
})

test_that("zero baseline yields an n/a percent change rather than Inf", {
  skip_if_not_installed("ggplot2")
  p <- suppressWarnings(mysterycall_subspecialist_infographic(
    subspecialty = "New subspecialty",
    start        = 0,
    end          = 0.5
  ))
  labels <- .infographic_labels(p)
  expect_true(any(grepl("n/a", labels, fixed = TRUE)))
})

test_that("input validation is enforced", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_subspecialist_infographic(start = 1),                 # end missing
    "Supply `start` and `end`"
  )
  expect_error(
    mysterycall_subspecialist_infographic(
      subspecialty = c("A", "B"), start = c(1, 2), end = 3),          # length mismatch
    "same length"
  )
  expect_error(
    mysterycall_subspecialist_infographic(
      subspecialty = "A", start = -1, end = 2),                       # negative
    "non-negative"
  )
})

test_that(".abbrev_subspecialty maps known names and falls back to initials", {
  expect_equal(mysterycall:::.abbrev_subspecialty("Maternal-Fetal Medicine"), "MFM")
  expect_equal(
    mysterycall:::.abbrev_subspecialty("Reproductive Endocrinology & Infertility"),
    "REI"
  )
  expect_equal(mysterycall:::.abbrev_subspecialty("Complex Family Planning"), "CFP")
  # unknown -> initials of words, capped at 4 letters
  expect_equal(mysterycall:::.abbrev_subspecialty("Alpha Beta Gamma"), "ABG")
})

test_that("writes a file when output_path is supplied", {
  skip_if_not_installed("ggplot2")
  out <- tempfile(fileext = ".png")
  on.exit(unlink(out), add = TRUE)
  suppressMessages(suppressWarnings(mysterycall_subspecialist_infographic(
    start = c(1.20, 0.95, 0.80, 0.40),
    end   = c(1.35, 1.02, 0.88, 0.61),
    output_path = out
  )))
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 0)
})
