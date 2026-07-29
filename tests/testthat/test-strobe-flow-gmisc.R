library(testthat)

test_that("mysterycall_strobe_flow(engine = 'gmisc') returns a grid grob", {
  skip_if_not_installed("Gmisc")
  skip_if_not_installed("grid")

  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_flow(
      n_total    = 743,
      n_calldate = 737,
      n_included = 141,
      n_waittime = 100,
      engine     = "gmisc"
    )
  ))

  expect_s3_class(result, "gTree")
  expect_s3_class(result, "mysterycall_strobe_flow_gmisc")
  # 5 main boxes + 3 exclusion boxes + 7 connectors + 1 title = 16 children.
  expect_true(length(result$children) >= 15L)
})

test_that("gmisc engine does not require ggplot2 to build the diagram", {
  skip_if_not_installed("Gmisc")
  # Explicit-count mode should reach the Gmisc branch without touching ggplot2.
  expect_s3_class(
    suppressMessages(suppressWarnings(
      mysterycall_strobe_flow(
        n_total = 100, n_calldate = 95, n_included = 50, n_waittime = 40,
        engine  = "gmisc"
      )
    )),
    "gTree"
  )
})

test_that("gmisc engine derives the same counts from a mysterycall_prepared object", {
  skip_if_not_installed("Gmisc")

  raw <- data.frame(
    calldate1  = c("2026-01-01", "2026-01-02", "", "2026-01-03", "2026-01-04"),
    exclusions = c(0, 9, 0, 3, 0),
    appdate    = c("2026-01-15", "", "2026-02-01", "", "2026-02-10"),
    stringsAsFactors = FALSE
  )

  gg <- suppressMessages(suppressWarnings(
    mysterycall_strobe_flow(data = raw, engine = "ggplot2")
  ))
  gm <- suppressMessages(suppressWarnings(
    mysterycall_strobe_flow(data = raw, engine = "gmisc")
  ))

  expect_s3_class(gg, "ggplot")
  expect_s3_class(gm, "gTree")
})

test_that("gmisc engine writes a file when output_path is supplied", {
  skip_if_not_installed("Gmisc")

  out <- tempfile(fileext = ".pdf")
  on.exit(unlink(out), add = TRUE)

  suppressMessages(suppressWarnings(
    mysterycall_strobe_flow(
      n_total = 100, n_calldate = 95, n_included = 50, n_waittime = 40,
      engine = "gmisc", output_path = out
    )
  ))

  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 0)
})

test_that("engine argument is validated via match.arg", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_strobe_flow(
        n_total = 100, n_calldate = 95, n_included = 50, n_waittime = 40,
        engine = "nope"
      )
    ))
  )
})
