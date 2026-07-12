#' CONSORT/STROBE flow diagram for mystery-caller studies
#'
#' @name flow_diagram
NULL

#' Draw a participant flow diagram for a mystery-caller study
#'
#' Produces a CONSORT/STROBE-style flow diagram using ggplot2 (no DiagrammeR
#' dependency). Boxes show N at each stage; side branches display exclusion
#' counts and optional reasons. The returned ggplot2 object can be saved with
#' [ggplot2::ggsave()] or embedded in R Markdown / Quarto reports.
#'
#' @param n_identified Integer. Physicians in the initial sampling frame
#'   (e.g. from NPI lookup).
#' @param n_contacted Integer or `NULL`. Physicians where a mystery call was
#'   attempted. If `NULL`, this box is omitted from the diagram.
#' @param n_excluded_contact Integer or `NULL`. Physicians excluded before
#'   contact (e.g. retired, wrong specialty, disconnected number). Shown as
#'   a right-side branch below the "identified" box.
#' @param n_completed Integer or `NULL`. Physicians for whom the call was
#'   completed (reached a live person). If `NULL`, this box is omitted.
#' @param n_excluded_complete Integer or `NULL`. Physicians excluded after
#'   contact but before analysis (e.g. unable to reach after 3 attempts,
#'   office refused to respond).
#' @param n_analysed Integer. Physicians included in the final analysis.
#'   Must be > 0 and <= `n_identified`.
#' @param exclusion_reasons Named character vector. Names `"contact"` and/or
#'   `"complete"` map to reason strings appended below the exclusion count
#'   (e.g. `c(contact = "Retired or wrong specialty", complete = "No answer")`).
#' @param label_identified,label_contacted,label_completed,label_analysed
#'   Character. Box headers for the four stages (the count is appended
#'   automatically). Override to repurpose the diagram for a non-mystery-caller
#'   pipeline (e.g. `label_completed = "Target subspecialists"`). Defaults are
#'   the mystery-caller wording.
#' @param label_excluded Character. Header for the right-side exclusion boxes.
#'   Default `"Excluded"`.
#' @param title Character. Plot title. Default `"Study Flow Diagram"`.
#' @param output_path Character or `NULL`. File path to save the plot via
#'   [ggplot2::ggsave()]. Extension determines format (`.png`, `.pdf`, etc.).
#'   When `NULL` (default), no file is written.
#' @param width Numeric. Width in inches for `ggsave`. Default `8`.
#' @param height Numeric. Height in inches for `ggsave`. Default `6`.
#'
#' @return A ggplot2 object (invisibly). When `output_path` is not `NULL`,
#'   the file is saved and the path is messaged to the console.
#'
#' @family manuscript
#' @seealso [mysterycall_strobe_checklist()] which flags when a flow diagram
#'   is missing; [mysterycall_table1()] for the baseline characteristics table.
#' @export
#'
#' @examples
#' mysterycall_flow_diagram(
#'   n_identified        = 500,
#'   n_contacted         = 420,
#'   n_excluded_contact  = 80,
#'   n_completed         = 369,
#'   n_excluded_complete = 51,
#'   n_analysed          = 369,
#'   exclusion_reasons   = c(
#'     contact  = "Retired, wrong specialty, or disconnected",
#'     complete = "No answer after 3 attempts"
#'   )
#' )
mysterycall_flow_diagram <- function(n_identified,
                                      n_contacted         = NULL,
                                      n_excluded_contact  = NULL,
                                      n_completed         = NULL,
                                      n_excluded_complete = NULL,
                                      n_analysed,
                                      exclusion_reasons   = NULL,
                                      label_identified    = "Physicians identified",
                                      label_contacted     = "Physicians contacted",
                                      label_completed     = "Calls completed",
                                      label_analysed      = "Physicians analysed",
                                      label_excluded      = "Excluded",
                                      title               = "Study Flow Diagram",
                                      output_path         = NULL,
                                      width               = 8,
                                      height              = 6) {

  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Install with: install.packages('ggplot2')",
         call. = FALSE)

  if (!is.numeric(n_identified) || length(n_identified) != 1L || n_identified < 1)
    stop("`n_identified` must be a single positive integer.", call. = FALSE)
  if (!is.numeric(n_analysed)   || length(n_analysed)   != 1L || n_analysed < 1)
    stop("`n_analysed` must be a single positive integer.", call. = FALSE)
  if (n_analysed > n_identified)
    stop("`n_analysed` cannot exceed `n_identified`.", call. = FALSE)

  n_identified <- as.integer(n_identified)
  n_analysed   <- as.integer(n_analysed)
  if (!is.null(n_contacted))         n_contacted         <- as.integer(n_contacted)
  if (!is.null(n_excluded_contact))  n_excluded_contact  <- as.integer(n_excluded_contact)
  if (!is.null(n_completed))         n_completed         <- as.integer(n_completed)
  if (!is.null(n_excluded_complete)) n_excluded_complete <- as.integer(n_excluded_complete)

  reason_contact  <- exclusion_reasons[["contact"]]
  reason_complete <- exclusion_reasons[["complete"]]

  # Layout constants
  bw  <- 0.28   # box half-width (centred at x=0.5)
  bh  <- 0.07   # box half-height
  cx  <- 0.50   # main column x centre
  ex  <- 0.83   # exclusion box x centre
  arr <- ggplot2::arrow(length = ggplot2::unit(0.2, "cm"), type = "closed")

  # Determine y positions for active stages
  stages <- c("identified", "contacted", "completed", "analysed")
  active <- c(
    "identified" = TRUE,
    "contacted"  = !is.null(n_contacted),
    "completed"  = !is.null(n_completed),
    "analysed"   = TRUE
  )
  n_stages <- sum(active)
  ypos_all <- seq(0.92, 0.08, length.out = 4L)
  ypos <- ypos_all
  names(ypos) <- stages

  .box_label <- function(header, n, reason = NULL) {
    lbl <- sprintf("%s\nN = %s", header, format(n, big.mark = ","))
    if (!is.null(reason)) lbl <- paste0(lbl, "\n(", reason, ")")
    lbl
  }

  p <- ggplot2::ggplot() +
    ggplot2::xlim(0, 1) +
    ggplot2::ylim(0, 1) +
    ggplot2::labs(title = title) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, size = 13, face = "bold"),
      plot.margin = ggplot2::margin(10, 10, 10, 10)
    )

  .add_box <- function(p, y, label, x = cx) {
    p +
      ggplot2::annotate("rect",
                        xmin = x - bw, xmax = x + bw,
                        ymin = y - bh, ymax = y + bh,
                        fill = "white", colour = "black", linewidth = 0.5) +
      ggplot2::annotate("text",
                        x = x, y = y, label = label,
                        size = 3, hjust = 0.5, vjust = 0.5)
  }

  .add_arrow_down <- function(p, y_from, y_to, x = cx) {
    p + ggplot2::annotate("segment",
                           x    = x, xend = x,
                           y    = y_from - bh,
                           yend = y_to   + bh,
                           arrow = arr)
  }

  .add_exclusion <- function(p, y_branch, n_excl, reason) {
    if (is.null(n_excl)) return(p)
    lbl <- .box_label(label_excluded, n_excl, reason)
    p <- p +
      ggplot2::annotate("segment",
                         x = cx, xend = ex - bw,
                         y = y_branch, yend = y_branch) +
      ggplot2::annotate("rect",
                         xmin = ex - bw, xmax = ex + bw,
                         ymin = y_branch - bh, ymax = y_branch + bh,
                         fill = "white", colour = "black", linewidth = 0.5) +
      ggplot2::annotate("text",
                         x = ex, y = y_branch, label = lbl,
                         size = 2.6, hjust = 0.5, vjust = 0.5)
    p
  }

  # --- Box 1: identified -------------------------------------------------------
  p <- .add_box(p, ypos["identified"],
                .box_label(label_identified, n_identified))

  # exclusion after identification
  excl_y1 <- (ypos["identified"] + ypos["contacted"]) / 2
  if (!is.null(n_excluded_contact)) {
    p <- .add_arrow_down(p, ypos["identified"], excl_y1 + bh)
    p <- .add_exclusion(p, excl_y1, n_excluded_contact, reason_contact)
  }

  # --- Box 2: contacted --------------------------------------------------------
  if (!is.null(n_contacted)) {
    from_y <- if (!is.null(n_excluded_contact)) excl_y1 - bh else ypos["identified"]
    p <- .add_arrow_down(p, from_y, ypos["contacted"])
    p <- .add_box(p, ypos["contacted"],
                  .box_label(label_contacted, n_contacted))
  }

  # exclusion after contact / before complete
  excl_y2 <- (ypos["contacted"] + ypos["completed"]) / 2
  if (!is.null(n_excluded_complete) && !is.null(n_contacted)) {
    p <- .add_arrow_down(p, ypos["contacted"], excl_y2 + bh)
    p <- .add_exclusion(p, excl_y2, n_excluded_complete, reason_complete)
  }

  # --- Box 3: completed --------------------------------------------------------
  if (!is.null(n_completed)) {
    from_y2 <- if (!is.null(n_excluded_complete) && !is.null(n_contacted)) {
      excl_y2 - bh
    } else if (!is.null(n_contacted)) {
      ypos["contacted"]
    } else {
      ypos["identified"]
    }
    p <- .add_arrow_down(p, from_y2, ypos["completed"])
    p <- .add_box(p, ypos["completed"],
                  .box_label(label_completed, n_completed))
  }

  # --- Box 4: analysed ---------------------------------------------------------
  prev_y <- if (!is.null(n_completed)) {
    ypos["completed"]
  } else if (!is.null(n_contacted)) {
    if (!is.null(n_excluded_complete)) excl_y2 - bh else ypos["contacted"]
  } else if (!is.null(n_excluded_contact)) {
    excl_y1 - bh
  } else {
    ypos["identified"]
  }
  p <- .add_arrow_down(p, prev_y, ypos["analysed"])
  p <- .add_box(p, ypos["analysed"],
                .box_label(label_analysed, n_analysed))

  if (!is.null(output_path)) {
    ggplot2::ggsave(output_path, plot = p, width = width, height = height)
    message("Flow diagram saved to: ", output_path)
  }

  invisible(p)
}
