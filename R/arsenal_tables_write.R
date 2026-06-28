#' Writes an Arsenal summary table to a Word document
#'
#' @param object A data frame (e.g. the output of [arsenal::summary.tableby()])
#'   to write. Must be a data frame  --  the function will error otherwise.
#' @param filename The filename without extension for the Word document.
#' @param output_dir Directory where the Word document should be written.
#'   Defaults to a session-specific folder inside [tempdir()].
#' @return Invisibly returns `NULL`. Called for the side effect of writing
#'   `<filename>.docx` to `output_dir`.
#' @family table
#' @seealso [mysterycall_write_table_pdf()], [mysterycall_table_overall()]
#' @export
#'
#' @examplesIf interactive()
#' mysterycall_write_arsenal_table(my_table, "output_table")
mysterycall_write_arsenal_table <- function(object, filename, output_dir = NULL) {
  if (!requireNamespace("arsenal", quietly = TRUE)) {
    stop(
      "This function requires the arsenal package.\n",
      "Install it with: install.packages(\"arsenal\")",
      call. = FALSE
    )
  }
  if (!is.data.frame(object)) {
    stop(sprintf("'object' must be a data frame, not %s.", class(object)[1L]), call. = FALSE)
  }
  if (!is.character(filename)) {
    stop(sprintf("'filename' must be a character string, not %s.", class(filename)[1L]), call. = FALSE)
  }

  if (is.null(output_dir)) {
    output_dir <- mysterycall_tempdir("tables", create = TRUE)
  } else if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Create full path for the Word file
  word_path <- file.path(output_dir, paste0(filename, ".docx"))

  message("Creating Arsenal table as a Word document...")
  tryCatch({
    arsenal::write2word(
      object,
      file = word_path,
      keep.md = FALSE,
      quiet = TRUE
    )
  }, error = function(e) {
    stop("Error occurred while writing to Word document: ", e$message, call. = FALSE)
  })

  # Print the full path to the saved file
  message("Word file saved successfully at ", word_path)
}
