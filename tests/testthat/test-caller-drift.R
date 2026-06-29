test_that("returns a list of class mysterycall_caller_drift", {
  set.seed(42)
  n <- 120L
  df <- data.frame(
    call_date = seq(as.Date("2023-01-02"), by = "day", length.out = n),
    caller    = rep(c("Alice", "Bob", "Carol"), times = n / 3L),
    offered   = rbinom(n, 1L, 0.55),
    stringsAsFactors = FALSE
  )

  res <- mysterycall_caller_drift(df, date_col = "call_date", plot = FALSE)

  expect_true(is.list(res))
  expect_s3_class(res, "mysterycall_caller_drift")
  expect_named(res, c("calendar", "sequence", "plot", "sentence"))
})


test_that("calendar element contains required fields when date_col provided", {
  set.seed(1)
  n <- 90L
  df <- data.frame(
    call_date = seq(as.Date("2023-03-01"), by = "day", length.out = n),
    offered   = rbinom(n, 1L, 0.6),
    stringsAsFactors = FALSE
  )

  res <- mysterycall_caller_drift(df, date_col = "call_date", plot = FALSE)

  expect_false(is.null(res$calendar))
  rbp <- res$calendar$rate_by_period
  expect_true(is.data.frame(rbp))
  expect_true(all(c("period", "time_index", "rate", "n") %in% names(rbp)))
  expect_false(is.null(res$calendar$slope))
  expect_false(is.null(res$calendar$p_value))
  expect_false(is.null(res$calendar$sentence))
})


test_that("sequence element contains required fields when call_seq_col provided", {
  set.seed(2)
  n <- 90L
  df <- data.frame(
    caller  = rep(c("Alice", "Bob", "Carol"), each = n / 3L),
    offered = rbinom(n, 1L, 0.5),
    stringsAsFactors = FALSE
  )
  df$seq_num <- ave(seq_len(n), df$caller, FUN = seq_along)

  res <- mysterycall_caller_drift(df, call_seq_col = "seq_num", plot = FALSE)

  expect_false(is.null(res$sequence))
  rbs <- res$sequence$rate_by_seq
  expect_true(is.data.frame(rbs))
  expect_true(all(c("seq_bin", "mean_seq", "rate", "n") %in% names(rbs)))
  expect_false(is.null(res$sequence$slope))
  expect_false(is.null(res$sequence$p_value))
})


test_that("errors when neither date_col nor call_seq_col provided", {
  set.seed(3)
  df <- data.frame(offered = rbinom(50L, 1L, 0.5))

  expect_error(
    mysterycall_caller_drift(df, plot = FALSE),
    "At least one of date_col or call_seq_col must be provided"
  )
})


