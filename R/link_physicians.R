#' Probabilistic record linkage of two physician lists without a shared key
#'
#' Audit sampling frames often must be reconciled against an external roster --
#' a called cohort against a Medicaid-acceptance list, applicants against a
#' resident roster -- when neither carries an NPI or any other unique key, only
#' names. Exact-name joins miss `"Katherine"` vs `"Kathryn"` and every
#' transposition; a deterministic join over-links common surnames. This wraps
#' \pkg{fastLink}'s Fellegi-Sunter linkage with Jaro-Winkler string comparison
#' on the name fields, optional blocking to keep the comparison space tractable,
#' and returns the matched pairs with their posterior match probability so a
#' human can review the borderline ones. Use it when you have names but no NPI;
#' when you have (or can look up) an NPI, prefer
#' [mysterycall_search_and_process_npi()] / [mysterycall_enrich_npi()].
#'
#' Requires the \pkg{fastLink} package.
#'
#' @param df_a,df_b The two data frames to link.
#' @param name_cols Character vector of the shared name columns to match on
#'   (must exist in both frames), e.g. `c("first_name", "last_name")`.
#' @param block_var Optional character scalar naming a column present in both
#'   frames to block on (e.g. `"state"`): only records sharing a block value are
#'   compared, which makes large linkages feasible. Default `NULL` (no blocking).
#' @param threshold Posterior-probability cutoff for calling a pair a match.
#'   Default `0.85`.
#' @param jw_weight Jaro-Winkler prefix weight passed to
#'   `fastLink::fastLink()`. Default `0.25`.
#' @param partial_match Logical; allow partial string agreement. Default `TRUE`.
#'
#' @return A [tibble::tibble()] of matched pairs -- the `name_cols` from each
#'   frame (suffixed `_a` / `_b`), the source row indices `index_a` / `index_b`,
#'   and `posterior` (the match probability) -- sorted descending by
#'   `posterior`. Zero rows when nothing clears `threshold`.
#'
#' @family data integrity
#' @seealso [mysterycall_normalize_org_name()],
#'   [mysterycall_search_and_process_npi()]
#' @examples
#' \donttest{
#' if (requireNamespace("fastLink", quietly = TRUE)) {
#'   a <- data.frame(first_name = c("Katherine", "Robert"),
#'                   last_name  = c("Smith", "Jones"))
#'   b <- data.frame(first_name = c("Kathryn", "Bob"),
#'                   last_name  = c("Smith", "Jones"))
#'   mysterycall_link_physicians(a, b, c("first_name", "last_name"))
#' }
#' }
#' @export
mysterycall_link_physicians <- function(df_a, df_b, name_cols,
                                       block_var = NULL, threshold = 0.85,
                                       jw_weight = 0.25, partial_match = TRUE) {
  checkmate::assert_data_frame(df_a, min.rows = 1L)
  checkmate::assert_data_frame(df_b, min.rows = 1L)
  checkmate::assert_character(name_cols, min.len = 1L, any.missing = FALSE)
  checkmate::assert_subset(name_cols, names(df_a))
  checkmate::assert_subset(name_cols, names(df_b))
  checkmate::assert_string(block_var, null.ok = TRUE)
  checkmate::assert_number(threshold, lower = 0, upper = 1)

  if (!requireNamespace("fastLink", quietly = TRUE)) {
    stop("mysterycall_link_physicians() requires the fastLink package.\n",
         "Install it with: install.packages(\"fastLink\")", call. = FALSE)
  }

  run_pair <- function(a, b, off_a = 0L, off_b = 0L) {
    fl <- fastLink::fastLink(
      dfA = a, dfB = b, varnames = name_cols,
      stringdist.match = name_cols, stringdist.method = "jw",
      jw.weight = jw_weight, partial.match = partial_match,
      dedupe.matches = TRUE, linprog.dedupe = TRUE,
      threshold.match = threshold, verbose = FALSE
    )
    if (is.null(fl$matches) || nrow(fl$matches) == 0L) return(NULL)
    ia <- fl$matches$inds.a
    ib <- fl$matches$inds.b
    out <- tibble::tibble(index_a = ia + off_a, index_b = ib + off_b)
    for (nm in name_cols) {
      out[[paste0(nm, "_a")]] <- a[[nm]][ia]
      out[[paste0(nm, "_b")]] <- b[[nm]][ib]
    }
    out$posterior <- fl$posterior %||% fl$matches$posterior
    out
  }

  if (is.null(block_var)) {
    res <- run_pair(df_a, df_b)
    res <- if (is.null(res)) NULL else list(res)
  } else {
    checkmate::assert_subset(block_var, names(df_a))
    checkmate::assert_subset(block_var, names(df_b))
    blocks <- intersect(unique(as.character(df_a[[block_var]])),
                        unique(as.character(df_b[[block_var]])))
    res <- lapply(blocks, function(bl) {
      ia_idx <- which(as.character(df_a[[block_var]]) == bl)
      ib_idx <- which(as.character(df_b[[block_var]]) == bl)
      if (!length(ia_idx) || !length(ib_idx)) return(NULL)
      out <- run_pair(df_a[ia_idx, , drop = FALSE],
                      df_b[ib_idx, , drop = FALSE])
      if (is.null(out)) return(NULL)
      # Remap within-block indices back to the original row numbers.
      out$index_a <- ia_idx[out$index_a]
      out$index_b <- ib_idx[out$index_b]
      out
    })
  }

  res <- Filter(Negate(is.null), res)
  if (!length(res)) {
    cols <- c("index_a", "index_b",
              as.vector(rbind(paste0(name_cols, "_a"), paste0(name_cols, "_b"))),
              "posterior")
    empty <- tibble::as_tibble(stats::setNames(
      rep(list(logical(0)), length(cols)), cols))
    return(empty)
  }
  out <- do.call(rbind, res)
  out[order(-out$posterior), , drop = FALSE]
}
