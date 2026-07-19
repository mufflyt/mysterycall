#' Leave-one-group-out refit sensitivity
#'
#' Refits a model repeatedly, each time dropping all rows belonging to one level
#' of a grouping variable (e.g. leave-one-caller-out, leave-one-site-out), and
#' tabulates how a target coefficient -- and, optionally, the joint significance
#' of a factor -- moves across refits. A headline estimate that is stable when
#' any single group is removed is more credible than one that hinges on one
#' caller or site.
#'
#' @param model A fitted model (`glm`, `glmer`, `glmmTMB`, ...) or a mysterycall
#'   model wrapper; the underlying fit is extracted automatically.
#' @param data The data frame the model was fit on (needed to subset and refit).
#' @param group Column in `data` whose levels are left out one at a time.
#' @param term Name of the coefficient to track across refits (e.g.
#'   `"ent_typePediatrics"`).
#' @param joint_predictor Optional predictor to also joint-test on each refit
#'   (via [mysterycall_joint_test()]), adding a `joint_p` column.
#' @param exponentiate If `TRUE` (default) report `exp(estimate)` (odds/rate
#'   ratio) alongside the estimate.
#' @param min_rows Skip a leave-out fit if fewer than this many rows remain.
#'   Default `10`.
#'
#' @return An object of class `"mysterycall_leave_one_out"`: a list with `table`
#'   (a tibble: `group_excluded`, `n`, `estimate`, optional `ratio`, `std_error`,
#'   `p_value`, optional `joint_p`, `converged`) and `full` (the target
#'   estimate/ratio/p on the complete data). [as.data.frame()] returns the table.
#'
#' @examples
#' set.seed(1)
#' d <- data.frame(
#'   y = rbinom(300, 1, 0.4),
#'   grp = factor(sample(c("a", "b", "c"), 300, TRUE)),
#'   caller = factor(sample(paste0("c", 1:5), 300, TRUE))
#' )
#' fit <- glm(y ~ grp, family = binomial, data = d)
#' mysterycall_leave_one_out(fit, d, group = "caller", term = "grpb",
#'                           joint_predictor = "grp")
#' @export
mysterycall_leave_one_out <- function(model, data, group, term,
                                      joint_predictor = NULL,
                                      exponentiate = TRUE, min_rows = 10L) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_choice(group, names(data))
  checkmate::assert_string(term)
  checkmate::assert_flag(exponentiate)
  checkmate::assert_count(min_rows)
  fit <- .mc_extract_fit(model)

  pull_term <- function(f) {
    co <- .mc_coef_table(f)
    if (is.null(co) || !term %in% rownames(co)) {
      return(c(est = NA_real_, se = NA_real_, p = NA_real_))
    }
    c(est = co[term, 1], se = co[term, 2], p = co[term, ncol(co)])
  }

  full <- pull_term(fit)
  levs <- sort(unique(as.character(data[[group]])))

  rows <- lapply(levs, function(lv) {
    sub <- data[as.character(data[[group]]) != lv, , drop = FALSE]
    if (nrow(sub) < min_rows) {
      return(.mc_loo_row(lv, nrow(sub), NA_real_, NA_real_, NA_real_,
                         joint_predictor, NA_real_, FALSE, exponentiate))
    }
    rf <- tryCatch(stats::update(fit, data = sub), error = function(e) NULL)
    if (is.null(rf)) {
      return(.mc_loo_row(lv, nrow(sub), NA_real_, NA_real_, NA_real_,
                         joint_predictor, NA_real_, FALSE, exponentiate))
    }
    tt <- pull_term(rf)
    jp <- NA_real_
    if (!is.null(joint_predictor)) {
      jp <- tryCatch(mysterycall_joint_test(rf, joint_predictor)$p_value,
                     error = function(e) NA_real_)
    }
    .mc_loo_row(lv, nrow(sub), tt[["est"]], tt[["se"]], tt[["p"]],
                joint_predictor, jp, TRUE, exponentiate)
  })
  tab <- tibble::as_tibble(do.call(rbind, rows))

  full_row <- list(estimate = unname(full[["est"]]),
                   p_value = unname(full[["p"]]))
  if (exponentiate) full_row$ratio <- exp(unname(full[["est"]]))

  structure(list(table = tab, full = full_row, term = term),
            class = "mysterycall_leave_one_out")
}

# a coefficient matrix (estimate, se, ..., p) across glm / glmer / glmmTMB
.mc_coef_table <- function(fit) {
  s <- summary(fit)
  co <- s$coefficients
  if (is.list(co) && !is.null(co$cond)) return(co$cond)   # glmmTMB
  if (is.matrix(co)) return(co)
  NULL
}

.mc_loo_row <- function(lv, n, est, se, p, joint_predictor, jp, converged,
                        exponentiate) {
  base <- data.frame(group_excluded = lv, n = n, estimate = est,
                     stringsAsFactors = FALSE)
  if (exponentiate) base$ratio <- exp(est)
  base$std_error <- se
  base$p_value <- p
  if (!is.null(joint_predictor)) base$joint_p <- jp
  base$converged <- converged
  base
}

#' @export
print.mysterycall_leave_one_out <- function(x, ...) {
  cat(sprintf("<mysterycall leave-one-group-out: term '%s', %d refits>\n",
              x$term, nrow(x$table)))
  if (!is.null(x$full$ratio)) {
    cat(sprintf("  full-data ratio: %.2f (p = %s)\n", x$full$ratio,
                format.pval(x$full$p_value, digits = 3, eps = 1e-4)))
  } else {
    cat(sprintf("  full-data estimate: %.3f (p = %s)\n", x$full$estimate,
                format.pval(x$full$p_value, digits = 3, eps = 1e-4)))
  }
  print(x$table, ...)
  invisible(x)
}

#' @export
as.data.frame.mysterycall_leave_one_out <- function(x, ...) {
  as.data.frame(x$table, ...)
}
