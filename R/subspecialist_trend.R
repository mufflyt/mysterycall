#' Subspecialist-density trend (per 100,000 women, multi-year)
#'
#' @name subspecialist_trend
NULL

#' Trend of OB-GYN subspecialist density per 100,000 women over time
#'
#' Computes subspecialists per 100,000 women for each subspecialty and year from
#' **raw counts** (numerator) divided by the **total female population**
#' (denominator), then draws a multi-year line/point trend -- one line per
#' subspecialty -- with optional direct end-of-line labels. The density is
#' derived from the inputs (`count / population * per`), never typed, so the
#' figure cannot disagree with its own numbers.
#'
#' **You supply both the counts and the denominators.** No population figures are
#' bundled with the package (they go stale and would need to be a cited vintage).
#' To fetch the total-female-population denominators from the U.S. Census ACS
#' 1-year tables (variable `B01001_026E`, "Estimate!!Total!!Female"), one call
#' per year:
#'
#' \preformatted{
#' # requires an internet connection and (optionally) a Census API key
#' fem_pop <- vapply(2013:2023, function(y) {
#'   u <- sprintf(
#'     "https://api.census.gov/data/\%d/acs/acs1?get=B01001_026E&for=us:1", y)
#'   as.numeric(jsonlite::fromJSON(u)[2, 1])
#' }, numeric(1))
#' names(fem_pop) <- 2013:2023
#' # NB: the ACS 1-year 2020 table was not released; use the 5-year 2020
#' #     table or a Population Estimates (PEP) value for that year.
#' }
#'
#' @param counts Subspecialist counts (numerator). One of:
#'   \itemize{
#'     \item a **long** data frame with the columns named by `subspecialty_col`,
#'       `year_col`, and `count_col`;
#'     \item a **wide** data frame with a `subspecialty_col` column plus one
#'       numeric column per year (headers like `2013` or `X2013`);
#'     \item a **matrix** with subspecialty row names and year column names.
#'   }
#' @param population Total female population (denominator). One of: a year-named
#'   numeric vector (names are years, e.g. `setNames(pop, 2013:2023)`), an
#'   unnamed numeric vector ordered by year, or a data frame with the columns
#'   `pop_year_col` and `pop_col`. Must cover every year present in `counts`.
#' @param subspecialty_col,year_col,count_col Column names for the long/wide
#'   `counts` form. Defaults `"subspecialty"`, `"year"`, `"count"`.
#' @param pop_year_col,pop_col Column names when `population` is a data frame.
#'   Defaults `"year"`, `"population"`.
#' @param per Numeric denominator scale. Default `1e5` (per 100,000 women).
#' @param title Character. Plot title. The observed year range is appended when
#'   `show_year_range = TRUE`.
#' @param show_year_range Logical. Append `", <min>-<max>"` to `title`.
#'   Default `TRUE`.
#' @param y_lab,x_lab Axis labels. `x_lab` defaults to `NULL` (no label, since
#'   the axis shows years).
#' @param palette Optional character vector of colours, one per subspecialty
#'   (passed to [ggplot2::scale_colour_manual()]). `NULL` uses the ggplot2
#'   default.
#' @param label_ends Logical. Label each line at its final year and hide the
#'   legend (`TRUE`, default) instead of showing a legend.
#' @param point_size,line_width Numeric point size and line width.
#' @param output_path Character or `NULL`. File path to save via
#'   [ggplot2::ggsave()]. `NULL` (default) writes nothing.
#' @param width,height Numeric. Saved size in inches. Defaults `9` x `5.5`.
#' @param dpi Integer. Resolution for raster output. Default `300`.
#'
#' @return A ggplot2 object (invisibly). Its `$data` holds the computed density
#'   table (`subspecialty`, `year`, `count`, `population`, `density`).
#'
#' @family manuscript
#' @seealso [mysterycall_subspecialist_infographic()] for the two-point
#'   (start -> end) infographic version.
#' @export
#'
#' @examples
#' # Long-format counts + a year-named female-population denominator.
#' counts <- data.frame(
#'   subspecialty = rep(c("Gynecologic Oncology", "Urogynecology"), each = 3),
#'   year         = rep(c(2013, 2018, 2023), times = 2),
#'   count        = c(1900, 2200, 2600, 900, 1400, 2100)
#' )
#' fem_pop <- c(`2013` = 160477237, `2018` = 165000000, `2023` = 168000000)
#' mysterycall_subspecialist_trend(counts, population = fem_pop)
mysterycall_subspecialist_trend <- function(
    counts,
    population,
    subspecialty_col = "subspecialty",
    year_col         = "year",
    count_col        = "count",
    pop_year_col     = "year",
    pop_col          = "population",
    per              = 1e5,
    title            = "OB-GYN Subspecialists per 100,000 Women",
    show_year_range  = TRUE,
    y_lab            = "Subspecialists per 100,000 women",
    x_lab            = NULL,
    palette          = NULL,
    label_ends       = TRUE,
    point_size       = 1.9,
    line_width       = 1.0,
    output_path      = NULL,
    width            = 9,
    height           = 5.5,
    dpi              = 300) {

  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Install with: install.packages('ggplot2')",
         call. = FALSE)
  if (missing(counts) || missing(population))
    stop("Supply both `counts` (numerator) and `population` (total female ",
         "population denominator).", call. = FALSE)

  d <- .counts_to_long(counts, subspecialty_col, year_col, count_col)
  if (any(is.na(d$year)))
    stop("Some `counts` years could not be parsed as integers.", call. = FALSE)
  if (any(d$count < 0, na.rm = TRUE))
    stop("`count` values must be non-negative.", call. = FALSE)

  pv <- .resolve_female_pop(population, d$year, pop_year_col, pop_col)
  d$population <- pv[as.character(d$year)]
  d$density    <- d$count / d$population * per
  d <- d[order(d$subspecialty, d$year), , drop = FALSE]

  years <- sort(unique(d$year))
  if (isTRUE(show_year_range))
    title <- sprintf("%s, %d–%d", title, min(years), max(years))

  p <- ggplot2::ggplot(
    d,
    ggplot2::aes(x = .data$year, y = .data$density,
                 colour = .data$subspecialty, group = .data$subspecialty)
  ) +
    ggplot2::geom_line(linewidth = line_width) +
    ggplot2::geom_point(size = point_size) +
    ggplot2::scale_x_continuous(
      breaks = years,
      expand = ggplot2::expansion(mult = c(0.02, if (label_ends) 0.22 else 0.05))
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, NA),
      expand = ggplot2::expansion(mult = c(0, 0.08))
    ) +
    ggplot2::labs(title = title, x = x_lab, y = y_lab, colour = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title       = ggplot2::element_text(face = "bold"),
      legend.position  = if (label_ends) "none" else "right"
    )

  if (!is.null(palette))
    p <- p + ggplot2::scale_colour_manual(values = palette)

  if (isTRUE(label_ends)) {
    ends <- d[d$year == max(years), , drop = FALSE]
    p <- p +
      ggplot2::geom_text(
        data    = ends,
        mapping = ggplot2::aes(label = .data$subspecialty),
        hjust = 0, nudge_x = 0.15, size = 3, show.legend = FALSE
      ) +
      ggplot2::coord_cartesian(clip = "off")
  }

  if (!is.null(output_path)) {
    ggplot2::ggsave(output_path, plot = p, width = width, height = height, dpi = dpi)
    message("Saved: ", output_path)
  }

  invisible(p)
}


