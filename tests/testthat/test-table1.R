df <- data.frame(
  gender    = c("Male", "Female", "Female", "Male", "Male", "Female",
                "Male", "Female"),
  academic  = c("University", "Private Practice", "Private Practice",
                "University", "Private Practice", "University",
                "Private Practice", "University"),
  wait_days = c(10, 25, 14, 30, 7, 21, 18, 35),
  insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS",
                "Medicaid", "BCBS", "Medicaid", "BCBS"),
  stringsAsFactors = FALSE
)

# ── Basic structure ────────────────────────────────────────────────────────────

test_that("table1: returns mysterycall_table1 list with expected names", {
  res <- mysterycall_table1(df, covariates = c("gender", "wait_days"))
  expect_s3_class(res, "mysterycall_table1")
  expect_named(res, c("table", "column_ns", "stratify_by", "n", "docx_path"))
  expect_s3_class(res$table, "tbl_df")
  expect_null(res$stratify_by)
  expect_equal(res$n, nrow(df))
})

test_that("table1: unstratified table has variable, level, Overall columns only", {
  res <- mysterycall_table1(df, covariates = c("gender", "academic"))
  expect_true("variable"  %in% names(res$table))
  expect_true("level"     %in% names(res$table))
  expect_true("Overall"   %in% names(res$table))
  expect_false("p_value"  %in% names(res$table))
})

test_that("table1: stratified table has group columns and p_value", {
  res <- mysterycall_table1(df, covariates = "gender", stratify_by = "insurance")
  cols <- names(res$table)
  expect_true("p_value" %in% cols)
  expect_true(any(grepl("BCBS",     cols)))
  expect_true(any(grepl("Medicaid", cols)))
})

# ── Categorical variables ──────────────────────────────────────────────────────

test_that("table1: categorical variable produces one row per level", {
  res <- mysterycall_table1(df, covariates = "gender")
  gender_rows <- res$table[res$table$variable == "gender", ]
  expect_equal(nrow(gender_rows), 2L)    # Female, Male
  expect_setequal(gender_rows$level, c("Female", "Male"))
})

test_that("table1: n (%) in Overall cell is correct", {
  res <- mysterycall_table1(df, covariates = "gender")
  female_row <- res$table[res$table$variable == "gender" &
                            res$table$level == "Female", ]
  # 4 females out of 8 total → "4 (50.0%)"
  expect_equal(female_row$Overall, "4 (50.0%)")
})

test_that("table1: p_value appears on first level row only", {
  res <- mysterycall_table1(df, covariates = "gender", stratify_by = "insurance")
  gender_rows <- res$table[res$table$variable == "gender", ]
  expect_false(is.na(gender_rows$p_value[[1L]]))
  expect_true(all(is.na(gender_rows$p_value[-1L])))
})

# ── Continuous variables ───────────────────────────────────────────────────────

test_that("table1: continuous variable produces one row per cont_stats entry", {
  res <- mysterycall_table1(df, covariates = "wait_days",
                             cont_stats = c("median_iqr", "mean_sd"))
  wait_rows <- res$table[res$table$variable == "wait_days", ]
  expect_equal(nrow(wait_rows), 2L)
  expect_true(any(grepl("Median", wait_rows$level)))
  expect_true(any(grepl("Mean",   wait_rows$level)))
})

test_that("table1: median_iqr only produces one row for continuous", {
  res <- mysterycall_table1(df, covariates = "wait_days",
                             cont_stats = "median_iqr")
  wait_rows <- res$table[res$table$variable == "wait_days", ]
  expect_equal(nrow(wait_rows), 1L)
  expect_true(grepl("Median", wait_rows$level))
})

test_that("table1: continuous p_value on first row, NA on second", {
  res <- mysterycall_table1(df, covariates = "wait_days",
                             stratify_by  = "insurance",
                             cont_stats   = c("median_iqr", "mean_sd"))
  wait_rows <- res$table[res$table$variable == "wait_days", ]
  expect_false(is.na(wait_rows$p_value[[1L]]))
  expect_true(is.na(wait_rows$p_value[[2L]]))
})

