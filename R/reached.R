#' Canonical "reached but declined" call-outcome labels
#'
#' A mystery call is *reached* when the office was actually connected to, even
#' if no appointment was offered. Three outcomes are reached-but-declined: the
#' office is not accepting new patients, a referral is required before
#' scheduling, or the caller was left on hold for more than five minutes. These
#' are genuine connections that did not yield an appointment, so they belong in
#' an acceptance-rate **denominator** (the office was reached and said no) even
#' though they are not in the numerator.
#'
#' This function returns that canonical vocabulary so
#' [mysterycall_acceptance_rate_calc()] and
#' [mysterycall_insurance_acceptance_rates()] keep reached-but-declined offices
#' in the denominator, consistent with [mysterycall_exclusion_summary()], which
#' also classifies these three as reached. The strings match
#' [mysterycall_exclusion_summary()]'s default `exclusion_categories` for the
#' `not_accepting`, `referral_required`, and `on_hold` groups.
#'
#' @return A character vector of the three reached-but-declined label strings.
#' @seealso [mysterycall_acceptance_rate_calc()], [mysterycall_exclusion_summary()]
#' @family utilities
#' @export
#' @examples
#' mysterycall_reached_declined_reasons()
mysterycall_reached_declined_reasons <- function() {
  c(
    "Not accepting new patients",
    "Physician referral required before scheduling appointment",
    "Greater than 5 minutes on hold"
  )
}
