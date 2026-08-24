# mysterycall_assign_blinded_slots() -- record numbering must not encode a matched pair's arm.
#
# The defect these tests exist to stop is not hypothetical: it shipped in a mystery-caller
# study's fielded REDCap dictionary, which was numbered by sorting on (pair, arm). One arm
# label sorted before the other alphabetically, so every pair landed control-then-treatment.
# Record parity predicted the arm perfectly, and the two members of a pair sat next to each
# other in the caller's dropdown. Blinding was defeated by the record id, which no masked
# field on the exposure column can fix.

n     <- 400L
pair  <- rep(seq_len(n / 2L), each = 2L)
group <- rep(c("treatment", "control"), n / 2L)

parity_split <- function(slot, group) {
  odd <- slot %% 2L == 1L
  c(trt_odd  = sum(group == "treatment" &  odd), trt_even  = sum(group == "treatment" & !odd),
    ctl_odd  = sum(group == "control"   &  odd), ctl_even  = sum(group == "control"   & !odd))
}
adjacent_pairs <- function(slot, pair) {
  by_slot <- as.character(pair)[order(slot)]
  sum(by_slot[-1L] == by_slot[-length(by_slot)])
}

test_that("adversarial: the naive sort-then-row_number ordering is reproduced and shown to leak", {
  ord    <- order(pair, group)
  leaked <- integer(n); leaked[ord] <- seq_len(n)
  split  <- parity_split(leaked, group)
  expect_equal(unname(split[["ctl_odd"]]), n / 2L)
  expect_equal(unname(split[["trt_odd"]]), 0L)
  expect_equal(adjacent_pairs(leaked, pair), n / 2L)
})

test_that("the allocator returns a permutation of the slots", {
  expect_equal(sort(mysterycall_assign_blinded_slots(pair, group)), seq_len(n))
})

test_that("parity carries exactly zero information about the arm", {
  split <- parity_split(mysterycall_assign_blinded_slots(pair, group), group)
  expect_equal(unname(split[["trt_odd"]]),  n / 4L)
  expect_equal(unname(split[["trt_even"]]), n / 4L)
  expect_equal(unname(split[["ctl_odd"]]),  n / 4L)
  expect_equal(unname(split[["ctl_even"]]), n / 4L)
})

test_that("no matched pair lands on consecutive slots", {
  expect_equal(adjacent_pairs(mysterycall_assign_blinded_slots(pair, group), pair), 0L)
})

test_that("the arms are not blocked into low and high slots either", {
  slot <- mysterycall_assign_blinded_slots(pair, group)
  trt_first_half <- sum(group == "treatment" & slot <= n / 2L)
  expect_gt(trt_first_half, 70L)
  expect_lt(trt_first_half, 130L)
})

test_that("the allocation is reproducible from its seed and varies without it", {
  expect_identical(mysterycall_assign_blinded_slots(pair, group, seed = 1L),
                   mysterycall_assign_blinded_slots(pair, group, seed = 1L))
  expect_false(identical(mysterycall_assign_blinded_slots(pair, group, seed = 1L),
                         mysterycall_assign_blinded_slots(pair, group, seed = 2L)))
})

test_that("a seeded call does not disturb the caller's own random state", {
  # withr::local_seed() restores the pre-call RNG state on exit; a bare set.seed() would not.
  set.seed(99)
  before <- runif(1)
  set.seed(99)
  mysterycall_assign_blinded_slots(pair, group, seed = 1L)
  after <- runif(1)
  expect_equal(before, after,
               info = "calling the allocator must not perturb the caller's own RNG stream")
})

test_that("the invariants hold across many seeds, not just the one that was chosen", {
  for (s in 1:40) {
    slot  <- mysterycall_assign_blinded_slots(pair, group, seed = s)
    split <- parity_split(slot, group)
    expect_equal(unname(split[["trt_odd"]]), n / 4L, info = sprintf("seed %d", s))
    expect_equal(adjacent_pairs(slot, pair), 0L,    info = sprintf("seed %d", s))
  }
})

test_that("BVA: the allocator refuses inputs it cannot balance", {
  expect_error(mysterycall_assign_blinded_slots(pair[-1L], group), "same length")
  # Dropping two whole pairs keeps both arms even, so this must still succeed.
  expect_error(mysterycall_assign_blinded_slots(pair[-(1:4)], group[-(1:4)], seed = 1L), NA)
  # An odd number of records cannot split into equal parity halves.
  expect_error(mysterycall_assign_blinded_slots(pair[-1L], group[-1L]), "even number")
  # Nor can an arm of odd size.
  g <- group; g[1L] <- "control"
  expect_error(mysterycall_assign_blinded_slots(pair, g), "even size")
  # One arm is not a comparison.
  expect_error(mysterycall_assign_blinded_slots(pair, rep("treatment", n)), "exactly 2 arms")
})

test_that("semantic: pair members stay together in the study, just not in the numbering", {
  slot <- mysterycall_assign_blinded_slots(pair, group)
  by_pair <- split(group, pair)
  expect_true(all(vapply(by_pair, length, integer(1)) == 2L))
  expect_true(all(vapply(by_pair, function(g) length(unique(g)) == 2L, logical(1))))
  expect_equal(length(unique(slot)), n)
})
