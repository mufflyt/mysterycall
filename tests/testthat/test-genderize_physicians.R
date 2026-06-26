library(testthat)
testthat::skip_if_not_installed("readr")
testthat::skip_if_not_installed("dplyr")
library(readr)
library(dplyr)

make_genderize_response <- function(payload, status = 200L) {
  body <- if (is.null(payload)) "null" else jsonlite::toJSON(payload, auto_unbox = TRUE, null = "null")
  structure(
    list(
      url = "https://api.genderize.io/",
      status_code = status,
      headers = list(),
      all_headers = list(),
      cookies = structure(list(), class = "set_cookies"),
      content = charToRaw(body),
      times = numeric()
    ),
    class = "response"
  )
}

expect_prediction_columns <- function(x) {
  expect_s3_class(x, "tbl_df")
  expect_setequal(colnames(x), c("first_name", "gender", "probability", "count"))
}

test_that("genderize_fetch deduplicates exact first names and trims whitespace", {
  queries <- list()
  fake_get <- function(url, query, ...) {
    queries <<- c(queries, list(query))
    values <- unname(unlist(query, use.names = FALSE))
    payload <- lapply(values, function(value) {
      list(name = value, gender = ifelse(value == "Alice", "female", "male"),
           probability = 0.91, count = 123L)
    })
    make_genderize_response(payload)
  }

  with_mocked_bindings(
    GET = fake_get,
    .package = "httr",
    code = {
      result <- mysterycall:::genderize_fetch(c(" Alice ", "Bob", "Alice", NA))
      expect_prediction_columns(result)
      expect_equal(nrow(result), 2L)
      expect_equal(sort(result$first_name), sort(c("Alice", "Bob")))
      expect_equal(queries[[1]][["name[0]"]], "Alice")
      expect_equal(queries[[1]][["name[1]"]], "Bob")
    }
  )
})

test_that("genderize_fetch handles single-object responses", {
  fake_get <- function(url, query, ...) {
    expect_equal(length(query), 1L)
    make_genderize_response(
      list(name = unname(query[[1]]), gender = "female", probability = 0.83, count = 55L)
    )
  }

  with_mocked_bindings(
    GET = fake_get,
    .package = "httr",
    code = {
      result <- mysterycall:::genderize_fetch("Eve")
      expect_prediction_columns(result)
      expect_equal(result$first_name, "Eve")
      expect_equal(result$gender, "female")
      expect_equal(result$probability, 0.83)
      expect_equal(result$count, 55L)
    }
  )
})

test_that("genderize_fetch surfaces HTTP and API errors", {
  with_mocked_bindings(
    GET = function(url, query, ...) make_genderize_response(list(error = "Too Many Requests"), status = 429L),
    .package = "httr",
    code = expect_error(mysterycall:::genderize_fetch("Ava"), "Genderize.io monthly quota exhausted")
  )

  with_mocked_bindings(
    GET = function(url, query, ...) make_genderize_response(list(error = "Daily limit reached")),
    .package = "httr",
    code = expect_error(mysterycall:::genderize_fetch("Mia"), "Genderize.io error: Daily limit reached")
  )
})

test_that("genderize_fetch batches requests to improve performance", {
  call_count <- 0L
  requested <- list()
  fake_get <- function(url, query, ...) {
    call_count <<- call_count + 1L
    requested <<- c(requested, list(unname(unlist(query, use.names = FALSE))))
    payload <- lapply(unname(unlist(query, use.names = FALSE)), function(name) {
      list(name = name, gender = "female", probability = 0.9, count = 10L)
    })
    make_genderize_response(payload)
  }

  with_mocked_bindings(
    GET = fake_get,
    .package = "httr",
    code = {
      first_names <- sprintf("Name%02d", 1:25)
      result <- mysterycall:::genderize_fetch(first_names)
      expect_equal(call_count, 3L)
      expect_equal(length(result$first_name), 25L)
      expect_true(all(vapply(requested, length, integer(1)) <= 10L))
    }
  )
})

# Helper: run mysterycall_genderize with genderize_fetch mocked.
# beepr::beep is only called when interactive() is TRUE (never in tests), so
# no beepr mock is needed; nesting two with_mocked_bindings caused the outer
# mock's on.exit cleanup frame to conflict in the full 153-file test suite.
with_genderize_mocks <- function(fake_genderize, expr) {
  with_mocked_bindings(
    genderize_fetch = fake_genderize,
    .package = "mysterycall",
    code = expr
  )
}

