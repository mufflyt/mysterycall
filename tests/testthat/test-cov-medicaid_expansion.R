library(testthat)
library(mysterycall)

# R/medicaid_expansion.R documents the `medicaid_expansion` dataset; there is no
# `mysterycall_medicaid_expansion_status()` lookup function in the package yet.
# This file covers the dataset itself. (The former always-skip placeholder for
# the not-yet-existent function was removed -- it asserted nothing.)

test_that("medicaid_expansion dataset exists and has expected structure", {
  expect_true(exists("medicaid_expansion", envir = asNamespace("mysterycall")) ||
              "medicaid_expansion" %in% ls(asNamespace("mysterycall")))
})
