#' Compute MAE and RMSE from a fitted Poisson or linear model
#'
#' @name mysterycall_model_metrics
NULL

#' Compute MAE and RMSE from a fitted model
#'
#' Extracts fitted values and the observed response from a fitted model and
#' returns mean absolute error and root-mean-square error. Works with
#' [mysterycall_poisson_model()] results, bare `glm`, `glmerMod`, or `lm`
#' objects.
#'
#' @param model A `mysterycall_poisson_model` result, or a `glm`, `glmerMod`,
#'   or `lm` object.
#'
#' @return A named list with two numeric scalar elements:
#'   \describe{
#'     \item{`mae`}{Numeric scalar (or `NA_real_`). Mean absolute error:
#'       mean(|observed - fitted|). Measures average prediction error in the
#'       original response units.}
#'     \item{`rmse`}{Numeric scalar (or `NA_real_`). Root-mean-square error:
#'       sqrt(mean((observed - fitted)^2)). Penalizes large errors more
#'       heavily than MAE.}
#'   }
#'   Both elements are `NA_real_` when fitted values cannot be extracted
#'   (e.g., model fitting failed or an unsupported class was passed).
#'
#' @seealso [mysterycall_poisson_model()] which produces compatible model
#'   objects; [mysterycall_select_best_model()] for AIC/BIC-based selection.
#' @family outcomes
#' @keywords internal
#'
#' @examples
#' m <- glm(mpg ~ wt, data = mtcars, family = gaussian())
#' mysterycall_model_metrics(m)
mysterycall_model_metrics <- function(model) {
  if (inherits(model, "mysterycall_poisson_model")) {
    fit <- model$model
  } else if (inherits(model, c("glmerMod", "glm", "lm"))) {
    fit <- model
  } else {
    stop(
      "`model` must be a `mysterycall_poisson_model`, glm, glmerMod, or lm object.",
      call. = FALSE
    )
  }

  obs  <- as.numeric(model.response(model.frame(fit)))
  pred <- as.numeric(fitted(fit))

  mae  <- mean(abs(obs - pred), na.rm = TRUE)
  rmse <- sqrt(mean((obs - pred)^2L, na.rm = TRUE))

  list(mae = mae, rmse = rmse)
}
