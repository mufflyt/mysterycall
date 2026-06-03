make_oto <- function() {
  data.frame(
    city              = c("Denver", "Denver", "Denver", "Denver",
                          "Boulder", "Boulder",
                          "Aspen", "Aspen"),
    state_code        = "CO",
    specialty_primary = c(
      "General Otolaryngology", "General Otolaryngology",
      "Neurotology", "Pediatric Otolaryngology",
      "General Otolaryngology", "Neurotology",
      "General Otolaryngology", "General Otolaryngology"
    ),
    id = 1:8,
    stringsAsFactors = FALSE
  )
}

smap <- c("Neurotology"              = "Neurotology",
          "Pediatric Otolaryngology" = "Pediatric Otolaryngology")

# ── Basics ────────────────────────────────────────────────────────────────────

test_that("assign_scenarios: returns data frame with new column", {
  out <- suppressMessages(
    mysterycall:::mysterycall_assign_scenarios(make_oto(), generalist_level = "General Otolaryngology",
                                  scenario_map = smap)
  )
  expect_s3_class(out, "data.frame")
  expect_true("scenario" %in% names(out))
})

test_that("assign_scenarios: non-generalists keep their own specialty", {
  out <- suppressMessages(
    mysterycall:::mysterycall_assign_scenarios(make_oto(), generalist_level = "General Otolaryngology",
                                  scenario_map = smap)
  )
  neuro_rows <- out[out$specialty_primary == "Neurotology", ]
  expect_true(all(neuro_rows$scenario == "Neurotology"))
  peds_rows <- out[out$specialty_primary == "Pediatric Otolaryngology", ]
  expect_true(all(peds_rows$scenario == "Pediatric Otolaryngology"))
})

test_that("assign_scenarios: generalists in Denver get alternating scenarios", {
  out <- suppressMessages(
    mysterycall:::mysterycall_assign_scenarios(make_oto(), generalist_level = "General Otolaryngology",
                                  scenario_map = smap, id_col = "id")
  )
  denver_gen <- out[out$city == "Denver" & out$specialty_primary == "General Otolaryngology", ]
  scenarios  <- sort(unique(denver_gen$scenario))
  expect_true("Neurotology" %in% scenarios)
  expect_true("Pediatric Otolaryngology" %in% scenarios)
})

test_that("assign_scenarios: Boulder generalist gets Neurotology only (no Pediatric there)", {
  out <- suppressMessages(
    mysterycall:::mysterycall_assign_scenarios(make_oto(), generalist_level = "General Otolaryngology",
                                  scenario_map = smap)
  )
  boulder_gen <- out[out$city == "Boulder" & out$specialty_primary == "General Otolaryngology", ]
  expect_equal(unique(boulder_gen$scenario), "Neurotology")
})

test_that("assign_scenarios: generalists with no local subspecialist get NA", {
  out <- suppressMessages(
    mysterycall:::mysterycall_assign_scenarios(make_oto(), generalist_level = "General Otolaryngology",
                                  scenario_map = smap)
  )
  aspen_gen <- out[out$city == "Aspen" & out$specialty_primary == "General Otolaryngology", ]
  expect_true(all(is.na(aspen_gen$scenario)))
})

test_that("assign_scenarios: custom scenario_col name is used", {
  out <- suppressMessages(
    mysterycall:::mysterycall_assign_scenarios(make_oto(), generalist_level = "General Otolaryngology",
                                  scenario_map = smap, scenario_col = "call_type")
  )
  expect_true("call_type" %in% names(out))
  expect_false("scenario" %in% names(out))
})

test_that("assign_scenarios: original columns preserved", {
  orig <- make_oto()
  out  <- suppressMessages(
    mysterycall:::mysterycall_assign_scenarios(orig, generalist_level = "General Otolaryngology",
                                  scenario_map = smap)
  )
  expect_true(all(names(orig) %in% names(out)))
})

# ── Input validation ──────────────────────────────────────────────────────────

test_that("assign_scenarios: non-dataframe errors", {
  expect_error(
    mysterycall:::mysterycall_assign_scenarios(list(a = 1), generalist_level = "X", scenario_map = c(Y = "Y")),
    "data frame"
  )
})

test_that("assign_scenarios: missing location column errors", {
  df <- make_oto()
  expect_error(
    mysterycall:::mysterycall_assign_scenarios(df, location_cols = c("city", "no_such"),
                                  generalist_level = "General Otolaryngology",
                                  scenario_map = smap),
    "no_such"
  )
})

test_that("assign_scenarios: missing specialty column errors", {
  df <- make_oto()
  expect_error(
    mysterycall:::mysterycall_assign_scenarios(df, specialty_col = "no_such",
                                  generalist_level = "General Otolaryngology",
                                  scenario_map = smap),
    "no_such"
  )
})

test_that("assign_scenarios: empty scenario_map errors", {
  expect_error(
    mysterycall:::mysterycall_assign_scenarios(make_oto(), generalist_level = "General Otolaryngology",
                                  scenario_map = character(0)),
    "scenario_map"
  )
})

test_that("assign_scenarios: unnamed scenario_map errors", {
  expect_error(
    mysterycall:::mysterycall_assign_scenarios(make_oto(), generalist_level = "General Otolaryngology",
                                  scenario_map = c("Neurotology")),
    "named"
  )
})

test_that("assign_scenarios: round-robin wraps for three scenarios", {
  df <- data.frame(
    city              = rep("TestCity", 7),
    state_code        = "TX",
    specialty_primary = c(rep("Generalist", 4), "Sub_A", "Sub_B", "Sub_C"),
    id                = 1:7,
    stringsAsFactors  = FALSE
  )
  out <- suppressMessages(
    mysterycall:::mysterycall_assign_scenarios(df,
                                  generalist_level = "Generalist",
                                  scenario_map = c("Sub_A" = "A", "Sub_B" = "B", "Sub_C" = "C"),
                                  id_col = "id")
  )
  gen_scenarios <- out[out$specialty_primary == "Generalist", "scenario"]
  expect_equal(gen_scenarios, c("A", "B", "C", "A"))
})
