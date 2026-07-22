#' Canonical overdispersion threshold for Poisson-vs-negative-binomial choice
#'
#' Every function in the package that reduces a Pearson dispersion statistic
#' (phi = sum(pearson_resid^2) / resid_df) to a "keep Poisson vs switch to
#' negative binomial" decision routes through this single value, so the model
#' choice can never again diverge between the automated selector and the
#' standalone diagnostics. When phi exceeds the threshold, a negative-binomial
#' (or otherwise overdispersion-robust) model is recommended.
#'
#' The default is `1.5`, a common overdispersion rule of thumb. Override it
#' globally with `options(mysterycall.overdispersion_threshold = <value>)`;
#' every consumer (`mysterycall_auto_model()`, `mysterycall_poisson_model()`,
#' `mysterycall_simple_poisson()`, `mysterycall_overdispersion_test()`,
#' `mysterycall_overdispersion_sentence()`, `mysterycall_marginal_power()`)
#' picks up the new value through its default argument.
#'
#' @return A single positive number: the current overdispersion threshold.
#' @family model selection
#' @seealso [mysterycall_auto_model()], [mysterycall_overdispersion_test()]
#' @export
#' @examples
#' mysterycall_overdispersion_threshold()
#' withr::with_options(
#'   list(mysterycall.overdispersion_threshold = 2.0),
#'   mysterycall_overdispersion_threshold()
#' )
mysterycall_overdispersion_threshold <- function() {
  x <- getOption("mysterycall.overdispersion_threshold", 1.5)
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0) {
    stop("option 'mysterycall.overdispersion_threshold' must be a single positive number.",
         call. = FALSE)
  }
  x
}
