# Reshape a long call table (one row per id x scenario) into an id-by-scenario
# matrix of `value_fun(...)`, erroring on duplicate (id, scenario) cells.
.mc_pair_wide <- function(data, id_col, scenario_col, values, what) {
  key <- paste(data[[id_col]], data[[scenario_col]], sep = "\r")
  if (anyDuplicated(key)) {
    dup <- unique(key[duplicated(key)])
    stop(sprintf(paste0("Found %d (%s, %s) combination(s) with more than one row ",
                        "(e.g. '%s'); aggregate to one %s per id per scenario ",
                        "before calling."),
                 length(dup), id_col, scenario_col,
                 sub("\r", " / ", dup[1]), what), call. = FALSE)
  }
  ids <- unique(data[[id_col]])
  scen <- unique(as.character(data[[scenario_col]]))
  w <- matrix(NA_real_, nrow = length(ids), ncol = length(scen),
              dimnames = list(NULL, scen))
  ii <- match(data[[id_col]], ids)
  jj <- match(as.character(data[[scenario_col]]), scen)
  w[cbind(ii, jj)] <- values
  list(wide = w, scenarios = scen)
}

.mc_default_contrasts <- function(scenarios) {
  if (length(scenarios) < 2L) {
    stop("Need at least two scenarios to form a paired contrast.", call. = FALSE)
  }
  cb <- utils::combn(scenarios, 2L, simplify = FALSE)
  cb
}

# Exact-McNemar minimum detectable effect: the smallest one-way discordant split
# (as an odds ratio) that yields `power` at level `alpha`, given `n_d` discordant
# pairs.
.mc_mcnemar_mde_or <- function(n_d, power = 0.80, alpha = 0.05) {
  if (is.na(n_d) || n_d < 1) return(NA_real_)
  crit <- stats::qbinom(alpha / 2, n_d, 0.5)
  for (psi in seq(0.50, 0.999, 0.001)) {
    k <- 0:n_d
    rej <- (k <= crit) | (k >= n_d - crit)
    if (sum(stats::dbinom(k[rej], n_d, psi)) >= power) return(psi / (1 - psi))
  }
  NA_real_
}

