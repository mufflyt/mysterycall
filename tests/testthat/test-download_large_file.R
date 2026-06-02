test_that("mysterycall_download_file returns existing complete file", {
  tmp_dir <- tempdir()
  dest <- normalizePath(file.path(tmp_dir, "example.dat"), mustWork = FALSE)
  writeBin(raw(10), dest)
  dest <- normalizePath(dest)  # re-resolve after file creation (macOS /var → /private/var)

  mockery::stub(mysterycall_download_file, "get_content_length", function(...) 10)
  expect_equal(mysterycall_download_file("https://example.com/data", dest, overwrite = FALSE), dest)
})

test_that("mysterycall_download_file detects in-progress lock", {
  tmp_dir <- tempdir()
  dest <- normalizePath(file.path(tmp_dir, "locked.dat"), mustWork = FALSE)
  lock_path <- paste0(dest, ".lock")
  dir.create(dirname(lock_path), recursive = TRUE, showWarnings = FALSE)
  file.create(lock_path)

  mockery::stub(mysterycall_download_file, "get_content_length", function(...) NA_real_)
  expect_equal(mysterycall_download_file("https://example.com/data", dest, overwrite = FALSE), dest)
  unlink(lock_path)
})

test_that("mysterycall_download_file falls back through download methods", {
  tmp_dir <- tempdir()
  dest <- normalizePath(file.path(tmp_dir, "fallback.dat"), mustWork = FALSE)
  dest_tmp <- paste0(dest, ".download")

  call_log <- new.env(parent = emptyenv())
  call_log$calls <- character(0)
  record_call <- function(name) {
    call_log$calls <- c(call_log$calls, name)
  }

  mockery::stub(mysterycall_download_file, "get_content_length", function(...) 4)
  mockery::stub(mysterycall_download_file, "download_with_wget", function(url, dest, quiet) {
    record_call("wget")
    FALSE
  })
  mockery::stub(mysterycall_download_file, "download_with_curl", function(url, dest, quiet) {
    record_call("curl")
    FALSE
  })
  mockery::stub(mysterycall_download_file, "download_with_download_file", function(url, dest, quiet) {
    record_call("download.file")
    writeBin(as.raw(rep(0, 4)), dest)
    TRUE
  })

  result <- mysterycall_download_file("https://example.com/data", dest, overwrite = TRUE)
  expect_equal(normalizePath(result), normalizePath(dest))
  expect_true(file.exists(result))
  expect_equal(file.info(result)$size, 4)
  expect_equal(call_log$calls, c("wget", "curl", "download.file"))

  unlink(c(dest, dest_tmp))
})
