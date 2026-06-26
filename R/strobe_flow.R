#' STROBE flow diagram for mystery-caller studies
#'
#' @name strobe_flow
NULL

#' Draw a STROBE-compliant flow diagram for mystery-caller (secret-shopper) studies
#'
#' Produces a publication-quality STROBE/CONSORT-style participant flow diagram
#' using ggplot2.  The diagram shows the complete filtering waterfall from the
#' raw call log to the two downstream analysis populations (logistic model and
#' wait-time model), with a right-side exclusion branch that lists each
#' exclusion-code category and its count.
#'
#' **Three input modes - use whichever is most convenient:**
#' \enumerate{
#'   \item **Raw data frame or CSV path** (`data`): all counts and exclusion
#'     details are computed automatically by calling [mysterycall_prepare_calls()]
#'     internally.  This is the recommended path for most users.
#'   \item **`mysterycall_prepared` object** (`prepared`): pass the object
#'     returned by [mysterycall_prepare_calls()] directly.  Useful when you
#'     have already run the preparation step.
#'   \item **Explicit counts** (`n_total`, `n_calldate`, ...): supply every N
#'     value by hand.  Useful for manual overrides or non-REDCap data.
#' }
#'
#' **REDCap exclusion-code labels:**
#' \itemize{
#'   \item Code 1 - Closed medical system (Kaiser / military)
#'   \item Code 2 - On hold > 5 minutes
#'   \item Code 3 - Wrong number or wrong specialty
#'   \item Code 5 - Phone not answered / busy signal
#'   \item Code 6 - Physician's personal phone
#'   \item Code 7 - Referral required before scheduling
#'   \item Code 8 - Voicemail
#'   \item Code 9 - Not accepting new patients
#'   \item Code 10 - Must see midlevel provider first
#'   \item Code NA - Exclusion code pending review
#' }
#'
#' @param data A data frame (raw REDCap export) **or** a character string
#'   giving the path to a CSV file.  When supplied, [mysterycall_prepare_calls()]
#'   is called internally using `col_calldate`, `col_exclusions`, and
#'   `col_appdate` to derive all N counts automatically.  All `n_*` arguments
#'   and `excl_detail` are ignored when `data` is provided.
#' @param prepared A `mysterycall_prepared` object returned by
#'   [mysterycall_prepare_calls()]. Counts are extracted automatically.
#'   Ignored when `data` is supplied.
#' @param col_calldate Character. Name of the call-date column in `data`.
#'   Default `"calldate1"`.
#' @param col_exclusions Character. Name of the exclusion-code column in `data`.
#'   Default `"exclusions"`.
#' @param col_appdate Character. Name of the appointment-date column in `data`.
#'   Default `"appdate"`.
#' @param n_total Integer. Total call records.  Required when neither `data`
#'   nor `prepared` is supplied.
#' @param n_calldate Integer. Records with a call date present.
#' @param n_included Integer. Records with exclusion code 0 (scheduling
#'   discussion took place).
#' @param n_logistic Integer. Records entering the logistic model.
#'   Defaults to `n_included`.
#' @param n_waittime Integer. Records entering the wait-time model
#'   (appointment date present).
#' @param excl_no_calldate Integer. Records dropped for missing call date.
#'   Default: `n_total - n_calldate`.
#' @param excl_detail Named integer vector of per-code exclusion counts.
#'   Names are REDCap codes as characters (`"1"`, `"2"`, ..., `"NA"`).
#'   Derived automatically when `data` or `prepared` is supplied.
#' @param label_total Character. Box label for the initial count.
#' @param label_calldate Character. Box label for the call-date step.
#' @param label_included Character. Box label for the included set.
#' @param label_logistic Character. Box label for the logistic analysis.
#' @param label_waittime Character. Box label for the wait-time analysis.
#' @param title Character. Plot title.
#' @param output_path Character or `NULL`. File path to save the diagram
#'   (`.png`, `.tiff`, `.pdf`, `.svg`).  When `NULL` (default), no file is
#'   written.  Raster formats also save a paired copy in the other format.
#' @param width Numeric. Width in inches. Default `9`.
#' @param height Numeric. Height in inches. Default `11`.
#' @param dpi Integer. Resolution for raster formats. Default `300`.
#'
#' @return A `ggplot2` object (invisibly).
#'
#' @family manuscript
#' @seealso [mysterycall_prepare_calls()], [mysterycall_flow_diagram()],
#'   [mysterycall_strobe_checklist()]
#' @export
#'
#' @examples
#' # Mode 1: from a data frame (simplest) — requires an existing CSV file.
#' \dontrun{
#' raw <- read.csv("ICVsPOPVsSUI_DATA_2026-06-23_1225.csv",
#'                 stringsAsFactors = FALSE)
#' mysterycall_strobe_flow(data = raw,
#'                         title = "STROBE Flow - ICVs vs POP vs SUI Study")
#' }
#'
#' # Mode 2: from a mysterycall_prepared object — requires prepare_calls() first.
#' \dontrun{
#' prepped <- mysterycall_prepare_calls(raw)
#' mysterycall_strobe_flow(prepared = prepped)
#' }
#'
#' # Mode 3: explicit counts (for non-REDCap data or manual overrides)
#' mysterycall_strobe_flow(
#'   n_total    = 743,
#'   n_calldate = 737,
#'   n_included = 141,
#'   n_waittime = 100
#' )
mysterycall_strobe_flow <- function(
    data             = NULL,
    prepared         = NULL,
    col_calldate     = "calldate1",
    col_exclusions   = "exclusions",
    col_appdate      = "appdate",
    n_total          = NULL,
    n_calldate       = NULL,
    n_included       = NULL,
    n_logistic       = NULL,
    n_waittime       = NULL,
    excl_no_calldate = NULL,
    excl_detail      = NULL,
    label_total      = "Call attempts logged",
    label_calldate   = "Call date recorded\n(call was placed)",
    label_included   = "Scheduling discussion possible\n(exclusion code = 0)",
    label_logistic   = "Logistic analysis\nOutcome: appointment offered (yes/no)",
    label_waittime   = "Wait-time analysis\nOutcome: days to appointment",
    title            = "STROBE Flow Diagram - Mystery-Caller Study",
    output_path      = NULL,
    width            = 9,
    height           = 11,
    dpi              = 300
) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Install with: install.packages('ggplot2')",
         call. = FALSE)

  # ---- Mode 1: raw data frame or CSV path ------------------------------------
  if (!is.null(data)) {
    if (is.character(data) && length(data) == 1L) {
      if (!file.exists(data))
        stop("File not found: ", data, call. = FALSE)
      data <- utils::read.csv(data, stringsAsFactors = FALSE)
      message("Read ", nrow(data), " rows from CSV.")
    }
    if (!is.data.frame(data))
      stop("`data` must be a data frame or a file path to a CSV.", call. = FALSE)

    prepared <- mysterycall_prepare_calls(
      data,
      col_calldate   = col_calldate,
      col_exclusions = col_exclusions,
      col_appdate    = col_appdate,
      na_exclusions  = "warn"
    )
  }

  # ---- Mode 2: mysterycall_prepared object -----------------------------------
  if (!is.null(prepared)) {
    if (!inherits(prepared, "mysterycall_prepared"))
      stop("`prepared` must be a `mysterycall_prepared` object.", call. = FALSE)

    wf         <- prepared$waterfall
    n_total    <- n_total    %||% wf$n_remaining[1L]
    n_calldate <- n_calldate %||% wf$n_remaining[2L]

    # n_included = records with exclusion code 0 specifically
    if (is.null(n_included) && !is.null(prepared$exclusion_summary)) {
      es     <- prepared$exclusion_summary
      codes  <- as.character(es$Code)
      codes[is.na(es$Code)] <- "NA"
      n_included <- as.integer(es$Freq[codes == "0"])
      if (length(n_included) != 1L) n_included <- NULL
    }
    n_included <- n_included %||% nrow(prepared$logistic_data)
    n_logistic <- n_logistic %||% n_included
    n_waittime <- n_waittime %||% nrow(prepared$waittime_data)

    # excl_detail: per-code counts, excluding code 0
    if (is.null(excl_detail) && !is.null(prepared$exclusion_summary)) {
      es     <- prepared$exclusion_summary
      codes  <- as.character(es$Code)
      codes[is.na(es$Code)] <- "NA"
      excl_detail <- stats::setNames(as.integer(es$Freq), codes)
      excl_detail <- excl_detail[codes != "0"]
    }
  }

  # ---- Mode 3: validate explicit counts --------------------------------------
  needed <- c("n_total", "n_calldate", "n_included", "n_waittime")
  miss   <- needed[sapply(needed, function(x) is.null(get(x)))]
  if (length(miss))
    stop("Could not determine: ", paste(miss, collapse = ", "),
         ". Supply `data`, `prepared`, or all n_* arguments.", call. = FALSE)

  n_total          <- as.integer(n_total)
  n_calldate       <- as.integer(n_calldate)
  n_included       <- as.integer(n_included)
  n_logistic       <- as.integer(n_logistic %||% n_included)
  n_waittime       <- as.integer(n_waittime)
  excl_no_calldate <- as.integer(excl_no_calldate %||% (n_total - n_calldate))

  # ---- Build exclusion labels -------------------------------------------------
  code_labels <- c(
    "1"  = "Closed medical system",
    "2"  = "On hold > 5 min",
    "3"  = "Wrong number / specialty",
    "5"  = "No answer / busy signal",
    "6"  = "Physician's personal phone",
    "7"  = "Referral required",
    "8"  = "Voicemail",
    "9"  = "Not accepting new patients",
    "10" = "Must see midlevel first",
    "NA" = "Exclusion code pending"
  )

  excl_total_screen <- n_calldate - n_included

  if (!is.null(excl_detail)) {
    detail_lines <- character(0)
    for (code in names(code_labels)) {
      n <- excl_detail[[code]]
      if (!is.null(n) && !is.na(n) && n > 0)
        detail_lines <- c(detail_lines,
                          sprintf("  - %s: %d", code_labels[[code]], as.integer(n)))
    }
    excl_screen_lbl <- paste0(
      "Excluded (n = ", .fmt_n(excl_total_screen), ")\n",
      paste(detail_lines, collapse = "\n")
    )
  } else {
    excl_screen_lbl <- sprintf("Excluded\n(n = %s)", .fmt_n(excl_total_screen))
  }

  excl_waittime <- n_logistic - n_waittime
  excl_ncd_lbl  <- sprintf("No call date recorded\n(n = %s)", .fmt_n(excl_no_calldate))
  excl_wt_lbl   <- sprintf("No appointment date\n(not offered or pending)\n(n = %s)",
                            .fmt_n(excl_waittime))

  # ---- Layout -----------------------------------------------------------------
  # Layout - all coordinates in [0,1] (y=1 top, y=0 bottom).
  cx    <- 0.30   # main column centre x
  ex    <- 0.80   # exclusion column centre x
  bw    <- 0.26   # main box half-width   -> right edge at 0.56
  ebw   <- 0.18   # excl box half-width   -> left edge at 0.62 (gap = 0.06)
  bh    <- 0.046  # main box half-height
  ebh_s <- 0.030  # small exclusion box half-height (2-3 lines)
  arr   <- ggplot2::arrow(length = ggplot2::unit(0.18, "cm"), type = "closed")

  y1 <- 0.920   # total
  y2 <- 0.770   # calldate
  y3 <- 0.480   # included  <- pushed down to give the excl box more room
  y4 <- 0.235   # logistic
  y5 <- 0.060   # waittime

  # tap points - midpoints on the main vertical line between consecutive boxes
  tap_ncd  <- (y1 + y2) / 2   # ~0.845
  tap_excl <- (y2 + y3) / 2   # ~0.625
  tap_wt   <- (y4 + y5) / 2   # ~0.148

  # Screening exclusion box height: fill 80% of the available gap between
  # box2-bottom and box3-top so the box never overlaps the main-column boxes.
  n_det_lines <- if (!is.null(excl_detail))
    sum(excl_detail[names(excl_detail) != "0"] > 0, na.rm = TRUE) else 0L
  available   <- ((y2 - bh) - (y3 + bh)) / 2   # half of gap between boxes
  ebh_screen  <- available * 0.90                # use 90% of that half-gap

  # ---- Drawing helpers --------------------------------------------------------
  .rect <- function(p, xc, yc, hw, hh) {
    p + ggplot2::annotate("rect",
                          xmin = xc - hw, xmax = xc + hw,
                          ymin = yc - hh, ymax = yc + hh,
                          fill = "white", colour = "black", linewidth = 0.55)
  }
  .txt <- function(p, xc, yc, label, size = 3.1, bold = FALSE) {
    p + ggplot2::annotate("text",
                          x = xc, y = yc, label = label,
                          size = size, hjust = 0.5, vjust = 0.5,
                          fontface = if (bold) "bold" else "plain",
                          lineheight = 1.10)
  }
  .mbox <- function(p, xc, yc, hw, hh, label, size = 3.1, bold = FALSE) {
    .txt(.rect(p, xc, yc, hw, hh), xc, yc, label, size, bold)
  }
  .varrow <- function(p, y_top, y_bot, xc = cx) {
    p + ggplot2::annotate("segment",
                          x = xc, xend = xc, y = y_top, yend = y_bot,
                          arrow = arr, linewidth = 0.45)
  }
  .harrow <- function(p, y_tap, x_from, x_to) {
    p + ggplot2::annotate("segment",
                          x = x_from, xend = x_to, y = y_tap, yend = y_tap,
                          arrow = arr, linewidth = 0.45)
  }
  .vseg <- function(p, y_from, y_to, xc = cx) {
    p + ggplot2::annotate("segment",
                          x = xc, xend = xc, y = y_from, yend = y_to,
                          linewidth = 0.45)
  }

  # ---- Build plot -------------------------------------------------------------
  p <- ggplot2::ggplot() +
    ggplot2::xlim(0, 1) + ggplot2::ylim(0, 1) +
    ggplot2::labs(title = title) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.title  = ggplot2::element_text(hjust = 0.5, size = 12, face = "bold",
                                          margin = ggplot2::margin(b = 8)),
      plot.margin = ggplot2::margin(14, 8, 8, 8)
    )

  # Box 1 - total
  p <- .mbox(p, cx, y1, bw, bh,
             paste0(label_total, "\n(N = ", .fmt_n(n_total), ")"), bold = TRUE)
  p <- .vseg(p, y1 - bh, tap_ncd)
  p <- .harrow(p, tap_ncd, cx + bw, ex - ebw)
  p <- .mbox(p, ex, tap_ncd, ebw, ebh_s, excl_ncd_lbl, size = 2.7)
  p <- .varrow(p, tap_ncd, y2 + bh)

  # Box 2 - calldate
  p <- .mbox(p, cx, y2, bw, bh,
             paste0(label_calldate, "\n(n = ", .fmt_n(n_calldate), ")"))
  p <- .vseg(p, y2 - bh, tap_excl)
  p <- .harrow(p, tap_excl, cx + bw, ex - ebw)
  p <- .mbox(p, ex, tap_excl, ebw, ebh_screen, excl_screen_lbl,
             size = if (n_det_lines > 6) 2.3 else 2.6)
  p <- .varrow(p, tap_excl, y3 + bh)

  # Box 3 - included
  p <- .mbox(p, cx, y3, bw, bh,
             paste0(label_included, "\n(n = ", .fmt_n(n_included), ")"))
  p <- .varrow(p, y3 - bh, y4 + bh)

  # Box 4 - logistic
  p <- .mbox(p, cx, y4, bw, bh,
             paste0(label_logistic, "\n(n = ", .fmt_n(n_logistic), ")"), bold = TRUE)
  p <- .vseg(p, y4 - bh, tap_wt)
  p <- .harrow(p, tap_wt, cx + bw, ex - ebw)
  p <- .mbox(p, ex, tap_wt, ebw, ebh_s + 0.010, excl_wt_lbl, size = 2.7)
  p <- .varrow(p, tap_wt, y5 + bh)

  # Box 5 - waittime
  p <- .mbox(p, cx, y5, bw, bh,
             paste0(label_waittime, "\n(n = ", .fmt_n(n_waittime), ")"), bold = TRUE)

  # ---- Save ------------------------------------------------------------------
  if (!is.null(output_path)) {
    fmt <- tolower(tools::file_ext(output_path))
    ggplot2::ggsave(output_path, plot = p, width = width, height = height, dpi = dpi)
    message("Saved: ", output_path)
    if (fmt %in% c("png", "tiff", "jpg", "jpeg")) {
      base  <- tools::file_path_sans_ext(output_path)
      other <- if (fmt == "png") paste0(base, ".tiff") else paste0(base, ".png")
      comp  <- if (grepl("\\.tiff?$", other)) "lzw" else NULL
      ggplot2::ggsave(other, plot = p, width = width, height = height, dpi = dpi,
                      compression = comp)
      message("Also saved: ", other)
    }
  }

  invisible(p)
}


# ---- package-internal helpers ------------------------------------------------

`%||%` <- function(a, b) if (!is.null(a)) a else b

.fmt_n <- function(n) format(as.integer(n), big.mark = ",")
