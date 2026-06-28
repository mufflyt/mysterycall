#' Caller-management utilities for mystery-caller studies
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name caller_management
NULL

#' Flag locations where generalist physicians are absent
#'
#' In a mystery-caller scenario-assignment workflow, subspecialists at a given
#' city/state need at least one generalist at the same location to pair with
#' (so the generalist can be called with the same insurance in the same city).
#' This function performs the QC check and returns a summary of which
#' locations are missing a generalist.
#'
#' @param data A data frame containing all physicians (generalists and
#'   subspecialists combined).
#' @param location_cols Character vector of column names that together define
#'   a unique location (e.g. `c("city", "state_code")`). Values are
#'   normalized to lower-case before joining.
#' @param specialty_col Character scalar naming the specialty column.
#' @param generalist_level Character scalar. The value in `specialty_col`
#'   that identifies a generalist (e.g. `"General Otolaryngology"`).
#'
#' @return A data frame with one row per unique location that contains
#'   at least one subspecialist, with columns:
#'   \describe{
#'     \item{location}{Concatenation of location columns, separated by `", "`.}
#'     \item{n_subspecialists}{Number of subspecialist physicians.}
#'     \item{n_generalists}{Number of generalist physicians (0 when absent).}
#'     \item{generalist_needed}{`TRUE` when no generalist is present.}
#'   }
#'
#' @seealso [mysterycall_caller_reliability()] for inter-rater reliability
#'   metrics; [mysterycall_assign_scenarios()] to pair generalists with
#'   subspecialists once locations are validated;
#'   [mysterycall_validate_npi()] for row-level NPI validation before
#'   location assignment.
#' @family data management
#' @export
#'
#' @examples
#' df <- data.frame(
#'   city      = c("Denver","Denver","Denver","Austin","Austin"),
#'   state     = c("CO","CO","CO","TX","TX"),
#'   specialty = c("General","Neurotology","Pediatric","Neurotology","General"),
#'   stringsAsFactors = FALSE
#' )
#' mysterycall_check_generalist_presence(df, c("city","state"), "specialty",
#'                                        "General")
mysterycall_check_generalist_presence <- function(data,
                                                   location_cols,
                                                   specialty_col,
                                                   generalist_level) {
  if (!is.data.frame(data))             stop(sprintf("'data' must be a data frame, not %s.", class(data)[1L]), call. = FALSE)
  missing_cols <- setdiff(c(location_cols, specialty_col), names(data))
  if (length(missing_cols) > 0L) {
    stop(sprintf("Columns not found in `data`: %s\nAvailable columns: %s",
                 paste(missing_cols, collapse = ", "),
                 paste(names(data), collapse = ", ")),
         call. = FALSE)
  }

  # Normalise location fields
  loc_norm <- lapply(location_cols, function(col) tolower(trimws(as.character(data[[col]]))))
  loc_key  <- do.call(paste, c(loc_norm, list(sep = "\t")))

  spec     <- as.character(data[[specialty_col]])
  is_gen   <- !is.na(spec) & spec == generalist_level
  is_sub   <- !is.na(spec) & spec != generalist_level

  sub_locs <- unique(loc_key[is_sub])
  if (length(sub_locs) == 0L) {
    return(data.frame(
      location          = character(0L),
      n_subspecialists  = integer(0L),
      n_generalists     = integer(0L),
      generalist_needed = logical(0L),
      stringsAsFactors  = FALSE
    ))
  }

  n_sub <- vapply(sub_locs, function(k) sum(loc_key[is_sub] == k), integer(1L))
  n_gen <- vapply(sub_locs, function(k) sum(loc_key[is_gen] == k), integer(1L))

  out <- data.frame(
    location          = gsub("\t", ", ", sub_locs),
    n_subspecialists  = n_sub,
    n_generalists     = n_gen,
    generalist_needed = n_gen == 0L,
    stringsAsFactors  = FALSE,
    row.names         = NULL
  )
  out[order(out$generalist_needed, decreasing = TRUE), ]
}
