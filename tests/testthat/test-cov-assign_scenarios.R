library(testthat)

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


# Test 1: Happy path - basic assignment with one location
test_that("mysterycall_assign_scenarios assigns scenarios correctly in single location", {
  df <- data.frame(
    city          = c("Denver", "Denver", "Denver", "Denver"),
    state_code    = "CO",
    specialty_primary = c(
      "General Otolaryngology", "General Otolaryngology",
      "Neurotology", "Pediatric Otolaryngology"
    ),
    id = 1:4,
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    generalist_level = "General Otolaryngology",
    scenario_map     = c("Neurotology" = "Neurotology",
                        "Pediatric Otolaryngology" = "Pediatric Otolaryngology")
  ))

  expect_s3_class(result, "data.frame")
  expect_true("scenario" %in% names(result))
  expect_equal(nrow(result), nrow(df))
  # Check non-generalists get their own specialty
  expect_equal(result$scenario[3], "Neurotology")
  expect_equal(result$scenario[4], "Pediatric Otolaryngology")
  # Check generalists are assigned (not NA)
  expect_false(is.na(result$scenario[1]))
  expect_false(is.na(result$scenario[2]))
})


# Test 2: Round-robin assignment with multiple generalists
test_that("mysterycall_assign_scenarios uses round-robin for generalist assignment", {
  df <- data.frame(
    city          = c("Denver", "Denver", "Denver", "Denver"),
    state_code    = "CO",
    specialty_primary = c(
      "General Medicine", "General Medicine", "General Medicine",
      "Cardiology"
    ),
    id = 1:4,
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    generalist_level = "General Medicine",
    scenario_map     = c("Cardiology" = "Cardiology")
  ))

  # Three generalists assigned to one scenario should cycle
  gen_scenarios <- result$scenario[1:3]
  # All should be "Cardiology" since it's the only available scenario
  expect_equal(gen_scenarios, c("Cardiology", "Cardiology", "Cardiology"))
})


# Test 3: Multiple locations with independent assignments
test_that("mysterycall_assign_scenarios handles multiple locations independently", {
  df <- data.frame(
    city          = c("Denver", "Denver", "Boulder", "Boulder"),
    state_code    = "CO",
    specialty_primary = c(
      "General Otolaryngology", "General Otolaryngology",
      "General Otolaryngology", "Neurotology"
    ),
    id = 1:4,
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    generalist_level = "General Otolaryngology",
    scenario_map     = c("Neurotology" = "Neurotology")
  ))

  # Denver generalists have no subspecialists → NA
  expect_true(is.na(result$scenario[1]))
  expect_true(is.na(result$scenario[2]))
  # Boulder generalist has Neurotology available
  expect_equal(result$scenario[3], "Neurotology")
})


# Test 4: ID column sorting affects round-robin order
test_that("mysterycall_assign_scenarios respects id_col for sorting", {
  df <- data.frame(
    city          = c("Denver", "Denver", "Denver"),
    state_code    = "CO",
    specialty_primary = c("General Medicine", "General Medicine", "Cardiology"),
    id = c(3, 1, 2),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    generalist_level = "General Medicine",
    scenario_map     = c("Cardiology" = "Cardiology"),
    id_col = "id"
  ))

  # With id_col, sorting by id should process row 2 (id=1) then row 1 (id=3)
  # both should get "Cardiology"
  expect_equal(result$scenario[1], "Cardiology")
  expect_equal(result$scenario[2], "Cardiology")
})


# Test 5: Custom scenario column name
test_that("mysterycall_assign_scenarios uses custom scenario_col name", {
  df <- data.frame(
    city          = c("Denver", "Denver", "Denver"),
    state_code    = "CO",
    specialty_primary = c("General Medicine", "General Medicine", "Cardiology"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    generalist_level = "General Medicine",
    scenario_map     = c("Cardiology" = "Cardiology"),
    scenario_col = "my_scenario"
  ))

  expect_true("my_scenario" %in% names(result))
  expect_false("scenario" %in% names(result))
  expect_equal(result$my_scenario[3], "Cardiology")
})


# Test 6: Custom location and specialty columns
test_that("mysterycall_assign_scenarios uses custom column names", {
  df <- data.frame(
    region        = c("North", "North", "North"),
    state         = "CA",
    prov_spec     = c("GP", "GP", "Specialist"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    location_cols    = c("region", "state"),
    specialty_col    = "prov_spec",
    generalist_level = "GP",
    scenario_map     = c("Specialist" = "Specialist")
  ))

  expect_true("scenario" %in% names(result))
  expect_equal(result$scenario[1], "Specialist")
  expect_equal(result$scenario[2], "Specialist")
})


