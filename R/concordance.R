# Guideline-concordance / reference-standard scoring engine
# -----------------------------------------------------------------------------
# One rubric-driven core that scores what staff *said* or *did* against a
# reference standard, at the item level, then rolls up to call- and study-level
# summaries. Generalises across the counseling-quality / guideline-adherence
# audit literature: a rubric is just a set of typed items, and each study is a
# rubric built from those types.
#
#   binary            value equals a fixed expected value
#   expected_present  the cue/question was elicited at all (value == TRUE)
#   reference_match   value equals a per-row reference column (gold standard
#                     varies by scenario / state / date)
#   evidence_tier     each named option maps to concordant / non-concordant via
#                     a (optionally date-versioned) lookup
# -----------------------------------------------------------------------------


# ---- internal helpers -------------------------------------------------------

# Coerce a heterogeneous yes/no column to logical (TRUE/FALSE/NA).
.mc_as_logical01 <- function(x) {
  if (is.logical(x)) return(x)
  if (is.numeric(x)) {
    out <- rep(NA, length(x))
    out[x == 1] <- TRUE
    out[x == 0] <- FALSE
    return(out)
  }
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA, length(s))
  out[s %in% c("1", "true", "t", "yes", "y")] <- TRUE
  out[s %in% c("0", "false", "f", "no", "n")] <- FALSE
  out
}

# Concordance of a captured value against an expected value. Returns a logical
# vector with NA where the value could not be coded (i.e. not applicable).
.mc_coerce_binary <- function(val, correct) {
  if (is.logical(correct) && length(correct) == 1L) {
    lv <- .mc_as_logical01(val)
    return(lv == correct)
  }
  cv <- as.character(val)
  res <- cv == as.character(correct)
  res[is.na(cv)] <- NA
  res
}

# Split an evidence-tier options column into a list of character vectors.
.mc_parse_options <- function(x, sep) {
  if (is.list(x)) return(lapply(x, function(e) as.character(e)))
  lapply(as.character(x), function(s) {
    if (is.na(s) || !nzchar(trimws(s))) return(character(0))
    trimws(strsplit(s, sep, fixed = TRUE)[[1]])
  })
}

# Subset a tier lookup to the rows in force on a given date.
.mc_tier_in_force <- function(lookup, date) {
  if (is.null(date) || is.na(date) || !("effective_from" %in% names(lookup))) {
    return(lookup)
  }
  ef <- as.Date(lookup$effective_from)
  et <- if ("effective_to" %in% names(lookup)) as.Date(lookup$effective_to) else as.Date(NA)
  keep <- (is.na(ef) | ef <= date) & (is.na(et) | et >= date)
  lookup[keep, , drop = FALSE]
}

# Wilson score interval for a binomial proportion. Returns c(lower, upper).
.mc_wilson_ci <- function(x, n, conf_level = 0.95) {
  if (is.na(n) || n == 0) return(c(NA_real_, NA_real_))
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  phat <- x / n
  denom <- 1 + z^2 / n
  centre <- (phat + z^2 / (2 * n)) / denom
  half <- (z * sqrt(phat * (1 - phat) / n + z^2 / (4 * n^2))) / denom
  c(max(0, centre - half), min(1, centre + half))
}

# Cohen's kappa (+ percent agreement) for two coders on one item.
.mc_cohen_kappa <- function(a, b) {
  ok <- !is.na(a) & !is.na(b)
  a <- a[ok]
  b <- b[ok]
  n <- length(a)
  if (n == 0L) return(c(kappa = NA_real_, pct_agree = NA_real_, n = 0))
  po <- mean(a == b)
  cats <- union(unique(a), unique(b))
  pe <- sum(vapply(cats, function(k) mean(a == k) * mean(b == k), numeric(1)))
  kappa <- if (isTRUE(all.equal(pe, 1))) NA_real_ else (po - pe) / (1 - pe)
  c(kappa = kappa, pct_agree = po, n = n)
}

