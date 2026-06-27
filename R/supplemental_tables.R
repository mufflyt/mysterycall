#' Export a publication-ready supplemental Excel workbook
#'
#' @name mysterycall_supplemental_tables
NULL

# ---------------------------------------------------------------------------
# Internal helper: write one data.frame as a zebra-striped sheet
# ---------------------------------------------------------------------------

#' @keywords internal
.xlsx_add_sheet <- function(wb, sheet_name, df) {
  openxlsx::addWorksheet(wb, sheetName = sheet_name)

  n_rows <- nrow(df)
  n_cols <- ncol(df)

  # --- styles -----------------------------------------------------------------
  header_style <- openxlsx::createStyle(
    fontColour  = "#FFFFFF",
    fgFill      = "#2C3E50",
    halign      = "LEFT",
    textDecoration = "bold",
    border      = "Bottom",
    borderColour = "#2C3E50",
    wrapText    = FALSE
  )

  stripe_style <- openxlsx::createStyle(
    fgFill = "#EAF2F8"   # light blue-grey for even rows
  )

  plain_style <- openxlsx::createStyle(
    fgFill = "#FFFFFF"
  )

  # --- write data + header row ------------------------------------------------
  openxlsx::writeData(wb, sheet = sheet_name, x = df,
                      startRow = 1L, startCol = 1L,
                      headerStyle = header_style,
                      borders = "rows",
                      borderStyle = "thin")

  # --- zebra stripes on data rows (row 1 is the header inside writeData) ------
  if (n_rows > 0L) {
    for (i in seq_len(n_rows)) {
      row_idx <- i + 1L   # +1 because row 1 is the header
      sty <- if (i %% 2L == 0L) stripe_style else plain_style
      openxlsx::addStyle(wb, sheet = sheet_name, style = sty,
                         rows = row_idx, cols = seq_len(n_cols),
                         gridExpand = TRUE, stack = TRUE)
    }
  }

  # --- auto-fit column widths -------------------------------------------------
  openxlsx::setColWidths(wb, sheet = sheet_name,
                         cols = seq_len(n_cols), widths = "auto")

  invisible(NULL)
}


# ---------------------------------------------------------------------------
# Main exported function
# ---------------------------------------------------------------------------

