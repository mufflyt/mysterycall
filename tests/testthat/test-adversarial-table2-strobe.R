# devtools::test() already calls load_all() before tests — removed pkgload::load_all() call

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

.poi_fake_t2 <- function(aic = 120.5, phi = 1.3, n_dropped = 4L) {
  structure(list(
    irr_table = data.frame(
      term     = c("(Intercept)", "insMedicaid"),
      irr      = c(1.00, 1.28),
      ci_lower = c(NA, 1.05),
      ci_upper = c(NA, 1.56),
      p_value  = c(NA, 0.014),
      stringsAsFactors = FALSE
    ),
    overdispersion = phi,
    n_dropped = n_dropped,
    model = NULL, aic = aic, bic = aic + 5
  ), class = "mysterycall_poisson_model")
}

.nb_fake_t2 <- function() {
  structure(list(
    irr_table = data.frame(
      term     = c("(Intercept)", "insMedicaid"),
      irr      = c(1.00, 1.28),
      ci_lower = c(NA, 1.05),
      ci_upper = c(NA, 1.56),
      p_value  = c(NA, 0.014),
      stringsAsFactors = FALSE
    ),
    overdispersion = 2.8, theta = 1.5,
    n_dropped = 4L, model = NULL, aic = 118.3, bic = 124.1
  ), class = "mysterycall_nb_model")
}

.acc_data <- function() {
  set.seed(99)
  data.frame(
    ins            = rep(c("Medicaid", "BCBS"), each = 20),
    contact_office = c(rbinom(20, 1, 0.6), rbinom(20, 1, 0.8)),
    stringsAsFactors = FALSE
  )
}

fake_poi <- structure(list(
  irr_table = data.frame(
    term     = "insMedicaid",
    irr      = 1.28,
    ci_lower = 1.05,
    ci_upper = 1.56,
    p_value  = 0.014,
    stringsAsFactors = FALSE
  ),
  overdispersion = 1.3, n_dropped = 4L, model = NULL
), class = "mysterycall_poisson_model")

fake_nb <- structure(list(
  irr_table = data.frame(
    term     = "insMedicaid",
    irr      = 1.28,
    ci_lower = 1.05,
    ci_upper = 1.56,
    p_value  = 0.014,
    stringsAsFactors = FALSE
  ),
  overdispersion = 2.8, theta = 1.5, n_dropped = 4L, model = NULL
), class = "mysterycall_nb_model")

fake_no_ci <- structure(list(
  irr_table = data.frame(
    term     = "insMedicaid",
    irr      = 1.28,
    ci_lower = NA_real_,
    ci_upper = NA_real_,
    p_value  = 0.014,
    stringsAsFactors = FALSE
  ),
  overdispersion = 1.3, n_dropped = NULL, model = NULL
), class = "mysterycall_poisson_model")

# ---------------------------------------------------------------------------
# Block 1: mysterycall_table2() adversarial
# ---------------------------------------------------------------------------

test_that("table2: data not a data frame stops with informative error", {
  expect_error(
    mysterycall_table2("not a df", .poi_fake_t2(), "ins"),
    regexp = "data frame"
  )
})

test_that("table2: data = 42 stops with informative error", {
  expect_error(
    mysterycall_table2(42, .poi_fake_t2(), "ins"),
    regexp = "data frame"
  )
})

test_that("table2: group_col length > 1 stops", {
  expect_error(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), c("ins", "other")),
    regexp = "single character"
  )
})

test_that("table2: group_col missing from data stops", {
  expect_error(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "missing_col"),
    regexp = "missing_col"
  )
})

test_that("table2: accepted_col missing from data stops", {
  expect_error(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins",
                       accepted_col = "missing_accepted"),
    regexp = "missing_accepted"
  )
})

test_that("table2: model_result = plain list stops", {
  expect_error(
    mysterycall_table2(.acc_data(), list(x = 1), "ins"),
    regexp = "mysterycall_poisson_model"
  )
})

test_that("table2: model_result = character string stops", {
  expect_error(
    mysterycall_table2(.acc_data(), "model", "ins"),
    regexp = "mysterycall_poisson_model"
  )
})

