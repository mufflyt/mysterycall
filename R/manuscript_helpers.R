#' Helpers for writing manuscript methods and results sections
#'
#' @name manuscript_helpers
NULL

#' Generate a sample-size methods sentence
#'
#' Calls [mysterycall_cochran_n()] and returns a ready-to-paste sentence for
#' the methods section of a mystery-caller manuscript.
#'
#' @param N Integer. Total population size.
#' @param margin_of_error Numeric in `(0, 1)`. Desired margin of error.
#'   Default `0.05` (+/-5%).
#'
#' @return A single character string ready to paste into a manuscript methods
#'   section describing the required sample size.
#'
#' @seealso [mysterycall_cochran_n()] for the underlying sample-size formula;
#'   [mysterycall_methods_paragraph()] to generate the full methods paragraph.
#' @family manuscript
#' @export
#'
#' @examples
#' mysterycall_sample_size_text(369)
mysterycall_sample_size_text <- function(N, margin_of_error = 0.05) {
  res <- mysterycall_cochran_n(N, margin_of_error)
  sprintf(
    paste0(
      "Using the Cochran formula for finite populations (N = %s, ",
      "margin of error = %.0f%%), a minimum sample size of ",
      "%s participants is required."
    ),
    format(res$N, big.mark = ","),
    res$margin_of_error * 100,
    format(res$n, big.mark = ",")
  )
}


#' One-line demographic summary for a study cohort
#'
#' Builds a compact summary string of the form
#' `"N = X; Y% female; Z% academic"` from a data frame. Any component whose
#' source column is omitted is silently excluded.
#'
#' @param data A data frame.
#' @param female_col Character scalar naming a column that encodes sex/gender.
#'   Recognized values (case-insensitive): `"female"`, `"f"` for female;
#'   `"male"`, `"m"` for male. Logical columns (`TRUE` = female) are also
#'   accepted.
#' @param setting_col Character scalar naming the practice-setting column.
#' @param academic_label Character scalar for the academic label used in
#'   `setting_col`. Default `"Academic"`.
#'
#' @return A single character string describing the physician cohort demographics
#'   (sex distribution, mean age, practice-setting breakdown).
#'
#' @seealso [mysterycall_methods_paragraph()] for the full methods section;
#'   [mysterycall_write_results_paragraph()] for the results section.
#' @family manuscript
#' @export
#'
#' @examples
#' df <- data.frame(
#'   gender  = c("Female", "Male", "Female", NA),
#'   setting = c("Academic", "Private Practice", "Academic", "Academic")
#' )
#' mysterycall_summarize_demographics(df, female_col = "gender",
#'                                    setting_col = "setting")
mysterycall_summarize_demographics <- function(data,
                                               female_col      = NULL,
                                               setting_col     = NULL,
                                               academic_label  = "Academic") {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)

  N <- nrow(data)

  pct_female <- if (!is.null(female_col) && female_col %in% names(data)) {
    vals <- data[[female_col]]
    if (is.logical(vals)) {
      mean(vals, na.rm = TRUE) * 100
    } else {
      mean(tolower(as.character(vals)) %in% c("female", "f"), na.rm = TRUE) * 100
    }
  } else {
    if (!is.null(female_col)) {
      warning(sprintf("Column '%s' not found in `data`; %% female set to NA.",
                      female_col), call. = FALSE)
    }
    NA_real_
  }

  pct_academic <- if (!is.null(setting_col) && setting_col %in% names(data)) {
    mean(data[[setting_col]] == academic_label, na.rm = TRUE) * 100
  } else {
    if (!is.null(setting_col)) {
      warning(sprintf("Column '%s' not found in `data`; %% academic set to NA.",
                      setting_col), call. = FALSE)
    }
    NA_real_
  }

  out <- paste0("N = ", format(N, big.mark = ","))
  if (!is.na(pct_female))   out <- paste0(out, "; ", sprintf("%.1f%%", pct_female), " female")
  if (!is.na(pct_academic)) out <- paste0(out, "; ", sprintf("%.1f%%", pct_academic), " academic")
  out
}


