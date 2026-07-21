#' Population-average GEE model for a clustered binary audit outcome
#'
#' A companion to the subject-specific mixed model
#' ([mysterycall_logistic_model()]). Where the GLMM estimates a *conditional*
#' (within-practice) log-odds and needs each cluster's random intercept to be
#' estimable, a generalized estimating equation (GEE) estimates the
#' *population-average* (marginal) log-odds and treats the within-practice
#' correlation as a nuisance to be modelled -- so it happily uses every record,
#' including the singleton and dyad practices a matched analysis would drop. The
#' marginal-versus-conditional contrast is a standard sensitivity analysis for
#' clustered binary access outcomes: agreement in sign and rough magnitude across
#' the two targets of inference is reassuring, divergence is worth a sentence in
#' the paper. Robust ("sandwich") standard errors make the result insensitive to
#' the working-correlation choice.
#'
#' Requires the \pkg{geepack} package.
#'
#' @param data A data frame in long form (one row per call).
#' @param outcome Character scalar naming the binary outcome column. Coerced with
#'   [as.integer()] after mapping `positive_values` to 1; anything else to 0.
#' @param predictors Character vector of predictor column names. The model is
#'   `outcome ~ predictors[1] + ... `.
#' @param cluster Character scalar naming the cluster / practice id column
#'   (the GEE `id`). Rows are sorted by this internally, as `geeglm()` requires.
#' @param positive_values Value(s) of `outcome` counted as the event. Default
#'   `TRUE` (also matches `1`, `"TRUE"`, `"Yes"` via `%in%`).
#' @param corstr Working correlation structure passed to
#'   [geepack::geeglm()]. Default `"exchangeable"`.
#' @param reference Optional named character vector mapping a predictor name to
#'   the factor level to use as its reference (via [stats::relevel()]), e.g.
#'   `c(scenario = "Straight couple")`. Default `NULL`.
#' @param conf_level Confidence level for the odds-ratio CI. Default `0.95`.
#' @param output_dir,filename Optional CSV export of the coefficient table.
#'   `output_dir = NA` (default) skips writing; `NULL` writes to a session temp
#'   directory via [mysterycall_tempdir()].
#'
#' @return An object of class `"mysterycall_gee"`: a list with `model` (the
#'   fitted `geeglm`), `or_table` (a [tibble::tibble()] of `term`, `estimate`
#'   log-OR, robust `se`, `wald_z`, `p_value`, `or`, `ci_lower`, `ci_upper`),
#'   `corstr`, `n`, `n_clusters`, and `separated` (terms whose |log-OR| exceeds
#'   10, a complete-separation flag suggesting a penalized fit instead).
#'   [as.data.frame()] returns the `or_table`.
#'
#' @family outcomes
#' @seealso [mysterycall_logistic_model()], [mysterycall_marginal_effects()]
#' @examples
#' \donttest{
#' if (requireNamespace("geepack", quietly = TRUE)) {
#'   set.seed(1)
#'   d <- data.frame(
#'     practice = rep(1:30, each = 2),
#'     scenario = rep(c("Straight couple", "Lesbian couple"), 30),
#'     accepted = rbinom(60, 1, rep(c(0.8, 0.55), 30))
#'   )
#'   mysterycall_gee(d, "accepted", "scenario", "practice",
#'                   reference = c(scenario = "Straight couple"))
#' }
#' }
#' @export
mysterycall_gee <- function(data, outcome, predictors, cluster,
                           positive_values = TRUE,
                           corstr = "exchangeable", reference = NULL,
                           conf_level = 0.95,
                           output_dir = NA, filename = NA) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_choice(outcome, names(data))
  checkmate::assert_character(predictors, min.len = 1L, any.missing = FALSE)
  checkmate::assert_subset(predictors, names(data))
  checkmate::assert_choice(cluster, names(data))
  checkmate::assert_string(corstr)
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)
  checkmate::assert_character(reference, null.ok = TRUE)

  if (!requireNamespace("geepack", quietly = TRUE)) {
    stop("mysterycall_gee() requires the geepack package.\n",
         "Install it with: install.packages(\"geepack\")", call. = FALSE)
  }

  # Complete cases on the columns the model touches.
  cols <- c(outcome, predictors, cluster)
  cc   <- stats::complete.cases(data[, cols, drop = FALSE])
  df   <- data[cc, , drop = FALSE]
  if (nrow(df) < 1L) stop("No complete cases across outcome/predictors/cluster.",
                          call. = FALSE)

  df[[outcome]] <- as.integer(df[[outcome]] %in% positive_values)

  # Optional reference releveling.
  if (!is.null(reference)) {
    for (nm in names(reference)) {
      if (!nm %in% names(df)) next
      df[[nm]] <- stats::relevel(factor(df[[nm]]), ref = reference[[nm]])
    }
  }

  # geeglm requires rows grouped by cluster.
  df <- df[order(df[[cluster]]), , drop = FALSE]

  form <- stats::reformulate(predictors, response = outcome)
  fit <- geepack::geeglm(
    form, data = df, family = stats::binomial(link = "logit"),
    id = df[[cluster]], corstr = corstr
  )

  s    <- summary(fit)
  co   <- s$coefficients
  z    <- stats::qnorm(1 - (1 - conf_level) / 2)
  est  <- co[["Estimate"]]
  se   <- co[["Std.err"]]
  pcol <- grep("^Pr", names(co), value = TRUE)[1]

  or_table <- tibble::tibble(
    term      = rownames(co),
    estimate  = est,
    se        = se,
    wald_z    = est / se,
    p_value   = co[[pcol]],
    or        = exp(est),
    ci_lower  = exp(est - z * se),
    ci_upper  = exp(est + z * se)
  )

  separated <- or_table$term[abs(or_table$estimate) > 10]

  if (!identical(output_dir, NA)) {
    dir <- if (is.null(output_dir)) mysterycall_tempdir() else output_dir
    fname <- if (is.na(filename)) "gee_model.csv" else filename
    utils::write.csv(or_table, file.path(dir, fname), row.names = FALSE)
  }

  structure(
    list(
      model      = fit,
      or_table   = or_table,
      corstr     = corstr,
      n          = nrow(df),
      n_clusters = length(unique(df[[cluster]])),
      separated  = separated
    ),
    class = "mysterycall_gee"
  )
}

#' @export
print.mysterycall_gee <- function(x, digits = 3, ...) {
  cat(sprintf("Population-average GEE (binomial/logit, %s)  n = %d  clusters = %d\n",
              x$corstr, x$n, x$n_clusters))
  tab <- x$or_table
  disp <- data.frame(
    term = tab$term,
    OR   = round(tab$or, digits),
    CI   = sprintf("[%.*f, %.*f]", digits, tab$ci_lower, digits, tab$ci_upper),
    p    = signif(tab$p_value, 3),
    stringsAsFactors = FALSE
  )
  print(disp, row.names = FALSE)
  if (length(x$separated)) {
    cat("\nWARNING: possible complete separation for: ",
        paste(x$separated, collapse = ", "),
        "\n  Consider a penalized (Firth) fit.\n", sep = "")
  }
  invisible(x)
}

#' @export
as.data.frame.mysterycall_gee <- function(x, ...) {
  as.data.frame(x$or_table, ...)
}
