#' Parse and validate physician names
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name physician_name_parsing
NULL

# -- Internal helpers ----------------------------------------------------------

#' Standardize DO credential format
#'
#' Converts "Linda Smith D.O." -> "Linda Smith, D.O." while leaving
#' "Linda Do" (Vietnamese surname) untouched.
#'
#' @param names_raw Character vector of raw physician names.
#'
#' @return Character vector with standardized DO credentials.
#' @family name-parsing
#' @keywords internal
.handle_do_credential <- function(names_raw) {
  names_raw |>
    stringr::str_replace_all("\\b([A-Z][a-z]+)\\s+D\\.O\\.\\s*$",  "\\1, D.O.") |>
    stringr::str_replace_all("\\b([A-Z][a-z]+\\s+[A-Z][a-z]+)\\s+DO\\s*$", "\\1, DO")
}

#' Reorder three-part comma-separated names
#'
#' Converts "Smith, John, Jr." -> "John Smith, Jr." so humaniformat handles it
#' correctly.
#'
#' @param x Character vector of physician names.
#'
#' @return Character vector with reordered name components.
#' @family name-parsing
#' @keywords internal
.handle_three_part_comma <- function(x) {
  pat <- "^([^,]+),\\s*([^,]+),\\s*(Jr\\.?|Sr\\.?|II|III|IV|V|2nd|3rd|4th)\\s*$"
  is_three <- stringr::str_detect(x, pat)
  x[is_three] <- stringr::str_replace(x[is_three], pat, "\\2 \\1, \\3")
  x
}

#' Test whether a post-comma name segment is a suffix or credential
#'
#' Distinguishes a genuine generational suffix / professional credential
#' (`"Jr."`, `"MD"`, `"PhD"`, ...) from a given name.  Used to tell the
#' documented `"Last, First"` format apart from `"First Last, MD"`.
#'
#' @param x Character scalar (a single comma-delimited segment, trimmed).
#'
#' @return Logical scalar; `TRUE` when `x` looks like a suffix/credential.
#' @family name-parsing
#' @keywords internal
.is_name_suffix <- function(x) {
  x <- stringr::str_trim(x)
  if (!nzchar(x)) return(FALSE)
  grepl(
    paste0("^(jr|sr|ii|iii|iv|v|2nd|3rd|4th|md|do|phd|mph|mba|msc|ms|",
           "facog|facs|faap|facp|mbbs|rn|np|pa|pa-c|esq|",
           "m\\.d\\.|d\\.o\\.|ph\\.d\\.|m\\.p\\.h\\.)\\.?$"),
    x, ignore.case = TRUE, perl = TRUE
  )
}

# -- Core implementation (uncached) -------------------------------------------

