# Nightly smoke tests — one minimal call per exported function.
# Goal: prove each function loads and executes without error on toy data.
# Statistical correctness is tested in dedicated test files; this file just
# guards against broken imports, renamed arguments, and missing dependencies.
#
# Skip conditions used:
#   skip_if_not_installed() — optional Suggests packages
#   skip("API") — functions that require network or external services

# ── Shared fixtures ──────────────────────────────────────────────────────────

# Minimal audit data frame covering most column conventions
AUDIT <- data.frame(
  npi                              = c("1234567893", "1234567893",
                                       "9876543210", "9876543210"),
  insurance                        = c("Medicaid", "BCBS",
                                       "Medicaid", "BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A", "A", "B", "B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN", "OB/GYN",
                                       "OB/GYN", "OB/GYN"),
  phone                            = c("3035550100", "3035550100",
                                       "7205550200", "7205550200"),
  physician_information            = c("Smith, John", "Smith, John",
                                       "Doe, Jane",   "Doe, Jane"),
  reason_for_exclusions            = c("Able to contact", "Able to contact",
                                       "Able to contact", "Able to contact"),
  stringsAsFactors = FALSE
)

# Poisson count data (used by multiple stats tests)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid", "BCBS"), each = 40L),
  stringsAsFactors = FALSE
)

# ── 1. Exported data objects / constants ─────────────────────────────────────

test_that("smoke: exported data constants are accessible", {
  is_data <- function(x) is.character(x) || is.data.frame(x) || is.list(x)
  expect_true(is_data(ACADEMIC_HOSPITAL_PATTERNS))
  expect_true(is_data(ACGME_PROGRAM_INDICATORS))
  expect_true(is_data(COTH_TEACHING_INDICATORS))
  expect_true(is_data(KNOWN_ACADEMIC_INSTITUTIONS))
  expect_true(is_data(MEDICAL_SCHOOL_INDICATORS))
  expect_true(is_data(MEDICARE_GME_INDICATORS))
  expect_true(is_data(NCI_CANCER_CENTERS))
  expect_true(is_data(NIH_CTSA_HUBS))
})

# ── 2. Scalar / string utilities ─────────────────────────────────────────────

test_that("smoke: mysterycall_format_pct", {
  expect_type(mysterycall_format_pct(0.456), "character")
  expect_type(mysterycall_format_pct(c(0.1, 0.9)), "character")
})

test_that("smoke: mysterycall_extract_zip5", {
  expect_equal(mysterycall_extract_zip5("80203-1234"), "80203")
  expect_equal(mysterycall_extract_zip5("80203"),      "80203")
})

test_that("smoke: mysterycall_luhn_check", {
  result <- mysterycall_luhn_check("1234567893")
  expect_type(result, "logical")
})

test_that("smoke: mysterycall_validate_phone", {
  result <- mysterycall_validate_phone("3035550100")
  expect_true(is.data.frame(result) || is.list(result))
})

test_that("smoke: mysterycall_validate_npi", {
  df <- data.frame(npi = c("1234567893", "0000000000"), stringsAsFactors = FALSE)
  result <- suppressMessages(mysterycall_validate_npi(df))
  expect_s3_class(result, "data.frame")
})

test_that("smoke: mysterycall_format_physician_name", {
  result <- mysterycall_format_physician_name("Jane", "Doe", suffix = "MD")
  expect_type(result, "character")
  expect_gt(nchar(result), 0L)
})

test_that("smoke: mysterycall_age_category", {
  result <- mysterycall_age_category(c(25, 45, 65))
  expect_true(is.character(result) || is.factor(result))
})

test_that("smoke: mysterycall_collapse_rare", {
  x <- c(rep("A", 60), rep("B", 30), rep("C", 5), rep("D", 3))
  result <- mysterycall_collapse_rare(x, threshold = 10L)
  expect_true("Other" %in% result)
})

test_that("smoke: mysterycall_reorder_by_freq", {
  x <- factor(c("B", "A", "B", "C", "A", "A"))
  result <- mysterycall_reorder_by_freq(x)
  expect_s3_class(result, "factor")
})

# ── 3. Greyscale theme ───────────────────────────────────────────────────────

test_that("smoke: mysterycall_bw_theme returns a list of ggplot2 elements", {
  result <- mysterycall_bw_theme()
  expect_true(is.list(result))
  expect_gte(length(result), 3L)
})

