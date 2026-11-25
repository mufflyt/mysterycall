test_that("street key strips units and normalizes directionals/suffixes", {
  key <- mysterycall_street_address_key("123 North Main Street Suite 400")
  expect_identical(key$street_number, "123")
  expect_true("MAIN" %in% key$street_tokens)
  expect_true("N" %in% key$street_tokens)
  expect_false("ST" %in% key$street_tokens)
  expect_false(any(grepl("400", key$street_tokens)))
  expect_true(key$has_num)
})

test_that("street key handles blank and PO box input without error", {
  blank <- mysterycall_street_address_key(NA_character_)
  expect_true(is.na(blank$normalized))
  expect_true(is.na(blank$street_number))

  po <- mysterycall_street_address_key("PO Box 12345")
  expect_true(po$is_po_box)
  expect_true(is.na(po$street_number))
  expect_false(po$has_num)
})

test_that("street agreement corroborates suite and suffix variants", {
  verdict <- mysterycall_street_address_agreement(
    "123 Main Street Suite 200",
    "123 Main St"
  )
  expect_identical(verdict$verdict, "corroborates")

  verdict <- mysterycall_street_address_agreement(
    "123 North Main Street",
    "123 N Main St Floor 2"
  )
  expect_identical(verdict$verdict, "corroborates")
})

test_that("roadway suffix alone cannot corroborate same-number addresses", {
  verdict <- mysterycall_street_address_agreement("123 Main St", "123 Oak St")
  expect_identical(verdict$verdict, "conflicts")
  expect_identical(verdict$reason, "no_shared_street_token")
  expect_false(mysterycall_street_addresses_agree("123 Main St", "123 Oak St"))
})

test_that("different street numbers conflict", {
  verdict <- mysterycall_street_address_agreement("123 Main St", "124 Main St")
  expect_identical(verdict$verdict, "conflicts")
  expect_identical(verdict$reason, "street_number_conflict")
})

test_that("missing and PO-box addresses are uninformative", {
  expect_identical(
    mysterycall_street_address_agreement(NA_character_, "123 Main St")$verdict,
    "uninformative"
  )
  expect_identical(
    mysterycall_street_address_agreement("PO Box 12345", "PO Box 12345")$verdict,
    "uninformative"
  )
})
