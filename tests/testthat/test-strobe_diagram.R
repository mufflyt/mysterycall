test_that("the diagram refuses anything that did not come from the validator", {
  expect_error(mysterycall_strobe_diagram(list(spine = c(a = 1, b = 1))),
               "mysterycall_flow_spec")
})

test_that("every validated count reaches a drawn box", {
  # The gap this closes: counts can be derived correctly and then the wrong
  # variable passed to a box. Checking the drawn labels catches that; checking
  # the derivation does not.
  spec <- mysterycall_flow_spec(
    spine = c("Screened" = 100, "Enrolled" = 80),
    exclusions = list("Screened" = c("Ineligible" = 15, "Declined" = 5)),
    splits = list("Enrolled" = c("Completed" = 70, "Withdrew" = 10)))
  p <- mysterycall_strobe_diagram(spec)
  drawn <- paste(unlist(lapply(p$layers, function(l) as.character(l$data$text))),
                 collapse = " | ")
  for (n in c("100", "80", "70", "10", "15", "5"))
    expect_match(drawn, paste0("n = ", n), fixed = TRUE)
  for (lab in c("Screened", "Enrolled", "Completed", "Withdrew", "Ineligible"))
    expect_match(drawn, lab, fixed = TRUE)
})

test_that("a child is drawn beneath its own parent, not across the diagram", {
  # A row spread edge to edge put a box under a parent it did not belong to.
  spec <- mysterycall_flow_spec(
    spine = c("A" = 100, "B" = 100),
    splits = list("B" = c("L" = 60, "R" = 40),
                  "R" = c("R1" = 25, "R2" = 15)))
  p <- mysterycall_strobe_diagram(spec)
  b <- do.call(rbind, lapply(p$layers, function(l)
    if ("text" %in% names(l$data)) l$data else NULL))
  xr  <- b$x[grepl("^R\n", b$text)]
  kids <- b$x[grepl("^R1\n|^R2\n", b$text)]
  expect_length(xr, 1L)
  expect_true(all(abs(kids - xr) < 0.35),
              info = "R1/R2 must sit near R, not at the canvas edges")
})

test_that("thousands separators appear in drawn counts", {
  spec <- mysterycall_flow_spec(c("Parsed" = 1154, "Cohort" = 1106),
                                exclusions = list("Parsed" = c("Video" = 48)))
  p <- mysterycall_strobe_diagram(spec)
  drawn <- paste(unlist(lapply(p$layers, function(l) as.character(l$data$text))),
                 collapse = " | ")
  expect_match(drawn, "1,154", fixed = TRUE)
})

test_that("it writes a file without needing a headless browser", {
  skip_if_not_installed("ggplot2")
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f), add = TRUE)
  spec <- mysterycall_flow_spec(c("A" = 10, "B" = 8),
                               exclusions = list("A" = c("gone" = 2)))
  mysterycall_strobe_diagram(spec, output_path = f, width = 5, height = 4, dpi = 72)
  expect_true(file.exists(f))
  expect_gt(file.info(f)$size, 1000)
})

test_that("the saved figure has an opaque white background by default", {
  # theme_void() leaves the background blank, which wrote a fully transparent
  # PNG (corner alpha 0). That is invisible on a white page and wrong the
  # moment the figure lands in a Word manuscript or on a coloured slide.
  skip_if_not_installed("png")
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f), add = TRUE)
  spec <- mysterycall_flow_spec(c("A" = 10, "B" = 8),
                                exclusions = list("A" = c("gone" = 2)))
  mysterycall_strobe_diagram(spec, output_path = f, width = 4, height = 3, dpi = 72)
  px <- png::readPNG(f)
  if (dim(px)[3] == 4L)
    expect_equal(px[1, 1, 4], 1, info = "corner pixel must be opaque")
  expect_equal(as.numeric(px[1, 1, 1:3]), c(1, 1, 1),
               info = "corner pixel must be white")
})

test_that("background = NA still gives a deliberately transparent figure", {
  skip_if_not_installed("png")
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f), add = TRUE)
  spec <- mysterycall_flow_spec(c("A" = 10, "B" = 8),
                                exclusions = list("A" = c("gone" = 2)))
  mysterycall_strobe_diagram(spec, output_path = f, width = 4, height = 3,
                             dpi = 72, background = NA)
  px <- png::readPNG(f)
  expect_equal(dim(px)[3], 4L)
  expect_equal(px[1, 1, 4], 0, info = "NA must stay transparent")
})
