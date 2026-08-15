#' Compute the wait-time equalization (crossover) point between two insurance groups
#'
#' @name mysterycall_wait_time_crossover
NULL

#' Compute the wait-time equalization point between two insurance groups
#'
#' Fits a simple linear regression of one insurance group's wait times against
#' another (paired by physician), then solves for the crossover day -- the number
#' of business days at which both groups predict the same wait time.  This
#' mirrors the scatter-plot analysis from the ortho sports medicine mystery-caller
#' Rmd, where Medicaid and BCBS wait times were plotted on log-log axes and the
#' intersection with the 45-degree (y = x) line was computed as
#' \eqn{x_{\text{cross}} = b / (1 - m)}, where \eqn{m} is the regression slope
#' and \eqn{b} is the intercept.
#'
#' Beyond the crossover point, \code{group1} patients experience longer waits
#' than \code{group2} patients (when \eqn{0 < m < 1} and the crossover exists).
#'
#' @param data A \code{data.frame} containing the study data.
#' @param time_col Character scalar.  Name of the column containing the wait
#'   time in business days.  Must be numeric and strictly positive when
#'   \code{log_transform = TRUE}.  Default
#'   \code{"business_days_until_appointment"}.
#' @param group_col Character scalar.  Name of the insurance/grouping column.
#'   Default \code{"insurance"}.
#' @param id_col Character scalar.  Name of the physician identifier column used
#'   to pair observations across insurance groups (e.g., phone number or NPI).
#'   Default \code{"phone"}.
#' @param group1 Character scalar or \code{NULL}.  Label for the first group
#'   (x-axis predictor in the regression).  When \code{NULL} (default), the
#'   first value in alphabetical order among unique \code{group_col} values is
#'   used.
#' @param group2 Character scalar or \code{NULL}.  Label for the second group
#'   (y-axis outcome in the regression).  When \code{NULL} (default), the
#'   second value in alphabetical order is used.
#' @param log_transform Logical scalar.  When \code{TRUE} (default), both
#'   wait-time columns are log-transformed before regression, matching the
#'   log-log axes of the source Rmd.  The crossover point is back-transformed
#'   with \code{exp()} before it is returned.  Rows where either group value is
#'   \code{<= 0} are silently dropped when \code{log_transform = TRUE}.
#' @param conf_level Numeric scalar in \code{(0, 1)}.  Confidence level passed
#'   through; stored on the result for downstream use.  Default \code{0.95}.
#' @param min_pairs Integer scalar.  Minimum number of paired physicians
#'   required after dropping incomplete rows.  An error is raised when fewer
#'   complete pairs are found.  Default \code{10L}.
#'
#' @return A named list of class \code{mysterycall_wait_time_crossover}:
#'   \describe{
#'     \item{\code{crossover_days}}{Numeric scalar.  The equalization point in
#'       business days (original scale, regardless of \code{log_transform}).
#'       \code{NA_real_} when the crossover is undefined, i.e., when the
#'       regression slope is \eqn{\ge 1} (diverging) or \eqn{\le 0} (no
#'       consistent direction).}
#'     \item{\code{slope}}{Numeric scalar.  Regression slope \eqn{m}.}
#'     \item{\code{intercept}}{Numeric scalar.  Regression intercept \eqn{b}.}
#'     \item{\code{r_squared}}{Numeric scalar.  \eqn{R^2} of the fitted linear
#'       model.}
#'     \item{\code{n_pairs}}{Integer scalar.  Number of physicians with
#'       non-missing data in both groups.}
#'     \item{\code{group1}}{Character scalar.  Label of the x-axis group.}
#'     \item{\code{group2}}{Character scalar.  Label of the y-axis group.}
#'     \item{\code{conf_level}}{Numeric scalar.  As supplied.}
#'     \item{\code{log_transform}}{Logical scalar.  As supplied.}
#'     \item{\code{plot_data}}{A \code{data.frame} with two columns named after
#'       \code{group1} and \code{group2}, each containing the original-scale
#'       (untransformed) wait times for physicians with complete pairs.
#'       Suitable for external \pkg{ggplot2} scatter-plot construction.}
#'     \item{\code{model}}{The fitted \code{lm} object (on the transformed
#'       scale when \code{log_transform = TRUE}).}
#'     \item{\code{sentence}}{Character scalar.  A plain-language summary
#'       suitable for direct insertion into a manuscript Results section.}
#'   }
#'
#' @details
#' \strong{Crossover formula.}
#' The regression line is \eqn{y = m x + b}.  Setting \eqn{y = x} (the 45-degree
#' line) and solving gives \eqn{x = b / (1 - m)}.  A finite, positive crossover
#' requires \eqn{0 < m < 1}:
#' \itemize{
#'   \item \eqn{m \ge 1}: the regression line never crosses y = x; \code{group2}
#'     wait times diverge from \code{group1}.
#'   \item \eqn{m \le 0}: the relationship is non-positive; no meaningful
#'     equalization point exists.
#' }
#' When \code{log_transform = TRUE} the regression operates on
#' \eqn{\log(\text{days})}; the crossover is solved on the log scale and
#' then returned as \eqn{\exp(x_{\text{cross}})}.
#'
#' \strong{Pairing.}
#' Observations are matched on \code{id_col} using \code{merge(..., by = id_col,
#' all = FALSE)}, so only physicians appearing in \emph{both} insurance groups
#' contribute.  When a physician has more than one observation per group, all
#' observations are kept and merged by their natural order after subsetting;
#' for studies with exactly one call per physician per group this is unambiguous.
#'
#' @seealso [mysterycall_kaplan_meier()], [mysterycall_lmm()]
#' @family outcomes
#' @export
#'
#' @examples
#' set.seed(42)
#' n_doc         <- 30
#' bcbs_days     <- pmax(1, round(stats::rnorm(n_doc, mean = 12, sd = 4)))
#' medicaid_days <- pmax(1, round(stats::rnorm(n_doc, mean = 18, sd = 6)))
#'
#' df <- data.frame(
#'   phone     = rep(sprintf("555-%04d", seq_len(n_doc)), times = 2L),
#'   insurance = rep(c("BCBS", "Medicaid"), each = n_doc),
#'   business_days_until_appointment = c(bcbs_days, medicaid_days)
#' )
#'
#' result <- mysterycall_wait_time_crossover(df, min_pairs = 5L)
#' print(result)
#'
#' ## Access individual components
#' result$crossover_days
#' result$r_squared
#' head(result$plot_data)
mysterycall_wait_time_crossover <- function(
    data,
    time_col      = "business_days_until_appointment",
    group_col     = "insurance",
    id_col        = "phone",
    group1        = NULL,
    group2        = NULL,
    log_transform = TRUE,
    conf_level    = 0.95,
    min_pairs     = 10L
) {
  # ---- input validation -------------------------------------------------------
  stopifnot("`data` must be a data frame" = is.data.frame(data))
  stopifnot("`time_col` must be a single column name" = is.character(time_col) && length(time_col) == 1L)
  stopifnot("`group_col` must be a single column name" = is.character(group_col) && length(group_col) == 1L)
  stopifnot("`id_col` must be a single column name" = is.character(id_col) && length(id_col) == 1L)
  stopifnot(
    "`log_transform` must be a single non-NA logical (TRUE/FALSE)" =
      is.logical(log_transform) && length(log_transform) == 1L && !is.na(log_transform)
  )
  stopifnot(
    "`conf_level` must be a single number in (0, 1)" =
      is.numeric(conf_level) && length(conf_level) == 1L &&
        conf_level > 0 && conf_level < 1
  )

  min_pairs <- as.integer(min_pairs)
  if (is.na(min_pairs) || min_pairs < 1L) {
    stop("`min_pairs` must be a positive integer.", call. = FALSE)
  }

  for (col in c(time_col, group_col, id_col)) {
    if (!col %in% names(data)) {
      stop(sprintf(
        "Column '%s' not found in `data`.\nAvailable columns: %s",
        col, paste(names(data), collapse = ", ")
      ), call. = FALSE)
    }
  }

  if (!is.numeric(data[[time_col]])) {
    stop(sprintf(
      "Column '%s' must be numeric; received %s.",
      time_col, class(data[[time_col]])[1L]
    ), call. = FALSE)
  }

  # ---- resolve group labels ---------------------------------------------------
  all_groups <- sort(unique(as.character(data[[group_col]])))
  all_groups <- all_groups[!is.na(all_groups)]

  if (length(all_groups) < 2L) {
    stop(
      "'", group_col, "' must contain at least 2 distinct non-NA levels; ",
      length(all_groups), " found.",
      call. = FALSE
    )
  }

  if (is.null(group1)) group1 <- all_groups[1L]
  if (is.null(group2)) group2 <- all_groups[2L]

  if (!group1 %in% all_groups) {
    stop(sprintf(
      "group1 '%s' not found in column '%s'.\nAvailable values: %s",
      group1, group_col, paste(all_groups, collapse = ", ")
    ), call. = FALSE)
  }
  if (!group2 %in% all_groups) {
    stop(sprintf(
      "group2 '%s' not found in column '%s'.\nAvailable values: %s",
      group2, group_col, paste(all_groups, collapse = ", ")
    ), call. = FALSE)
  }
  if (identical(group1, group2)) {
    stop("group1 and group2 must be different values.", call. = FALSE)
  }

  # ---- subset to the two groups and pivot wide --------------------------------
  grp_col_vals <- as.character(data[[group_col]])

  sub1 <- data[grp_col_vals == group1, c(id_col, time_col), drop = FALSE]
  sub2 <- data[grp_col_vals == group2, c(id_col, time_col), drop = FALSE]

  names(sub1)[names(sub1) == time_col] <- ".g1_time"
  names(sub2)[names(sub2) == time_col] <- ".g2_time"

  paired <- merge(sub1, sub2, by = id_col, all = FALSE)

  # ---- drop incomplete / invalid rows -----------------------------------------
  ok <- !is.na(paired[[".g1_time"]]) & !is.na(paired[[".g2_time"]])
  if (log_transform) {
    ok <- ok & (paired[[".g1_time"]] > 0) & (paired[[".g2_time"]] > 0)
  }
  paired <- paired[ok, , drop = FALSE]

  n_pairs <- nrow(paired)

  if (n_pairs < min_pairs) {
    stop(
      "Only ", n_pairs, " complete pair(s) found after removing NA",
      if (log_transform) "/non-positive" else "",
      " values; min_pairs = ", min_pairs, ".",
      call. = FALSE
    )
  }

  # ---- build plot_data on original (untransformed) scale ----------------------
  plot_data <- data.frame(
    g1 = paired[[".g1_time"]],
    g2 = paired[[".g2_time"]],
    stringsAsFactors = FALSE
  )
  names(plot_data) <- c(group1, group2)

  # ---- optionally log-transform for regression --------------------------------
  x_fit <- paired[[".g1_time"]]
  y_fit <- paired[[".g2_time"]]

  if (log_transform) {
    x_fit <- log(x_fit)
    y_fit <- log(y_fit)
  }

  fit_df <- data.frame(x = x_fit, y = y_fit)

  # ---- fit lm(group2 ~ group1) ------------------------------------------------
  fit  <- stats::lm(y ~ x, data = fit_df)
  sm   <- summary(fit)

  m    <- stats::coef(fit)[["x"]]
  b    <- stats::coef(fit)[["(Intercept)"]]
  r_sq <- sm$r.squared

  # ---- compute crossover on the (possibly log-) scale -------------------------
  crossover_raw <- NA_real_

  if (!is.na(m) && m > 0 && m < 1) {
    crossover_raw <- b / (1 - m)
  }

  # back-transform to business days
  crossover_days <- if (!is.na(crossover_raw) && log_transform) {
    exp(crossover_raw)
  } else {
    crossover_raw
  }

  # ---- build plain-language sentence ------------------------------------------
  sentence <- .wt_crossover_sentence(crossover_days, m, group1, group2)

  # ---- assemble result --------------------------------------------------------
  result <- list(
    crossover_days = crossover_days,
    slope          = m,
    intercept      = b,
    r_squared      = r_sq,
    n_pairs        = n_pairs,
    group1         = group1,
    group2         = group2,
    conf_level     = conf_level,
    log_transform  = log_transform,
    plot_data      = plot_data,
    model          = fit,
    sentence       = sentence
  )
  class(result) <- "mysterycall_wait_time_crossover"
  result
}


