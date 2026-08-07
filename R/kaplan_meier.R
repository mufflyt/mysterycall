#' Kaplan-Meier time-to-appointment analysis by insurance group
#'
#' @name mysterycall_kaplan_meier
NULL

#' Kaplan-Meier curve of days-to-appointment by insurance group
#'
#' Fits a Kaplan-Meier survival model to wait-time data from mystery-caller
#' studies. In this framing the "event" is receiving an appointment and
#' "time" is the wait in days. Callers who never receive an appointment are
#' right-censored at \code{max_days}. A log-rank test compares the groups.
#' The optional plot is built manually with \pkg{ggplot2} (step functions +
#' ribbon CI bands) — \pkg{survminer} is not required.
#'
#' @param data A \code{data.frame} containing the study data.
#' @param time_col Character. Name of the column containing days until
#'   appointment (numeric). Rows where an appointment was never offered
#'   should have \code{NA} or a value \code{>= max_days}.
#' @param event_col Character. Name of the binary event column: \code{1} =
#'   appointment offered/obtained, \code{0} = censored (no appointment).
#'   Logical columns are coerced to integer silently. Default \code{"offered"}.
#' @param group_col Character. Name of the grouping variable (e.g.,
#'   \code{"insurance"}). Must have at least two levels. Required.
#' @param max_days Numeric scalar. Maximum follow-up days for administrative
#'   censoring. When \code{event_col = 0} and \code{time_col = NA}, time is
#'   imputed as \code{max_days}. All times are clamped to
#'   \code{[0, max_days]}. Default \code{90}.
#' @param conf_level Numeric scalar in \code{(0, 1)}. Confidence level for
#'   survival confidence intervals. Default \code{0.95}.
#' @param plot Logical. If \code{TRUE} (default) and \pkg{ggplot2} is
#'   installed, produce a Kaplan-Meier plot.
#' @param plot_title Character. Title for the plot. Default
#'   \code{"Time to Appointment by Insurance Type"}.
#' @param ylab Character. Label for the y-axis, which shows the survival
#'   function \eqn{S(t)} -- the fraction of callers who have \emph{not yet}
#'   secured an appointment by day \eqn{t}. Default
#'   \code{"Callers still awaiting an appointment (\%)"}, a plain-language
#'   phrasing; pass any string to override.
#' @param legend_title Character scalar or \code{NULL}. Title shown above the
#'   colour/fill legend. Default \code{NULL} uses a prettified \code{group_col}
#'   (underscores to spaces, title case) rather than the raw variable name;
#'   pass an explicit string (e.g. \code{"Subspecialty"}) to override, or
#'   \code{""} to drop the legend title entirely.
#' @param palette Character vector of colors, one per group level. Default
#'   \code{NULL} uses \pkg{viridis} if installed, otherwise \pkg{ggplot2}
#'   defaults.
#' @param risk_table Logical. If \code{TRUE} (default) and \pkg{ggplot2} is
#'   available, attach a number-at-risk table below the KM plot using
#'   \pkg{patchwork} (if installed).
#'
#' @return A named list of class \code{mysterycall_kaplan_meier} containing:
#'   \describe{
#'     \item{\code{survfit}}{The \code{\link[survival]{survfit}} object.}
#'     \item{\code{logrank_p}}{Numeric. Log-rank chi-square p-value.}
#'     \item{\code{logrank_p_fmt}}{Character. Formatted p-value string,
#'       e.g. \code{"p = 0.003"} or \code{"p < 0.001"}.}
#'     \item{\code{median_by_group}}{A \code{data.frame} with columns
#'       \code{group}, \code{median_days}, \code{ci_lower_days},
#'       \code{ci_upper_days}. Medians are \code{NA} when the survival
#'       function never drops below 0.5 (median not reached).}
#'     \item{\code{plot}}{A \code{ggplot} object (or a \pkg{patchwork}
#'       composite when \code{risk_table = TRUE} and \pkg{patchwork} is
#'       installed), or \code{NULL} when \pkg{ggplot2} is unavailable or
#'       \code{plot = FALSE}.}
#'     \item{\code{sentence}}{A character string summarising the result,
#'       ready for insertion into a manuscript Results section.}
#'   }
#'
#' @details
#' \strong{Required package:} \pkg{survival} must be installed
#' (\code{install.packages("survival")}). It is listed in \code{Suggests}.
#'
#' \strong{Censoring imputation:} Rows where \code{event_col = 0} (or
#' \code{NA}) AND \code{time_col = NA} have their time set to
#' \code{max_days}. Rows with \code{event_col = 1} and missing time are
#' dropped with a warning.
#'
#' \strong{Plot:} The KM step functions are drawn with
#' \code{\link[ggplot2]{geom_step}} and shaded CI bands with
#' \code{\link[ggplot2]{geom_ribbon}}. The log-rank p-value is annotated in
#' the upper-right panel area. If \pkg{patchwork} is installed and
#' \code{risk_table = TRUE}, a number-at-risk table is appended below the
#' main panel.
#'
#' @family outcomes
#' @seealso \code{\link{mysterycall_lmm}},
#'   \code{\link{mysterycall_poisson_model}}
#' @export
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   days      = c(3, 7, 14, 21, 90, 5, 10, 30, 90, 90),
#'   offered   = c(1,  1,  1,  1,  0, 1,  1,  1,  0,  0),
#'   insurance = c(
#'     "Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
#'     "BCBS",     "BCBS",     "BCBS",     "BCBS",     "BCBS"
#'   )
#' )
#'
#' result <- mysterycall_kaplan_meier(
#'   data      = df,
#'   time_col  = "days",
#'   event_col = "offered",
#'   group_col = "insurance",
#'   max_days  = 90
#' )
#'
#' cat(result$sentence, "\n")
#' print(result$median_by_group)
#' if (!is.null(result$plot)) print(result$plot)
#' }
mysterycall_kaplan_meier <- function(
    data,
    time_col,
    event_col  = "offered",
    group_col,
    max_days     = 90,
    conf_level   = 0.95,
    plot         = TRUE,
    plot_title   = "Time to Appointment by Insurance Type",
    ylab         = "Callers still awaiting an appointment (%)",
    legend_title = NULL,
    palette      = NULL,
    risk_table   = TRUE
) {

  # ---- Guard: survival must be installed -------------------------------------
  if (!requireNamespace("survival", quietly = TRUE)) {
    stop(
      "Package 'survival' is required. Install it with: install.packages('survival')",
      call. = FALSE
    )
  }

  # ---- Input validation ------------------------------------------------------
  if (!is.data.frame(data)) {
    stop("'data' must be a data.frame.", call. = FALSE)
  }
  if (missing(time_col) || !is.character(time_col) || !nzchar(time_col)) {
    stop("'time_col' must be a non-empty character string.", call. = FALSE)
  }
  if (missing(group_col) || !is.character(group_col) || !nzchar(group_col)) {
    stop("'group_col' must be a non-empty character string.", call. = FALSE)
  }
  for (col in c(time_col, event_col, group_col)) {
    if (!col %in% names(data)) {
      stop(sprintf("Column '%s' not found in 'data'.", col), call. = FALSE)
    }
  }
  if (!is.numeric(data[[time_col]])) {
    stop(sprintf("Column '%s' must be numeric.", time_col), call. = FALSE)
  }
  ev_raw <- data[[event_col]]
  if (is.logical(ev_raw)) {
    ev_raw <- as.integer(ev_raw)
  }
  if (!is.numeric(ev_raw) && !is.integer(ev_raw)) {
    stop(
      sprintf("Column '%s' must be numeric or logical (0/1).", event_col),
      call. = FALSE
    )
  }
  valid_ev <- ev_raw[!is.na(ev_raw)]
  if (!all(valid_ev %in% c(0, 1))) {
    stop(
      sprintf("Column '%s' must contain only 0, 1, or NA.", event_col),
      call. = FALSE
    )
  }
  if (!is.numeric(max_days) || length(max_days) != 1L || is.na(max_days) ||
      max_days <= 0) {
    stop("'max_days' must be a single positive number.", call. = FALSE)
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1) {
    stop("'conf_level' must be a single number in (0, 1).", call. = FALSE)
  }

  # ---- Build analysis data frame ---------------------------------------------
  df <- data.frame(
    time  = as.numeric(data[[time_col]]),
    event = as.integer(ev_raw),
    # droplevels() removes empty factor levels: an unused level would make
    # nlevels() over-count relative to the strata survfit actually fits,
    # desyncing the curves/palette/risk-table (it surfaced as stray "-N"
    # suffixes on the risk-table row labels, or a hard row-count error).
    group = droplevels(as.factor(data[[group_col]])),
    stringsAsFactors = FALSE
  )

  # Legend title: default to a prettified group_col rather than the raw
  # variable name (e.g. "sub4" -> "Sub4"; "insurance_type" -> "Insurance Type").
  if (is.null(legend_title)) {
    legend_title <- tools::toTitleCase(gsub("[_.]+", " ", group_col))
  }
  if (!is.character(legend_title) || length(legend_title) != 1L) {
    stop("'legend_title' must be a single character string or NULL.",
         call. = FALSE)
  }

  # Impute censored rows that have NA time: set time = max_days
  censored_na_time <- is.na(df$time) & (is.na(df$event) | df$event == 0L)
  df$time[censored_na_time]   <- max_days
  df$event[is.na(df$event)]   <- 0L

  # Rows with event=1 but still missing time cannot be used
  bad_rows <- is.na(df$time)
  if (any(bad_rows)) {
    warning(
      sprintf(
        "%d row(s) with event = 1 and missing time were removed.",
        sum(bad_rows)
      ),
      call. = FALSE
    )
    df <- df[!bad_rows, ]
  }

  # Clamp times to [0, max_days]
  df$time <- pmax(0, pmin(df$time, max_days))

  n_groups <- nlevels(df$group)
  if (n_groups < 2L) {
    stop(
      sprintf(
        "'group_col' (\"%s\") must have at least 2 non-missing levels; found %d.",
        group_col, n_groups
      ),
      call. = FALSE
    )
  }
  if (nrow(df) < 2L) {
    stop("Fewer than 2 usable rows remain after cleaning.", call. = FALSE)
  }

  # ---- Survival fit ----------------------------------------------------------
  sf <- survival::survfit(
    survival::Surv(time, event) ~ group,
    data     = df,
    conf.int = conf_level
  )

  # ---- Log-rank test ---------------------------------------------------------
  sd_obj     <- survival::survdiff(survival::Surv(time, event) ~ group, data = df)
  logrank_p  <- 1 - stats::pchisq(sd_obj$chisq, df = length(sd_obj$n) - 1L)
  logrank_p_fmt <- .km_fmt_pvalue(logrank_p)

  # ---- Median by group -------------------------------------------------------
  sf_tbl  <- summary(sf)$table   # matrix: rows = strata, cols = stats
  med_col <- grep("^median$",  colnames(sf_tbl), ignore.case = TRUE)
  lcl_col <- grep("LCL",       colnames(sf_tbl), ignore.case = TRUE)
  ucl_col <- grep("UCL",       colnames(sf_tbl), ignore.case = TRUE)

  # Fallback column detection if names differ
  if (!length(med_col)) med_col <- which(colnames(sf_tbl) == "median")[1L]
  if (!length(lcl_col)) lcl_col <- grep("lower|0\\.", colnames(sf_tbl))[1L]
  if (!length(ucl_col)) ucl_col <- grep("upper|0\\.", colnames(sf_tbl))[2L]

  grp_labels <- gsub("^group=", "", rownames(sf_tbl))

  median_by_group <- data.frame(
    group         = grp_labels,
    median_days   = if (length(med_col)) sf_tbl[, med_col[1L]] else NA_real_,
    ci_lower_days = if (length(lcl_col)) sf_tbl[, lcl_col[1L]] else NA_real_,
    ci_upper_days = if (length(ucl_col)) sf_tbl[, ucl_col[1L]] else NA_real_,
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  # ---- Summary sentence ------------------------------------------------------
  sig_word <- if (!is.na(logrank_p) && logrank_p < 0.05) {
    "significantly"
  } else {
    "not significantly"
  }

  med_parts <- mapply(
    function(grp, med) {
      if (is.na(med)) {
        sprintf("%s: median not reached", grp)
      } else {
        sprintf("%s: %.0f days", grp, med)
      }
    },
    median_by_group$group,
    median_by_group$median_days,
    SIMPLIFY = TRUE,
    USE.NAMES = FALSE
  )

  sentence <- sprintf(
    "Median time to appointment differed %s by %s (%s; log-rank %s).",
    sig_word,
    group_col,
    paste(med_parts, collapse = " vs. "),
    logrank_p_fmt
  )

  # ---- Plot ------------------------------------------------------------------
  km_plot <- NULL

  if (isTRUE(plot) && requireNamespace("ggplot2", quietly = TRUE)) {
    km_plot <- .km_ggplot(
      sf          = sf,
      df          = df,
      n_groups    = n_groups,
      group_col   = group_col,
      legend_title = legend_title,
      grp_labels  = grp_labels,
      logrank_p_fmt = logrank_p_fmt,
      plot_title  = plot_title,
      ylab        = ylab,
      palette     = palette,
      risk_table  = risk_table,
      max_days    = max_days
    )
  }

  # ---- Return ----------------------------------------------------------------
  result <- list(
    survfit         = sf,
    logrank_p       = logrank_p,
    logrank_p_fmt   = logrank_p_fmt,
    median_by_group = median_by_group,
    plot            = km_plot,
    sentence        = sentence
  )
  class(result) <- c("mysterycall_kaplan_meier", "list")
  result
}


# ---- Internal helpers --------------------------------------------------------

#' Format a p-value as a character string
#' @noRd
.km_fmt_pvalue <- function(p) {
  if (is.na(p)) return("p = NA")
  if (p < 0.001) return("p < 0.001")
  paste0("p = ", formatC(p, digits = 3, format = "f"))
}

#' Build the KM ggplot (internal)
#'
#' Extracts strata data from a \code{survfit} object and assembles a step-
#' function KM curve with ribbon CI bands. Optionally appends a number-at-risk
#' table via \pkg{patchwork}.
#'
#' @noRd
.km_ggplot <- function(
    sf,
    df,
    n_groups,
    group_col,
    legend_title,
    grp_labels,
    logrank_p_fmt,
    plot_title,
    ylab,
    palette,
    risk_table,
    max_days
) {
  # Extract per-strata vectors from survfit
  strata_lengths <- as.integer(sf$strata)

  # Clean group labels: strip any "<variable>=" prefix from strata names
  # (generic, not just "group="), so display labels never carry raw internals.
  clean_labels <- sub("^[^=]*=", "", names(sf$strata))

  # Shared x-axis breaks so the risk-table columns line up under the curve
  # gridlines instead of on their own irregular ticks.
  x_breaks <- pretty(c(0, max_days))
  x_breaks <- x_breaks[x_breaks >= 0 & x_breaks <= max_days]

  plot_df <- data.frame(
    time   = sf$time,
    surv   = sf$surv,
    lower  = if (!is.null(sf$lower)) sf$lower else sf$surv,
    upper  = if (!is.null(sf$upper)) sf$upper else sf$surv,
    strata = factor(
      rep(clean_labels, strata_lengths),
      levels = clean_labels
    ),
    stringsAsFactors = FALSE
  )

  # Prepend (time=0, surv=1) origin for each group so steps begin at 100%
  origin_df <- data.frame(
    time   = rep(0, n_groups),
    surv   = rep(1, n_groups),
    lower  = rep(1, n_groups),
    upper  = rep(1, n_groups),
    strata = factor(clean_labels, levels = clean_labels),
    stringsAsFactors = FALSE
  )
  plot_df <- rbind(origin_df, plot_df)
  plot_df <- plot_df[order(as.integer(plot_df$strata), plot_df$time), ]

  # Color palette
  fill_colors <- NULL
  if (!is.null(palette)) {
    fill_colors <- palette
  } else if (requireNamespace("viridis", quietly = TRUE)) {
    fill_colors <- viridis::viridis(n_groups, end = 0.85)
  }

  # Annotation position: upper-right
  ann_x <- max_days * 0.60
  ann_y <- 0.92

  km <- ggplot2::ggplot(
    plot_df,
    ggplot2::aes(
      x      = time,
      y      = surv,
      colour = strata,
      fill   = strata
    )
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = lower, ymax = upper),
      alpha  = 0.15,
      colour = NA
    ) +
    ggplot2::geom_step(linewidth = 0.8) +
    ggplot2::annotate(
      "text",
      x        = ann_x,
      y        = ann_y,
      label    = paste("Log-rank", logrank_p_fmt),
      hjust    = 0,
      size     = 3.5,
      fontface = "italic"
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, 1),
      labels = scales::percent_format(accuracy = 1),
      name   = ylab,
      expand = ggplot2::expansion(mult = c(0, 0.04))
    ) +
    ggplot2::scale_x_continuous(
      name   = "Days",
      limits = c(0, max_days),
      breaks = x_breaks,
      expand = ggplot2::expansion(mult = c(0.02, 0.02))
    ) +
    ggplot2::labs(
      title  = plot_title,
      colour = legend_title,
      fill   = legend_title
    ) +
    ggplot2::guides(
      colour = ggplot2::guide_legend(
        nrow = 1, override.aes = list(linewidth = 1.4, alpha = 1)
      ),
      fill = "none"
    ) +
    ggplot2::theme_bw(base_size = 12) +
    ggplot2::theme(
      legend.position   = "bottom",
      legend.key        = ggplot2::element_blank(),
      legend.title      = if (nzchar(legend_title)) {
        ggplot2::element_text(face = "bold")
      } else {
        ggplot2::element_blank()
      },
      plot.title        = ggplot2::element_text(face = "bold", size = 13),
      plot.title.position = "plot",
      panel.grid.minor  = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = "grey92"),
      axis.title.y      = ggplot2::element_text(margin = ggplot2::margin(r = 6))
    )

  # Apply custom / viridis colors
  if (!is.null(fill_colors)) {
    km <- km +
      ggplot2::scale_colour_manual(values = fill_colors, name = legend_title) +
      ggplot2::scale_fill_manual(values = fill_colors, name = legend_title)
  }

  # ---- Risk table ------------------------------------------------------------
  if (isTRUE(risk_table)) {
    # Count at the SAME x-axis breaks as the curve so the columns line up.
    tick_times <- x_breaks

    risk_list <- lapply(clean_labels, function(grp) {
      grp_df <- df[df$group == grp, ]
      n_risk <- vapply(
        tick_times,
        function(t) sum(grp_df$time >= t, na.rm = TRUE),
        integer(1L)
      )
      data.frame(
        time   = tick_times,
        n_risk = n_risk,
        # rev() so the first group sits at the TOP of the table, matching the
        # reading order of the legend.
        strata = factor(grp, levels = rev(clean_labels)),
        stringsAsFactors = FALSE
      )
    })
    risk_df <- do.call(rbind, risk_list)

    # Colour the row labels to match the curves (top-to-bottom = rev of the
    # strata order used on the discrete y axis). Falls back to grey20 when no
    # palette is available. Numbers stay dark grey for guaranteed legibility.
    risk_label_cols <- if (!is.null(fill_colors)) {
      rev(fill_colors[seq_len(n_groups)])
    } else {
      "grey20"
    }

    risk_tbl_plot <- ggplot2::ggplot(
      risk_df,
      ggplot2::aes(x = time, y = strata, label = n_risk)
    ) +
      ggplot2::geom_text(size = 3, colour = "grey20") +
      ggplot2::scale_x_continuous(
        limits = c(0, max_days),
        breaks = x_breaks,
        expand = ggplot2::expansion(mult = c(0.02, 0.02)),
        name   = NULL
      ) +
      ggplot2::scale_y_discrete(name = NULL) +
      ggplot2::labs(title = "Number at risk") +
      ggplot2::theme_minimal(base_size = 10) +
      ggplot2::theme(
        panel.grid          = ggplot2::element_blank(),
        plot.title          = ggplot2::element_text(size = 10, face = "bold"),
        plot.title.position = "plot",
        axis.text.y         = ggplot2::element_text(size = 9, hjust = 0,
                                                    face = "bold",
                                                    colour = risk_label_cols),
        axis.title.x        = ggplot2::element_blank(),
        axis.text.x         = ggplot2::element_blank(),
        axis.ticks          = ggplot2::element_blank()
      )

    if (requireNamespace("patchwork", quietly = TRUE)) {
      km <- patchwork::wrap_plots(
        km,
        risk_tbl_plot,
        ncol    = 1,
        heights = c(3.4, 1)
      )
    }
  }

  km
}


# ---- S3 print method ---------------------------------------------------------

#' Print a mysterycall_kaplan_meier result
#'
#' @param x A \code{mysterycall_kaplan_meier} object.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.mysterycall_kaplan_meier <- function(x, ...) {
  cat("-- mysterycall_kaplan_meier --\n\n")
  cat(x$sentence, "\n\n")
  cat("Median days to appointment by group:\n")
  print(x$median_by_group, row.names = FALSE)
  cat("\nLog-rank test:", x$logrank_p_fmt, "\n")
  if (!is.null(x$plot)) {
    cat("Plot: available (call print(result$plot) to display)\n")
  }
  invisible(x)
}
