# Multi-category / multi-response call outcomes and a call-outcome taxonomy
# -----------------------------------------------------------------------------
# The package's outcome set was binary (offered / declined) and count (wait
# days). Real audit calls are graded and multi-state: a clinic names several
# pain options (check-all-that-apply), routes a caller through an access tier
# (info by phone -> in-person only -> must establish care), or blocks an
# appointment pending insurance verification / a referral / records. This module
# turns those realities into first-class outcomes.
#
#   mysterycall_multiresponse_tabulate()  per-option prevalence (Wilson CI),
#                                         co-occurrence, options-per-call
#   mysterycall_classify_call_outcome()   map raw dispositions to a standard
#                                         call-outcome taxonomy
#   mysterycall_outcome_gradient()        ordered multi-category summary with
#                                         cumulative proportions (access tiers)
#   mysterycall_ordinal_model()           proportional-odds model for a graded
#                                         ordinal outcome (MASS::polr)
# -----------------------------------------------------------------------------


# ---- internal helpers -------------------------------------------------------

# Which rows actually responded (so an empty set counts, but NA / NULL does not).
.mc_responding <- function(x) {
  if (is.list(x)) {
    return(!vapply(x, function(e) is.null(e) ||
                     (length(e) == 1L && is.na(e)), logical(1)))
  }
  !is.na(x)
}

# Per-option prevalence table with Wilson CIs, given parsed option sets + a
# responding mask.
.mc_option_prevalence <- function(sets, responding, conf_level, sort) {
  total <- sum(responding)
  opts <- sort(unique(unlist(sets[responding])))
  if (length(opts) == 0L) {
    return(tibble::tibble(
      option = character(0), n = integer(0), total = integer(0),
      prevalence = numeric(0), ci_lower = numeric(0), ci_upper = numeric(0)
    ))
  }
  counts <- unname(vapply(opts, function(o) {
    sum(vapply(which(responding), function(i) o %in% sets[[i]], logical(1)))
  }, integer(1)))
  ci <- t(vapply(counts, function(cnt) .mc_wilson_ci(cnt, total, conf_level),
                 numeric(2)))
  out <- tibble::tibble(
    option     = opts,
    n          = as.integer(counts),
    total      = as.integer(total),
    prevalence = round(counts / total, 3),
    ci_lower   = round(ci[, 1], 3),
    ci_upper   = round(ci[, 2], 3)
  )
  if (isTRUE(sort)) out <- out[order(-out$prevalence), ]
  out
}


# ---- multi-response (check-all-that-apply) ----------------------------------