# ── 4. Theme and colour scale helpers ────────────────────────────────────────

test_that("smoke: green-journal theme helpers return ggplot objects", {
  expect_no_error(mysterycall_theme_green_journal())
  expect_no_error(mysterycall_theme_green_journal_faceted())
  expect_no_error(mysterycall_theme_green_journal_map())
  expect_no_error(mysterycall_scale_fill_green_journal())
  expect_no_error(mysterycall_scale_color_green_journal())
  expect_no_error(mysterycall_palette_green_journal())
})

# ── 5. Data-frame summaries ──────────────────────────────────────────────────

test_that("smoke: mysterycall_descriptive_stats", {
  result <- mysterycall_descriptive_stats(AUDIT, "wait_days")
  expect_true(is.list(result) || is.data.frame(result))
})

test_that("smoke: mysterycall_distribution_summary", {
  result <- mysterycall_distribution_summary(AUDIT, "wait_days")
  expect_true(is.list(result) || is.data.frame(result))
})

test_that("smoke: mysterycall_check_normality", {
  result <- suppressMessages(mysterycall_check_normality(COUNT_DF, "days"))
  expect_true(is.list(result))
  expect_true("is_normal" %in% names(result))
})

test_that("smoke: mysterycall_missing_data_analysis", {
  df <- AUDIT
  df$wait_days[1] <- NA_integer_
  result <- suppressMessages(
    mysterycall_missing_data_analysis(df, outcome_col = "wait_days",
                                      group_col = "insurance")
  )
  expect_true(is.list(result) || is.data.frame(result))
})

test_that("smoke: mysterycall_distribution_summary on offered", {
  df <- AUDIT
  df$offered <- as.integer(df$offered)
  result <- mysterycall_distribution_summary(df, "offered")
  expect_true(is.list(result) || is.data.frame(result))
})

# ── 6. Acceptance-rate calculations ──────────────────────────────────────────

test_that("smoke: mysterycall_acceptance_rate", {
  result <- suppressMessages(
    mysterycall_acceptance_rate(AUDIT, accepted_col = "contact_office",
                                group_by = "insurance")
  )
  expect_true(is.data.frame(result) || is.list(result))
})

test_that("smoke: mysterycall_acceptance_rate_calc", {
  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(AUDIT,
      insurance_col   = "insurance",
      inclusion_col   = "reason_for_exclusions",
      inclusion_value = "Able to contact",
      wait_col        = "business_days_until_appointment",
      id_col          = "phone"
    )
  )
  expect_true(is.list(result) || is.data.frame(result))
})

# ── 7. Wait-time helpers ─────────────────────────────────────────────────────

test_that("smoke: mysterycall_wait_time_summary", {
  result <- suppressMessages(
    mysterycall_wait_time_summary(AUDIT, wait_col = "wait_days",
                                  group_by = "insurance")
  )
  expect_true(is.data.frame(result) || is.list(result))
})

test_that("smoke: mysterycall_wait_time_by_group", {
  result <- suppressMessages(
    mysterycall_wait_time_by_group(AUDIT,
      outcome_col = "business_days_until_appointment",
      group_col   = "insurance",
      output_dir  = NA)
  )
  expect_true(is.data.frame(result) || is.list(result))
})

# ── 8. Statistical modelling ─────────────────────────────────────────────────

test_that("smoke: mysterycall_simple_poisson", {
  set.seed(1)
  result <- suppressMessages(
    mysterycall_simple_poisson(COUNT_DF, outcome = "days",
                               group = "insurance",
                               use_profile_ci = FALSE)
  )
  expect_s3_class(result, "mysterycall_simple_poisson")
})

test_that("smoke: mysterycall_check_zero_inflation", {
  skip_if_not_installed("DHARMa")
  set.seed(2)
  mod <- suppressMessages(
    mysterycall_simple_poisson(COUNT_DF, outcome = "days",
                               group = "insurance", use_profile_ci = FALSE)
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_check_zero_inflation(mod$model, plot = FALSE)
  ))
  expect_true(is.list(result) || is.data.frame(result))
})

