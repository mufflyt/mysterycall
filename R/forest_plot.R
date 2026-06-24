#' Publication-ready forest plot for mystery-caller model results
#'
#' @name forest_plot
NULL

#' Publication-ready forest plot of IRRs or odds ratios
#'
#' Produces a B&W forest plot styled for journal submission, following the
#' design used in Acosta & Mufflyt (2025-2026): alternating row shading,
#' right-side annotation text (`"1.28 (1.05-1.56); P = .014"`), AMA-style
#' p-values, and significance encoded via point shape and CI linetype rather
#' than colour. Accepts model objects, plain data frames, or named lists of
#' models.
#'
#' For a simpler quick-look plot see [mysterycall_irr_plot()].
#'
#' @param x A `mysterycall_poisson_model`, `mysterycall_nb_model`,
#'   `mysterycall_auto_model`, or `mysterycall_logistic_model` object; **or**
#'   a data frame with columns `term`, one of `irr`/`or`/`estimate`,
#'   `ci_lower`, `ci_upper`, and optionally `p_value`; **or** a named list of
#'   such model objects (rows from each model are stacked with a `model` label
#'   prepended to the term).
#' @param term_labels Named character vector. Maps internal term names to
#'   display labels, e.g.
#'   `c("insuranceMedicaid" = "Medicaid vs. BCBS [Referent: BCBS]")`.
#'   Unmatched terms are left unchanged.
#' @param include_intercept Logical. Include the `(Intercept)` row? Default
#'   `FALSE`.
#' @param reference_line Numeric. X position of the null-effect dashed
#'   vertical line. Default `1`.
#' @param x_limits Numeric vector of length 2. X-axis limits
#'   `c(lower, upper)`. Auto-computed from the data when `NULL` (default).
#' @param annotation_x Numeric. X position of the right-side annotation text.
#'   Defaults to just past the right x-limit.
#' @param x_label Character. X-axis label. Automatically set to
#'   `"Odds Ratio (95% CI)"` for logistic models; defaults to
#'   `"Incidence Rate Ratio (95% CI)"` otherwise.
#' @param title Character or `NULL`. Plot title.
#' @param subtitle Character or `NULL`. Plot subtitle.
#' @param sig_threshold Numeric. P-value threshold for significance. Default
#'   `0.05`.
#' @param output_path Character or `NULL`. When non-`NULL`, both a TIFF
#'   (`lzw` compression) and PNG are saved using the same file stem (extension
#'   is replaced). Requires `ggplot2`.
#' @param width Numeric. Plot width in inches for saved files. Default `13`.
#' @param height Numeric or `NULL`. Plot height in inches. Auto-scales with
#'   number of rows when `NULL` (default): `max(3, 1.2 + nrow * 0.65)`.
#' @param dpi Integer. Resolution for saved files. Default `300`.
#' @param ... Ignored.
#'
#' @return A `ggplot` object, returned invisibly. The plot is also printed to
#'   the active graphics device.
#'
#' @family outcomes
#' @seealso [mysterycall_irr_plot()] for a simpler quick-look version;
#'   [mysterycall_poisson_model()], [mysterycall_nb_model()],
#'   [mysterycall_logistic_model()]
#' @export
#'
#' @examplesIf requireNamespace("ggplot2", quietly = TRUE)
#' irr_df <- data.frame(
#'   term     = c("Medicaid vs. BCBS [Referent: BCBS]",
#'                "Incontinence vs. Prolapse",
#'                "Bladder Pain vs. Prolapse",
#'                "Female vs. Male Physician"),
#'   irr      = c(1.28, 1.05, 0.91, 1.12),
#'   ci_lower = c(1.05, 0.88, 0.74, 0.95),
#'   ci_upper = c(1.56, 1.25, 1.12, 1.32),
#'   p_value  = c(0.014, 0.580, 0.370, 0.180),
#'   stringsAsFactors = FALSE
#' )
#' mysterycall_forest_plot(
#'   irr_df,
#'   title = "Incidence Rate Ratios for Days to Appointment"
#' )
mysterycall_forest_plot <- function(x,
                                     term_labels       = NULL,
                                     include_intercept = FALSE,
                                     reference_line    = 1,
                                     x_limits          = NULL,
                                     annotation_x      = NULL,
                                     x_label           = "Incidence Rate Ratio (95% CI)",
                                     title             = NULL,
                                     subtitle          = NULL,
                                     sig_threshold     = 0.05,
                                     output_path       = NULL,
                                     width             = 13,
                                     height            = NULL,
                                     dpi               = 300,
                                     ...) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Install with: install.packages('ggplot2')",
         call. = FALSE)
  }

  # ---- Extract tbl from input type -------------------------------------------
  tbl <- .fp_extract(x, x_label)
  x_label <- attr(tbl, "x_label") %||% x_label

  # ---- Filter intercept -------------------------------------------------------
  if (!include_intercept && "term" %in% names(tbl)) {
    tbl <- tbl[tbl$term != "(Intercept)", , drop = FALSE]
  }
  if (!nrow(tbl)) stop("No rows remain after filtering.", call. = FALSE)

  # ---- Apply term labels ------------------------------------------------------
  if (!is.null(term_labels)) {
    m <- match(tbl$term, names(term_labels))
    tbl$term <- ifelse(!is.na(m), term_labels[m], tbl$term)
  }

  # ---- Significance & annotations --------------------------------------------
  if (!"p_value" %in% names(tbl)) tbl$p_value <- NA_real_
  tbl$sig       <- as.character(!is.na(tbl$p_value) & tbl$p_value < sig_threshold)
  tbl$irr_label <- sprintf("%.2f (%.2f-%.2f)", tbl$irr, tbl$ci_lower, tbl$ci_upper)
  tbl$p_str     <- .fmt_ama_pvalue(tbl$p_value)
  tbl$annotation <- ifelse(nzchar(tbl$p_str),
                            paste0(tbl$irr_label, "; ", tbl$p_str),
                            tbl$irr_label)

  # ---- Factor ordering (first row of tbl -> top of plot) ----------------------
  tbl$term <- factor(tbl$term, levels = rev(as.character(tbl$term)))

  # ---- Auto x-limits ---------------------------------------------------------
  if (is.null(x_limits)) {
    lo  <- min(tbl$ci_lower, na.rm = TRUE)
    hi  <- max(tbl$ci_upper, na.rm = TRUE)
    pad <- (hi - lo) * 0.05
    x_limits <- c(max(0.05, lo - pad), hi + pad)
  }
  if (is.null(annotation_x)) annotation_x <- x_limits[2] * 1.04

  # ---- Auto height -----------------------------------------------------------
  if (is.null(height)) height <- max(3, 1.2 + nrow(tbl) * 0.65)

  # ---- Alternating row shading -----------------------------------------------
  n_rows  <- nrow(tbl)
  shade_y <- seq(0.5, n_rows - 0.5, by = 2)

  # ---- Build plot ------------------------------------------------------------
  p <- ggplot2::ggplot(tbl, ggplot2::aes(x = .data$irr, y = .data$term))

  for (ylo in shade_y) {
    p <- p + ggplot2::annotate("rect",
      xmin = -Inf, xmax = Inf,
      ymin = ylo,  ymax = ylo + 1,
      fill = "grey96", alpha = 1
    )
  }

  # horizontal separators between rows (skip first and last)
  if (n_rows > 2) {
    sep_y <- seq(1.5, n_rows - 0.5, by = 1)
    for (sy in sep_y) {
      p <- p + ggplot2::geom_hline(yintercept = sy, color = "grey70", linewidth = 0.3)
    }
  }

  p <- p +
    ggplot2::geom_vline(xintercept = reference_line, linetype = "dashed",
                        color = "grey50", linewidth = 0.6) +
    ggplot2::geom_errorbarh(
      ggplot2::aes(xmin = .data$ci_lower, xmax = .data$ci_upper,
                   linetype = .data$sig),
      height = 0.25, linewidth = 0.8, color = "black"
    ) +
    ggplot2::geom_point(
      ggplot2::aes(shape = .data$sig),
      size = 3.5, color = "black", fill = "black"
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = annotation_x, label = .data$annotation,
                   fontface = ifelse(.data$sig == "TRUE", "bold", "plain")),
      hjust = 0, size = 3.1, color = "black"
    ) +
    ggplot2::scale_linetype_manual(
      values = c("TRUE" = "solid", "FALSE" = "dashed"), guide = "none"
    ) +
    ggplot2::scale_shape_manual(
      values = c("TRUE" = 18L, "FALSE" = 5L), guide = "none"
    ) +
    ggplot2::coord_cartesian(xlim = x_limits, clip = "off") +
    ggplot2::labs(x = x_label, y = NULL, title = title, subtitle = subtitle) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      plot.title         = ggplot2::element_text(face = "bold", size = 12, hjust = 0),
      plot.subtitle      = ggplot2::element_text(size = 9, color = "grey40", hjust = 0,
                                                 margin = ggplot2::margin(b = 8)),
      axis.text.y        = ggplot2::element_text(size = 10.5, hjust = 1),
      axis.text.x        = ggplot2::element_text(size = 9.5),
      axis.title.x       = ggplot2::element_text(size = 10,
                                                  margin = ggplot2::margin(t = 6)),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(color = "grey88", linewidth = 0.4),
      legend.position    = "none",
      plot.margin        = ggplot2::margin(t = 8, r = 160, b = 8, l = 10)
    )

  # ---- Save ------------------------------------------------------------------
  if (!is.null(output_path)) {
    stem <- tools::file_path_sans_ext(output_path)
    ggplot2::ggsave(paste0(stem, ".tiff"), p,
                    width = width, height = height, dpi = dpi,
                    device = "tiff", compression = "lzw", bg = "white")
    ggplot2::ggsave(paste0(stem, ".png"), p,
                    width = width, height = height, dpi = dpi, bg = "white")
    message("Saved: ", paste(paste0(stem, c(".tiff", ".png")), collapse = ", "))
  }

  print(p)
  invisible(p)
}


