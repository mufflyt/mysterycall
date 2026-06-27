#' Build a Manuscript-Ready Demographics Sentence
#'
#' For each supplied column, finds the modal (most common) non-NA level, its
#' count, the total non-NA count, and the percentage. The results are assembled
#' into a single manuscript-ready sentence. Clauses for subspecialty and
#' credential can be suppressed by passing `NULL` to the corresponding column
#' argument.
#'
#' @param data A data frame.
#' @param gender_col Character scalar. Column name for physician gender.
#'   Default `"gender"`.
#' @param subspecialty_col Character scalar or `NULL`. Column name for
#'   subspecialty. Pass `NULL` to omit that clause. Default `"Subspecialty"`.
#' @param credential_col Character scalar or `NULL`. Column name for
#'   professional credential/qualification. Pass `NULL` to omit. Default
#'   `"Provider.Credential.Text"`.
#' @param digits Integer. Decimal places for percentages. Default `1`.
#' @param label_gender Character. Human-readable label for the gender clause.
#'   Default `"physician gender"`.
#' @param label_subspecialty Character. Human-readable label for the
#'   subspecialty clause. Default `"subspecialty"`.
#' @param label_credential Character. Human-readable label for the credential
#'   clause. Default `"professional qualification"`.
#'
#' @return A character scalar (the sentence, visibly). The per-column summary
#'   statistics are attached as attribute `"stats"` (a named list with elements
#'   `$gender`, `$subspecialty`, `$credential`, each a list with fields
#'   `level`, `count`, `total`, `pct`). Invisibly, the full named list is also
#'   available via `attr(result, "stats")`.
#'
#' @family descriptive helpers
#' @importFrom dplyr group_by summarise arrange desc slice n
#' @importFrom scales comma
#' @export
#'
#' @examples
#' df <- data.frame(
#'   gender                   = c("Male", "Male", "Female", "Male"),
#'   Subspecialty             = c("REI", "MFM", "REI", "REI"),
#'   Provider.Credential.Text = c("MD", "DO", "MD", "MD"),
#'   stringsAsFactors = FALSE
#' )
#' sent <- mysterycall_demographics_sentence(df)
#' cat(sent)
mysterycall_demographics_sentence <- function(
    data,
    gender_col        = "gender",
    subspecialty_col  = "Subspecialty",
    credential_col    = "Provider.Credential.Text",
    digits            = 1L,
    label_gender      = "physician gender",
    label_subspecialty = "subspecialty",
    label_credential  = "professional qualification") {

  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  if (!is.character(gender_col) || length(gender_col) != 1L)
    stop("`gender_col` must be a single character string.", call. = FALSE)
  if (!gender_col %in% names(data))
    stop(sprintf("Column '%s' not found in `data`.", gender_col), call. = FALSE)

  # Helper: compute modal-level stats for one column
  .modal_stats <- function(col_name) {
    vals  <- data[[col_name]]
    vals  <- vals[!is.na(vals)]
    total <- length(vals)
    if (total == 0L)
      return(list(level = NA_character_, count = 0L, total = 0L, pct = NA_real_))
    tbl   <- sort(table(vals), decreasing = TRUE)
    level <- names(tbl)[1L]
    count <- as.integer(tbl[1L])
    pct   <- count / total * 100
    list(level = level, count = count, total = total, pct = pct)
  }

  # Gender (required)
  g <- .modal_stats(gender_col)

  # Subspecialty (optional)
  if (!is.null(subspecialty_col)) {
    if (!subspecialty_col %in% names(data))
      stop(sprintf("Column '%s' not found in `data`.", subspecialty_col),
           call. = FALSE)
    s <- .modal_stats(subspecialty_col)
  } else {
    s <- NULL
  }

  # Credential (optional)
  if (!is.null(credential_col)) {
    if (!credential_col %in% names(data))
      stop(sprintf("Column '%s' not found in `data`.", credential_col),
           call. = FALSE)
    cr <- .modal_stats(credential_col)
  } else {
    cr <- NULL
  }

  # Build sentence dynamically
  gender_clause <- sprintf(
    "the most common %s was %s (n = %s/N = %s, %.*f%%)",
    label_gender,
    g$level,
    scales::comma(g$count),
    scales::comma(g$total),
    digits,
    g$pct
  )

  clauses <- gender_clause

  if (!is.null(s)) {
    sub_clause <- sprintf(
      "the predominant %s observed was %s (n = %s/N = %s, %.*f%%)",
      label_subspecialty,
      s$level,
      scales::comma(s$count),
      scales::comma(s$total),
      digits,
      s$pct
    )
    clauses <- c(clauses, sub_clause)
  }

  if (!is.null(cr)) {
    cred_clause <- sprintf(
      "the most prevalent %s was %s (n = %s/N = %s, %.*f%%)",
      label_credential,
      cr$level,
      scales::comma(cr$count),
      scales::comma(cr$total),
      digits,
      cr$pct
    )
    clauses <- c(clauses, cred_clause)
  }

  sentence <- paste0(
    "In our dataset, ",
    paste(clauses, collapse = ". Additionally, "),
    "."
  )

  message(sentence)

  stats_list <- list(
    gender       = g,
    subspecialty = s,
    credential   = cr
  )

  result <- sentence
  attr(result, "stats") <- stats_list
  result
}