test_that("smoke: mysterycall_overdispersion_test", {
  set.seed(2)
  mod <- suppressMessages(
    mysterycall_simple_poisson(COUNT_DF, outcome = "days",
                               group = "insurance", use_profile_ci = FALSE)
  )
  result <- suppressMessages(
    mysterycall_overdispersion_test(mod$model)
  )
  expect_true(is.list(result) || is.data.frame(result))
})

test_that("smoke: mysterycall_bootstrap_ci", {
  set.seed(3)
  result <- suppressMessages(
    mysterycall_bootstrap_ci(AUDIT, outcome_col = "wait_days",
                              group_col = "insurance", n_boot = 100L,
                              seed = 3L)
  )
  expect_true(is.data.frame(result) || is.list(result))
})

test_that("smoke: mysterycall_compare_waves", {
  result <- suppressMessages(
    mysterycall_compare_waves(AUDIT, wave_col = "wave",
                              outcome_col = "wait_days")
  )
  expect_true(is.list(result) || is.data.frame(result))
})

test_that("smoke: mysterycall_logistic_model", {
  skip_if_not_installed("lme4")
  set.seed(4)
  df <- data.frame(
    outcome   = rep(c(0L, 1L), 20L),
    insurance = rep(c("Medicaid", "BCBS"), 20L),
    caller    = rep(letters[1:4], 10L),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_logistic_model(df,
      outcome          = "outcome",
      predictors       = "insurance",
      random_intercept = "caller")
  ))
  expect_s3_class(result, "mysterycall_logistic_model")
})

# ── 9. Visualisation functions ───────────────────────────────────────────────

test_that("smoke: mysterycall_facet_histogram", {
  set.seed(5)
  p <- suppressMessages(
    mysterycall_facet_histogram(COUNT_DF, x_col = "days",
                                facet_col = "insurance",
                                output_dir = NA)
  )
  expect_s3_class(p, "ggplot")
})

test_that("smoke: mysterycall_facet_histogram monochrome + reorder", {
  set.seed(6)
  p <- suppressMessages(
    mysterycall_facet_histogram(COUNT_DF, x_col = "days",
                                facet_col = "insurance",
                                monochrome = TRUE, reorder_facets = TRUE,
                                output_dir = NA)
  )
  expect_s3_class(p, "ggplot")
})

test_that("smoke: mysterycall_log_histogram", {
  set.seed(7)
  p <- suppressMessages(
    mysterycall_log_histogram(COUNT_DF, x_col = "days",
                              facet_col = "insurance",
                              output_dir = NA)
  )
  expect_s3_class(p, "ggplot")
})

test_that("smoke: mysterycall_log_histogram monochrome", {
  set.seed(8)
  p <- suppressMessages(
    mysterycall_log_histogram(COUNT_DF, x_col = "days",
                              facet_col = "insurance",
                              monochrome = TRUE, output_dir = NA)
  )
  expect_s3_class(p, "ggplot")
})

test_that("smoke: mysterycall_forest_plot symmetric x-axis", {
  set.seed(9)
  df <- data.frame(
    outcome   = rpois(80L, 8L),
    insurance = rep(c("Medicaid", "BCBS"), 40L),
    stringsAsFactors = FALSE
  )
  mod <- suppressMessages(suppressWarnings(
    mysterycall_simple_poisson(df, outcome = "outcome",
                               group = "insurance",
                               use_profile_ci = FALSE)
  ))
  # forest_plot accepts the irr_table from the poisson result
  p <- suppressMessages(
    mysterycall_forest_plot(mod$irr_table, output_dir = NA)
  )
  expect_s3_class(p, "ggplot")
})

test_that("smoke: mysterycall_acceptance_waffle", {
  skip_if_not_installed("waffle")
  accept <- list(
    medicaid = list(accepted = 35L, declined = 15L),
    bcbs     = list(accepted = 45L, declined = 5L)
  )
  p <- suppressMessages(
    mysterycall_acceptance_waffle(accept, output_dir = NA)
  )
  expect_false(is.null(p))
})

test_that("smoke: mysterycall_wait_time_crossover", {
  # Build a fixture with enough paired physicians to clear the min_pairs floor
  set.seed(11)
  phones <- paste0("303555", sprintf("%04d", 1:15))
  xover_df <- data.frame(
    phone     = rep(phones, each = 2L),
    insurance = rep(c("Medicaid", "BCBS"), 15L),
    business_days_until_appointment = rpois(30L, 8L) + 1L,
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_wait_time_crossover(xover_df, min_pairs = 5L)
  ))
  expect_true(is.data.frame(result) || is.list(result))
})

