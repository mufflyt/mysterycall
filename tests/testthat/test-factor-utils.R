# ── mysterycall:::mysterycall_recode_credentials ───────────────────────────────────────────

test_that("recode_credentials: MD variants → 'MD'", {
  expect_equal(mysterycall:::mysterycall_recode_credentials("MD"),     "MD")
  expect_equal(mysterycall:::mysterycall_recode_credentials("M.D."),   "MD")
  expect_equal(mysterycall:::mysterycall_recode_credentials("MD/PhD"), "MD")
  expect_equal(mysterycall:::mysterycall_recode_credentials("MD-PhD"), "MD")
  expect_equal(mysterycall:::mysterycall_recode_credentials("doctor of medicine"), "MD")
  expect_equal(mysterycall:::mysterycall_recode_credentials("Allopathic"), "MD")
})

test_that("recode_credentials: DO variants → 'DO'", {
  expect_equal(mysterycall:::mysterycall_recode_credentials("DO"),    "DO")
  expect_equal(mysterycall:::mysterycall_recode_credentials("D.O."),  "DO")
  expect_equal(mysterycall:::mysterycall_recode_credentials("osteopathic"), "DO")
})

test_that("recode_credentials: MD takes priority over DO in combined string", {
  # "MD/DO" contains both; MD should win (checked first)
  expect_equal(mysterycall:::mysterycall_recode_credentials("MD/DO"), "MD")
})

test_that("recode_credentials: non-MD/DO → 'Other'", {
  expect_equal(mysterycall:::mysterycall_recode_credentials("PA-C"),  "Other")
  expect_equal(mysterycall:::mysterycall_recode_credentials("MBBS"),  "Other")
  expect_equal(mysterycall:::mysterycall_recode_credentials("NP"),    "Other")
  expect_equal(mysterycall:::mysterycall_recode_credentials("RN"),    "Other")
  expect_equal(mysterycall:::mysterycall_recode_credentials("DDS"),   "Other")
})

test_that("recode_credentials: NA → NA", {
  expect_true(is.na(mysterycall:::mysterycall_recode_credentials(NA_character_)))
})

test_that("recode_credentials: custom other_label", {
  expect_equal(mysterycall:::mysterycall_recode_credentials("NP", other_label = "Non-Physician"), "Non-Physician")
})

test_that("recode_credentials: case-insensitive", {
  expect_equal(mysterycall:::mysterycall_recode_credentials("md"),  "MD")
  expect_equal(mysterycall:::mysterycall_recode_credentials("DO"),  "DO")
  expect_equal(mysterycall:::mysterycall_recode_credentials("d.O."), "DO")
})

test_that("recode_credentials: vectorized", {
  res <- mysterycall:::mysterycall_recode_credentials(c("M.D.", "D.O.", "PA", NA))
  expect_equal(res, c("MD", "DO", "Other", NA))
  expect_length(res, 4L)
})

test_that("recode_credentials: returns character vector", {
  expect_type(mysterycall:::mysterycall_recode_credentials("MD"), "character")
})

# ── mysterycall:::mysterycall_reorder_by_freq ───────────────────────────────────────────────

test_that("reorder_by_freq: most frequent level is first", {
  x   <- c("B","A","A","C","B","B","C")
  res <- mysterycall:::mysterycall_reorder_by_freq(x)
  expect_equal(levels(res)[[1L]], "B")
})

test_that("reorder_by_freq: returns a factor", {
  x   <- c("A","B","B")
  res <- mysterycall:::mysterycall_reorder_by_freq(x)
  expect_s3_class(res, "factor")
})

test_that("reorder_by_freq: works on character input", {
  x   <- c("X","Y","Y","Z")
  res <- mysterycall:::mysterycall_reorder_by_freq(x)
  expect_equal(levels(res)[[1L]], "Y")
})

test_that("reorder_by_freq: works on factor input", {
  x   <- factor(c("A","B","B","C"))
  res <- mysterycall:::mysterycall_reorder_by_freq(x)
  expect_s3_class(res, "factor")
  expect_equal(levels(res)[[1L]], "B")
})

test_that("reorder_by_freq: decreasing=FALSE reverses order", {
  x   <- c("A","A","A","B","B","C")
  res <- mysterycall:::mysterycall_reorder_by_freq(x, decreasing = FALSE)
  expect_equal(levels(res)[[1L]], "C")
})

test_that("reorder_by_freq: na_level includes NAs as last level", {
  x   <- c("A","A","B", NA)
  res <- mysterycall:::mysterycall_reorder_by_freq(x, na_level = "Unknown")
  expect_true("Unknown" %in% levels(res))
  expect_equal(tail(levels(res), 1L), "Unknown")
})

test_that("reorder_by_freq: NAs without na_level remain NA", {
  x   <- c("A","B", NA)
  res <- mysterycall:::mysterycall_reorder_by_freq(x)
  expect_true(any(is.na(res)))
})

test_that("reorder_by_freq: non-character/factor input errors", {
  expect_error(mysterycall:::mysterycall_reorder_by_freq(1:5), "character or factor")
})

test_that("reorder_by_freq: preserves length", {
  x <- c("A","B","B","C")
  expect_length(mysterycall:::mysterycall_reorder_by_freq(x), length(x))
})
