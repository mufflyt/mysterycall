# Production Baseline Metrics
# These represent known-good performance from production runs
# Update these when expected behavior changes intentionally

BASELINE_METRICS <- list(
  # Version and date
  version = "1.0.0",
  date_established = "2025-10-29",

  # NPI Search Performance
  npi_search = list(
    match_rate = 0.85,          # 85% of physicians should match
    match_rate_tolerance = 0.05, # Allow 5% deviation
    min_acceptable = 0.75,       # Never go below 75%
    description = "Percentage of input physicians that successfully match to an NPI"
  ),

  # Geocoding Performance
  geocoding = list(
    success_rate = 0.92,         # 92% should geocode successfully
    success_rate_tolerance = 0.05,
    min_acceptable = 0.85,
    coordinate_precision = 4,     # Minimum 4 decimal places
    us_bounds_rate = 0.95,       # 95% should be in US bounds
    description = "Percentage of addresses that successfully geocode"
  ),

  # Genderization Performance
  genderization = list(
    assignment_rate = 0.88,      # 88% should get gender assignment
    assignment_rate_tolerance = 0.05,
    min_acceptable = 0.80,
    high_confidence_rate = 0.75, # 75% should have probability > 0.8
    description = "Percentage of first names that successfully get gender assigned"
  ),

  # Data Retention (pipeline data loss)
  data_retention = list(
    phase1_retention = 0.95,     # Lose max 5% in phase 1
    phase2_retention = 0.90,     # Lose max 10% in phase 2
    overall_retention = 0.85,    # Lose max 15% overall
    tolerance = 0.05,
    description = "Percentage of input records retained through pipeline"
  ),

  # Data Quality
  data_quality = list(
    # Critical columns should have < 20% NA
    max_na_rate_critical = 0.20,
    critical_columns = c("npi", "lat", "lon", "state", "practice_name"),

    # Non-critical columns can have < 50% NA
    max_na_rate_noncritical = 0.50,

    # No duplicate NPIs
    max_duplicate_npi_rate = 0.01,  # Allow 1% (measurement error)

    description = "Data quality thresholds for analysis-ready data"
  ),

  # Categorical Value Domains
  categorical_domains = list(
    gender = c("M", "F", "Male", "Female", "male", "female", NA_character_),
    state = c(state.abb, state.name, NA_character_),
    yes_no = c("Yes", "No", "YES", "NO", "yes", "no", NA_character_),
    description = "Valid domains for categorical variables"
  ),

  # Performance Benchmarks
  performance = list(
    # Rows per second for mysterycall_clean_phase1
    phase1_rows_per_sec = 50,
    phase1_tolerance = 0.30,     # Allow 30% slower

    # NPI search timeout per record
    npi_search_timeout_sec = 2,

    # Geocoding timeout per address
    geocoding_timeout_sec = 1,

    # Maximum memory per 1000 rows
    max_memory_per_1k_mb = 100,

    description = "Performance benchmarks for pipeline operations"
  ),

  # Spatial Analysis
  spatial = list(
    # Coordinates should be in US bounds
    us_lat_range = c(24.396308, 49.384358),  # Contiguous US
    us_lon_range = c(-125.0, -66.93457),

    # Fraction of geocoded coordinates expected to fall within US bounds
    us_bounds_rate = 0.90,
    us_bounds_tolerance = 0.05,

    # Census block group join success
    blockgroup_join_rate = 0.90,
    blockgroup_join_tolerance = 0.05,

    # Isochrone generation success
    isochrone_success_rate = 0.88,
    isochrone_success_tolerance = 0.05,

    description = "Spatial analysis quality metrics"
  )
)

# Helper function to check if metric is within acceptable range
check_metric_regression <- function(current_value,
                                   baseline_value,
                                   tolerance = 0.05,
                                   min_acceptable = NULL) {

  # Calculate bounds
  lower_bound <- baseline_value - tolerance
  if (!is.null(min_acceptable)) {
    lower_bound <- max(lower_bound, min_acceptable)
  }
  upper_bound <- baseline_value + tolerance

  list(
    current = current_value,
    baseline = baseline_value,
    lower_bound = lower_bound,
    upper_bound = upper_bound,
    passed = current_value >= lower_bound && current_value <= upper_bound,
    below_minimum = !is.null(min_acceptable) && current_value < min_acceptable,
    deviation_pct = 100 * (current_value - baseline_value) / baseline_value
  )
}

# Helper to format regression test failure message
format_regression_message <- function(metric_name, check_result) {
  sprintf(
    "❌ REGRESSION in %s: Current %.2f%% vs Baseline %.2f%% (deviation: %+.1f%%, bounds: %.2f%% - %.2f%%)",
    metric_name,
    check_result$current * 100,
    check_result$baseline * 100,
    check_result$deviation_pct,
    check_result$lower_bound * 100,
    check_result$upper_bound * 100
  )
}