#' Within-practice paired McNemar test for a binary acceptance outcome
#'
#' The unmatched comparison of acceptance across scenarios (insurance types,
#' caller personas) is confounded whenever the scenarios were not called at the
#' same set of practices -- one scenario's calls can land disproportionately at
#' generous practices. The matched comparison removes each practice's baseline
#' generosity: only practices called under *both* scenarios contribute, and for a
#' binary outcome only the **discordant** practices (a different answer to the
#' two callers) carry information, so the effective sample size is the discordant
#' count, not the paired count. This runs the exact McNemar test on each pairwise
#' scenario contrast and reports the discordant split, odds ratio, exact p-value,
#' and the minimum detectable odds ratio at the requested power.
#'
#' @param data A long data frame: one row per practice x scenario.
#' @param id_col Practice / cluster identifier column.
#' @param scenario_col Scenario column (2+ levels).
#' @param outcome_col Binary acceptance column.
#' @param positive_values Value(s) of `outcome_col` counted as acceptance.
#'   Default `TRUE` (also matches `"TRUE"`/`1`/`"Yes"` via `%in%`).
#' @param contrasts Optional list of length-2 character vectors naming the
#'   scenario pairs to test. Default `NULL` tests all pairwise combinations.
#' @param power,alpha Power and two-sided level for the minimum-detectable odds
#'   ratio. Defaults `0.80` and `0.05`.
#' @param output_dir,filename Optional CSV export of the result table.
#'
#' @return An object of class `"mysterycall_paired_mcnemar"`: a list with `table`
#'   (one row per contrast: `contrast`, `n_paired`, `concordant`, `discordant`,
#'   `disc_favor_a`, `disc_favor_b`, `odds_ratio`, `mcnemar_p`,
#'   `mde_or_power`). [as.data.frame()] returns the table.
#'
#' @examples
#' set.seed(1)
#' d <- data.frame(
#'   practice = rep(1:40, each = 2),
#'   scenario = rep(c("Commercial", "Medicaid"), 40),
#'   accepted = rbinom(80, 1, rep(c(0.8, 0.5), 40))
#' )
#' mysterycall_paired_acceptance_mcnemar(d, "practice", "scenario", "accepted")
#' @export
mysterycall_paired_acceptance_mcnemar <- function(
    data, id_col, scenario_col, outcome_col, positive_values = TRUE,
    contrasts = NULL, power = 0.80, alpha = 0.05,
    output_dir = NA, filename = NA) {

  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_choice(id_col, names(data))
  checkmate::assert_choice(scenario_col, names(data))
  checkmate::assert_choice(outcome_col, names(data))
  checkmate::assert_number(power, lower = 0.01, upper = 0.999)
  checkmate::assert_number(alpha, lower = 1e-6, upper = 0.5)

  acc <- as.numeric(data[[outcome_col]] %in% positive_values)
  wd <- .mc_pair_wide(data, id_col, scenario_col, acc, "outcome")
  contrasts <- contrasts %||% .mc_default_contrasts(wd$scenarios)

  rows <- lapply(contrasts, function(cc) {
    .mc_assert_contrast(cc, wd$scenarios)
    a <- wd$wide[, cc[1]]; b <- wd$wide[, cc[2]]
    ok <- !is.na(a) & !is.na(b)
    a <- a[ok] == 1; b <- b[ok] == 1
    yn <- sum(a & !b); ny <- sum(!a & b); disc <- yn + ny
    data.frame(
      contrast = paste(cc, collapse = " vs "),
      n_paired = length(a),
      concordant = sum(a == b),
      discordant = disc,
      disc_favor_a = yn, disc_favor_b = ny,
      odds_ratio = if (ny > 0) yn / ny else if (yn > 0) Inf else NA_real_,
      mcnemar_p = if (disc > 0) stats::binom.test(min(yn, ny), disc)$p.value
                  else NA_real_,
      mde_or_power = .mc_mcnemar_mde_or(disc, power, alpha),
      stringsAsFactors = FALSE
    )
  })
  tab <- tibble::as_tibble(do.call(rbind, rows))
  .mc_maybe_write_csv(tab, output_dir, filename)

  structure(list(table = tab, power = power, alpha = alpha),
            class = "mysterycall_paired_mcnemar")
}

