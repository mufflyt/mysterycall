#' Render a fitted model as a LaTeX equation
#'
#' Supplementary methods sections often print the statistical model as an
#' equation. This builds the LaTeX for a fitted generalized linear (mixed) model
#' -- the link-transformed outcome as a linear predictor over the fixed-effect
#' terms, plus any random intercept -- without the \pkg{equatiomatic}
#' dependency. It reads the family/link, the fixed-effect term labels, and the
#' random-effect grouping factor(s) straight off the fit.
#'
#' @param model A fitted model (`glm`, `lme4::glmer`/`lmer`, `glmmTMB`) or a
#'   mysterycall model wrapper (`mysterycall_logistic_model`,
#'   `mysterycall_poisson_model`, `mysterycall_nb_model`, `mysterycall_lmm`); the
#'   underlying fit is extracted automatically.
#' @param coefficients If `TRUE`, substitute the fitted coefficient values for
#'   the symbolic \eqn{\beta}s (a fitted equation); if `FALSE` (default) keep the
#'   symbolic \eqn{\beta_k} with a term legend.
#' @param digits Rounding for fitted coefficients when `coefficients = TRUE`.
#'   Default `3`.
#' @param wrap If `TRUE` (default) wrap the returned string in `$$ ... $$` display
#'   delimiters so it renders directly in R Markdown; if `FALSE` return the bare
#'   math.
#'
#' @return A length-1 character string of LaTeX, with a `"legend"` attribute
#'   mapping each \eqn{\beta_k} to its term label (when `coefficients = FALSE`).
#'   Printed via `cat()` inside a `results='asis'` chunk it renders as an
#'   equation.
#'
#' @examples
#' d <- data.frame(y = rbinom(100, 1, 0.5), x = rnorm(100),
#'                 grp = factor(sample(letters[1:5], 100, TRUE)))
#' fit <- glm(y ~ x, family = binomial, data = d)
#' cat(mysterycall_model_equation(fit))
#' @export
mysterycall_model_equation <- function(model, coefficients = FALSE, digits = 3,
                                       wrap = TRUE) {
  checkmate::assert_flag(coefficients)
  checkmate::assert_flag(wrap)
  fit <- .mc_extract_fit(model)

  # link + response
  info <- .mc_model_link(fit)
  link <- info$link
  resp <- .mc_latex_escape(all.vars(stats::formula(fit))[1])
  lhs <- switch(link,
    logit = sprintf("\\operatorname{logit}\\left(\\Pr(\\text{%s}=1)\\right)", resp),
    log   = sprintf("\\log\\left(\\mathbb{E}[\\text{%s}]\\right)", resp),
    identity = sprintf("\\mathbb{E}[\\text{%s}]", resp),
    sprintf("\\operatorname{%s}\\left(\\mathbb{E}[\\text{%s}]\\right)", link, resp))

  # fixed-effect term labels (exclude random-effect bars)
  tl <- attr(stats::terms(stats::formula(fit)), "term.labels")
  fixed <- tl[!grepl("\\|", tl)]

  # random-effect grouping factors, e.g. (1 | npi)
  bars <- tl[grepl("\\|", tl)]
  groups <- unique(trimws(sub(".*\\|", "", bars)))

  if (coefficients) {
    cf <- .mc_fixed_coefs(fit)
    terms_tex <- character(0)
    b0 <- if ("(Intercept)" %in% names(cf)) round(unname(cf["(Intercept)"]), digits) else 0
    body <- format(b0, nsmall = 0)
    for (nm in setdiff(names(cf), "(Intercept)")) {
      val <- round(unname(cf[nm]), digits)
      sign <- if (val < 0) " - " else " + "
      body <- paste0(body, sign, format(abs(val), nsmall = 0),
                     " \\cdot \\text{", .mc_latex_escape(nm), "}")
    }
    legend <- NULL
  } else {
    body <- "\\beta_0"
    legend <- character(0)
    for (k in seq_along(fixed)) {
      body <- paste0(body, " + \\beta_{", k, "}\\,\\text{",
                     .mc_latex_escape(fixed[k]), "}")
      legend <- c(legend, sprintf("beta_%d = %s", k, fixed[k]))
    }
  }

  # random intercept term
  re <- ""
  re_line <- ""
  if (length(groups)) {
    gi <- .mc_latex_escape(groups[1])
    re <- sprintf(" + u_{\\text{%s}}", gi)
    re_line <- sprintf(", \\quad u_{\\text{%s}} \\sim \\mathcal{N}(0,\\ \\sigma^2)", gi)
  }

  eq <- paste0(lhs, " = ", body, re, re_line)
  if (wrap) eq <- paste0("$$", eq, "$$")
  attr(eq, "legend") <- legend
  eq
}

# ---- internals --------------------------------------------------------------

.mc_model_link <- function(fit) {
  fam <- tryCatch(stats::family(fit), error = function(e) NULL)
  if (!is.null(fam) && !is.null(fam$link)) {
    return(list(family = fam$family, link = fam$link))
  }
  # glmmTMB stores family differently
  if (inherits(fit, "glmmTMB")) {
    f <- fit$modelInfo$family
    return(list(family = f$family, link = f$link %||% "log"))
  }
  list(family = "gaussian", link = "identity")
}

.mc_fixed_coefs <- function(fit) {
  if (inherits(fit, "glmmTMB")) return(glmmTMB::fixef(fit)$cond)
  if (inherits(fit, "merMod")) return(lme4::fixef(fit))
  stats::coef(fit)
}

# escape LaTeX-special characters in a term/variable label
.mc_latex_escape <- function(x) {
  x <- gsub("\\\\", "", x)
  x <- gsub("([&%$#_{}])", "\\\\\\1", x)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x
}
