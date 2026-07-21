#' Per-cluster scenario coverage for a matched multi-scenario audit
#'
#' A matched mystery-caller design calls the *same* practice under two or more
#' scenarios (insurance types, caller personas), and the paired analyses
#' ([mysterycall_paired_acceptance_mcnemar()],
#' [mysterycall_paired_wait_within_practice()]) only draw information from
#' clusters observed under both arms of a contrast. Before running them it is
#' worth knowing how complete the design actually is: how many practices were
#' reached under the *full* set of scenarios versus only a partial set, and which
#' scenario is short. A mistyped or unmatched cluster key silently becomes a
#' one-scenario singleton and deflates the paired denominator, so this coverage
#' check is a design-integrity guard as much as a descriptive table. Pair it with
#' [mysterycall_flag_near_duplicate_keys()] to catch the mistyped keys that cause
#' spurious singletons.
#'
#' @param data A long data frame: one row per cluster x scenario call.
#' @param id_col Cluster / practice identifier column.
#' @param scenario_col Scenario column.
#' @param scenarios Optional character vector naming the scenario levels the
#'   design intended. When `NULL` (default) all non-missing values found in
#'   `scenario_col` are used. A "complete" cluster is one observed under every
#'   scenario in this set. Names not present in the data are still reported (as
#'   fully missing), so you can assert the design you *meant* to run.
#' @param output_dir,filename Optional CSV export of the per-cluster coverage
#'   table. `output_dir = NA` (default) skips writing; `NULL` writes to a session
#'   temp directory via [mysterycall_tempdir()].
#'
#' @return An object of class `"mysterycall_scenario_coverage"`: a list with
#'   \describe{
#'     \item{`coverage`}{[tibble::tibble()], one row per cluster: `id`, a logical
#'       `has_<scenario>` column per scenario level, and `n_scenarios` (how many
#'       of the intended scenarios were observed).}
#'     \item{`summary`}{[tibble::tibble()] design totals: `n_clusters`,
#'       `n_complete` (observed under all scenarios), `n_partial`, `n_singleton`,
#'       plus one `n_missing_<scenario>` count per scenario.}
#'     \item{`scenarios`}{The scenario levels used.}
#'   }
#'   [as.data.frame()] returns the per-cluster `coverage` table.
#'
#' @family descriptive helpers
#' @seealso [mysterycall_paired_acceptance_mcnemar()],
#'   [mysterycall_flag_near_duplicate_keys()]
#' @examples
#' d <- data.frame(
#'   practice = c(1, 1, 1, 2, 2, 3),
#'   scenario = c("Straight", "Lesbian", "Single mother",
#'                "Straight", "Lesbian", "Straight")
#' )
#' mysterycall_scenario_coverage(d, "practice", "scenario")
#' @export
mysterycall_scenario_coverage <- function(data, id_col, scenario_col,
                                          scenarios = NULL,
                                          output_dir = NA, filename = NA) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_choice(id_col, names(data))
  checkmate::assert_choice(scenario_col, names(data))
  checkmate::assert_character(scenarios, min.len = 1L, any.missing = FALSE,
                              null.ok = TRUE)

  scen_vec <- as.character(data[[scenario_col]])
  if (is.null(scenarios)) {
    scenarios <- sort(unique(scen_vec[!is.na(scen_vec) & nzchar(scen_vec)]))
  }
  if (length(scenarios) < 1L) {
    stop("No scenario levels found in `scenario_col`.", call. = FALSE)
  }

  ids <- unique(data[[id_col]])
  ids <- ids[!is.na(ids)]
  if (length(ids) < 1L) stop("No non-missing cluster ids found.", call. = FALSE)

  # Logical membership: was cluster i seen under scenario j?
  present <- vapply(scenarios, function(s) {
    seen <- unique(data[[id_col]][!is.na(scen_vec) & scen_vec == s])
    ids %in% seen
  }, logical(length(ids)))
  present <- matrix(present, nrow = length(ids),
                    dimnames = list(NULL, scenarios))

  n_scenarios <- rowSums(present)
  coverage <- data.frame(id = ids, stringsAsFactors = FALSE)
  for (s in scenarios) coverage[[paste0("has_", s)]] <- present[, s]
  coverage$n_scenarios <- as.integer(n_scenarios)
  coverage <- tibble::as_tibble(coverage)

  n_target <- length(scenarios)
  summary_tbl <- tibble::tibble(
    n_clusters  = length(ids),
    n_complete  = sum(n_scenarios == n_target),
    n_partial   = sum(n_scenarios > 1L & n_scenarios < n_target),
    n_singleton = sum(n_scenarios == 1L)
  )
  for (s in scenarios) {
    summary_tbl[[paste0("n_missing_", s)]] <- sum(!present[, s])
  }

  if (!identical(output_dir, NA)) {
    dir <- if (is.null(output_dir)) mysterycall_tempdir() else output_dir
    fname <- if (is.na(filename)) "scenario_coverage.csv" else filename
    utils::write.csv(coverage, file.path(dir, fname), row.names = FALSE)
  }

  structure(
    list(coverage = coverage, summary = summary_tbl, scenarios = scenarios),
    class = "mysterycall_scenario_coverage"
  )
}

#' @export
print.mysterycall_scenario_coverage <- function(x, ...) {
  s <- x$summary
  cat("Scenario coverage across", s$n_clusters, "clusters\n")
  cat(sprintf("  complete (all %d scenarios): %d\n",
              length(x$scenarios), s$n_complete))
  cat(sprintf("  partial (2+ but not all):    %d\n", s$n_partial))
  cat(sprintf("  singleton (1 scenario):      %d\n", s$n_singleton))
  miss <- grep("^n_missing_", names(s), value = TRUE)
  for (m in miss) {
    cat(sprintf("  missing %-20s %d\n",
                paste0(sub("^n_missing_", "", m), ":"), s[[m]]))
  }
  invisible(x)
}

#' @export
as.data.frame.mysterycall_scenario_coverage <- function(x, ...) {
  as.data.frame(x$coverage, ...)
}
