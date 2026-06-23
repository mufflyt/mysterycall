suppressPackageStartupMessages({
  pkgload::load_all("/Users/tylermuffly/mysterycall", quiet = TRUE)
})

# ── shared fake model helpers ────────────────────────────────────────────────

.fake_poi <- function(aic = 120, bic = 125, phi = 1.3) {
  irr <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    irr      = c(1.00, 1.28),
    ci_lower = c(NA,   1.05),
    ci_upper = c(NA,   1.56),
    p_value  = c(NA,   0.014),
    stringsAsFactors = FALSE
  )
  structure(
    list(irr_table = irr, overdispersion = phi,
         theta = NA_real_,   # explicit NA: as.numeric(NULL)=numeric(0) breaks data.frame()
         model = NULL, aic = aic, bic = bic, n_dropped = 2L),
    class = "mysterycall_poisson_model"
  )
}

.fake_nb <- function(aic = 118, bic = 124, phi = 2.8, theta = 1.5) {
  irr <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    irr      = c(1.00, 1.28),
    ci_lower = c(NA,   1.05),
    ci_upper = c(NA,   1.56),
    p_value  = c(NA,   0.014),
    stringsAsFactors = FALSE
  )
  structure(
    list(irr_table = irr, overdispersion = phi, theta = theta,
         model = NULL, aic = aic, bic = bic, n_dropped = 2L),
    class = "mysterycall_nb_model"
  )
}

# ── Block 1: mysterycall_sensitivity() — adversarial ─────────────────────────

test_that("non-data-frame data rejects", {
  expect_error(
    mysterycall_sensitivity("not_a_df", "wait", "ins", "phys"),
    regexp = "data frame"
  )
})

test_that("outcome not in names(data) rejects", {
  df <- data.frame(wait = 1, ins = "A", phys = "D1", stringsAsFactors = FALSE)
  expect_error(
    mysterycall_sensitivity(df, "WRONG", "ins", "phys"),
    regexp = "outcome"
  )
})

test_that("random_intercept not in names(data) rejects", {
  df <- data.frame(wait = 1, ins = "A", phys = "D1", stringsAsFactors = FALSE)
  expect_error(
    mysterycall_sensitivity(df, "wait", "ins", "WRONG"),
    regexp = "random_intercept"
  )
})

test_that("predictors empty character vector rejects", {
  df <- data.frame(wait = 1, ins = "A", phys = "D1", stringsAsFactors = FALSE)
  expect_error(
    mysterycall_sensitivity(df, "wait", character(0), "phys"),
    regexp = "predictors"
  )
})

test_that("baseline_mean = 0 rejects", {
  df <- data.frame(wait = 1, ins = "A", phys = "D1", stringsAsFactors = FALSE)
  expect_error(
    mysterycall_sensitivity(df, "wait", "ins", "phys", baseline_mean = 0),
    regexp = "positive"
  )
})

test_that("subset_var not in names(data) warns and skips stratification", {
  skip_if_not_installed("lme4")
  set.seed(1)
  df <- data.frame(
    wait = rpois(40, 18),
    ins  = rep(c("Medicaid", "BCBS"), 20),
    phys = rep(paste0("Dr", 1:10), each = 4),
    stringsAsFactors = FALSE
  )
  expect_warning(
    suppressMessages(
      mysterycall_sensitivity(df, "wait", "ins", "phys",
                              subset_var = "nonexistent", family = "poisson")
    ),
    regexp = "subset_var"
  )
})

test_that("subset < 10 rows warns and is skipped", {
  skip_if_not_installed("lme4")
  set.seed(2)
  df <- data.frame(
    wait    = rpois(50, 18),
    ins     = rep(c("Medicaid", "BCBS"), 25),
    setting = c(rep("Academic", 48), "Tiny", "Tiny"),
    phys    = rep(paste0("Dr", 1:10), each = 5),
    stringsAsFactors = FALSE
  )
  expect_warning(
    suppressMessages(
      mysterycall_sensitivity(df, "wait", "ins", "phys",
                              subset_var = "setting", family = "poisson")
    ),
    regexp = "< 10 rows"
  )
})

