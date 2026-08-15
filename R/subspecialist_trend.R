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
#' @param conf_level Numeric in `(0, 1)` or `NULL`. When set (e.g. `0.95`), an
#'   exact Poisson confidence interval is computed for each rate and drawn as a
#'   shaded band per subspecialty; the limits are added to `$data` as
#'   `density_low` / `density_high`. `NULL` (default) draws no interval. Treats
#'   each count as Poisson given its year's population denominator.
#' @param trend_test `FALSE` (default), `TRUE`, `"poisson"`, or
#'   `"quasipoisson"`. When enabled, fits a per-subspecialty log-linear
#'   regression of count on year with an offset of `log(population)`, i.e. a
#'   model of the rate's annual change, and attaches the tidy result as
#'   `attr(p, "trend_test")` (annual rate ratio, CI, percent change per year and
#'   over the span, and the year-term p-value). `TRUE` uses Poisson (Wald);
#'   `"quasipoisson"` uses a t-test on the overdispersion-scaled SE. The CI uses
#'   `conf_level` when set, else 95%. When `label_ends` is on, each line's label
#'   also shows the rate ratio per year and a significance star.
#' @param numerator_source Character or `NULL`. Citation for the subspecialist
#'   counts (e.g. `"ABOG certified-diplomate counts, 2013-2023"`). Recorded in
#'   the provenance and, if set, shown in the figure caption.
#' @param denominator_source Character. Citation for the female-population
#'   denominator. Defaults to the U.S. Census ACS 1-year table B01001
#'   (`B01001_026E`). Set to `NULL` to omit.
#' @param denominator_vintage Character or `NULL`. Extra denominator detail
#'   recorded in the provenance (e.g. `"ACS 1-year 2013-2023; 2020 from ACS
#'   5-year"`).
#' @param accessed Date or character or `NULL`. When the source data were
#'   pulled (recorded in the provenance and caption).
#' @param notes Character or `NULL`. Free-text note recorded in the provenance.
#' @param caption Character, `NULL`, or `NA`. Figure caption. `NULL` (default)
#'   auto-builds a source line from the numerator/denominator provenance; `NA`
#'   (or `""`) draws no caption; a string is used verbatim.
#' @param write_provenance Logical. When `output_path` is set, also write
#'   provenance sidecars next to the image: a human-readable
#'   `<output>.provenance.txt` and, when \pkg{jsonlite} is installed, a
#'   machine-readable `<output>.provenance.json` (schema `mysterycall/provenance`)
#'   carrying the record and the per-point density table. Default `TRUE`.
#' @param output_path Character or `NULL`. File path to save via
#'   [ggplot2::ggsave()]. `NULL` (default) writes nothing.
#' @param width,height Numeric. Saved size in inches. Defaults `9` x `5.5`.
#' @param dpi Integer. Resolution for raster output. Default `300`.
#'
#' @return A ggplot2 object (invisibly). Its `$data` holds the computed density
#'   table (`subspecialty`, `year`, `count`, `population`, `density`, plus
#'   `density_low` / `density_high` when `conf_level` is set). When
#'   `trend_test` is enabled, `attr(p, "trend_test")` holds the per-subspecialty
#'   trend statistics (and they are folded into the JSON/txt provenance
#'   sidecars). `attr(p, "provenance")` holds a `mysterycall_provenance` record
#'   (metric,
#'   computation, numerator/denominator sources, package version, access date,
#'   and creation timestamp). When saved, `<output>.provenance.txt` and (if
#'   \pkg{jsonlite} is installed) `<output>.provenance.json` sidecars are written
#'   alongside the image (unless `write_provenance = FALSE`).
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
    conf_level       = NULL,
    trend_test       = FALSE,
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

  # optional exact Poisson confidence interval on each rate
  show_ci <- !is.null(conf_level)
  if (show_ci) {
    if (!is.numeric(conf_level) || length(conf_level) != 1L ||
        conf_level <= 0 || conf_level >= 1)
      stop("`conf_level` must be a single number in (0, 1), e.g. 0.95.",
           call. = FALSE)
    ci <- .poisson_rate_ci(d$count, d$population, per, conf_level)
    d$density_low  <- ci$lower
    d$density_high <- ci$upper
  }

  years <- sort(unique(d$year))
  if (isTRUE(show_year_range))
    title <- sprintf("%s, %d\u2013%d", title, min(years), max(years))

  # ---- optional per-subspecialty trend statistic -----------------------------
  do_test   <- !is.null(trend_test) && !isFALSE(trend_test)
  trend_tbl <- NULL
  if (do_test) {
    fam <- if (isTRUE(trend_test)) "poisson"
           else match.arg(as.character(trend_test), c("poisson", "quasipoisson"))
    test_conf <- if (is.null(conf_level)) 0.95 else conf_level
    trend_tbl <- .subspecialty_trend_test(d, fam, test_conf)
  }

  # ---- provenance ------------------------------------------------------------
  prov <- .build_provenance(
    metric              = sprintf("Subspecialists per %s women",
                                  format(per, big.mark = ",", scientific = FALSE)),
    computation         = sprintf(
      "density = count / population * %s%s",
      format(per, scientific = FALSE),
      paste0(
        if (show_ci) sprintf("; %g%% exact Poisson CI on each rate",
                             conf_level * 100) else "",
        if (do_test) sprintf("; per-subspecialty %s trend of count on year (offset log population)",
                             fam) else "")),
    numerator_desc      = "Subspecialist counts by subspecialty and year (user-supplied)",
    denominator_desc    = "Total female population by year",
    generated_by        = "mysterycall::mysterycall_subspecialist_trend()",
    per                 = per,
    years               = years,
    n_series            = length(unique(d$subspecialty)),
    numerator_source    = numerator_source,
    denominator_source  = denominator_source,
    denominator_vintage = denominator_vintage,
    accessed            = accessed,
    notes               = notes
  )

  # caption: NULL -> auto from provenance; NA / "" -> none; string -> literal
  cap <- if (is.null(caption)) .provenance_caption(prov)
         else if (length(caption) == 1L && is.na(caption)) ""
         else caption
  if (!nzchar(cap)) cap <- NULL

  p <- ggplot2::ggplot(
    d,
    ggplot2::aes(x = .data$year, y = .data$density,
                 colour = .data$subspecialty, group = .data$subspecialty)
  )
  if (show_ci) {
    p <- p + ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$density_low, ymax = .data$density_high,
                   fill = .data$subspecialty),
      alpha = 0.15, colour = NA, show.legend = FALSE
    )
    if (!is.null(palette))
      p <- p + ggplot2::scale_fill_manual(values = palette)
  }
  p <- p +
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
    ggplot2::labs(title = title, x = x_lab, y = y_lab, colour = NULL,
                  caption = cap) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title       = ggplot2::element_text(face = "bold"),
      plot.caption     = ggplot2::element_text(size = 7, colour = "#666666",
                                               hjust = 0),
      legend.position  = if (label_ends) "none" else "right"
    )

  if (!is.null(palette))
    p <- p + ggplot2::scale_colour_manual(values = palette)

  if (isTRUE(label_ends)) {
    ends <- d[d$year == max(years), , drop = FALSE]
    ends$.lab <- ends$subspecialty
    if (do_test) {
      m    <- trend_tbl[match(ends$subspecialty, trend_tbl$subspecialty), ]
      star <- ifelse(is.na(m$p_value), "",
                ifelse(m$p_value < 0.001, "***",
                  ifelse(m$p_value < 0.01, "**",
                    ifelse(m$p_value < 0.05, "*", ""))))
      ends$.lab <- ifelse(
        is.na(m$rr_per_year), ends$subspecialty,
        sprintf("%s\n(\u00d7%.3f/yr%s)", ends$subspecialty, m$rr_per_year, star)
      )
    }
    p <- p +
      ggplot2::geom_text(
        data    = ends,
        mapping = ggplot2::aes(label = .data[[".lab"]]),
        hjust = 0, nudge_x = 0.15, size = 3, lineheight = 0.9,
        show.legend = FALSE
      ) +
      ggplot2::coord_cartesian(clip = "off")
  }

  attr(p, "provenance") <- prov
  if (do_test) attr(p, "trend_test") <- trend_tbl

  if (!is.null(output_path)) {
    ggplot2::ggsave(output_path, plot = p, width = width, height = height, dpi = dpi)
    message("Saved: ", output_path)
    if (isTRUE(write_provenance))
      .write_provenance(prov, output_path, d,
                        extra = if (do_test) list(trend_test = trend_tbl) else NULL)
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

# Per-subspecialty trend test: a log-linear regression of count on year with an
# offset of log(population), i.e. a model of the rate's annual change. Returns a
# tidy data frame, one row per subspecialty, with the annual rate ratio
# (exp(beta_year)), its CI, the implied percent change per year and over the
# observed span, and the year-term p-value. `family` is "poisson" (Wald z) or
# "quasipoisson" (t with residual df, robust to overdispersion). Subspecialties
# with fewer than two distinct years return an all-NA row (a slope is undefined).
.subspecialty_trend_test <- function(d, family, conf) {
  crit_z <- stats::qnorm(1 - (1 - conf) / 2)
  subs   <- unique(d$subspecialty)
  rows   <- lapply(subs, function(s) {
    di      <- d[d$subspecialty == s, , drop = FALSE]
    n_years <- length(unique(di$year))
    base <- data.frame(
      subspecialty = s, n_years = n_years, family = family,
      rr_per_year = NA_real_, conf_low = NA_real_, conf_high = NA_real_,
      pct_per_year = NA_real_, pct_total = NA_real_, p_value = NA_real_,
      stringsAsFactors = FALSE
    )
    if (n_years < 2L) return(base)
    fit <- tryCatch(
      stats::glm(count ~ year, family = family,
                 offset = log(di$population), data = di),
      error = function(e) NULL
    )
    if (is.null(fit)) return(base)
    co <- stats::coef(summary(fit))
    if (!"year" %in% rownames(co)) return(base)
    est  <- co["year", "Estimate"]
    se   <- co["year", 2L]
    pval <- co["year", ncol(co)]          # Pr(>|z|) or Pr(>|t|), last column
    crit <- if (family == "quasipoisson")
      stats::qt(1 - (1 - conf) / 2, df = stats::df.residual(fit)) else crit_z
    span <- diff(range(di$year))
    base$rr_per_year  <- exp(est)
    base$conf_low     <- exp(est - crit * se)
    base$conf_high    <- exp(est + crit * se)
    base$pct_per_year <- (exp(est) - 1) * 100
    base$pct_total    <- (exp(est * span) - 1) * 100
    base$p_value      <- pval
    base
  })
  do.call(rbind, rows)
}

# Exact (Poisson) confidence interval for a rate = count / population * per.
# Uses the gamma/chi-square relationship (Garwood exact limits on the Poisson
# mean): lower = qgamma(a/2, count), upper = qgamma(1 - a/2, count + 1), with the
# lower limit defined as 0 when count == 0. Base R only; vectorised.
.poisson_rate_ci <- function(count, population, per, conf_level) {
  alpha <- 1 - conf_level
  lo_ct <- ifelse(count <= 0, 0, stats::qgamma(alpha / 2, shape = count))
  hi_ct <- stats::qgamma(1 - alpha / 2, shape = count + 1)
  list(lower = lo_ct / population * per,
       upper = hi_ct / population * per)
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
