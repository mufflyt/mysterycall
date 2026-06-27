#' Literature comparison table for mystery-caller study Discussion sections
#'
#' @name mysterycall_literature_table
NULL


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

#' Determine disparity direction from OR and 95 % CI
#'
#' @param or      Numeric vector of odds ratios.
#' @param ci_low  Numeric vector of lower CI bounds.
#' @param ci_high Numeric vector of upper CI bounds.
#'
#' @return Character vector: "Disparity detected", "Favors equity", or "NS".
#' @keywords internal
.lit_direction <- function(or, ci_low, ci_high) {
  # CI does not include 1 -> statistically significant disparity
  sig   <- (ci_high < 1) | (ci_low > 1)
  # OR within [0.80, 1.25] is treated as "near 1" (no clinically important gap)
  near1 <- (or >= 0.80) & (or <= 1.25)

  direction <- character(length(or))
  direction[sig]            <- "Disparity detected"
  direction[!sig & near1]   <- "Favors equity"
  direction[!sig & !near1]  <- "NS"
  # Guard against NA inputs
  direction[is.na(or) | is.na(ci_low) | is.na(ci_high)] <- NA_character_
  direction
}

#' Validate the required columns of prior_studies
#'
#' @param df Data frame supplied by the caller.
#' @keywords internal
.lit_validate_prior <- function(df) {
  if (!is.data.frame(df)) {
    stop("`prior_studies` must be a data.frame.", call. = FALSE)
  }
  required <- c("author", "year", "specialty", "insurance_comparison",
                "or", "ci_lower", "ci_upper", "n")
  missing  <- setdiff(required, names(df))
  if (length(missing) > 0L) {
    stop(
      "The following required columns are absent from `prior_studies`: ",
      paste(missing, collapse = ", "), ".",
      call. = FALSE
    )
  }
  if (!is.character(df$author)) {
    stop("`prior_studies$author` must be character.", call. = FALSE)
  }
  if (!is.numeric(df$or) || !is.numeric(df$ci_lower) || !is.numeric(df$ci_upper)) {
    stop(
      "`prior_studies$or`, `$ci_lower`, and `$ci_upper` must all be numeric.",
      call. = FALSE
    )
  }
  if (any(!is.na(df$or) & df$or <= 0)) {
    stop("All non-NA values in `prior_studies$or` must be positive.", call. = FALSE)
  }
  invisible(NULL)
}


# ---------------------------------------------------------------------------
# Main function
# ---------------------------------------------------------------------------

