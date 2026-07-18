# Tests for multi-category / multi-response call outcomes (R/call_outcomes.R)

test_that("multiresponse_tabulate computes per-option prevalence with Wilson CIs", {
  calls <- data.frame(
    options = c("ibuprofen;lidocaine", "ibuprofen", "", "misoprostol;ibuprofen"),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_multiresponse_tabulate(calls, "options")
  expect_s3_class(res, "mysterycall_multiresponse")

  ibu <- res$prevalence[res$prevalence$option == "ibuprofen", ]
  expect_equal(ibu$n, 3L)          # named in 3 of 4 responding calls
  expect_equal(ibu$total, 4L)      # empty string still counts as responding
  expect_equal(ibu$prevalence, 0.75)
  expect_true(ibu$ci_lower < 0.75 && ibu$ci_upper > 0.75)

  # sorted by descending prevalence
  expect_equal(res$prevalence$option[1], "ibuprofen")
})

test_that("multiresponse summary and co-occurrence are correct", {
  calls <- data.frame(
    options = c("a;b", "a", "b;c", "a;b;c"),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_multiresponse_tabulate(calls, "options", sort = FALSE)
  expect_equal(res$summary$n_responding, 4L)
  expect_equal(res$summary$mean_options_per_call, mean(c(2, 1, 2, 3)))

  co <- res$cooccurrence
  expect_equal(co["a", "a"], 3L)   # a named in 3 calls
  expect_equal(co["a", "b"], 2L)   # a & b together in calls 1 and 4
  expect_equal(co["b", "c"], 2L)   # b & c together in calls 3 and 4
})

test_that("NA is non-responding but empty string is responding-with-none", {
  calls <- data.frame(
    options = c("a;b", NA, "", "a"),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_multiresponse_tabulate(calls, "options")
  expect_equal(res$summary$n_calls, 4L)
  expect_equal(res$summary$n_responding, 3L)          # NA excluded
  a <- res$prevalence[res$prevalence$option == "a", ]
  expect_equal(a$total, 3L)                            # denominator = responding
  expect_equal(a$n, 2L)
})

test_that("multiresponse supports grouping", {
  calls <- data.frame(
    options = c("a;b", "a", "b", "a;b"),
    region  = c("W", "W", "E", "E"),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_multiresponse_tabulate(calls, "options", group_var = "region")
  expect_false(is.null(res$by_group))
  expect_true("group" %in% names(res$by_group))
  expect_setequal(unique(res$by_group$group), c("W", "E"))
})

test_that("classify_call_outcome maps dispositions to the taxonomy", {
  raw <- c(
    "Appointment offered in 12 days",
    "Needs a referral first",
    "Won't give info over the phone",
    "No answer after 3 tries",
    "Must verify insurance ID number",
    "Records required before scheduling",
    "Not accepting new patients",
    "Some unrecognised note"
  )
  out <- mysterycall_classify_call_outcome(raw)
  expect_s3_class(out, "factor")
  expect_equal(as.character(out[1]), "appointment_offered")
  expect_equal(as.character(out[2]), "referral_required")
  expect_equal(as.character(out[3]), "gatekeeping_no_info")
  expect_equal(as.character(out[4]), "not_reached")
  expect_equal(as.character(out[5]), "insurance_verification_required")
  expect_equal(as.character(out[6]), "records_required")
  expect_equal(as.character(out[7]), "new_patient_restriction")
  expect_equal(as.character(out[8]), "other")
})

test_that("classify_call_outcome honours a custom mapping and NA passthrough", {
  out <- mysterycall_classify_call_outcome(
    c("PRICE quoted", "walk in", NA),
    mapping = list(priced = "price", walk_in = "walk")
  )
  expect_equal(as.character(out[1]), "priced")
  expect_equal(as.character(out[2]), "walk_in")
  expect_true(is.na(out[3]))
  expect_equal(levels(out), c("priced", "walk_in", "other"))
})

test_that("outcome_gradient returns ordered proportions with cumulative", {
  df <- data.frame(
    access = c("phone", "phone", "in_person", "must_establish", "phone",
               "in_person", "must_establish", "must_establish")
  )
  g <- mysterycall_outcome_gradient(
    df, "access", levels = c("phone", "in_person", "must_establish")
  )
  expect_s3_class(g, "tbl_df")
  expect_equal(g$level, c("phone", "in_person", "must_establish"))
  expect_equal(g$n, c(3L, 2L, 3L))
  expect_equal(g$proportion, c(0.375, 0.25, 0.375))
  expect_equal(g$cumulative_prop[3], 1)     # cumulative reaches 1
  expect_true(all(g$ci_lower <= g$proportion & g$ci_upper >= g$proportion))
})

test_that("outcome_gradient supports grouping", {
  df <- data.frame(
    tier = c("low", "high", "low", "high"),
    grp  = c("A", "A", "B", "B")
  )
  g <- mysterycall_outcome_gradient(df, "tier", levels = c("low", "high"),
                                    group_var = "grp")
  expect_true("group" %in% names(g))
  expect_equal(nrow(g), 4L)                 # 2 levels x 2 groups
})

test_that("ordinal_model returns proportional-odds ORs", {
  skip_if_not_installed("MASS")
  set.seed(1)
  # build a clear ordinal gradient driven by the predictor
  n <- 150
  x <- rbinom(n, 1, 0.5)
  lin <- 1.2 * x + rnorm(n)
  y <- cut(lin, breaks = quantile(lin, c(0, .33, .66, 1)),
           labels = c("phone", "in_person", "must_establish"),
           include.lowest = TRUE, ordered_result = TRUE)
  df <- data.frame(access = y, medicaid = x)
  res <- mysterycall_ordinal_model(df, "access", "medicaid")
  expect_s3_class(res, "tbl_df")
  expect_true("or" %in% names(res))
  expect_equal(res$term, "medicaid")
  expect_true(res$or > 0)
})

test_that("print and as.data.frame methods work", {
  calls <- data.frame(options = c("a;b", "a", "b"), stringsAsFactors = FALSE)
  res <- mysterycall_multiresponse_tabulate(calls, "options")
  expect_output(print(res), "multiresponse")
  df <- as.data.frame(res)
  expect_s3_class(df, "data.frame")
  expect_true("prevalence" %in% names(df))
})