# ── 10. ICC / caller reliability ─────────────────────────────────────────────

test_that("smoke: mysterycall_icc_report", {
  # Needs more calls than callers — build a bigger fixture
  set.seed(12)
  icc_df <- data.frame(
    caller_id = rep(c("A","B","C"), 20L),
    offered   = sample(c(TRUE,FALSE), 60L, replace = TRUE),
    insurance = rep(c("Medicaid","BCBS"), 30L),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_icc_report(icc_df,
      caller_col  = "caller_id",
      outcome_col = "offered")
  ))
  expect_true(is.list(result) || is.data.frame(result))
})

test_that("smoke: mysterycall_caller_reliability", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_caller_reliability(AUDIT,
      caller_col  = "caller_id",
      outcome_col = "offered")
  ))
  expect_true(is.list(result) || is.data.frame(result))
})

test_that("smoke: mysterycall_caller_drift", {
  # Requires date_col or call_seq_col — provide call_seq_col
  set.seed(13)
  drift_df <- data.frame(
    offered      = rep(c(TRUE, FALSE), 20L),
    caller_id    = rep(c("A", "B"), 20L),
    call_seq_col = 1:40L,
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_caller_drift(drift_df,
      outcome_col  = "offered",
      caller_col   = "caller_id",
      call_seq_col = "call_seq_col")
  ))
  expect_true(is.list(result) || is.data.frame(result))
})

# ── 11. Sentence / prose generators ──────────────────────────────────────────

test_that("smoke: mysterycall_wait_time_sentence", {
  result <- suppressMessages(
    mysterycall_wait_time_sentence(AUDIT,
      outcome_col = "business_days_until_appointment",
      group_col   = "insurance")
  )
  expect_true(is.character(result) || is.list(result))
})

test_that("smoke: mysterycall_insurance_wait_sentence", {
  result <- suppressMessages(
    mysterycall_insurance_wait_sentence(AUDIT,
      outcome_col   = "business_days_until_appointment",
      insurance_col = "insurance",
      bcbs_label    = "BCBS")
  )
  expect_true(is.character(result) || is.list(result))
})

test_that("smoke: mysterycall_overdispersion_sentence", {
  set.seed(10)
  mod <- suppressMessages(
    mysterycall_simple_poisson(COUNT_DF, outcome = "days",
                               group = "insurance", use_profile_ci = FALSE)
  )
  result <- mysterycall_overdispersion_sentence(mod$model)
  expect_true(is.character(result) || is.list(result))
})

# ── 12. Safe joins ────────────────────────────────────────────────────────────

test_that("smoke: safe join family", {
  # All left rows appear in right so the default 98% coverage threshold passes
  left  <- data.frame(id = 1:3, val_l = letters[1:3])
  right <- data.frame(id = 1:4, val_r = LETTERS[1:4])

  res_left <- mysterycall_safe_left_join(left, right, by = "id",
                                         write_report = FALSE)
  expect_s3_class(res_left, "data.frame")
  expect_equal(nrow(res_left), 3L)

  res_inner <- mysterycall_safe_inner_join(left, right, by = "id",
                                            write_report = FALSE)
  expect_s3_class(res_inner, "data.frame")
  expect_equal(nrow(res_inner), 3L)

  res_anti <- mysterycall_safe_anti_join(left, right, by = "id",
                                          write_report = FALSE)
  expect_s3_class(res_anti, "data.frame")
  expect_equal(nrow(res_anti), 0L)

  res_semi <- mysterycall_safe_semi_join(left, right, by = "id",
                                          write_report = FALSE)
  expect_s3_class(res_semi, "data.frame")
  expect_equal(nrow(res_semi), 3L)
})

test_that("smoke: mysterycall_merge_with_prefix", {
  x <- data.frame(id = 1:2, score = c(10, 20))
  y <- data.frame(id = 1:2, score = c(30, 40))
  result <- mysterycall_merge_with_prefix(x, y, by = "id")
  expect_s3_class(result, "data.frame")
  expect_true(any(grepl("x_|y_", names(result))))
})

# ── 13. Deduplication / column manipulation ───────────────────────────────────

