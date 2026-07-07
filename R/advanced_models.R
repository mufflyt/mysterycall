#' Model Same-Day Appointments (Wait Time is Zero)
#'
#' Fits a logistic regression model predicting the probability that an appointment
#' wait time is exactly zero (same-day appointment) versus a positive wait time.
#'
#' @param data A data frame containing the call outcomes.
#' @param formula Formula. Formula for the logistic model (e.g. `appt_zero ~ PE_or_Not * Payer`).
#' @param wait_col Character. Column name representing the wait days.
#' @return A glm model object of family binomial.
#' @export
mysterycall_model_zero_wait <- function(data, formula, wait_col = "business_days") {
  if (!wait_col %in% names(data)) {
    stop(sprintf("Wait column '%s' not found in dataset.", wait_col))
  }
  
  # Create binary indicator: 1 if wait is exactly 0, 0 if positive
  data$appt_zero <- as.integer(data[[wait_col]] == 0)
  
  model <- stats::glm(formula, data = data, family = stats::binomial(link = "logit"))
  return(model)
}

#' Compare Count Mixed Model Families (Poisson, nbinom1, nbinom2)
#'
#' Fits and compares three different generalized linear mixed-effects model (GLMM)
#' count families (Poisson, linear Negative Binomial, and quadratic Negative Binomial)
#' using AIC, BIC, and Log-Likelihood to identify the best fit for overdispersed wait times.
#'
#' @param data A data frame containing the call outcomes.
#' @param formula Formula. Formula for the mixed model (e.g. `Wait_Time ~ PE_or_Not * Payer + (1|Matched_Pair_ID)`).
#' @return A data frame containing fit metrics (AIC, BIC, logLik, deviance) for each model.
#' @export
mysterycall_compare_count_families <- function(data, formula) {
  if (!requireNamespace("glmmTMB", quietly = TRUE)) {
    stop("Package 'glmmTMB' is required. Install with: install.packages('glmmTMB')", call. = FALSE)
  }
  
  cat("Fitting Poisson mixed model...\n")
  fit_poisson <- tryCatch(
    glmmTMB::glmmTMB(formula, data = data, family = stats::poisson(link = "log")),
    error = function(e) { message("Poisson fit failed: ", e$message); NULL }
  )
  
  cat("Fitting Negative Binomial 1 (linear variance) mixed model...\n")
  fit_nbinom1 <- tryCatch(
    glmmTMB::glmmTMB(formula, data = data, family = glmmTMB::nbinom1(link = "log")),
    error = function(e) { message("Negative Binomial 1 fit failed: ", e$message); NULL }
  )
  
  cat("Fitting Negative Binomial 2 (quadratic variance) mixed model...\n")
  fit_nbinom2 <- tryCatch(
    glmmTMB::glmmTMB(formula, data = data, family = glmmTMB::nbinom2(link = "log")),
    error = function(e) { message("Negative Binomial 2 fit failed: ", e$message); NULL }
  )
  
  # Compute comparison table
  models <- list(Poisson = fit_poisson, nbinom1 = fit_nbinom1, nbinom2 = fit_nbinom2)
  comparison <- data.frame()
  
  for (name in names(models)) {
    m <- models[[name]]
    if (!is.null(m)) {
      comparison <- rbind(comparison, data.frame(
        Model = name,
        AIC = stats::AIC(m),
        BIC = stats::BIC(m),
        logLik = as.numeric(stats::logLik(m)),
        Deviance = stats::deviance(m)
      ))
    }
  }
  
  return(comparison)
}

#' Model Non-Linear Relationships with Splines or Polynomials
#'
#' Fits a regression model incorporating natural cubic splines or polynomial terms
#' for a continuous predictor, and optionally plots the predicted non-linear relationship.
#'
#' @param data A data frame containing the call outcomes.
#' @param outcome_col Character. Column name of the dependent variable.
#' @param predictor_col Character. Column name of the continuous predictor to model non-linearly.
#' @param other_covariates Character vector of other covariates to include in the model.
#' @param type Character. Type of non-linear model: `"spline"` (natural cubic spline) or `"poly"` (orthogonal polynomial). Default is `"spline"`.
#' @param df_degree Integer. Degrees of freedom for splines, or degree for polynomial. Default is 3.
#' @param plot Logical. If TRUE, plots the non-linear relationship. Default is TRUE.
#' @return A list containing the fitted model object and the ggplot2 object (if plot is TRUE).
#' @export
mysterycall_model_nonlinear <- function(data, outcome_col, predictor_col, other_covariates = NULL, 
                                        type = "spline", df_degree = 3, plot = TRUE) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Install with: install.packages('ggplot2')", call. = FALSE)
  }
  if (!requireNamespace("splines", quietly = TRUE)) {
    stop("Package 'splines' is required.", call. = FALSE)
  }
  
  # Clean data
  model_data <- data[!is.na(data[[outcome_col]]) & !is.na(data[[predictor_col]]), ]
  
  # Construct formula
  nonlinear_term <- if (type == "spline") {
    sprintf("splines::ns(%s, df = %d)", predictor_col, df_degree)
  } else {
    sprintf("poly(%s, %d)", predictor_col, df_degree)
  }
  
  cov_str <- if (!is.null(other_covariates)) paste(other_covariates, collapse = " + ") else NULL
  formula_str <- if (!is.null(cov_str)) {
    sprintf("%s ~ %s + %s", outcome_col, nonlinear_term, cov_str)
  } else {
    sprintf("%s ~ %s", outcome_col, nonlinear_term)
  }
  
  formula <- stats::as.formula(formula_str)
  
  # Fit linear model (using OLS for general visualization)
  model <- stats::lm(formula, data = model_data)
  
  p <- NULL
  if (plot) {
    # Generate predictions for plotting the smooth curve
    pred_grid <- data.frame(seq(min(model_data[[predictor_col]], na.rm = TRUE),
                                max(model_data[[predictor_col]], na.rm = TRUE),
                                length.out = 200))
    names(pred_grid) <- predictor_col
    
    # Add mean/reference values for other covariates if present
    if (!is.null(other_covariates)) {
      for (cov in other_covariates) {
        val <- model_data[[cov]]
        pred_grid[[cov]] <- if (is.numeric(val)) mean(val, na.rm = TRUE) else val[1]
      }
    }
    
    preds <- stats::predict(model, newdata = pred_grid, se.fit = TRUE)
    pred_grid$fit <- preds$fit
    pred_grid$se <- preds$se.fit
    pred_grid$low <- preds$fit - 1.96 * preds$se
    pred_grid$high <- preds$fit + 1.96 * preds$se
    
    p <- ggplot2::ggplot(model_data, ggplot2::aes_string(x = predictor_col, y = outcome_col)) +
      ggplot2::geom_point(alpha = 0.4, color = "#7F8C8D") +
      ggplot2::geom_ribbon(data = pred_grid, ggplot2::aes(y = fit, ymin = low, ymax = high), 
                           fill = "#0C5A30", alpha = 0.2) +
      ggplot2::geom_line(data = pred_grid, ggplot2::aes(y = fit), 
                         color = "#0C5A30", linewidth = 1.2) +
      ggplot2::labs(
        title = sprintf("Non-Linear Relationship: %s vs %s", predictor_col, outcome_col),
        subtitle = sprintf("Estimated via %s (df/degree = %d)", type, df_degree),
        x = predictor_col,
        y = outcome_col
      ) +
      ggplot2::theme_minimal()
  }
  
  return(list(model = model, plot = p))
}
