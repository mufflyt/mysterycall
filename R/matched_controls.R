#' Build a propensity-score-matched control cohort
#'
#' Many mystery-caller audits are case-control by design: a treated group
#' (private-equity-owned practices, hospital-acquired practices, a specific
#' chain) is compared against otherwise-similar controls. To make the comparison
#' fair -- and to keep the call burden bounded -- you match each treated practice
#' to a nearby, comparable control. This builds that matched cohort: it fits a
#' propensity model on the treated units versus a candidate pool, then greedily
#' matches each treated unit 1:1 to its nearest control on the propensity score,
#' within an exact stratum (e.g. same state) and an optional geographic caliper,
#' without replacement.
#'
#' The greedy nearest-neighbour scheme is the one audit teams actually use when a
#' control must be *callable* (same state, a short drive away), which off-the-
#' shelf matchers do not express directly. For unconstrained statistical matching
#' consider the \pkg{MatchIt} package instead.
#'
#' @param treated Data frame of treated units (one row per unit, unless
#'   `cluster_col` is set).
#' @param candidates Data frame of candidate controls. Must contain the
#'   propensity covariates, `id_col`, any `exact` columns, and (if used) the
#'   `coords` columns.
#' @param ps_formula A two-sided formula `treatment ~ x1 + x2 + ...`. The
#'   left-hand side names the treatment indicator this function creates
#'   internally (1 for `treated`, 0 for `candidates`); the right-hand side are
#'   the matching covariates, which must exist in both frames.
#' @param id_col Name of the unique identifier column (present in both frames).
#' @param exact Optional character vector of columns that a control must match
#'   the treated unit on exactly (e.g. `"state"`). Default `NULL`.
#' @param coords Optional length-2 character vector naming latitude and longitude
#'   columns (in both frames), used for the distance caliper. `NULL` disables the
#'   caliper. See [mysterycall_geocode_city_state()] to populate them.
#' @param caliper_miles Maximum control distance in miles (haversine). Ignored
#'   when `coords` is `NULL`. Default `10`.
#' @param min_in_caliper Require at least this many candidates within the caliper
#'   before a treated unit is matched (guards against matching to an isolated
#'   control). Default `1`.
#' @param cluster_col Optional column identifying clusters (e.g. an office/site
#'   shared by several treated providers). When set, at most one treated unit per
#'   cluster is matched; units within a cluster are tried in random order until
#'   one matches.
#' @param seed Integer seed for the within-cluster shuffle (reproducibility).
#'   Default `42`.
#'
#' @return An object of class `"mysterycall_matched_controls"`: a list with
#'   `pairs` (a tibble: `pair_id`, `treated_id`, `control_id`, `ps_treated`,
#'   `ps_control`, `ps_diff`, `distance_miles`), `matched_treated`,
#'   `matched_controls` (the matched rows from each input), `ps_model` (the fitted
#'   `glm`), `balance` (standardized mean differences for numeric covariates,
#'   treated vs matched controls), and counts `n_treated`, `n_matched`,
#'   `n_unmatched`. [as.data.frame()] returns `pairs`.
#'
#' @examples
#' set.seed(1)
#' treated <- data.frame(
#'   npi = 1:20, state = sample(c("CO", "TX"), 20, TRUE),
#'   lat = runif(20, 39, 40), lon = runif(20, -105, -104),
#'   years = rpois(20, 12), female = rbinom(20, 1, 0.5))
#' candidates <- data.frame(
#'   npi = 101:400, state = sample(c("CO", "TX"), 300, TRUE),
#'   lat = runif(300, 39, 40), lon = runif(300, -105, -104),
#'   years = rpois(300, 10), female = rbinom(300, 1, 0.5))
#' m <- mysterycall_build_matched_controls(
#'   treated, candidates, treatment ~ years + female,
#'   id_col = "npi", exact = "state", coords = c("lat", "lon"),
#'   caliper_miles = 40)
#' m
#' @export
mysterycall_build_matched_controls <- function(
    treated, candidates, ps_formula, id_col,
    exact = NULL, coords = NULL, caliper_miles = 10, min_in_caliper = 1L,
    cluster_col = NULL, seed = 42) {

  checkmate::assert_data_frame(treated, min.rows = 1L)
  checkmate::assert_data_frame(candidates, min.rows = 1L)
  checkmate::assert_formula(ps_formula)
  checkmate::assert_choice(id_col, names(treated))
  checkmate::assert_choice(id_col, names(candidates))
  checkmate::assert_count(min_in_caliper, positive = TRUE)
  if (!is.null(exact)) {
    checkmate::assert_subset(exact, names(treated))
    checkmate::assert_subset(exact, names(candidates))
  }
  if (!is.null(coords)) {
    checkmate::assert_character(coords, len = 2L)
    checkmate::assert_subset(coords, names(treated))
    checkmate::assert_subset(coords, names(candidates))
    checkmate::assert_number(caliper_miles, lower = 0)
  }
  if (!is.null(cluster_col)) checkmate::assert_choice(cluster_col, names(treated))

  vars <- all.vars(ps_formula)
  lhs <- vars[1]
  rhs_vars <- all.vars(ps_formula[[3L]])
  checkmate::assert_subset(rhs_vars, names(treated))
  checkmate::assert_subset(rhs_vars, names(candidates))

  # ---- propensity model on treated vs. candidate pool -----------------------
  tr <- treated[, rhs_vars, drop = FALSE]; tr[[lhs]] <- 1L
  ca <- candidates[, rhs_vars, drop = FALSE]; ca[[lhs]] <- 0L
  combined <- rbind(tr, ca)
  ps_model <- stats::glm(ps_formula, family = stats::binomial(), data = combined)
  ps_all <- stats::predict(ps_model, type = "response")
  ps_tr <- ps_all[seq_len(nrow(treated))]
  ps_ca <- ps_all[nrow(treated) + seq_len(nrow(candidates))]

  cand_id <- as.character(candidates[[id_col]])

  # ---- iteration units (one treated per cluster, if requested) --------------
  if (!is.null(cluster_col)) {
    cl <- as.character(treated[[cluster_col]])
    units <- lapply(sort(unique(cl)), function(g) which(cl == g))
  } else {
    units <- as.list(seq_len(nrow(treated)))
  }

  if (!is.null(seed)) withr::local_seed(seed)
  used <- character(0)
  rows <- list()

  for (unit in units) {
    order_rows <- if (length(unit) == 1L) unit else sample(unit)
    for (ti in order_rows) {
      ok <- !(cand_id %in% used)
      for (e in exact) {
        ok <- ok & (as.character(candidates[[e]]) == as.character(treated[[e]][ti]))
      }
      pool <- which(ok)
      if (!length(pool)) next

      dist <- rep(NA_real_, length(pool))
      if (!is.null(coords)) {
        dist <- .mc_haversine_miles(
          treated[[coords[1]]][ti], treated[[coords[2]]][ti],
          candidates[[coords[1]]][pool], candidates[[coords[2]]][pool])
        in_cal <- which(dist < caliper_miles)
        if (length(in_cal) < min_in_caliper) next
        pool <- pool[in_cal]; dist <- dist[in_cal]
      }

      psdiff <- abs(ps_ca[pool] - ps_tr[ti])
      best <- which.min(psdiff)
      ci <- pool[best]
      rows[[length(rows) + 1L]] <- data.frame(
        pair_id = length(rows) + 1L,
        treated_row = ti, control_row = ci,
        treated_id = treated[[id_col]][ti],
        control_id = candidates[[id_col]][ci],
        ps_treated = ps_tr[ti], ps_control = ps_ca[ci],
        ps_diff = psdiff[best],
        distance_miles = if (!is.null(coords)) dist[best] else NA_real_,
        stringsAsFactors = FALSE)
      used <- c(used, cand_id[ci])
      break
    }
  }

  if (length(rows)) {
    pr <- do.call(rbind, rows)
    matched_treated <- treated[pr$treated_row, , drop = FALSE]
    matched_controls <- candidates[pr$control_row, , drop = FALSE]
    pairs <- tibble::as_tibble(pr[, setdiff(names(pr), c("treated_row", "control_row"))])
    balance <- .mc_match_balance(matched_treated, matched_controls, rhs_vars, combined)
  } else {
    matched_treated <- treated[0, , drop = FALSE]
    matched_controls <- candidates[0, , drop = FALSE]
    pairs <- tibble::tibble(pair_id = integer(0), treated_id = treated[[id_col]][0],
                            control_id = candidates[[id_col]][0],
                            ps_treated = numeric(0), ps_control = numeric(0),
                            ps_diff = numeric(0), distance_miles = numeric(0))
    balance <- tibble::tibble(covariate = character(0), mean_treated = numeric(0),
                              mean_control = numeric(0), smd = numeric(0))
  }

  n_treated <- if (!is.null(cluster_col)) length(unique(as.character(treated[[cluster_col]])))
               else nrow(treated)

  structure(
    list(pairs = pairs, matched_treated = matched_treated,
         matched_controls = matched_controls, ps_model = ps_model,
         balance = balance, n_treated = n_treated, n_matched = nrow(pairs),
         n_unmatched = n_treated - nrow(pairs)),
    class = "mysterycall_matched_controls"
  )
}

