# ── mysterycall_plot_inclexcl ─────────────────────────────────────────────────

test_that("plot_inclexcl: returns grViz object", {
  skip_if_not_installed("DiagrammeR")
  res <- mysterycall_plot_inclexcl(
    counts = c(Identified = 612, Screened = 470, Analyzed = 301)
  )
  expect_s3_class(res, "htmlwidget")
})

test_that("plot_inclexcl: exclusions accepted as named list", {
  skip_if_not_installed("DiagrammeR")
  res <- mysterycall_plot_inclexcl(
    counts     = c(Identified = 612, Screened = 470, Analyzed = 301),
    exclusions = list(Identified = "142 excluded: no phone")
  )
  expect_s3_class(res, "htmlwidget")
})

test_that("plot_inclexcl: subspecialty_breakdown accepted", {
  skip_if_not_installed("DiagrammeR")
  res <- mysterycall_plot_inclexcl(
    counts                 = c(Identified = 612, Analyzed = 301),
    subspecialty_breakdown = c(General = 150, Neurotology = 80, Pediatric = 71)
  )
  expect_s3_class(res, "htmlwidget")
})

test_that("plot_inclexcl: fewer than 2 phases errors", {
  skip_if_not_installed("DiagrammeR")
  expect_error(
    mysterycall_plot_inclexcl(counts = c(Only = 100)),
    "at least 2"
  )
})

test_that("plot_inclexcl: exclusion name not in counts errors", {
  skip_if_not_installed("DiagrammeR")
  expect_error(
    mysterycall_plot_inclexcl(
      counts     = c(A = 100, B = 50),
      exclusions = list(C = "bad name")
    ),
    "not found in"
  )
})

test_that("plot_inclexcl: title parameter accepted without error", {
  skip_if_not_installed("DiagrammeR")
  res <- mysterycall_plot_inclexcl(
    counts = c(Identified = 500, Analyzed = 300),
    title  = "Study Flow"
  )
  expect_s3_class(res, "htmlwidget")
})
