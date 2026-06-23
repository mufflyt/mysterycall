suppressPackageStartupMessages(
  pkgload::load_all("/Users/tylermuffly/mysterycall", quiet = TRUE)
)

.t1_data <- function() {
  data.frame(
    insurance = rep(c("Medicaid", "BCBS"), 25),
    female    = sample(c(TRUE, FALSE), 50, replace = TRUE, prob = c(0.4, 0.6)),
    setting   = sample(c("Academic", "Private"), 50, replace = TRUE),
    wait_days = round(runif(50, 5, 45)),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Block 1: adversarial — existing input guards still hold
# ---------------------------------------------------------------------------

test_that("data not a data frame errors", {
  expect_error(
    mysterycall_table1("not a df", covariates = "female"),
    regexp = "data frame"
  )
})

test_that("data = 42 errors", {
  expect_error(mysterycall_table1(42, covariates = "female"))
})

test_that("covariates column not in data errors", {
  set.seed(1); df <- .t1_data()
  expect_error(
    mysterycall_table1(df, covariates = "nonexistent_col"),
    regexp = "nonexistent_col"
  )
})

test_that("stratify_by column not in data errors", {
  set.seed(1); df <- .t1_data()
  expect_error(
    mysterycall_table1(df, covariates = "female", stratify_by = "nonexistent_col"),
    regexp = "nonexistent_col"
  )
})

test_that("stratify_by must be scalar — vector rejected", {
  set.seed(1); df <- .t1_data()
  expect_error(
    mysterycall_table1(df, covariates = "female",
                       stratify_by = c("insurance", "setting")),
    regexp = "single"
  )
})

test_that("digits = -1 errors", {
  set.seed(1); df <- .t1_data()
  expect_error(
    mysterycall_table1(df, covariates = "female", digits = -1),
    regexp = "non-negative"
  )
})

# ---------------------------------------------------------------------------
# Block 2: negative control — output_path = NULL (existing behaviour unchanged)
# ---------------------------------------------------------------------------

test_that("output_path = NULL returns class mysterycall_table1", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"),
                          stratify_by = "insurance")
  expect_s3_class(r, "mysterycall_table1")
})

test_that("$docx_path is NULL when output_path not supplied", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"),
                          stratify_by = "insurance")
  expect_null(r$docx_path)
})

test_that("$table is a data frame", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"))
  expect_true(is.data.frame(r$table))
})

test_that("$table has a variable column", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"))
  expect_true("variable" %in% names(r$table))
})

test_that("$table has a level column", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"))
  expect_true("level" %in% names(r$table))
})

test_that("$column_ns is a named integer-compatible vector", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"),
                          stratify_by = "insurance")
  expect_true(is.numeric(r$column_ns))
  expect_false(is.null(names(r$column_ns)))
})

test_that("$n equals nrow(data)", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"))
  expect_equal(r$n, nrow(df))
})

test_that("$stratify_by matches supplied argument", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"),
                          stratify_by = "insurance")
  expect_equal(r$stratify_by, "insurance")
})

test_that("$stratify_by is NULL when not supplied", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"))
  expect_null(r$stratify_by)
})

test_that("p_value=FALSE removes p_value column", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"),
                          stratify_by = "insurance", p_value = FALSE)
  expect_false("p_value" %in% names(r$table))
})

test_that("p_value column present when p_value=TRUE and stratify_by set", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"),
                          stratify_by = "insurance", p_value = TRUE)
  expect_true("p_value" %in% names(r$table))
})

test_that("include_overall=FALSE removes Overall column", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = c("female", "setting"),
                          stratify_by = "insurance", include_overall = FALSE)
  expect_false("Overall" %in% names(r$table))
})

test_that("variable_labels renames variable in output", {
  set.seed(1); df <- .t1_data()
  r <- mysterycall_table1(df, covariates = "female",
                          variable_labels = c(female = "Female sex"))
  expect_true("Female sex" %in% r$table$variable)
  expect_false("female" %in% r$table$variable)
})

test_that("as_flex_table.mysterycall_table1 is NOT in namespace exports", {
  ns_exports <- getNamespaceExports("mysterycall")
  expect_false("as_flex_table.mysterycall_table1" %in% ns_exports)
})

# ---------------------------------------------------------------------------
# Block 3: negative control — output_path integration
# ---------------------------------------------------------------------------

test_that("output_path writes docx and $docx_path matches", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("officer")
  tmp <- tempfile(fileext = ".docx")
  set.seed(1); df <- .t1_data()
  result <- suppressMessages(
    mysterycall_table1(df,
                       covariates  = c("female", "setting", "wait_days"),
                       stratify_by = "insurance",
                       output_path = tmp)
  )
  expect_equal(result$docx_path, tmp)
})

test_that("output_path: file exists on disk", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("officer")
  tmp <- tempfile(fileext = ".docx")
  set.seed(1); df <- .t1_data()
  suppressMessages(
    mysterycall_table1(df,
                       covariates  = c("female", "setting"),
                       stratify_by = "insurance",
                       output_path = tmp)
  )
  expect_true(file.exists(tmp))
})

test_that("output_path: written file is non-empty", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("officer")
  tmp <- tempfile(fileext = ".docx")
  set.seed(1); df <- .t1_data()
  suppressMessages(
    mysterycall_table1(df,
                       covariates  = c("female", "setting"),
                       output_path = tmp)
  )
  expect_gt(file.size(tmp), 0)
})

test_that("$table content identical with and without output_path", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("officer")
  set.seed(1); df1 <- .t1_data()
  set.seed(1); df2 <- .t1_data()
  r_no   <- mysterycall_table1(df1, c("female", "setting"), "insurance")
  r_with <- suppressMessages(
    mysterycall_table1(df2, c("female", "setting"), "insurance",
                       output_path = tempfile(fileext = ".docx"))
  )
  expect_equal(r_no$table, r_with$table)
})

test_that("class is still mysterycall_table1 when output_path is set", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("officer")
  tmp <- tempfile(fileext = ".docx")
  set.seed(1); df <- .t1_data()
  result <- suppressMessages(
    mysterycall_table1(df, c("female", "setting"), "insurance",
                       output_path = tmp)
  )
  expect_s3_class(result, "mysterycall_table1")
})

test_that("$n unchanged when output_path is set", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("officer")
  tmp <- tempfile(fileext = ".docx")
  set.seed(1); df <- .t1_data()
  result <- suppressMessages(
    mysterycall_table1(df, c("female", "setting"), "insurance",
                       output_path = tmp)
  )
  expect_equal(result$n, nrow(df))
})

test_that("output_path emits a message containing 'Table 1 written'", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("officer")
  tmp <- tempfile(fileext = ".docx")
  set.seed(1); df <- .t1_data()
  expect_message(
    mysterycall_table1(df, c("female", "setting"), "insurance",
                       output_path = tmp),
    regexp = "Table 1 written"
  )
})
