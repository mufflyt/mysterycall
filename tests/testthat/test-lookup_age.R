ref <- tibble::tibble(
  first_name    = c("Gioi", "Debra", "Michael"),
  last_name     = c("Smith-Nguyen", "Acerenza", "Miller"),
  state         = c("CA", "MD", "CA"),
  age_current   = c(69L, 58L, 91L),
  honorific     = c("MD", "DO", "MD"),
  npi           = c(NA, "1932181781", NA),
  city          = c("La Mesa", "Frederick", "Sacramento"),
  age_at_scrape = c(59L, 48L, 81L),
  scrape_year   = c(2016L, 2016L, 2016L),
  age_source    = c("raw_2016", "raw_2016", "raw_2016"),
  n_obs         = c(3L, 3L, 2L)
)

test_that("lookup_age: exact name + state match returns age", {
  r <- mysterycall_lookup_age("Gioi", "Smith-Nguyen", "CA", reference = ref)
  expect_true(r$matched)
  expect_equal(r$age_current, 69L)
  expect_equal(r$npi, NA_character_)
})

test_that("lookup_age: full state name is converted to abbreviation", {
  r <- mysterycall_lookup_age("Debra", "Acerenza", "Maryland", reference = ref)
  expect_true(r$matched)
  expect_equal(r$state, "MD")
  expect_equal(r$age_current, 58L)
  expect_equal(r$npi, "1932181781")
})

test_that("lookup_age: matching is case / punctuation / whitespace insensitive", {
  r <- mysterycall_lookup_age("  gioi ", "SMITH-NGUYEN.", "ca", reference = ref)
  expect_true(r$matched)
  expect_equal(r$age_current, 69L)
})

test_that("lookup_age: no match, impute = FALSE yields NA age and matched = FALSE", {
  r <- mysterycall_lookup_age("Nobody", "Xyzzy", "CO",
                              reference = ref, impute = FALSE)
  expect_false(r$matched)
  expect_true(is.na(r$age_current))
  expect_false(r$age_imputed)
})

test_that("lookup_age: unmatched gets flagged imputed age by default", {
  r <- mysterycall_lookup_age("Nobody", "Xyzzy", "CO", reference = ref)
  expect_false(r$matched)
  expect_true(r$age_imputed)
  expect_false(is.na(r$age_current))
  # CO absent from ref -> national median of c(69,58,91) = 69
  expect_equal(r$age_current, 69)
  expect_equal(r$age_source, "imputed_national_median")
})

test_that("lookup_age: imputation uses state median when the state is present", {
  # Two CA reference ages (69, 91) -> median 80 for an unmatched CA query
  r <- mysterycall_lookup_age("Ghost", "Nomatch", "CA", reference = ref)
  expect_true(r$age_imputed)
  expect_equal(r$age_current, 80)
  expect_equal(r$age_source, "imputed_state_median")
})

test_that("lookup_age: matched rows are never flagged as imputed", {
  r <- mysterycall_lookup_age("Gioi", "Smith-Nguyen", "CA", reference = ref)
  expect_true(r$matched)
  expect_false(r$age_imputed)
})

test_that("lookup_age: right state required (wrong state does not match)", {
  r <- mysterycall_lookup_age("Gioi", "Smith-Nguyen", "TX", reference = ref)
  expect_false(r$matched)
})

test_that("lookup_age: NA / empty state never matches", {
  r <- mysterycall_lookup_age(c("Gioi", "Debra"),
                              c("Smith-Nguyen", "Acerenza"),
                              c(NA, ""), reference = ref)
  expect_false(any(r$matched))
})

test_that("lookup_age: vectorised, preserves input order and length", {
  r <- mysterycall_lookup_age(
    first_name = c("Debra", "Gioi", "Nobody"),
    last_name  = c("Acerenza", "Smith-Nguyen", "Xyzzy"),
    state      = c("MD", "CA", "CO"),
    reference  = ref,
    impute     = FALSE
  )
  expect_equal(nrow(r), 3L)
  expect_equal(r$matched, c(TRUE, TRUE, FALSE))
  expect_equal(r$age_current, c(58L, 69L, NA))
})

test_that("lookup_age: scalar state recycles across many names", {
  r <- mysterycall_lookup_age(c("Gioi", "Michael"),
                              c("Smith-Nguyen", "Miller"),
                              "CA", reference = ref)
  expect_equal(r$matched, c(TRUE, TRUE))
  expect_equal(r$age_current, c(69L, 91L))
})

test_that("lookup_age: mismatched non-scalar lengths error", {
  expect_error(
    mysterycall_lookup_age(c("A", "B"), c("X", "Y", "Z"), "CA", reference = ref),
    "length 1 or"
  )
})

test_that("lookup_age: works against the bundled reference dataset", {
  skip_if_not(exists("healthgrades_ages"))
  r <- mysterycall_lookup_age("Debra", "Acerenza", "MD")
  expect_true(r$matched)
  expect_true(is.numeric(r$age_current) && r$age_current > 40)
})
