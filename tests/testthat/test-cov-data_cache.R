library(testthat)
library(mysterycall)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)


test_that("mysterycall_cache_set() and mysterycall_cache_get() work for basic key-value storage", {
  # Clear cache before test
  mysterycall_cache_clear()

  # Store a simple value
  mysterycall_cache_set("key1", "value1")
  expect_equal(mysterycall_cache_get("key1"), "value1")

  # Store multiple values
  mysterycall_cache_set("key2", 42)
  expect_equal(mysterycall_cache_get("key2"), 42)

  # Verify first value is still there
  expect_equal(mysterycall_cache_get("key1"), "value1")
})


test_that("mysterycall_cache_get() returns NULL for non-existent keys", {
  mysterycall_cache_clear()

  # Non-existent key should return NULL
  result <- mysterycall_cache_get("nonexistent_key")
  expect_null(result)

  # Even after setting other keys, missing key returns NULL
  mysterycall_cache_set("some_key", "some_value")
  expect_null(mysterycall_cache_get("different_key"))
})


test_that("mysterycall_cache_set() can store complex objects", {
  mysterycall_cache_clear()

  # Store a data frame
  mysterycall_cache_set("df_key", AUDIT)
  cached_df <- mysterycall_cache_get("df_key")
  expect_equal(cached_df, AUDIT)

  # Store a list
  test_list <- list(a = 1, b = "text", c = AUDIT)
  mysterycall_cache_set("list_key", test_list)
  expect_equal(mysterycall_cache_get("list_key"), test_list)

  # Store NULL as a value
  mysterycall_cache_set("null_key", NULL)
  expect_null(mysterycall_cache_get("null_key"))
})


test_that("mysterycall_cache_clear() empties the cache", {
  mysterycall_cache_clear()

  # Add some values
  mysterycall_cache_set("key1", "value1")
  mysterycall_cache_set("key2", "value2")
  mysterycall_cache_set("key3", COUNT_DF)

  # Verify they exist
  expect_equal(mysterycall_cache_get("key1"), "value1")
  expect_equal(mysterycall_cache_get("key2"), "value2")

  # Clear the cache
  mysterycall_cache_clear()

  # All keys should now return NULL
  expect_null(mysterycall_cache_get("key1"))
  expect_null(mysterycall_cache_get("key2"))
  expect_null(mysterycall_cache_get("key3"))
})


test_that("mysterycall_cache_set() overwrites existing keys", {
  mysterycall_cache_clear()

  # Set initial value
  mysterycall_cache_set("key", "initial")
  expect_equal(mysterycall_cache_get("key"), "initial")

  # Overwrite with new value
  mysterycall_cache_set("key", "updated")
  expect_equal(mysterycall_cache_get("key"), "updated")

  # Overwrite with different type
  mysterycall_cache_set("key", list(a = 1, b = 2))
  cached <- mysterycall_cache_get("key")
  expect_equal(cached$a, 1)
  expect_equal(cached$b, 2)
})