# Score a single rubric item -> logical vector (NA where not applicable), before
# na_policy is applied.
.mc_score_item <- function(data, item_row, tier_lookup, option_sep, dates) {
  type <- item_row$type
  item <- item_row$item

  if (type %in% c("binary", "expected_present")) {
    return(.mc_coerce_binary(data[[item]], item_row$correct[[1L]]))
  }

  if (type == "reference_match") {
    val <- data[[item]]
    ref <- data[[item_row$reference_col]]
    res <- as.character(val) == as.character(ref)
    res[is.na(val) | is.na(ref)] <- NA
    return(res)
  }

  if (type == "evidence_tier") {
    opts <- .mc_parse_options(data[[item]], option_sep)
    vapply(seq_along(opts), function(i) {
      o <- opts[[i]]
      if (length(o) == 0L) return(NA)
      lk <- .mc_tier_in_force(tier_lookup, if (!is.null(dates)) dates[i] else NULL)
      concordant_opts <- lk$option[lk$tier == "concordant"]
      any(o %in% concordant_opts)
    }, logical(1))
  } else {
    stop("Unknown rubric item type: ", type, call. = FALSE)
  }
}

.mc_recycle <- function(x, n, name) {
  if (length(x) == 1L) return(rep(x, n))
  if (length(x) == n) return(x)
  stop(sprintf("`%s` must have length 1 or %d.", name, n), call. = FALSE)
}


# ---- rubric constructor -----------------------------------------------------

#' Define a Guideline-Concordance Rubric
#'
#' Builds the reference standard that [mysterycall_score_concordance()] scores
#' captured calls against. A rubric is a set of typed items; each study in the
#' mystery-caller counseling / guideline-adherence literature is expressed as a
#' rubric assembled from four item types.
#'
#' @param item Character vector. Machine-readable item ids. Each must match a
#'   column in the captured-call data passed to
#'   [mysterycall_score_concordance()]. Must be unique.
#' @param label Character vector. Manuscript-facing wording per item. Recycled
#'   to `length(item)`. Default: `item`.
#' @param type Character vector. One of `"binary"`, `"expected_present"`,
#'   `"reference_match"`, `"evidence_tier"`. Recycled. Default `"binary"`.
#'   \describe{
#'     \item{`binary`}{Concordant when the value equals `correct`.}
#'     \item{`expected_present`}{Concordant when the cue was elicited at all
#'       (`correct` is forced to `TRUE`).}
#'     \item{`reference_match`}{Concordant when the value equals a per-row
#'       reference column named by `reference_col` (gold standard varies by
#'       scenario / state / date).}
#'     \item{`evidence_tier`}{The value is a set of named options per call;
#'       concordant when it includes at least one option in the `"concordant"`
#'       tier of `tier_lookup`.}
#'   }
#' @param correct Expected value(s) for `binary` items. A scalar (recycled), a
#'   vector of length `length(item)`, or a list. Ignored for `reference_match`
#'   and `evidence_tier`. Default `TRUE`.
#' @param reference_col Character vector. For `reference_match` items, the name
#'   of the per-row gold-standard column. Recycled. Default `NA`.
#' @param tier_lookup Data frame or `NULL`. For `evidence_tier` items, a table
#'   with columns `option`, `tier` (`"concordant"` / `"nonconcordant"` /
#'   `"neutral"`) and optional `effective_from` / `effective_to` dates for
#'   date-versioned guidelines. Default `NULL`.
#' @param weight Numeric vector. Composite-score weights (> 0). Recycled.
#'   Default `1`.
#' @param na_policy Character vector. How to treat uncodable / unreached items:
#'   `"not_applicable"` drops the item from that call's denominator (the natural
#'   handling for within-encounter conversation exits); `"incorrect"` counts it
#'   as non-concordant against a full denominator. Recycled. Default
#'   `"not_applicable"`.
#' @param option_sep Character scalar. Delimiter for `evidence_tier` option
#'   columns supplied as strings. Default `";"`.
#'
#' @return A `mysterycall_rubric` object: a list with element `items` (a
#'   [tibble::tibble()] of the validated item specifications), `tier_lookup`,
#'   and `option_sep`.
#'
#' @family concordance
#' @seealso [mysterycall_score_concordance()]
#' @importFrom tibble tibble
#' @importFrom checkmate assert_character assert_numeric assert_data_frame
#' @export
#'
#' @examples
#' # Lungfiel 2023 - a four-item counseling-quality checklist
#' mysterycall_concordance_rubric(
#'   item  = c("advised_window", "take_asap", "redose_after_vomit"),
#'   label = c("Advised on differing windows of effect",
#'             "Advised to take as soon as possible",
#'             "Advised re-dosing after vomiting"),
#'   type  = "binary", correct = TRUE
#' )
mysterycall_concordance_rubric <- function(
    item,
    label         = item,
    type          = "binary",
    correct       = TRUE,
    reference_col = NA_character_,
    tier_lookup   = NULL,
    weight        = 1,
    na_policy     = "not_applicable",
    option_sep    = ";") {

  checkmate::assert_character(item, min.len = 1, any.missing = FALSE, unique = TRUE)
  n <- length(item)

  allowed_types <- c("binary", "expected_present", "reference_match", "evidence_tier")
  type <- .mc_recycle(as.character(type), n, "type")
  if (!all(type %in% allowed_types)) {
    stop("`type` must be one of: ", paste(allowed_types, collapse = ", "), call. = FALSE)
  }

  label         <- .mc_recycle(as.character(label), n, "label")
  reference_col <- .mc_recycle(as.character(reference_col), n, "reference_col")
  na_policy     <- .mc_recycle(as.character(na_policy), n, "na_policy")
  if (!all(na_policy %in% c("not_applicable", "incorrect"))) {
    stop('`na_policy` must be "not_applicable" or "incorrect".', call. = FALSE)
  }
  weight <- .mc_recycle(weight, n, "weight")
  checkmate::assert_numeric(weight, lower = .Machine$double.eps, finite = TRUE)

  # correct -> list of length n; expected_present items are forced to TRUE
  if (!is.list(correct)) correct <- as.list(correct)
  if (length(correct) == 1L) correct <- rep(correct, n)
  if (length(correct) != n) {
    stop("`correct` must have length 1 or ", n, ".", call. = FALSE)
  }
  for (i in seq_len(n)) {
    if (type[i] == "expected_present") correct[[i]] <- TRUE
  }

  # per-type requirements
  if (any(type == "reference_match" & is.na(reference_col))) {
    stop("`reference_match` items require a non-NA `reference_col`.", call. = FALSE)
  }
  if (any(type == "evidence_tier")) {
    checkmate::assert_data_frame(tier_lookup, min.rows = 1)
    if (!all(c("option", "tier") %in% names(tier_lookup))) {
      stop("`tier_lookup` needs columns `option` and `tier`.", call. = FALSE)
    }
  }

  items <- tibble::tibble(
    item          = item,
    label         = label,
    type          = type,
    correct       = correct,
    reference_col = reference_col,
    weight        = weight,
    na_policy     = na_policy
  )

  structure(
    list(items = items, tier_lookup = tier_lookup, option_sep = option_sep),
    class = "mysterycall_rubric"
  )
}