#' Tabulate a Multi-Response ("Check-All-That-Apply") Call Outcome
#'
#' Summarises an outcome where each call may name several options at once -- for
#' example the set of pain-management options a clinic offers (Sharma 2025) or
#' the alternatives a pharmacy suggests when a product is unavailable (Wilkinson
#' 2018). Reports per-option prevalence with Wilson intervals, an option
#' co-occurrence matrix, and options-per-call summaries. Denominators use only
#' *responding* calls; a call that responded but named nothing counts toward the
#' denominator with zero options.
#'
#' @param data A data frame.
#' @param var Character scalar. The multi-response column: either a list-column
#'   of character vectors, or a delimited string (see `sep`). `NA` marks a
#'   non-responding call (excluded from denominators); an empty string is a
#'   responding call that named no options.
#' @param group_var Character scalar or `NULL`. Optional grouping column; when
#'   supplied, per-option prevalence is also computed within each group.
#' @param sep Character scalar. Delimiter for string-valued option columns.
#'   Default `";"`.
#' @param conf_level Numeric. Confidence level for Wilson intervals. Default
#'   `0.95`.
#' @param sort Logical. Sort options by descending prevalence. Default `TRUE`.
#'
#' @return A `mysterycall_multiresponse` object: a list with `prevalence` (a
#'   [tibble::tibble()]), `cooccurrence` (an integer matrix; diagonal = option
#'   counts, off-diagonal = joint counts), `summary` (n_calls, n_responding,
#'   mean_options_per_call, pct_naming_any), `by_group` (tibble or `NULL`), and
#'   `settings`.
#'
#' @family call-outcomes
#' @importFrom tibble tibble
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_number assert_flag
#' @export
#'
#' @examples
#' calls <- data.frame(
#'   options = c("ibuprofen;lidocaine", "ibuprofen", "", "misoprostol;ibuprofen"),
#'   region  = c("W", "W", "E", "E"),
#'   stringsAsFactors = FALSE
#' )
#' res <- mysterycall_multiresponse_tabulate(calls, "options", group_var = "region")
#' res$prevalence
mysterycall_multiresponse_tabulate <- function(
    data, var, group_var = NULL, sep = ";",
    conf_level = 0.95, sort = TRUE) {

  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_string(var)
  need <- if (is.null(group_var)) var else c(var, group_var)
  checkmate::assert_names(names(data), must.include = need)
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)
  checkmate::assert_flag(sort)

  x <- data[[var]]
  responding <- .mc_responding(x)
  sets <- .mc_parse_options(x, sep)

  prevalence <- .mc_option_prevalence(sets, responding, conf_level, sort)

  # co-occurrence matrix over responding calls
  opts <- prevalence$option
  K <- length(opts)
  co <- matrix(0L, K, K, dimnames = list(opts, opts))
  for (i in which(responding)) {
    s <- intersect(sets[[i]], opts)
    if (length(s) == 0L) next
    idx <- match(s, opts)
    co[idx, idx] <- co[idx, idx] + 1L
  }

  n_resp <- sum(responding)
  # count DISTINCT options per call so a call listing "a;a" counts one, matching
  # how prevalence (%in%) and co-occurrence (intersect) dedupe.
  n_opts_per <- vapply(sets[responding], function(s) length(unique(s)), integer(1))
  summary <- list(
    n_calls               = nrow(data),
    n_responding          = n_resp,
    mean_options_per_call = if (n_resp > 0) round(mean(n_opts_per), 2) else NA_real_,
    pct_naming_any        = if (n_resp > 0) round(mean(n_opts_per > 0), 3) else NA_real_
  )

  by_group <- NULL
  if (!is.null(group_var)) {
    g <- as.character(data[[group_var]])
    parts <- lapply(split(seq_len(nrow(data)), g), function(idx) {
      .mc_option_prevalence(sets[idx], responding[idx], conf_level, sort)
    })
    by_group <- do.call(rbind, Map(function(tb, gname) {
      if (nrow(tb) == 0L) return(NULL)
      cbind(group = gname, tb)
    }, parts, names(parts)))
    by_group <- tibble::as_tibble(by_group)
  }

  structure(
    list(
      prevalence   = prevalence,
      cooccurrence = co,
      summary      = summary,
      by_group     = by_group,
      settings     = list(var = var, group_var = group_var, sep = sep,
                          conf_level = conf_level)
    ),
    class = "mysterycall_multiresponse"
  )
}


# ---- call-outcome taxonomy --------------------------------------------------

# The default disposition taxonomy: canonical level -> case-insensitive regex.
# Order matters: the first matching pattern wins.
.mc_default_outcome_map <- function() {
  list(
    not_reached                     = "no answer|voicemail|disconnect|not in service|unreachable|busy|no working",
    gatekeeping_no_info             = "won'?t (give|share|provide)|no info|not over (the )?phone|can'?t (say|tell)|call back",
    insurance_verification_required = "insurance (id|number|verif|member)|member id|verify insurance|need.*insurance",
    referral_required               = "referral",
    records_required                = "records|chart|prior notes",
    new_patient_restriction         = "not accepting new|established patients only|existing patients only|no new patients",
    declined                        = "declin|refus|not accept|no appointment|unavailable|turned away",
    appointment_offered             = "offered|scheduled|appointment (given|available|offered)|booked|accepted|yes"
  )
}

#' Map Raw Call Dispositions to a Standard Outcome Taxonomy
#'
#' Collapses free-text or heterogeneous call-disposition labels into a small,
#' analysable set of canonical states that recur across access audits -- so an
#' appointment blocked pending insurance verification, a referral, or records is
#' distinguished from a plain refusal, and phone gatekeeping and unreachable
#' numbers become their own funnel stages (Pollack 2016, Sharma 2025, Hodson
#' 2025).
#'
#' @param x Character vector of raw disposition text (one per call).
#' @param mapping Named list or `NULL`. Names are canonical levels; values are
#'   case-insensitive regular expressions matched against `x`. The first
#'   matching pattern (in list order) wins. `NULL` uses a built-in default map
#'   covering the common access-audit states.
#' @param other Character scalar. Level assigned when nothing matches. Default
#'   `"other"`.
#'
#' @return A factor with levels in `mapping` order followed by `other`.
#'
#' @family call-outcomes
#' @importFrom checkmate assert_character assert_list assert_string
#' @export
#'
#' @examples
#' raw <- c("Appointment offered in 12 days", "Needs a referral first",
#'          "Won't give info over the phone", "No answer after 3 tries",
#'          "Must verify insurance ID number")
#' mysterycall_classify_call_outcome(raw)
mysterycall_classify_call_outcome <- function(x, mapping = NULL, other = "other") {
  checkmate::assert_character(x)
  checkmate::assert_string(other)
  if (is.null(mapping)) mapping <- .mc_default_outcome_map()
  checkmate::assert_list(mapping, types = "character", names = "named", min.len = 1)

  levels_order <- c(names(mapping), other)
  result <- rep(other, length(x))
  result[is.na(x)] <- NA_character_

  for (lvl in names(mapping)) {
    pat <- mapping[[lvl]]
    hit <- !is.na(x) & result == other & grepl(pat, x, ignore.case = TRUE, perl = TRUE)
    result[hit] <- lvl
  }
  factor(result, levels = levels_order)
}


