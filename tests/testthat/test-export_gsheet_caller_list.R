test_that("export_gsheet_caller_list writes title row, header, and ordered rows", {
  src <- withr::local_tempfile(fileext = ".csv")
  out <- withr::local_tempfile(fileext = ".csv")
  readr::write_csv(data.frame(
    `Provider Name`   = c("Dr. B", "Dr. A", "Dr. D", "Dr. C"),
    Phone             = c("222", "111", "444", "333"),
    NPI               = c("1000000002", "1000000001", "1000000004", "1000000003"),
    State             = c("FL", "FL", "AL", "AL"),
    PE_or_Not         = c("PE", "Non-PE", "PE", "Non-PE"),
    `Matched Pair ID` = c("2", "2", "1", "1"),
    check.names = FALSE, stringsAsFactors = FALSE), src)

  res <- mysterycall_export_gsheet_caller_list(
    src, out, study_title = "Test Study", verbose = FALSE)

  lines <- readLines(out)
  expect_equal(lines[1], "Test Study,,,")
  expect_equal(lines[2], "Provider Name,Phone,NPI,Stage 1 Calling")
  expect_length(lines, 6L)                       # title + header + 4 rows

  # Ordered by state (AL before FL); within a pair Non-PE precedes PE.
  expect_equal(res[["Provider Name"]], c("Dr. C", "Dr. D", "Dr. A", "Dr. B"))
  expect_true(all(res[["Stage 1 Calling"]] == ""))
})

test_that("output uses CRLF line endings", {
  src <- withr::local_tempfile(fileext = ".csv")
  out <- withr::local_tempfile(fileext = ".csv")
  readr::write_csv(data.frame(
    `Provider Name`   = "Dr. A", Phone = "111", NPI = "1000000001",
    State = "CO", PE_or_Not = "PE", `Matched Pair ID` = "1",
    check.names = FALSE), src)

  mysterycall_export_gsheet_caller_list(src, out, verbose = FALSE)
  raw <- readBin(out, "raw", n = file.info(out)$size)
  expect_true(any(raw == as.raw(0x0d)))          # contains CR
})

test_that("backup is written once and originals are preserved", {
  src    <- withr::local_tempfile(fileext = ".csv")
  out    <- withr::local_tempfile(fileext = ".csv")
  backup <- withr::local_tempfile(fileext = ".csv")
  unlink(backup)                                 # ensure it does not exist yet (silent if absent)
  readr::write_csv(data.frame(
    `Provider Name` = "Dr. A", Phone = "111", NPI = "1000000001",
    State = "CO", PE_or_Not = "PE", `Matched Pair ID` = "1",
    check.names = FALSE), src)

  writeLines("original contents", out)
  mysterycall_export_gsheet_caller_list(src, out, backup = backup, verbose = FALSE)
  expect_true(file.exists(backup))
  expect_equal(readLines(backup), "original contents")
})

test_that("missing required columns raise an error", {
  src <- withr::local_tempfile(fileext = ".csv")
  out <- withr::local_tempfile(fileext = ".csv")
  readr::write_csv(data.frame(`Provider Name` = "Dr. A", check.names = FALSE), src)
  expect_error(
    mysterycall_export_gsheet_caller_list(src, out, verbose = FALSE),
    "subset")
})