test_that("top-level sentence and calendar$sentence are character scalars", {
  set.seed(4)
  n <- 60L
  df <- data.frame(
    call_date = seq(as.Date("2023-06-01"), by = "day", length.out = n),
    offered   = rbinom(n, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  res <- mysterycall_caller_drift(df, date_col = "call_date", plot = FALSE)

  expect_true(is.character(res$sentence))
  expect_length(res$sentence, 1L)
  expect_true(nchar(res$sentence) > 0L)
  expect_true(is.character(res$calendar$sentence))
  expect_length(res$calendar$sentence, 1L)
})


test_that("plot is NULL when plot = FALSE", {
  set.seed(5)
  n <- 60L
  df <- data.frame(
    call_date = seq(as.Date("2023-01-02"), by = "day", length.out = n),
    offered   = rbinom(n, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  res <- mysterycall_caller_drift(df, date_col = "call_date", plot = FALSE)

  expect_null(res$plot)
})


test_that("calendar p_value is numeric and in [0, 1]", {
  set.seed(6)
  n <- 84L
  df <- data.frame(
    call_date = seq(as.Date("2023-01-02"), by = "day", length.out = n),
    offered   = rbinom(n, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  res <- mysterycall_caller_drift(df, date_col = "call_date", plot = FALSE)

  expect_true(is.numeric(res$calendar$p_value))
  expect_gte(res$calendar$p_value, 0)
  expect_lte(res$calendar$p_value, 1)
})


test_that("sequence p_value is numeric and in [0, 1]", {
  set.seed(7)
  n <- 90L
  df <- data.frame(
    caller  = rep(c("Alice", "Bob", "Carol"), each = n / 3L),
    offered = rbinom(n, 1L, 0.5),
    stringsAsFactors = FALSE
  )
  df$seq_num <- ave(seq_len(n), df$caller, FUN = seq_along)

  res <- mysterycall_caller_drift(df, call_seq_col = "seq_num", plot = FALSE)

  expect_true(is.numeric(res$sequence$p_value))
  expect_gte(res$sequence$p_value, 0)
  expect_lte(res$sequence$p_value, 1)
})


test_that("slope is numeric for both calendar and sequence", {
  set.seed(8)
  n <- 120L
  df <- data.frame(
    call_date = seq(as.Date("2023-01-02"), by = "day", length.out = n),
    caller    = rep(c("Alice", "Bob", "Carol"), times = n / 3L),
    offered   = rbinom(n, 1L, 0.55),
    stringsAsFactors = FALSE
  )
  df$seq_num <- ave(seq_len(n), df$caller, FUN = seq_along)

  res <- mysterycall_caller_drift(
    df,
    date_col     = "call_date",
    call_seq_col = "seq_num",
    plot         = FALSE
  )

  expect_true(is.numeric(res$calendar$slope))
  expect_length(res$calendar$slope, 1L)
  expect_true(is.numeric(res$sequence$slope))
  expect_length(res$sequence$slope, 1L)
})


test_that("warns when outcome_col contains non-binary values", {
  set.seed(9)
  n <- 60L
  df <- data.frame(
    call_date  = seq(as.Date("2023-01-02"), by = "day", length.out = n),
    continuous = rnorm(n, mean = 5, sd = 1),
    stringsAsFactors = FALSE
  )

  expect_warning(
    mysterycall_caller_drift(df, outcome_col = "continuous",
                             date_col = "call_date", plot = FALSE),
    "values other than 0/1"
  )
})


test_that("errors when date_col is not in data", {
  set.seed(10)
  df <- data.frame(offered = rbinom(40L, 1L, 0.5))

  expect_error(
    mysterycall_caller_drift(df, date_col = "nonexistent_date", plot = FALSE)
  )
})


test_that("errors when outcome_col is not in data", {
  set.seed(11)
  n <- 40L
  df <- data.frame(
    call_date = seq(as.Date("2023-01-02"), by = "day", length.out = n),
    offered   = rbinom(n, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_caller_drift(df, outcome_col = "missing_outcome",
                             date_col = "call_date", plot = FALSE)
  )
})


test_that("works with caller_col — derives sequence from date rank within callers", {
  set.seed(12)
  n <- 120L
  df <- data.frame(
    call_date = seq(as.Date("2023-01-02"), by = "day", length.out = n),
    caller    = rep(c("Alice", "Bob", "Carol"), times = n / 3L),
    offered   = rbinom(n, 1L, 0.55),
    stringsAsFactors = FALSE
  )

  res <- mysterycall_caller_drift(
    df,
    outcome_col = "offered",
    date_col    = "call_date",
    caller_col  = "caller",
    plot        = FALSE
  )

  expect_s3_class(res, "mysterycall_caller_drift")
  expect_false(is.null(res$sequence))
  expect_false(is.null(res$calendar))
  expect_true(is.data.frame(res$sequence$rate_by_seq))
})


test_that("calendar is NULL and sequence is populated when only call_seq_col provided", {
  set.seed(13)
  n <- 75L
  df <- data.frame(
    caller  = rep(c("Alice", "Bob", "Carol"), each = 25L),
    offered = rbinom(n, 1L, 0.5),
    stringsAsFactors = FALSE
  )
  df$seq_num <- ave(seq_len(n), df$caller, FUN = seq_along)

  res <- mysterycall_caller_drift(df, call_seq_col = "seq_num", plot = FALSE)

  expect_null(res$calendar)
  expect_false(is.null(res$sequence))
})


test_that("rate_by_period has correct column types and valid rate values", {
  set.seed(14)
  n <- 84L
  df <- data.frame(
    call_date = seq(as.Date("2023-02-01"), by = "day", length.out = n),
    offered   = rbinom(n, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  res <- mysterycall_caller_drift(df, date_col = "call_date", plot = FALSE)
  rbp <- res$calendar$rate_by_period

  expect_true(is.character(rbp$period))
  expect_true(is.integer(rbp$time_index))
  expect_true(is.numeric(rbp$rate))
  expect_true(is.integer(rbp$n))
  expect_true(all(rbp$rate >= 0 & rbp$rate <= 1))
  expect_true(all(rbp$n > 0L))
})
