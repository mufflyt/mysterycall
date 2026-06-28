skip_if_not_installed("sf")

make_square_sf <- function(...) {
  square <- sf::st_polygon(list(rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1), c(0, 0))))
  sf::st_sf(..., geometry = sf::st_sfc(square, crs = 4326))
}

test_that("mysterycall_calculate_overlap checkmate validations trigger", {
  bg <- make_square_sf(GEOID = "000000000000", vintage = 2020)
  iso <- make_square_sf(drive_time = 30, data_year = 2020)

  expect_error(mysterycall_calculate_overlap(NULL, iso, 30, tempdir(), notify = FALSE), "block_groups")
  expect_error(mysterycall_calculate_overlap(bg, NULL, 30, tempdir(), notify = FALSE), "isochrones_joined")
  expect_error(mysterycall_calculate_overlap(bg, iso, -1, tempdir(), notify = FALSE), "drive_time_minutes")
  expect_error(mysterycall_calculate_overlap(bg, iso, 30, "", notify = FALSE), "output_dir")
  expect_error(mysterycall_calculate_overlap(bg, iso, 30, tempdir(), notify = "no"), "notify")
})

test_that("mysterycall_map_block_group checkmate validations trigger", {
  bg <- make_square_sf(GEOID = "000000000000", NAMELSAD = "BG", overlap = 0.5, vintage = 2020)
  iso <- make_square_sf(drive_time = 30)

  expect_error(mysterycall_map_block_group(NULL, iso, tempdir()), "bg_data")
  expect_error(mysterycall_map_block_group(bg, NULL, tempdir()), "isochrones_data")
  expect_error(mysterycall_map_block_group(bg, iso, ""), "output_dir")
  expect_error(mysterycall_map_block_group(bg |> dplyr::mutate(overlap = 1.5), iso, tempdir()), "bg_data\\$overlap")
  expect_error(mysterycall_map_block_group(bg, iso |> dplyr::mutate(drive_time = "thirty"), tempdir()), "drive_time")
})
