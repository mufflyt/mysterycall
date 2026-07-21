#' Bin a wait-time-to-appointment into weekly categories and a threshold flag
#'
#' Audit results are usually reported two ways: an ordered set of weekly bins
#' (how the wait distribution is shaped) and a single clinically-meaningful
#' binary threshold -- classically "more than a two-week wait", the headline
#' access outcome. This standardizes both from a numeric days-to-appointment
#' vector so the ">N-week" convention is defined once instead of re-derived with
#' a fresh [cut()] in every analysis.
#'
#' @param x Numeric vector of business days (or calendar days) until the
#'   appointment.
#' @param threshold_days Numeric. The binary cutoff; `over_threshold` is `TRUE`
#'   when `x > threshold_days`. Default `14` (a two-week wait).
#' @param bin_width Numeric. Width of each ordered bin in days. Default `7`
#'   (weekly).
#' @param max_bin Numeric. The last finite bin edge; values above it fall in a
#'   single top `"> max_bin"` bin. Default `28`.
#'
#' @return A [tibble::tibble()] the length of `x` with columns `days` (the
#'   input), `bin` (an ordered factor of weekly categories), and
#'   `over_threshold` (logical). `NA` days give `NA` in both derived columns.
#'
#' @family data integrity
#' @seealso [mysterycall_wait_time_summary()], [mysterycall_business_days()]
#' @examples
#' mysterycall_categorize_wait(c(3, 10, 15, 30, NA))
#' @export
mysterycall_categorize_wait <- function(x, threshold_days = 14,
                                       bin_width = 7, max_bin = 28) {
  checkmate::assert_numeric(x)
  checkmate::assert_number(threshold_days, lower = 0)
  checkmate::assert_number(bin_width, lower = 1)
  checkmate::assert_number(max_bin, lower = bin_width)

  edges  <- seq(bin_width, max_bin, by = bin_width)
  breaks <- c(-Inf, edges, Inf)
  labels <- c(
    paste0(c(0, utils::head(edges, -1) + 1), "-", edges),
    paste0("> ", max_bin)
  )
  bin <- cut(x, breaks = breaks, labels = labels, right = TRUE,
             ordered_result = TRUE)

  tibble::tibble(
    days           = x,
    bin            = bin,
    over_threshold = x > threshold_days
  )
}
