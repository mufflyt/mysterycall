#' Simulated-patient (CRiSP-style) reporting checklist
#'
#' Mystery-caller / secret-shopper studies are a form of *simulated-patient*
#' research, and reviewers increasingly expect the covert-methodology reporting
#' items that a generic STROBE checklist does not cover: why the covert method
#' was justified, how callers were recruited and standardized, how scenario
#' fidelity was monitored, how (and whether) practices could detect the call, and
#' how the deception was handled ethically. This returns a fillable checklist
#' organized around the domains of the CRiSP framework (Checklist for Reporting
#' Research using Simulated-Patient methodology), as a companion to
#' [mysterycall_strobe_checklist()].
#'
#' It is a scaffold, not a substitute for the source instrument: the `reported`
#' column is yours to complete (a page/section reference or `"n/a"`), and item
#' wording should be confirmed against the current published checklist for a
#' formal submission.
#'
#' @param reported Optional character vector, one entry per checklist item, used
#'   to pre-fill the `reported` column (e.g. page numbers). Length must equal the
#'   number of items (see `nrow()` of a default call). Default `NA`.
#'
#' @return An object of class `"mysterycall_crisp_checklist"`: a data frame with
#'   columns `section`, `item`, `recommendation`, `reported`.
#'   [as.data.frame()] returns it plainly.
#'
#' @seealso [mysterycall_strobe_checklist()]
#' @examples
#' cl <- mysterycall_crisp_checklist()
#' head(cl)
#' nrow(cl)
#' @export
mysterycall_crisp_checklist <- function(reported = NA) {
  items <- rbind(
    c("Rationale", "Justification of covert method",
      "State why a simulated-patient/mystery-caller design was necessary rather than a survey or overt audit."),
    c("Rationale", "Construct measured",
      "Define the access construct(s) audited (e.g. new-patient acceptance, wait time) and why they matter."),
    c("Scenario", "Scenario development",
      "Describe how the caller scenario(s) were developed, piloted, and validated for clinical plausibility."),
    c("Scenario", "Scenario standardization",
      "Report the script and the fields deliberately varied (e.g. insurance) vs. held constant across calls."),
    c("Callers", "Caller recruitment and characteristics",
      "Describe who placed the calls, their number, background, and any relevant characteristics."),
    c("Callers", "Caller training",
      "Report how callers were trained to deliver the scenario consistently and to record outcomes."),
    c("Callers", "Standardization monitoring",
      "Report checks on caller adherence/standardization during data collection (e.g. call review, drift checks)."),
    c("Detection", "Detection and contamination",
      "State whether practices could detect the call, any suspected detections, and repeat-practice contamination controls."),
    c("Sampling", "Sampling frame",
      "Describe the target population, sampling frame, sample selection, and the number of practices/physicians."),
    c("Sampling", "Call protocol",
      "Report the calling window, call attempts/callbacks, timing, and rules for a completed call."),
    c("Measurement", "Outcome ascertainment",
      "Define each outcome operationally and how it was recorded at the time of the call."),
    c("Measurement", "Data quality",
      "Report data-entry verification, handling of incomplete/ambiguous calls, and reconciliation of discordant fields."),
    c("Analysis", "Statistical methods",
      "Describe the models, clustering (e.g. by practice), covariates, and handling of missing data."),
    c("Analysis", "Sensitivity analyses",
      "Report pre-specified sensitivity/robustness analyses and any subgroup analyses."),
    c("Ethics", "Ethical approval and deception",
      "Report IRB/ethics approval, the justification for waiving consent/deception, and steps to minimize harm."),
    c("Ethics", "Provider burden",
      "Describe steps taken to limit the burden imposed on practices (e.g. call length, non-booking)."),
    c("Results", "Participation flow",
      "Report the flow from sampled to reached to analyzed practices, with reasons for exclusion."),
    c("Results", "Outcome estimates",
      "Report the primary and secondary outcome estimates with measures of precision."),
    c("Discussion", "Limitations of the covert method",
      "Discuss limitations specific to simulated-patient methodology (single contact, detection, generalizability)."),
    c("Discussion", "Generalizability",
      "Discuss the external validity of the findings to the target population and settings.")
  )
  out <- data.frame(
    section = items[, 1], item = items[, 2], recommendation = items[, 3],
    reported = NA_character_, stringsAsFactors = FALSE
  )
  if (!(length(reported) == 1L && is.na(reported))) {
    if (length(reported) != nrow(out)) {
      stop(sprintf("`reported` must have %d entries (one per checklist item), not %d.",
                   nrow(out), length(reported)), call. = FALSE)
    }
    out$reported <- as.character(reported)
  }
  structure(out, class = c("mysterycall_crisp_checklist", "data.frame"))
}

#' @export
print.mysterycall_crisp_checklist <- function(x, ...) {
  cat(sprintf("<CRiSP-style simulated-patient reporting checklist: %d items, %d sections>\n",
              nrow(x), length(unique(x$section))))
  print(as.data.frame(x), row.names = FALSE, ...)
  invisible(x)
}