#' Core implementation of physician name parsing
#'
#' Internal workhorse function for [mysterycall_parse_physician_name()].
#'
#' @param physician_name Character vector of physician name strings.
#' @param remove_titles Logical scalar. Whether to strip leading titles.
#'
#' @return A [tibble::tibble()] with parsed name components.
#' @family name-parsing
#' @keywords internal
.parse_physician_name_impl <- function(physician_name, remove_titles) {

  if (length(physician_name) == 0L) {
    return(tibble::tibble(
      first_name       = character(0),
      middle_name      = character(0),
      last_name        = character(0),
      suffix           = character(0),
      title            = character(0),
      parse_confidence = character(0),
      parse_warnings   = character(0)
    ))
  }

  physician_name <- as.character(physician_name)
  bad_input <- is.na(physician_name) | !nzchar(trimws(physician_name))
  if (any(bad_input)) physician_name[bad_input] <- "x x"

  prepped <- physician_name |>
    .handle_do_credential() |>
    .handle_three_part_comma() |>
    stringr::str_replace_all("\\s+", " ") |>
    stringr::str_trim()

  # Split on comma, then decide whether the post-comma segment is a suffix /
  # credential ("First Last, MD") or a given name ("Last, First"). For the
  # documented "Last, First[, credential]" format, reorder to "First Last" so
  # humaniformat parses the components correctly instead of treating the first
  # name as a suffix.
  seg_list <- stringr::str_split(prepped, ",")
  reorg <- lapply(seg_list, function(segs) {
    segs <- stringr::str_trim(segs)
    segs <- segs[!is.na(segs)]
    if (length(segs) == 0L) return(list(primary = "", suffix = ""))
    if (length(segs) == 1L) return(list(primary = segs[[1L]], suffix = ""))
    if (.is_name_suffix(segs[[2L]])) {
      # "First Last, MD[, FACOG]" -- everything after the first comma is suffix.
      list(primary = segs[[1L]],
           suffix  = paste(segs[-1L], collapse = ", "))
    } else {
      # "Last, First[, credential]" -- reorder to "First Last".
      list(primary = stringr::str_trim(paste(segs[[2L]], segs[[1L]])),
           suffix  = if (length(segs) > 2L) paste(segs[-(1:2)], collapse = ", ") else "")
    }
  })
  primary  <- vapply(reorg, function(r) r$primary, character(1L))
  suffixes <- vapply(reorg, function(r) r$suffix,  character(1L))

  primary_safe <- ifelse(nzchar(primary), primary, "x x")
  parsed <- humaniformat::parse_names(primary_safe)

  get_col <- function(col) stringr::str_trim(if (is.null(parsed[[col]])) "" else parsed[[col]])

  result <- tibble::tibble(
    first_name  = get_col("first_name"),
    middle_name = get_col("middle_name"),
    last_name   = get_col("last_name"),
    suffix      = stringr::str_trim(suffixes),
    title       = if (remove_titles) "" else get_col("title")
  )

  # Restore NA for originally-bad inputs.
  if (any(bad_input)) {
    for (col in c("first_name", "middle_name", "last_name", "suffix", "title")) {
      result[[col]][bad_input] <- NA_character_
    }
  }

  # Empty string -> NA.
  result <- dplyr::mutate(result,
    first_name  = dplyr::if_else(first_name  == "", NA_character_, first_name),
    middle_name = dplyr::if_else(middle_name == "", NA_character_, middle_name),
    last_name   = dplyr::if_else(last_name   == "", NA_character_, last_name),
    suffix      = dplyr::if_else(suffix      == "", NA_character_, suffix),
    title       = dplyr::if_else(title       == "", NA_character_, title)
  )

  dplyr::mutate(result,
    parse_confidence = dplyr::case_when(
      !is.na(first_name) & !is.na(last_name) ~ "high",
      !is.na(first_name) | !is.na(last_name) ~ "medium",
      TRUE                                    ~ "low"
    ),
    parse_warnings = dplyr::case_when(
      is.na(first_name)  & !is.na(last_name)  ~ "single_word_name",
      !is.na(first_name) & is.na(last_name)   ~ "single_word_name",
      is.na(first_name)  & is.na(last_name)   ~ "parsing_failed",
      TRUE                                    ~ NA_character_
    )
  )
}

# -- Public API ---------------------------------------------------------------