# ---- package-internal helpers ------------------------------------------------

# Normalise `counts` (long df / wide df / matrix) to a long data frame with
# columns: subspecialty (chr), year (int), count (num).
.counts_to_long <- function(counts, subspecialty_col, year_col, count_col) {
  if (is.matrix(counts)) {
    ss <- rownames(counts); yr <- colnames(counts)
    if (is.null(ss) || is.null(yr))
      stop("A matrix `counts` needs subspecialty row names and year column names.",
           call. = FALSE)
    return(data.frame(
      subspecialty = rep(ss, times = ncol(counts)),
      year         = as.integer(rep(yr, each = nrow(counts))),
      count        = as.numeric(counts),
      stringsAsFactors = FALSE
    ))
  }
  if (!is.data.frame(counts))
    stop("`counts` must be a data frame or a matrix.", call. = FALSE)

  if (count_col %in% names(counts)) {
    # long form
    for (col in c(subspecialty_col, year_col, count_col))
      if (!col %in% names(counts))
        stop("Long `counts` is missing column: ", col, call. = FALSE)
    return(data.frame(
      subspecialty = as.character(counts[[subspecialty_col]]),
      year         = as.integer(counts[[year_col]]),
      count        = as.numeric(counts[[count_col]]),
      stringsAsFactors = FALSE
    ))
  }

  # wide form: subspecialty_col + one column per year
  if (!subspecialty_col %in% names(counts))
    stop("Wide `counts` needs a `", subspecialty_col,
         "` column plus one column per year.", call. = FALSE)
  year_cols <- setdiff(names(counts), subspecialty_col)
  if (!length(year_cols))
    stop("Wide `counts` has no year columns.", call. = FALSE)
  yr <- suppressWarnings(as.integer(gsub("^[Xx]", "", year_cols)))
  if (any(is.na(yr)))
    stop("Wide `counts` year columns must be numeric years (e.g. 2013 or X2013). ",
         "Offending: ", paste(year_cols[is.na(yr)], collapse = ", "), call. = FALSE)
  do.call(rbind, lapply(seq_along(year_cols), function(i) {
    data.frame(
      subspecialty = as.character(counts[[subspecialty_col]]),
      year         = yr[i],
      count        = as.numeric(counts[[year_cols[i]]]),
      stringsAsFactors = FALSE
    )
  }))
}

# Resolve `population` (year-named vector / ordered vector / data frame) to a
# named numeric vector keyed by year-as-character, covering every year needed.
.resolve_female_pop <- function(population, years, pop_year_col, pop_col) {
  years <- sort(unique(years))
  if (is.data.frame(population)) {
    for (col in c(pop_year_col, pop_col))
      if (!col %in% names(population))
        stop("`population` data frame is missing column: ", col, call. = FALSE)
    pv <- stats::setNames(
      as.numeric(population[[pop_col]]),
      as.character(as.integer(population[[pop_year_col]]))
    )
  } else if (is.numeric(population)) {
    if (!is.null(names(population))) {
      pv <- stats::setNames(as.numeric(population), as.character(names(population)))
    } else {
      if (length(population) != length(years))
        stop("Unnamed `population` must have one value per year (", length(years),
             "), ordered by year.", call. = FALSE)
      pv <- stats::setNames(as.numeric(population), as.character(years))
    }
  } else {
    stop("`population` must be a numeric vector (optionally year-named) or a ",
         "data frame.", call. = FALSE)
  }
  if (any(pv <= 0, na.rm = TRUE))
    stop("`population` values must be positive.", call. = FALSE)
  miss <- setdiff(as.character(years), names(pv))
  if (length(miss))
    stop("`population` is missing denominators for year(s): ",
         paste(miss, collapse = ", "), call. = FALSE)
  pv
}
