#' CONSORT-style inclusion/exclusion flowchart for mystery-caller studies
#'
#' @name mysterycall_plot_inclexcl
NULL

#' Generate a CONSORT-style inclusion/exclusion flowchart
#'
#' Builds a DiagrammeR DOT diagram tailored to mystery-caller study reporting.
#' Unlike the generic [mysterycall_flowchart()], this function understands the
#' standard mystery-caller study phases (identification, screening, enrollment,
#' analysis) and lays out exclusion boxes on the right side with dashed arrows.
#'
#' Optionally appends a subspecialty distribution table in the final node.
#'
#' @param counts Named integer vector. Names are phase labels shown in the main
#'   boxes; values are physician counts at each phase. At least 2 phases are
#'   required.
#' @param exclusions Named list mapping a phase label (must be in `counts`) to
#'   a character string describing the exclusion reason and count (e.g.
#'   `list(Screening = "142 excluded: no phone number")`. Each entry produces
#'   a dashed side box to the right of the named phase.
#' @param subspecialty_breakdown Optional named integer vector. When supplied,
#'   the bottom box gains an extra line listing subspecialty counts
#'   (e.g. `c("General" = 120, "Neurotology" = 58, "Pediatric" = 44)`).
#' @param title Optional character scalar shown above the diagram.
#' @param node_width Numeric. Width of the main boxes in inches. Default `3.5`.
#' @param font_size Integer. Font size in points. Default `10L`.
#'
#' @return A `DiagrammeR::grViz` object representing the CONSORT flow diagram.
#'   Renders automatically in the RStudio Viewer and RMarkdown HTML output.
#'   To export to SVG or PDF:
#'   ```r
#'   svg_text <- DiagrammeRsvg::export_svg(diagram)
#'   rsvg::rsvg_pdf(chartr("\n", "", svg_text), "consort.pdf")
#'   ```
#' @seealso [mysterycall_flowchart()] for a generic multi-step flowchart;
#'   [mysterycall_acceptance_rate()] to compute the counts that feed this diagram.
#' @family outcomes
#' @export
#'
#' @examplesIf interactive()
#' mysterycall_plot_inclexcl(
#'   counts = c(
#'     Identified = 612,
#'     Screened   = 470,
#'     Enrolled   = 301,
#'     Analyzed   = 301
#'   ),
#'   exclusions = list(
#'     Identified = "142 excluded:\n  No phone number (n=87)\n  Duplicate NPI (n=55)",
#'     Screened   = paste0("169 excluded:\n",
#'       "  Not accepting new patients (n=112)\n",
#'       "  No appointment offered (n=57)")
#'   ),
#'   subspecialty_breakdown = c(General = 120, Neurotology = 58,
#'                               Pediatric = 44, Other = 79),
#'   title = "Mystery Caller Study -- ENT"
#' )
mysterycall_plot_inclexcl <- function(counts,
                                       exclusions             = NULL,
                                       subspecialty_breakdown = NULL,
                                       title                  = NULL,
                                       node_width             = 3.5,
                                       font_size              = 10L) {
  if (!requireNamespace("DiagrammeR", quietly = TRUE)) {
    stop(
      "DiagrammeR is required",
      call. = FALSE
    )
  }
  if (!is.numeric(counts) || is.null(names(counts)) || length(counts) < 2L) {
    stop("`counts` must be a named numeric vector with at least 2 elements.", call. = FALSE)
  }
  if (!is.null(exclusions) && !is.list(exclusions)) {
    stop("`exclusions` must be a named list.", call. = FALSE)
  }
  bad_exc <- setdiff(names(exclusions), names(counts))
  if (length(bad_exc) > 0L) {
    stop("Exclusion names not found in `counts`: ", paste(bad_exc, collapse = ", "), call. = FALSE)
  }

  .esc <- function(s) gsub('"', '\\"', s, fixed = TRUE)
  w    <- node_width
  fs   <- as.integer(font_size)
  n    <- length(counts)

  # -- Main-box labels ----------------------------------------------------------
  labels <- mapply(function(nm, ct) {
    paste0(.esc(nm), "\\n(n = ", format(as.integer(ct), big.mark = ","), ")")
  }, names(counts), counts, USE.NAMES = FALSE)

  # Append subspecialty breakdown to final box
  if (!is.null(subspecialty_breakdown) && is.numeric(subspecialty_breakdown) &&
      length(subspecialty_breakdown) > 0L) {
    sub_lines <- paste(
      sprintf("  %s: n=%s", names(subspecialty_breakdown),
              format(as.integer(subspecialty_breakdown), big.mark = ",")),
      collapse = "\\n"
    )
    labels[[n]] <- paste0(labels[[n]], "\\n\\nSubspecialties:\\n", sub_lines)
  }

  # -- Node definitions ---------------------------------------------------------
  node_lines <- character(n)
  for (i in seq_len(n)) {
    node_lines[[i]] <- sprintf(
      'N%d [label="%s", shape=box, width=%.1f, fontsize=%d];',
      i, labels[[i]], w, fs
    )
  }

  # -- Main-flow edges ----------------------------------------------------------
  edge_lines <- character(n - 1L)
  for (i in seq_len(n - 1L)) {
    edge_lines[[i]] <- sprintf("N%d -> N%d;", i, i + 1L)
  }

  # -- Exclusion side-boxes -----------------------------------------------------
  exc_nodes <- character(0L)
  exc_edges <- character(0L)
  exc_idx   <- 0L
  for (nm in names(exclusions)) {
    phase_i  <- which(names(counts) == nm)[[1L]]
    exc_idx  <- exc_idx + 1L
    exc_id   <- sprintf("E%d", exc_idx)
    exc_lbl  <- .esc(as.character(exclusions[[nm]]))
    exc_nodes <- c(exc_nodes, sprintf(
      '%s [label="%s", shape=box, style=dashed, width=%.1f, fontsize=%d];',
      exc_id, exc_lbl, w, fs
    ))
    exc_edges <- c(exc_edges, sprintf(
      "N%d -> %s [style=dashed];", phase_i, exc_id
    ))
  }

  # -- Title --------------------------------------------------------------------
  title_line <- if (!is.null(title)) {
    sprintf('labelloc="t"; label="%s"; fontsize=%d;', .esc(title), fs + 2L)
  } else ""

  dot <- paste0(
    'digraph inclusion_exclusion {\n',
    '  rankdir=TB;\n',
    if (nzchar(title_line)) paste0("  ", title_line, "\n") else "",
    "  node [fontname=Helvetica];\n",
    paste0("  ", node_lines,  collapse = "\n"), "\n",
    if (length(exc_nodes) > 0L)
      paste0("  ", exc_nodes, collapse = "\n") else "",
    "\n",
    paste0("  ", edge_lines,  collapse = "\n"), "\n",
    if (length(exc_edges) > 0L)
      paste0("  ", exc_edges, collapse = "\n") else "",
    "\n}"
  )

  DiagrammeR::grViz(dot)
}