# ---- scoring workhorse ------------------------------------------------------

#' Score Captured Calls Against a Concordance Rubric
#'
#' Compares each captured call to the reference standard defined by a
#' [mysterycall_concordance_rubric()] and returns call-level composite scores,
#' item-level concordance rates (with Wilson confidence intervals), and an
#' overall summary. Item denominators track *applicability* separately from the
#' number of calls, so within-encounter conversation exits (which shrink an
#' item's denominator) are handled natively rather than being mistaken for a
#' zero.
#'
#' @param data A data frame with one row per call. Rubric item ids are columns.
#'   `evidence_tier` items hold either a list-column of option vectors or a
#'   delimited string (see `option_sep` on the rubric).
#' @param rubric A `mysterycall_rubric` from [mysterycall_concordance_rubric()].
#' @param call_id_col Character scalar or `NULL`. Column uniquely identifying a
#'   call. `NULL` uses the row index.
#' @param group_col Character scalar or `NULL`. Optional grouping column; when
#'   supplied, the result carries a per-group composite summary suitable for a
#'   disparities table.
#' @param date_col Character scalar or `NULL`. Optional call-date column used to
#'   select the `evidence_tier` rows in force at call time (date-versioned
#'   guidelines).
#' @param conf_level Numeric. Confidence level for item-rate Wilson intervals.
#'   Default `0.95`.
#' @param output_dir Character scalar or `NULL`. Directory for the item-rate
#'   CSV. `NULL` writes to a session temp directory via [mysterycall_tempdir()].
#'   Pass `NA` to skip writing.
#' @param filename Character scalar. Output CSV file name. Default
#'   `"concordance_item_rates.csv"`.
#'
#' @return A `mysterycall_concordance` object: a list with
#' \describe{
#'   \item{`call_scores`}{Tibble, one row per call: `call_id`, `n_applicable`,
#'     `n_concordant`, `score_pct`, `weighted_pct`.}
#'   \item{`item_rates`}{Tibble, one row per item: `item`, `label`, `type`,
#'     `n_applicable`, `n_concordant`, `rate`, `ci_lower`, `ci_upper`.}
#'   \item{`overall`}{Named list: `mean_score_pct`, `sd_score_pct`,
#'     `median_score_pct`, `n_calls`, `mean_items_applicable`.}
#'   \item{`by_group`}{Tibble or `NULL`: per-group `n_calls`, `mean_score_pct`,
#'     `sd_score_pct`.}
#'   \item{`rubric`, `settings`}{The rubric and call settings.}
#' }
#'
#' @family concordance
#' @importFrom tibble tibble
#' @importFrom stats sd median
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_number
#' @importFrom utils write.csv
#' @export
#'
#' @examples
#' calls <- data.frame(
#'   advised_window     = c(TRUE, TRUE, FALSE, NA,   TRUE),
#'   take_asap          = c(TRUE, FALSE, TRUE, TRUE, TRUE),
#'   redose_after_vomit = c(FALSE, TRUE, NA,   TRUE, TRUE),
#'   district           = c("A", "A", "B", "B", "B")
#' )
#' rub <- mysterycall_concordance_rubric(
#'   item = c("advised_window", "take_asap", "redose_after_vomit"),
#'   type = "binary", correct = TRUE
#' )
#' res <- mysterycall_score_concordance(calls, rub, group_col = "district",
#'                                      output_dir = NA)
#' res$item_rates
mysterycall_score_concordance <- function(
    data,
    rubric,
    call_id_col = NULL,
    group_col   = NULL,
    date_col    = NULL,
    conf_level  = 0.95,
    output_dir  = NULL,
    filename    = "concordance_item_rates.csv") {

  checkmate::assert_data_frame(data, min.rows = 1)
  if (!inherits(rubric, "mysterycall_rubric")) {
    stop("`rubric` must come from mysterycall_concordance_rubric().", call. = FALSE)
  }
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)

  items <- rubric$items
  K <- nrow(items)
  n <- nrow(data)

  # required columns
  need <- items$item
  ref_needed <- items$reference_col[items$type == "reference_match"]
  need <- c(need, ref_needed[!is.na(ref_needed)])
  if (!is.null(group_col)) need <- c(need, group_col)
  if (!is.null(date_col)) need <- c(need, date_col)
  if (!is.null(call_id_col)) need <- c(need, call_id_col)
  checkmate::assert_names(names(data), must.include = unique(need))

  dates <- if (!is.null(date_col)) as.Date(data[[date_col]]) else NULL

  # score each item into concordant / applicable matrices
  CM <- matrix(NA_real_, nrow = n, ncol = K)  # 1 concordant, 0 discordant, NA n/a
  AM <- matrix(FALSE, nrow = n, ncol = K)     # applicable flag
  for (k in seq_len(K)) {
    raw <- .mc_score_item(data, items[k, ], rubric$tier_lookup, rubric$option_sep, dates)
    concordant <- raw
    if (items$na_policy[k] == "incorrect") {
      concordant[is.na(concordant)] <- FALSE
      AM[, k] <- TRUE
    } else {
      AM[, k] <- !is.na(concordant)
    }
    num <- as.numeric(concordant)
    num[!AM[, k]] <- NA_real_
    CM[, k] <- num
  }

  W <- items$weight
  Wmat <- matrix(W, nrow = n, ncol = K, byrow = TRUE)

  n_appl_row <- rowSums(AM)
  n_conc_row <- rowSums(CM, na.rm = TRUE)
  w_appl_row <- rowSums(Wmat * AM)
  w_conc_row <- rowSums(Wmat * CM, na.rm = TRUE)

  score_pct    <- ifelse(n_appl_row > 0, 100 * n_conc_row / n_appl_row, NA_real_)
  weighted_pct <- ifelse(w_appl_row > 0, 100 * w_conc_row / w_appl_row, NA_real_)

  call_id <- if (!is.null(call_id_col)) data[[call_id_col]] else seq_len(n)

  call_scores <- tibble::tibble(
    call_id      = call_id,
    n_applicable = n_appl_row,
    n_concordant = as.integer(n_conc_row),
    score_pct    = round(score_pct, 1),
    weighted_pct = round(weighted_pct, 1)
  )

  # item-level rates + Wilson CIs
  n_appl_col <- colSums(AM)
  n_conc_col <- colSums(CM, na.rm = TRUE)
  rate <- ifelse(n_appl_col > 0, n_conc_col / n_appl_col, NA_real_)
  ci <- t(vapply(
    seq_len(K),
    function(k) .mc_wilson_ci(n_conc_col[k], n_appl_col[k], conf_level),
    numeric(2)
  ))

  item_rates <- tibble::tibble(
    item         = items$item,
    label        = items$label,
    type         = items$type,
    n_applicable = as.integer(n_appl_col),
    n_concordant = as.integer(n_conc_col),
    rate         = round(rate, 3),
    ci_lower     = round(ci[, 1], 3),
    ci_upper     = round(ci[, 2], 3)
  )

  overall <- list(
    mean_score_pct        = round(mean(score_pct, na.rm = TRUE), 1),
    sd_score_pct          = round(stats::sd(score_pct, na.rm = TRUE), 1),
    median_score_pct      = round(stats::median(score_pct, na.rm = TRUE), 1),
    n_calls               = n,
    mean_items_applicable = round(mean(n_appl_row), 1)
  )

  by_group <- NULL
  if (!is.null(group_col)) {
    g <- as.character(data[[group_col]])
    by_group <- do.call(rbind, lapply(split(score_pct, g), function(s) {
      data.frame(
        n_calls        = length(s),
        mean_score_pct = round(mean(s, na.rm = TRUE), 1),
        sd_score_pct   = round(stats::sd(s, na.rm = TRUE), 1),
        stringsAsFactors = FALSE
      )
    }))
    by_group <- tibble::tibble(
      group          = rownames(by_group),
      n_calls        = by_group$n_calls,
      mean_score_pct = by_group$mean_score_pct,
      sd_score_pct   = by_group$sd_score_pct
    )
  }

  if (!isTRUE(is.na(output_dir))) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("concordance", create = TRUE)
    }
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    }
    out_path <- file.path(output_dir, filename)
    utils::write.csv(item_rates, out_path, row.names = FALSE)
    message(sprintf("Concordance item rates written to: %s", out_path))
  }

  structure(
    list(
      call_scores = call_scores,
      item_rates  = item_rates,
      overall     = overall,
      by_group    = by_group,
      rubric      = rubric,
      settings    = list(
        group_col = group_col, date_col = date_col,
        call_id_col = call_id_col, conf_level = conf_level
      )
    ),
    class = "mysterycall_concordance"
  )
}