#' Within-practice paired wait-time comparison
#'
#' The matched analogue of [mysterycall_paired_acceptance_mcnemar()] for a
#' continuous wait-time outcome: for each pairwise scenario contrast it pairs the
#' practices called under both scenarios, forms the within-practice wait
#' differences, and reports the mean difference (with a paired-t confidence
#' interval), the paired t-test and Wilcoxon signed-rank p-values, and the
#' minimum detectable difference in days at the requested power. Pairing removes
#' each practice's baseline speed, which the unmatched comparison confounds.
#'
#' @param data A long data frame: one row per practice x scenario.
#' @param id_col Practice / cluster identifier column.
#' @param scenario_col Scenario column (2+ levels).
#' @param wait_col Numeric wait-time column.
#' @param contrasts Optional list of length-2 character vectors of scenario
#'   pairs. Default `NULL` tests all pairwise combinations.
#' @param power,conf_level Power for the minimum detectable difference and
#'   confidence level for the mean-difference interval. Defaults `0.80`, `0.95`.
#' @param output_dir,filename Optional CSV export of the result table.
#'
#' @return An object of class `"mysterycall_paired_wait"`: a list with `table`
#'   (one row per contrast: `contrast`, `n_paired`, `mean_diff_days`,
#'   `ci_lower`, `ci_upper`, `sd_diff`, `paired_t_p`, `wilcoxon_p`,
#'   `mde_days_power`). [as.data.frame()] returns the table.
#'
#' @examples
#' set.seed(2)
#' d <- data.frame(
#'   practice = rep(1:30, each = 2),
#'   scenario = rep(c("Commercial", "Medicaid"), 30),
#'   wait_days = round(c(rbind(rpois(30, 10), rpois(30, 18))))
#' )
#' mysterycall_paired_wait_within_practice(d, "practice", "scenario", "wait_days")
#' @export
mysterycall_paired_wait_within_practice <- function(
    data, id_col, scenario_col, wait_col, contrasts = NULL,
    power = 0.80, conf_level = 0.95, output_dir = NA, filename = NA) {

  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_choice(id_col, names(data))
  checkmate::assert_choice(scenario_col, names(data))
  checkmate::assert_choice(wait_col, names(data))
  checkmate::assert_number(power, lower = 0.01, upper = 0.999)
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)

  wv <- suppressWarnings(as.numeric(data[[wait_col]]))
  wd <- .mc_pair_wide(data, id_col, scenario_col, wv, "wait value")
  contrasts <- contrasts %||% .mc_default_contrasts(wd$scenarios)

  rows <- lapply(contrasts, function(cc) {
    .mc_assert_contrast(cc, wd$scenarios)
    a <- wd$wide[, cc[1]]; b <- wd$wide[, cc[2]]
    ok <- !is.na(a) & !is.na(b); a <- a[ok]; b <- b[ok]; d <- a - b
    n <- length(d)
    tt <- if (n >= 3) tryCatch(stats::t.test(a, b, paired = TRUE,
                                             conf.level = conf_level),
                               error = function(e) NULL) else NULL
    data.frame(
      contrast = paste(cc, collapse = " vs "),
      n_paired = n,
      mean_diff_days = if (n >= 1) mean(d) else NA_real_,
      ci_lower = if (!is.null(tt)) tt$conf.int[1] else NA_real_,
      ci_upper = if (!is.null(tt)) tt$conf.int[2] else NA_real_,
      sd_diff = if (n >= 2) stats::sd(d) else NA_real_,
      paired_t_p = if (!is.null(tt)) tt$p.value else NA_real_,
      wilcoxon_p = if (n >= 3) suppressWarnings(tryCatch(
        stats::wilcox.test(a, b, paired = TRUE)$p.value,
        error = function(e) NA_real_)) else NA_real_,
      mde_days_power = if (n >= 3 && stats::sd(d) > 0) tryCatch(
        stats::power.t.test(n = n, sd = stats::sd(d), power = power,
                            type = "paired")$delta,
        error = function(e) NA_real_) else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  tab <- tibble::as_tibble(do.call(rbind, rows))
  .mc_maybe_write_csv(tab, output_dir, filename)

  structure(list(table = tab, power = power, conf_level = conf_level),
            class = "mysterycall_paired_wait")
}

# ---- shared internals -------------------------------------------------------

.mc_assert_contrast <- function(cc, scenarios) {
  if (length(cc) != 2L || !all(cc %in% scenarios)) {
    stop(sprintf("Contrast c('%s') must name two scenarios present in the data (%s).",
                 paste(cc, collapse = "', '"),
                 paste(scenarios, collapse = ", ")), call. = FALSE)
  }
}

.mc_maybe_write_csv <- function(tab, output_dir, filename) {
  if (!is.na(output_dir) && !is.na(filename)) {
    if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
    utils::write.csv(tab, file.path(output_dir, filename), row.names = FALSE)
  }
}

#' @export
print.mysterycall_paired_mcnemar <- function(x, ...) {
  cat(sprintf("<mysterycall paired McNemar: %d contrast(s), MDE at %.0f%% power>\n",
              nrow(x$table), 100 * x$power))
  print(x$table, ...)
  invisible(x)
}

#' @export
as.data.frame.mysterycall_paired_mcnemar <- function(x, ...) {
  as.data.frame(x$table, ...)
}

#' @export
print.mysterycall_paired_wait <- function(x, ...) {
  cat(sprintf("<mysterycall paired wait: %d contrast(s), MDE at %.0f%% power>\n",
              nrow(x$table), 100 * x$power))
  print(x$table, ...)
  invisible(x)
}

#' @export
as.data.frame.mysterycall_paired_wait <- function(x, ...) {
  as.data.frame(x$table, ...)
}
