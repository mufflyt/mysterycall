#' Check Normality and Summarize Data
#'
#' Checks the normality of a variable using the Shapiro-Wilk test, returns
#' summary statistics, and--crucially--generates a manuscript-ready
#' `$interpretation` sentence that identifies count data and recommends
#' Poisson regression when appropriate.
#'
#' @param data A dataframe containing the data.
#' @param variable A string specifying the column name of the variable to be
#'   checked and summarized.
#' @param outcome_label Optional character scalar. Human-readable label for the
#'   outcome used in the interpretation sentence (e.g.,
#'   `"days until appointment"`). Defaults to `variable`.
#' @param group_label Optional character scalar. Human-readable label for the
#'   grouping variable used in the interpretation sentence (e.g.,
#'   `"insurance type"`). Defaults to `"the grouping variable"`.
#'
#' @return A named list containing:
#'   \describe{
#'     \item{`is_normal`}{Logical. `TRUE` if Shapiro-Wilk p > 0.05.}
#'     \item{`p_value`}{Numeric. Shapiro-Wilk p-value.}
#'     \item{`w_statistic`}{Numeric. Shapiro-Wilk W statistic.}
#'     \item{`is_count`}{Logical. `TRUE` if all non-missing values are
#'       non-negative integers -- heuristic for count outcomes.}
#'     \item{`mean`, `sd`}{Numeric scalars (present when `is_normal = TRUE`).}
#'     \item{`median`, `iqr`}{Numeric scalars (present when `is_normal = FALSE`).}
#'     \item{`interpretation`}{Character scalar. A single manuscript-ready
#'       paragraph describing the distribution and, for non-normal count data,
#'       recommending Poisson regression over t-test or Kruskal-Wallis.}
#'   }
#'   Side effects: emits a histogram + density plot and a Q-Q plot.
#'
#' @section Interpretation sentence:
#' When the data are **not normally distributed** and **consist of counts**
#' (non-negative integers), the returned sentence reads:
#'
#' *"The data is not normally distributed (Shapiro-Wilk W = X, p = Y). Plus it
#' is count data. t-test assumes that data is normally distributed, and
#' comparing the means of count data is also not appropriate. We can check the
#' incidence rate ratio (IRR) for comparison of outcome among the categories
#' of the grouping variable. Better to use Poisson regression."*
#'
#' @seealso [mysterycall_simple_poisson()] for the Poisson model this function
#'   recommends; [mysterycall_prepare_table1_vars()] for downstream variable
#'   standardization.
#' @family modeling helpers
#' @export
#' @importFrom rlang sym
#' @importFrom stats shapiro.test IQR median sd qnorm
#'
#' @examples
#' sample_data <- data.frame(
#'   business_days_until_appointment = c(1L, 3L, 2L, 5L, 0L, 4L, 7L, 2L, 1L, 14L)
#' )
#' result <- mysterycall_check_normality(
#'   sample_data, "business_days_until_appointment",
#'   outcome_label = "days until appointment",
#'   group_label   = "insurance type"
#' )
#' cat(result$interpretation)
mysterycall_check_normality <- function(data, variable,
                                        outcome_label = NULL,
                                        group_label   = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop(
      "This function requires the ggplot2 package.\n",
      "Install it with: install.packages(\"ggplot2\")",
      call. = FALSE
    )
  }

  if (!variable %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.\nAvailable columns: %s",
                 variable, paste(names(data), collapse = ", ")), call. = FALSE)
  }

  outcome_label <- outcome_label %||% variable
  group_label   <- group_label   %||% "the grouping variable"

  data_var <- stats::na.omit(data[[variable]])
  n_neg <- sum(data_var < 0)
  if (n_neg > 0L)
    warning(sprintf(
      "%d negative value%s found in '%s' (min = %g). Negative wait days are impossible -- check for date calculation errors before modelling.",
      n_neg, if (n_neg == 1L) "" else "s", variable, min(data_var)
    ), call. = FALSE)
  n_long <- sum(data_var > 365)
  if (n_long > 0L)
    warning(sprintf(
      "%d value%s in '%s' exceed 365 days (max = %g). Wait times over one year are likely a year-typo error (e.g. 2027 instead of 2026) -- verify appointment dates.",
      n_long, if (n_long == 1L) "" else "s", variable, max(data_var)
    ), call. = FALSE)
  message("Normality check for '", variable, "': n = ", length(data_var))

  if (length(data_var) < 3L)
    stop("Sample size must be at least 3 for the Shapiro-Wilk test.", call. = FALSE)
  if (length(data_var) > 5000L)
    stop("Sample size must be no more than 5000 for the Shapiro-Wilk test.", call. = FALSE)

  # -- Shapiro-Wilk -------------------------------------------------------------
  normality_test <- stats::shapiro.test(data_var)
  p_value    <- normality_test$p.value
  w_statistic <- normality_test$statistic

  is_normal <- p_value > 0.05

  # -- Count-data heuristic -----------------------------------------------------
  # All observed values are non-negative whole numbers -> treat as count outcome
  is_count <- all(data_var == floor(data_var)) && min(data_var, na.rm = TRUE) >= 0

  # -- Plots --------------------------------------------------------------------
  clean_data <- data[!is.na(data[[variable]]), , drop = FALSE]

  hist_plot <- ggplot2::ggplot(clean_data, ggplot2::aes(x = !!rlang::sym(variable))) +
    ggplot2::geom_histogram(ggplot2::aes(y = ggplot2::after_stat(density)),
                            binwidth = 0.5, fill = "lightblue", color = "black", na.rm = TRUE) +
    ggplot2::geom_density(alpha = 0.2, fill = "#FF6666", na.rm = TRUE) +
    ggplot2::labs(title = paste("Histogram and Density Plot of", variable),
                  x = variable, y = "Density")

  qq_plot <- ggplot2::ggplot(clean_data, ggplot2::aes(sample = !!rlang::sym(variable))) +
    ggplot2::stat_qq(na.rm = TRUE) +
    ggplot2::stat_qq_line(na.rm = TRUE) +
    ggplot2::labs(title = paste("Q-Q Plot of", variable))

  invisible(hist_plot)
  invisible(qq_plot)

  # -- Summary statistics -------------------------------------------------------
  w_fmt <- sprintf("%.3f", w_statistic)
  p_fmt <- if (p_value < 0.001) "< 0.001" else sprintf("%.3f", p_value)

  if (is_normal) {
    mean_val <- mean(data_var, na.rm = TRUE)
    sd_val   <- stats::sd(data_var, na.rm = TRUE)
    summary_stats <- list(
      is_normal   = TRUE,
      p_value     = p_value,
      w_statistic = w_statistic,
      is_count    = is_count,
      mean        = mean_val,
      sd          = sd_val
    )
    interpretation <- sprintf(
      paste0(
        "The data is approximately normally distributed ",
        "(Shapiro-Wilk W = %s, p = %s). ",
        "Mean %s: %.2f (SD: %.2f)."
      ),
      w_fmt, p_fmt, outcome_label, mean_val, sd_val
    )
    message("Approximately normal. Mean = ", round(mean_val, 2),
            ", SD = ", round(sd_val, 2))
  } else {
    median_val <- stats::median(data_var, na.rm = TRUE)
    iqr_val    <- stats::IQR(data_var, na.rm = TRUE)
    summary_stats <- list(
      is_normal   = FALSE,
      p_value     = p_value,
      w_statistic = w_statistic,
      is_count    = is_count,
      median      = median_val,
      iqr         = iqr_val
    )

    if (is_count) {
      interpretation <- sprintf(
        paste0(
          "The data is not normally distributed ",
          "(Shapiro-Wilk W = %s, p = %s). ",
          "Plus it is count data. ",
          "t-test assumes that data is normally distributed, and comparing the ",
          "means of count data is also not appropriate. ",
          "We can check the incidence rate ratio (IRR) for comparison of %s ",
          "among the categories of %s. ",
          "Better to use Poisson regression. ",
          "Median %s: %.1f (IQR: %.1f)."
        ),
        w_fmt, p_fmt,
        outcome_label, group_label,
        outcome_label, median_val, iqr_val
      )
    } else {
      interpretation <- sprintf(
        paste0(
          "The data is not normally distributed ",
          "(Shapiro-Wilk W = %s, p = %s). ",
          "Non-parametric measures are more appropriate. ",
          "Median %s: %.1f (IQR: %.1f)."
        ),
        w_fmt, p_fmt, outcome_label, median_val, iqr_val
      )
    }
    message("Not normally distributed. Median = ", median_val,
            ", IQR = ", iqr_val,
            if (is_count) " [count data -- Poisson recommended]" else "")
  }

  summary_stats$interpretation <- interpretation
  message(interpretation)
  return(summary_stats)
}