# ---- ordered multi-category gradient ----------------------------------------

#' Ordered Multi-Category Outcome Summary (Access Gradient)
#'
#' Summarises a categorical outcome across its levels with per-level counts,
#' proportions, Wilson intervals, and -- for an ordered (graded) outcome such as
#' an access tier -- cumulative proportions. Fits the graded access ladders in
#' the literature (Sharma's "information by phone / in-person only / must
#' establish care"; a triage disposition; a staff-role breakdown).
#'
#' @param data A data frame.
#' @param var Character scalar. The categorical outcome column.
#' @param levels Character vector or `NULL`. The level ordering. `NULL` uses the
#'   factor levels of `var`, or the sorted unique values.
#' @param group_var Character scalar or `NULL`. Optional grouping column.
#' @param conf_level Numeric. Wilson interval confidence level. Default `0.95`.
#' @param cumulative Logical. Add a `cumulative_prop` column following `levels`
#'   order (meaningful for an ordinal outcome). Default `TRUE`.
#'
#' @return A [tibble::tibble()] with columns (optional `group`), `level`, `n`,
#'   `total`, `proportion`, `ci_lower`, `ci_upper`, and optionally
#'   `cumulative_prop`.
#'
#' @family call-outcomes
#' @importFrom tibble tibble
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_number assert_flag
#' @export
#'
#' @examples
#' df <- data.frame(
#'   access = c("phone", "phone", "in_person", "must_establish", "phone",
#'              "in_person", "must_establish", "must_establish")
#' )
#' mysterycall_outcome_gradient(
#'   df, "access", levels = c("phone", "in_person", "must_establish")
#' )
mysterycall_outcome_gradient <- function(
    data, var, levels = NULL, group_var = NULL,
    conf_level = 0.95, cumulative = TRUE) {

  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_string(var)
  need <- if (is.null(group_var)) var else c(var, group_var)
  checkmate::assert_names(names(data), must.include = need)
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)
  checkmate::assert_flag(cumulative)

  if (is.null(levels)) {
    levels <- if (is.factor(data[[var]])) levels(data[[var]]) else sort(unique(data[[var]][!is.na(data[[var]])]))
  }

  one_block <- function(vals, grp_label) {
    vals <- vals[!is.na(vals)]
    total <- length(vals)
    counts <- unname(vapply(levels, function(l) sum(vals == l), integer(1)))
    ci <- t(vapply(counts, function(cnt) .mc_wilson_ci(cnt, total, conf_level),
                   numeric(2)))
    out <- tibble::tibble(
      level      = levels,
      n          = as.integer(counts),
      total      = as.integer(total),
      proportion = round(counts / total, 3),
      ci_lower   = round(ci[, 1], 3),
      ci_upper   = round(ci[, 2], 3)
    )
    if (isTRUE(cumulative)) {
      out$cumulative_prop <- round(cumsum(counts) / total, 3)
    }
    if (!is.null(grp_label)) out <- cbind(group = grp_label, out)
    out
  }

  if (is.null(group_var)) {
    return(tibble::as_tibble(one_block(data[[var]], NULL)))
  }
  parts <- split(data[[var]], as.character(data[[group_var]]))
  res <- do.call(rbind, Map(function(v, g) one_block(v, g), parts, names(parts)))
  tibble::as_tibble(res)
}


# ---- proportional-odds ordinal model ----------------------------------------