# ── Block 2: mysterycall_sensitivity() — negative control ────────────────────

test_that("full sample always included in subsets_run", {
  skip_if_not_installed("lme4")
  set.seed(3)
  df <- data.frame(
    wait = rpois(40, 18),
    ins  = rep(c("Medicaid", "BCBS"), 20),
    phys = rep(paste0("Dr", 1:10), each = 4),
    stringsAsFactors = FALSE
  )
  res <- suppressWarnings(suppressMessages(
    mysterycall_sensitivity(df, "wait", "ins", "phys", family = "poisson")
  ))
  expect_true("Full sample" %in% res$subsets_run)
})

test_that("exclude_zeros = TRUE on data with no zeros equals full sample", {
  skip_if_not_installed("lme4")
  set.seed(4)
  df <- data.frame(
    wait = rpois(40, 18) + 1L,
    ins  = rep(c("Medicaid", "BCBS"), 20),
    phys = rep(paste0("Dr", 1:10), each = 4),
    stringsAsFactors = FALSE
  )
  res <- suppressWarnings(suppressMessages(
    mysterycall_sensitivity(df, "wait", "ins", "phys",
                            exclude_zeros = TRUE, family = "poisson")
  ))
  expect_equal(sort(res$subsets_run), sort(c("Full sample", "Exclude zeros")))
})

test_that("family = 'poisson' gives model_type 'poisson' in table", {
  skip_if_not_installed("lme4")
  set.seed(5)
  df <- data.frame(
    wait = rpois(40, 18),
    ins  = rep(c("Medicaid", "BCBS"), 20),
    phys = rep(paste0("Dr", 1:10), each = 4),
    stringsAsFactors = FALSE
  )
  res <- suppressWarnings(suppressMessages(
    mysterycall_sensitivity(df, "wait", "ins", "phys", family = "poisson")
  ))
  non_na <- res$table[!is.na(res$table$model_type), ]
  expect_true(all(non_na$model_type == "poisson"))
})

test_that("stratified subset_var adds subset rows beyond full sample", {
  skip_if_not_installed("lme4")
  set.seed(6)
  df <- data.frame(
    wait    = rpois(80, 18),
    ins     = rep(c("Medicaid", "BCBS"), 40),
    setting = rep(c("Academic", "Private", "Academic", "Private"), 20),
    phys    = rep(paste0("Dr", 1:20), each = 4),
    stringsAsFactors = FALSE
  )
  res <- suppressWarnings(suppressMessages(
    mysterycall_sensitivity(df, "wait", "ins", "phys",
                            subset_var = "setting", family = "poisson")
  ))
  # $subsets_run only lists converged fits; $table holds all attempted subsets
  subset_names <- unique(res$table$subset_name)
  expect_true("Full sample" %in% subset_names)
  expect_true("Academic"    %in% subset_names)
  expect_true("Private"     %in% subset_names)
})

test_that("baseline_mean supplied adds days_diff column to table", {
  skip_if_not_installed("lme4")
  set.seed(7)
  df <- data.frame(
    wait = rpois(40, 18),
    ins  = rep(c("Medicaid", "BCBS"), 20),
    phys = rep(paste0("Dr", 1:10), each = 4),
    stringsAsFactors = FALSE
  )
  res <- suppressWarnings(suppressMessages(
    mysterycall_sensitivity(df, "wait", "ins", "phys",
                            baseline_mean = 18, family = "poisson")
  ))
  expect_true("days_diff" %in% names(res$table))
})

test_that("returned object has required list elements", {
  skip_if_not_installed("lme4")
  set.seed(8)
  df <- data.frame(
    wait = rpois(40, 18),
    ins  = rep(c("Medicaid", "BCBS"), 20),
    phys = rep(paste0("Dr", 1:10), each = 4),
    stringsAsFactors = FALSE
  )
  res <- suppressWarnings(suppressMessages(
    mysterycall_sensitivity(df, "wait", "ins", "phys", family = "poisson")
  ))
  expect_true(all(c("table", "models", "subsets_run", "family") %in% names(res)))
  expect_s3_class(res, "mysterycall_sensitivity")
})

