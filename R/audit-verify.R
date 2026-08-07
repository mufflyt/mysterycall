#' Volatile audit fields excluded from artifact_id computation
#'
#' The canonical list of audit JSON fields that change between runs and are
#' therefore excluded when computing `artifact_id`. Any field that appears here
#' must NOT influence the content-addressable identity of an artifact.
#'
#' Keeping this constant in one place ensures that `mysterycall_verify_artifact()`
#' and `mysterycall_clean_phase1()` use identical canonicalization logic.
#'
#' @return Character vector of field names.
#' @family validation
#' @keywords internal
.audit_volatile_fields <- c(
  "start_time", "end_time", "duration_seconds",
  "r_version", "platform", "package_version", "parameters"
)


#' Verify the content-addressable identity of an audit trail JSON file
#'
#' Loads an audit JSON written by [mysterycall_clean_phase1()], strips the
#' volatile fields, recomputes the SHA-256 digest of the stable payload, and
#' compares it against the stored `artifact_id`. A mismatch means the file was
#' modified after it was written or the `artifact_id` was computed with
#' different logic.
#'
#' @param audit_path Character scalar. Path to an `audit_trail_*.json` file.
#'
#' @return Invisibly returns `TRUE` if verification passes. Throws an
#'   informative error if verification fails or the file cannot be parsed.
#'
#' @section Contract:
#' **Inputs:**
#' - `audit_path` must point to a readable JSON file produced by
#'   [mysterycall_clean_phase1()] at schema version >= 1.2.0.
#'
#' **Guarantees:**
#' - Returns `TRUE` (invisibly) only when `artifact_id` matches the recomputed
#'   digest. Any other outcome raises an error with a diagnostic message.
#' - Never modifies the audit file.
#'
#' **Fails if:**
#' - `audit_path` does not exist or is not valid JSON.
#' - The file was produced by a schema version prior to 1.2.0 (no `artifact_id`).
#' - The recomputed digest does not match the stored `artifact_id`.
#'
#' @section Called By:
#' - Downstream validation scripts and CI pipelines
#'
#' @family workflow
#' @export
#'
#' @examplesIf interactive()
#' # Verify an audit file written by clean_phase1
#' mysterycall_verify_artifact("path/to/audit_trail_2026-05-09.json")
mysterycall_verify_artifact <- function(audit_path) {
  if (!requireNamespace("jsonlite", quietly = TRUE) ||
      !requireNamespace("digest", quietly = TRUE)) {
    stop("Packages 'jsonlite' and 'digest' are required",
         call. = FALSE)
  }
  if (!is.character(audit_path) || length(audit_path) != 1L || !nzchar(audit_path)) {
    stop("audit_path must be a non-empty character scalar.", call. = FALSE)
  }
  if (!file.exists(audit_path)) {
    stop("Audit file not found: ", audit_path, call. = FALSE)
  }

  audit <- tryCatch(
    jsonlite::fromJSON(audit_path, simplifyVector = FALSE),
    error = function(e) stop("Could not parse audit JSON: ", e$message, call. = FALSE)
  )

  if (is.null(audit$artifact_id)) {
    stop(
      "Audit file does not contain 'artifact_id'. ",
      "This file was produced by schema version < 1.2.0 and cannot be verified. ",
      "Re-run mysterycall_clean_phase1() to generate a verifiable artifact.",
      call. = FALSE
    )
  }

  stored_id   <- audit$artifact_id
  stable_keys <- sort(setdiff(names(audit), c(.audit_volatile_fields, "artifact_id")), method = "radix")
  stable_json <- jsonlite::toJSON(audit[stable_keys], auto_unbox = TRUE, digits = NA)
  recomputed  <- digest::digest(as.character(stable_json), algo = "sha256", serialize = FALSE)

  if (!identical(stored_id, recomputed)) {
    stop(
      "Artifact verification FAILED for: ", audit_path, "\n",
      "  stored artifact_id : ", stored_id,  "\n",
      "  recomputed         : ", recomputed,  "\n",
      "The audit file may have been modified after generation, or ",
      "the artifact_id was computed with different canonicalization logic.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}