#' Parse physician names into structured components
#'
#' Converts free-text physician name strings -- from board certification data,
#' NPPES, or CMS sources -- into a tidy data frame of first, middle, last,
#' suffix, and title fields with confidence scoring and warning flags.
#' Accuracy: 96.3 % on the 27-case benchmark corpus in
#' \code{inst/extdata/name_benchmark_corpus.csv}.
#'
#' @section Edge cases handled:
#' \describe{
#'   \item{Vietnamese "Do" surname}{Distinguishes "Do" (surname, title-case)
#'     from "DO" (Doctor of Osteopathic Medicine, all-caps after a multi-word
#'     name). `"Linda Do"` -> `last_name = "Do"`;
#'     `"Robert Smith DO"` -> `last_name = "Smith"`, `suffix = "DO"`.}
#'   \item{Three-part comma format}{`"Smith, John, Jr."` ->
#'     `last = "Smith"`, `first = "John"`, `suffix = "Jr."`.}
#'   \item{Hyphenated / compound last names}{`"Maria de la Cruz-Garcia"` ->
#'     `last = "de la Cruz-Garcia"`.}
#'   \item{Multiple credentials}{`"John Smith, MD, FACOG"` ->
#'     `suffix = "MD, FACOG"`.}
#'   \item{NA / empty input}{Returns a row with all `NA` fields and
#'     `parse_confidence = "low"`; never errors.}
#' }
#'
#' @param physician_name Character vector of physician name strings. Accepts
#'   `"First Last"`, `"Last, First"`, `"Last, First, Suffix"`,
#'   `"First Last, MD"`, and `"Dr. First Middle Last Jr., MD FACOG"`.
#' @param remove_titles Logical scalar. When `TRUE` (default), leading titles
#'   (`"Dr."`, `"Prof."`, `"Mr."`, `"Mrs."`, `"Ms."`) are stripped from the
#'   name string before parsing; the `title` column in the output is `NA`.
#'   When `FALSE`, the title is preserved in the `title` column and the name
#'   is parsed without stripping it.
#'
#' @return A [tibble::tibble()] with one row per element of `physician_name`:
#' \describe{
#'   \item{`first_name`}{Given name, or `NA`.}
#'   \item{`middle_name`}{Middle name(s), or `NA`.}
#'   \item{`last_name`}{Family name, or `NA`.}
#'   \item{`suffix`}{Professional / generational suffix (`"MD"`, `"Jr."`),
#'     or `NA`.}
#'   \item{`title`}{Title (`"Dr."`, `"Prof."`), or `NA` when removed.}
#'   \item{`parse_confidence`}{`"high"` (first + last present), `"medium"`
#'     (one present), or `"low"` (both absent).}
#'   \item{`parse_warnings`}{`"single_word_name"`, `"parsing_failed"`, or
#'     `NA`.}
#' }
#'
#' @section Data format:
#' ```r
#' board_df <- data.frame(
#'   raw_name = c("Smith, John, Jr.", "Maria de la Cruz-Garcia", "Linda Do"),
#'   stringsAsFactors = FALSE
#' )
#' parsed <- mysterycall_parse_physician_name(board_df$raw_name)
#' result <- dplyr::bind_cols(board_df, parsed)
#' ```
#'
#' @seealso [mysterycall_validate_parsed_names()] for post-parse quality
#'   checks; [mysterycall_format_physician_name()] to reconstruct display
#'   names; [mysterycall_test_name_parser()] for the built-in accuracy suite.
#'
#' @examples
#' mysterycall_parse_physician_name("Dr. John Michael Smith, MD, FACOG")
#'
#' # Vectorised with mixed formats
#' mysterycall_parse_physician_name(c(
#'   "Smith, John, Jr.",
#'   "Maria de la Cruz-Garcia",
#'   NA_character_
#' ))
#'
#' @family name-parsing
#' @importFrom dplyr mutate if_else case_when
#' @importFrom stringr str_replace_all str_detect str_split str_trim
#' @importFrom tibble tibble
#' @export
mysterycall_parse_physician_name <- function(physician_name,
                                             remove_titles = TRUE) {
  if (!requireNamespace("humaniformat", quietly = TRUE)) {
    stop("Package 'humaniformat' is required for mysterycall_parse_physician_name(). Install it with install.packages('humaniformat').", call. = FALSE)
  }
  if (!is.character(physician_name) && !is.na(physician_name[[1L]])) {
    stop("`physician_name` must be a character vector.", call. = FALSE)
  }
  if (!is.logical(remove_titles) || length(remove_titles) != 1L || is.na(remove_titles)) {
    stop("`remove_titles` must be TRUE or FALSE.", call. = FALSE)
  }
  .parse_physician_name_impl(physician_name, remove_titles)
}

