#' State-Level Choropleth Map of Acceptance Rates
#'
#' @name mysterycall_geographic_map
NULL

#' Create a state-level choropleth map of acceptance rates
#'
#' Draws a CONUS (or full US) choropleth of per-state appointment acceptance
#' rates using \pkg{ggplot2}, \pkg{maps}, and \pkg{viridis}. Binary 0/1
#' outcome columns are aggregated to per-state means automatically; columns
#' already containing rates (0-1) are used directly.
#'
#' @section State identifier format:
#' The function detects whether `state_col` contains abbreviations or full
#' names by sampling the first non-missing value. When the value is two
#' characters or fewer it is treated as an abbreviation and looked up in
#' [base::state.abb] / [base::state.name]. Longer values are lower-cased
#' and joined directly to the map polygon data. DC and US territories are not
#' present in the built-in datasets and will appear as no-data states.
#'
#' @section Outcome aggregation:
#' When every non-missing value in `outcome_col` is exactly 0 or 1, the column
#' is treated as binary and aggregated to a per-state acceptance rate via
#' [base::tapply()] (`mean(x, na.rm = TRUE)`). Any other numeric column is
#' also averaged per state, so passing a pre-computed rate works as expected.
#'
#' @param data data.frame. Must contain at least `state_col` and `outcome_col`.
#' @param state_col Character. Column containing state abbreviations (e.g.
#'   `"CO"`, `"CA"`) or full state names (e.g. `"Colorado"`). Default
#'   `"state"`.
#' @param outcome_col Character. Column containing either binary 0/1 outcomes
#'   or per-observation acceptance rates (0-1 numeric). Default `"offered"`.
#' @param fill_label Character. Legend title shown on the fill scale. Default
#'   `"Acceptance rate"`.
#' @param title Character or `NULL`. Plot title. Default `NULL`.
#' @param subtitle Character or `NULL`. Plot subtitle. Default `NULL`.
#' @param palette Character. Viridis color palette. One of `"viridis"`,
#'   `"magma"`, `"plasma"`, `"inferno"`, or `"cividis"`. Default `"viridis"`.
#' @param direction Integer. Viridis scale direction: `1` (low color = low
#'   value; default) or `-1` (reversed).
#' @param low_states_warn Integer. Issue a [base::warning()] for any state
#'   with fewer than this many non-missing observations. Default `5L`.
#' @param na_color Character. Fill color for states not present in `data`.
#'   Default `"grey80"`.
#' @param include_alaska_hawaii Logical. When `FALSE` (default), Alaska (`AK`)
#'   and Hawaii (`HI`) are dropped before aggregation and mapping, producing a
#'   standard CONUS choropleth.
#'
#' @return A `ggplot` object of class `c("gg", "ggplot")`, returned invisibly.
#'   Print or assign the return value to display the map.
#'
#' @family reporting
#' @seealso [mysterycall_map_acceptance_rate()] for a simpler one-call
#'   choropleth; [mysterycall_forest_plot()] for model-level visualization.
#' @export
#'
#' @examples
#' \dontrun{
#' # --- Binary outcome example (0/1 call outcomes per row) --------------------
#' set.seed(42)
#' n <- 300
#' df <- data.frame(
#'   state   = sample(c("CO", "CA", "TX", "NY", "FL", "WA", "OR"), n,
#'                    replace = TRUE),
#'   offered = rbinom(n, 1, 0.60),
#'   stringsAsFactors = FALSE
#' )
#' p <- mysterycall_geographic_map(
#'   df,
#'   title    = "Appointment Acceptance Rate by State",
#'   subtitle = "Mystery-caller study, n = 300 calls"
#' )
#' print(p)
#'
#' # --- Pre-aggregated rates (one row per state) ------------------------------
#' rate_df <- data.frame(
#'   state = c("CO", "CA", "TX", "NY", "FL"),
#'   rate  = c(0.55, 0.72, 0.48, 0.63, 0.81),
#'   stringsAsFactors = FALSE
#' )
#' mysterycall_geographic_map(
#'   rate_df,
#'   outcome_col = "rate",
#'   palette     = "plasma",
#'   direction   = -1L,
#'   fill_label  = "Acceptance\nrate"
#' )
#' }
mysterycall_geographic_map <- function(data,
                                        state_col             = "state",
                                        outcome_col           = "offered",
                                        fill_label            = "Acceptance rate",
                                        title                 = NULL,
                                        subtitle              = NULL,
                                        palette               = c("viridis", "magma", "plasma",
                                                                  "inferno", "cividis"),
                                        direction             = 1L,
                                        low_states_warn       = 5L,
                                        na_color              = "grey80",
                                        include_alaska_hawaii = FALSE) {

  # ---- Package guards ---------------------------------------------------------
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop(
      "Package 'ggplot2' is required. Install with: install.packages('ggplot2')",
      call. = FALSE
    )
  }
  if (!requireNamespace("maps", quietly = TRUE)) {
    stop(
      "Package 'maps' is required. Install with: install.packages('maps')",
      call. = FALSE
    )
  }
  # ---- Input validation -------------------------------------------------------
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!is.character(state_col) || length(state_col) != 1L) {
    stop("`state_col` must be a single character string.", call. = FALSE)
  }
  if (!is.character(outcome_col) || length(outcome_col) != 1L) {
    stop("`outcome_col` must be a single character string.", call. = FALSE)
  }
  if (!state_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", state_col), call. = FALSE)
  }
  if (!outcome_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", outcome_col), call. = FALSE)
  }
  if (!is.null(title) && (!is.character(title) || length(title) != 1L)) {
    stop("`title` must be a single character string or NULL.", call. = FALSE)
  }
  if (!is.null(subtitle) && (!is.character(subtitle) || length(subtitle) != 1L)) {
    stop("`subtitle` must be a single character string or NULL.", call. = FALSE)
  }

  palette   <- match.arg(palette)
  direction <- as.integer(direction)
  if (!direction %in% c(1L, -1L)) {
    stop("`direction` must be 1 or -1.", call. = FALSE)
  }
  if (!is.numeric(low_states_warn) || length(low_states_warn) != 1L ||
      low_states_warn < 0) {
    stop("`low_states_warn` must be a non-negative integer scalar.", call. = FALSE)
  }
  if (!is.logical(include_alaska_hawaii) || length(include_alaska_hawaii) != 1L) {
    stop("`include_alaska_hawaii` must be a single logical value.", call. = FALSE)
  }

  # ---- Extract working vectors ------------------------------------------------
  state_raw   <- as.character(data[[state_col]])
  outcome_raw <- data[[outcome_col]]

  if (!is.numeric(outcome_raw)) {
    stop(sprintf("Column '%s' must be numeric.", outcome_col), call. = FALSE)
  }

  non_na_states <- state_raw[!is.na(state_raw)]
  if (length(non_na_states) == 0L) {
    stop("No non-missing values found in `state_col`.", call. = FALSE)
  }

  # ---- State abbreviation -> lowercase full name lookup -----------------------
  # Uses built-in state.abb / state.name (50 US states; DC and territories absent).
  abb_to_lower <- stats::setNames(tolower(state.name), state.abb)

  sample_state <- non_na_states[1L]
  if (nchar(sample_state) <= 2L) {
    # Abbreviations: look up lowercase full name; unknown abbreviations map to NA.
    state_joined <- abb_to_lower[toupper(state_raw)]
  } else {
    # Full names: lowercase for joining with map polygon region labels.
    state_joined <- tolower(state_raw)
  }

  # ---- Optionally drop Alaska and Hawaii --------------------------------------
  if (!include_alaska_hawaii) {
    is_ak_hi <- (toupper(state_raw) %in% c("AK", "HI")) |
                (!is.na(state_joined) & (state_joined %in% c("alaska", "hawaii")))
    keep         <- !is_ak_hi
    state_raw    <- state_raw[keep]
    outcome_raw  <- outcome_raw[keep]
    state_joined <- state_joined[keep]
  }

  # ---- Detect outcome type and aggregate per state ----------------------------
  non_na_outcome <- outcome_raw[!is.na(outcome_raw)]
  if (length(non_na_outcome) == 0L) {
    stop("No non-missing values found in `outcome_col`.", call. = FALSE)
  }

  is_binary <- all(non_na_outcome %in% c(0, 1))

  if (!is_binary && any(non_na_outcome < 0 | non_na_outcome > 1)) {
    warning(
      "Some values in `outcome_col` fall outside [0, 1]; ",
      "they are treated as rates and averaged per state.",
      call. = FALSE
    )
  }

  # Both binary and continuous branches aggregate to per-state mean.
  rates_by_state <- tapply(outcome_raw, state_joined, mean, na.rm = TRUE)

  # ---- Warn on states with low observation counts ----------------------------
  n_by_state <- tapply(outcome_raw, state_joined, function(x) sum(!is.na(x)))
  low_thresh <- as.integer(low_states_warn)
  low_n_names <- names(n_by_state)[
    !is.na(n_by_state) & n_by_state < low_thresh
  ]
  if (length(low_n_names) > 0L) {
    warning(
      sprintf(
        "The following state(s) have fewer than %d observation(s): %s",
        low_thresh,
        paste(low_n_names, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  # ---- Build per-state rate data frame ----------------------------------------
  rate_df <- data.frame(
    region = names(rates_by_state),
    rate   = as.numeric(rates_by_state),
    stringsAsFactors = FALSE
  )

  # ---- Fetch polygon data (maps package accessed via ggplot2::map_data) -------
  map_poly <- ggplot2::map_data("state")

  # ---- Merge rates into polygon data (left join keeps all polygons) -----------
  merged <- merge(
    map_poly,
    rate_df,
    by    = "region",
    all.x = TRUE
  )
  # Restore correct polygon draw order after merge scrambles rows.
  merged <- merged[order(merged$group, merged$order), ]

  # ---- Build ggplot2 object ---------------------------------------------------
  p <- ggplot2::ggplot(
      merged,
      ggplot2::aes(
        x     = .data$long,
        y     = .data$lat,
        group = .data$group,
        fill  = .data$rate
      )
    ) +
    ggplot2::geom_polygon(color = "white", linewidth = 0.2) +
    ggplot2::coord_map("albers", lat0 = 39, lat1 = 45) +
    ggplot2::scale_fill_viridis_c(
      option    = palette,
      direction = direction,
      na.value  = na_color,
      name      = fill_label,
      labels    = scales::percent_format(accuracy = 1)
    ) +
    ggplot2::labs(
      title    = title,
      subtitle = subtitle
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(
      legend.position = "right",
      plot.title      = ggplot2::element_text(
        face  = "bold",
        size  = 12,
        hjust = 0.5
      ),
      plot.subtitle   = ggplot2::element_text(
        size   = 9,
        color  = "grey40",
        hjust  = 0.5,
        margin = ggplot2::margin(b = 6)
      ),
      legend.title    = ggplot2::element_text(size = 9),
      legend.text     = ggplot2::element_text(size = 8)
    )

  invisible(p)
}