# ── Block 3: mysterycall_model_comparison_table() — adversarial ──────────────

test_that("non-list input rejects", {
  expect_error(
    mysterycall_model_comparison_table("not_a_list"),
    regexp = "named list"
  )
})

test_that("unnamed list rejects", {
  expect_error(
    mysterycall_model_comparison_table(list(.fake_poi(), .fake_nb())),
    regexp = "named list"
  )
})

test_that("single-element list rejects", {
  expect_error(
    mysterycall_model_comparison_table(list(A = .fake_poi())),
    regexp = "named list"
  )
})

test_that("list with non-model element rejects", {
  expect_error(
    mysterycall_model_comparison_table(list(A = .fake_poi(), B = list(x = 1))),
    regexp = "mysterycall_poisson_model"
  )
})

test_that("invalid criterion string rejects via match.arg", {
  expect_error(
    mysterycall_model_comparison_table(
      list(A = .fake_poi(), B = .fake_nb()),
      criterion = "log_likelihood"
    )
  )
})

# ── Block 4: mysterycall_model_comparison_table() — negative control ─────────

test_that("lower AIC model is marked as winner with criterion='aic'", {
  tbl <- mysterycall_model_comparison_table(
    list(Poisson = .fake_poi(aic = 150, bic = 160),
         NB      = .fake_nb(aic = 120, bic = 130)),
    criterion = "aic"
  )
  expect_equal(attr(tbl, "winner"), "NB")
  expect_equal(tbl$Winner[tbl$Model == "NB"], "*")
  expect_equal(tbl$Winner[tbl$Model == "Poisson"], "")
})

test_that("lower BIC model is winner when criterion='bic'", {
  tbl <- mysterycall_model_comparison_table(
    list(A = .fake_poi(aic = 100, bic = 200),
         B = .fake_nb(aic = 110, bic = 115)),
    criterion = "bic"
  )
  expect_equal(attr(tbl, "winner"), "B")
})

test_that("Poisson model has NA theta in output", {
  tbl <- mysterycall_model_comparison_table(
    list(P = .fake_poi(), N = .fake_nb())
  )
  poi_theta <- tbl$Theta[tbl$Model == "P"]
  expect_true(is.na(poi_theta))
})

test_that("NB model has non-NA theta in output", {
  tbl <- mysterycall_model_comparison_table(
    list(P = .fake_poi(), N = .fake_nb(theta = 2.0))
  )
  nb_theta <- tbl$Theta[tbl$Model == "N"]
  expect_false(is.na(nb_theta))
})

test_that("delta AIC is 0 for winner and positive for loser", {
  tbl <- mysterycall_model_comparison_table(
    list(Best   = .fake_poi(aic = 100, bic = 110),
         Worse  = .fake_nb(aic = 115, bic = 120)),
    criterion = "aic"
  )
  winner_delta <- as.numeric(tbl[["ΔAIC"]][tbl$Model == "Best"])
  loser_delta  <- as.numeric(tbl[["ΔAIC"]][tbl$Model == "Worse"])
  expect_equal(winner_delta, 0, tolerance = 1e-6)
  expect_true(loser_delta > 0)
})

test_that("output has all required columns", {
  tbl <- mysterycall_model_comparison_table(
    list(A = .fake_poi(), B = .fake_nb())
  )
  expected_cols <- c("Model", "Family", "N", "Params",
                     "AIC", "BIC", "ΔAIC", "ΔBIC",
                     "Phi (Pearson)", "Theta", "Winner")
  expect_true(all(expected_cols %in% names(tbl)))
})

test_that("Family column correctly labels Poisson vs NB rows", {
  tbl <- mysterycall_model_comparison_table(
    list(P = .fake_poi(), N = .fake_nb())
  )
  expect_equal(tbl$Family[tbl$Model == "P"], "Poisson")
  expect_equal(tbl$Family[tbl$Model == "N"], "Negative Binomial")
})
