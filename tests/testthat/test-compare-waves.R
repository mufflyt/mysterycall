make_wave_prop_df <- function() {
  data.frame(
    wave    = c("pre","pre","pre","post","post","post"),
    outcome = c(1, 0, 1,    1, 1, 0),
    stringsAsFactors = FALSE
  )
}

make_wave_cont_df <- function() {
  data.frame(
    wave    = c("pre","pre","pre","post","post","post"),
    outcome = c(3.1, 4.2, 2.8, 7.5, 8.1, 6.9),
    stringsAsFactors = FALSE
  )
}

test_that("returns a data.frame", {
  res <- mysterycall:::mysterycall_compare_waves(make_wave_prop_df(), "wave", "outcome")
  expect_s3_class(res, "data.frame")
})

test_that("proportion type has correct columns", {
  res <- mysterycall:::mysterycall_compare_waves(make_wave_prop_df(), "wave", "outcome", type = "proportion")
  expect_true(all(c("wave","n","n_accepted","rate","lower_ci","upper_ci","p_vs_ref") %in% names(res)))
})

test_that("continuous type has correct columns", {
  res <- mysterycall:::mysterycall_compare_waves(make_wave_cont_df(), "wave", "outcome", type = "continuous")
  expect_true(all(c("wave","n","mean","median","sd","q1","q3","p_vs_ref") %in% names(res)))
})

test_that("ref_wave attribute is set", {
  res <- mysterycall:::mysterycall_compare_waves(make_wave_prop_df(), "wave", "outcome")
  expect_false(is.null(attr(res, "ref_wave")))
})

test_that("ref_wave row has NA p_vs_ref", {
  df  <- make_wave_prop_df()
  res <- mysterycall:::mysterycall_compare_waves(df, "wave", "outcome", ref_wave = "pre")
  ref_row <- res[res$wave == "pre", ]
  expect_true(is.na(ref_row$p_vs_ref))
})

test_that("non-ref wave has numeric p_vs_ref", {
  df  <- make_wave_prop_df()
  res <- mysterycall:::mysterycall_compare_waves(df, "wave", "outcome", ref_wave = "pre")
  non_ref <- res[res$wave != "pre", ]
  expect_true(is.numeric(non_ref$p_vs_ref))
})

test_that("errors when fewer than 2 waves", {
  df <- data.frame(wave = c("pre","pre"), outcome = c(1, 0))
  expect_error(
    mysterycall:::mysterycall_compare_waves(df, "wave", "outcome"),
    "2 unique waves"
  )
})

test_that("group_col stratifies results by group x wave", {
  df <- data.frame(
    wave    = c("pre","pre","post","post","pre","pre","post","post"),
    outcome = c(1, 0, 1, 1, 0, 0, 0, 1),
    group   = c("F","F","F","F","M","M","M","M"),
    stringsAsFactors = FALSE
  )
  res <- mysterycall:::mysterycall_compare_waves(df, "wave", "outcome", group_col = "group")
  expect_true("group" %in% names(res))
  expect_equal(nrow(res), 4L)  # 2 waves x 2 groups
})

test_that("auto-detects proportion for 0/1 outcome", {
  df  <- make_wave_prop_df()
  res <- mysterycall:::mysterycall_compare_waves(df, "wave", "outcome", type = "auto")
  expect_true("rate" %in% names(res))
})

test_that("auto-detects continuous for non-binary outcome", {
  df  <- make_wave_cont_df()
  res <- mysterycall:::mysterycall_compare_waves(df, "wave", "outcome", type = "auto")
  expect_true("mean" %in% names(res))
})

test_that("default ref_wave is the first wave alphabetically", {
  df <- data.frame(
    wave    = c("wave2","wave2","wave1","wave1"),
    outcome = c(1, 0, 1, 1)
  )
  res <- mysterycall:::mysterycall_compare_waves(df, "wave", "outcome")
  expect_equal(attr(res, "ref_wave"), "wave1")
})
