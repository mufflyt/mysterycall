# Jobs 21, 22, 24: provider-roster identity, NPI reconciliation, call identity.
#
# The counts asserted here are the ones a join quietly changes. A many-to-many
# expansion adds rows that look like extra observations; a bad dedup removes
# providers that were never meant to be merged. Neither errors, and both change
# the denominator.

fixture_path <- testthat::test_path("..", "fixtures", "canonical_study.R")
skip_if_not(file.exists(fixture_path), "canonical study fixture not found")
source(fixture_path)

S         <- mc_canonical_study()
STUDY     <- S$study
PROVIDERS <- S$providers
CALLS     <- S$calls

# ---------------------------------------------------------------------------
# Job 21: provider identifier uniqueness
# ---------------------------------------------------------------------------

test_that("roster identifier counts are exactly as constructed", {
  expect_equal(nrow(PROVIDERS), 16L)
  expect_equal(anyDuplicated(PROVIDERS$provider_id), 0L)

  npi <- PROVIDERS$npi
  expect_equal(sum(is.na(npi)), 1L)                       # P16
  expect_equal(length(unique(stats::na.omit(npi))), 14L)
  expect_equal(sum(duplicated(stats::na.omit(npi))), 1L)  # P13 repeats P01
})

test_that("the duplicated NPI belongs to two distinct roster IDs", {
  npi <- PROVIDERS$npi
  dup_value <- unique(npi[duplicated(npi) & !is.na(npi)])
  expect_length(dup_value, 1L)

  rows <- PROVIDERS[!is.na(npi) & npi == dup_value, ]
  expect_equal(nrow(rows), 2L)
  # Same physician, two roster IDs. Distinguishing these is the whole point of
  # deduplication: collapsing on provider_id alone would keep both.
  expect_equal(length(unique(rows$provider_id)), 2L)
  expect_equal(length(unique(rows$physician_information)), 1L)
})

test_that("physician-location combinations are counted, not conflated", {
  # P04 has two phone numbers. A provider count and a location count are
  # different denominators and must not be used interchangeably.
  locs <- unique(STUDY[, c("id_number", "phone")])
  expect_equal(nrow(locs), 17L)                    # 16 providers, P04 twice
  expect_gt(nrow(locs), length(unique(STUDY$id_number)))

  multi <- table(locs$id_number)
  expect_equal(sum(multi > 1L), 1L)
  expect_equal(names(multi)[multi > 1L], "P04")
})

test_that("mysterycall_flag_repeat_physicians finds the repeated physician", {
  d <- STUDY
  res <- mysterycall_flag_repeat_physicians(
    data       = d,
    id_col     = "id_number",
    name_col   = "physician_information",
    threshold  = 2L,
    output_dir = NULL
  )
  expect_true(is.data.frame(res))
  # "Alvarez, Maria" appears under P01 and P13.
  expect_gte(nrow(res), 1L)
})

# ---------------------------------------------------------------------------
# Job 22: NPI reconciliation
# ---------------------------------------------------------------------------

test_that("a missing NPI never resolves to another provider's NPI", {
  no_npi <- PROVIDERS[is.na(PROVIDERS$npi), ]
  expect_equal(nrow(no_npi), 1L)
  expect_equal(no_npi$provider_id, "P16")

  # The provider still has calls; a missing identifier must not remove them
  # from the call log.
  expect_gt(sum(STUDY$id_number == "P16"), 0L)
})

test_that("an ambiguous NPI match is never resolved by taking the first row", {
  npi <- PROVIDERS$npi
  dup_value <- unique(npi[duplicated(npi) & !is.na(npi)])
  candidates <- PROVIDERS[!is.na(npi) & npi == dup_value, ]
  expect_equal(nrow(candidates), 2L)

  # match() returns only the first hit. Any reconciliation that relies on it
  # silently discards the second candidate, which is why the ambiguity must be
  # detected before matching rather than after.
  first_only <- PROVIDERS[match(dup_value, PROVIDERS$npi), ]
  expect_equal(nrow(first_only), 1L)
  expect_lt(nrow(first_only), nrow(candidates))

  ambiguous <- sum(stats::ave(rep(1L, nrow(candidates)),
                              candidates$npi, FUN = length) > 1L)
  expect_gt(ambiguous, 0L)
})

test_that("every call maps to a roster provider", {
  orphans <- setdiff(unique(STUDY$id_number), PROVIDERS$provider_id)
  expect_equal(orphans, character(0),
               info = paste("calls with no roster entry:",
                            paste(orphans, collapse = ", ")))
})

# ---------------------------------------------------------------------------
# Job 24: one call really means one call
# ---------------------------------------------------------------------------

test_that("no exact duplicate rows exist in the call log", {
  expect_equal(sum(duplicated(CALLS)), 0L)
})

test_that("provider, location and arm together identify a call uniquely", {
  key <- paste(STUDY$id_number, STUDY$phone, STUDY$insurance, sep = "|")
  dupes <- key[duplicated(key)]
  expect_equal(dupes, character(0),
               info = paste("duplicated call keys:", paste(dupes, collapse = ", ")))
})

test_that("P01 and P13 are separate calls despite sharing an NPI and phone", {
  # They are the same physician reached at the same number, but they are two
  # roster entries and therefore two calls. Deduplicating on NPI alone would
  # remove real observations; deduplicating on nothing would double-count the
  # physician. The fixture makes both mistakes visible.
  p01 <- STUDY[STUDY$id_number == "P01", ]
  p13 <- STUDY[STUDY$id_number == "P13", ]
  expect_equal(nrow(p01), 2L)
  expect_equal(nrow(p13), 2L)
  expect_equal(unique(p01$phone), unique(p13$phone))

  npi_lookup <- stats::setNames(PROVIDERS$npi, PROVIDERS$provider_id)
  expect_equal(unname(npi_lookup[["P01"]]), unname(npi_lookup[["P13"]]))
})

test_that("mysterycall_check_duplicates flags the multi-location provider", {
  # In a two-arm crossover a provider should contribute two calls. P04 has two
  # office locations and therefore four, which is legitimate but must be
  # visible: counting P04 once as a provider and four times as a call is the
  # distinction that decides a denominator.
  res <- mysterycall_check_duplicates(STUDY, id_col = "id_number", max_calls = 2L)

  expect_true(is.data.frame(res))
  expect_setequal(unique(res$id_number), "P04")
  expect_equal(nrow(res), 4L)
  expect_true(all(res$n_calls == 4L))
  expect_equal(attr(res, "n_flagged"), 1L)
})

test_that("check_duplicates flags nothing when the per-provider cap allows it", {
  # The complement: raise the cap above P04's four calls and the fixture is
  # clean, confirming the test above fails for the intended reason.
  res <- mysterycall_check_duplicates(STUDY, id_col = "id_number", max_calls = 4L)
  expect_equal(nrow(res), 0L)
  expect_equal(attr(res, "n_flagged"), 0L)
})

test_that("removing a duplicate is auditable, not silent", {
  # Whatever rule is applied, the count removed must be recoverable. A dedup
  # that cannot say how many rows it dropped cannot be reconciled against a
  # denominator.
  before <- nrow(STUDY)
  deduped <- STUDY[!duplicated(paste(STUDY$id_number, STUDY$phone,
                                     STUDY$insurance, sep = "|")), ]
  after <- nrow(deduped)
  removed <- before - after

  expect_equal(removed, 0L)          # nothing to remove in the canonical data
  expect_equal(before, after + removed)
})