test_that("mysterycall_genderize produces enriched output and preserves original data", {
  input <- tibble::tibble(
    first_name = c("Ada", "Grace", "Ada", "Edsger", NA_character_),
    last_name  = c("Lovelace", "Hopper", "Smith", "Dijkstra", "Unknown")
  )
  predictions <- tibble::tibble(
    first_name  = c("Ada", "Grace", "Edsger"),
    gender      = c("female", "female", "male"),
    probability = c(0.99, 0.97, 0.88),
    count       = c(120L, 80L, 40L)
  )

  temp_dir <- file.path(tempdir(), paste0("genderize-", as.integer(stats::runif(1, 1, 1e6))))
  dir.create(temp_dir, showWarnings = FALSE)
  input_path <- file.path(temp_dir, "physicians.csv")
  readr::write_csv(input, input_path)

  with_genderize_mocks(function(first_names, ...) predictions, {
    result <- mysterycall_genderize(input_path, temp_dir)
    expect_equal(nrow(result), nrow(input))
    expect_setequal(colnames(result), c(colnames(input), colnames(predictions)[-1]))
    expect_equal(sum(!is.na(result$gender)), 4L)
    expect_equal(sum(is.na(result$gender)), 1L)
    output_files <- list.files(temp_dir, pattern = "^genderized_.*\\.csv$", full.names = TRUE)
    expect_true(length(output_files) == 1L)
    saved <- readr::read_csv(output_files[[1]], show_col_types = FALSE)
    expect_equal(result, saved)
  })
})

test_that("mysterycall_genderize maintains historical match rates", {
  input <- tibble::tibble(first_name = c("Alan", "Barbara", "Charlie", "Dana"))
  predictions <- tibble::tibble(
    first_name  = c("Alan", "Barbara", "Charlie"),
    gender      = c("male", "female", NA_character_),
    probability = c(0.91, 0.92, NA_real_),
    count       = c(50L, 65L, NA_integer_)
  )

  temp_dir <- tempfile("genderize-regression")
  dir.create(temp_dir)
  input_path <- file.path(temp_dir, "physicians.csv")
  readr::write_csv(input, input_path)

  with_genderize_mocks(function(first_names, ...) predictions, {
    result <- mysterycall_genderize(input_path, temp_dir)
    expect_gte(mean(!is.na(result$gender)), 0.5)
  })
})

test_that("mysterycall_genderize enforces data validation on blank or malformed names", {
  input <- tibble::tibble(
    first_name = c("", "  ", "Lynn", NA_character_),
    last_name  = c("One", "Two", "Three", "Four")
  )
  predictions <- tibble::tibble(
    first_name = "Lynn", gender = "female", probability = 0.95, count = 30L
  )

  temp_dir <- tempfile("genderize-validation")
  dir.create(temp_dir)
  input_path <- file.path(temp_dir, "physicians.csv")
  readr::write_csv(input, input_path)

  with_genderize_mocks(function(first_names, ...) predictions, {
    result <- mysterycall_genderize(input_path, temp_dir)
    trimmed <- trimws(result$first_name)
    blank_or_missing <- is.na(trimmed) | trimmed == ""
    expect_equal(sum(blank_or_missing), 3L)
    expect_equal(sum(!is.na(result$gender)), 1L)
    expect_true(all(result$gender[result$first_name %in% "Lynn"] == "female"))
  })
})

test_that("mysterycall_genderize output remains compatible with downstream case_when logic", {
  input <- tibble::tibble(first_name = paste0("Name", 1:10))
  predictions <- tibble::tibble(
    first_name  = paste0("Name", 1:10),
    gender      = rep(c("male", "female"), length.out = 10),
    probability = rep(c(0.8, 0.85), length.out = 10),
    count       = rep(20L, 10)
  )

  temp_dir <- tempfile("genderize-property")
  dir.create(temp_dir)
  input_path <- file.path(temp_dir, "physicians.csv")
  readr::write_csv(input, input_path)

  with_genderize_mocks(function(first_names, ...) predictions, {
    result <- mysterycall_genderize(input_path, temp_dir)
    genders <- na.omit(unique(result$gender))
    expect_true(all(genders %in% c("male", "female")))
  })
})

test_that("mysterycall_genderize provides required columns for handoff workflows", {
  input <- tibble::tibble(first_name = c("Ruth", "Ida"), external_id = c("X1", "X2"))
  predictions <- tibble::tibble(
    first_name  = c("Ruth", "Ida"),
    gender      = c("female", "female"),
    probability = c(0.89, 0.9),
    count       = c(44L, 32L)
  )

  temp_dir <- tempfile("genderize-handoff")
  dir.create(temp_dir)
  input_path <- file.path(temp_dir, "physicians.csv")
  readr::write_csv(input, input_path)

  with_genderize_mocks(function(first_names, ...) predictions, {
    result <- mysterycall_genderize(input_path, temp_dir)
    expect_true(all(c("probability", "count") %in% colnames(result)))
    expect_equal(result$external_id, input$external_id)
    expect_equal(result$gender, predictions$gender)
  })
})
