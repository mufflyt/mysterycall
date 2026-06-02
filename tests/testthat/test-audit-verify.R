# Tests for R/audit-verify.R

skip_if_not_installed("jsonlite")
skip_if_not_installed("digest")

# Helper: build an audit JSON file with a correct artifact_id
write_audit <- function(path,
                        artifact_id_override = NULL,
                        omit_artifact_id     = FALSE,
                        stable_payload = list(
                          input_rows  = 100L,
                          output_rows = 95L,
                          n_dupes     = 0L
                        ),
                        volatile_payload = list(
                          start_time      = "2026-06-01T12:00:00Z",
                          end_time        = "2026-06-01T12:00:30Z",
                          duration_seconds = 30L,
                          r_version       = "4.6.0",
                          platform        = "test",
                          package_version = "1.3.0",
                          parameters      = list(foo = 1L)
                        )) {
  stable_keys <- sort(names(stable_payload))
  stable_json <- jsonlite::toJSON(stable_payload[stable_keys], auto_unbox = TRUE, digits = NA)
  computed_id <- digest::digest(as.character(stable_json), algo = "sha256", serialize = FALSE)

  audit <- c(stable_payload, volatile_payload)
  if (!omit_artifact_id) {
    audit$artifact_id <- artifact_id_override %||% computed_id
  }
  jsonlite::write_json(audit, path, auto_unbox = TRUE, digits = NA)
  list(path = path, computed_id = computed_id)
}

`%||%` <- function(a, b) if (is.null(a)) b else a

test_that("mysterycall_verify_artifact returns TRUE invisibly for valid audit", {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))
  write_audit(tmp)
  res <- mysterycall_verify_artifact(tmp)
  expect_true(res)
})

test_that("mysterycall_verify_artifact errors on missing file", {
  expect_error(
    mysterycall_verify_artifact("/nonexistent/audit_trail_999.json"),
    "not found"
  )
})

test_that("mysterycall_verify_artifact errors on non-character input", {
  expect_error(mysterycall_verify_artifact(123L), "character scalar")
  expect_error(mysterycall_verify_artifact(c("a", "b")), "character scalar")
  expect_error(mysterycall_verify_artifact(""), "character scalar")
})

test_that("mysterycall_verify_artifact errors on missing artifact_id (pre-1.2.0 schema)", {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))
  write_audit(tmp, omit_artifact_id = TRUE)
  expect_error(
    mysterycall_verify_artifact(tmp),
    "artifact_id"
  )
})

test_that("mysterycall_verify_artifact errors on tampered audit (wrong artifact_id)", {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))
  write_audit(tmp, artifact_id_override = "deadbeef")
  expect_error(
    mysterycall_verify_artifact(tmp),
    "verification FAILED"
  )
})

test_that("mysterycall_verify_artifact errors on malformed JSON", {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))
  writeLines("{ not: valid json", tmp)
  expect_error(
    mysterycall_verify_artifact(tmp),
    "Could not parse"
  )
})
