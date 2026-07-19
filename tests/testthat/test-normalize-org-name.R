# Tests for mysterycall_normalize_org_name()

test_that("variants of the same practice collapse to one canonical form", {
  got <- mysterycall_normalize_org_name(c(
    "Women's Health Specialists, LLC",
    "Womens Health Specialists PC",
    "WOMEN'S HEALTH SPECIALISTS"))
  expect_equal(unique(got), "WOMENS HEALTH SPECIALISTS")
})

test_that("ampersand expands and punctuation is stripped", {
  expect_equal(
    mysterycall_normalize_org_name("Rocky Mountain OB & GYN, P.A."),
    "ROCKY MOUNTAIN OB AND GYN")
})

test_that("legal suffixes and credentials are dropped as whole words", {
  expect_equal(mysterycall_normalize_org_name("Acme Care Inc"), "ACME CARE")
  expect_equal(mysterycall_normalize_org_name("Jane Roe MD PLLC"), "JANE ROE")
  # a suffix embedded in a real word is NOT dropped
  expect_equal(mysterycall_normalize_org_name("Incline Health"), "INCLINE HEALTH")
})

test_that("NA becomes empty string and length is preserved", {
  got <- mysterycall_normalize_org_name(c("A LLC", NA, "B PC"))
  expect_equal(got, c("A", "", "B"))
  expect_length(got, 3L)
})

test_that("curly apostrophes normalize like straight ones", {
  expect_identical(
    mysterycall_normalize_org_name("Children’s Clinic"),
    mysterycall_normalize_org_name("Children's Clinic"))
})

test_that("drop_suffixes = character(0) keeps the tokens", {
  expect_equal(
    mysterycall_normalize_org_name("Acme Care Inc", drop_suffixes = character(0)),
    "ACME CARE INC")
})

test_that("expand_ampersand = FALSE removes & as punctuation instead", {
  expect_equal(
    mysterycall_normalize_org_name("A & B", expand_ampersand = FALSE),
    "A B")
})

test_that("the normalized key makes a join work across spellings", {
  cohort <- data.frame(name = c("Women's Health Specialists, LLC",
                                "Rocky Mountain OB & GYN PA"))
  roster <- data.frame(name = c("WOMENS HEALTH SPECIALISTS",
                                "ROCKY MOUNTAIN OB AND GYN"),
                       owner = c("PE-backed", "Independent"))
  cohort$key <- mysterycall_normalize_org_name(cohort$name)
  merged <- merge(cohort, roster, by.x = "key", by.y = "name")
  expect_equal(nrow(merged), 2L)
  expect_setequal(merged$owner, c("PE-backed", "Independent"))
})
