test_that("parse_redcap_labels returns a data frame with expected columns", {
  raw <- c(scenario = "1, Straight couple | 2, Lesbian couple | 3, Single woman")
  result <- mysterycall_parse_redcap_labels(raw)
  expect_s3_class(result, "data.frame")
  expect_true(all(c("field", "code", "label") %in% names(result)))
})

test_that("parse_redcap_labels handles multiple named fields", {
  raw <- c(
    scenario = "1, A | 2, B",
    accepted = "0, No | 1, Yes"
  )
  result <- mysterycall_parse_redcap_labels(raw)
  expect_equal(nrow(result), 4L)
  expect_equal(unique(result$field), c("scenario", "accepted"))
})

test_that("parse_redcap_labels rejects non-character input", {
  expect_error(mysterycall_parse_redcap_labels(NULL), "character")
  expect_error(mysterycall_parse_redcap_labels(character(0)), "character")
})

test_that("parse_redcap_labels handles NA entries gracefully", {
  raw <- c(scenario = "1, A | 2, B", broken = NA_character_)
  result <- mysterycall_parse_redcap_labels(raw)
  expect_true(nrow(result) >= 2L)
})

test_that("parse_redcap_labels trims whitespace by default", {
  raw <- c(field1 = " 1 ,  Hello  |  2 ,  World  ")
  result <- mysterycall_parse_redcap_labels(raw)
  expect_equal(result$label, c("Hello", "World"))
})

test_that("parse_redcap_labels accepts custom separators", {
  raw <- c(q = "1; OptionA :: 2; OptionB")
  result <- mysterycall_parse_redcap_labels(raw, sep_choice = " :: ", sep_code = "; ")
  expect_equal(nrow(result), 2L)
  expect_equal(result$code, c("1", "2"))
})