# ---- inter-rater reliability ------------------------------------------------

#' Per-Item Inter-Rater Agreement for a Concordance Rubric
#'
#' Computes Cohen's kappa and percent agreement for each rubric item across two
#' independent coders/callers of the *same* calls -- the reliability metric that
#' dual-coder counseling audits report (and that several published studies
#' collected the raw material for but never computed).
#'
#' @param rater1,rater2 Data frames of identical shape, one row per call in the
#'   same order (or aligned by `call_id_col`), each holding the rubric item
#'   columns as coded by one rater.
#' @param rubric A `mysterycall_rubric`. Only its `item` ids are used.
#' @param call_id_col Character scalar or `NULL`. If supplied, the two frames
#'   are aligned on this key before comparison; otherwise row order is assumed.
#'
#' @return A [tibble::tibble()] with columns `item`, `kappa`, `pct_agree`, `n`.
#'
#' @family concordance
#' @importFrom tibble tibble
#' @importFrom checkmate assert_data_frame
#' @export
#'
#' @examples
#' r1 <- data.frame(asked_age = c(TRUE, TRUE, FALSE, TRUE))
#' r2 <- data.frame(asked_age = c(TRUE, FALSE, FALSE, TRUE))
#' rub <- mysterycall_concordance_rubric("asked_age", type = "expected_present")
#' mysterycall_concordance_kappa(r1, r2, rub)
mysterycall_concordance_kappa <- function(rater1, rater2, rubric, call_id_col = NULL) {
  checkmate::assert_data_frame(rater1, min.rows = 1)
  checkmate::assert_data_frame(rater2, min.rows = 1)
  if (!inherits(rubric, "mysterycall_rubric")) {
    stop("`rubric` must come from mysterycall_concordance_rubric().", call. = FALSE)
  }

  if (!is.null(call_id_col)) {
    ord2 <- match(rater1[[call_id_col]], rater2[[call_id_col]])
    rater2 <- rater2[ord2, , drop = FALSE]
  }

  items <- rubric$items$item
  rows <- lapply(items, function(it) {
    k <- .mc_cohen_kappa(rater1[[it]], rater2[[it]])
    tibble::tibble(
      item = it,
      kappa = round(unname(k["kappa"]), 3),
      pct_agree = round(unname(k["pct_agree"]), 3),
      n = as.integer(unname(k["n"]))
    )
  })
  do.call(rbind, rows)
}


