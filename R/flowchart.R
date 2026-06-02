#' CONSORT-style inclusion/exclusion flowchart
#'
#' @name mysterycall_flowchart
NULL


#' Generate a CONSORT-style flow diagram for a mystery caller study
#'
#' Produces a top-to-bottom DiagrammeR DOT flow diagram showing the sequential
#' inclusion and exclusion of providers from the analysis. Each step is a
#' labelled box with a count; optional exclusion side-boxes branch off to the
#' right. Requires the `DiagrammeR` package (listed in Suggests).
#'
#' @param steps Named character vector (or named list coercible to character).
#'   Each name is a step label and each value is the formatted count to display.
#'   Steps are rendered top-to-bottom in the order supplied. Example:
#'   ```r
#'   c(
#'     "Physicians in AAOS Directory" = "671",
#'     "Functioning Phone Number"     = "501",
#'     "Successfully Called"          = "432"
#'   )
#'   ```
#' @param exclusions Optional named character vector. Names must match names in
#'   `steps` (the step *after* which the exclusion occurred); values are the
#'   exclusion description displayed in a side box. Example:
#'   ```r
#'   c("Functioning Phone Number" = "170 excluded: no functioning phone")
#'   ```
#' @param title Optional character scalar placed above the diagram. `NULL`
#'   (default) adds no title node.
#' @param node_width Numeric. Fixed width of each flow box in inches. Default `3.5`.
#' @param font_size Integer. Base font size for node labels. Default `10L`.
#'
#' @return A `DiagrammeR` / `htmlwidget` object. Print it to view in the
#'   RStudio Viewer or a browser; use `DiagrammeRsvg::export_svg()` +
#'   `rsvg::rsvg_pdf()` to save to PDF.
#'
#' @family visualization
#' @seealso [mysterycall_poisson_model()]
#' @export
#'
#' @examplesIf requireNamespace("DiagrammeR", quietly = TRUE)
#' mysterycall_flowchart(
#'   steps = c(
#'     "Physicians in Directory" = "671",
#'     "Functioning Phone"       = "501",
#'     "Both Insurance Types"    = "432",
#'     "Final Analysis"          = "389"
#'   ),
#'   exclusions = c(
#'     "Functioning Phone"    = "170 excluded: no functioning phone",
#'     "Both Insurance Types" = "69 excluded: Medicaid not accepted",
#'     "Final Analysis"       = "43 excluded: incomplete call data"
#'   )
#' )
mysterycall_flowchart <- function(steps,
                                   exclusions = NULL,
                                   title      = NULL,
                                   node_width = 3.5,
                                   font_size  = 10L) {

  if (!requireNamespace("DiagrammeR", quietly = TRUE)) {
    stop("Package 'DiagrammeR' is required",
         call. = FALSE)
  }

  # -- Validate ---------------------------------------------------------------
  if (!is.character(steps) || is.null(names(steps)) || length(steps) < 1L) {
    stop("`steps` must be a named character vector with at least one entry.", call. = FALSE)
  }
  if (!is.null(exclusions)) {
    if (!is.character(exclusions) || is.null(names(exclusions))) {
      stop("`exclusions` must be a named character vector.", call. = FALSE)
    }
    bad <- setdiff(names(exclusions), names(steps))
    if (length(bad)) {
      stop(sprintf(
        "These exclusion names do not match any step: %s",
        paste(bad, collapse = ", ")
      ), call. = FALSE)
    }
  }

  step_names <- names(steps)
  n_steps    <- length(steps)

  # -- Build safe DOT IDs (alphanumeric only) ---------------------------------
  make_id <- function(s, prefix = "N") {
    paste0(prefix, gsub("[^A-Za-z0-9]", "_", s))
  }

  node_ids  <- make_id(step_names)
  excl_ids  <- if (!is.null(exclusions)) make_id(names(exclusions), "E") else character(0L)

  # -- Node definitions --------------------------------------------------------
  node_lines <- character(0L)

  if (!is.null(title)) {
    node_lines <- c(node_lines, sprintf(
      '  Title [label="%s", shape=plaintext, fontsize=%d]',
      .fc_escape(title), font_size + 2L
    ))
  }

  for (i in seq_len(n_steps)) {
    lbl <- sprintf("%s\\nn = %s", step_names[[i]], steps[[i]])
    node_lines <- c(node_lines, sprintf(
      '  %s [label="%s", shape=box, width=%.1f, fontsize=%d]',
      node_ids[[i]], .fc_escape(lbl), node_width, font_size
    ))
  }

  for (i in seq_along(excl_ids)) {
    lbl <- exclusions[[i]]
    node_lines <- c(node_lines, sprintf(
      '  %s [label="%s", shape=box, style=dashed, width=%.1f, fontsize=%d]',
      excl_ids[[i]], .fc_escape(lbl), node_width - 0.5, font_size
    ))
  }

  # -- Edge definitions --------------------------------------------------------
  edge_lines <- character(0L)

  if (!is.null(title)) {
    edge_lines <- c(edge_lines, sprintf("  Title -> %s", node_ids[[1L]]))
  }

  for (i in seq_len(n_steps - 1L)) {
    edge_lines <- c(edge_lines, sprintf("  %s -> %s", node_ids[[i]], node_ids[[i + 1L]]))
    # Exclusion side box branches from the transition edge midpoint (from source node)
    step_nm <- step_names[[i + 1L]]
    if (!is.null(exclusions) && step_nm %in% names(exclusions)) {
      excl_id <- make_id(step_nm, "E")
      edge_lines <- c(edge_lines, sprintf(
        "  %s -> %s [style=dashed, constraint=false]",
        node_ids[[i]], excl_id
      ))
    }
  }

  # -- Assemble DOT ------------------------------------------------------------
  dot <- paste0(
    "digraph flowchart {\n",
    "  graph [layout=dot, rankdir=TB, overlap=false, fontsize=", font_size, "]\n",
    "  node [fixedsize=false]\n\n",
    paste(node_lines, collapse = "\n"), "\n\n",
    paste(edge_lines, collapse = "\n"), "\n",
    "}\n"
  )

  DiagrammeR::grViz(dot)
}


# Escape double quotes inside DOT string literals
.fc_escape <- function(s) gsub('"', '\\\\"', s)
