#' Cumulative appointment-acquisition curve for single-contact designs
#'
#' Plots (and tabulates) the empirical cumulative proportion of *all* calls that
#' had secured an appointment by business-day `t`. This is deliberately **not** a
#' Kaplan-Meier / time-to-event analysis: a mystery-caller study is a single
#' simulated contact, not longitudinal follow-up, so there is no censoring and no
#' at-risk set. Calls that never received an offer are retained in the
#' denominator as never obtaining an appointment, which is why each curve
#' plateaus at its group's offer rate rather than approaching 1.
#'
#' Prefer this over [mysterycall_kaplan_meier()] when "wait" is the delay to a
#' one-shot offer: KM right-censors the non-offered calls at the horizon, which
#' implies continued follow-up the design does not have and inflates the implied
#' cumulative probability.
#'
#' @param data A data frame, one row per call.
#' @param time_col Name of the wait-time column (business days to the appointment
#'   among offered calls; ignored/`NA` for non-offered calls).
#' @param offered_col Name of the binary offered indicator. Values are coerced
#'   with [as.logical()] after mapping `1`/`0` and `"TRUE"`/`"FALSE"`; anything
#'   that is not truthy counts as not offered.
#' @param group_col Optional grouping column; one curve per group. If `NULL`, a
#'   single overall curve is produced.
#' @param horizon Maximum business day to evaluate (waits are capped here).
#'   Default `90`.
#' @param plot Logical; if `TRUE` (requires \pkg{ggplot2}) attach a step-curve
#'   figure to `$plot`.
#' @param output_dir,filename Optional. If both are non-`NA`, the tidy curve
#'   table is written to `file.path(output_dir, filename)` as CSV.
#'
#' @return An object of class `"mysterycall_cumulative_access_curve"`: a list
#'   with `table` (tidy `group`, `day`, `p`, `n`), `plateau` (each group's final
#'   cumulative proportion = its offer rate), `horizon`, and `plot`.
#'   [as.data.frame()] returns the tidy table.
#'
#' @examples
#' set.seed(1)
#' d <- data.frame(
#'   wait_days = c(5, 12, NA, 30, 8, NA, 45, 20),
#'   offered   = c(1, 1, 0, 1, 1, 0, 1, 1),
#'   group     = rep(c("A", "B"), each = 4)
#' )
#' res <- mysterycall_cumulative_access_curve(
#'   d, "wait_days", "offered", "group", horizon = 60
#' )
#' res$plateau
#' @export
mysterycall_cumulative_access_curve <- function(
    data, time_col, offered_col, group_col = NULL, horizon = 90,
    plot = FALSE, output_dir = NA, filename = NA) {

  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_choice(time_col, names(data))
  checkmate::assert_choice(offered_col, names(data))
  if (!is.null(group_col)) checkmate::assert_choice(group_col, names(data))
  checkmate::assert_number(horizon, lower = 1)
  checkmate::assert_flag(plot)

  offered <- .mc_as_offered(data[[offered_col]])
  wait <- suppressWarnings(as.numeric(data[[time_col]]))
  # effective time-to-appointment: the observed wait among offered calls, NA if
  # never offered. Waits beyond `horizon` are simply never <= t for t <= horizon,
  # so the curve does not count them within the window (rather than pretending
  # they all arrive exactly at the horizon). A curve therefore plateaus at the
  # share of calls that obtained an appointment *within* the horizon, which
  # equals the offer rate only when every wait falls inside it.
  wait_e <- ifelse(offered & !is.na(wait), wait, NA_real_)

  grp <- if (is.null(group_col)) rep("All", nrow(data)) else
    as.character(data[[group_col]])
  glev <- unique(grp)
  days <- 0:floor(horizon)

  rows <- lapply(glev, function(g) {
    idx <- grp == g
    we <- wait_e[idx]
    ng <- length(we)
    p <- vapply(days, function(t) sum(!is.na(we) & we <= t) / ng, numeric(1))
    data.frame(group = g, day = days, p = p, n = ng, stringsAsFactors = FALSE)
  })
  tab <- tibble::as_tibble(do.call(rbind, rows))

  plateau <- tibble::tibble(
    group = glev,
    offer_rate = unname(vapply(glev, function(g) {
      idx <- grp == g
      mean(offered[idx], na.rm = TRUE)
    }, numeric(1))),
    n = unname(vapply(glev, function(g) sum(grp == g), integer(1)))
  )

  if (!is.na(output_dir) && !is.na(filename)) {
    if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
    utils::write.csv(tab, file.path(output_dir, filename), row.names = FALSE)
  }

  gg <- NULL
  if (isTRUE(plot)) {
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
      warning("`plot = TRUE` needs the ggplot2 package; returning table only.",
              call. = FALSE)
    } else {
      gg <- .mc_cumulative_plot(tab, is.null(group_col))
    }
  }

  structure(
    list(table = tab, plateau = plateau, horizon = horizon, plot = gg),
    class = "mysterycall_cumulative_access_curve"
  )
}

# ---- internals --------------------------------------------------------------

.mc_as_offered <- function(x) {
  if (is.logical(x)) return(x & !is.na(x))
  if (is.numeric(x)) return(!is.na(x) & x != 0)
  xc <- trimws(tolower(as.character(x)))
  out <- xc %in% c("true", "1", "yes", "y", "offered")
  out
}

.mc_cumulative_plot <- function(tab, single) {
  p <- ggplot2::ggplot(
    tab, ggplot2::aes(x = .data$day, y = .data$p, colour = .data$group)) +
    ggplot2::geom_step(linewidth = 0.9) +
    ggplot2::scale_y_continuous(
      labels = function(v) paste0(round(100 * v), "%"),
      limits = c(0, NA),
      expand = ggplot2::expansion(mult = c(0, 0.04))) +
    ggplot2::labs(
      x = "Business days since call",
      y = "Cumulative proportion of calls with an appointment",
      colour = NULL,
      title = "Cumulative probability of securing an appointment",
      subtitle = paste("Empirical cumulative proportion of all calls;",
                       "no-offer calls never obtain one, so each curve",
                       "plateaus at its offer rate")) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(colour = "grey40", size = 9),
      panel.grid.minor = ggplot2::element_blank())
  if (single) p <- p + ggplot2::guides(colour = "none")
  p
}

#' @export
print.mysterycall_cumulative_access_curve <- function(x, ...) {
  cat(sprintf("<mysterycall cumulative access curve: %d group(s), horizon %g days>\n",
              nrow(x$plateau), x$horizon))
  pl <- x$plateau
  pl$offer_rate <- sprintf("%.1f%%", 100 * pl$offer_rate)
  print(pl, ...)
  if (!is.null(x$plot)) cat("\n$plot: a ggplot step curve is attached.\n")
  invisible(x)
}

#' @export
as.data.frame.mysterycall_cumulative_access_curve <- function(x, ...) {
  as.data.frame(x$table, ...)
}
