suppressWarnings(library(sf))

test_that("mysterycall_calculate_overlap enforces alignment and records area method", {
  square <- sf::st_polygon(list(rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1), c(0, 0))))
  bg <- sf::st_sf(
    GEOID = "000000000000",
    vintage = 2020,
    geometry = sf::st_sfc(square, crs = 4326)
  )
  iso <- sf::st_sf(
    drive_time = 30,
    data_year = 2020,
    geometry = sf::st_sfc(square, crs = 4326)
  )

  out_dir <- tempfile("iso_test_match_")
  dir.create(out_dir)

  mysterycall_calculate_overlap(
    bg,
    iso,
    drive_time_minutes = 30,
    output_dir = out_dir,
    notify = FALSE
  )

  shp <- file.path(out_dir, "intersect_30_minutes.shp")
  expect_true(file.exists(shp))

  res <- sf::st_read(shp, quiet = TRUE)
  # Shapefiles truncate column names to 10 chars: "area_method" → "ar_mthd"
  area_col <- intersect(c("area_method", "ar_mthd"), names(res))
  expect_true(length(area_col) > 0)
  expect_equal(unique(res[[area_col[1]]]), "projected:EPSG:5070")
})

test_that("mysterycall_calculate_overlap blocks unsupported vintage mismatches", {
  square <- sf::st_polygon(list(rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1), c(0, 0))))
  bg <- sf::st_sf(
    GEOID = "000000000000",
    vintage = 2020,
    geometry = sf::st_sfc(square, crs = 4326)
  )
  iso <- sf::st_sf(
    drive_time = 30,
    data_year = 2019,
    geometry = sf::st_sfc(square, crs = 4326)
  )

  expect_error(
    mysterycall_calculate_overlap(
      bg,
      iso,
      drive_time_minutes = 30,
      output_dir = tempdir(),
      notify = FALSE
    ),
    "differ"
  )
})

test_that("mysterycall_calculate_overlap accepts crosswalk function for 2010/2020", {
  square <- sf::st_polygon(list(rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1), c(0, 0))))
  bg <- sf::st_sf(
    GEOID = "000000000000",
    vintage = 2010,
    geometry = sf::st_sfc(square, crs = 4326)
  )
  iso <- sf::st_sf(
    drive_time = 30,
    data_year = 2020,
    geometry = sf::st_sfc(square, crs = 4326)
  )

  crosswalk <- function(x, years) {
    expect_equal(years$from, 2010)
    expect_equal(years$to, 2020)
    x$vintage <- years$to
    x
  }

  out_dir <- tempfile("iso_test_crosswalk_")
  dir.create(out_dir)

  mysterycall_calculate_overlap(
    bg,
    iso,
    drive_time_minutes = 30,
    output_dir = out_dir,
    crosswalk = crosswalk,
    notify = FALSE
  )

  expect_true(file.exists(file.path(out_dir, "intersect_30_minutes.shp")))
})

test_that("mysterycall_calculate_overlap reports available drive times when requested value is missing", {
  square <- sf::st_polygon(list(rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1), c(0, 0))))
  bg <- sf::st_sf(
    GEOID = "000000000000",
    vintage = 2020,
    geometry = sf::st_sfc(square, crs = 4326)
  )
  iso <- sf::st_sf(
    drive_time = c(30, 60),
    data_year = c(2020, 2020),
    geometry = sf::st_sfc(square, square, crs = 4326)
  )

  expect_error(
    mysterycall_calculate_overlap(
      bg,
      iso,
      drive_time_minutes = 45,
      output_dir = tempdir(),
      notify = FALSE
    ),
    "Available drive_time values: 30, 60"
  )
})
