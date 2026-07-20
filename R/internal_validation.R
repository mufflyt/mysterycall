# Helper utility to filter data to complete cases, handling interaction terms properly
clean_complete_cases <- function(data, outcome, predictors, extra_cols = NULL) {
  decomposed_predictors <- unique(unlist(lapply(predictors, function(term) {
    if (grepl("[:\\*\\+\\|\\(\\)]", term)) {
      tryCatch(all.vars(stats::as.formula(paste("~", term))), error = function(e) term)
    } else {
      term
    }
  })))
  model_cols <- unique(c(outcome, decomposed_predictors, extra_cols))
  model_cols <- model_cols[model_cols %in% names(data)]
  cc_mask <- stats::complete.cases(data[, model_cols, drop = FALSE])
  data[cc_mask, , drop = FALSE]
}

#' Locked Temporal Validation for Count/Binary Models
#'
#' Evaluates model performance by training on historical data (before a temporal threshold)
#' and validating predictions on future data.
#'
#' @param data A data frame containing the call outcomes.
#' @param outcome Character. Column name of the dependent variable.
#' @param predictors Character vector of predictor column names.
#' @param time_col Character. Column name representing time (Date or numeric year).
#' @param threshold Value of time_col used to split train (<= threshold) and test (> threshold).
#' @param family Character. Model family: `"poisson"`, `"nbinom"`, or `"binomial"`. Default is `"nbinom"`.
#' @return A list containing the train model, test predictions, and out-of-sample performance metrics (MSE, MAE).
#' @export
mysterycall_temporal_validation <- function(data, outcome, predictors, time_col, threshold, family = "nbinom") {
  if (!requireNamespace("glmmTMB", quietly = TRUE)) {
    stop("Package 'glmmTMB' is required.", call. = FALSE)
  }
  
  # Clean complete cases first to avoid NA mismatch issues in predict/metrics
  data <- clean_complete_cases(data, outcome, predictors, time_col)
  
  # Split data
  train_data <- data[data[[time_col]] <= threshold, ]
  test_data  <- data[data[[time_col]] > threshold, ]
  
  if (nrow(train_data) == 0 || nrow(test_data) == 0) {
    stop("Split resulted in empty train or test set. Adjust the threshold.", call. = FALSE)
  }
  
  # Fit model
  formula_str <- sprintf("%s ~ %s", outcome, paste(predictors, collapse = " + "))
  formula <- stats::as.formula(formula_str)
  
  model_family <- if (family == "poisson") {
    stats::poisson()
  } else if (family == "binomial") {
    stats::binomial()
  } else {
    glmmTMB::nbinom2()
  }
  
  fit <- glmmTMB::glmmTMB(formula, data = train_data, family = model_family)
  
  # Predict out-of-sample
  preds <- stats::predict(fit, newdata = test_data, type = "response")
  actuals <- test_data[[outcome]]
  
  # Metrics
  mse <- mean((actuals - preds)^2, na.rm = TRUE)
  mae <- mean(abs(actuals - preds), na.rm = TRUE)
  
  return(list(
    train_model = fit,
    test_data = test_data,
    predictions = preds,
    metrics = data.frame(
      Train_N = nrow(train_data),
      Test_N = nrow(test_data),
      MSE = mse,
      MAE = mae
    )
  ))
}

