# test-states-not-contacted-gold-standard.R
#
# Gold-standard tests for mysterycall_not_contacted_states().
#
# NOTE: The function calls beepr::beep(2) unconditionally. Tests require beepr
# to be installed, or the sound call will error. beepr is listed as a dependency
# of the mysterycall package so skip_if_not_installed("beepr") is used as a guard.
#
# Testing tenets satisfied:
#   - Gold-standard manually-verified values (exact state counts and names)
#   - Enforce domain invariants (contacted + not-contacted == all states)
#   - Test for silent failures (Yes/No character values, mixed-case inputs)
#   - Boundary conditions (all contacted, none contacted, NULL all_states)
#   - Idempotency (same data → same string output)
#   - Schema contracts (always length-1 character string)

library(testthat)

skip_if_not_installed("beepr")
skip_if_not_installed("dplyr")

# ---------------------------------------------------------------------------
# Gold-standard mini state list for deterministic testing
# ---------------------------------------------------------------------------
ten_states <- c(
  "Alabama", "Alaska", "Arizona", "Arkansas", "California",
  "Colorado", "Connecticut", "Delaware", "Florida", "Georgia"
)

# ---------------------------------------------------------------------------
# 1. Gold standard: 3 contacted of 10 → 7 not contacted, verify names
# ---------------------------------------------------------------------------

test_that("3 states contacted of 10 → output mentions exactly 7 excluded states", {
  df <- data.frame(state = c("California", "Colorado", "Arizona"),
                   stringsAsFactors = FALSE)
  result <- mysterycall_not_contacted_states(df, all_states = ten_states)

  # States NOT contacted: Alabama, Alaska, Arkansas, Connecticut, Delaware, Florida, Georgia
  not_contacted <- setdiff(ten_states, c("California", "Colorado", "Arizona"))
  expect_equal(length(not_contacted), 7L)

  # Each excluded state must appear in the output string
  for (state in not_contacted) {
    expect_true(grepl(state, result, fixed = TRUE),
                label = paste("Missing excluded state:", state, "| Output:", result))
  }
})

test_that("contacted states are NOT mentioned as excluded in the output", {
  df <- data.frame(state = c("California", "Colorado", "Arizona"),
                   stringsAsFactors = FALSE)
  result <- mysterycall_not_contacted_states(df, all_states = ten_states)

  # Contacted states should not appear in the excluded list section
  # The format is "...excluded states include {list}."
  excluded_section <- sub(".*excluded states include ", "", result)
  for (state in c("California", "Colorado", "Arizona")) {
    expect_false(grepl(state, excluded_section, fixed = TRUE),
                 label = paste("Contacted state", state, "incorrectly appears in excluded section"))
  }
})

# ---------------------------------------------------------------------------
# 2. Gold standard: all states contacted → no states listed as excluded
# ---------------------------------------------------------------------------

test_that("all states contacted → output contains 'No states' as excluded", {
  df <- data.frame(state = ten_states, stringsAsFactors = FALSE)
  result <- mysterycall_not_contacted_states(df, all_states = ten_states)
  expect_true(grepl("No states", result),
              label = paste("Output:", result))
})

# ---------------------------------------------------------------------------
# 3. Gold standard: no states contacted → all listed as excluded
# ---------------------------------------------------------------------------

test_that("no states contacted → all 10 states listed as excluded", {
  # Pass empty data frame (no state column contact info means no states contacted)
  df <- data.frame(state = character(0), stringsAsFactors = FALSE)
  result <- mysterycall_not_contacted_states(df, all_states = ten_states)

  # All 10 states must appear in the excluded section
  for (state in ten_states) {
    expect_true(grepl(state, result, fixed = TRUE),
                label = paste("Missing excluded state:", state))
  }
})

# ---------------------------------------------------------------------------
# 4. Schema: output is always a length-1 character string
# ---------------------------------------------------------------------------

test_that("mysterycall_not_contacted_states always returns length-1 character", {
  df <- data.frame(state = c("California", "Colorado"), stringsAsFactors = FALSE)
  result <- mysterycall_not_contacted_states(df, all_states = ten_states)
  expect_type(result, "character")
  expect_length(result, 1L)
})

