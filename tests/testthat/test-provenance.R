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

test_that(".provenance_caption is empty when no source or description is known", {
  prov <- mysterycall:::.build_provenance(
    metric = "m", computation = "c",
    numerator_desc = NULL, denominator_desc = NULL, generated_by = "g"
  )
  expect_identical(mysterycall:::.provenance_caption(prov), "")
})
