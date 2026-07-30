library(testthat)

COUNTS_LONG <- data.frame(
  subspecialty = rep(c("Gynecologic Oncology", "Urogynecology"), each = 3),
  year         = rep(c(2013L, 2018L, 2023L), times = 2),
  count        = c(1900, 2200, 2600, 900, 1400, 2100),
  stringsAsFactors = FALSE
)
FEM_POP <- c(`2013` = 160000000, `2018` = 165000000, `2023` = 168000000)

test_that("computes density = count / population * per and returns a ggplot", {
  skip_if_not_installed("ggplot2")
  p <- suppressWarnings(
    mysterycall_subspecialist_trend(COUNTS_LONG, population = FEM_POP)
  )
  expect_s3_class(p, "ggplot")
  d <- p$data
  # Gyn Onc 2013: 1900 / 160,000,000 * 1e5 = 1.1875
  got <- d$density[d$subspecialty == "Gynecologic Oncology" & d$year == 2013]
  expect_equal(got, 1900 / 160000000 * 1e5)
  expect_true(all(c("subspecialty", "year", "count", "population", "density") %in% names(d)))
})

test_that("wide-format counts pivot to the same densities as long", {
  skip_if_not_installed("ggplot2")
  wide <- data.frame(
    subspecialty = c("Gynecologic Oncology", "Urogynecology"),
    `2013`       = c(1900, 900),
    `2018`       = c(2200, 1400),
    `2023`       = c(2600, 2100),
    check.names  = FALSE,
    stringsAsFactors = FALSE
  )
  p_wide <- suppressWarnings(
    mysterycall_subspecialist_trend(wide, population = FEM_POP)
  )
  p_long <- suppressWarnings(
    mysterycall_subspecialist_trend(COUNTS_LONG, population = FEM_POP)
  )
  key <- function(d) d[order(d$subspecialty, d$year), "density"]
  expect_equal(key(p_wide$data), key(p_long$data))
})

test_that("matrix counts are accepted", {
  skip_if_not_installed("ggplot2")
  m <- matrix(c(1900, 900, 2200, 1400, 2600, 2100), nrow = 2,
              dimnames = list(c("Gynecologic Oncology", "Urogynecology"),
                              c("2013", "2018", "2023")))
  p <- suppressWarnings(mysterycall_subspecialist_trend(m, population = FEM_POP))
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(p$data), 6L)
})

test_that("population accepted as a data frame and as an ordered vector", {
  skip_if_not_installed("ggplot2")
  pop_df <- data.frame(year = c(2013, 2018, 2023),
                       population = c(160000000, 165000000, 168000000))
  p_df <- suppressWarnings(
    mysterycall_subspecialist_trend(COUNTS_LONG, population = pop_df)
  )
  p_vec <- suppressWarnings(  # unnamed, ordered by sorted year
    mysterycall_subspecialist_trend(
      COUNTS_LONG, population = c(160000000, 165000000, 168000000))
  )
  expect_equal(p_df$data$density, p_vec$data$density)
})

test_that("missing a denominator year is an informative error", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_subspecialist_trend(
      COUNTS_LONG, population = c(`2013` = 160000000, `2018` = 165000000)),
    "missing denominators for year"
  )
})

test_that("both counts and population are required", {
  expect_error(mysterycall_subspecialist_trend(COUNTS_LONG), "Supply both")
})

test_that("provenance is attached and written as a sidecar", {
  skip_if_not_installed("ggplot2")
  p <- suppressWarnings(mysterycall_subspecialist_trend(
    COUNTS_LONG, population = FEM_POP,
    numerator_source = "ABOG diplomate counts",
    accessed = "2026-07-30"
  ))
  prov <- attr(p, "provenance")
  expect_s3_class(prov, "mysterycall_provenance")
  expect_equal(prov$numerator$source, "ABOG diplomate counts")
  expect_equal(prov$per, 1e5)
  expect_equal(prov$years, c(2013, 2023))
  expect_match(prov$generated_by, "subspecialist_trend")
  # caption auto-built onto the figure
  expect_true(!is.null(p$labels$caption) && nzchar(p$labels$caption))

  out <- tempfile(fileext = ".png")
  side <- paste0(tools::file_path_sans_ext(out), ".provenance.txt")
  on.exit(unlink(c(out, side)), add = TRUE)
  suppressMessages(suppressWarnings(mysterycall_subspecialist_trend(
    COUNTS_LONG, population = FEM_POP,
    numerator_source = "ABOG diplomate counts", accessed = "2026-07-30",
    output_path = out
  )))
  expect_true(file.exists(side))
  txt <- paste(readLines(side), collapse = "\n")
  expect_match(txt, "ABOG diplomate counts")
  expect_match(txt, "B01001_026E")
  expect_match(txt, "Per-point values")
})

test_that("caption = NA suppresses the caption", {
  skip_if_not_installed("ggplot2")
  p <- suppressWarnings(mysterycall_subspecialist_trend(
    COUNTS_LONG, population = FEM_POP, caption = NA
  ))
  expect_null(p$labels$caption)
})

test_that("negative counts and non-positive population are rejected", {
  skip_if_not_installed("ggplot2")
  bad <- COUNTS_LONG; bad$count[1] <- -5
  expect_error(
    mysterycall_subspecialist_trend(bad, population = FEM_POP),
    "non-negative"
  )
  expect_error(
    mysterycall_subspecialist_trend(
      COUNTS_LONG, population = c(`2013` = 0, `2018` = 1, `2023` = 1)),
    "positive"
  )
})
