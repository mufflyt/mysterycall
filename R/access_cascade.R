#' Define one stage of an access cascade
#'
#' Helper that builds a single stage specification for
#' [mysterycall_access_cascade()]. A stage is one row of the access cascade:
#' a labelled measure counted over a column, with a denominator that is either
#' the full analytic sample, the previous stage, another stage, or a fixed
#' number.
#'
#' @param label Human-readable measure name shown in the table and figure
#'   (e.g. `"Practice accepting new patients"`).
#' @param column Name of the column in `data` that carries this measure.
#' @param success The value(s) in `column` that count as a "hit". Matched with
#'   `%in%` (so `NA` never counts). Alternatively a predicate
#'   `function(x)` returning a logical vector the length of `x`.
#' @param denominator What the count is a percentage *of*. One of:
#'   `"total"` (the number of rows in `data`, i.e. the analytic sample; the
#'   default), `"previous"` (the hit count of the stage defined immediately
#'   before this one, giving a strict funnel), a single positive number, or a
#'   character string naming the `label` of an earlier stage (whose hit count
#'   becomes the denominator -- e.g. reporting "share of offers" against an
#'   earlier "offered" stage).
#' @param group Optional block label used to group related stages in the output
#'   table (e.g. `"Access cascade"`, `"Reasons not accepting"`). Defaults to
#'   `"Access cascade"`.
#'
#' @return A list with class `"mysterycall_cascade_stage"`.
#' @seealso [mysterycall_access_cascade()]
#' @examples
#' mysterycall_cascade_stage(
#'   "New-patient appointment offered", "appointment_offered", success = TRUE
#' )
#' @export
mysterycall_cascade_stage <- function(label, column, success,
                                      denominator = "total", group = NULL) {
  checkmate::assert_string(label)
  checkmate::assert_string(column)
  if (!is.function(success)) checkmate::assert_vector(success, min.len = 1L)
  if (is.null(group)) group <- "Access cascade"
  checkmate::assert_string(group)
  if (!is.function(success)) {
    # allow atomic denominator that is a name, number, or the two keywords
  }
  structure(
    list(label = label, column = column, success = success,
         denominator = denominator, group = group),
    class = "mysterycall_cascade_stage"
  )
}

#' Summarize an access cascade across the call pathway
#'
#' Mystery-caller and simulated-patient studies capture a sequence of
#' intermediate access constructs on the way to (or instead of) an appointment:
#' reaching a live office, whether the practice accepts new patients, whether it
#' treats the presented complaint, whether an appointment is offered, and with
#' whom. This function turns an ordered set of stage definitions into a tidy
#' count / denominator / percent table with Wilson confidence intervals, and an
#' optional funnel-style figure. Denominators may be the full analytic sample, a
#' strictly nested previous stage, another named stage, or a fixed number, so a
#' single call can mix a nested funnel with "share of offers" sub-breakdowns.
#'
#' @param data A data frame (one row per call / encounter). Filter it to your
#'   analytic sample *before* calling; `"total"` denominators use `nrow(data)`.
#' @param stages A list of stage specifications. Each element is either the
#'   output of [mysterycall_cascade_stage()] or a plain list with the same
#'   fields (`label`, `column`, `success`, and optionally `denominator`,
#'   `group`). Stages are evaluated in order, which is what makes `"previous"`
#'   and by-name denominators resolvable.
#' @param conf_level Confidence level for the Wilson interval on each
#'   proportion. Default `0.95`.
#' @param plot Logical; if `TRUE` (requires \pkg{ggplot2}) attach a horizontal
#'   funnel figure of every stage to the returned object as `$plot`.
#' @param title,subtitle Optional figure title / subtitle. When `plot = TRUE`
#'   and left `NULL`, sensible defaults describing the analytic sample are used.
#' @param output_dir,filename Optional. If both are non-`NA`, the table is
#'   written to `file.path(output_dir, filename)` as CSV.
#'
#' @return An object of class `"mysterycall_access_cascade"`: a list with
#'   `table` (a tibble of `group`, `measure`, `n`, `denominator`, `pct`,
#'   `ci_lower`, `ci_upper`), `n_total` (rows in `data`), and `plot` (a ggplot
#'   or `NULL`). [as.data.frame()] returns the table.
#'
#' @examples
#' d <- data.frame(
#'   office_answered      = c(TRUE, TRUE, TRUE, FALSE, TRUE),
#'   new_patient_status   = c("Accepting", "Accepting", "Not accepting", NA, "Accepting"),
#'   appointment_offered  = c(TRUE, FALSE, FALSE, FALSE, TRUE)
#' )
#' mysterycall_access_cascade(d, list(
#'   mysterycall_cascade_stage("Reached a live office", "office_answered", TRUE),
#'   mysterycall_cascade_stage("Accepting new patients", "new_patient_status", "Accepting"),
#'   mysterycall_cascade_stage("Appointment offered", "appointment_offered", TRUE)
#' ))
#' @export
mysterycall_access_cascade <- function(data, stages, conf_level = 0.95,
                                       plot = FALSE, title = NULL,
                                       subtitle = NULL,
                                       output_dir = NA, filename = NA) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_list(stages, min.len = 1L)
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)
  checkmate::assert_flag(plot)

  n_total <- nrow(data)
  stages <- lapply(stages, .mc_coerce_stage)

  labels <- vapply(stages, `[[`, character(1), "label")
  if (anyDuplicated(labels)) {
    stop("Every stage `label` must be unique; duplicated: ",
         paste(unique(labels[duplicated(labels)]), collapse = ", "),
         call. = FALSE)
  }

  n_hits <- integer(length(stages))
  rows <- vector("list", length(stages))
  for (i in seq_along(stages)) {
    st <- stages[[i]]
    if (!st$column %in% names(data)) {
      stop(sprintf("Stage '%s' references column '%s', which is not in `data`.",
                   st$label, st$column), call. = FALSE)
    }
    hits <- .mc_stage_hits(data[[st$column]], st$success)
    n_hits[i] <- sum(hits)

    denom <- .mc_resolve_denominator(st$denominator, i, n_hits, labels, n_total,
                                     st$label)
    ci <- .mc_wilson_ci(n_hits[i], denom, conf_level)
    rows[[i]] <- data.frame(
      group = st$group, measure = st$label,
      n = n_hits[i], denominator = denom,
      pct = if (denom > 0) 100 * n_hits[i] / denom else NA_real_,
      ci_lower = 100 * ci[1], ci_upper = 100 * ci[2],
      stringsAsFactors = FALSE
    )
  }
  tab <- tibble::as_tibble(do.call(rbind, rows))

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
      gg <- .mc_cascade_plot(tab, n_total, title, subtitle)
    }
  }

  structure(
    list(table = tab, n_total = n_total, plot = gg),
    class = "mysterycall_access_cascade"
  )
}