# Test 7: No generalists in location
test_that("mysterycall_assign_scenarios handles locations with no generalists", {
  df <- data.frame(
    city          = c("Denver", "Denver"),
    state_code    = "CO",
    specialty_primary = c("Cardiology", "Neurology"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    generalist_level = "General Medicine",
    scenario_map     = c("Cardiology" = "Cardiology")
  ))

  # Non-generalists should still get their own specialty
  expect_equal(result$scenario[1], "Cardiology")
  expect_equal(result$scenario[2], "Neurology")
})


# Test 8: No available subspecialties for generalists
test_that("mysterycall_assign_scenarios assigns NA when no subspecialties match", {
  df <- data.frame(
    city          = c("Denver", "Denver", "Denver"),
    state_code    = "CO",
    specialty_primary = c("General Medicine", "General Medicine", "Dermatology"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    generalist_level = "General Medicine",
    scenario_map     = c("Cardiology" = "Cardiology")  # not present in data
  ))

  # Generalists get NA since Cardiology not in this location
  expect_true(is.na(result$scenario[1]))
  expect_true(is.na(result$scenario[2]))
  # Non-generalist gets their own specialty
  expect_equal(result$scenario[3], "Dermatology")
})


# Test 9: Multiple scenarios available (round-robin test)
test_that("mysterycall_assign_scenarios cycles through multiple scenarios in round-robin", {
  df <- data.frame(
    city          = c("Denver", "Denver", "Denver", "Denver", "Denver"),
    state_code    = "CO",
    specialty_primary = c(
      "General Medicine", "General Medicine", "General Medicine",
      "Cardiology", "Neurology"
    ),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    generalist_level = "General Medicine",
    scenario_map     = c("Cardiology" = "Card", "Neurology" = "Neuro")
  ))

  # Three generalists should cycle: Card, Neuro, Card
  gen_scenarios <- result$scenario[1:3]
  expect_equal(gen_scenarios, c("Card", "Neuro", "Card"))
})


# Test 10: Missing required argument
test_that("mysterycall_assign_scenarios errors when generalist_level is missing", {
  df <- data.frame(
    city          = "Denver",
    state_code    = "CO",
    specialty_primary = "GP",
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_assign_scenarios(df, scenario_map = c("A" = "A")),
    "missing"
  )
})


# Test 11: Missing required argument scenario_map
test_that("mysterycall_assign_scenarios errors when scenario_map is missing", {
  df <- data.frame(
    city          = "Denver",
    state_code    = "CO",
    specialty_primary = "GP",
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_assign_scenarios(df, generalist_level = "GP"),
    "missing"
  )
})


# Test 12: Invalid generalist_level (empty string)
test_that("mysterycall_assign_scenarios errors on empty generalist_level", {
  df <- data.frame(
    city = "Denver",
    state_code = "CO",
    specialty_primary = "GP",
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_assign_scenarios(
      df,
      generalist_level = "",
      scenario_map = c("A" = "A")
    )),
    "non-empty character scalar"
  )
})


# Test 13: Invalid generalist_level (not character)
test_that("mysterycall_assign_scenarios errors on non-character generalist_level", {
  df <- data.frame(
    city = "Denver",
    state_code = "CO",
    specialty_primary = "GP",
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_assign_scenarios(
      df,
      generalist_level = 123,
      scenario_map = c("A" = "A")
    )),
    "non-empty character scalar"
  )
})


# Test 14: Invalid scenario_map (unnamed vector)
test_that("mysterycall_assign_scenarios errors on unnamed scenario_map", {
  df <- data.frame(
    city = "Denver",
    state_code = "CO",
    specialty_primary = "GP",
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_assign_scenarios(
      df,
      generalist_level = "GP",
      scenario_map = c("A", "B")
    )),
    "named character vector"
  )
})


# Test 15: Invalid scenario_map (empty vector)
test_that("mysterycall_assign_scenarios errors on empty scenario_map", {
  df <- data.frame(
    city = "Denver",
    state_code = "CO",
    specialty_primary = "GP",
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_assign_scenarios(
      df,
      generalist_level = "GP",
      scenario_map = c()
    )),
    "named character vector"
  )
})


