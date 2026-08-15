#' Subspecialist-density infographic (per 100,000 women)
#'
#' @name subspecialist_infographic
#' @keywords internal
NULL

#' Workforce-density infographic for OB-GYN subspecialists
#'
#' Reproduces the "clinicians per unit" infographic style (a titled header bar
#' over one accent-coloured panel per subspecialty) as a single ggplot2 object,
#' repurposed to show **subspecialists per 100,000 women** at two time points.
#' Each panel shows the subspecialty, the percent change, and the
#' `year_start` -> `year_end` values with a direction arrow. Percent change is
#' computed from the supplied values, never typed in, so the figure cannot
#' disagree with its own numbers.
#'
#' You supply the density values; nothing is imputed. Provide them either as the
#' `start` / `end` vectors (paste-friendly) or through a `data` frame.
#'
#' @param subspecialty Character vector of panel labels. Defaults to the four
#'   ABOG OB-GYN subspecialties (Gynecologic Oncology, Maternal-Fetal Medicine,
#'   Reproductive Endocrinology & Infertility, Urogynecology).
#' @param start,end Numeric vectors of density values (subspecialists per
#'   100,000 women) at `year_start` and `year_end`. Same length as
#'   `subspecialty`. Required unless supplied via `data`.
#' @param abbrev Character vector of short badge labels (one per panel). When
#'   `NULL` (default) a sensible abbreviation is derived from `subspecialty`
#'   (e.g. "MFM", "REI"); a newline in a badge splits it across two lines.
#' @param data Optional data frame carrying the values instead of the vectors.
#'   Columns are named by `subspecialty_col`, `start_col`, `end_col`, and
#'   optionally `abbrev_col`. When supplied it overrides the vector arguments.
#' @param subspecialty_col,start_col,end_col,abbrev_col Column names read from
#'   `data`. Defaults `"subspecialty"`, `"start"`, `"end"`, `"abbrev"`.
#' @param year_start,year_end Integer years shown under each value and appended
#'   to the header title. Defaults `2018` and `2023`.
#' @param title Character. Header title; the year range is appended
#'   automatically (e.g. `"...: 2018-2023"`).
#' @param palette Character vector of panel accent colours, recycled across
#'   panels (defaults alternate a blue and a green, matching the source figure).
#' @param header_fill Character. Fill colour of the header bar.
#' @param increase_color,decrease_color Character. Colours for a rising vs.
#'   falling density (used for the percent change when
#'   `color_pct_by = "direction"`, and always for the value arrow).
#' @param color_pct_by One of `"direction"` (default; green up / red down) or
#'   `"panel"` (colour the percent change with the panel accent, like the
#'   source figure).
#' @param digits Integer. Decimal places for the density values. Default `2`.
#' @param numerator_source Character or `NULL`. Citation for the subspecialist
#'   densities/counts. Recorded in the provenance and, if set, shown in the
#'   caption.
#' @param denominator_source Character. Citation for the female-population
#'   denominator. Defaults to the U.S. Census ACS 1-year table B01001
#'   (`B01001_026E`). Set to `NULL` to omit.
#' @param denominator_vintage Character or `NULL`. Extra denominator detail
#'   recorded in the provenance.
#' @param accessed Date or character or `NULL`. When the source data were
#'   pulled (recorded in the provenance and caption).
#' @param notes Character or `NULL`. Free-text note recorded in the provenance.
#' @param caption Character, `NULL`, or `NA`. Bottom source caption. `NULL`
#'   (default) auto-builds a source line from provenance; `NA` (or `""`) draws
#'   none; a string is used verbatim.
#' @param write_provenance Logical. When `output_path` is set, also write
#'   provenance sidecars next to the image: a human-readable
#'   `<output>.provenance.txt` and, when \pkg{jsonlite} is installed, a
#'   machine-readable `<output>.provenance.json` (schema `mysterycall/provenance`)
#'   carrying the record and the per-panel values. Default `TRUE`.
#' @param output_path Character or `NULL`. File path to save via
#'   [ggplot2::ggsave()] (`.png`, `.pdf`, `.tiff`, `.svg`). `NULL` (default)
#'   writes nothing.
#' @param width,height Numeric. Saved size in inches. Defaults `10` x `4.8`.
#' @param dpi Integer. Resolution for raster output. Default `300`.
#'
#' @return A ggplot2 object (invisibly); `attr(p, "provenance")` holds a
#'   `mysterycall_provenance` record. When `output_path` is set the image is
#'   written (plus `<output>.provenance.txt` and, if \pkg{jsonlite} is installed,
#'   `<output>.provenance.json` sidecars unless `write_provenance = FALSE`) and
#'   the path messaged.
#'
#' @family manuscript
#' @seealso [mysterycall_flow_diagram()], [mysterycall_strobe_flow()]
#' @export
#'
#' @examples
#' # Paste your own per-100,000-women densities for the four ABOG subspecialties:
#' mysterycall_subspecialist_infographic(
#'   start = c(1.20, 0.95, 0.80, 0.40),   # 2018
#'   end   = c(1.35, 1.02, 0.88, 0.61)    # 2023
#' )
#'
#' # Or from a data frame, with custom panels and a saved file:
#' df <- data.frame(
#'   subspecialty = c("Gynecologic Oncology", "Maternal-Fetal Medicine"),
#'   start        = c(1.20, 0.95),
#'   end          = c(1.35, 1.02)
#' )
#' \dontrun{
#' mysterycall_subspecialist_infographic(data = df,
#'                                       output_path = "subspecialists_per_100k.png")
#' }
mysterycall_subspecialist_infographic <- function(
    subspecialty = c("Gynecologic Oncology",
                     "Maternal-Fetal Medicine",
                     "Reproductive Endocrinology & Infertility",
                     "Urogynecology"),
    start,
    end,
    abbrev           = NULL,
    data             = NULL,
    subspecialty_col = "subspecialty",
    start_col        = "start",
    end_col          = "end",
    abbrev_col       = "abbrev",
    year_start       = 2018L,
    year_end         = 2023L,
    title            = "OB-GYN Subspecialists per 100,000 Women",
    palette          = c("#1F4E66", "#2F6F3E"),
    header_fill      = "#2E6E8E",
    increase_color   = "#2F6F3E",
    decrease_color   = "#B22222",
    color_pct_by     = c("direction", "panel"),
    digits           = 2L,
    numerator_source    = NULL,
    denominator_source  = paste0("U.S. Census Bureau, American Community Survey ",
                                 "1-year estimates, table B01001 (B01001_026E, ",
                                 "total female population)"),
    denominator_vintage = NULL,
    accessed            = NULL,
    notes               = NULL,
    caption             = NULL,
    write_provenance    = TRUE,
    output_path      = NULL,
    width            = 10,
    height           = 4.8,
    dpi              = 300) {

  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Install with: install.packages('ggplot2')",
         call. = FALSE)

  color_pct_by <- match.arg(color_pct_by)

  # ---- resolve inputs (data frame OR vectors) --------------------------------
  if (!is.null(data)) {
    if (!is.data.frame(data))
      stop("`data` must be a data frame.", call. = FALSE)
    for (col in c(subspecialty_col, start_col, end_col))
      if (!col %in% names(data))
        stop("`data` is missing required column: ", col, call. = FALSE)
    subspecialty <- as.character(data[[subspecialty_col]])
    start        <- as.numeric(data[[start_col]])
    end          <- as.numeric(data[[end_col]])
    if (!is.null(abbrev_col) && abbrev_col %in% names(data))
      abbrev <- as.character(data[[abbrev_col]])
  }

  if (missing(start) || missing(end))
    stop("Supply `start` and `end` (subspecialists per 100,000 women for ",
         year_start, " and ", year_end, "), as vectors or via `data`.",
         call. = FALSE)

  n <- length(subspecialty)
  if (length(start) != n || length(end) != n)
    stop("`subspecialty`, `start`, and `end` must have the same length (",
         n, ").", call. = FALSE)
  if (!is.numeric(start) || !is.numeric(end))
    stop("`start` and `end` must be numeric.", call. = FALSE)
  if (any(start < 0, na.rm = TRUE) || any(end < 0, na.rm = TRUE))
    stop("`start` and `end` must be non-negative.", call. = FALSE)
  if (!is.null(abbrev) && length(abbrev) != n)
    stop("`abbrev` must have one entry per subspecialty (", n, ").",
         call. = FALSE)

  if (is.null(abbrev)) abbrev <- .abbrev_subspecialty(subspecialty)

  # ---- derive percent change (from the values, never typed) ------------------
  pct     <- ifelse(start > 0, (end - start) / start * 100, NA_real_)
  pct_lbl <- ifelse(is.na(pct), "n/a", sprintf("%+.1f%%", pct))
  dir     <- ifelse(is.na(pct) | pct == 0, "flat",
                    ifelse(pct > 0, "up", "down"))

  accent  <- rep_len(palette, n)
  pct_col <- switch(
    color_pct_by,
    panel     = accent,
    direction = ifelse(dir == "up", increase_color,
                       ifelse(dir == "down", decrease_color, "#555555"))
  )
  arrow_col <- ifelse(dir == "up", increase_color,
                      ifelse(dir == "down", decrease_color, "#999999"))

  fmt_val <- function(x) formatC(round(x, digits), format = "f", digits = digits)

  # ---- provenance ------------------------------------------------------------
  prov <- .build_provenance(
    metric              = "Subspecialists per 100,000 women",
    computation         = "percent change = (end - start) / start * 100; density values supplied",
    numerator_desc      = "Subspecialist density at two time points (user-supplied)",
    denominator_desc    = "Total female population",
    generated_by        = "mysterycall::mysterycall_subspecialist_infographic()",
    years               = c(as.integer(year_start), as.integer(year_end)),
    n_series            = n,
    numerator_source    = numerator_source,
    denominator_source  = denominator_source,
    denominator_vintage = denominator_vintage,
    accessed            = accessed,
    notes               = notes
  )
  prov_table <- data.frame(
    subspecialty = subspecialty,
    start        = start,
    end          = end,
    pct_change   = round(pct, 1),
    stringsAsFactors = FALSE
  )
  names(prov_table)[2:3] <- c(paste0("y", year_start), paste0("y", year_end))

  cap <- if (is.null(caption)) .provenance_caption(prov)
         else if (length(caption) == 1L && is.na(caption)) ""
         else caption

  # ---- layout (points/text sized in absolute units; badges stay circular) ----
  cx    <- seq_len(n) - 0.5          # panel centres on x in [0, n]
  xmax  <- n
  y_badge <- 0.80; y_name <- 0.635; y_pct <- 0.46; y_val <- 0.29; y_year <- 0.205

  wrap_name <- vapply(
    subspecialty,
    function(s) stringr::str_wrap(toupper(s), width = 16),
    character(1)
  )

  p <- ggplot2::ggplot() +
    ggplot2::coord_cartesian(xlim = c(0, xmax), ylim = c(0, 1.02), clip = "off") +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      plot.margin     = ggplot2::margin(6, 6, 6, 6)
    )

  # header bar
  p <- p +
    ggplot2::annotate("rect", xmin = 0.03, xmax = xmax - 0.03,
                      ymin = 0.905, ymax = 1.0, fill = header_fill, colour = NA) +
    ggplot2::annotate("text", x = xmax / 2, y = 0.9525,
                      label = sprintf("%s: %d–%d", toupper(title),
                                      as.integer(year_start), as.integer(year_end)),
                      colour = "white", fontface = "bold", size = 5)

  # accent badges + abbreviation
  p <- p +
    ggplot2::annotate("point", x = cx, y = y_badge, shape = 21,
                      size = 22, fill = accent, colour = accent, stroke = 0) +
    ggplot2::annotate("text", x = cx, y = y_badge, label = abbrev,
                      colour = "white", fontface = "bold", size = 2.7,
                      lineheight = 0.9)

  # subspecialty names
  p <- p +
    ggplot2::annotate("text", x = cx, y = y_name, label = wrap_name,
                      colour = accent, fontface = "bold", size = 3.1,
                      lineheight = 0.95, vjust = 1)

  # percent change (headline)
  p <- p +
    ggplot2::annotate("text", x = cx, y = y_pct, label = pct_lbl,
                      colour = pct_col, fontface = "bold", size = 6.2)

  # start -> end values with a direction arrow
  p <- p +
    ggplot2::annotate("text", x = cx - 0.20, y = y_val, label = fmt_val(start),
                      colour = "#333333", fontface = "bold", size = 3.3, hjust = 1) +
    ggplot2::annotate("segment", x = cx - 0.09, xend = cx + 0.09,
                      y = y_val, yend = y_val, colour = arrow_col, linewidth = 0.7,
                      arrow = ggplot2::arrow(length = ggplot2::unit(0.14, "cm"),
                                             type = "closed")) +
    ggplot2::annotate("text", x = cx + 0.20, y = y_val, label = fmt_val(end),
                      colour = "#333333", fontface = "bold", size = 3.3, hjust = 0)

  # year labels
  p <- p +
    ggplot2::annotate("text", x = cx - 0.20, y = y_year,
                      label = as.integer(year_start),
                      colour = "#8A8A8A", size = 2.6, hjust = 1) +
    ggplot2::annotate("text", x = cx + 0.20, y = y_year,
                      label = as.integer(year_end),
                      colour = "#8A8A8A", size = 2.6, hjust = 0)

  # source caption (wrapped) along the bottom
  if (nzchar(cap)) {
    p <- p +
      ggplot2::annotate("text", x = xmax / 2, y = 0.03,
                        label = stringr::str_wrap(cap, width = 120),
                        colour = "#777777", size = 2.2, hjust = 0.5,
                        lineheight = 0.95)
  }

  attr(p, "provenance") <- prov

  if (!is.null(output_path)) {
    ggplot2::ggsave(output_path, plot = p, width = width, height = height, dpi = dpi)
    message("Saved: ", output_path)
    if (isTRUE(write_provenance)) .write_provenance(prov, output_path, prov_table)
  }

  invisible(p)
}


# ---- package-internal helper -------------------------------------------------

# Derive a short badge label from a subspecialty name: use a known abbreviation
# where possible, otherwise the initials of each word (up to 4 letters).
.abbrev_subspecialty <- function(x) {
  map <- c(
    "gynecologic oncology"                              = "GYN\nONC",
    "maternal-fetal medicine"                           = "MFM",
    "maternal fetal medicine"                           = "MFM",
    "reproductive endocrinology & infertility"          = "REI",
    "reproductive endocrinology and infertility"        = "REI",
    "urogynecology"                                     = "URO\nGYN",
    "female pelvic medicine & reconstructive surgery"   = "FPMRS",
    "female pelvic medicine and reconstructive surgery" = "FPMRS",
    "complex family planning"                           = "CFP"
  )
  key <- tolower(trimws(x))
  out <- unname(map[key])
  miss <- is.na(out)
  if (any(miss)) {
    out[miss] <- vapply(x[miss], function(s) {
      words <- strsplit(gsub("[^A-Za-z ]", " ", s), "\\s+")[[1]]
      words <- words[nzchar(words)]
      if (!length(words)) return("")
      substr(toupper(paste0(substr(words, 1, 1), collapse = "")), 1, 4)
    }, character(1))
  }
  out
}