# ---- internals --------------------------------------------------------------

.mc_coerce_stage <- function(x) {
  if (inherits(x, "mysterycall_cascade_stage")) return(x)
  if (!is.list(x) || is.null(x$label) || is.null(x$column) ||
      is.null(x$success)) {
    stop("Each stage must be a mysterycall_cascade_stage() or a list with ",
         "`label`, `column`, and `success` fields.", call. = FALSE)
  }
  mysterycall_cascade_stage(
    label = x$label, column = x$column, success = x$success,
    denominator = if (is.null(x$denominator)) "total" else x$denominator,
    group = x$group
  )
}

.mc_stage_hits <- function(col, success) {
  if (is.function(success)) {
    ok <- success(col)
    if (!is.logical(ok) || length(ok) != length(col)) {
      stop("A `success` predicate must return a logical vector the length of ",
           "the column.", call. = FALSE)
    }
  } else {
    ok <- col %in% success
  }
  ok[is.na(ok)] <- FALSE
  ok
}

.mc_resolve_denominator <- function(denominator, i, n_hits, labels, n_total,
                                     label) {
  if (is.numeric(denominator)) {
    checkmate::assert_number(denominator, lower = 0)
    return(as.numeric(denominator))
  }
  checkmate::assert_string(denominator)
  if (identical(denominator, "total")) return(n_total)
  if (identical(denominator, "previous")) {
    if (i == 1L) {
      stop(sprintf(paste0("Stage '%s' uses denominator = 'previous' but is the ",
                          "first stage; use 'total' or a fixed number."), label),
           call. = FALSE)
    }
    return(n_hits[i - 1L])
  }
  # otherwise a by-name reference to an earlier stage
  ref <- match(denominator, labels[seq_len(i - 1L)])
  if (is.na(ref)) {
    stop(sprintf(paste0("Stage '%s' denominator '%s' does not name an earlier ",
                        "stage (and is not 'total', 'previous', or a number)."),
                 label, denominator), call. = FALSE)
  }
  n_hits[ref]
}

.mc_cascade_plot <- function(tab, n_total, title, subtitle) {
  measure <- factor(tab$measure, levels = rev(tab$measure))
  df <- data.frame(measure = measure, n = tab$n, p = tab$pct)
  if (is.null(title)) title <- "Access measures across the call pathway"
  if (is.null(subtitle)) {
    subtitle <- sprintf(
      "Share of measure-specific denominators (%d analytic calls)", n_total)
  }
  ggplot2::ggplot(df, ggplot2::aes(x = .data$p, y = .data$measure,
                                   fill = .data$p)) +
    ggplot2::geom_col(ggplot2::aes(x = 100), fill = "grey93", width = 0.66) +
    ggplot2::geom_col(width = 0.66) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%d  (%.0f%%)", .data$n, .data$p)),
      hjust = -0.12, size = 3.5, fontface = "bold", colour = "grey20") +
    ggplot2::scale_fill_gradient(low = "#9ecae1", high = "#08519c",
                                 guide = "none") +
    ggplot2::scale_x_continuous(
      limits = c(0, 100), breaks = seq(0, 100, 25),
      labels = function(x) paste0(x, "%"),
      expand = ggplot2::expansion(mult = c(0, 0.14))) +
    ggplot2::labs(x = NULL, y = NULL, title = title, subtitle = subtitle) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = "grey92"),
      plot.title    = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(colour = "grey40", size = 10))
}

#' Print a `mysterycall_access_cascade` object
#'
#' @param x A `mysterycall_access_cascade` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return `x`, invisibly.
#' @export
print.mysterycall_access_cascade <- function(x, ...) {
  cat(sprintf("<mysterycall access cascade: %d stages, %d analytic calls>\n",
              nrow(x$table), x$n_total))
  tab <- x$table
  tab$pct <- sprintf("%.1f%%", tab$pct)
  tab$ci <- sprintf("[%.1f, %.1f]", tab$ci_lower, tab$ci_upper)
  print(tab[, c("group", "measure", "n", "denominator", "pct", "ci")],
        row.names = FALSE)
  if (!is.null(x$plot)) cat("\n$plot: a ggplot funnel figure is attached.\n")
  invisible(x)
}

#' Coerce a `mysterycall_access_cascade` object to a data frame
#'
#' @param x A `mysterycall_access_cascade` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return A `data.frame` representation of `x`.
#' @export
as.data.frame.mysterycall_access_cascade <- function(x, ...) {
  as.data.frame(x$table, ...)
}
