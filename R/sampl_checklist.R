#' SAMPL statistical-reporting checklist
#'
#' STROBE says what to report about an observational study's design; SAMPL
#' (Statistical Analyses and Methods in the Published Literature) says how to
#' report the numbers themselves: give an effect size with a confidence
#' interval rather than a bare p-value, name the test and why it fits, give the
#' denominator behind every percentage, and state the precision the data
#' actually support. This returns a fillable checklist of the SAMPL items that
#' bear on a mystery-caller audit -- proportions, rate ratios, wait times,
#' clustered calls -- as a companion to [mysterycall_strobe_checklist()] and
#' [mysterycall_crisp_checklist()].
#'
#' The point of citing it in a manuscript is usually defensive: reporting
#' `"OR 0.31, 95% CI 0.05 to 1.9"` instead of `"p = .21"` is a deliberate
#' choice backed by a published guideline, not a way to dodge a null result.
#'
#' It is a scaffold, not a substitute for the source guideline: the `reported`
#' column is yours to complete (a page/section reference or `"n/a"`), and item
#' wording should be confirmed against the published guidelines for a formal
#' submission.
#'
#' @param reported Optional character vector, one entry per checklist item, used
#'   to pre-fill the `reported` column (e.g. page numbers). Length must equal the
#'   number of items (see `nrow()` of a default call). Default `NA`.
#'
#' @return An object of class `"mysterycall_sampl_checklist"`: a data frame with
#'   columns `section`, `item`, `recommendation`, `reported`.
#'   [as.data.frame()] returns it plainly.
#'
#' @references
#' Lang TA, Altman DG. Basic statistical reporting for articles published in
#' biomedical journals: the "Statistical Analyses and Methods in the Published
#' Literature" or the SAMPL Guidelines. *International Journal of Nursing
#' Studies*. 2015;52(1):5-9. \doi{10.1016/j.ijnurstu.2014.09.006}
#'
#' @family manuscript
#' @seealso [mysterycall_strobe_checklist()] for the design-reporting items and
#'   [mysterycall_crisp_checklist()] for the simulated-patient items.
#' @examples
#' cl <- mysterycall_sampl_checklist()
#' head(cl)
#' nrow(cl)
#' @export
mysterycall_sampl_checklist <- function(reported = NA) {
  items <- rbind(
    c("General", "Methods reproducible from the description",
      "Describe the statistical methods in enough detail that a knowledgeable reader with the data could verify the reported results."),
    c("General", "Numerical precision",
      "Report numbers to the precision the data support: two significant digits for most effect sizes, and no more decimal places than the measurement justifies."),
    c("General", "Denominators for every percentage",
      "Give the numerator and denominator behind each percentage, and report counts alone rather than percentages for groups of fewer than about 20."),
    c("General", "Intervals and ranges written with 'to'",
      "Separate the endpoints of confidence intervals and ranges with 'to' rather than a hyphen, so that negative endpoints stay unambiguous."),
    c("General", "P values reported as exact values",
      "Report p values as exact values to two or three decimal places rather than as inequalities against alpha; reserve '< 0.001' for values below that, and never report 'NS'."),
    c("General", "Effect size, not just a p value",
      "Report an effect size with a confidence interval for every primary comparison; a p value on its own is not a result and does not measure the size of an effect."),
    c("Data", "Number of observations analyzed",
      "Report the number of calls, physicians, and practices contributing to each analysis and how that differs from the number sampled."),
    c("Data", "Missing data",
      "State how much data were missing, why, and how missing values were handled (complete case, imputation) in each analysis."),
    c("Data", "Transformations, recoding, and outliers",
      "Report any transformation, category collapsing, or recoding, and how outliers were identified and handled, stating what was pre-specified."),
    c("Summary statistics", "Summary matched to the distribution",
      "Use mean (SD) for approximately symmetric data and median (25th to 75th percentile) for skewed data such as wait times, and say which is reported."),
    c("Summary statistics", "SD distinguished from SEM",
      "Report the standard deviation when describing the variability of the data, label it explicitly, and do not substitute the standard error of the mean."),
    c("Summary statistics", "Basis for distributional claims",
      "State how the distributional assumption behind each summary measure or test was assessed."),
    c("Risk and rates", "Type of ratio identified",
      "State whether an odds ratio, risk ratio, rate ratio, or incidence rate ratio is reported, and name the reference group."),
    c("Risk and rates", "Absolute measures alongside relative ones",
      "Report the underlying absolute rates or risks, with their numerators and denominators, next to every ratio measure."),
    c("Risk and rates", "Denominator time or exposure",
      "For rates, state the denominator of exposure (calls per physician, business days at risk) and any offset used to model it."),
    c("Hypothesis tests", "Each test named and justified",
      "Name every statistical test, state what it was applied to, and say why it suits the data at hand."),
    c("Hypothesis tests", "Alpha level and tails",
      "State the alpha level used to define statistical significance and whether tests were one- or two-tailed."),
    c("Hypothesis tests", "Assumptions verified",
      "Report how the assumptions of each test were checked (independence, distribution, expected cell counts, equality of variances)."),
    c("Hypothesis tests", "Unit of analysis and clustering",
      "State the unit of analysis and how repeated calls to the same physician or practice were accounted for."),
    c("Hypothesis tests", "Multiplicity",
      "State how many comparisons were made and whether p values or intervals were adjusted; label unadjusted secondary comparisons as exploratory."),
    c("Regression", "Primary, secondary, and post hoc analyses distinguished",
      "Separate pre-specified primary analyses from secondary and post hoc ones, and say which were decided after seeing the data."),
    c("Regression", "Model specification",
      "Report the model family and link function, the candidate variables considered, the variable-selection procedure, and the final model."),
    c("Regression", "Coefficients with confidence intervals",
      "Report each regression coefficient, or its exponentiated form, with a confidence interval rather than a p value alone."),
    c("Regression", "Model checking",
      "Report goodness of fit, overdispersion, collinearity, and influential-observation diagnostics for the final model."),
    c("Regression", "Correlation reported with n and an interval",
      "Name the correlation coefficient used and report it with the sample size and a confidence interval."),
    c("Time-to-event", "Censoring and numbers at risk",
      "For time-to-appointment analyses, state how never-scheduled and right-censored calls were handled and report the numbers at risk."),
    c("Software", "Software, versions, and analyst",
      "Name the statistical software and version, the key packages and their versions, and who performed the analysis.")
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
  structure(out, class = c("mysterycall_sampl_checklist", "data.frame"))
}

#' Print a `mysterycall_sampl_checklist` object
#'
#' @param x A `mysterycall_sampl_checklist` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return `x`, invisibly.
#' @family manuscript
#' @export
print.mysterycall_sampl_checklist <- function(x, ...) {
  cat(sprintf("<SAMPL statistical-reporting checklist: %d items, %d sections>\n",
              nrow(x), length(unique(x$section))))
  print(as.data.frame(x), row.names = FALSE, ...)
  invisible(x)
}
