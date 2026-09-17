#' Detect and visualise calendar and sequence drift in mystery-caller outcomes
#'
#' @name mysterycall_caller_drift
NULL

#' Detect calendar drift and learning/fatigue drift in acceptance rates
#'
#' Tests whether acceptance rates drifted over the study period (calendar
#' drift) or over a caller's sequential call number (learning or fatigue
#' drift). Both forms of drift threaten design validity; this function
#' provides the statistical evidence and ready-to-paste sentence needed for
#' the methods section.
#'
#' @param data A data frame.
#' @param outcome_col Character scalar. Binary 0/1 outcome column. Default
#'   \code{"offered"}.
#' @param date_col Character scalar or \code{NULL}. Date column used to
#'   detect calendar drift. Default \code{NULL}.
#' @param call_seq_col Character scalar or \code{NULL}. Integer column giving
#'   the sequential call number for each caller (1st call, 2nd call, etc.).
#'   Default \code{NULL}. When \code{NULL} and both \code{date_col} and
#'   \code{caller_col} are provided, the sequence is derived by ranking dates
#'   within each caller (ties broken by row order).
#' @param caller_col Character scalar or \code{NULL}. Grouping column for
#'   caller identity, used to derive \code{call_seq_col} when that argument
#'   is \code{NULL}. Default \code{NULL}.
#' @param week_or_day Character scalar. Aggregation unit for the calendar
#'   trend: \code{"week"} (default) or \code{"day"}.
#' @param plot Logical. When \code{TRUE} (default) and \pkg{ggplot2} is
#'   installed, \code{$plot} in the return value is a \code{ggplot} object;
#'   otherwise \code{$plot} is \code{NULL}.
#' @param test Character scalar. Trend-test method. Currently only
#'   \code{"lm"} (default) is supported.
#'
#' @details
#' \strong{Calendar drift.} \code{outcome_col} is aggregated by
#' \code{week_or_day} period. A linear model
#' \code{lm(rate \~ time_index)} is fitted, where \code{time_index} is the
#' chronological rank of each period (1, 2, 3, \ldots). The slope is the
#' estimated change in acceptance rate per week (or day). Week boundaries
#' follow \code{format(date, "\%Y-\%U")} (Sunday-start ISO-adjacent
#' convention).
#'
#' \strong{Sequence drift.} Calls are grouped into consecutive bins of five
#' by \code{call_seq_col} (or by the within-caller date rank when
#' \code{call_seq_col} is \code{NULL}). Within each bin the acceptance rate
#' and mean sequence number are computed. A linear model
#' \code{lm(rate \~ mean_seq)} is fitted; the slope is the estimated change
#' in acceptance rate per additional call.
#'
#' Significance is assessed at \eqn{\alpha = 0.05}.
#'
#' @return A named list of class \code{mysterycall_caller_drift}:
#' \describe{
#'   \item{\code{calendar}}{Named list or \code{NULL} (when \code{date_col}
#'     is \code{NULL}). Elements: \code{rate_by_period} (data frame with
#'     columns \code{period}, \code{time_index}, \code{rate}, \code{n}),
#'     \code{slope}, \code{slope_se}, \code{p_value}, \code{p_fmt},
#'     \code{sentence}.}
#'   \item{\code{sequence}}{Named list or \code{NULL} (when no sequence
#'     information is available). Elements: \code{rate_by_seq} (data frame
#'     with columns \code{seq_bin}, \code{mean_seq}, \code{rate}, \code{n}),
#'     \code{slope}, \code{slope_se}, \code{p_value}, \code{p_fmt},
#'     \code{sentence}.}
#'   \item{\code{plot}}{\code{ggplot} object or \code{NULL}.}
#'   \item{\code{sentence}}{Character scalar. Combined one-sentence summary
#'     ready to paste into the methods section, e.g. \emph{"Acceptance rates
#'     did not change significantly over the study period (slope=-0.002 per
#'     week, p=0.43) or over call sequence (slope=0.001 per call, p=0.81),
#'     supporting design validity."}}
#' }
#'
#' @examples
#' set.seed(42)
#' n <- 120L
#' df <- data.frame(
#'   call_date = seq(as.Date("2023-01-02"), by = "day", length.out = n),
#'   caller    = rep(c("Alice", "Bob", "Carol"), times = n / 3L),
#'   offered   = rbinom(n, 1L, 0.55)
#' )
#'
#' # Calendar + sequence drift (sequence derived from date within caller)
#' res <- mysterycall_caller_drift(
#'   df,
#'   outcome_col = "offered",
#'   date_col    = "call_date",
#'   caller_col  = "caller",
#'   week_or_day = "week",
#'   plot        = FALSE
#' )
#' cat(res$sentence, "\n")
#' res$calendar$p_value
#' head(res$calendar$rate_by_period)
#'
#' # Explicit call_seq_col, no plot
#' df$seq <- ave(seq_len(n), df$caller, FUN = seq_along)
#' res2 <- mysterycall_caller_drift(
#'   df,
#'   outcome_col  = "offered",
#'   call_seq_col = "seq",
#'   plot         = FALSE
#' )
#' res2$sequence$slope
#'
#' @seealso [mysterycall_flag_date_outliers()],
#'   [mysterycall_caller_reliability()]
#' @family outcomes
#' @export
mysterycall_caller_drift <- function(
    data,
    outcome_col  = "offered",
    date_col     = NULL,
    call_seq_col = NULL,
    caller_col   = NULL,
    week_or_day  = c("week", "day"),
    plot         = TRUE,
    test         = c("lm")
) {

  # ---- input validation -------------------------------------------------------
  stopifnot("`data` must be a data frame" = is.data.frame(data))
  stopifnot("`outcome_col` must be a single column name" = is.character(outcome_col) && length(outcome_col) == 1L)
  if (!outcome_col %in% names(data)) {
    stop(sprintf(
      "outcome_col '%s' not found in `data`.\nAvailable columns: %s",
      outcome_col, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  }

  y <- suppressWarnings(as.numeric(data[[outcome_col]]))
  if (!all(y[!is.na(y)] %in% c(0, 1))) {
    warning(
      "outcome_col '", outcome_col, "' contains values other than 0/1. ",
      "Treating as numeric; acceptance rate = mean(outcome).",
      call. = FALSE
    )
  }

  if (!is.null(date_col)) {
    stopifnot("`date_col` must be a single column name" = is.character(date_col) && length(date_col) == 1L)
    if (!date_col %in% names(data)) {
      stop(sprintf(
        "date_col '%s' not found in `data`.\nAvailable columns: %s",
        date_col, paste(names(data), collapse = ", ")
      ), call. = FALSE)
    }
  }

  if (!is.null(call_seq_col)) {
    stopifnot("`call_seq_col` must be a single column name" = is.character(call_seq_col) && length(call_seq_col) == 1L)
    if (!call_seq_col %in% names(data)) {
      stop(sprintf(
        "call_seq_col '%s' not found in `data`.\nAvailable columns: %s",
        call_seq_col, paste(names(data), collapse = ", ")
      ), call. = FALSE)
    }
  }

  if (!is.null(caller_col)) {
    stopifnot("`caller_col` must be a single column name" = is.character(caller_col) && length(caller_col) == 1L)
    if (!caller_col %in% names(data)) {
      stop(sprintf(
        "caller_col '%s' not found in `data`.\nAvailable columns: %s",
        caller_col, paste(names(data), collapse = ", ")
      ), call. = FALSE)
    }
  }

  week_or_day <- match.arg(week_or_day)
  test        <- match.arg(test)
  stopifnot("`plot` must be a single logical (TRUE/FALSE)" = is.logical(plot) && length(plot) == 1L)

  if (is.null(date_col) && is.null(call_seq_col)) {
    stop(
      "At least one of date_col or call_seq_col must be provided.",
      call. = FALSE
    )
  }

  # ---- helpers ----------------------------------------------------------------

  # Format p-value for prose: "p < 0.001" or "p = 0.043" (package convention,
  # matching results_paragraph()/write_results_paragraph()/kaplan_meier()).
  .fmt_p <- function(p) {
    if (is.na(p)) return("NA")
    mysterycall_format_p(p, name = "p")
  }

  # Fit lm(y ~ x) and return slope, SE, p-value as a list
  .fit_lm_trend <- function(x, y) {
    df2 <- data.frame(x = x, y = y)
    df2 <- df2[stats::complete.cases(df2), ]
    if (nrow(df2) < 3L) {
      warning(
        "Fewer than 3 complete observations for trend test; returning NA.",
        call. = FALSE
      )
      return(list(slope = NA_real_, slope_se = NA_real_, p_value = NA_real_))
    }
    fit      <- stats::lm(y ~ x, data = df2)
    coef_mat <- summary(fit)$coefficients
    if (!"x" %in% rownames(coef_mat)) {
      return(list(slope = NA_real_, slope_se = NA_real_, p_value = NA_real_))
    }
    list(
      slope    = unname(coef_mat["x", "Estimate"]),
      slope_se = unname(coef_mat["x", "Std. Error"]),
      p_value  = unname(coef_mat["x", "Pr(>|t|)"])
    )
  }

  # Build a trend partial-sentence ("did not change..." or "changed...") for
  # the caller-facing sentence.  `context` is "over the study period" or
  # "over call sequence".
  .trend_clause <- function(slope, p_value, p_fmt, unit, context) {
    sig <- !is.na(p_value) && p_value < 0.05
    if (sig) {
      direction <- if (!is.na(slope) && slope > 0) "increased" else "decreased"
      sprintf(
        "Acceptance rates %s significantly %s (slope=%+.3f per %s, %s)",
        direction, context, slope, unit, p_fmt
      )
    } else {
      sprintf(
        "Acceptance rates did not change significantly %s (slope=%+.3f per %s, %s)",
        context, slope, unit, p_fmt
      )
    }
  }

  # ============================================================
  # 1. CALENDAR DRIFT
  # ============================================================
  cal_result <- NULL

  if (!is.null(date_col)) {
    dates <- tryCatch(
      as.Date(data[[date_col]]),
      error = function(e) {
        stop(
          "Could not coerce date_col '", date_col, "' to Date: ",
          conditionMessage(e),
          call. = FALSE
        )
      }
    )

    keep_c <- !is.na(dates) & !is.na(y)
    if (!any(keep_c)) {
      warning("No complete cases for calendar drift analysis.", call. = FALSE)
    } else {
      d_cal <- data.frame(
        date    = dates[keep_c],
        outcome = y[keep_c],
        stringsAsFactors = FALSE
      )

      # Assign period label
      d_cal$period <- if (week_or_day == "week") {
        format(d_cal$date, "%Y-%U")    # year-week (Sunday start)
      } else {
        format(d_cal$date, "%Y-%m-%d")
      }

      # Map period labels to chronological integer index
      period_levels <- sort(unique(d_cal$period))
      d_cal$time_index <- match(d_cal$period, period_levels)

      # Aggregate: rate and n per period
      agg_rate <- tapply(d_cal$outcome, d_cal$time_index, mean,   na.rm = TRUE)
      agg_n    <- tapply(d_cal$outcome, d_cal$time_index, length)
      t_idx    <- as.integer(names(agg_rate))

      rate_by_period <- data.frame(
        period     = period_levels[t_idx],
        time_index = t_idx,
        rate       = as.numeric(agg_rate),
        n          = as.integer(agg_n),
        stringsAsFactors = FALSE
      )
      rate_by_period <- rate_by_period[order(rate_by_period$time_index), ]
      rownames(rate_by_period) <- NULL

      # Trend test
      trend_c  <- .fit_lm_trend(rate_by_period$time_index, rate_by_period$rate)
      p_fmt_c  <- .fmt_p(trend_c$p_value)
      unit_c   <- if (week_or_day == "week") "week" else "day"

      cal_sentence <- .trend_clause(
        trend_c$slope, trend_c$p_value, p_fmt_c,
        unit_c, "over the study period"
      )

      cal_result <- list(
        rate_by_period = rate_by_period,
        slope          = trend_c$slope,
        slope_se       = trend_c$slope_se,
        p_value        = trend_c$p_value,
        p_fmt          = p_fmt_c,
        unit           = unit_c,
        sentence       = cal_sentence
      )
    }
  }

  # ============================================================
  # 2. SEQUENCE DRIFT
  # ============================================================
  seq_result <- NULL

  # Resolve per-row call sequence number
  seq_vec <- NULL

  if (!is.null(call_seq_col)) {
    seq_vec <- suppressWarnings(as.numeric(data[[call_seq_col]]))
  } else if (!is.null(date_col) && !is.null(caller_col)) {
    # Derive within-caller date rank
    dates2   <- as.Date(data[[date_col]])
    caller2  <- data[[caller_col]]
    seq_vec  <- rep(NA_real_, nrow(data))
    for (cl in unique(caller2)) {
      idx <- which(caller2 == cl)
      seq_vec[idx] <- rank(dates2[idx], ties.method = "first", na.last = "keep")
    }
  }

  if (!is.null(seq_vec)) {
    keep_s <- !is.na(seq_vec) & !is.na(y)
    if (!any(keep_s)) {
      warning("No complete cases for sequence drift analysis.", call. = FALSE)
    } else {
      d_seq <- data.frame(
        seq_val = seq_vec[keep_s],
        outcome = y[keep_s],
        stringsAsFactors = FALSE
      )

      # Bin to groups of 5 calls: bin 1 = calls 1-5, bin 2 = 6-10, ...
      d_seq$seq_bin <- ceiling(d_seq$seq_val / 5)

      # Aggregate rate and mean sequence number per bin
      agg_rate_s <- tapply(d_seq$outcome, d_seq$seq_bin, mean,   na.rm = TRUE)
      agg_seq_s  <- tapply(d_seq$seq_val, d_seq$seq_bin, mean,   na.rm = TRUE)
      agg_n_s    <- tapply(d_seq$outcome, d_seq$seq_bin, length)
      bins        <- as.integer(names(agg_rate_s))

      rate_by_seq <- data.frame(
        seq_bin  = bins,
        mean_seq = as.numeric(agg_seq_s[as.character(bins)]),
        rate     = as.numeric(agg_rate_s),
        n        = as.integer(agg_n_s),
        stringsAsFactors = FALSE
      )
      rate_by_seq <- rate_by_seq[order(rate_by_seq$seq_bin), ]
      rownames(rate_by_seq) <- NULL

      # Trend test: x = mean_seq so slope is "per call"
      trend_s  <- .fit_lm_trend(rate_by_seq$mean_seq, rate_by_seq$rate)
      p_fmt_s  <- .fmt_p(trend_s$p_value)

      seq_sentence <- .trend_clause(
        trend_s$slope, trend_s$p_value, p_fmt_s,
        "call", "over call sequence"
      )

      seq_result <- list(
        rate_by_seq = rate_by_seq,
        slope       = trend_s$slope,
        slope_se    = trend_s$slope_se,
        p_value     = trend_s$p_value,
        p_fmt       = p_fmt_s,
        unit        = "call",
        sentence    = seq_sentence
      )
    }
  }

  # ============================================================
  # 3. COMBINED SENTENCE
  # ============================================================

  # Build a joined, methods-ready sentence from whichever components exist.
  combined_sentence <- .cd_combined_sentence(cal_result, seq_result)

  # ============================================================
  # 4. PLOT
  # ============================================================
  plt <- NULL

  if (isTRUE(plot)) {
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
      message(
        "Package 'ggplot2' is required for plotting. ",
        "Install with: install.packages(\"ggplot2\"). Returning $plot = NULL."
      )
    } else {
      plt <- .cd_build_plot(cal_result, seq_result, week_or_day)
    }
  }

  # ============================================================
  # 5. RETURN
  # ============================================================
  out <- list(
    calendar = cal_result,
    sequence = seq_result,
    plot     = plt,
    sentence = combined_sentence
  )
  class(out) <- "mysterycall_caller_drift"
  out
}


# ---- internal: combined methods sentence ------------------------------------

.cd_combined_sentence <- function(cal_result, seq_result) {
  has_cal <- !is.null(cal_result)
  has_seq <- !is.null(seq_result)

  cal_sig <- has_cal && !is.na(cal_result$p_value) && cal_result$p_value < 0.05
  seq_sig <- has_seq && !is.na(seq_result$p_value) && seq_result$p_value < 0.05

  if (!has_cal && !has_seq) {
    return("No drift analysis was performed (both date_col and call_seq_col are NULL).")
  }

  # If neither is significant the sentence reads cleanly in the negative.
  if (!cal_sig && !seq_sig) {
    if (has_cal && has_seq) {
      return(sprintf(
        "Acceptance rates did not change significantly over the study period (slope=%+.3f per %s, %s) or over call sequence (slope=%+.3f per %s, %s), supporting design validity.",
        cal_result$slope, cal_result$unit, cal_result$p_fmt,
        seq_result$slope, seq_result$unit, seq_result$p_fmt
      ))
    }
    if (has_cal) {
      return(sprintf(
        "Acceptance rates did not change significantly over the study period (slope=%+.3f per %s, %s), supporting design validity.",
        cal_result$slope, cal_result$unit, cal_result$p_fmt
      ))
    }
    # has_seq only
    return(sprintf(
      "Acceptance rates did not change significantly over call sequence (slope=%+.3f per %s, %s), supporting design validity.",
      seq_result$slope, seq_result$unit, seq_result$p_fmt
    ))
  }

  # At least one is significant -- use the individual sub-sentences.
  parts <- character(0L)
  if (has_cal) {
    parts <- c(parts, cal_result$sentence)
  }
  if (has_seq) {
    parts <- c(parts, seq_result$sentence)
  }
  paste0(paste(parts, collapse = "; "), ".")
}


# ---- internal: build ggplot2 drift plot -------------------------------------

.cd_build_plot <- function(cal_result, seq_result, week_or_day) {
  # Both panels share a common aesthetic spec; patchwork is used when available.
  gg <- ggplot2::ggplot   # alias for brevity

  make_panel <- function(df, x_col, y_col, xlab, title_str) {
    x_vals <- df[[x_col]]
    y_vals <- df[[y_col]]
    slope  <- unname(stats::coef(stats::lm(y_vals ~ x_vals))["x_vals"])
    # smooth line from lm
    x_rng  <- range(x_vals, na.rm = TRUE)
    fit_df <- data.frame(
      x = x_rng,
      y = stats::predict(
        stats::lm(y_vals ~ x_vals),
        newdata = data.frame(x_vals = x_rng)
      )
    )

    p <- gg(df, ggplot2::aes(x = .data[[x_col]], y = .data[[y_col]])) +
      ggplot2::geom_point(size = 2.5, colour = "steelblue4") +
      ggplot2::geom_line(
        data    = fit_df,
        mapping = ggplot2::aes(x = x, y = y),
        colour  = "firebrick3",
        linewidth = 0.8,
        linetype  = "dashed"
      ) +
      ggplot2::scale_y_continuous(
        labels = function(b) paste0(round(b * 100), "%"),
        limits = c(0, 1)
      ) +
      ggplot2::labs(
        title = title_str,
        x     = xlab,
        y     = "Acceptance rate"
      ) +
      ggplot2::theme_bw(base_size = 11) +
      ggplot2::theme(plot.title = ggplot2::element_text(size = 10, face = "bold"))
    p
  }

  panels <- list()

  if (!is.null(cal_result)) {
    x_label_cal <- if (week_or_day == "week") "Week index" else "Day index"
    panels[["calendar"]] <- make_panel(
      cal_result$rate_by_period,
      x_col      = "time_index",
      y_col      = "rate",
      xlab       = x_label_cal,
      title_str  = "Calendar drift"
    )
  }

  if (!is.null(seq_result)) {
    panels[["sequence"]] <- make_panel(
      seq_result$rate_by_seq,
      x_col      = "mean_seq",
      y_col      = "rate",
      xlab       = "Mean call sequence number",
      title_str  = "Sequence drift (learning / fatigue)"
    )
  }

  if (length(panels) == 0L) return(NULL)
  if (length(panels) == 1L) return(panels[[1L]])

  # Two panels: prefer patchwork, fall back to calendar panel only
  if (requireNamespace("patchwork", quietly = TRUE)) {
    patchwork::wrap_plots(panels, ncol = 2L)
  } else {
    message(
      "Install 'patchwork' to display both panels side-by-side. ",
      "Returning calendar panel only."
    )
    panels[["calendar"]]
  }
}


#' Print method for mysterycall_caller_drift objects
#'
#' @param x A \code{mysterycall_caller_drift} object.
#' @param ... Ignored.
#'
#' @return \code{invisible(x)}.
#'
#' @examples
#' \donttest{
#' set.seed(1)
#' df <- data.frame(
#'   call_date = seq(as.Date("2023-01-02"), by = "day", length.out = 60),
#'   offered   = rbinom(60, 1, 0.5)
#' )
#' res <- mysterycall_caller_drift(df, date_col = "call_date", plot = FALSE)
#' print(res)
#' }
#'
#' @method print mysterycall_caller_drift
#' @family outcomes
#' @export
print.mysterycall_caller_drift <- function(x, ...) {
  cat("-- mysterycall_caller_drift --\n")

  if (!is.null(x$calendar)) {
    cat(sprintf(
      "Calendar drift : slope = %+.4f, SE = %.4f, %s\n",
      x$calendar$slope,
      x$calendar$slope_se,
      x$calendar$p_fmt
    ))
    cat(sprintf(
      "  Periods analysed : %d\n",
      nrow(x$calendar$rate_by_period)
    ))
  } else {
    cat("Calendar drift : not analysed (date_col = NULL)\n")
  }

  if (!is.null(x$sequence)) {
    cat(sprintf(
      "Sequence drift : slope = %+.4f, SE = %.4f, %s\n",
      x$sequence$slope,
      x$sequence$slope_se,
      x$sequence$p_fmt
    ))
    cat(sprintf(
      "  Bins analysed    : %d\n",
      nrow(x$sequence$rate_by_seq)
    ))
  } else {
    cat("Sequence drift : not analysed (call_seq_col = NULL, or insufficient info)\n")
  }

  cat("\nSummary sentence:\n")
  cat(strwrap(x$sentence, width = 72L, exdent = 2L), sep = "\n")
  invisible(x)
}