# ---- internal helpers --------------------------------------------------------

`%||%` <- function(a, b) if (!is.null(a)) a else b

.fmt_ama_pvalue <- function(p) {
  ifelse(is.na(p), "",
    ifelse(p < 0.001, "P < .001",
      ifelse(p < 0.10,
        paste0("P = ", sub("0\\.", ".", sprintf("%.3f", p))),
        paste0("P = ", sub("0\\.", ".", sprintf("%.2f", p)))
      )
    )
  )
}

.fp_extract <- function(x, x_label_default) {

  # Named list of models -> bind rows with a "model" prefix on term
  if (is.list(x) && !is.data.frame(x) &&
      !inherits(x, c("mysterycall_poisson_model", "mysterycall_nb_model",
                     "mysterycall_auto_model", "mysterycall_logistic_model"))) {
    nms <- names(x)
    if (is.null(nms)) nms <- paste0("Model", seq_along(x))
    parts <- lapply(seq_along(x), function(i) {
      sub <- .fp_extract(x[[i]], x_label_default)
      sub$term <- paste0("[", nms[i], "] ", sub$term)
      sub
    })
    out <- do.call(rbind, parts)
    attr(out, "x_label") <- x_label_default
    return(out)
  }

  # Logistic model -> use or_table, override label
  if (inherits(x, "mysterycall_logistic_model")) {
    tbl <- as.data.frame(x$or_table)
    names(tbl)[names(tbl) == "or"] <- "irr"
    attr(tbl, "x_label") <- "Odds Ratio (95% CI)"
    return(tbl)
  }

  # Poisson / NB / auto_model -> use irr_table
  if (inherits(x, c("mysterycall_poisson_model", "mysterycall_nb_model",
                     "mysterycall_auto_model"))) {
    tbl <- as.data.frame(x$irr_table)
    attr(tbl, "x_label") <- x_label_default
    return(tbl)
  }

  # Plain data frame
  if (is.data.frame(x)) {
    tbl <- x
    # Normalise estimate column to "irr"
    est_col <- intersect(c("irr", "or", "estimate"), names(tbl))[1]
    if (is.na(est_col)) {
      stop("Data frame must contain one of: 'irr', 'or', 'estimate'.", call. = FALSE)
    }
    if (est_col != "irr") names(tbl)[names(tbl) == est_col] <- "irr"
    required <- c("irr", "ci_lower", "ci_upper")
    missing_cols <- setdiff(required, names(tbl))
    if (length(missing_cols)) {
      stop("Data frame missing required columns: ",
           paste(missing_cols, collapse = ", "), ".", call. = FALSE)
    }
    if (!"term" %in% names(tbl)) tbl$term <- paste0("Term", seq_len(nrow(tbl)))
    lbl <- if ("or" %in% names(x)) "Odds Ratio (95% CI)" else x_label_default
    attr(tbl, "x_label") <- lbl
    return(tbl)
  }

  stop("`x` must be a model object, data frame, or named list of models.", call. = FALSE)
}