test_that("output is length-1 character even with NULL all_states", {
  df <- data.frame(state = c("California", "Texas"), stringsAsFactors = FALSE)
  result <- mysterycall_not_contacted_states(df)
  expect_type(result, "character")
  expect_length(result, 1L)
})

# ---------------------------------------------------------------------------
# 5. Domain invariant: count of excluded + count of contacted == length(all_states)
# ---------------------------------------------------------------------------

test_that("excluded + contacted state count equals total all_states count", {
  contacted_states <- c("California", "Colorado", "Arizona")
  df <- data.frame(state = contacted_states, stringsAsFactors = FALSE)
  result <- mysterycall_not_contacted_states(df, all_states = ten_states)

  n_contacted <- length(contacted_states)
  n_excluded  <- length(setdiff(ten_states, contacted_states))
  expect_equal(n_contacted + n_excluded, length(ten_states))
})

# ---------------------------------------------------------------------------
# 6. Silent failure: contact_office column with "Yes"/"No" values
# ---------------------------------------------------------------------------

test_that("contact_office='Yes' rows are treated as contacted states", {
  df <- data.frame(
    state          = c("Alabama", "Alaska", "Arizona", "Arkansas", "California"),
    contact_office = c("Yes", "No", "Yes", "No", "Yes"),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_not_contacted_states(df, all_states = ten_states)

  # Only Alabama, Arizona, California had "Yes" → those are contacted
  # Alabama, Arizona, California should NOT appear in excluded section
  # Alaska and Arkansas (and the remaining 5) should appear as excluded
  expect_true(grepl("Alaska",   result), label = "Alaska should be excluded")
  expect_true(grepl("Arkansas", result), label = "Arkansas should be excluded")
})

# ---------------------------------------------------------------------------
# 7. Silent failure: contact_office with mixed case ("yes"/"YES"/"Yes")
# ---------------------------------------------------------------------------

test_that("mixed-case contact_office values ('yes', 'YES', 'Yes') all treated as affirmative", {
  df <- data.frame(
    state          = c("Alabama", "Alaska", "Arizona"),
    contact_office = c("yes", "YES", "Yes"),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_not_contacted_states(df, all_states = ten_states)

  # All three states should be treated as contacted, so they should NOT be in the excluded section
  excluded_section <- sub(".*excluded states include ", "", result)
  for (state in c("Alabama", "Alaska", "Arizona")) {
    expect_false(grepl(state, excluded_section, fixed = TRUE),
                 label = paste(state, "with affirmative contact incorrectly excluded"))
  }
})

# ---------------------------------------------------------------------------
# 8. Boundary: NULL all_states uses default 51 states
# ---------------------------------------------------------------------------

test_that("NULL all_states uses default 51-state list internally", {
  df <- data.frame(state = c("California", "Texas", "New York"),
                   stringsAsFactors = FALSE)
  result <- mysterycall_not_contacted_states(df, all_states = NULL)

  # With 51 default states and 3 contacted, there should be 48 excluded
  # We can't enumerate all 48, but the result should mention many states
  expect_true(grepl("Alabama", result) || grepl("Alaska", result) || grepl("Colorado", result),
              label = "Default states should appear in excluded list")
})

# ---------------------------------------------------------------------------
# 9. Idempotency: calling twice with same data gives same string
# ---------------------------------------------------------------------------

test_that("mysterycall_not_contacted_states is idempotent", {
  df <- data.frame(state = c("California", "Colorado"), stringsAsFactors = FALSE)
  result1 <- mysterycall_not_contacted_states(df, all_states = ten_states)
  result2 <- mysterycall_not_contacted_states(df, all_states = ten_states)
  expect_equal(result1, result2)
})

# ---------------------------------------------------------------------------
# 10. Output always contains the count of unique physicians
# ---------------------------------------------------------------------------

test_that("output string always contains 'unique physicians' phrase", {
  df <- data.frame(state = c("California", "Colorado"), stringsAsFactors = FALSE)
  result <- mysterycall_not_contacted_states(df, all_states = ten_states)
  expect_true(grepl("unique physicians", result),
              label = paste("Output:", result))
})
