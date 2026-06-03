#' Assign call scenarios to generalist providers
#'
#' @name mysterycall_assign_scenarios
NULL


#' Assign call scenarios to generalist providers based on local subspecialty availability
#'
#' In mystery caller studies, generalist providers are called using a vignette
#' that matches a subspecialty present in the same city/state. This function
#' groups providers by location, detects which subspecialty scenarios are
#' available locally, and assigns scenarios to generalists in round-robin order
#' so that calls are balanced across scenarios.
#'
#' Non-generalist rows receive their own specialty as the scenario. Generalists
#' in locations that have no matching subspecialists receive `NA`.
#'
#' @param data A data frame containing provider records. One row = one provider.
#' @param location_cols Character vector of column names that define a
#'   geographic group (default `c("city", "state_code")`). Rows are grouped by
#'   all columns together.
#' @param specialty_col Character scalar. Column holding each provider's
#'   specialty (default `"specialty_primary"`).
#' @param generalist_level Character scalar. The value in `specialty_col` that
#'   identifies generalist providers who will receive scenario assignments.
#' @param scenario_map Named character vector mapping subspecialty values in
#'   `specialty_col` to scenario labels. Example:
#'   `c("Neurotology" = "Neurotology", "Pediatric Otolaryngology" = "Pediatric Otolaryngology")`.
#'   Each name is a value that appears in `specialty_col`; each value is the
#'   scenario label that will be assigned to generalists in cities where that
#'   subspecialty is present. **The subspecialty values used as names here must
#'   derive from board certification data (e.g. ABOHNS via
#'   [mysterycall_parse_certification_subspecialty()]) and must not come from
#'   NPPES `taxonomies_desc` or DAC taxonomy codes.**
#' @param id_col Optional character scalar. Column used to sort rows within each
#'   location group before round-robin assignment. When `NULL` (default) the
#'   existing row order is used.
#' @param scenario_col Character scalar. Name of the new scenario column to
#'   create (default `"scenario"`).
#'
#' @return `data` with one additional character column named `scenario_col`.
#'
#' @seealso [mysterycall_check_generalist_presence()] to validate paired
#'   generalist coverage before assigning scenarios;
#'   [mysterycall_reconcile_specialty()] for specialty harmonization.
#' @family study design
#' @keywords internal
#'
#' @examples
#' df <- data.frame(
#'   city          = c("Denver", "Denver", "Denver", "Denver", "Boulder", "Boulder"),
#'   state_code    = "CO",
#'   specialty_primary = c(
#'     "General Otolaryngology", "General Otolaryngology",
#'     "Neurotology", "Pediatric Otolaryngology",
#'     "General Otolaryngology", "Neurotology"
#'   ),
#'   id = 1:6,
#'   stringsAsFactors = FALSE
#' )
#' mysterycall_assign_scenarios(
#'   df,
#'   generalist_level = "General Otolaryngology",
#'   scenario_map     = c("Neurotology"               = "Neurotology",
#'                        "Pediatric Otolaryngology"  = "Pediatric Otolaryngology"),
#'   id_col           = "id"
#' )
mysterycall_assign_scenarios <- function(data,
                                          location_cols    = c("city", "state_code"),
                                          specialty_col    = "specialty_primary",
                                          generalist_level,
                                          scenario_map,
                                          id_col           = NULL,
                                          scenario_col     = "scenario") {

  validate_dataframe(data, name = "data", allow_zero_rows = FALSE)
  validate_required_columns(data, c(location_cols, specialty_col), name = "data")

  if (!is.character(generalist_level) || length(generalist_level) != 1L || !nzchar(generalist_level)) {
    stop("`generalist_level` must be a non-empty character scalar.", call. = FALSE)
  }
  if (!is.character(scenario_map) || is.null(names(scenario_map)) || length(scenario_map) == 0L) {
    stop("`scenario_map` must be a named character vector with at least one entry.", call. = FALSE)
  }
  if (!is.character(scenario_col) || length(scenario_col) != 1L || !nzchar(scenario_col)) {
    stop("`scenario_col` must be a non-empty character scalar.", call. = FALSE)
  }
  if (!is.null(id_col)) {
    validate_required_columns(data, id_col, name = "data")
  }

  subspecialty_values <- names(scenario_map)

  # -- Process each location group ---------------------------------------------
  data[[scenario_col]] <- NA_character_

  groups <- unique(data[, location_cols, drop = FALSE])

  for (g_idx in seq_len(nrow(groups))) {
    grp_filter <- rep(TRUE, nrow(data))
    for (col in location_cols) {
      grp_filter <- grp_filter & (data[[col]] == groups[[col]][[g_idx]])
    }
    grp_rows <- which(grp_filter)

    # Which scenarios are available in this group?
    specs_in_group <- data[[specialty_col]][grp_rows]
    available_scenarios <- scenario_map[names(scenario_map) %in% specs_in_group]

    # Non-generalists: scenario = their own specialty
    non_gen_mask <- grp_rows[specs_in_group != generalist_level]
    if (length(non_gen_mask)) {
      data[[scenario_col]][non_gen_mask] <- data[[specialty_col]][non_gen_mask]
    }

    # Generalists: round-robin across available scenarios
    gen_mask <- grp_rows[specs_in_group == generalist_level]
    if (!length(gen_mask) || !length(available_scenarios)) next

    # Sort generalist rows by id_col if requested
    if (!is.null(id_col)) {
      gen_order <- order(data[[id_col]][gen_mask])
      gen_mask  <- gen_mask[gen_order]
    }

    scenario_labels <- unname(available_scenarios)
    n_scenarios <- length(scenario_labels)
    for (rank_i in seq_along(gen_mask)) {
      data[[scenario_col]][gen_mask[[rank_i]]] <- scenario_labels[[(rank_i - 1L) %% n_scenarios + 1L]]
    }
  }

  n_assigned <- sum(!is.na(data[[scenario_col]][data[[specialty_col]] == generalist_level]))
  n_gen      <- sum(data[[specialty_col]] == generalist_level, na.rm = TRUE)
  message(sprintf(
    "Scenarios assigned to %d/%d generalist rows; stored in column '%s'.",
    n_assigned, n_gen, scenario_col
  ))

  data
}
