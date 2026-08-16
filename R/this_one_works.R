#' Confirm all traffic is routed through Tor
#'
#' Stops with an error if the Tor proxy is unreachable or the visible IP is
#' not a Tor exit node -- ensuring no requests are sent over your real IP.
#'
#' @param torPort Integer SOCKS5 proxy port (default 9150).
#' @return Invisibly returns the detected Tor exit-node IP.
#' @keywords internal
verify_tor <- function(torPort = 9150L) {
  proxy_str <- paste0("socks5://localhost:", as.integer(torPort))

  resp <- tryCatch(
    httr::GET(
      "https://check.torproject.org/api/ip",
      httr::use_proxy(proxy_str),
      httr::timeout(20)
    ),
    error = function(e) stop(
      "Cannot reach Tor proxy on port ", torPort, ": ", conditionMessage(e),
      "\nMake sure Tor Browser (port 9150) or the tor daemon (port 9050) is running.",
      call. = FALSE
    )
  )

  if (httr::status_code(resp) != 200L)
    stop("Tor check endpoint returned HTTP ", httr::status_code(resp), call. = FALSE)

  info   <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  ip     <- info[["IP"]]
  is_tor <- isTRUE(info[["IsTor"]])

  if (!is_tor)
    stop(
      "IP leak detected: visible IP ", ip, " is NOT a Tor exit node.\n",
      "Verify that Tor is running on port ", torPort, " before scraping.",
      call. = FALSE
    )

  message(sprintf("[tor] Verified \u2014 exit node IP: %s", ip))
  invisible(ip)
}


#' Rotate the Tor circuit so the next request uses a new exit node
#'
#' Sends \code{SIGNAL NEWNYM} to the Tor control port. Silently skips if
#' the control port is unreachable (common with Tor Browser's default settings).
#'
#' @param control_port Integer control port (default 9051).
#' @param password Character control-port password (default \code{""}).
#' @keywords internal
rotate_tor_circuit <- function(control_port = 9051L, password = "") {
  tryCatch({
    con <- socketConnection("127.0.0.1", port = as.integer(control_port),
                            open = "r+", timeout = 5, blocking = TRUE)
    on.exit(try(close(con), silent = TRUE))
    writeLines(sprintf('AUTHENTICATE "%s"', password), con)
    writeLines("SIGNAL NEWNYM", con)
    Sys.sleep(2)  # Tor needs ~2 s to build a new circuit
    message("[tor] Circuit rotated \u2014 new exit node assigned")
  }, error = function(e) {
    message(sprintf(
      "[tor] Circuit rotation skipped (%s)\n      Tip: enable the Tor control port or use the tor daemon instead of Tor Browser.",
      conditionMessage(e)
    ))
  })
}