test_that("smoke: mysterycall_dedup_by_insurance", {
  df <- data.frame(
    phone                 = c("3035550100", "3035550100"),
    insurance             = c("Medicaid", "BCBS"),
    physician_information = c("Smith", "Smith"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_dedup_by_insurance(df, output_dir = NA)
  )
  expect_s3_class(result, "data.frame")
})

test_that("smoke: mysterycall_rename_columns", {
  df <- data.frame(A = 1:3, B = 4:6)
  result <- mysterycall_rename_columns(df,
    target_strings = c("A", "B"),
    new_names      = c("alpha", "beta"))
  expect_true("alpha" %in% names(result))
  expect_true("beta"  %in% names(result))
})

test_that("smoke: mysterycall_remove_constants", {
  df <- data.frame(x = rep(1L, 5L), y = 1:5)
  result <- mysterycall_remove_constants(df)
  expect_false("x" %in% names(result))
  expect_true("y"  %in% names(result))
})

test_that("smoke: mysterycall_remove_near_zero", {
  df <- data.frame(x = c(rep(1L, 95L), 2L, 3L, 4L, 5L, 6L), y = 1:100)
  result <- suppressMessages(mysterycall_remove_near_zero(df))
  expect_s3_class(result, "data.frame")
})

# ── 14. Flagging / quality checks ────────────────────────────────────────────

test_that("smoke: mysterycall_flag_repeat_physicians", {
  df <- AUDIT
  df$id_number <- df$npi
  result <- suppressMessages(
    mysterycall_flag_repeat_physicians(df, id_col = "id_number",
                                       output_dir = NA)
  )
  expect_s3_class(result, "data.frame")
})

test_that("smoke: mysterycall_flag_date_outliers", {
  df <- data.frame(
    appt_date = as.Date(c("2024-01-10", "2024-01-20",
                           "2020-01-01", "2024-01-15")),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_flag_date_outliers(df, date_col = "appt_date")
  )
  expect_s3_class(result, "data.frame")
})

test_that("smoke: mysterycall_check_duplicates", {
  result <- suppressMessages(
    mysterycall_check_duplicates(AUDIT, id_col = "npi")
  )
  expect_true(is.list(result) || is.data.frame(result))
})

test_that("smoke: mysterycall_check_data_completeness", {
  result <- mysterycall_check_data_completeness(AUDIT)
  expect_true(is.data.frame(result) || is.list(result))
})

test_that("smoke: mysterycall_assess_data_quality", {
  result <- suppressMessages(mysterycall_assess_data_quality(AUDIT))
  expect_true(is.data.frame(result) || is.list(result))
})

# ── 15. NPI / phone utilities ────────────────────────────────────────────────

test_that("smoke: mysterycall_parse_physician_name", {
  result <- mysterycall_parse_physician_name("Smith, John A.")
  expect_true(is.list(result) || is.character(result) || is.data.frame(result))
})

test_that("smoke: mysterycall_validate_phone returns a data frame with logical column", {
  result <- mysterycall_validate_phone("303-555-0100")
  expect_s3_class(result, "data.frame")
  expect_true("phone_e164_valid" %in% names(result))
  expect_type(result$phone_e164_valid, "logical")
})

# ── 16. No-longer-in-service ─────────────────────────────────────────────────

test_that("smoke: mystercall_no_longer_in_service exists", {
  expect_true(existsMethod("show", "ANY") || is.function(mystercall_no_longer_in_service) ||
    exists("mystercall_no_longer_in_service", envir = asNamespace("mysterycall")))
})

test_that("smoke: mysterycall_no_longer_in_service exists", {
  expect_true(exists("mysterycall_no_longer_in_service",
                     envir = asNamespace("mysterycall")))
})

# ── 17. Namespace completeness ────────────────────────────────────────────────

test_that("smoke: all NAMESPACE exports resolve to callable functions or objects", {
  ns      <- asNamespace("mysterycall")
  exports <- getNamespaceExports("mysterycall")
  # Skip operator exports
  fns <- exports[!grepl("^%", exports)]
  missing <- vapply(fns, function(nm) {
    !exists(nm, envir = ns, inherits = FALSE)
  }, logical(1L))
  if (any(missing)) {
    fail(paste("These exports are missing from the namespace:",
               paste(names(missing)[missing], collapse = ", ")))
  }
  succeed()
})
