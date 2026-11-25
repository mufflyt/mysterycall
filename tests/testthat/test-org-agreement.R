test_that("org tokens normalize legal suffixes and function words", {
  tokens <- mysterycall_org_tokens("University of Colorado Hospital, LLC")
  expect_true("UNIVERSITY" %in% tokens[[1]])
  expect_true("COLORADO" %in% tokens[[1]])
  expect_false("OF" %in% tokens[[1]])
  expect_false("LLC" %in% tokens[[1]])
})

test_that("meaningful token count retains distinctive words and drops generic words", {
  expect_equal(mysterycall_count_meaningful_org_tokens("University Medical Center"), 0L)
  expect_equal(mysterycall_count_meaningful_org_tokens("Rose Medical Center"), 1L)
})

test_that("weighted similarity downweights generic tokens", {
  distinctive <- mysterycall_weighted_token_similarity(
    "Rose Medical Center",
    "Rose Medical Center Denver"
  )
  generic_only <- mysterycall_weighted_token_similarity(
    "University Medical Center",
    "University Medical Center Hospital"
  )
  expect_gt(distinctive, generic_only)
  expect_gte(distinctive, 0)
  expect_lte(distinctive, 1)
})

test_that("org agreement accepts exact and meaningful substring matches", {
  expect_true(mysterycall_org_names_agree("Rose Medical Center", "Rose Medical Center"))
  expect_true(mysterycall_org_names_agree("Rose Medical Center Denver", "Rose Medical Center Denver Hospital"))
})

test_that("org agreement rejects generic-only substring matches and blanks", {
  expect_false(mysterycall_org_names_agree(
    "University Medical Center",
    "University Medical Center Hospital"
  ))
  expect_false(mysterycall_org_names_agree(NA_character_, "Rose Medical Center"))
  expect_false(mysterycall_org_names_agree("", "Rose Medical Center"))
})

test_that("org pairwise helpers broadcast scalars but refuse unsafe recycling", {
  expect_length(
    mysterycall_weighted_token_similarity("Rose Medical Center", c("Rose Medical", "Rose Hospital")),
    2L
  )
  expect_error(
    mysterycall_weighted_token_similarity(c("A", "B"), c("A", "B", "C")),
    "same length|broadcasting"
  )
  expect_error(
    mysterycall_org_names_agree(c("A", "B"), c("A", "B", "C")),
    "same length|broadcasting"
  )
})