#' Scrape ABOG Physicians via Tor (privacy-first)
#'
#' Queries \code{https://api.abog.org/diplomate/{id}/verify} for each ID in
#' \code{[startID, endID]}.  Every request is routed through a local Tor
#' SOCKS5 proxy -- your real IP address is never sent to the ABOG server.
#'
#' Privacy protections (in order of importance):
#' \enumerate{
#'   \item \strong{Tor verification} -- confirms a Tor exit node is in use
#'         \emph{before} any scraping begins; aborts if the check fails.
#'   \item \strong{Circuit rotation} -- requests a new Tor exit node every
#'         \code{rotate_tor_every} requests, limiting how much traffic any
#'         single exit node sees.
#'   \item \strong{Randomised timing} -- each request waits a random interval
#'         in \code{[sleep_min, sleep_max]} seconds, so traffic cannot be
#'         fingerprinted by a fixed inter-request cadence.
#'   \item \strong{Randomised User-Agent} -- each request picks a different
#'         browser string so repeated requests look like different clients.
#'   \item \strong{Transient-error retry} -- 429 / 5xx and network errors are
#'         retried with exponential back-off; only confirmed 404 / empty
#'         responses are logged as genuinely not found.  This prevents
#'         valid records from being silently lost.
#'   \item \strong{Checkpoint saves} -- results are written to disk every
#'         \code{checkpoint_every} records so no data is lost if the session
#'         is interrupted.
#' }
#'
#' @param startID Integer. First diplomate ID to query.
#' @param endID Integer. Last diplomate ID to query (inclusive).
#' @param torPort Integer. Tor SOCKS5 proxy port.  Use \code{9150} (default)
#'   for Tor Browser or \code{9050} for the \code{tor} daemon.
#' @param tor_ports Integer vector of Tor SOCKS5 proxy ports (default
#'   \code{9050}).  Supply multiple ports -- e.g. \code{c(9050, 9052, 9054,
#'   9056)} -- to enable parallel scraping: the ID range is split into
#'   \code{length(tor_ports)} chunks and each chunk is scraped in its own
#'   forked process through a different Tor circuit.  Requires the \code{tor}
#'   daemon configured with one \code{SocksPort} per entry (see
#'   \code{/opt/homebrew/etc/tor/torrc}).  Use \code{9150} for Tor Browser
#'   (single port only).
#' @param tor_control_port Integer. Tor control port for circuit rotation
#'   (default 9051).  Pass \code{NULL} to disable rotation entirely.
#' @param tor_control_password Character. Control-port password (default
#'   \code{""}, i.e. no password -- typical for localhost-only setups).
#' @param skip_ids_paths Optional character vector of paths to CSV or Parquet
#'   files containing IDs to skip.  Each file may have a column named
#'   \code{WrongIDs}, \code{UnknownIDs}, or \code{FailedIDs} -- all are
#'   recognised automatically.  Pass the \code{UnknownIDs_*.csv} and/or
#'   \code{FailedIDs_*.csv} files from a previous run to avoid re-querying
#'   IDs that were already confirmed empty or that persistently failed.
#' @param output_format \code{"csv"} (default) or \code{"parquet"}.
#' @param output_dir Directory for output files. Created if absent.
#'   Defaults to \code{tempdir()}.
#' @param checkpoint_every Save partial results after every N successful
#'   records (default 100). Set to \code{Inf} to disable.
#' @param max_retries Maximum retry attempts per ID for transient errors
#'   (default 3).
#' @param sleep_min Minimum seconds between requests (default 2).  Increase
#'   to be more conservative.
#' @param sleep_max Maximum seconds between requests (default 5).
#' @param rotate_tor_every Request a new Tor circuit every N requests
#'   (default 25). Lower values mean more exit-node diversity at the cost
#'   of slightly more delay (2 s per rotation).  Set to \code{Inf} to disable.
#' @param max_skip_age_days Integer. Maximum age (in days) of a "confirmed empty"
#'   record before the ID is re-queried (default 180 -- six months).  Files with
#'   a \code{ConfirmedEmptyAt} column use per-row timestamps; older files
#'   without that column are judged by their file modification date.  Set to
#'   \code{Inf} to trust skip files forever (not recommended -- newly certified
#'   physicians can fill previously empty IDs).
#' @param descending Logical. If \code{TRUE}, iterate from \code{endID} down
#'   to \code{startID} so the most recently issued (highest-numbered) IDs are
#'   scraped first (default \code{FALSE}).  Combine with
#'   \code{\link{find_max_abog_id}} to always start from the current top of
#'   the registry.
#' @param verbose Logical. Print per-ID progress (default \code{TRUE}).
#'
#' @return A data frame of scraped physician records with columns from the
#'   ABOG JSON response plus \code{ID} and \code{ScrapedAt}.
#'
#' @importFrom httr GET content use_proxy add_headers timeout status_code
#' @importFrom dplyr bind_rows
#'
#' @examplesIf interactive()
#' result <- scrape_physicians_data_with_tor(
#'   startID    = 9045999,
#'   endID      = 9046010,
#'   torPort    = 9150,
#'   output_dir = "~/Desktop/abog_scrape"
#' )
#' @keywords internal
scrape_physicians_data_with_tor <- function(
    startID,
    endID,
    tor_ports            = 9050L,
    tor_control_port     = 9051L,
    tor_control_password = "",
    skip_ids_paths       = NULL,
    output_format        = c("csv", "parquet"),
    output_dir           = tempdir(),
    checkpoint_every     = 100L,
    max_retries          = 3L,
    sleep_min            = 0.3,
    sleep_max            = 0.8,
    sleep_min_notfound   = 0.1,
    sleep_max_notfound   = 0.3,
    rotate_tor_every     = 50L,
    descending           = FALSE,
    max_skip_age_days    = 180L,
    verbose              = TRUE) {

  output_format <- match.arg(output_format)
  tor_ports     <- as.integer(tor_ports)
  n_workers     <- length(tor_ports)
  .log <- function(...) if (verbose) message(...)

  # -- Validate ---------------------------------------------------------------
  stopifnot(
    is.numeric(startID), is.numeric(endID), startID <= endID,
    all(tor_ports > 0L),
    is.numeric(sleep_min), is.numeric(sleep_max), sleep_min >= 0, sleep_min <= sleep_max,
    is.numeric(sleep_min_notfound), is.numeric(sleep_max_notfound),
    is.numeric(max_retries), max_retries >= 0L,
    is.numeric(checkpoint_every), checkpoint_every > 0,
    is.numeric(rotate_tor_every), rotate_tor_every > 0
  )

  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

  # -- Verify all Tor ports before any scraping -------------------------------
  for (p in tor_ports) verify_tor(p)

  # -- Skip list (staleness-filtered) ----------------------------------------
  skip_col_names <- c("WrongIDs", "UnknownIDs", "FailedIDs")
  wrong_ids      <- integer(0)
  cutoff         <- Sys.time() - as.numeric(max_skip_age_days) * 86400

  if (!is.null(skip_ids_paths)) {
    n_loaded <- 0L; n_dropped <- 0L
    for (path in skip_ids_paths) {
      tbl <- tryCatch(tyler_read_table(path), error = function(e) NULL)
      if (is.null(tbl)) next
      id_col <- intersect(skip_col_names, names(tbl))
      if (length(id_col) == 0L) next
      ids <- suppressWarnings(as.integer(tbl[[id_col[[1L]]]]))
      ids <- ids[!is.na(ids) & ids > 0L]
      if ("ConfirmedEmptyAt" %in% names(tbl)) {
        ts      <- as.POSIXct(tbl$ConfirmedEmptyAt)[seq_along(ids)]
        keep    <- !is.na(ts) & ts >= cutoff
        n_dropped <- n_dropped + sum(!keep)
        ids     <- ids[keep]
      } else {
        mtime <- file.info(path)$mtime
        if (!is.na(mtime) && mtime < cutoff) { n_dropped <- n_dropped + length(ids); ids <- integer(0) }
      }
      n_loaded  <- n_loaded + length(ids)
      wrong_ids <- unique(c(wrong_ids, ids))
    }
    .log(sprintf("[abog] Skip list: %d fresh, %d stale-dropped \u2192 %d skipped",
                 n_loaded, n_dropped, length(wrong_ids)))
  }

  # -- Build ID list ----------------------------------------------------------
  full_seq <- if (descending)
    seq.int(as.integer(endID), as.integer(startID), by = -1L)
  else
    seq.int(as.integer(startID), as.integer(endID))
  id_list <- setdiff(full_seq, wrong_ids)
  n_total <- length(id_list)

  .log(sprintf("[abog] %s IDs | %d worker(s) | order: %s | sleep: %.1f\u2013%.1f s (found), %.1f\u2013%.1f s (not found)",
               format(n_total, big.mark = ","), n_workers,
               if (descending) "desc" else "asc",
               sleep_min, sleep_max, sleep_min_notfound, sleep_max_notfound))

  est_secs <- n_total * (0.7 * mean(c(sleep_min_notfound, sleep_max_notfound)) +
                          0.3 * mean(c(sleep_min, sleep_max))) / n_workers
  .log(sprintf("[abog] Estimated time: %.1f hours (%.1f days)",
               est_secs / 3600, est_secs / 86400))

  timestamp_start <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")

  # -- Self-contained worker function ----------------------------------------
  # Everything the worker needs is passed explicitly so it runs cleanly in a
  # forked process with no shared state.
  run_worker <- function(worker_id, chunk, proxy_str, base_url,
                         sleep_min, sleep_max, sleep_min_notfound, sleep_max_notfound,
                         max_retries, rotate_tor_every, tor_control_port,
                         tor_control_password, checkpoint_every,
                         output_dir, output_format, timestamp_start,
                         startID, endID, verbose) {

    .wlog <- function(...) if (verbose) message(sprintf("[W%d] ", worker_id), ...)

    user_agents <- c(
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      "Mozilla/5.0 (X11; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Safari/605.1.15",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0"
    )

    Physicians        <- data.frame()
    UnknownIDs        <- integer(0)
    UnknownTimestamps <- as.POSIXct(character(0))
    FailedIDs         <- integer(0)
    FailedTimestamps  <- as.POSIXct(character(0))
    n_ckpt            <- 0L   # counts IDs since last checkpoint (all outcomes)
    n_req             <- 0L
    n_chunk           <- length(chunk)

    save_worker_results <- function(label = "") {
      ext  <- if (identical(output_format, "parquet")) ".parquet" else ".csv"
      stem <- file.path(output_dir, sprintf("W%d_Physicians_%d-%d_%s%s",
                                             worker_id, startID, endID, timestamp_start, label))
      if (nrow(Physicians) > 0)
        tyler_write_table(Physicians, paste0(stem, ext), format = output_format)
      tyler_write_table(
        data.frame(UnknownIDs = UnknownIDs, ConfirmedEmptyAt = UnknownTimestamps),
        file.path(output_dir, sprintf("W%d_UnknownIDs_%d-%d_%s%s%s",
                                       worker_id, startID, endID, timestamp_start, label, ext)),
        format = output_format
      )
      tyler_write_table(
        data.frame(FailedIDs = FailedIDs, ConfirmedEmptyAt = FailedTimestamps),
        file.path(output_dir, sprintf("W%d_FailedIDs_%d-%d_%s%s%s",
                                       worker_id, startID, endID, timestamp_start, label, ext)),
        format = output_format
      )
    }

    for (i in seq_along(chunk)) {
      id <- chunk[[i]]

      # Circuit rotation
      n_req <- n_req + 1L
      if (!is.null(tor_control_port) && is.finite(rotate_tor_every) &&
          n_req > 1L && n_req %% as.integer(rotate_tor_every) == 1L)
        rotate_tor_circuit(tor_control_port, tor_control_password)

      ua  <- user_agents[[sample.int(length(user_agents), 1L)]]
      url <- sprintf(base_url, id)
      if (i %% 500L == 1L || i == n_chunk)
        .wlog(sprintf("[%d/%d] ID %d | found: %d", i, n_chunk, id, nrow(Physicians)))

      status <- "failed"; row <- NULL

      for (attempt in seq_len(max_retries + 1L)) {
        resp <- tryCatch(
          httr::GET(url, httr::use_proxy(proxy_str), httr::timeout(30),
                    httr::add_headers(`User-Agent`      = ua,
                                      `Accept`          = "application/json, */*;q=0.8",
                                      `Accept-Language` = "en-US,en;q=0.9",
                                      `Accept-Encoding` = "gzip, deflate, br",
                                      `Referer`         = "https://www.abog.org/",
                                      `Connection`      = "keep-alive")),
          error = function(e) NULL
        )

        if (is.null(resp)) {
          if (attempt <= max_retries) Sys.sleep((2^attempt) * sleep_min)
          next
        }

        sc <- httr::status_code(resp)

        if (sc == 200L) {
          body <- tryCatch(
            jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8")),
            error = function(e) NULL
          )
          if (!is.null(body) && length(body) > 0) {
            flat          <- lapply(body, function(x) if (length(x) != 1L || is.list(x)) I(list(x)) else x)
            row           <- as.data.frame(flat, stringsAsFactors = FALSE)
            row$ID        <- id
            row$ScrapedAt <- Sys.time()
            status        <- "ok"
          } else {
            status <- "not_found"
          }
          break
        }
        if (sc == 404L) { status <- "not_found"; break }

        if (attempt <= max_retries)
          Sys.sleep((2^attempt) * runif(1, sleep_min, sleep_max))
      }

      # Checkpoint fires on every N IDs processed (regardless of outcome)
      n_ckpt <- n_ckpt + 1L
      if (status == "ok") {
        Physicians <- dplyr::bind_rows(Physicians, row)
        Sys.sleep(runif(1, sleep_min, sleep_max))
      } else if (status == "not_found") {
        UnknownIDs        <- c(UnknownIDs, id)
        UnknownTimestamps <- c(UnknownTimestamps, Sys.time())
        Sys.sleep(runif(1, sleep_min_notfound, sleep_max_notfound))
      } else {
        FailedIDs        <- c(FailedIDs, id)
        FailedTimestamps <- c(FailedTimestamps, Sys.time())
        Sys.sleep(runif(1, sleep_min_notfound, sleep_max_notfound))
      }
      if (is.finite(checkpoint_every) && n_ckpt >= as.integer(checkpoint_every)) {
        save_worker_results("_checkpoint")
        n_ckpt <- 0L
      }
    }

    save_worker_results()
    list(Physicians = Physicians, UnknownIDs = UnknownIDs,
         UnknownTimestamps = UnknownTimestamps,
         FailedIDs = FailedIDs, FailedTimestamps = FailedTimestamps)
  }

  # -- Split IDs across workers and launch -----------------------------------
  chunks <- split(id_list, cut(seq_along(id_list), n_workers, labels = FALSE))

  if (n_workers == 1L) {
    results <- list(run_worker(
      1L, chunks[[1L]], paste0("socks5://localhost:", tor_ports[[1L]]),
      "https://api.abog.org/diplomate/%d/verify",
      sleep_min, sleep_max, sleep_min_notfound, sleep_max_notfound,
      max_retries, rotate_tor_every, tor_control_port, tor_control_password,
      checkpoint_every, output_dir, output_format, timestamp_start,
      startID, endID, verbose
    ))
  } else {
    .log(sprintf("[abog] Forking %d workers on ports %s",
                 n_workers, paste(tor_ports, collapse = ", ")))
    results <- parallel::mclapply(
      seq_len(n_workers),
      function(w) run_worker(
        w, chunks[[w]], paste0("socks5://localhost:", tor_ports[[w]]),
        "https://api.abog.org/diplomate/%d/verify",
        sleep_min, sleep_max, sleep_min_notfound, sleep_max_notfound,
        max_retries, rotate_tor_every, tor_control_port, tor_control_password,
        checkpoint_every, output_dir, output_format, timestamp_start,
        startID, endID, verbose
      ),
      mc.cores = n_workers,
      mc.preschedule = FALSE
    )
  }

  # -- Merge worker results ---------------------------------------------------
  ok <- vapply(results, is.list, logical(1))
  if (any(!ok)) {
    failed_workers <- which(!ok)
    .log(sprintf("[abog] WARNING: %d worker(s) failed (W%s) \u2014 excluded from merged output; per-worker checkpoint CSVs are intact",
                 sum(!ok), paste(failed_workers, collapse = ", W")))
  }
  results <- results[ok]
  Physicians        <- dplyr::bind_rows(lapply(results, `[[`, "Physicians"))
  UnknownIDs        <- unlist(lapply(results, `[[`, "UnknownIDs"))
  UnknownTimestamps <- do.call(c, lapply(results, `[[`, "UnknownTimestamps"))
  FailedIDs         <- unlist(lapply(results, `[[`, "FailedIDs"))
  FailedTimestamps  <- do.call(c, lapply(results, `[[`, "FailedTimestamps"))

  # -- Final merged save ------------------------------------------------------
  ext  <- if (identical(output_format, "parquet")) ".parquet" else ".csv"
  tyler_write_table(Physicians,
    file.path(output_dir, paste0("Physicians_", startID, "-", endID, "_", timestamp_start, ext)),
    format = output_format)
  tyler_write_table(data.frame(UnknownIDs = UnknownIDs, ConfirmedEmptyAt = UnknownTimestamps),
    file.path(output_dir, paste0("UnknownIDs_", startID, "-", endID, "_", timestamp_start, ext)),
    format = output_format)
  tyler_write_table(data.frame(FailedIDs = FailedIDs, ConfirmedEmptyAt = FailedTimestamps),
    file.path(output_dir, paste0("FailedIDs_", startID, "-", endID, "_", timestamp_start, ext)),
    format = output_format)

  .log(sprintf("[abog] Done. %d found | %d not found | %d failed \u2192 %s",
               nrow(Physicians), length(UnknownIDs), length(FailedIDs), output_dir))

  if (requireNamespace("beepr", quietly = TRUE)) beepr::beep(2)
  invisible(Physicians)
}