test_that("table1: Overall cell contains bracket notation for median_iqr", {
  res <- mysterycall_table1(df, covariates = "wait_days",
                             cont_stats = "median_iqr")
  cell <- res$table$Overall[[1L]]
  expect_true(grepl("\\[", cell) && grepl("\\]", cell))
})

test_that("table1: Overall cell contains parentheses for mean_sd", {
  res <- mysterycall_table1(df, covariates = "wait_days",
                             cont_stats = "mean_sd")
  cell <- res$table$Overall[[1L]]
  expect_true(grepl("\\(", cell) && grepl("\\)", cell))
})

# ── Column N metadata ──────────────────────────────────────────────────────────

test_that("table1: column_ns sums to n when stratified", {
  res <- mysterycall_table1(df, covariates = "gender", stratify_by = "insurance")
  expect_equal(sum(res$column_ns[c("BCBS", "Medicaid")]), res$n)
})

test_that("table1: include_overall = FALSE drops Overall column", {
  res <- mysterycall_table1(df, covariates = "gender",
                             stratify_by    = "insurance",
                             include_overall = FALSE)
  expect_false("Overall" %in% names(res$table))
  expect_false("Overall" %in% names(res$column_ns))
})

# ── Variable labels ────────────────────────────────────────────────────────────

test_that("table1: variable_labels replaces column name in variable column", {
  res <- mysterycall_table1(df, covariates = c("gender", "wait_days"),
                             variable_labels = c(gender    = "Sex",
                                                 wait_days = "Wait time (days)"))
  expect_true("Sex"             %in% res$table$variable)
  expect_true("Wait time (days)" %in% res$table$variable)
  expect_false("gender"          %in% res$table$variable)
  expect_false("wait_days"       %in% res$table$variable)
})

# ── p_value = FALSE ────────────────────────────────────────────────────────────

test_that("table1: p_value = FALSE drops p_value column", {
  res <- mysterycall_table1(df, covariates = "gender",
                             stratify_by = "insurance",
                             p_value     = FALSE)
  expect_false("p_value" %in% names(res$table))
})

# ── Mixed covariates ───────────────────────────────────────────────────────────

test_that("table1: mixed categorical and continuous covariates work together", {
  res <- mysterycall_table1(df,
                             covariates   = c("gender", "academic", "wait_days"),
                             stratify_by  = "insurance",
                             cont_stats   = "median_iqr")
  expect_s3_class(res$table, "tbl_df")
  variables_in_table <- unique(res$table$variable)
  expect_true(all(c("gender", "academic", "wait_days") %in% variables_in_table))
})

# ── Error handling ─────────────────────────────────────────────────────────────

test_that("table1: stops when covariate column missing", {
  expect_error(
    mysterycall_table1(df, covariates = "nonexistent_col"),
    "nonexistent_col"
  )
})

test_that("table1: stops when stratify_by column missing", {
  expect_error(
    mysterycall_table1(df, covariates = "gender", stratify_by = "no_such_col"),
    "no_such_col"
  )
})

test_that("table1: stops on invalid digits", {
  expect_error(
    mysterycall_table1(df, covariates = "gender", digits = -1),
    "digits"
  )
})

# ── print method ──────────────────────────────────────────────────────────────

test_that("table1: print method runs without error", {
  res <- mysterycall_table1(df, covariates = "gender", stratify_by = "insurance")
  expect_output(print(res), "Table 1")
  expect_output(print(res), "Stratified by")
})

# ── Logical variable treated as categorical ────────────────────────────────────

test_that("table1: logical column treated as categorical (not continuous)", {
  df2 <- data.frame(accepted = c(TRUE, FALSE, TRUE, TRUE, FALSE, TRUE),
                    insurance = c("A", "A", "A", "B", "B", "B"))
  res <- mysterycall_table1(df2, covariates = "accepted",
                             stratify_by = "insurance")
  lvls <- res$table[res$table$variable == "accepted", "level", drop = TRUE]
  expect_setequal(lvls, c("FALSE", "TRUE"))
})
