skip_if_not_installed("gtsummary")

make_df <- function(n = 60) {
  set.seed(42)
  data.frame(
    gender    = sample(c("Male", "Female"), n, replace = TRUE),
    setting   = sample(c("Academic", "Private"), n, replace = TRUE),
    age_cat   = sample(c("30-39", "40-49", "50-59"), n, replace = TRUE),
    insurance = sample(c("BCBS", "Medicaid"), n, replace = TRUE),
    stringsAsFactors = FALSE
  )
}

# ── happy paths ───────────────────────────────────────────────────────────────

test_that("table1_gtsummary: returns a gtsummary tbl_summary object (unstratified)", {
  df  <- make_df()
  out <- suppressMessages(suppressWarnings(
    mysterycall_table1_gtsummary(df, vars = c("gender", "setting", "age_cat"))
  ))
  expect_s3_class(out, "tbl_summary")
})

test_that("table1_gtsummary: stratified version returns tbl_summary", {
  df  <- make_df()
  out <- suppressMessages(suppressWarnings(
    mysterycall_table1_gtsummary(df,
      vars       = c("gender", "setting", "age_cat"),
      strata_col = "insurance"
    )
  ))
  expect_s3_class(out, "tbl_summary")
})

test_that("table1_gtsummary: overall_last = TRUE works", {
  df <- make_df()
  expect_s3_class(
    suppressMessages(suppressWarnings(
      mysterycall_table1_gtsummary(df, vars = c("gender", "setting"),
                                    strata_col = "insurance",
                                    overall_last = TRUE)
    )),
    "tbl_summary"
  )
})

test_that("table1_gtsummary: warns and drops strata_col from vars", {
  df <- make_df()
  expect_warning(
    suppressMessages(
      mysterycall_table1_gtsummary(df,
        vars       = c("insurance", "gender"),
        strata_col = "insurance")
    ),
    "appears in `vars`"
  )
})

test_that("table1_gtsummary: label_list is accepted", {
  df  <- make_df()
  out <- suppressMessages(suppressWarnings(
    mysterycall_table1_gtsummary(df,
      vars       = c("gender", "setting"),
      label_list = list(gender = "Sex", setting = "Practice type")
    )
  ))
  expect_s3_class(out, "tbl_summary")
})

# ── validation errors ────────────────────────────────────────────────────────

test_that("table1_gtsummary: rejects non-data.frame data", {
  expect_error(mysterycall_table1_gtsummary("not a df", vars = "x"),
               "must be a data frame")
})

test_that("table1_gtsummary: rejects empty vars", {
  expect_error(mysterycall_table1_gtsummary(make_df(), vars = character(0)),
               "non-empty character")
})

test_that("table1_gtsummary: rejects non-character vars", {
  expect_error(mysterycall_table1_gtsummary(make_df(), vars = 1:2),
               "non-empty character")
})

test_that("table1_gtsummary: errors when vars not in data", {
  expect_error(
    mysterycall_table1_gtsummary(make_df(), vars = c("gender", "missing_col")),
    "missing_col"
  )
})

test_that("table1_gtsummary: rejects multi-element strata_col", {
  expect_error(
    mysterycall_table1_gtsummary(make_df(), vars = "gender",
                                  strata_col = c("a", "b")),
    "single non-NA character"
  )
})

test_that("table1_gtsummary: rejects NA strata_col", {
  expect_error(
    mysterycall_table1_gtsummary(make_df(), vars = "gender",
                                  strata_col = NA_character_),
    "single non-NA character"
  )
})

test_that("table1_gtsummary: errors when strata_col not in data", {
  expect_error(
    mysterycall_table1_gtsummary(make_df(), vars = "gender",
                                  strata_col = "nope"),
    "not found in `data`"
  )
})

test_that("table1_gtsummary: rejects invalid percent", {
  expect_error(
    suppressMessages(
      mysterycall_table1_gtsummary(make_df(), vars = "gender",
                                    percent = "bad_option")
    )
  )
})

test_that("table1_gtsummary: rejects invalid missing", {
  expect_error(
    suppressMessages(
      mysterycall_table1_gtsummary(make_df(), vars = "gender",
                                    missing = "bad_option")
    )
  )
})