test_that("table2: baseline_mean = 0 stops", {
  expect_error(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins",
                       baseline_mean = 0),
    regexp = "positive"
  )
})

test_that("table2: baseline_mean = -5 stops", {
  expect_error(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins",
                       baseline_mean = -5),
    regexp = "positive"
  )
})

test_that("table2: baseline_mean = 'twenty' stops", {
  expect_error(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins",
                       baseline_mean = "twenty"),
    regexp = "positive"
  )
})

# ---------------------------------------------------------------------------
# Block 2: mysterycall_table2() negative control
# ---------------------------------------------------------------------------

test_that("table2: basic call returns mysterycall_table2 class", {
  result <- suppressWarnings(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins")
  )
  expect_s3_class(result, "mysterycall_table2")
})

test_that("table2: result has acceptance, estimates, notes elements", {
  result <- suppressWarnings(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins")
  )
  expect_true(all(c("acceptance", "estimates", "notes") %in% names(result)))
})

test_that("table2: $acceptance has Group column", {
  result <- suppressWarnings(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins")
  )
  expect_true("Group" %in% names(result$acceptance))
})

test_that("table2: $acceptance has 'Accepted, n (%)' column", {
  result <- suppressWarnings(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins")
  )
  expect_true("Accepted, n (%)" %in% names(result$acceptance))
})

test_that("table2: $acceptance has '95% CI' column", {
  result <- suppressWarnings(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins")
  )
  expect_true("95% CI" %in% names(result$acceptance))
})

test_that("table2: $estimates has Term column", {
  result <- suppressWarnings(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins")
  )
  expect_true("Term" %in% names(result$estimates))
})

test_that("table2: $estimates has 'IRR 95% CI' column", {
  result <- suppressWarnings(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins")
  )
  expect_true("IRR 95% CI" %in% names(result$estimates))
})

test_that("table2: $notes is a non-empty character vector", {
  result <- suppressWarnings(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins")
  )
  expect_type(result$notes, "character")
  expect_gte(length(result$notes), 1L)
})

test_that("table2: baseline_mean = NULL → no Days Diff column in estimates", {
  result <- suppressWarnings(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins",
                       baseline_mean = NULL)
  )
  expect_false("Days Diff" %in% names(result$estimates))
})

test_that("table2: baseline_mean = 21 with exposure_col → Days Diff present", {
  result <- suppressWarnings(
    mysterycall_table2(.acc_data(), .poi_fake_t2(), "ins",
                       baseline_mean = 21,
                       exposure_col  = "ins")
  )
  expect_true("Days Diff" %in% names(result$estimates))
})

# ---------------------------------------------------------------------------
# Block 3: mysterycall_strobe_checklist() adversarial
# ---------------------------------------------------------------------------

test_that("strobe: model_result = plain list stops", {
  expect_error(
    mysterycall_strobe_checklist(list(x = 1)),
    regexp = "mysterycall_poisson_model"
  )
})

test_that("strobe: model_result = NULL stops", {
  expect_error(
    mysterycall_strobe_checklist(NULL),
    regexp = "mysterycall_poisson_model"
  )
})

test_that("strobe: model_result = character string stops", {
  expect_error(
    mysterycall_strobe_checklist("model"),
    regexp = "mysterycall_poisson_model"
  )
})

test_that("strobe: model_result = numeric stops", {
  expect_error(
    mysterycall_strobe_checklist(42),
    regexp = "mysterycall_poisson_model"
  )
})

# ---------------------------------------------------------------------------
# Block 4: mysterycall_strobe_checklist() negative control
# ---------------------------------------------------------------------------

test_that("strobe: returns data frame with 16 rows", {
  cl <- mysterycall_strobe_checklist(fake_poi)
  expect_s3_class(cl, "data.frame")
  expect_equal(nrow(cl), 16L)
})

test_that("strobe: class includes mysterycall_strobe_checklist and data.frame", {
  cl <- mysterycall_strobe_checklist(fake_poi)
  expect_true(inherits(cl, "mysterycall_strobe_checklist"))
  expect_true(inherits(cl, "data.frame"))
})