#' Build a literature comparison table of prior mystery-caller study ORs
#'
#' Accepts a user-supplied data frame of published mystery-caller audit-study
#' odds ratios, optionally appends the current study's result, applies
#' consistent formatting, and returns a tidy comparison table ready for the
#' manuscript Discussion section.  An optional forest plot and a ready-to-paste
#' Discussion sentence are also produced.
#'
#' @param prior_studies A data frame of published odds-ratio estimates with the
#'   following **required** columns:
#'   \describe{
#'     \item{`author`}{Character. Citation label, e.g. `"Bisgaier & Rhodes 2011"`.}
#'     \item{`year`}{Integer. Publication year.}
#'     \item{`specialty`}{Character. Clinical specialty studied.}
#'     \item{`insurance_comparison`}{Character. Comparison label, e.g.
#'       `"Medicaid vs. Private"`.}
#'     \item{`or`}{Numeric. Odds ratio point estimate.}
#'     \item{`ci_lower`}{Numeric. Lower bound of the 95 % CI.}
#'     \item{`ci_upper`}{Numeric. Upper bound of the 95 % CI.}
#'     \item{`n`}{Integer. Total calls made in that study.}
#'   }
#'   Optional columns — included in the formatted table when present:
#'   `setting`, `outcome_label`, `notes`.
#' @param current_study A named list (or `NULL`).  When non-`NULL`, a row
#'   labelled `"[Current study]"` is appended **after** the prior studies but
#'   **before** sorting.  Required list elements mirror the required columns of
#'   `prior_studies`: `author`, `year`, `specialty`, `insurance_comparison`,
#'   `or`, `ci_lower`, `ci_upper`, `n`.  Optional elements: `setting`,
#'   `outcome_label`, `notes`.  The `author` element, if provided, is
#'   overwritten with `"[Current study]"`.
#' @param sort_by Character scalar controlling row order of the formatted table.
#'   One of `"year"` (default), `"or"`, `"author"`, or `"specialty"`.
#' @param digits Non-negative integer scalar.  Decimal places for OR and CI
#'   values.  Default `2L`.
#' @param highlight_current Logical.  When `TRUE` (default) and
#'   `current_study` is non-`NULL`, `"***"` is appended to the Author cell of
#'   the current-study row in the formatted output.
#' @param include_forest Logical.  Default `FALSE`.  When `TRUE` **and**
#'   \pkg{ggplot2} is installed, a simple forest plot is built and returned as
#'   `$forest_plot`.  When \pkg{ggplot2} is absent and `include_forest = TRUE`,
#'   a warning is issued and `$forest_plot` remains `NULL`.
#'
#' @return A list of class `mysterycall_literature_table` containing:
#' \describe{
#'   \item{`table`}{Data frame formatted for printing or export with columns
#'     `Author`, `Year`, `Specialty`, `Comparison`, `N`, `"OR (95% CI)"`, and
#'     `Direction`.  Optional columns `Setting`, `Outcome`, `Notes` are included
#'     when the corresponding source columns are present.  The `Direction`
#'     column takes one of three values: `"Disparity detected"` (95 % CI
#'     excludes 1), `"Favors equity"` (CI includes 1 and OR is within
#'     \[0.80, 1.25\]), or `"NS"` (CI includes 1 but OR is outside that range).}
#'   \item{`forest_plot`}{A \pkg{ggplot2} object, or `NULL` when
#'     `include_forest = FALSE` or \pkg{ggplot2} is unavailable.}
#'   \item{`n_studies`}{Integer.  Number of studies in the comparison table
#'     (including the current study, if supplied).}
#'   \item{`or_range`}{Character.  Human-readable OR range, e.g. `"0.31-0.87"`.}
#'   \item{`sentence`}{Character.  Ready-to-paste Discussion sentence
#'     summarising the literature context, e.g.
#'     `"Across 12 published mystery-caller studies, ORs for Medicaid vs.
#'     private insurance ranged from 0.31 to 0.87, consistent with our finding
#'     of OR = 0.62."`.  When `current_study` is `NULL` the phrase
#'     `"consistent with our finding of OR = X.XX"` is omitted.}
#' }
#'
#' @section Direction labels:
#' The `Direction` column is derived purely from the 95 % CI provided in
#' `prior_studies` (and `current_study`).  Studies with a CI that **excludes**
#' 1 are labelled `"Disparity detected"`.  Among studies whose CI includes 1,
#' those with an OR in \[0.80, 1.25\] are labelled `"Favors equity"`;
#' the remainder are labelled `"NS"` (not significant but OR suggests a
#' meaningful gap).
#'
#' @family manuscript
#' @seealso [mysterycall_results_paragraph()], [mysterycall_forest_plot()]
#' @export
#'
#' @examples
#' prior <- data.frame(
#'   author               = c("Bisgaier & Rhodes 2011",
#'                             "Lowe et al. 2012",
#'                             "Kugelmass 2016",
#'                             "Saloner et al. 2015"),
#'   year                 = c(2011L, 2012L, 2016L, 2015L),
#'   specialty            = c("Pediatrics", "Orthopedics",
#'                             "Psychiatry", "Primary Care"),
#'   insurance_comparison = rep("Medicaid vs. Private", 4L),
#'   or                   = c(0.38, 0.61, 0.45, 0.87),
#'   ci_lower             = c(0.22, 0.44, 0.31, 0.72),
#'   ci_upper             = c(0.65, 0.85, 0.66, 1.05),
#'   n                    = c(1612L, 800L, 360L, 1560L),
#'   stringsAsFactors     = FALSE
#' )
#'
#' current <- list(
#'   author               = "Acosta & Mufflyt",
#'   year                 = 2025L,
#'   specialty            = "Urogynecology",
#'   insurance_comparison = "Medicaid vs. Private",
#'   or                   = 0.62,
#'   ci_lower             = 0.41,
#'   ci_upper             = 0.94,
#'   n                    = 480L
#' )
#'
#' result <- mysterycall_literature_table(
#'   prior_studies   = prior,
#'   current_study   = current,
#'   sort_by         = "year",
#'   digits          = 2L,
#'   include_forest  = FALSE
#' )
#'
#' print(result)
#' result$sentence
mysterycall_literature_table <- function(prior_studies,
                                         current_study      = NULL,
                                         sort_by            = c("year", "or", "author", "specialty"),
                                         digits             = 2L,
                                         highlight_current  = TRUE,
                                         include_forest     = FALSE) {

  # ---------------------------------------------------------------------------
  # 1. Input validation
  # ---------------------------------------------------------------------------
  .lit_validate_prior(prior_studies)

  sort_by <- match.arg(sort_by)

  if (!is.numeric(digits) || length(digits) != 1L || digits < 0L) {
    stop("`digits` must be a non-negative integer scalar.", call. = FALSE)
  }
  digits <- as.integer(digits)

  if (!is.logical(highlight_current) || length(highlight_current) != 1L) {
    stop("`highlight_current` must be a single logical value.", call. = FALSE)
  }
  if (!is.logical(include_forest) || length(include_forest) != 1L) {
    stop("`include_forest` must be a single logical value.", call. = FALSE)
  }

  # ---------------------------------------------------------------------------
  # 2. Optional columns to carry through
  # ---------------------------------------------------------------------------
  optional_cols <- c("setting", "outcome_label", "notes")
  present_opt   <- intersect(optional_cols, names(prior_studies))

  # ---------------------------------------------------------------------------
  # 3. Append current_study row
  # ---------------------------------------------------------------------------
  is_current_row <- rep(FALSE, nrow(prior_studies))

  if (!is.null(current_study)) {
    if (!is.list(current_study)) {
      stop("`current_study` must be a named list or NULL.", call. = FALSE)
    }
    cs_required <- c("year", "specialty", "insurance_comparison",
                     "or", "ci_lower", "ci_upper", "n")
    cs_missing  <- setdiff(cs_required, names(current_study))
    if (length(cs_missing) > 0L) {
      stop(
        "The following elements are missing from `current_study`: ",
        paste(cs_missing, collapse = ", "), ".",
        call. = FALSE
      )
    }
    if (!is.numeric(current_study$or)      ||
        !is.numeric(current_study$ci_lower) ||
        !is.numeric(current_study$ci_upper)) {
      stop(
        "`current_study$or`, `$ci_lower`, and `$ci_upper` must be numeric.",
        call. = FALSE
      )
    }
    if (!is.na(current_study$or) && current_study$or <= 0) {
      stop("`current_study$or` must be a positive number.", call. = FALSE)
    }

    # Build the new row -------------------------------------------------------
    cs_row <- data.frame(
      author               = "[Current study]",
      year                 = as.integer(current_study$year),
      specialty            = as.character(current_study$specialty),
      insurance_comparison = as.character(current_study$insurance_comparison),
      or                   = as.numeric(current_study$or),
      ci_lower             = as.numeric(current_study$ci_lower),
      ci_upper             = as.numeric(current_study$ci_upper),
      n                    = as.integer(current_study$n),
      stringsAsFactors     = FALSE
    )

    # Carry optional columns from current_study if present --------------------
    for (oc in present_opt) {
      cs_row[[oc]] <- if (!is.null(current_study[[oc]])) {
        as.character(current_study[[oc]])
      } else {
        NA_character_
      }
    }
    # Any optional col in prior_studies but not supplied in current_study
    for (oc in setdiff(present_opt, names(current_study))) {
      cs_row[[oc]] <- NA_character_
    }

    # Ensure prior_studies also has the optional cols -------------------------
    for (oc in present_opt) {
      if (!oc %in% names(prior_studies)) {
        prior_studies[[oc]] <- NA_character_
      }
    }

    combined       <- rbind(prior_studies[, c("author", "year", "specialty",
                                               "insurance_comparison", "or",
                                               "ci_lower", "ci_upper", "n",
                                               present_opt),
                                          drop = FALSE],
                            cs_row[,     c("author", "year", "specialty",
                                           "insurance_comparison", "or",
                                           "ci_lower", "ci_upper", "n",
                                           present_opt),
                                   drop = FALSE])
    is_current_row <- c(rep(FALSE, nrow(prior_studies)), TRUE)

  } else {
    combined       <- prior_studies[, c("author", "year", "specialty",
                                        "insurance_comparison", "or",
                                        "ci_lower", "ci_upper", "n",
                                        present_opt),
                                    drop = FALSE]
  }

  # ---------------------------------------------------------------------------
  # 4. Sort
  # ---------------------------------------------------------------------------
  sort_col <- switch(sort_by,
    year      = "year",
    or        = "or",
    author    = "author",
    specialty = "specialty"
  )
  ord        <- order(combined[[sort_col]], na.last = TRUE)
  combined   <- combined[ord, , drop = FALSE]
  is_current_row <- is_current_row[ord]
  rownames(combined) <- NULL

  # ---------------------------------------------------------------------------
  # 5. Compute Direction column
  # ---------------------------------------------------------------------------
  direction <- .lit_direction(combined$or, combined$ci_lower, combined$ci_upper)

  # ---------------------------------------------------------------------------
  # 6. Format OR (95 % CI) column
  # ---------------------------------------------------------------------------
  fmt <- function(v) formatC(round(v, digits), format = "f", digits = digits)

  or_ci_col <- sprintf("%s (%s-%s)",
                       fmt(combined$or),
                       fmt(combined$ci_lower),
                       fmt(combined$ci_upper))

  # ---------------------------------------------------------------------------
  # 7. Build the formatted display table
  # ---------------------------------------------------------------------------
  author_display <- combined$author
  if (highlight_current && !is.null(current_study)) {
    author_display[is_current_row] <- paste0(
      author_display[is_current_row], "***"
    )
  }

  out_tbl <- data.frame(
    Author      = author_display,
    Year        = combined$year,
    Specialty   = combined$specialty,
    Comparison  = combined$insurance_comparison,
    N           = combined$n,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  out_tbl[["OR (95% CI)"]] <- or_ci_col
  out_tbl[["Direction"]]   <- direction

  # Optional pass-through columns -------------------------------------------
  opt_rename <- c(setting = "Setting", outcome_label = "Outcome", notes = "Notes")
  for (oc in present_opt) {
    out_tbl[[opt_rename[oc]]] <- combined[[oc]]
  }

  # ---------------------------------------------------------------------------
  # 8. Summary values for $or_range and $sentence
  # ---------------------------------------------------------------------------
  all_or   <- combined$or
  or_min   <- min(all_or, na.rm = TRUE)
  or_max   <- max(all_or, na.rm = TRUE)
  or_range <- paste0(fmt(or_min), "-", fmt(or_max))

  n_studies  <- nrow(combined)

  # Dominant insurance comparison label (most common) -----------------------
  comp_table <- sort(table(combined$insurance_comparison), decreasing = TRUE)
  dominant_comp <- if (length(comp_table) > 0L) names(comp_table)[1L] else ""

  # Build sentence -----------------------------------------------------------
  prior_label <- if (!is.null(current_study)) {
    paste0(n_studies - 1L, " published mystery-caller")
  } else {
    paste0(n_studies, " mystery-caller")
  }

  if (!is.null(current_study)) {
    cs_or_fmt <- fmt(as.numeric(current_study$or))
    sentence <- sprintf(
      "Across %s studies, ORs for %s ranged from %s, consistent with our finding of OR = %s.",
      prior_label,
      dominant_comp,
      or_range,
      cs_or_fmt
    )
  } else {
    sentence <- sprintf(
      "Across %s studies, ORs for %s ranged from %s.",
      prior_label,
      dominant_comp,
      or_range
    )
  }

  # ---------------------------------------------------------------------------
  # 9. Optional forest plot
  # ---------------------------------------------------------------------------
  forest_plot <- NULL
  if (include_forest) {
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
      warning(
        "Package 'ggplot2' is required for `include_forest = TRUE`. ",
        "Install with: install.packages('ggplot2'). ",
        "Returning `forest_plot = NULL`.",
        call. = FALSE
      )
    } else {
      plot_df <- data.frame(
        label     = author_display,
        or        = combined$or,
        ci_lower  = combined$ci_lower,
        ci_upper  = combined$ci_upper,
        current   = is_current_row,
        direction = direction,
        stringsAsFactors = FALSE
      )
      # Order rows top-to-bottom on the y-axis (reversed from table order)
      plot_df$y_pos <- seq(nrow(plot_df), 1L, by = -1L)

      forest_plot <- ggplot2::ggplot(
        plot_df,
        ggplot2::aes(x = or, y = y_pos)
      ) +
        ggplot2::geom_vline(xintercept = 1, linetype = "dashed",
                            colour = "grey40") +
        ggplot2::geom_errorbar(
          ggplot2::aes(xmin = ci_lower, xmax = ci_upper),
          orientation = "y",
          width       = 0.25,
          linewidth   = 0.6
        ) +
        ggplot2::geom_point(
          ggplot2::aes(shape = current),
          size = 2.5, fill = "white", stroke = 0.8
        ) +
        ggplot2::scale_shape_manual(
          values = c(`FALSE` = 16L, `TRUE` = 18L),
          guide  = "none"
        ) +
        ggplot2::scale_y_continuous(
          breaks = plot_df$y_pos,
          labels = plot_df$label
        ) +
        ggplot2::labs(
          x       = "Odds Ratio (95% CI)",
          y       = NULL,
          caption = "*** = Current study; dashed line at OR = 1 (no disparity)."
        ) +
        ggplot2::theme_bw(base_size = 10L) +
        ggplot2::theme(
          panel.grid.major.y = ggplot2::element_blank(),
          panel.grid.minor   = ggplot2::element_blank(),
          axis.text.y        = ggplot2::element_text(hjust = 1L)
        )
    }
  }

  # ---------------------------------------------------------------------------
  # 10. Assemble and return
  # ---------------------------------------------------------------------------
  structure(
    list(
      table       = out_tbl,
      forest_plot = forest_plot,
      n_studies   = n_studies,
      or_range    = or_range,
      sentence    = sentence
    ),
    class = "mysterycall_literature_table"
  )
}


# ---------------------------------------------------------------------------
# S3 print method
# ---------------------------------------------------------------------------

#' Print a mysterycall_literature_table object
#'
#' Prints the formatted comparison table, the OR range, and the Discussion
#' sentence to the console.
#'
#' @param x A `mysterycall_literature_table` object.
#' @param ... Ignored.
#'
#' @return `x`, invisibly.
#' @export
print.mysterycall_literature_table <- function(x, ...) {
  cat(sprintf(
    "\n-- Mystery-caller literature comparison (%d studies) --\n\n",
    x$n_studies
  ))
  print(x$table, row.names = FALSE)
  cat(sprintf("\nOR range: %s\n", x$or_range))
  cat("\nDiscussion sentence:\n")
  cat(x$sentence, "\n")
  if (!is.null(x$forest_plot)) {
    cat("\n(Forest plot available in $forest_plot)\n")
  }
  invisible(x)
}