# ---- prose builder ----------------------------------------------------------

#' Manuscript-Ready Concordance Sentence
#'
#' Turns a [mysterycall_score_concordance()] result into a numbers-locked
#' sentence, in the package's prose-builder family. With `item = NULL` it
#' describes the overall composite; naming an `item` describes that item's
#' concordance rate and confidence interval.
#'
#' @param x A `mysterycall_concordance` object.
#' @param item Character scalar or `NULL`. A rubric item id, or `NULL` for the
#'   overall composite sentence.
#' @param subject Character scalar. Noun for the audited units. Default
#'   `"clinics"`.
#' @param digits Integer. Rounding digits for percentages. Default `1`.
#'
#' @return A character scalar.
#'
#' @family concordance
#' @importFrom checkmate assert_class assert_string assert_integerish
#' @export
#'
#' @examples
#' calls <- data.frame(advised_window = c(TRUE, TRUE, FALSE, NA, TRUE))
#' rub <- mysterycall_concordance_rubric("advised_window", type = "binary")
#' res <- mysterycall_score_concordance(calls, rub, output_dir = NA)
#' cat(mysterycall_concordance_sentence(res, item = "advised_window",
#'                                      subject = "pharmacies"))
mysterycall_concordance_sentence <- function(x, item = NULL, subject = "clinics",
                                             digits = 1L) {
  checkmate::assert_class(x, "mysterycall_concordance")
  checkmate::assert_string(subject)
  checkmate::assert_integerish(digits, lower = 0, len = 1)

  if (is.null(item)) {
    o <- x$overall
    return(sprintf(
      paste0("Across %d %s, guideline concordance averaged %s%% of applicable ",
             "items (mean %s of %d rubric items assessed per call)."),
      o$n_calls, subject,
      formatC(o$mean_score_pct, format = "f", digits = digits),
      formatC(o$mean_items_applicable, format = "f", digits = digits),
      nrow(x$item_rates)
    ))
  }

  row <- x$item_rates[x$item_rates$item == item, , drop = FALSE]
  if (nrow(row) == 0L) {
    stop("`item` not found in the scored rubric: ", item, call. = FALSE)
  }
  sprintf(
    "%s %s concordant with the standard for \"%s\" in %s%% of calls (n = %d; 95%% CI %s-%s%%).",
    format(subject), "were",
    row$label,
    formatC(100 * row$rate, format = "f", digits = digits),
    row$n_applicable,
    formatC(100 * row$ci_lower, format = "f", digits = digits),
    formatC(100 * row$ci_upper, format = "f", digits = digits)
  )
}


