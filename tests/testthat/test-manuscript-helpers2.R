# ── mysterycall:::mysterycall_methods_paragraph ────────────────────────────────────────────

test_that("methods_paragraph: returns single character string", {
  res <- mysterycall:::mysterycall_methods_paragraph(300, 25, c("Otolaryngology"))
  expect_type(res, "character")
  expect_length(res, 1L)
})

test_that("methods_paragraph: contains physician count", {
  res <- mysterycall:::mysterycall_methods_paragraph(300, 25, "Otolaryngology")
  expect_match(res, "300")
})

test_that("methods_paragraph: contains city count", {
  res <- mysterycall:::mysterycall_methods_paragraph(300, 25, "Otolaryngology")
  expect_match(res, "25")
})

test_that("methods_paragraph: multiple specialties joined with 'and'", {
  res <- mysterycall:::mysterycall_methods_paragraph(300, 25, c("Otolaryngology","Urology","Dermatology"))
  expect_match(res, "and Dermatology")
})

test_that("methods_paragraph: insurance types appear in paragraph", {
  res <- mysterycall:::mysterycall_methods_paragraph(300, 25, "ENT",
                                        insurance_types = c("Medicaid","BCBS"))
  expect_match(res, "Medicaid")
  expect_match(res, "BCBS")
})

test_that("methods_paragraph: custom outcome label", {
  res <- mysterycall:::mysterycall_methods_paragraph(300, 25, "ENT",
                                        outcome = "wait time in days")
  expect_match(res, "wait time in days")
})

test_that("methods_paragraph: invalid n_physicians errors", {
  expect_error(mysterycall:::mysterycall_methods_paragraph(0, 25, "ENT"), "positive")
})

# ── mysterycall_format_results_table ─────────────────────────────────────────

make_irr_tbl <- function() {
  data.frame(
    term     = c("(Intercept)", "insuranceMedicaid", "genderMale"),
    irr      = c(1.00, 1.38, 0.95),
    ci_lower = c(0.90, 1.10, 0.80),
    ci_upper = c(1.10, 1.73, 1.13),
    p_value  = c(0.01, 0.005, 0.620),
    stringsAsFactors = FALSE
  )
}

test_that("format_results_table: returns data frame", {
  res <- mysterycall_format_results_table(make_irr_tbl())
  expect_s3_class(res, "data.frame")
})

test_that("format_results_table: intercept excluded by default", {
  res <- mysterycall_format_results_table(make_irr_tbl())
  expect_false("(Intercept)" %in% res$Term)
})

test_that("format_results_table: intercept included when requested", {
  res <- mysterycall_format_results_table(make_irr_tbl(), include_intercept = TRUE)
  expect_true("(Intercept)" %in% res$Term)
})

test_that("format_results_table: has expected column names", {
  res <- mysterycall_format_results_table(make_irr_tbl())
  expect_true(all(c("Term", "IRR", "95% CI", "p-value") %in% names(res)))
})

test_that("format_results_table: p < 0.001 shown as '< 0.001'", {
  tbl <- make_irr_tbl()
  tbl$p_value[[2L]] <- 0.0001
  res <- mysterycall_format_results_table(tbl)
  expect_equal(res[res$Term == "insuranceMedicaid", "p-value"], "< 0.001")
})

test_that("format_results_table: significant_rows attribute set", {
  res <- mysterycall_format_results_table(make_irr_tbl())
  expect_true(!is.null(attr(res, "significant_rows")))
  expect_true(length(attr(res, "significant_rows")) > 0L)
})

test_that("format_results_table: accepts mysterycall_poisson_model", {
  skip_if_not_installed("lme4")
  set.seed(1L)
  df <- data.frame(
    wait = rpois(40, 14),
    ins  = rep(c("BCBS","Medicaid"), 20),
    phys = rep(paste0("D", 1:8), 5),
    stringsAsFactors = FALSE
  )
  mod <- mysterycall_poisson_model(df, "wait", "ins", "phys")
  res <- mysterycall_format_results_table(mod)
  expect_s3_class(res, "data.frame")
})