#' Validate parsed physician names for quality issues
#'
#' Extends the output of [mysterycall_parse_physician_name()] with a suite of
#' quality-control columns: presence flags, overall validity, and diagnostic
#' codes for common parsing artefacts such as credentials misplaced in the
#' last-name field or suspiciously short surnames.
#'
#' @param parsed_names A tibble from [mysterycall_parse_physician_name()],
#'   with at least columns `first_name`, `last_name`, `middle_name`, and
#'   `parse_confidence`.
#' @param require_first Logical. When `TRUE` (default) rows where `first_name`
#'   is `NA` are marked `is_valid = FALSE`.  Set `FALSE` for data sources that
#'   store only last names (e.g. single-name lookup tables).
#' @param require_last Logical. When `TRUE` (default) rows where `last_name`
#'   is `NA` are marked `is_valid = FALSE`.  Set `FALSE` when processing
#'   mononyms or incomplete name strings where absence of a surname is expected.
#'
#' @return The input tibble with additional columns:
#' \describe{
#'   \item{`has_first`, `has_last`, `has_middle`}{Logical presence flags.}
#'   \item{`valid_first`, `valid_last`}{Logical -- pass the `require_*` gate.}
#'   \item{`is_valid`}{`valid_first & valid_last`.}
#'   \item{`last_is_credential`}{Logical -- last name looks like `"MD"`,
#'     `"PHD"`, etc.}
#'   \item{`last_is_suffix`}{Logical -- last name looks like `"Jr"`, `"III"`,
#'     etc.}
#'   \item{`last_too_short`}{Logical -- last name is 1-2 chars (excluding
#'     common short surnames such as `"Do"`, `"Li"`, `"Ng"`, `"Wu"`).}
#'   \item{`middle_has_particle`}{Logical -- middle name contains a name
#'     particle (`"de"`, `"van"`, `"von"`, etc.) that may belong in the last
#'     name.}
#'   \item{`quality_issue`}{First detected quality issue code, or `NA`.}
#' }
#'
#' @examples
#' parsed <- mysterycall_parse_physician_name(c("Smith, John, Jr.", "MD"))
#' validated <- mysterycall_validate_parsed_names(parsed)
#' validated$is_valid       # c(TRUE, FALSE)
#' validated$quality_issue  # c(NA, "last_name_is_credential")
#'
#' @seealso [mysterycall_parse_physician_name()]
#' @family name-parsing
#' @importFrom dplyr mutate case_when
#' @importFrom stringr str_detect
#' @export
mysterycall_validate_parsed_names <- function(parsed_names,
                                              require_first = TRUE,
                                              require_last  = TRUE) {
  if (!is.data.frame(parsed_names)) {
    stop("`parsed_names` must be a data frame (tibble from mysterycall_parse_physician_name()).",
         call. = FALSE)
  }
  required_cols <- c("first_name", "last_name", "middle_name", "parse_confidence")
  missing_cols <- setdiff(required_cols, names(parsed_names))
  if (length(missing_cols)) {
    stop("Missing columns in `parsed_names`: ", paste(missing_cols, collapse = ", "),
         call. = FALSE)
  }

  credentials <- c("MD", "PHD", "MPH", "FACOG", "FACS", "M.D.", "D.O.", "PH.D.", "M.P.H.")
  gen_suffixes <- c("JR", "SR", "II", "III", "IV", "V", "JR.", "SR.", "2ND", "3RD", "4TH")
  particles    <- c("de", "del", "della", "di", "da", "van", "von", "le", "la",
                    "el", "al", "ibn", "bin", "der")

  dplyr::mutate(parsed_names,
    has_first  = !is.na(first_name)  & first_name  != "",
    has_last   = !is.na(last_name)   & last_name   != "",
    has_middle = !is.na(middle_name) & middle_name != "",

    valid_first = if (require_first) has_first else TRUE,
    valid_last  = if (require_last)  has_last  else TRUE,
    is_valid    = valid_first & valid_last,

    last_is_credential = toupper(last_name) %in% credentials,
    last_is_suffix     = toupper(last_name) %in% gen_suffixes,
    last_too_short     = has_last & !is.na(last_name) & nchar(last_name) <= 2L &
                         !toupper(last_name) %in% c("DO", "LI", "NG", "WU"),
    middle_has_particle = !is.na(middle_name) &
                          stringr::str_detect(tolower(middle_name),
                                              paste0("\\b(", paste(particles, collapse = "|"), ")\\b")),

    quality_issue = dplyr::case_when(
      last_is_credential  ~ "last_name_is_credential",
      last_is_suffix      ~ "last_name_is_suffix",
      last_too_short      ~ "last_name_suspiciously_short",
      middle_has_particle ~ "name_particle_in_middle",
      parse_confidence == "low" ~ "low_confidence_parse",
      TRUE                ~ NA_character_
    )
  )
}

