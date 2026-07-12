library(testthat)

test_that("mysterycall_add_hhi joins HHI and derives hhi_k + hhi_cat", {
  offices <- data.frame(office = c("A", "B", "C"),
                        cbsa   = c("19740", "12060", "99999"),
                        stringsAsFactors = FALSE)
  hhi_tbl <- data.frame(cbsa = c("19740", "12060"), hhi = c(1450, 2600))
  out <- suppressWarnings(mysterycall_add_hhi(offices, hhi_tbl))
  expect_equal(out$hhi[1], 1450)
  expect_equal(out$hhi_k[1], 1.45)
  expect_equal(as.character(out$hhi_cat), c("moderate", "high", NA))
  expect_true(is.ordered(out$hhi_cat))
})

test_that("DOJ/FTC thresholds bin correctly", {
  d <- data.frame(cbsa = c("a", "b", "c", "d"), stringsAsFactors = FALSE)
  tbl <- data.frame(cbsa = c("a", "b", "c", "d"),
                    hhi = c(500, 1000, 1800, 5000))
  out <- mysterycall_add_hhi(d, tbl)
  # cut() is (lower, upper]: 1000 -> un-concentrated, 1800 -> moderate
  expect_equal(as.character(out$hhi_cat),
               c("un-concentrated", "un-concentrated", "moderate", "high"))
})

test_that("unmatched markets warn", {
  d <- data.frame(cbsa = c("x", "y"), stringsAsFactors = FALSE)
  tbl <- data.frame(cbsa = "x", hhi = 1200)
  expect_warning(mysterycall_add_hhi(d, tbl), "not present")
})

test_that("market key builds city|STATE form", {
  expect_equal(mysterycall:::.hhi_market_key("Denver-Aurora-Lakewood, CO"), "denver|CO")
  expect_equal(mysterycall:::.hhi_market_key("New York-Newark-Jersey City, NY-NJ-PA"),
               "new york|NY")
})

test_that("read_kff_hhi errors clearly on missing file", {
  expect_error(mysterycall_read_kff_hhi("does-not-exist.xlsx"), "not found")
})

test_that("add_hhi input validation", {
  expect_error(mysterycall_add_hhi(1L, data.frame(cbsa = "x", hhi = 1)), "must be a data frame")
  expect_error(mysterycall_add_hhi(data.frame(cbsa = "x"), data.frame(cbsa = "x", hhi = 1),
                                   market_col = "nope"), "not found")
})