# Test 16: Invalid scenario_col (empty string)
test_that("mysterycall_assign_scenarios errors on empty scenario_col", {
  df <- data.frame(
    city = "Denver",
    state_code = "CO",
    specialty_primary = "GP",
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_assign_scenarios(
      df,
      generalist_level = "GP",
      scenario_map = c("A" = "A"),
      scenario_col = ""
    )),
    "non-empty character scalar"
  )
})


# Test 17: Missing location column
test_that("mysterycall_assign_scenarios errors when location column is missing", {
  df <- data.frame(
    state_code = "CO",
    specialty_primary = "GP",
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_assign_scenarios(
      df,
      generalist_level = "GP",
      scenario_map = c("A" = "A")
    )),
    "city"
  )
})


# Test 18: Missing specialty column
test_that("mysterycall_assign_scenarios errors when specialty_col is missing", {
  df <- data.frame(
    city = "Denver",
    state_code = "CO",
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_assign_scenarios(
      df,
      generalist_level = "GP",
      scenario_map = c("A" = "A")
    )),
    "specialty_primary"
  )
})


# Test 19: Missing id_col column
test_that("mysterycall_assign_scenarios errors when id_col is missing", {
  df <- data.frame(
    city = "Denver",
    state_code = "CO",
    specialty_primary = "GP",
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_assign_scenarios(
      df,
      generalist_level = "GP",
      scenario_map = c("A" = "A"),
      id_col = "nonexistent_id"
    )),
    "nonexistent_id"
  )
})


# Test 20: Data frame with zero rows
test_that("mysterycall_assign_scenarios errors on zero-row data frame", {
  df <- data.frame(
    city = character(),
    state_code = character(),
    specialty_primary = character(),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_assign_scenarios(
      df,
      generalist_level = "GP",
      scenario_map = c("A" = "A")
    )),
    "at least one row"
  )
})


# Test 21: Data frame is not a data frame
test_that("mysterycall_assign_scenarios errors on non-data.frame input", {
  expect_error(
    suppressMessages(mysterycall_assign_scenarios(
      list(a = 1),
      generalist_level = "GP",
      scenario_map = c("A" = "A")
    )),
    "data.frame"
  )
})


# Test 22: Return value includes all original columns
test_that("mysterycall_assign_scenarios preserves original columns", {
  df <- data.frame(
    city = "Denver",
    state_code = "CO",
    specialty_primary = "GP",
    extra_col = "test",
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    generalist_level = "GP",
    scenario_map = c("A" = "A")
  ))

  expect_true(all(names(df) %in% names(result)))
  expect_equal(result$extra_col, "test")
})


# Test 23: Generalist receives its own specialty if it's in scenario_map
test_that("mysterycall_assign_scenarios assigns generalist specialty if in scenario_map", {
  df <- data.frame(
    city = c("Denver", "Denver"),
    state_code = "CO",
    specialty_primary = c("General Medicine", "General Medicine"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    generalist_level = "General Medicine",
    scenario_map = c("General Medicine" = "Primary Care")
  ))

  # Both are generalists but the specialty is in the map, so they get the scenario label
  expect_equal(result$scenario[1], "Primary Care")
  expect_equal(result$scenario[2], "Primary Care")
})


# Test 24: Multiple location columns (city, state, region)
test_that("mysterycall_assign_scenarios groups by multiple location columns correctly", {
  df <- data.frame(
    city = c("Denver", "Denver", "Denver", "Denver"),
    state = "CO",
    region = c("North", "North", "South", "South"),
    specialty_primary = c("GP", "GP", "GP", "Cardiology"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    location_cols = c("city", "state", "region"),
    generalist_level = "GP",
    scenario_map = c("Cardiology" = "Cardiology")
  ))

  # North region GPs have no Cardiology
  expect_true(is.na(result$scenario[1]))
  expect_true(is.na(result$scenario[2]))
  # South region GP has Cardiology
  expect_equal(result$scenario[3], "Cardiology")
})


# Test 25: Output row count matches input row count
test_that("mysterycall_assign_scenarios maintains row count", {
  df <- data.frame(
    city = rep("Denver", 10),
    state_code = "CO",
    specialty_primary = c(rep("GP", 7), rep("Specialist", 3)),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_assign_scenarios(
    df,
    generalist_level = "GP",
    scenario_map = c("Specialist" = "Spec")
  ))

  expect_equal(nrow(result), nrow(df))
})