#' Export a publication-ready supplemental Excel workbook
#'
#' Collects results from [mysterycall_logistic_model()],
#' [mysterycall_poisson_model()], [mysterycall_nb_model()], and/or
#' [mysterycall_lmm()] into a single, formatted Excel workbook ready for
#' journal submission as an online supplement.
#'
#' Each sheet receives zebra-stripe row shading, a bold dark-blue header row,
#' and auto-fitted column widths. The workbook metadata records the author name
#' (when supplied) and the creation date.
#'
#' @param logistic_fit A `mysterycall_logistic_model` object returned by
#'   [mysterycall_logistic_model()], or `NULL` (default). When non-`NULL`,
#'   the full odds-ratio table (all terms, including the intercept) is written
#'   to **Sheet 1 "OR Table"**.
#' @param poisson_fit A `mysterycall_poisson_model` or `mysterycall_nb_model`
#'   object, or `NULL` (default). When non-`NULL`, the full IRR table is
#'   written to **Sheet 2 "IRR Table"**.
#' @param lmm_fit A `mysterycall_lmm` object returned by
#'   [mysterycall_lmm()], or `NULL` (default). When non-`NULL`, the
#'   coefficient table is written as an additional sheet ("LMM Coefs"); if a
#'   geometric-mean-ratio table is present it is appended as "LMM GMR".
#' @param extra_tables A named `list` of `data.frame`s to include as
#'   additional sheets. Each element name becomes the sheet name (truncated
#'   to 31 characters as required by Excel). Default `list()`.
#' @param file Character scalar. Output file path. The `.xlsx` extension is
#'   appended automatically when absent. Default `"supplemental_tables.xlsx"`.
#' @param overwrite Logical. When `FALSE` (default) the function stops if
#'   `file` already exists. Set `TRUE` to silently overwrite.
#' @param author Character scalar or `NULL`. Author name written to the
#'   workbook's Creator property. Default `NULL` (uses the current system
#'   user via [Sys.info()]).
#'
#' @details
#' ## Sheet contents
#'
#' | Sheet | Populated when |
#' |---|---|
#' | **OR Table** | `logistic_fit` is non-`NULL` |
#' | **IRR Table** | `poisson_fit` is non-`NULL` |
#' | **Model Comparison** | at least two of the three model fits are non-`NULL` |
#' | **Complete Cases** | any model fit is non-`NULL` |
#' | **Session Info** | always |
#' | **LMM Coefs** | `lmm_fit` is non-`NULL` |
#' | **LMM GMR** | `lmm_fit` non-`NULL` and `lmm_fit$gmr_table` non-`NULL` |
#' | *(extra names)* | corresponding element of `extra_tables` |
#'
#' ## Requires
#' The `openxlsx` package must be installed (it is listed in `Suggests`).
#' Install with `install.packages("openxlsx")`.
#'
#' @return `invisible(file)` — the normalised absolute path to the written
#'   workbook, so the path can be captured and passed to downstream functions.
#'
#' @family reporting
#' @seealso [mysterycall_logistic_model()], [mysterycall_poisson_model()],
#'   [mysterycall_nb_model()], [mysterycall_lmm()], [mysterycall_model_table()]
#' @export
#'
#' @examples
#' \dontrun{
#' ## Logistic + Poisson fits from a mystery-caller dataset
#' set.seed(42)
#' df <- data.frame(
#'   offered   = rbinom(80, 1L, 0.7),
#'   wait_days = rpois(80, lambda = 12),
#'   insurance = rep(c("Medicaid", "BCBS"), 40),
#'   physician = rep(paste0("Dr", 1:20), each = 4L),
#'   stringsAsFactors = FALSE
#' )
#'
#' log_fit <- mysterycall_logistic_model(df, "offered",   "insurance", "physician")
#' poi_fit <- mysterycall_poisson_model(df, "wait_days",  "insurance", "physician")
#'
#' out <- mysterycall_supplemental_tables(
#'   logistic_fit = log_fit,
#'   poisson_fit  = poi_fit,
#'   file         = "supplement.xlsx",
#'   overwrite    = TRUE,
#'   author       = "Tyler Muffly"
#' )
#' message("Workbook written to: ", out)
#' }
mysterycall_supplemental_tables <- function(logistic_fit = NULL,
                                             poisson_fit  = NULL,
                                             lmm_fit      = NULL,
                                             extra_tables = list(),
                                             file         = "supplemental_tables.xlsx",
                                             overwrite    = FALSE,
                                             author       = NULL) {

  # -- openxlsx availability ---------------------------------------------------
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    stop(
      "Package 'openxlsx' is required. Install with: install.packages('openxlsx')",
      call. = FALSE
    )
  }

  # -- Argument validation -----------------------------------------------------
  if (!is.character(file) || length(file) != 1L || nchar(trimws(file)) == 0L) {
    stop("`file` must be a non-empty character scalar.", call. = FALSE)
  }

  # Ensure .xlsx extension
  if (!grepl("\\.xlsx$", file, ignore.case = TRUE)) {
    file <- paste0(file, ".xlsx")
  }
  file <- normalizePath(file, mustWork = FALSE)

  if (!is.logical(overwrite) || length(overwrite) != 1L) {
    stop("`overwrite` must be a single logical value.", call. = FALSE)
  }
  if (file.exists(file) && !overwrite) {
    stop(
      sprintf("File already exists: '%s'. Set `overwrite = TRUE` to replace it.", file),
      call. = FALSE
    )
  }

  if (!is.null(author) && (!is.character(author) || length(author) != 1L)) {
    stop("`author` must be a single character string or NULL.", call. = FALSE)
  }

  if (!is.list(extra_tables)) {
    stop("`extra_tables` must be a named list of data.frames.", call. = FALSE)
  }
  if (length(extra_tables) > 0L) {
    if (is.null(names(extra_tables)) || any(nchar(names(extra_tables)) == 0L)) {
      stop("Every element of `extra_tables` must have a non-empty name.", call. = FALSE)
    }
    not_df <- !vapply(extra_tables, is.data.frame, logical(1L))
    if (any(not_df)) {
      stop(
        sprintf(
          "The following `extra_tables` elements are not data.frames: %s",
          paste(names(extra_tables)[not_df], collapse = ", ")
        ),
        call. = FALSE
      )
    }
  }

  # -- At least one content source required ------------------------------------
  has_content <- (
    !is.null(logistic_fit) ||
    !is.null(poisson_fit)  ||
    !is.null(lmm_fit)      ||
    length(extra_tables) > 0L
  )
  if (!has_content) {
    stop(
      "At least one of `logistic_fit`, `poisson_fit`, `lmm_fit`, or `extra_tables` must be non-NULL.",
      call. = FALSE
    )
  }

  # -- Class guards for model objects ------------------------------------------
  if (!is.null(logistic_fit) &&
      !inherits(logistic_fit, "mysterycall_logistic_model")) {
    stop(
      "`logistic_fit` must be a `mysterycall_logistic_model` object or NULL.",
      call. = FALSE
    )
  }
  if (!is.null(poisson_fit) &&
      !inherits(poisson_fit, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    stop(
      "`poisson_fit` must be a `mysterycall_poisson_model`, `mysterycall_nb_model` object, or NULL.",
      call. = FALSE
    )
  }
  if (!is.null(lmm_fit) && !inherits(lmm_fit, "mysterycall_lmm")) {
    stop("`lmm_fit` must be a `mysterycall_lmm` object or NULL.", call. = FALSE)
  }

  # -- Resolve author ----------------------------------------------------------
  creator <- if (!is.null(author)) author else {
    si <- tryCatch(Sys.info()[["user"]], error = function(e) "Unknown")
    if (is.na(si) || nchar(si) == 0L) "Unknown" else si
  }

  # -- Create workbook ---------------------------------------------------------
  wb <- openxlsx::createWorkbook(creator = creator)
  openxlsx::modifyBaseFont(wb, fontSize = 11, fontName = "Calibri")

  # ---- Sheet 1: OR Table (logistic model) ------------------------------------
  if (!is.null(logistic_fit)) {
    or_tbl <- logistic_fit$or_table
    # Rename columns to publication-friendly labels
    out_or <- data.frame(
      Term          = or_tbl$term,
      `Log-Odds`    = round(or_tbl$estimate,  4L),
      `SE`          = round(or_tbl$se,         4L),
      `z`           = round(or_tbl$z_value,    3L),
      `OR`          = round(or_tbl$or,         3L),
      `CI Lower`    = round(or_tbl$ci_lower,   3L),
      `CI Upper`    = round(or_tbl$ci_upper,   3L),
      `p-value`     = or_tbl$p_value_fmt,
      stringsAsFactors = FALSE,
      check.names   = FALSE
    )
    .xlsx_add_sheet(wb, "OR Table", out_or)
  }

  # ---- Sheet 2: IRR Table (Poisson / NB model) -------------------------------
  if (!is.null(poisson_fit)) {
    irr_tbl <- poisson_fit$irr_table
    out_irr <- data.frame(
      Term          = irr_tbl$term,
      `Log-Rate`    = round(irr_tbl$estimate,  4L),
      `SE`          = round(irr_tbl$se,         4L),
      `z`           = round(irr_tbl$z_value,    3L),
      `IRR`         = round(irr_tbl$irr,        3L),
      `CI Lower`    = round(irr_tbl$ci_lower,   3L),
      `CI Upper`    = round(irr_tbl$ci_upper,   3L),
      `p-value`     = irr_tbl$p_value_fmt,
      stringsAsFactors = FALSE,
      check.names   = FALSE
    )
    .xlsx_add_sheet(wb, "IRR Table", out_irr)
  }

  # ---- Sheet 3: Model Comparison (AIC / BIC) ---------------------------------
  n_models <- sum(c(!is.null(logistic_fit),
                    !is.null(poisson_fit),
                    !is.null(lmm_fit)))
  if (n_models >= 2L) {
    mc_rows <- list()

    if (!is.null(logistic_fit)) {
      mc_rows[["Logistic (GLMM)"]] <- c(
        logistic_fit$aic,
        logistic_fit$bic,
        logistic_fit$n,
        logistic_fit$n_dropped
      )
    }
    if (!is.null(poisson_fit)) {
      label <- if (inherits(poisson_fit, "mysterycall_nb_model")) {
        "Negative-Binomial (GLMM)"
      } else {
        "Poisson (GLMM)"
      }
      mc_rows[[label]] <- c(
        poisson_fit$aic,
        poisson_fit$bic,
        poisson_fit$n,
        poisson_fit$n_dropped
      )
    }
    if (!is.null(lmm_fit)) {
      mc_rows[["LMM"]] <- c(
        lmm_fit$aic,
        lmm_fit$bic,
        lmm_fit$n,
        lmm_fit$n_dropped
      )
    }

    mc_mat  <- do.call(rbind, mc_rows)
    mc_df   <- data.frame(
      Model       = rownames(mc_mat),
      AIC         = round(mc_mat[, 1L], 2L),
      BIC         = round(mc_mat[, 2L], 2L),
      n           = as.integer(mc_mat[, 3L]),
      n_dropped   = as.integer(mc_mat[, 4L]),
      stringsAsFactors = FALSE,
      check.names = FALSE,
      row.names   = NULL
    )
    best_aic <- which.min(mc_df$AIC)
    mc_df$delta_AIC  <- round(mc_df$AIC - mc_df$AIC[[best_aic]], 2L)
    mc_df$AIC_winner <- mc_df$Model == mc_df$Model[[best_aic]]

    .xlsx_add_sheet(wb, "Model Comparison", mc_df)
  }

  # ---- Sheet 4: Complete Cases -----------------------------------------------
  cc_rows <- list()

  .make_cc_row <- function(label, n_total, n, n_dropped) {
    pct <- if (n_total > 0L) round(100 * n / n_total, 1L) else NA_real_
    data.frame(
      Model      = label,
      n_total    = as.integer(n_total),
      n_complete = as.integer(n),
      n_dropped  = as.integer(n_dropped),
      pct_complete = pct,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }

  if (!is.null(logistic_fit)) {
    n_tot <- logistic_fit$n + logistic_fit$n_dropped
    cc_rows[["logistic"]] <- .make_cc_row(
      "Logistic (GLMM)", n_tot, logistic_fit$n, logistic_fit$n_dropped
    )
  }
  if (!is.null(poisson_fit)) {
    n_tot <- poisson_fit$n + poisson_fit$n_dropped
    label <- if (inherits(poisson_fit, "mysterycall_nb_model")) {
      "Negative-Binomial (GLMM)"
    } else {
      "Poisson (GLMM)"
    }
    cc_rows[["poisson"]] <- .make_cc_row(
      label, n_tot, poisson_fit$n, poisson_fit$n_dropped
    )
  }
  if (!is.null(lmm_fit)) {
    n_tot <- lmm_fit$n + lmm_fit$n_dropped
    cc_rows[["lmm"]] <- .make_cc_row(
      "LMM", n_tot, lmm_fit$n, lmm_fit$n_dropped
    )
  }

  if (length(cc_rows) > 0L) {
    cc_df <- do.call(rbind, cc_rows)
    rownames(cc_df) <- NULL
    names(cc_df)[names(cc_df) == "pct_complete"] <- "% complete"
    .xlsx_add_sheet(wb, "Complete Cases", cc_df)
  }

  # ---- Sheet 5: Session Info -------------------------------------------------
  pkg_deps <- c("mysterycall", "openxlsx", "lme4", "lmerTest",
                "glmmTMB", "tibble", "stats")
  pkg_info <- vapply(pkg_deps, function(p) {
    tryCatch(
      as.character(utils::packageVersion(p)),
      error = function(e) NA_character_
    )
  }, character(1L))

  rv <- R.version
  si_df <- data.frame(
    Item  = c("R version",
              "R platform",
              "Date created",
              paste0("Package: ", pkg_deps)),
    Value = c(
      paste0(rv$major, ".", rv$minor),
      rv$platform,
      format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
      pkg_info
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  .xlsx_add_sheet(wb, "Session Info", si_df)

  # ---- Optional LMM sheets ---------------------------------------------------
  if (!is.null(lmm_fit)) {
    coef_tbl <- lmm_fit$coef_table
    out_lmm <- data.frame(
      Term         = coef_tbl$term,
      Estimate     = round(coef_tbl$estimate,  4L),
      SE           = round(coef_tbl$se,         4L),
      t            = round(coef_tbl$t_value,    3L),
      df           = round(coef_tbl$df,         1L),
      `CI Lower`   = round(coef_tbl$ci_lower,   3L),
      `CI Upper`   = round(coef_tbl$ci_upper,   3L),
      `p-value`    = coef_tbl$p_value_fmt,
      stringsAsFactors = FALSE,
      check.names  = FALSE
    )
    .xlsx_add_sheet(wb, "LMM Coefs", out_lmm)

    if (!is.null(lmm_fit$gmr_table)) {
      g <- lmm_fit$gmr_table
      out_gmr <- data.frame(
        Term       = g$term,
        GMR        = round(g$GMR,    3L),
        `GMR Low`  = round(g$GMR_lo, 3L),
        `GMR High` = round(g$GMR_hi, 3L),
        `p-value`  = g$p_value_fmt,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
      .xlsx_add_sheet(wb, "LMM GMR", out_gmr)
    }
  }

  # ---- Extra user-supplied tables --------------------------------------------
  if (length(extra_tables) > 0L) {
    # Excel sheet names max 31 characters; deduplicate if needed
    used_names <- openxlsx::sheets(wb)
    for (nm in names(extra_tables)) {
      safe_nm <- substr(nm, 1L, 31L)
      # Resolve collisions with a numeric suffix
      candidate <- safe_nm
      suffix    <- 1L
      while (candidate %in% used_names) {
        candidate <- substr(paste0(safe_nm, "_", suffix), 1L, 31L)
        suffix    <- suffix + 1L
      }
      used_names <- c(used_names, candidate)
      .xlsx_add_sheet(wb, candidate, extra_tables[[nm]])
    }
  }

  # -- Save workbook -----------------------------------------------------------
  openxlsx::saveWorkbook(wb, file = file, overwrite = overwrite)

  invisible(file)
}
