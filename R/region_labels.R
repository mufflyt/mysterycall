# Region labels for a US state choropleth
# -----------------------------------------------------------------------------
# Turns the state -> region mapping from mysterycall_assign_region() into a
# ready-to-plot table of per-state labels positioned at state centroids, so a
# choropleth can annotate each state with its AAO-HNS (or ACOG / Census) region
# without hand-placing text. Uses base R datasets::state.center, so no spatial
# dependency is required.
# -----------------------------------------------------------------------------

#' Region Labels for a US State Choropleth
#'
#' Returns one row per US state with its region label and an approximate
#' centroid, ready to overlay on a state choropleth as a
#' [ggplot2::geom_text()] layer -- e.g. to label each state with its AAO-HNS
#' district. Region assignments come from [mysterycall_assign_region()];
#' centroids use base R `datasets::state.center`, so no spatial packages are
#' needed.
#'
#' @param system Region system passed to [mysterycall_assign_region()]. One of
#'   `"aao_hns"` (default), `"acog"`, or `"census"`.
#' @param label Character. Which column is exposed as `label` for convenience:
#'   `"region"` (default) or `"abbr"` (the two-letter state code).
#'
#' @return A data frame with one row per of the 50 US states and columns
#'   `state`, `abbr`, `region`, `lon`, `lat`, and `label`. Because
#'   `datasets::state.center` covers only the 50 states, the District of
#'   Columbia and territories are not included; add their label positions
#'   manually if your map shows them.
#'
#' @family mapping
#' @seealso [mysterycall_assign_region()]
#' @export
#'
#' @examples
#' labs <- mysterycall_region_labels(system = "aao_hns")
#' head(labs)
#'
#' # Overlay on a state choropleth (ggplot2):
#' \dontrun{
#' ggplot2::ggplot() +
#'   ggplot2::geom_sf(data = states_sf, ggplot2::aes(fill = region)) +
#'   ggplot2::geom_text(
#'     data = mysterycall_region_labels(),
#'     ggplot2::aes(x = lon, y = lat, label = label), size = 3
#'   )
#' }
mysterycall_region_labels <- function(system = c("aao_hns", "acog", "census"),
                                      label  = c("region", "abbr")) {
  system <- match.arg(system)
  label  <- match.arg(label)

  states <- datasets::state.name
  abbr   <- datasets::state.abb
  region <- mysterycall_assign_region(states, system = system)

  out <- data.frame(
    state  = states,
    abbr   = abbr,
    region = region,
    lon    = datasets::state.center$x,
    lat    = datasets::state.center$y,
    stringsAsFactors = FALSE
  )
  out$label <- if (label == "abbr") out$abbr else out$region
  out
}
