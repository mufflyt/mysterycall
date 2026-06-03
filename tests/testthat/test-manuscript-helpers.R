# ── mysterycall:::mysterycall_sample_size_text ──────────────────────────────────────────────

test_that("sample_size_text: returns single character string", {
  res <- mysterycall:::mysterycall_sample_size_text(369)
  expect_type(res, "character")
  expect_length(res, 1L)
})

test_that("sample_size_text: contains sample size number", {
  res <- mysterycall:::mysterycall_sample_size_text(369)
  # Cochran n for N=369, e=0.05 → 192
  expect_match(res, "192")
})

test_that("sample_size_text: contains population size", {
  res <- mysterycall:::mysterycall_sample_size_text(369)
  expect_match(res, "369")
})

test_that("sample_size_text: mentions margin of error percentage", {
  res <- mysterycall:::mysterycall_sample_size_text(369, margin_of_error = 0.10)
  expect_match(res, "10%")
})

test_that("sample_size_text: larger population → larger required n", {
  n1 <- mysterycall_cochran_n(200)$n
  n2 <- mysterycall_cochran_n(10000)$n
  expect_gt(n2, n1)
})

# ── mysterycall_summarize_demographics ───────────────────────────────────────

test_that("summarize_demographics: returns single string", {
  df  <- data.frame(gender = c("Female","Male","Female"), setting = c("Academic","Private Practice","Academic"))
  res <- mysterycall_summarize_demographics(df, female_col = "gender", setting_col = "setting")
  expect_type(res, "character")
  expect_length(res, 1L)
})

test_that("summarize_demographics: N= is always present", {
  df  <- data.frame(x = 1:5)
  res <- mysterycall_summarize_demographics(df)
  expect_match(res, "N = 5")
})

test_that("summarize_demographics: female % correct", {
  df  <- data.frame(gender = c("Female", "Male", "Female", "Male"))
  res <- mysterycall_summarize_demographics(df, female_col = "gender")
  expect_match(res, "50.0% female")
})

test_that("summarize_demographics: logical female column works", {
  df  <- data.frame(is_female = c(TRUE, FALSE, TRUE, TRUE))
  res <- mysterycall_summarize_demographics(df, female_col = "is_female")
  expect_match(res, "75.0% female")
})

test_that("summarize_demographics: academic % correct", {
  df  <- data.frame(setting = c("Academic","Academic","Private Practice","Academic"))
  res <- mysterycall_summarize_demographics(df, setting_col = "setting")
  expect_match(res, "75.0% academic")
})

test_that("summarize_demographics: missing column is silently skipped", {
  df  <- data.frame(x = 1:5)
  res <- mysterycall_summarize_demographics(df, female_col = "nonexistent")
  expect_false(grepl("female", res))
})

test_that("summarize_demographics: non-data-frame errors", {
  expect_error(mysterycall_summarize_demographics(list()), "data frame")
})

# ── mysterycall_write_results_paragraph ──────────────────────────────────────

test_that("write_results_paragraph: errors on non-model input", {
  expect_error(
    mysterycall_write_results_paragraph(list(), "BCBS", "insurance"),
    "mysterycall_poisson_model"
  )
})

test_that("write_results_paragraph: errors when exposure not found", {
  skip_if_not_installed("lme4")
  set.seed(1)
  df <- data.frame(
    wait  = rpois(40, 14),
    ins   = rep(c("BCBS", "Medicaid"), 20),
    phys  = rep(paste0("D", 1:8), 5),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_poisson_model(df, "wait", "ins", "phys")
  expect_error(
    mysterycall_write_results_paragraph(res, "BCBS", "gender"),
    "No coefficient"
  )
})

test_that("write_results_paragraph: produces non-empty string for valid model", {
  skip_if_not_installed("lme4")
  set.seed(2)
  df <- data.frame(
    wait  = rpois(40, 14),
    ins   = rep(c("BCBS", "Medicaid"), 20),
    phys  = rep(paste0("D", 1:8), 5),
    stringsAsFactors = FALSE
  )
  res  <- mysterycall_poisson_model(df, "wait", "ins", "phys")
  para <- mysterycall_write_results_paragraph(res, "BCBS", "ins")
  expect_type(para, "character")
  expect_gt(nchar(para), 20L)
  expect_match(para, "Compared with BCBS")
})
