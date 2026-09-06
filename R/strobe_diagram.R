# strobe_diagram.R — draw a validated participant flow.
#
# Deliberately takes a mysterycall_flow_spec rather than loose counts, so the
# arithmetic is checked before anything is drawn. mysterycall_strobe_flow()
# accepts n_total/n_included/n_logistic directly and draws whatever it is
# handed; this path cannot.

#' Draw a validated STROBE participant-flow diagram
#'
#' Renders a [mysterycall_flow_spec()] as a STROBE/CONSORT participant-flow
#' diagram: a main column of steps, exclusion boxes teeing off to the right,
#' and any splits drawn beneath their parent.
#'
#' Uses ggplot2 only. There is no Graphviz or htmlwidget path, and so no
#' headless browser is needed to write a PNG -- the diagram renders in a plain
#' CI container, which is where a check of its numbers is worth having.
#'
#' @param spec A `mysterycall_flow_spec` from [mysterycall_flow_spec()].
#' @param title Character or `NULL`. Plot title.
#' @param output_path Character or `NULL`. Where to save. Extension picks the
#'   device (`.png`, `.pdf`, `.svg`, ...). `NULL` returns the plot undrawn.
#' @param width,height Numeric. Inches. Defaults 9 and 7.
#' @param dpi Integer. Raster resolution. Default 300.
#' @param base_size Numeric. Base text size in points. Default 10.
#' @param background Colour for the plot background. Default `"white"`.
#'   [ggplot2::theme_void()] leaves the background blank, which writes a
#'   TRANSPARENT PNG -- fine on a white web page, unpredictable once the figure
#'   is placed in a Word manuscript or on a coloured slide, where whatever is
#'   behind it shows through the boxes. Pass `NA` for a transparent background
#'   deliberately.
#'
#' @return Invisibly, the `ggplot` object.
#'
#' @examples
#' spec <- mysterycall_flow_spec(
#'   spine = c("Screened" = 100, "Enrolled" = 80),
#'   exclusions = list("Screened" = c("Ineligible" = 15, "Declined" = 5)),
#'   splits = list("Enrolled" = c("Completed" = 70, "Withdrew" = 10))
#' )
#' p <- mysterycall_strobe_diagram(spec, title = "Participant flow")
#'
#' @seealso [mysterycall_flow_spec()]
#' @export
mysterycall_strobe_diagram <- function(spec,
                                       title = NULL,
                                       output_path = NULL,
                                       width = 9,
                                       height = 7,
                                       dpi = 300,
                                       base_size = 10,
                                       background = "white") {

  if (!inherits(spec, "mysterycall_flow_spec"))
    stop("`spec` must come from mysterycall_flow_spec(), so the arithmetic is ",
         "checked before anything is drawn.", call. = FALSE)
  if (isFALSE(spec$closed))
    stop("`spec` is marked as not closing; refusing to draw it.", call. = FALSE)

  nm <- names(spec$spine)
  n_step <- length(nm)

  # One row per spine step, plus a row for each level of splits beneath.
  split_rows <- .split_levels(spec$splits, nm)
  n_row <- n_step + length(split_rows)
  ytop <- 1
  ygap <- 1 / n_row

  boxes <- data.frame(label = character(0), n = numeric(0), x = numeric(0),
                      y = numeric(0), kind = character(0),
                      stringsAsFactors = FALSE)
  segs <- data.frame(x = numeric(0), y = numeric(0), xend = numeric(0),
                     yend = numeric(0), stringsAsFactors = FALSE)

  cx <- 0.34   # spine column centre
  ex <- 0.80   # exclusion column centre

  ys <- ytop - (seq_len(n_step) - 0.5) * ygap
  for (i in seq_len(n_step)) {
    boxes <- rbind(boxes, data.frame(
      label = nm[i], n = unname(spec$spine[[i]]), x = cx, y = ys[i],
      kind = if (i == n_step) "terminal" else "spine", stringsAsFactors = FALSE))
    if (i < n_step) segs <- rbind(segs, data.frame(
      x = cx, y = ys[i] - ygap * 0.30, xend = cx, yend = ys[i + 1] + ygap * 0.30))
    if (nm[i] %in% names(spec$exclusions)) {
      e <- spec$exclusions[[nm[i]]]
      ymid <- (ys[i] + ys[i + 1]) / 2
      boxes <- rbind(boxes, data.frame(
        label = paste(sprintf("%s (n = %s)", names(e),
                              vapply(e, .fmt_count, character(1))),
                      collapse = "\n"),
        n = NA_real_, x = ex, y = ymid, kind = "excluded",
        stringsAsFactors = FALSE))
      segs <- rbind(segs, data.frame(x = cx, y = ymid, xend = ex - 0.15,
                                     yend = ymid))
    }
  }

  # Splits: each level sits on its own row, children spread across the width.
  parent_y <- stats::setNames(ys, nm)
  parent_x <- stats::setNames(rep(cx, n_step), nm)
  for (lvl in seq_along(split_rows)) {
    yrow <- ytop - (n_step + lvl - 0.5) * ygap
    kids_all <- split_rows[[lvl]]
    # Children hang under their OWN parent. Spreading a whole row edge to edge
    # puts a box under a parent it does not belong to and sends its arrow
    # across the diagram, which reads as a different flow than the one meant.
    by_parent <- split(kids_all, vapply(kids_all, function(z) z$parent, character(1)))
    for (pn in names(by_parent)) {
      kids <- by_parent[[pn]]
      px <- parent_x[[pn]]
      span <- min(0.30 * length(kids), 0.62)
      xs <- if (length(kids) == 1) px else
        seq(px - span / 2, px + span / 2, length.out = length(kids))
      xs <- pmin(pmax(xs, 0.13), 0.87)   # keep boxes on the canvas
      for (k in seq_along(kids)) {
        kid <- kids[[k]]
        boxes <- rbind(boxes, data.frame(
          label = kid$label, n = kid$n, x = xs[k], y = yrow, kind = "split",
          stringsAsFactors = FALSE))
        segs <- rbind(segs, data.frame(
          x = px, y = parent_y[[pn]] - ygap * 0.30,
          xend = xs[k], yend = yrow + ygap * 0.30))
        parent_y[[kid$label]] <- yrow
        parent_x[[kid$label]] <- xs[k]
      }
    }
  }

  boxes$text <- ifelse(is.na(boxes$n), boxes$label,
                       sprintf("%s\nn = %s", boxes$label,
                               vapply(boxes$n, .fmt_count, character(1))))

  fill <- c(spine = "#E8F0F4", terminal = "#C4DAE6", excluded = "#FFFFFF",
            split = "#F3F0EA")
  arr <- ggplot2::arrow(length = ggplot2::unit(0.16, "cm"), type = "closed")

  p <- ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = segs,
      ggplot2::aes(x = .data$x, y = .data$y, xend = .data$xend, yend = .data$yend),
      arrow = arr, linewidth = 0.35, colour = "#1B3A4B") +
    ggplot2::geom_label(
      data = boxes,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$text,
                   fill = .data$kind),
      colour = "#1B3A4B", size = base_size / 3.2, lineheight = 1.05,
      label.padding = ggplot2::unit(0.45, "lines"),
      label.r = ggplot2::unit(0.12, "lines"), linewidth = 0.3) +
    ggplot2::scale_fill_manual(values = fill, guide = "none") +
    ggplot2::scale_x_continuous(limits = c(0, 1), expand = ggplot2::expansion(0.02)) +
    ggplot2::scale_y_continuous(limits = c(0, 1.02), expand = ggplot2::expansion(0.02)) +
    ggplot2::labs(title = title) +
    ggplot2::theme_void(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        hjust = 0.5, face = "bold", margin = ggplot2::margin(b = 6)),
      plot.background  = if (is.na(background)) ggplot2::element_blank() else
        ggplot2::element_rect(fill = background, colour = NA),
      panel.background = if (is.na(background)) ggplot2::element_blank() else
        ggplot2::element_rect(fill = background, colour = NA))

  if (!is.null(output_path))
    ggplot2::ggsave(output_path, p, width = width, height = height, dpi = dpi,
                    bg = if (is.na(background)) "transparent" else background)

  invisible(p)
}

# Arrange splits into rows: children of spine steps first, then children of
# those children, so a "not published" arm can be broken down a level lower.
.split_levels <- function(splits, spine_names) {
  if (!length(splits)) return(list())
  levels <- list()
  resolved <- spine_names
  remaining <- splits
  while (length(remaining)) {
    ready <- names(remaining)[names(remaining) %in% resolved]
    if (!length(ready)) break
    row <- list()
    for (p in ready)
      for (k in names(remaining[[p]]))
        row[[length(row) + 1L]] <- list(parent = p, label = k,
                                        n = unname(remaining[[p]][[k]]))
    levels[[length(levels) + 1L]] <- row
    resolved <- c(resolved, vapply(row, function(z) z$label, character(1)))
    remaining <- remaining[!names(remaining) %in% ready]
  }
  levels
}
