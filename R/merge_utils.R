#' Merge two data frames with source-prefixed column names
#'
#' @name mysterycall_merge_with_prefix
NULL

#' Merge two data frames and prefix non-key columns to show their origin
#'
#' Renames all non-key columns in `x` with `prefix_x` and all non-key
#' columns in `y` with `prefix_y`, then performs a left join on `by`.
#' This keeps columns traceable (e.g. `findent_state` vs `abohns_state`)
#' when two data sources are combined.
#'
#' @param x A data frame (left table).
#' @param y A data frame (right table).
#' @param by Character vector of column names to join on. These columns are
#'   NOT prefixed.
#' @param prefix_x Character scalar prefix applied to non-key columns of `x`.
#'   Default `"x_"`.
#' @param prefix_y Character scalar prefix applied to non-key columns of `y`.
#'   Default `"y_"`.
#' @param join_type One of `"left"` (default), `"inner"`, `"full"`, or
#'   `"right"`.
#'
#' @return A data frame in this column order: (1) join key columns (names
#'   unchanged), (2) non-key columns of `x` with `prefix_x` prepended (e.g.
#'   `"specialty"` becomes `"npi_specialty"`), (3) non-key columns of `y` with
#'   `prefix_y` prepended. Row order follows base R `merge()` (sorted by key).
#'   For `join_type = "left"`, unmatched `y` columns are `NA`.
#'
#' @seealso [mysterycall_safe_left_join()] for joins with duplicate-key
#'   warnings; [mysterycall_reconcile_specialty()] for post-join specialty
#'   harmonization.
#' @family data management
#' @keywords internal
#'
#' @examples
#' registry <- data.frame(npi = c("A","B"), state = c("CO","TX"),
#'                        specialty = c("ENT","ENT"), stringsAsFactors = FALSE)
#' abohns    <- data.frame(npi = c("A","C"), cert = c("Neurotology",NA),
#'                         stringsAsFactors = FALSE)
#' mysterycall:::mysterycall_merge_with_prefix(registry, abohns, by = "npi",
#'                                prefix_x = "npi_", prefix_y = "abohns_")
mysterycall_merge_with_prefix <- function(x, y, by,
                                           prefix_x   = "x_",
                                           prefix_y   = "y_",
                                           join_type  = c("left","inner","full","right")) {
  join_type <- match.arg(join_type)
  if (!is.data.frame(x))                   stop("`x` must be a data frame.", call. = FALSE)
  if (!is.data.frame(y))                   stop("`y` must be a data frame.", call. = FALSE)
  missing_x <- setdiff(by, names(x))
  missing_y <- setdiff(by, names(y))
  if (length(missing_x) > 0L) stop("Join key(s) not in x: ", paste(missing_x, collapse=", "), call. = FALSE)
  if (length(missing_y) > 0L) stop("Join key(s) not in y: ", paste(missing_y, collapse=", "), call. = FALSE)

  rename_non_key <- function(df, prefix, by_cols) {
    nms     <- names(df)
    non_key <- setdiff(nms, by_cols)
    names(df)[match(non_key, nms)] <- paste0(prefix, non_key)
    df
  }

  x2 <- rename_non_key(x, prefix_x, by)
  y2 <- rename_non_key(y, prefix_y, by)

  switch(join_type,
    left  = merge(x2, y2, by = by, all.x = TRUE),
    inner = merge(x2, y2, by = by, all   = FALSE),
    full  = merge(x2, y2, by = by, all   = TRUE),
    right = merge(x2, y2, by = by, all.y = TRUE)
  )
}
