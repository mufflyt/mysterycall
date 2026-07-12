library(testthat)

test_that("provider counts collapse to distinct NPIs per county and pad FIPS", {
  roster <- data.frame(
    npi         = sprintf("1%09d", c(1, 1, 2, 3, 4)),  # NPI 1 duplicated in same county
    fips_county = c("08031", "8031", "08031", "48201", "48201"),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_get_county_provider_counts(roster)
  expect_s3_class(res, "mysterycall_provider_counts")
  co <- res$by_county
  expect_equal(sort(co$fips_county), c("08031", "48201"))
  # 8031 pads to 08031; NPIs {1,2} distinct there
  expect_equal(co$n_providers[co$fips_county == "08031"], 2L)
  expect_equal(co$n_providers[co$fips_county == "48201"], 2L)
})

test_that("provider density scales by population", {
  roster <- data.frame(npi = sprintf("1%09d", 1:2),
                       fips_county = c("08031", "08031"),
                       stringsAsFactors = FALSE)
  pop <- data.frame(fips_county = "08031", population = 200000)
  res <- mysterycall_get_county_provider_counts(roster, population = pop, per = 100000)
  expect_equal(res$by_county$providers_per_100k, 1)  # 2 / 200000 * 100000
})

test_that("denominator_label renames the density column and keeps arithmetic", {
  roster <- data.frame(npi = sprintf("1%09d", 1:2),
                       fips_county = c("08031", "08031"),
                       stringsAsFactors = FALSE)
  women <- data.frame(fips_county = "08031", population = 200000)
  res <- mysterycall_get_county_provider_counts(
    roster, population = women, denominator_label = "women")
  expect_true("providers_per_100k_women" %in% names(res$by_county))
  expect_false("providers_per_100k" %in% names(res$by_county))
  expect_equal(res$by_county$providers_per_100k_women, 1)  # 2 / 200000 * 100000
  # sanitizes to a syntactic suffix
  res2 <- mysterycall_get_county_provider_counts(
    roster, population = women, denominator_label = "Reproductive-Age Women")
  expect_true("providers_per_100k_reproductive_age_women" %in% names(res2$by_county))
})

test_that("denominator_label validation", {
  roster <- data.frame(npi = sprintf("1%09d", 1),
                       fips_county = "08031", stringsAsFactors = FALSE)
  pop <- data.frame(fips_county = "08031", population = 1000)
  expect_error(
    mysterycall_get_county_provider_counts(roster, population = pop,
                                           denominator_label = c("a", "b")),
    "single non-empty string")
})

test_that("missing county FIPS warns and drops", {
  roster <- data.frame(npi = sprintf("1%09d", 1:2),
                       fips_county = c("08031", NA), stringsAsFactors = FALSE)
  expect_warning(res <- mysterycall_get_county_provider_counts(roster), "missing/blank")
  expect_equal(res$n_counties, 1L)
})

test_that("taxonomy breakdown returned when requested", {
  roster <- data.frame(npi = sprintf("1%09d", 1:3),
                       fips_county = c("08031", "08031", "08031"),
                       taxonomy = c("OBGYN", "OBGYN", "FM"), stringsAsFactors = FALSE)
  res <- mysterycall_get_county_provider_counts(roster, taxonomy_col = "taxonomy")
  expect_false(is.null(res$by_specialty))
  expect_equal(nrow(res$by_specialty), 2L)
})

test_that("enrollment aggregates and derives ratio + ordered category", {
  cms <- data.frame(
    fips_county         = c("08031", "48201", "48201"),
    medicare_enrollment = c(90000, 400000, 10000),
    medicaid_enrollment = c(45000, 600000, 20000),
    stringsAsFactors = FALSE
  )
  en <- mysterycall_summarize_county_enrollment(cms)
  expect_equal(en$medicare_enrollment[en$fips_county == "48201"], 410000)
  expect_equal(en$medicaid_to_medicare_ratio[en$fips_county == "08031"], 0.5)
  expect_s3_class(en$medicaid_access_category, "ordered")
  expect_equal(as.character(en$medicaid_access_category[en$fips_county == "08031"]),
               "Medium (0.50-0.74)")
})

test_that("enrollment ratio is NA when Medicare is zero", {
  cms <- data.frame(fips_county = "08031", medicare_enrollment = 0,
                    medicaid_enrollment = 100, stringsAsFactors = FALSE)
  en <- mysterycall_summarize_county_enrollment(cms)
  expect_true(is.na(en$medicaid_to_medicare_ratio))
})

test_that("enrollment input validation", {
  expect_error(mysterycall_summarize_county_enrollment(data.frame(x = 1)), "not found")
})