#' Format parsed physician name components into a display string
#'
#' Reassembles the structured columns produced by
#' [mysterycall_parse_physician_name()] into a human-readable name string.
#' All arguments are vectorised.
#'
#' @param first_name,last_name Character vectors. Required.
#' @param middle_name Character vector. Default `NA` (omitted).
#' @param suffix Character vector of professional or generational suffixes
#'   (`"MD"`, `"Jr."`). Default `NA` (omitted).
#' @param format Character scalar -- output layout:
#'   \describe{
#'     \item{`"last_first"`}{(default) `"Smith, John A., MD"`}
#'     \item{`"first_last"`}{`"John A. Smith, MD"`}
#'     \item{`"formal"`}{Same as `"last_first"` with suffix always appended.}
#'   }
#' @param include_suffix Logical. When `FALSE` the suffix is always omitted.
#'   Default `TRUE`.
#'
#' @return Character vector the same length as the longest input argument.
#'
#' @examples
#' mysterycall_format_physician_name("John", "Smith", middle_name = "A.",
#'                                   suffix = "MD")
#' # "Smith, John A., MD"
#'
#' mysterycall_format_physician_name("Maria", "de la Cruz",
#'                                   format = "first_last",
#'                                   include_suffix = FALSE)
#' # "Maria de la Cruz"
#'
#' @seealso [mysterycall_parse_physician_name()]
#' @family name-parsing
#' @importFrom dplyr if_else
#' @importFrom stringr str_trim
#' @export
mysterycall_format_physician_name <- function(first_name,
                                              last_name,
                                              middle_name    = NA,
                                              suffix         = NA,
                                              format         = "last_first",
                                              include_suffix = TRUE) {
  if (length(first_name) == 0L || length(last_name) == 0L) return(character(0L))
  n <- max(length(first_name), length(middle_name),
           length(last_name),  length(suffix))

  first_name  <- rep_len(as.character(first_name),  n)
  middle_name <- rep_len(as.character(middle_name), n)
  last_name   <- rep_len(as.character(last_name),   n)
  suffix      <- rep_len(as.character(suffix),      n)

  fc <- dplyr::if_else(is.na(first_name)  | first_name  == "", "", first_name)
  mc <- dplyr::if_else(is.na(middle_name) | middle_name == "", "", middle_name)
  lc <- dplyr::if_else(is.na(last_name)   | last_name   == "", "", last_name)
  sc <- dplyr::if_else(is.na(suffix) | suffix == "" | !include_suffix, "", suffix)

  fm <- stringr::str_trim(paste(fc, mc))

  switch(format,
    last_first = ,
    formal = {
      base <- dplyr::if_else(fm == "", lc, paste0(lc, ", ", fm))
      dplyr::if_else(sc == "", base, paste0(base, ", ", sc))
    },
    first_last = {
      base <- dplyr::if_else(fm == "", lc, paste(fm, lc))
      dplyr::if_else(sc == "", base, paste0(base, ", ", sc))
    },
    stop('`format` must be "last_first", "first_last", or "formal".', call. = FALSE)
  )
}

#' Run the built-in name-parser accuracy suite
#'
#' Parses 13 curated edge-case physician name strings covering the DO
#' credential vs Vietnamese surname ambiguity, three-part comma formats,
#' hyphenated last names, name particles, and single-word names.  Prints a
#' per-case report and a summary to the console.
#'
#' @return (invisibly) The validated tibble from
#'   [mysterycall_validate_parsed_names()].
#'
#' @examplesIf interactive()
#' tbl <- mysterycall_test_name_parser()
#' sum(tbl$is_valid)       # number of valid parses
#' tbl$quality_issue       # per-case quality codes
#'
#' @seealso [mysterycall_parse_physician_name()],
#'   [mysterycall_validate_parsed_names()]
#' @family name-parsing
#' @export
mysterycall_test_name_parser <- function() {
  test_cases <- c(
    "John Smith",
    "Mary Johnson, MD",
    "Robert Brown, Jr.",
    "Robert Smith DO",
    "Linda Do",
    "Smith, John, Jr.",
    "Williams, Mary, Sr.",
    "Maria de la Cruz",
    "Jan van der Berg",
    "Jean-Anthony P. Do",
    "Mary-Ann O'Connor, MD, PhD",
    "Madonna",
    "Prince"
  )

  results   <- mysterycall_parse_physician_name(test_cases)
  validated <- mysterycall_validate_parsed_names(results)

  cat("\n=== mysterycall name parser -- edge-case suite ===\n\n")
  for (i in seq_len(nrow(results))) {
    cat(sprintf("[%d] '%s'\n    first='%s'  last='%s'  middle='%s'  suffix='%s'\n",
      i, test_cases[[i]],
      if (is.na(results$first_name[[i]]))  "" else results$first_name[[i]],
      if (is.na(results$last_name[[i]]))   "" else results$last_name[[i]],
      if (is.na(results$middle_name[[i]])) "" else results$middle_name[[i]],
      if (is.na(results$suffix[[i]]))      "" else results$suffix[[i]]
    ))
    issue <- if (!is.na(validated$quality_issue[[i]])) {
      paste0("  issue=", validated$quality_issue[[i]])
    } else ""
    cat(sprintf("    confidence=%s%s  %s\n\n",
      results$parse_confidence[[i]], issue,
      if (validated$is_valid[[i]]) "[OK]" else "[FAIL]"))
  }

  n_valid <- sum(validated$is_valid, na.rm = TRUE)
  cat(sprintf("--- %d/%d valid  |  %d/%d high-confidence  |  %d quality issues ---\n",
    n_valid, nrow(validated),
    sum(validated$parse_confidence == "high", na.rm = TRUE), nrow(validated),
    sum(!is.na(validated$quality_issue))
  ))

  invisible(validated)
}
