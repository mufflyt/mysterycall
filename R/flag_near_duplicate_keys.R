#' Flag near-duplicate cluster keys (likely mistyped grouping values)
#'
#' A random-intercept mystery-caller analysis clusters calls by a practice /
#' cluster key. When that key is entered by hand across data-collection waves, a
#' single mistyped character (`"Aurora Womens Health"` vs.
#' `"Aurora Women's Health"`) splits one practice into two, silently corrupting
#' the estimated random-effect variance and deflating every paired denominator
#' (see [mysterycall_scenario_coverage()]). Exact-duplicate checks
#' ([mysterycall_check_duplicates()]) cannot catch this because the strings
#' differ. This scans all unique keys with an edit-distance
#' ([utils::adist()]) and returns the pairs that are close enough to be worth a
#' human's eyes -- a loud safety net rather than a silent singleton.
#'
#' A pair is flagged when its raw edit distance is at most `max_edit` **or** its
#' length-normalized distance (edit distance / longer key length) is at most
#' `max_norm`. The `OR` catches both short keys a few characters apart and long
#' keys differing by a small fraction. Comparison is case- and
#' whitespace-insensitive by default; feed keys already run through
#' [mysterycall_normalize_org_name()] to cut false positives.
#'
#' @param keys Character vector of cluster keys (or a data-frame column). Missing
#'   and empty entries are dropped before comparison.
#' @param max_edit Integer. Flag a pair when its raw edit distance is at most
#'   this. Default `4L`.
#' @param max_norm Numeric in `[0, 1]`. Flag a pair when its normalized edit
#'   distance is at most this. Default `0.15`.
#' @param ignore_case Logical; compare case-insensitively. Default `TRUE`.
#' @param output_dir,filename Optional CSV export of the flagged pairs.
#'   `output_dir = NA` (default) skips writing; `NULL` writes to a session temp
#'   directory via [mysterycall_tempdir()].
#'
#' @return A [tibble::tibble()] with one row per flagged pair -- columns `key_a`,
#'   `key_b`, `edit_distance` (integer), `norm_distance` (rounded to 3) -- sorted
#'   by `edit_distance` then `norm_distance`. Zero rows (with the same columns)
#'   when nothing is flagged.
#'
#' @family data integrity
#' @seealso [mysterycall_check_duplicates()], [mysterycall_normalize_org_name()],
#'   [mysterycall_scenario_coverage()]
#' @examples
#' keys <- c("Aurora Womens Health", "Aurora Women's Health",
#'           "Denver Fertility", "Boulder OBGYN")
#' mysterycall_flag_near_duplicate_keys(keys)
#' @export
mysterycall_flag_near_duplicate_keys <- function(keys, max_edit = 4L,
                                                max_norm = 0.15,
                                                ignore_case = TRUE,
                                                output_dir = NA,
                                                filename = NA) {
  checkmate::assert_atomic_vector(keys, min.len = 1L)
  checkmate::assert_count(max_edit)
  checkmate::assert_number(max_norm, lower = 0, upper = 1)
  checkmate::assert_flag(ignore_case)

  keys <- as.character(keys)
  keys <- unique(keys[!is.na(keys) & nzchar(trimws(keys))])

  empty <- tibble::tibble(
    key_a = character(), key_b = character(),
    edit_distance = integer(), norm_distance = numeric()
  )

  if (length(keys) >= 2L) {
    cmp <- if (ignore_case) toupper(keys) else keys
    dm  <- utils::adist(cmp)
    idx <- utils::combn(length(keys), 2L)
    d   <- dm[t(idx)]
    len <- pmax(nchar(keys[idx[1, ]]), nchar(keys[idx[2, ]]))
    nd  <- d / len
    keep <- d <= max_edit | nd <= max_norm
    if (any(keep)) {
      hits <- tibble::tibble(
        key_a         = keys[idx[1, ]][keep],
        key_b         = keys[idx[2, ]][keep],
        edit_distance = as.integer(d[keep]),
        norm_distance = round(nd[keep], 3)
      )
      hits <- hits[order(hits$edit_distance, hits$norm_distance), ]
    } else {
      hits <- empty
    }
  } else {
    hits <- empty
  }

  if (!identical(output_dir, NA)) {
    dir <- if (is.null(output_dir)) mysterycall_tempdir() else output_dir
    fname <- if (is.na(filename)) "near_duplicate_keys.csv" else filename
    utils::write.csv(hits, file.path(dir, fname), row.names = FALSE)
  }

  hits
}