# ---- internal helper ---------------------------------------------------------

#' @keywords internal
#' @noRd
.wt_crossover_sentence <- function(crossover_days, m, group1, group2) {
  if (!is.na(crossover_days) && crossover_days > 0) {
    sprintf(
      paste0(
        "At approximately %.0f business days, wait times were equal for %s ",
        "and %s patients. Beyond this point, %s patients experienced longer waits."
      ),
      crossover_days, group1, group2, group1
    )
  } else if (!is.na(m) && m >= 1) {
    sprintf(
      paste0(
        "No equalization point exists between %s and %s: the regression slope ",
        "(%.3f) is >= 1, indicating %s wait times diverge from %s without ",
        "intersection. crossover_days is NA."
      ),
      group1, group2, m, group2, group1
    )
  } else if (!is.na(m) && m <= 0) {
    sprintf(
      paste0(
        "No equalization point exists between %s and %s: the regression slope ",
        "(%.3f) is <= 0, indicating no consistent directional relationship. ",
        "crossover_days is NA."
      ),
      group1, group2, m
    )
  } else {
    sprintf(
      paste0(
        "The crossover point could not be determined for %s vs. %s. ",
        "crossover_days is NA."
      ),
      group1, group2
    )
  }
}


#' Print a mysterycall_wait_time_crossover result
#'
#' Displays the plain-language sentence, key regression statistics, and the
#' full \code{summary(lm)} output.
#'
#' @param x A \code{mysterycall_wait_time_crossover} object.
#' @param digits Integer.  Decimal places for slope, intercept, and crossover
#'   point display.  Default \code{2}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @family outcomes
#' @export
print.mysterycall_wait_time_crossover <- function(x, digits = 2, ...) {
  cat("-- mysterycall_wait_time_crossover --\n\n")
  cat(x$sentence, "\n\n")
  cat(sprintf(
    "Groups : %s (x-axis, group1) vs. %s (y-axis, group2)\n",
    x$group1, x$group2
  ))
  cat(sprintf("Pairs  : %d physicians with data in both groups\n", x$n_pairs))
  cat(sprintf(
    "Scale  : %s\n",
    if (x$log_transform) "log (regression on log scale; crossover back-transformed)" else "original"
  ))
  cat("\n")

  if (!is.na(x$crossover_days)) {
    cat(sprintf(
      "Crossover point : %s business days\n",
      round(x$crossover_days, digits)
    ))
  } else {
    cat("Crossover point : NA (slope outside (0, 1); see sentence above)\n")
  }

  cat(sprintf(
    "Slope (m)       : %s\n", round(x$slope,     digits)
  ))
  cat(sprintf(
    "Intercept (b)   : %s\n", round(x$intercept, digits)
  ))
  cat(sprintf(
    "R-squared       : %.3f\n", x$r_squared
  ))
  cat("\nRegression summary:\n")
  print(summary(x$model))
  invisible(x)
}