#' Generate a boilerplate methods paragraph for a mystery-caller study
#'
#' Fills a standard methods template describing the mystery-caller audit
#' methodology, sample size, geographic scope, insurance types tested, outcome
#' measure, and analysis software.
#'
#' @param n_physicians Integer. Total number of physicians contacted.
#' @param n_cities Integer. Number of cities/states covered.
#' @param specialties Character vector of medical specialties included.
#' @param insurance_types Character vector of insurance types tested.
#'   Default `c("Medicaid", "commercial insurance")`.
#' @param outcome Character scalar describing the primary outcome.
#'   Default `"business days until a new-patient appointment"`.
#' @param software Character scalar naming the analysis software.
#'   Default `"R (R Foundation for Statistical Computing)"`.
#' @param model_family One of `"poisson"` (default), `"negative_binomial"`, or
#'   `"auto"`. Controls the statistical-model sentence appended after the
#'   software statement. Alternatively, pass a fitted `mysterycall_poisson_model`
#'   or `mysterycall_nb_model` object and the family is detected automatically.
#'
#' @return A single character string containing a ready-to-paste methods
#'   paragraph describing the mystery-caller study design.
#'
#' @seealso [mysterycall_sample_size_text()] for the sample-size sentence;
#'   [mysterycall_summarize_demographics()] for the demographics summary;
#'   [mysterycall_write_results_paragraph()] for the results section.
#' @family manuscript
#' @export
#'
#' @examples
#' mysterycall_methods_paragraph(
#'   n_physicians  = 369,
#'   n_cities      = 10,
#'   specialties   = c("otolaryngology", "neurotology"),
#'   insurance_types = c("Medicaid", "Blue Cross Blue Shield")
#' )
#'
#' mysterycall_methods_paragraph(
#'   n_physicians    = 216,
#'   n_cities        = 12,
#'   specialties     = "otolaryngology",
#'   model_family    = "negative_binomial"
#' )
mysterycall_methods_paragraph <- function(n_physicians,
                                          n_cities,
                                          specialties,
                                          insurance_types = c("Medicaid", "commercial insurance"),
                                          outcome         = "business days until a new-patient appointment",
                                          software        = "R (R Foundation for Statistical Computing)",
                                          model_family    = c("poisson", "negative_binomial", "auto")) {
  if (!is.numeric(n_physicians) || n_physicians < 1)
    stop("`n_physicians` must be a positive number.", call. = FALSE)
  if (!is.numeric(n_cities) || n_cities < 1)
    stop("`n_cities` must be a positive number.", call. = FALSE)
  if (!is.character(specialties) || length(specialties) == 0L)
    stop("`specialties` must be a non-empty character vector.", call. = FALSE)

  if (inherits(model_family, "mysterycall_nb_model"))      model_family <- "negative_binomial"
  if (inherits(model_family, "mysterycall_poisson_model")) model_family <- "poisson"
  model_family <- match.arg(model_family)

  spec_str <- if (length(specialties) == 1L) {
    specialties
  } else {
    paste(paste(specialties[-length(specialties)], collapse = ", "),
          "and", specialties[[length(specialties)]])
  }
  ins_str <- paste(insurance_types, collapse = " and ")

  model_sentence <- switch(
    model_family,
    poisson = paste0(
      "A multilevel Poisson regression model with physician random intercepts was fit ",
      "using the lme4 package to estimate incidence rate ratios (IRR) for the primary outcomes."
    ),
    negative_binomial = paste0(
      "A multilevel negative binomial regression model with physician random intercepts was fit ",
      "using the glmmTMB package to account for overdispersion in appointment wait times ",
      "and estimate incidence rate ratios (IRR)."
    ),
    auto = paste0(
      "Multilevel Poisson regression was used as the primary model; ",
      sprintf(
        "if overdispersion was detected (Pearson phi > %s), a negative binomial model was ",
        format(mysterycall_overdispersion_threshold())
      ),
      "substituted and reported instead."
    )
  )

  sprintf(
    paste0(
      "A mystery-caller audit methodology was employed. ",
      "A total of %s physicians representing %s were identified from publicly available ",
      "directories across %s cities and states in the United States. ",
      "Mystery callers posed as new patients insured with %s and contacted each physician's ",
      "office to request the earliest available new-patient appointment. ",
      "Calls were standardized and completed within one week of each other. ",
      "The primary outcome was %s. ",
      "All analyses were performed using %s. ",
      "%s"
    ),
    format(as.integer(n_physicians), big.mark = ","),
    spec_str,
    format(as.integer(n_cities), big.mark = ","),
    ins_str,
    outcome,
    software,
    model_sentence
  )
}


#' Format an IRR table for manuscript display
#'
#' Rounds incidence rate ratios and confidence intervals, combines CI into a
#' single `"lower-upper"` column (en-dash separator), and formats p-values.
#' Optionally excludes the intercept row.
#'
#' @param x A `mysterycall_poisson_model` result or a data frame with at
#'   least columns `term`, `irr`, `ci_lower`, `ci_upper`, `p_value`.
#' @param digits Integer. Decimal places for IRR and CI columns. Default `2L`.
#' @param include_intercept Logical. Whether to include the `(Intercept)` row.
#'   Default `FALSE`.
#'
#' @return A data frame with columns `Term`, `IRR`, `95% CI`, `p-value`.
#'   The data frame carries an integer attribute `"significant_rows"` with
#'   the row indices where `p_value < 0.05`, allowing downstream formatters
#'   to apply bold styling.  Intercept row is excluded by default.
#'
#' @seealso [mysterycall_poisson_model()] and [mysterycall_nb_model()] which
#'   produce the model input; [mysterycall_write_results_paragraph()] to
#'   generate a prose summary.
#' @family manuscript
#' @export
#'
#' @examplesIf interactive()
#' tbl <- mysterycall_format_results_table(model_result)
#' knitr::kable(tbl)
mysterycall_format_results_table <- function(x,
                                              digits            = 2L,
                                              include_intercept = FALSE) {
  if (inherits(x, c("mysterycall_poisson_model", "mysterycall_nb_model"))) x <- x$irr_table
  if (!is.data.frame(x))
    stop("`x` must be a data frame, `mysterycall_poisson_model`, or `mysterycall_nb_model`.", call. = FALSE)
  need <- c("term", "irr", "ci_lower", "ci_upper", "p_value")
  missing_cols <- setdiff(need, names(x))
  if (length(missing_cols) > 0L)
    stop("Missing columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)

  if (!include_intercept) x <- x[x$term != "(Intercept)", , drop = FALSE]

  fmt <- paste0("%.", as.integer(digits), "f")
  out <- data.frame(
    Term      = x$term,
    IRR       = sprintf(fmt, x$irr),
    `95% CI`  = sprintf(paste0(fmt, " to ", fmt), x$ci_lower, x$ci_upper),
    `p-value` = mysterycall_format_p(x$p_value),
    sig       = !is.na(x$p_value) & x$p_value < 0.05,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  attr(out, "significant_rows") <- which(out$sig)
  out$sig <- NULL
  out
}
# NOTE: the canonical mysterycall_write_results_paragraph() lives in
# R/write_results_paragraph.R (documented, exported, accepts a data frame and
# alpha/digits controls). A second, undocumented copy formerly defined here was
# dead code -- it was shadowed by collation order -- and has been removed to
# avoid the two definitions drifting apart.
