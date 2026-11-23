#!/usr/bin/env python3
"""Fault injection harness.

One defect at a time in a disposable worktree; reverted before the next, so
mutations never compose and the main working tree is never touched.
"""
import json, subprocess, sys

WT = sys.argv[1]
PATTERN = "adversarial|cohort-and-offset|review-findings"

M = [
 ("M1-poisson-offset-positivity", "R/poisson_model.R",
  "    validate_log_offset(data_cc[[offset_col]], offset_col,\n"
  "                        row_ids = which(cc_mask))\n", "",
  "poisson rejects every invalid finite offset"),
 ("M2-nb-offset-positivity", "R/nb_model.R",
  "    validate_log_offset(data_cc[[offset_col]], offset_col,\n"
  "                        row_ids = which(cc_mask))\n", "",
  "nb rejects every invalid finite offset"),
 ("M3-outcome-finiteness", "R/poisson_model.R",
  "  validate_outcome_finite(data[[outcome]], outcome)\n", "",
  "a NaN outcome is refused rather than counted as missing"),
 ("M4-strict-counts-ignored", "R/poisson_model.R",
  "strict = strict_counts", "strict = FALSE",
  "poisson strict count policy rejects fractions"),
 ("M5-converged-conflates-warnings", "R/poisson_model.R",
  "converged   <- opt_ok && !any(conv_msg_bad) && !any(conv_warn)",
  "converged   <- opt_ok && !any(conv_msg_bad) && !length(fit_warnings)",
  "a clean fit stays converged however many warnings it emits"),
 ("M6-dispersion-details-dropped", "R/poisson_model.R",
  "      dispersion_details = dispersion_details,\n", "",
  "poisson declared dispersion convention is reproducible"),
 ("M7-coef-returns-null", "R/model_accessors.R",
  'coef.mysterycall_poisson_model <- function(object, ...) {\n'
  '  .mc_fixed_effects(.mc_engine_fit(object, "coef"))\n}',
  'coef.mysterycall_poisson_model <- function(object, ...) {\n'
  '  object[["coefficients"]]\n}',
  "poisson accessors are real, not NULL fallbacks"),
 ("M8-cohort-assertion-neutered", "R/utils-validation.R",
  "  if (n_used == as.integer(n_expected)) {",
  "  if (TRUE) {",
  "assert_model_cohort errors when the engine dropped rows"),
 ("M9-s3-registration-removed", "NAMESPACE",
  "S3method(coef,mysterycall_poisson_model)\n", "",
  "all fitted-model S3 methods are registered"),
 ("M10-nan-offset-accepted", "R/utils-validation.R",
  '  n_nan <- sum(is.nan(x))\n  if (n_nan) {\n    stop(sprintf(\n'
  '      paste0("`%s` (offset_col) contains %d NaN value(s). NaN is not a ",',
  '  n_nan <- 0L\n  if (n_nan) {\n    stop(sprintf(\n'
  '      paste0("`%s` (offset_col) contains %d NaN value(s). NaN is not a ",',
  "NaN exposure errors even though complete.cases would drop it"),
 ("M11-pmatch-guard-weakened", "R/model_accessors.R",
  "  hit <- !is.na(pmatch(nms, targets, duplicates.ok = TRUE))",
  "  hit <- nms %in% targets",
  "partial argument matching cannot bypass the dots guard"),
 ("M12-confint-ignores-conf-level", "R/model_accessors.R",
  '    level <- object[["conf_level"]]\n    if (is.null(level)) {\n'
  '      level <- 0.95\n    }',
  '    level <- 0.95',
  "confint() defaults to the level the model was fitted with"),
 ("M13-lmm-uses-z-not-t", "R/model_accessors.R",
  "    stats::qt(1 - (1 - level) / 2, df = df)",
  "    stats::qnorm(1 - (1 - level) / 2)",
  "confint() on an LMM uses the t quantile the fitter uses"),
 # The guard moved into .mc_dispersion_ratio() precisely because this
 # mutation went undetected while it was inline in both fitters: no public
 # input reaches that branch, so deleting it broke no test.
 ("M14-dispersion-zero-not-na", "R/model_accessors.R",
  "  if (n_total > 0L && n_na >= n_total) {\n    return(NA_real_)\n  }\n"
  "  pearson_chisq / df",
  "  pearson_chisq / df",
  "the dispersion ratio is NA when no residual was computable"),
]

def run(cmd):
    return subprocess.run(cmd, cwd=WT, capture_output=True, text=True)

def revert():
    run(["git", "checkout", "--", "R/", "NAMESPACE"])

res = []
for mid, path, find, repl, expect in M:
    revert()
    src = open(f"{WT}/{path}").read()
    if src.count(find) != 1:
        res.append({"id": mid, "expect": expect, "status": "PATCH-FAILED",
                    "detail": f"anchor count {src.count(find)}"})
        print(json.dumps(res[-1]), flush=True); continue
    open(f"{WT}/{path}", "w").write(src.replace(find, repl, 1))
    out = (lambda p: p.stdout + p.stderr)(
        run(["Rscript", "tools/run-test-subset.R", PATTERN]))
    failing = [l.strip() for l in out.splitlines()
               if "failing" in l and "0 failing" not in l]
    names = [l.strip() for l in out.splitlines()
             if expect[:38] in l]
    res.append({"id": mid, "expect": expect,
                "status": "DETECTED" if failing else "MISSED",
                "summary": failing[-1] if failing else out.splitlines()[-1],
                "expected_test_failed": bool(names)})
    print(json.dumps(res[-1]), flush=True)

revert()
print("\n==== SUMMARY ====")
for r in res:
    print(f"{r['status']:14} {r['id']}")
d = ("/private/tmp/claude-501/-Users-tylermuffly-mysterycall/"
     "98ffb128-068b-4fa8-985f-e2b4c7cdfc71/scratchpad/mutation3-results.json")
open(d, "w").write(json.dumps(res, indent=2))
