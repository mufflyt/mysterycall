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

#' Calculate Haversine Distance to Platform Headquarters
#'
#' Computes the geographic distance (in miles) between a clinic's coordinates and
#' its corresponding private equity platform's regional headquarters.
#' For control practices, the function uses the headquarters of the platform to
#' which its matched PE pair belongs.
#'
#' @param lats Numeric vector of clinic latitudes.
#' @param lons Numeric vector of clinic longitudes.
#' @param platforms Character vector of platform/practice names.
#' @param matched_pairs Character vector of matched pair group IDs.
#' @return A numeric vector of distances in miles.
#' @export
mysterycall_calculate_hq_distance <- function(lats, lons, platforms, matched_pairs) {
  if (length(lats) != length(lons) || length(lats) != length(platforms)) {
    stop("lats, lons, and platforms must be of the same length.")
  }
  
  # Define regional HQ coordinates
  hq_coords <- list(
    "Unified Women's Healthcare" = c(26.3683, -80.1289), # Boca Raton, FL
    "Axia Women's Health" = c(39.8459, -74.9943),        # Voorhees, NJ
    "Women's Care Enterprises" = c(27.9506, -82.4572),   # Tampa, FL
    "Together Women's Health" = c(42.3995, -82.9121),    # Grosse Pointe Farms, MI
    "CCRM Fertility" = c(39.5448, -104.8770),            # Lone Tree, CO
    "Advantia Health" = c(38.8904, -77.0842),            # Arlington, VA
    "US Fertility" = c(39.0840, -77.1528),               # Rockville, MD
    "Kindbody" = c(40.7128, -74.0060),                   # New York, NY
    "IVI RMA Global" = c(40.7062, -74.5493),             # Basking Ridge, NJ
    "Femwell Group Health" = c(25.7617, -80.1918),       # Miami, FL
    "Nova Women's Health Partners" = c(42.3601, -71.0589), # Boston, MA
    "OB Hospitalist Group" = c(34.7812, -82.3082)         # Mauldin, SC
  )
  
  r <- 3959 # Earth's radius in miles
  n <- length(lats)
  distances <- numeric(n)
  
  # Pre-resolve control platforms by matching pair
  pe_platform_map <- list()
  for (i in seq_along(platforms)) {
    plat <- platforms[i]
    pair <- matched_pairs[i]
    if (!is.na(pair) && pair != "" && pair != "NA" && plat != "Control Group") {
      pe_platform_map[[pair]] <- plat
    }
  }
  
  for (i in seq_len(n)) {
    lat <- lats[i]
    lon <- lons[i]
    plat <- platforms[i]
    pair <- matched_pairs[i]
    
    if (is.na(lat) || is.na(lon)) {
      distances[i] <- NA
      next
    }
    
    # Resolve platform for controls
    resolved_plat <- plat
    if (plat == "Control Group" && !is.na(pair) && pair != "" && pair != "NA") {
      if (pair %in% names(pe_platform_map)) {
        resolved_plat <- pe_platform_map[[pair]]
      }
    }
    
    # Handle Unified subdivisions
    if (!is.null(resolved_plat) && grepl("Unified Women's Healthcare", resolved_plat)) {
      resolved_plat <- "Unified Women's Healthcare"
    }
    
    # Get HQ coordinates
    coords <- if (!is.null(resolved_plat)) hq_coords[[resolved_plat]] else NULL
    if (is.null(coords)) {
      distances[i] <- NA
      next
    }
    
    # Haversine formula
    phi1 <- lat * pi / 180
    phi2 <- coords[1] * pi / 180
    d_phi <- (coords[1] - lat) * pi / 180
    d_lam <- (coords[2] - lon) * pi / 180
    
    a <- sin(d_phi / 2)^2 + cos(phi1) * cos(phi2) * sin(d_lam / 2)^2
    c <- 2 * atan2(sqrt(a), sqrt(1 - a))
    distances[i] <- r * c
  }
  
  return(distances)
}
