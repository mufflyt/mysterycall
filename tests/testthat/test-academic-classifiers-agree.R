library(testthat)

# The two academic classifiers now share one vocabulary, so they agree on the
# names that previously disagreed (Medical Center, Cancer Center, Duke, Emory,
# Health System, ...). F1 = classify_academic_affiliation (academic vs not);
# F2 = classify_practice_setting (Academic/Government/Private).

f1_academic <- function(name) {
  res <- suppressMessages(
    mysterycall:::mysterycall_classify_academic_affiliation(name)
  )
  res$academic_classification == "Academic"
}
f2_academic <- function(name) {
  suppressMessages(mysterycall_classify_practice_setting(name)) == "Academic"
}

test_that("previously-divergent names now classify Academic in BOTH", {
  names <- c(
    "Community Medical Center",
    "Regional Cancer Center",
    "Duke Health",
    "Vanderbilt Clinic",
    "Emory Clinic",
    "Henry Ford Hospital",
    "Ascension Health System"
  )
  for (nm in names) {
    expect_true(f1_academic(nm), info = paste("F1 should be academic:", nm))
    expect_true(f2_academic(nm), info = paste("F2 should be academic:", nm))
  }
})

test_that("the wired-in evidence constants are now consulted", {
  # NCI cancer center, ACGME program, CTSA hub -> academic (were dead code before)
  expect_true(f1_academic("Comprehensive Cancer Center"))
  expect_true(f1_academic("OBGYN Residency Program"))
  expect_true(f1_academic("Clinical and Translational Science Award Hub"))
})

test_that("a plainly non-academic private office stays non-academic in both", {
  nm <- "Denver ENT Associates LLC"
  expect_false(f1_academic(nm))
  expect_false(f2_academic(nm))
})

test_that("NA and empty names do not error and are non-academic", {
  res <- suppressMessages(
    mysterycall:::mysterycall_classify_academic_affiliation(c(NA, "", "Johns Hopkins"))
  )
  expect_equal(res$academic_classification, c("Non-Academic", "Non-Academic", "Academic"))
})