test_that("strobe: columns are Item, Category, Description, Status, Detail", {
  cl <- mysterycall_strobe_checklist(fake_poi)
  expect_equal(names(cl), c("Item", "Category", "Description", "Status", "Detail"))
})

test_that("strobe: all Status values are PASS, WARN, or FAIL", {
  cl <- mysterycall_strobe_checklist(fake_poi)
  expect_true(all(cl$Status %in% c("PASS", "WARN", "FAIL")))
})

test_that("strobe: item 7 is PASS for Poisson model", {
  cl <- mysterycall_strobe_checklist(fake_poi)
  expect_equal(cl$Status[cl$Item == 7L], "PASS")
})

test_that("strobe: item 7 is PASS for NB model", {
  cl <- mysterycall_strobe_checklist(fake_nb)
  expect_equal(cl$Status[cl$Item == 7L], "PASS")
})

test_that("strobe: item 9 is PASS for NB model (overdispersion addressed)", {
  cl <- mysterycall_strobe_checklist(fake_nb)
  expect_equal(cl$Status[cl$Item == 9L], "PASS")
})

test_that("strobe: item 9 is WARN for Poisson model without override", {
  cl <- mysterycall_strobe_checklist(fake_poi)
  expect_equal(cl$Status[cl$Item == 9L], "WARN")
})

test_that("strobe: item 10 is PASS when has_flow_diagram = TRUE", {
  cl <- mysterycall_strobe_checklist(fake_poi, has_flow_diagram = TRUE)
  expect_equal(cl$Status[cl$Item == 10L], "PASS")
})

test_that("strobe: item 10 is WARN when has_flow_diagram = FALSE", {
  cl <- mysterycall_strobe_checklist(fake_poi, has_flow_diagram = FALSE)
  expect_equal(cl$Status[cl$Item == 10L], "WARN")
})

test_that("strobe: item 15 is PASS when sensitivity_run = TRUE", {
  cl <- mysterycall_strobe_checklist(fake_poi, sensitivity_run = TRUE)
  expect_equal(cl$Status[cl$Item == 15L], "PASS")
})

test_that("strobe: item 15 is WARN when sensitivity_run = FALSE", {
  cl <- mysterycall_strobe_checklist(fake_poi, sensitivity_run = FALSE)
  expect_equal(cl$Status[cl$Item == 15L], "WARN")
})

test_that("strobe: item 12 is PASS when irr_table has non-NA ci_lower", {
  cl <- mysterycall_strobe_checklist(fake_poi)
  expect_equal(cl$Status[cl$Item == 12L], "PASS")
})

test_that("strobe: item 12 is FAIL when ci_lower all NA", {
  cl <- mysterycall_strobe_checklist(fake_no_ci)
  expect_equal(cl$Status[cl$Item == 12L], "FAIL")
})

test_that("strobe: item 11 is PASS when n_dropped not NULL", {
  cl <- mysterycall_strobe_checklist(fake_poi)
  expect_equal(cl$Status[cl$Item == 11L], "PASS")
})

test_that("strobe: item 11 is WARN when n_dropped is NULL", {
  cl <- mysterycall_strobe_checklist(fake_no_ci)
  expect_equal(cl$Status[cl$Item == 11L], "WARN")
})

test_that("strobe: item 14 is PASS when overdispersion present", {
  cl <- mysterycall_strobe_checklist(fake_poi)
  expect_equal(cl$Status[cl$Item == 14L], "PASS")
})

test_that("strobe: irr_reported = TRUE overrides FAIL → item 12 becomes PASS", {
  cl <- mysterycall_strobe_checklist(fake_no_ci, irr_reported = TRUE)
  expect_equal(cl$Status[cl$Item == 12L], "PASS")
})

test_that("strobe: items 1,2,3,4,5,16 are always WARN", {
  cl <- mysterycall_strobe_checklist(fake_poi)
  always_warn_items <- c(1L, 2L, 3L, 4L, 5L, 16L)
  statuses <- cl$Status[cl$Item %in% always_warn_items]
  expect_true(all(statuses == "WARN"))
})
