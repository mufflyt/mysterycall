library(testthat)

test_that(".build_provenance captures fields and prints a readable block", {
  prov <- mysterycall:::.build_provenance(
    metric             = "Subspecialists per 100,000 women",
    computation        = "density = count / population * 1e+05",
    numerator_desc     = "Counts (user-supplied)",
    denominator_desc   = "Total female population",
    generated_by       = "mysterycall::mysterycall_subspecialist_trend()",
    per                = 1e5,
    years              = c(2013, 2018, 2023),
    n_series           = 4L,
    numerator_source   = "ABOG diplomate counts",
    denominator_source = "Census ACS B01001_026E",
    accessed           = "2026-07-30"
  )
  expect_s3_class(prov, "mysterycall_provenance")
  expect_equal(prov$years, c(2013, 2023))          # range, not every year
  expect_equal(prov$n_series, 4L)
  expect_true(!is.na(prov$package_version))
  expect_true(!is.na(prov$created))

  out <- utils::capture.output(print(prov))
  txt <- paste(out, collapse = "\n")
  expect_match(txt, "figure provenance")
  expect_match(txt, "ABOG diplomate counts")
  expect_match(txt, "Census ACS B01001_026E")
  expect_match(txt, "2013–2023")
})

test_that(".provenance_caption falls back to descriptions and notes access date", {
  prov <- mysterycall:::.build_provenance(
    metric = "m", computation = "c",
    numerator_desc = "num desc", denominator_desc = "den desc",
    generated_by = "g", accessed = "2026-07-30"
  )
  cap <- mysterycall:::.provenance_caption(prov)
  expect_match(cap, "^Source — ")
  expect_match(cap, "num desc")
  expect_match(cap, "den desc")
  expect_match(cap, "accessed 2026-07-30")
})

test_that(".write_provenance emits both .txt and .json sidecars", {
  skip_if_not_installed("jsonlite")
  prov <- mysterycall:::.build_provenance(
    metric = "Subspecialists per 100,000 women",
    computation = "density = count / population * 1e+05",
    numerator_desc = "Counts", denominator_desc = "Total female population",
    generated_by = "mysterycall::mysterycall_subspecialist_trend()",
    per = 1e5, years = c(2013, 2023), n_series = 2L,
    numerator_source = "ABOG diplomate counts",
    denominator_source = "Census ACS B01001_026E", accessed = "2026-07-30"
  )
  data <- data.frame(
    subspecialty = c("Gynecologic Oncology", "Urogynecology"),
    year = c(2013L, 2013L), count = c(1900, 900),
    population = c(160000000, 160000000),
    density = c(1900, 900) / 160000000 * 1e5
  )
  out  <- tempfile(fileext = ".png")
  base <- tools::file_path_sans_ext(out)
  txt  <- paste0(base, ".provenance.txt")
  json <- paste0(base, ".provenance.json")
  on.exit(unlink(c(txt, json)), add = TRUE)

  paths <- suppressMessages(mysterycall:::.write_provenance(prov, out, data))
  expect_setequal(paths, c(txt, json))
  expect_true(file.exists(json))

  parsed <- jsonlite::fromJSON(json)
  expect_equal(parsed$schema, "mysterycall/provenance")
  expect_equal(parsed$provenance$numerator$source, "ABOG diplomate counts")
  expect_equal(parsed$provenance$per, 1e5)
  # per-point table round-trips as an array of records
  expect_equal(nrow(parsed$data), 2L)
  expect_equal(sort(parsed$data$count), c(900, 1900))
})

test_that(".provenance_caption is empty when no source or description is known", {
  prov <- mysterycall:::.build_provenance(
    metric = "m", computation = "c",
    numerator_desc = NULL, denominator_desc = NULL, generated_by = "g"
  )
  expect_identical(mysterycall:::.provenance_caption(prov), "")
})
