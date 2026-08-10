library(testthat)
library(mysterycall)

# ── mysterycall_resolve_path ──────────────────────────────────────────────────

test_that("mysterycall_resolve_path returns a normalized path for valid inputs", {
  base <- tempdir()
  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_resolve_path("output.csv", base_dir = base, create = FALSE)
  ))
  expect_type(result, "character")
  expect_length(result, 1L)
  # Check it is an absolute path ending with the requested filename
  expect_true(grepl("^(/|[A-Za-z]:)", result))
  expect_true(endsWith(result, "output.csv"))
})

test_that("mysterycall_resolve_path appends alias sub-directory for known types", {
  base <- tempdir()
  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_resolve_path("table1.csv", type = "tables", base_dir = base, create = FALSE)
  ))
  expect_true(grepl("tables", result, fixed = TRUE))
  expect_true(endsWith(result, "table1.csv"))
})

test_that("mysterycall_resolve_path errors on non-existent base_dir", {
  fake_dir <- file.path(tempdir(), "no_such_dir_xyz_999")
  expect_error(
    mysterycall:::mysterycall_resolve_path("file.csv", base_dir = fake_dir, create = FALSE),
    regexp = "does not exist"
  )
})

test_that("mysterycall_resolve_path errors on unknown type alias", {
  base <- tempdir()
  expect_error(
    mysterycall:::mysterycall_resolve_path("file.csv", type = "bogus_alias", base_dir = base),
    regexp = "Unknown path alias"
  )
})

test_that("mysterycall_resolve_path with create = TRUE creates the parent directory", {
  base <- tempdir()
  # Pass a RELATIVE subdir name: resolve_path() prepends base_dir. Passing an
  # absolute path here double-prepends base_dir, which yields an invalid
  # two-drive-letter path on Windows (it happened to collapse to a valid nested
  # path on Linux).
  subdir <- paste0("test_create_", as.integer(Sys.time()))
  on.exit(unlink(file.path(base, subdir), recursive = TRUE), add = TRUE)

  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_resolve_path(subdir, "output.csv", base_dir = base, create = TRUE)
  ))
  expect_type(result, "character")
  # The resolved parent directory should now exist
  expect_true(dir.exists(dirname(result)))
})

# ── mysterycall_export_with_backup ────────────────────────────────────────────

test_that("mysterycall_export_with_backup writes a data.frame as CSV", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_export_with_backup(mtcars, tmp, backup = FALSE, quiet = TRUE)
  ))
  # Compare resolved paths to handle macOS /var -> /private/var symlink
  expect_equal(
    normalizePath(result, winslash = "/", mustWork = FALSE),
    normalizePath(tmp,    winslash = "/", mustWork = FALSE)
  )
  expect_true(file.exists(tmp))
  read_back <- utils::read.csv(tmp)
  expect_equal(nrow(read_back), nrow(mtcars))
})

test_that("mysterycall_export_with_backup writes an RDS file", {
  tmp <- tempfile(fileext = ".rds")
  on.exit(unlink(tmp), add = TRUE)

  obj <- list(a = 1:3, b = "hello")
  suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_export_with_backup(obj, tmp, backup = FALSE, quiet = TRUE)
  ))
  expect_true(file.exists(tmp))
  read_back <- readRDS(tmp)
  expect_identical(read_back, obj)
})

test_that("mysterycall_export_with_backup errors when path is empty", {
  expect_error(
    mysterycall:::mysterycall_export_with_backup(mtcars, "", backup = FALSE, quiet = TRUE),
    regexp = "non-empty string"
  )
})

test_that("mysterycall_export_with_backup creates a timestamped backup when file exists", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(c(tmp, list.files(dirname(tmp), pattern = "\\.bak$", full.names = TRUE))), add = TRUE)

  # Write the file once so it exists
  suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_export_with_backup(mtcars[1:5, ], tmp, backup = FALSE, quiet = TRUE)
  ))
  expect_true(file.exists(tmp))

  # Second write should trigger a backup
  suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_export_with_backup(mtcars[6:10, ], tmp, backup = TRUE, quiet = TRUE)
  ))

  bak_files <- list.files(dirname(tmp), pattern = paste0(basename(tmp), ".*\\.bak$"), full.names = TRUE)
  expect_gte(length(bak_files), 1L)
})