#' Recalibration Assessment for Fitted Models
#'
#' Assesses the calibration of predicted values against observed outcomes
#' by fitting a calibration curve and returning the calibration intercept and slope.
#'
#' @param observed Numeric vector of actual observed outcomes.
#' @param predicted Numeric vector of predicted values/probabilities from the model.
#' @param family Character. Outcome distribution: `"binomial"` or `"poisson"`. Default is `"binomial"`.
#' @param plot Logical. If TRUE, returns a calibration plot. Default is TRUE.
#' @return A list containing the calibration intercept, slope, and optionally a ggplot2 calibration curve.
#' @export
mysterycall_recalibration_assessment <- function(observed, predicted, family = "binomial", plot = TRUE) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required.", call. = FALSE)
  }
  
  cal_data <- data.frame(Obs = observed, Pred = predicted)
  
  # Fit calibration model
  # For probabilities, we fit on the logit scale: logit(Obs) ~ logit(Pred)
  cal_fit <- if (family == "binomial") {
    # Add epsilon to prevent logit(0) or logit(1)
    eps <- 1e-5
    cal_data$Pred_logit <- log((pmax(eps, pmin(1 - eps, cal_data$Pred))) / (1 - pmax(eps, pmin(1 - eps, cal_data$Pred))))
    stats::glm(Obs ~ Pred_logit, data = cal_data, family = stats::binomial(link = "logit"))
  } else {
    # Count calibration: log(Obs) ~ log(Pred)
    cal_data$Pred_log <- log(pmax(1e-5, cal_data$Pred))
    stats::glm(Obs ~ Pred_log, data = cal_data, family = stats::poisson(link = "log"))
  }
  
  coefs <- stats::coef(summary(cal_fit))
  intercept <- coefs[1, 1]
  slope <- coefs[2, 1]
  
  p <- NULL
  if (plot) {
    p <- ggplot2::ggplot(cal_data, ggplot2::aes(x = Pred, y = Obs)) +
      ggplot2::geom_point(alpha = 0.4, color = "#7F8C8D") +
      ggplot2::geom_smooth(method = "glm", method.args = list(family = if(family == "binomial") stats::binomial() else stats::poisson()), 
                           color = "#0C5A30", fill = "#0C5A30", alpha = 0.2) +
      ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "#7F8C8D") +
      ggplot2::labs(
        title = "Model Recalibration Assessment",
        subtitle = sprintf("Calibration Slope: %.3f (Ideal = 1.0) | Intercept: %.3f (Ideal = 0.0)", slope, intercept),
        x = "Predicted Values",
        y = "Observed Values"
      ) +
      ggplot2::theme_minimal()
  }
  
  return(list(
    calibration_intercept = intercept,
    calibration_slope = slope,
    plot = p
  ))
}

#' Site/Provider Split Simulation (Cluster Cross-Validation)
#'
#' Performs k-fold cross-validation while splitting by a cluster variable (e.g. site or provider ID)
#' to ensure that observations from the same cluster are never split across train and test sets.
#'
#' @param data A data frame containing the call outcomes.
#' @param outcome Character. Column name of the dependent variable.
#' @param predictors Character vector of predictor column names.
#' @param cluster_col Character. Column name of the clustering/splitting variable.
#' @param k Integer. Number of folds. Default is 5.
#' @param family Character. Model family: `"poisson"`, `"nbinom"`, or `"binomial"`. Default is `"nbinom"`.
#' @return A data frame containing average performance metrics across all folds.
#' @export
mysterycall_provider_split_simulation <- function(data, outcome, predictors, cluster_col, k = 5, family = "nbinom") {
  if (!requireNamespace("glmmTMB", quietly = TRUE)) {
    stop("Package 'glmmTMB' is required.", call. = FALSE)
  }
  
  # Clean complete cases first to avoid NA mismatch issues in predict/metrics
  data <- clean_complete_cases(data, outcome, predictors, cluster_col)
  
  # Get unique clusters
  clusters <- unique(data[[cluster_col]])
  n_clusters <- length(clusters)
  
  # Assign clusters to folds
  set.seed(42)
  folds <- split(sample(clusters), rep(1:k, length.out = n_clusters))
  
  results <- data.frame()
  formula_str <- sprintf("%s ~ %s", outcome, paste(predictors, collapse = " + "))
  formula <- stats::as.formula(formula_str)
  
  model_family <- if (family == "poisson") {
    stats::poisson()
  } else if (family == "binomial") {
    stats::binomial()
  } else {
    glmmTMB::nbinom2()
  }
  
  for (i in 1:k) {
    test_clusters <- folds[[i]]
    train_data <- data[!data[[cluster_col]] %in% test_clusters, ]
    test_data  <- data[data[[cluster_col]] %in% test_clusters, ]
    
    if (nrow(train_data) > 0 && nrow(test_data) > 0) {
      fit <- tryCatch(
        glmmTMB::glmmTMB(formula, data = train_data, family = model_family),
        error = function(e) NULL
      )
      
      if (!is.null(fit)) {
        preds <- stats::predict(fit, newdata = test_data, type = "response")
        actuals <- test_data[[outcome]]
        mse <- mean((actuals - preds)^2, na.rm = TRUE)
        mae <- mean(abs(actuals - preds), na.rm = TRUE)
        
        results <- rbind(results, data.frame(Fold = i, MSE = mse, MAE = mae))
      }
    }
  }
  
  # Average metrics
  summary_metrics <- data.frame(
    Folds_Evaluated = nrow(results),
    Mean_MSE = mean(results$MSE, na.rm = TRUE),
    Mean_MAE = mean(results$MAE, na.rm = TRUE)
  )
  
  return(summary_metrics)
}