#' Proportional-Odds Model for a Graded Ordinal Outcome
#'
#' Fits an ordinal (cumulative-link) model to a graded outcome such as an access
#' tier, returning proportional-odds odds ratios with Wald confidence intervals
#' and p-values. Thin wrapper around [MASS::polr()].
#'
#' @param data A data frame.
#' @param outcome_var Character scalar. The ordinal outcome column.
#' @param predictors Character vector. Predictor column names.
#' @param levels Character vector or `NULL`. The outcome's increasing level
#'   order. `NULL` uses the existing factor ordering or sorted unique values.
#' @param conf_level Numeric. Confidence level for the Wald intervals. Default
#'   `0.95`.
#'
#' @return A [tibble::tibble()] with columns `term`, `or`, `ci_lower`,
#'   `ci_upper`, `p_value` (one row per predictor coefficient).
#'
#' @family call-outcomes
#' @importFrom tibble tibble
#' @importFrom stats as.formula pnorm qnorm
#' @importFrom checkmate assert_data_frame assert_string assert_character assert_names assert_number
#' @export
#'
#' @examples
#' if (requireNamespace("MASS", quietly = TRUE)) {
#'   set.seed(1)
#'   df <- data.frame(
#'     access = factor(sample(c("phone", "in_person", "must_establish"), 90, TRUE),
#'                     levels = c("phone", "in_person", "must_establish"),
#'                     ordered = TRUE),
#'     medicaid = sample(c(0, 1), 90, TRUE)
#'   )
#'   mysterycall_ordinal_model(df, "access", "medicaid")
#' }
mysterycall_ordinal_model <- function(
    data, outcome_var, predictors, levels = NULL, conf_level = 0.95) {

  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_string(outcome_var)
  checkmate::assert_character(predictors, min.len = 1, any.missing = FALSE)
  checkmate::assert_names(names(data), must.include = c(outcome_var, predictors))
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)
  if (!requireNamespace("MASS", quietly = TRUE)) {
    stop("mysterycall_ordinal_model() requires the MASS package.", call. = FALSE)
  }

  y <- data[[outcome_var]]
  if (is.null(levels)) {
    levels <- if (is.factor(y)) levels(y) else sort(unique(y[!is.na(y)]))
  }
  data[[outcome_var]] <- factor(y, levels = levels, ordered = TRUE)
  if (nlevels(data[[outcome_var]]) < 3L) {
    stop(sprintf(
      paste0("`%s` has %d ordered level(s); mysterycall_ordinal_model() needs ",
             "an outcome with 3+ levels. For a binary outcome use a logistic model."),
      outcome_var, nlevels(data[[outcome_var]])), call. = FALSE)
  }

  fml <- stats::as.formula(
    paste(outcome_var, "~", paste(predictors, collapse = " + "))
  )
  fit <- MASS::polr(fml, data = data, Hess = TRUE)

  co <- summary(fit)$coefficients
  keep <- setdiff(rownames(co), names(fit$zeta))  # drop the intercept cutpoints
  co <- co[keep, , drop = FALSE]
  est <- co[, "Value"]
  se <- co[, "Std. Error"]
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  tibble::tibble(
    term     = rownames(co),
    or       = round(exp(est), 3),
    ci_lower = round(exp(est - z * se), 3),
    ci_upper = round(exp(est + z * se), 3),
    p_value  = round(2 * stats::pnorm(-abs(est / se)), 4)
  )
}


# ---- S3 methods -------------------------------------------------------------

#' Print a `mysterycall_multiresponse` object
#'
#' @param x A `mysterycall_multiresponse` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return `x`, invisibly.
#' @export
print.mysterycall_multiresponse <- function(x, ...) {
  s <- x$summary
  cat(sprintf("<mysterycall_multiresponse: %s>\n", x$settings$var))
  cat(sprintf("  %d calls (%d responding); mean %.2f options/call; %.1f%% named >=1\n",
              s$n_calls, s$n_responding, s$mean_options_per_call,
              100 * s$pct_naming_any))
  cat("  option prevalence:\n")
  pv <- x$prevalence
  for (i in seq_len(nrow(pv))) {
    cat(sprintf("    %-24s %5.1f%% (n=%d)\n",
                substr(pv$option[i], 1, 24), 100 * pv$prevalence[i], pv$n[i]))
  }
  if (!is.null(x$by_group)) {
    cat(sprintf("  grouped by %s (%d groups)\n",
                x$settings$group_var, length(unique(x$by_group$group))))
  }
  invisible(x)
}

#' Coerce a `mysterycall_multiresponse` object to a data frame
#'
#' @param x A `mysterycall_multiresponse` object.
#' @param ... Ignored; present for S3 method consistency.
#' @return A `data.frame` representation of `x`.
#' @export
as.data.frame.mysterycall_multiresponse <- function(x, ...) {
  as.data.frame(x$prevalence, ...)
}