# ---- S3 methods -------------------------------------------------------------

#' @export
print.mysterycall_rubric <- function(x, ...) {
  cat(sprintf("<mysterycall_rubric: %d item(s)>\n", nrow(x$items)))
  tab <- x$items[, c("item", "type", "na_policy")]
  print(as.data.frame(tab), row.names = FALSE)
  invisible(x)
}

#' @export
print.mysterycall_concordance <- function(x, ...) {
  o <- x$overall
  cat(sprintf(
    "<mysterycall_concordance: %d calls, %d items>\n", o$n_calls, nrow(x$item_rates)
  ))
  cat(sprintf(
    "  composite: mean %.1f%% (median %.1f%%, sd %.1f), %.1f items/call applicable\n",
    o$mean_score_pct, o$median_score_pct, o$sd_score_pct, o$mean_items_applicable
  ))
  cat("  item concordance:\n")
  ir <- x$item_rates
  for (i in seq_len(nrow(ir))) {
    cat(sprintf(
      "    %-28s %5.1f%% (n=%d)\n",
      substr(ir$label[i], 1, 28),
      100 * ir$rate[i], ir$n_applicable[i]
    ))
  }
  if (!is.null(x$by_group)) {
    cat(sprintf("  grouped by %s (%d groups)\n",
                x$settings$group_col, nrow(x$by_group)))
  }
  invisible(x)
}

#' @export
as.data.frame.mysterycall_concordance <- function(x, ...) {
  as.data.frame(x$item_rates, ...)
}
