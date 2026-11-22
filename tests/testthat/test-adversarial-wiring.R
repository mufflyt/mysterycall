# Installation and namespace wiring checks; do not skip absent methods.

mc_adv_methods <- base::c(
  "coef", "vcov", "confint", "nobs", "formula",
  "fitted", "residuals", "summary"
)
mc_adv_model_classes <- base::c(
  "mysterycall_poisson_model", "mysterycall_nb_model"
)

testthat::test_that("all fitted-model S3 methods are registered", {
  namespace <- base::getNamespaceInfo("mysterycall", "S3methods")
  testthat::expect_true(base::is.matrix(namespace))
  for (model_class in mc_adv_model_classes) {
    for (method_name in mc_adv_methods) {
      registration <- base::any(
        namespace[, 1L] == method_name &
          namespace[, 2L] == model_class
      )
      testthat::expect_true(
        registration,
        info = base::sprintf("Unregistered: %s.%s", method_name,
                             model_class)
      )
      # getS3method() is exported by utils, not base: `base::getS3method`
      # raises "object not found" before the assertion can run.
      testthat::expect_true(
        base::is.function(utils::getS3method(
          method_name, model_class, optional = TRUE
        )),
        info = base::sprintf("Missing dispatch: %s.%s", method_name,
                             model_class)
      )
    }
  }
})

testthat::test_that("R package contract documents strict count policy", {
  poisson_formals <- base::names(base::formals(
    mysterycall::mysterycall_poisson_model
  ))
  nb_formals <- base::names(base::formals(
    mysterycall::mysterycall_nb_model
  ))
  testthat::expect_true("strict_counts" %in% poisson_formals)
  testthat::expect_true("strict_counts" %in% nb_formals)
})

testthat::test_that("successful fit separates convergence and warnings", {
  for (family_id in base::c("poisson", "nb")) {
    fitted_result <- mc_adv_fit(mc_adv_calls(), family_id)
    testthat::expect_type(fitted_result$convergence$converged,
                          "logical")
    testthat::expect_length(fitted_result$convergence$converged, 1L)
    testthat::expect_false(base::is.na(
      fitted_result$convergence$converged
    ))
    testthat::expect_true(
      "fit_warnings" %in% base::names(fitted_result),
      info = base::sprintf("%s lacks independent warning log", family_id)
    )
    testthat::expect_type(fitted_result$fit_warnings, "character")
  }
})

testthat::test_that("fit object guards reject missing engine fits", {
  for (family_id in base::c("poisson", "nb")) {
    fitted_result <- mc_adv_fit(mc_adv_calls(), family_id)
    fitted_result$model <- NULL
    for (method_name in mc_adv_methods) {
      method_fun <- base::get(method_name,
        envir = base::asNamespace(
          if (method_name == "summary") "base" else "stats"
        )
      )
      testthat::expect_error(
        method_fun(fitted_result),
        info = base::sprintf("%s.%s silently accepted missing fit",
                             method_name, family_id)
      )
    }
  }
})