#' Find the highest valid ABOG diplomate ID
#'
#' Scans upward from \code{seed_id} through the ABOG API (via Tor), tracking
#' the highest ID that returns a physician record.  Stops after
#' \code{max_consecutive_misses} consecutive IDs return nothing, which
#' reliably signals the end of the registry even when IDs are not perfectly
#' contiguous.
#'
#' A binary search is NOT used here because ABOG IDs have gaps -- an empty
#' response at ID N does not imply N+1 is also empty.
#'
#' @param seed_id Integer. A known valid ID to start scanning from (e.g. the
#'   highest ID in your existing dataset).
#' @param torPort Integer. Tor SOCKS5 proxy port (default 9150).
#' @param max_consecutive_misses Integer. Stop scanning after this many
#'   back-to-back empty/404 responses (default 100).  Increase if the registry
#'   has long gaps between recent additions.
#' @param sleep_between Numeric. Seconds to sleep between probes (default 0.3).
#' @param verbose Logical. Print progress (default TRUE).
#' @return The highest integer diplomate ID that returned physician data.
#'
#' @examplesIf interactive()
#' max_id <- find_max_abog_id(seed_id = 9046331, torPort = 9150)
#' @keywords internal
find_max_abog_id <- function(seed_id,
                              torPort                 = 9150L,
                              max_consecutive_misses  = 100L,
                              sleep_between           = 0.3,
                              verbose                 = TRUE) {
  .log     <- function(...) if (verbose) message(...)
  proxy    <- paste0("socks5://localhost:", as.integer(torPort))
  base_url <- "https://api.abog.org/diplomate/%d/verify"

  probe <- function(id) {
    resp <- tryCatch(
      httr::GET(sprintf(base_url, id), httr::use_proxy(proxy), httr::timeout(20)),
      error = function(e) NULL
    )
    if (is.null(resp) || httr::status_code(resp) != 200L) return(FALSE)
    body <- tryCatch(
      jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8")),
      error = function(e) list()
    )
    length(body) > 0
  }

  .log(sprintf(
    "[find_max] Scanning upward from %d (stopping after %d consecutive misses)",
    seed_id, max_consecutive_misses
  ))

  max_found   <- as.integer(seed_id)
  consec_miss <- 0L
  id          <- as.integer(seed_id) + 1L

  while (consec_miss < as.integer(max_consecutive_misses)) {
    if (probe(id)) {
      .log(sprintf("[find_max] %d: found", id))
      max_found   <- id
      consec_miss <- 0L
    } else {
      consec_miss <- consec_miss + 1L
    }
    id <- id + 1L
    Sys.sleep(sleep_between)
  }

  .log(sprintf(
    "[find_max] Highest valid ABOG ID: %d  (stopped after %d consecutive misses at %d)",
    max_found, max_consecutive_misses, id - 1L
  ))
  max_found
}


# -- Example usage --------------------------------------------------------------
#
# Make sure Tor Browser is open (port 9150) or the tor daemon is running (9050).
#
# Step 1 -- find the current highest ID, then scrape downward from it:
#
# max_id <- find_max_abog_id(seed_id = 9046331, torPort = 9150)
#
# result <- scrape_physicians_data_with_tor(
#   startID    = 1,
#   endID      = max_id,
#   torPort    = 9150,
#   descending = TRUE,           # newest physicians first
#   output_dir = "~/Desktop/abog_scrape"
# )