#' Bootstrap Predictor-Retention Stability Analysis
#'
#' Draws bootstrap resamples from the data, fits a model, and calculates the percentage of times
#' each predictor is retained as statistically significant to assess model stability.
#'
#' @param data A data frame containing the call outcomes.
#' @param outcome Character. Column name of the dependent variable.
#' @param predictors Character vector of predictor candidates.
#' @param n_boot Integer. Number of bootstrap replicates. Default is 100.
#' @param p_threshold Numeric. Alpha level to define significance/retention (default is 0.05).
#' @param family Character. Model family: `"poisson"`, `"nbinom"`, or `"binomial"`. Default is `"binomial"`.
#' @return A data frame containing the retention frequency (percentage) for each predictor.
#' @export
mysterycall_bootstrap_predictor_stability <- function(data, outcome, predictors, n_boot = 100,
                                                      p_threshold = 0.05, family = "binomial") {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_string(outcome, min.chars = 1L)
  checkmate::assert_character(predictors, min.len = 1L, any.missing = FALSE,
                              min.chars = 1L, unique = TRUE)
  checkmate::assert_subset(c(outcome, predictors), choices = names(data))
  checkmate::assert_count(n_boot, positive = TRUE)
  checkmate::assert_number(p_threshold, lower = 0, upper = 1)
  checkmate::assert_choice(family, c("binomial", "poisson"))

  # Clean complete cases first to avoid NA mismatch issues in bootstrap iterations
  data <- clean_complete_cases(data, outcome, predictors)
  
  n_obs <- nrow(data)
  selection_counts <- setNames(rep(0L, length(predictors)), predictors)
  
  formula_str <- sprintf("%s ~ %s", outcome, paste(predictors, collapse = " + "))
  formula <- stats::as.formula(formula_str)
  
  cat("Running bootstrap predictor-retention stability loops...\n")
  pb <- utils::txtProgressBar(min = 0, max = n_boot, style = 3)
  
  for (i in 1:n_boot) {
    # Bootstrap resample
    boot_idx <- sample(1:n_obs, replace = TRUE)
    boot_data <- data[boot_idx, ]
    
    fit <- if (family == "binomial") {
      tryCatch(stats::glm(formula, data = boot_data, family = stats::binomial(link = "logit")), error = function(e) NULL)
    } else {
      # Use basic GLM Poisson for bootstrap speed
      tryCatch(stats::glm(formula, data = boot_data, family = stats::poisson(link = "log")), error = function(e) NULL)
    }
    
    if (!is.null(fit)) {
      coefs <- tryCatch(stats::coef(summary(fit)), error = function(e) NULL)
      if (!is.null(coefs)) {
        for (pred in predictors) {
          # Match predictor term in coefficient rownames
          row_match <- grep(pred, rownames(coefs))
          if (length(row_match) > 0) {
            p_val <- min(coefs[row_match, 4])
            if (!is.na(p_val) && p_val < p_threshold) {
              selection_counts[[pred]] <- selection_counts[[pred]] + 1L
            }
          }
        }
      }
    }
    utils::setTxtProgressBar(pb, i)
  }
  close(pb)
  
  stability_df <- data.frame(
    Predictor = names(selection_counts),
    Retention_Count = as.integer(selection_counts),
    Retention_Frequency = round((as.integer(selection_counts) / n_boot) * 100, 1)
  ) %>%
    arrange(desc(Retention_Frequency))
  
  return(stability_df)
}