# standardized mean differences (treated vs matched controls) for numeric covars
.mc_match_balance <- function(mt, mc, rhs_vars, combined) {
  num <- rhs_vars[vapply(rhs_vars, function(v) is.numeric(combined[[v]]),
                         logical(1))]
  if (!length(num)) {
    return(tibble::tibble(covariate = character(0), mean_treated = numeric(0),
                          mean_control = numeric(0), smd = numeric(0)))
  }
  do.call(rbind, lapply(num, function(v) {
    a <- mt[[v]]; b <- mc[[v]]
    ma <- mean(a, na.rm = TRUE); mb <- mean(b, na.rm = TRUE)
    sp <- sqrt((stats::var(a, na.rm = TRUE) + stats::var(b, na.rm = TRUE)) / 2)
    tibble::tibble(covariate = v, mean_treated = ma, mean_control = mb,
                   smd = if (isTRUE(sp > 0)) (ma - mb) / sp else 0)
  }))
}

#' Print a `mysterycall_matched_controls` object
#'
#' @param x A `mysterycall_matched_controls` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return `x`, invisibly.
#' @export
print.mysterycall_matched_controls <- function(x, ...) {
  cat(sprintf("<mysterycall matched controls: %d of %d treated matched (%d unmatched)>\n",
              x$n_matched, x$n_treated, x$n_unmatched))
  if (nrow(x$pairs)) {
    if (any(!is.na(x$pairs$distance_miles))) {
      cat(sprintf("  median control distance: %.1f miles; max ps difference: %.3f\n",
                  stats::median(x$pairs$distance_miles, na.rm = TRUE),
                  max(x$pairs$ps_diff, na.rm = TRUE)))
    }
    cat("\nCovariate balance (standardized mean differences):\n")
    print(x$balance, ...)
  }
  invisible(x)
}

#' Coerce a `mysterycall_matched_controls` object to a data frame
#'
#' @param x A `mysterycall_matched_controls` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return A `data.frame` representation of `x`.
#' @export
as.data.frame.mysterycall_matched_controls <- function(x, ...) {
  as.data.frame(x$pairs, ...)
}
