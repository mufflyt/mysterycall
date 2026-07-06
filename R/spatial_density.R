#' Calculate Spatial Density of Clinics (Local Concentration Index)
#'
#' Computes the number of other locations within a specified radius (in miles) 
#' for each coordinate pair in a set of latitudes and longitudes.
#' Uses the Haversine formula for spherical distance.
#'
#' @param lats Numeric vector of latitudes.
#' @param lons Numeric vector of longitudes.
#' @param target_lats Numeric vector of latitudes for the target group to count (e.g. PE clinics). 
#'   If NULL, defaults to the set of lats.
#' @param target_lons Numeric vector of longitudes for the target group to count. 
#'   If NULL, defaults to the set of lons.
#' @param radius Numeric. The search radius in miles. Default is 15.
#' @return An integer vector containing the count of target locations within the radius for each input point.
#' @export
#' @examples
#' lats <- c(42.59, 25.62, 40.26)
#' lons <- c(-83.49, -80.32, -74.52)
#' mysterycall_calculate_spatial_density(lats, lons, radius = 15)
mysterycall_calculate_spatial_density <- function(lats, lons, target_lats = NULL, target_lons = NULL, radius = 15) {
  if (length(lats) != length(lons)) {
    stop("lats and lons must be of the same length.")
  }
  
  if (is.null(target_lats) || is.null(target_lons)) {
    target_lats <- lats
    target_lons <- lons
    self_adjust <- TRUE
  } else {
    if (length(target_lats) != length(target_lons)) {
      stop("target_lats and target_lons must be of the same length.")
    }
    self_adjust <- FALSE
  }
  
  r <- 3959 # Earth's radius in miles
  n_points <- length(lats)
  n_targets <- length(target_lats)
  counts <- integer(n_points)
  
  # Convert degrees to radians for target list
  t_lat_rad <- target_lats * pi / 180
  t_lon_rad <- target_lons * pi / 180
  
  for (i in seq_len(n_points)) {
    lat_rad <- lats[i] * pi / 180
    lon_rad <- lons[i] * pi / 180
    
    # Vectorized Haversine distance
    d_lat <- t_lat_rad - lat_rad
    d_lon <- t_lon_rad - lon_rad
    
    a <- sin(d_lat / 2)^2 + cos(lat_rad) * cos(t_lat_rad) * sin(d_lon / 2)^2
    dists <- r * 2 * atan2(sqrt(a), sqrt(1 - a))
    
    # Count within radius
    within_count <- sum(dists <= radius, na.rm = TRUE)
    
    # Adjust to exclude self-matching if counting within the same set
    if (self_adjust && within_count > 0) {
      within_count <- within_count - 1L
    }
    
    counts[i] <- as.integer(within_count)
  }
  
  return(counts)
}
